# License : MIT
# http://mollifier.mit-license.org/

########################################
## Environment variable configuration
#
# LANG
#文字コード設定
export LANG=ja_JP.UTF-8

#ローカルのzshrcを読み込む
source ~/.zshrc.local

# auto directory pushd that you can get dirs list by cd -[tab]
#  historyの自動保管
#  cd -[tab]でcdのhistoryを閲覧できる
#setopt auto_pushd

# command correct edition before each completion attempt
#コマンドをtypoしたときに聞きなおしてくれる
setopt correct

# compacked complete list display
#表示を詰めてくれる
setopt list_packed

# 色を使用出来るようにする
autoload -Uz colors
colors

# emacs 風キーバインドにする
bindkey -e

# ヒストリの設定
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000

# プロンプト
# 1行表示
# PROMPT="%~ %# "
# 2行表示
PROMPT="%{${fg[green]}%}[%n]%{${reset_color}%} %~
%# "


# 単語の区切り文字を指定する
autoload -Uz select-word-style
select-word-style default
# ここで指定した文字は単語区切りとみなされる
# / も区切りと扱うので、^W でディレクトリ１つ分を削除できる
zstyle ':zle:*' word-chars " /=;@:{},|"
zstyle ':zle:*' word-style unspecified

########################################
# 補完
# 補完機能を有効にする
autoload -Uz compinit
compinit

# 補完で小文字でも大文字にマッチさせる
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ../ の後は今いるディレクトリを補完しない
zstyle ':completion:*' ignore-parents parent pwd ..

# sudo の後ろでコマンド名を補完する
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin \
                   /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin

# ps コマンドのプロセス名補完
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'


########################################
# vcs_info
autoload -Uz vcs_info
autoload -Uz add-zsh-hook

zstyle ':vcs_info:*' formats '%F{green}(%s)-[%b]%f'
zstyle ':vcs_info:*' actionformats '%F{red}(%s)-[%b|%a]%f'

function _update_vcs_info_msg() {
    LANG=en_US.UTF-8 vcs_info
    RPROMPT="${vcs_info_msg_0_}"
}
add-zsh-hook precmd _update_vcs_info_msg

########################################
# オプション
# 日本語ファイル名を表示可能にする
setopt print_eight_bit

# beep を無効にする
setopt no_beep

# フローコントロールを無効にする
setopt no_flow_control

# Ctrl+Dでzshを終了しない
setopt ignore_eof

# '#' 以降をコメントとして扱う
setopt interactive_comments

# ディレクトリ名だけでcdする
setopt auto_cd

# cd したら自動的にpushdする
setopt auto_pushd
# 重複したディレクトリを追加しない
setopt pushd_ignore_dups

# 同時に起動したzshの間でヒストリを共有する
setopt share_history

# 同じコマンドをヒストリに残さない
setopt hist_ignore_all_dups

# スペースから始まるコマンド行はヒストリに残さない
setopt hist_ignore_space

# ヒストリに保存するときに余分なスペースを削除する
setopt hist_reduce_blanks

# 高機能なワイルドカード展開を使用する
setopt extended_glob

########################################
# キーバインド

# ^R で履歴検索をするときに * でワイルドカードを使用出来るようにする
bindkey '^R' history-incremental-pattern-search-backward

########################################
# エイリアス

alias la='ls -a'
alias ll='ls -l'
alias lla='ls -la'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias mkdir='mkdir -p'

# sudo の後のコマンドでエイリアスを有効にする
alias sudo='sudo '

# グローバルエイリアス
alias -g L='| less'
alias -g G='| grep'

# git
alias g='git'
alias gs='g st'
alias ga='g ad'
alias gap='g ad -p'
alias gb='g br'
alias gd='g df'
alias gdc='g dfc'
alias gco='g co'
alias gcom='g co -m'
alias gch='g ch'
alias gchm='g ch master'
alias gchd='g ch develop'
alias gpl='g pl'
alias gps='g ps'
alias gl='g l'
alias gsw='g sw'

