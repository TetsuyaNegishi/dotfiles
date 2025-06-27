alias la='ls -a'
alias ll='ls -l'
alias lla='ls -la'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

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

# yarn
alias y='yarn'
alias ys='y start'
alias ya='y add'

## マージ済みのローカルブランチをすべて削除
alias gbd='git branch --merged|egrep -v "\*|develop|master"|xargs git branch -d'
## プルリクエスト作成
alias gpr='git push -u origin $(git symbolic-ref --short HEAD) && hub browse -- compare/$(git symbolic-ref --short HEAD)'

alias cdghq='cd $(ghq root)/$(ghq list | peco)'
alias relogin='exec $SHELL -l'

# git worktree
function gw
    git worktree add -b $argv[1] ./.git-worktree/$argv[1]
end
