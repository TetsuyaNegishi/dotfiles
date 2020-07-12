#!/bin/bash

ln -sf ~/ConfigFile/zshrc ~/.zshrc
ln -sf ~/ConfigFile/gitconfig ~/.gitconfig
ln -sf ~/ConfigFile/Brewfile ~/Brewfile
ln -sf ~/ConfigFile/gitignore_global ~/.gitignore_global

mkdir ~/vscode-workspace

echo "==== setup gitconfig ==="
cp ./gitconfig.local.example ~/.gitconfig.local
read -p "name: " name
sed -i -e "s/<name>/$name/" ~/.gitconfig.local
read -p "email: " email
sed -i -e "s/<email>/$email/" ~/.gitconfig.local