## マージ済みのローカルブランチをすべて削除
alias gbd='git branch --merged|egrep -v "\*|develop|master"|xargs git branch -d'
## プルリクエスト作成
alias gpr='git push -u origin $(git symbolic-ref --short HEAD) && hub browse -- compare/$(git symbolic-ref --short HEAD)'

# translate
alias ten='trans -b :en'

# hub
function git(){hub "$@"}

# yarn
alias y='yarn'
alias ys='y start'
alias ya='y add'

# C で標準出力をクリップボードにコピーする
# mollifier delta blog : http://mollifier.hatenablog.com/entry/20100317/p1
if which pbcopy >/dev/null 2>&1 ; then
    # Mac
    alias -g C='| pbcopy'
elif which xsel >/dev/null 2>&1 ; then
    # Linux
    alias -g C='| xsel --input --clipboard'
elif which putclip >/dev/null 2>&1 ; then
    # Cygwin
    alias -g C='| putclip'
fi

#保管色付け
zstyle ':completion:*' list-colors 'di=34' 'ln=35' 'so=32' 'ex=31' 'bd=46;34' 'cd=43;34'

#cdとlsの省略
setopt auto_cd
function chpwd() { ls }

#cdなしでディレクトリ名を直接指定して移動し、移動後自動でlsする
setopt auto_cd
function chpwd() { ls }

#
# Goolge Search by Google Chrome
# terminalからググったりqiita検索をできる
#
google() {
    local str opt
    if [ $# != 0 ]; then
        for i in $*; do
            # $strが空じゃない場合、検索ワードを+記号でつなぐ(and検索)
            str="$str${str:++}$i"
        done
        opt='search?num=100'
        opt="${opt}&q=${str}"
    fi
    open -a Google\ Chrome http://www.google.co.jp/$opt
}

qiita() {
    local str opt
    if [ $# != 0 ]; then
        for i in $*; do
            # $strが空じゃない場合、検索ワードを+記号でつなぐ(and検索)
            str="$str${str:++}$i"
        done
        opt='search?num=100'
        opt="${opt}&q=${str}"
    fi
    open -a Google\ Chrome http://qiita.com/$opt
}

## Completion configuration
#
#予測変換
# autoload predict-on
# predict-on

# autoload -U compinit
# compinit

#カレントディレクトの表示方法がルートからすべて表示される
#PROMPT="%/%% "
#PROMPT2="%_%% "
SPROMPT="%r is correct? [n,y,a,e]:] "


#ls色付け
export LSCOLORS=exfxcxdxbxegedabagacad
export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
########################################
# OS 別の設定
case ${OSTYPE} in
    darwin*)
        #Mac用の設定
        export CLICOLOR=1
        alias ls='ls -G -F'
        ;;
    linux*)
        #Linux用の設定
        alias ls='ls -F --color=auto'
        ;;
esac

# vim:set ft=zsh:

# vscodeをコマンドラインから起動させる
code () { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $* ;}

# nodebrewの設定
export PATH=$HOME/.nodebrew/current/bin:$PATH

# pecoで過去のコマンド履歴を検索
function peco-select-history() {
  BUFFER=$(\history -n -r 1 | peco --query "$LBUFFER")
  CURSOR=$#BUFFER
  zle clear-screen
}
zle -N peco-select-history
bindkey '^r' peco-select-history

# z
. `brew --prefix`/etc/profile.d/z.sh

alias cdghq='cd $(ghq root)/$(ghq list | peco)'

# pecoでVSCodeのworkspaceを検索
# workspaceを'~/vscode-workspace'に保存すること
function peco-vscode-workspace() {
  VSCODE_WORKSPACE="${HOME}/vscode-workspace"
  BUFFER=$(ls ${VSCODE_WORKSPACE} | peco )
  CURSOR=$#BUFFER
  code "${VSCODE_WORKSPACE}/${BUFFER}"
  REPOSITORY_PATH="${VSCODE_WORKSPACE}/$(cat "${VSCODE_WORKSPACE}/${BUFFER}" | jq -r '.folders[0].path')"
  cd $REPOSITORY_PATH
}
zle -N peco-vscode-workspace
alias cw=peco-vscode-workspace
