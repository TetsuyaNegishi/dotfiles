function cw
  set VSCODE_WORKSPACE "$HOME/vscode-workspace"
  ls $VSCODE_WORKSPACE | peco | read BUFFER
	code "$VSCODE_WORKSPACE/$BUFFER"

  set REPOSITORY_PATH "$VSCODE_WORKSPACE/$(cat "$VSCODE_WORKSPACE/$BUFFER" | jq -r '.folders[0].path')"
  cd $REPOSITORY_PATH
end

