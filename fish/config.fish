if status is-interactive
    # Commands to run in interactive sessions can go here
end

function fish_user_key_bindings
    bind \cr peco_select_history
end

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
