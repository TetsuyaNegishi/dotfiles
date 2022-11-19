/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
curl "https://raw.githubusercontent.com/TetsuyaNegishi/ConfigFile/master/Brewfile" -O
brew bundle
rm -f Brewfile
