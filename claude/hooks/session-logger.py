#!/usr/bin/env python3
"""Claude Code -> Obsidian session logger.

Fired by the global SessionEnd hook. Two-stage gate:
  1. cheap pre-filter in this script (skips trivial sessions at 0 model cost)
  2. headless `claude -p` (Sonnet) reads the repo + transcript, judges the
     session, and either says SKIP or returns a Japanese work-log note.

Design notes:
  - Recursion guard: the inner `claude -p` we spawn would itself fire SessionEnd.
    We set CLAUDE_SESSION_LOGGER=1 in its environment and bail out immediately
    when we see it, so the inner session never re-triggers logging.
  - The heavy stage runs detached (--worker) so the user's session exits fast.
  - Fail-safe: any error -> exit 0. This hook must never break a session.
"""

import json
import os
import subprocess
import sys
import shutil
import datetime
import tempfile
from pathlib import Path

# ---- tunables -------------------------------------------------------------
MIN_EDITS = 1          # need at least this many file-editing tool uses
MIN_MESSAGES = 6       # ...and a non-trivial conversation length
JUDGE_MODEL = "sonnet"  # Sonnet 4.6
MAX_TURNS = 30
EDIT_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit", "apply_patch"}

VAULT = Path(os.environ.get(
    "OBSIDIAN_VAULT",
    str(Path.home() / "Documents" / "Obsidian Vault"),
))
LOG_FILE = Path.home() / ".claude" / "hooks" / "session-logger.log"
GUARD_ENV = "CLAUDE_SESSION_LOGGER"


def debug(msg: str) -> None:
    try:
        ts = datetime.datetime.now().isoformat(timespec="seconds")
        with LOG_FILE.open("a") as f:
            f.write(f"[{ts}] {msg}\n")
    except Exception:
        pass


# ---- transcript parsing ---------------------------------------------------
def scan_transcript(path: str):
    """Return (edit_count, message_count, user_prompt_count)."""
    edits = 0
    messages = 0
    user_prompts = 0
    try:
        with open(path, "r") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except Exception:
                    continue
                mtype = obj.get("type")
                if mtype in ("user", "assistant"):
                    messages += 1
                content = (obj.get("message") or {}).get("content")
                if mtype == "user":
                    # genuine prompt = has text content, not only tool_result
                    if isinstance(content, str):
                        user_prompts += 1
                    elif isinstance(content, list):
                        if any(isinstance(b, dict) and b.get("type") == "text"
                               for b in content):
                            user_prompts += 1
                if mtype == "assistant" and isinstance(content, list):
                    for b in content:
                        if isinstance(b, dict) and b.get("type") == "tool_use" \
                                and b.get("name") in EDIT_TOOLS:
                            edits += 1
    except Exception as e:
        debug(f"scan_transcript error: {e}")
    return edits, messages, user_prompts


