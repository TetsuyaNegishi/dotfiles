#!/bin/bash

cd `dirname $0`

CURRENT_DIR=`pwd`

mkdir -p ~/vscode-workspace
mkdir -p ~/ScreenShot

ln -sf "$CURRENT_DIR/fish" ~/.config/

ln -sf "$CURRENT_DIR/launchd/com.user.brewupgrade.plist" ~/Library/LaunchAgents/

ln -sf "$CURRENT_DIR/git/.gitconfig" ~/.gitconfig
ln -sf "$CURRENT_DIR/git/.gitignore_global" ~/.gitignore_global

echo "==== setup gitconfig ==="
cp -f ./git/.gitconfig.local.example ~/.gitconfig.local
read -p "name: " name
sed -i -e "s/<name>/$name/" ~/.gitconfig.local
read -p "email: " email
sed -i -e "s/<email>/$email/" ~/.gitconfig.local

source ./macOS

echo "/usr/local/bin/fish" >> /etc/shells
chsh -s /usr/local/bin/fish
