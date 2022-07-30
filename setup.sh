#!/bin/bash

cd `dirname $0`

CURRENT_DIR=`pwd`

mkdir -p ~/vscode-workspace
mkdir -p ~/ScreenShot

ln -sf "$CURRENT_DIR/fish" ~/.config/fish

ln -sf "$CURRENT_DIR/gitconfig" ~/.gitconfig
ln -sf "$CURRENT_DIR/gitignore_global" ~/.gitignore_global

echo "==== setup gitconfig ==="
cp ./gitconfig.local.example ~/.gitconfig.local
read -p "name: " name
sed -i -e "s/<name>/$name/" ~/.gitconfig.local
read -p "email: " email
sed -i -e "s/<email>/$email/" ~/.gitconfig.local

source ./macOS

sed -e "s|<home>|$HOME|g" ./crontab > ./crontab_tmp
crontab ./crontab_tmp
rm ./crontab_tmp

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
brew bundle