def project_name(cwd: str) -> str:
    try:
        out = subprocess.run(
            ["git", "-C", cwd, "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, timeout=5,
        )
        if out.returncode == 0 and out.stdout.strip():
            return Path(out.stdout.strip()).name
    except Exception:
        pass
    return Path(cwd).name or "unknown"


def git_branch(cwd: str) -> str:
    try:
        out = subprocess.run(
            ["git", "-C", cwd, "rev-parse", "--abbrev-ref", "HEAD"],
            capture_output=True, text=True, timeout=5,
        )
        if out.returncode == 0:
            return out.stdout.strip()
    except Exception:
        pass
    return ""


def already_logged(logs_dir: Path, session_id: str) -> bool:
    if not session_id or not logs_dir.exists():
        return False
    try:
        for p in logs_dir.glob("*.md"):
            head = p.read_text(errors="ignore")[:600]
            if f"session_id: {session_id}" in head:
                return True
    except Exception:
        pass
    return False


# ---- stage 1: front (fast, runs inline) -----------------------------------
def front():
    if os.environ.get(GUARD_ENV) == "1":
        # we are inside the headless judge's own session -> never recurse
        return 0
    try:
        payload = json.load(sys.stdin)
    except Exception as e:
        debug(f"no/invalid stdin json: {e}")
        return 0

    transcript = payload.get("transcript_path", "")
    cwd = payload.get("cwd") or os.getcwd()
    session_id = payload.get("session_id", "")

    if not transcript or not os.path.exists(transcript):
        debug("no transcript path; skip")
        return 0

    edits, messages, prompts = scan_transcript(transcript)
    debug(f"gate session={session_id[:8]} edits={edits} msgs={messages} "
          f"prompts={prompts} cwd={cwd}")
    if edits < MIN_EDITS or messages < MIN_MESSAGES:
        debug("pre-filter: trivial session, skip (0 cost)")
        return 0

    proj = project_name(cwd)
    logs_dir = VAULT / proj / "logs"
    if already_logged(logs_dir, session_id):
        debug("already logged this session_id, skip")
        return 0

    payload["_computed"] = {
        "project": proj,
        "branch": git_branch(cwd),
        "edits": edits,
    }
    # hand the slow stage off to a detached worker so the session exits fast
    tmp = tempfile.NamedTemporaryFile(
        "w", suffix=".json", prefix="cc-logger-", delete=False)
    json.dump(payload, tmp)
    tmp.close()

    env = dict(os.environ)
    env[GUARD_ENV] = "1"
    try:
        subprocess.Popen(
            [sys.executable, os.path.abspath(__file__), "--worker", tmp.name],
            env=env,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
        debug("spawned worker")
    except Exception as e:
        debug(f"failed to spawn worker: {e}")
    return 0


# ---- stage 2: worker (slow, detached) -------------------------------------
JUDGE_PROMPT = """\
あなたは完了した Claude Code セッションをレビューし、日本語の作業ログを書く役割です。

リポジトリのルート: {cwd}
セッションの transcript (JSONL): {transcript}

手順:
1. transcript を Read して、このセッションで何が行われたか把握する。
2. リポジトリの設計ドキュメント（あれば）を読んで「正しいアーキテクチャ」を把握する。
   候補: CLAUDE.md, docs/*.md, packages/*/docs/*architecture*.md など。Glob/Grep で探す。
3. 以下2点をまとめる。

## やったこと
- このセッションで実際に行った作業を箇条書きで（変更したファイル・機能単位）。

## 失敗
approach / architecture 上の失敗だけを対象にする。lint/test/CI のような機械的エラーは対象外。
失敗のシグナルは次のいずれか:
  - ユーザーによる訂正・ダメ出し
  - Claude 自身の自己訂正・やり直し・revert
  - 設計ドキュメントと照らしてあなたが独自に気づいた逸脱
失敗が無ければ「## 失敗」セクションに「- なし」とだけ書く。
各失敗は次の4項目を必ず含めること:
  - **what**: 何が起きたか（例: 既存の repository 層を経由せず component から直接 API を叩いた）
  - **why+fix**: なぜダメか（逸脱した設計ルール）と、本来どうすべきだったか。今後 CLAUDE.md に転記できる actionable な書き方で。
  - **signal**: どう検出したか（user訂正 / 自己訂正 / repo判定）と該当ファイル
  - **severity/tags**: minor か major か、と #failure #architecture などのタグ

出力ルール（厳守）:
- このセッションに記録する価値のある作業が無い場合は、最初の行に SKIP とだけ出力して終了。
- 価値がある場合は、1行目に `FAILURES=<件数>`（数字のみ）を出力し、2行目以降に上記の
  Markdown 本文（## やったこと と ## 失敗）だけを出力する。
- frontmatter は付けない。説明や前置き・後書きは一切書かない。
"""


def run_judge(cwd: str, transcript: str) -> str:
    claude = shutil.which("claude") or "claude"
    prompt = JUDGE_PROMPT.format(cwd=cwd, transcript=transcript)
    env = dict(os.environ)
    env[GUARD_ENV] = "1"
    cmd = [
        claude, "-p", prompt,
        "--model", JUDGE_MODEL,
        "--allowedTools", "Read,Grep,Glob",
        "--max-turns", str(MAX_TURNS),
    ]
    try:
        out = subprocess.run(
            cmd, cwd=cwd, env=env, capture_output=True, text=True,
            timeout=600,
        )
        if out.returncode != 0:
            debug(f"judge non-zero rc={out.returncode} stderr={out.stderr[:400]}")
        return out.stdout.strip()
    except Exception as e:
        debug(f"judge error: {e}")
        return ""


def worker(tmpfile: str):
    try:
        with open(tmpfile) as f:
            payload = json.load(f)
    except Exception as e:
        debug(f"worker bad payload: {e}")
        return 0
    finally:
        try:
            os.unlink(tmpfile)
        except Exception:
            pass

    cwd = payload.get("cwd") or os.getcwd()
    transcript = payload.get("transcript_path", "")
    session_id = payload.get("session_id", "")
    reason = payload.get("reason", "")
    comp = payload.get("_computed", {})
    proj = comp.get("project", Path(cwd).name)
    branch = comp.get("branch", "")

    result = run_judge(cwd, transcript)
    if not result or result.lstrip().upper().startswith("SKIP"):
        debug(f"judge said SKIP/empty for {session_id[:8]}")
        return 0

    lines = result.splitlines()
    failures = 0
    body_start = 0
    if lines and lines[0].strip().upper().startswith("FAILURES="):
        try:
            failures = int(lines[0].split("=", 1)[1].strip())
        except Exception:
            failures = 0
        body_start = 1
    body = "\n".join(lines[body_start:]).strip()

    now = datetime.datetime.now()
    logs_dir = VAULT / proj / "logs"
    logs_dir.mkdir(parents=True, exist_ok=True)
    fname = now.strftime("%Y-%m-%d-%H%M") + ".md"
    target = logs_dir / fname
    if target.exists():
        target = logs_dir / (now.strftime("%Y-%m-%d-%H%M") +
                             f"-{session_id[:6]}.md")

    fm = (
        "---\n"
        f"project: {proj}\n"
        f"date: {now.strftime('%Y-%m-%d')}\n"
        f"time: {now.strftime('%H:%M')}\n"
        f"branch: {branch}\n"
        f"session_id: {session_id}\n"
        f"reason: {reason}\n"
        "tags: [claude-log]\n"
        f"failures: {failures}\n"
        "---\n\n"
    )
    try:
        target.write_text(fm + body + "\n")
        debug(f"wrote {target} (failures={failures})")
    except Exception as e:
        debug(f"write failed: {e}")
    return 0


def main():
    try:
        if len(sys.argv) >= 3 and sys.argv[1] == "--worker":
            return worker(sys.argv[2])
        return front()
    except Exception as e:
        debug(f"fatal (ignored): {e}")
        return 0


if __name__ == "__main__":
    sys.exit(main())
