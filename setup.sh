#!/bin/bash

cd `dirname $0`

CURRENT_DIR=`pwd`

mkdir -p ~/vscode-workspace
mkdir -p ~/ScreenShot
mkdir -p ~/Library/dotfiles

ln -sfn "$CURRENT_DIR/scripts" ~/Library/dotfiles
ln -sfn "$CURRENT_DIR/fish" ~/.config/
ln -sfn "$CURRENT_DIR/alacritty" ~/.config/
ln -sfn "$CURRENT_DIR/tmux" ~/.config/
ln -sfn "$CURRENT_DIR/hammerspoon" ~/.hammerspoon

ln -sfn "$CURRENT_DIR/git/.gitconfig" ~/.gitconfig
ln -sfn "$CURRENT_DIR/git/.gitignore_global" ~/.gitignore_global

cat "$CURRENT_DIR/launchd/com.user.brewupgrade.plist" > ~/Library/LaunchAgents/com.user.brewupgrade.plist
cat "$CURRENT_DIR/launchd/com.user.cleanup-files.plist" | sed "s|\$HOME|$HOME|g" > ~/Library/LaunchAgents/com.user.cleanup-files.plist

if [ ! -f ~/.gitconfig.local ]; then
    echo "==== setup gitconfig ==="
    cp -f ./git/.gitconfig.local.example ~/.gitconfig.local
    read -p "name: " name
    sed -i -e "s/<name>/$name/" ~/.gitconfig.local
    read -p "email: " email
    sed -i -e "s/<email>/$email/" ~/.gitconfig.local
fi

source ./macOS

if ! grep -q "/usr/local/bin/fish" /etc/shells; then
    echo "/usr/local/bin/fish" | sudo tee -a /etc/shells
fi

if [ "$SHELL" != "/usr/local/bin/fish" ]; then
    chsh -s /usr/local/bin/fish
fi
