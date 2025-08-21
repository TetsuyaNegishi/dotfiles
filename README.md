# ConfigFile

個人的に使ってる環境設定用のファイルをまとめたものです。

## 使い方

homebrew関連のセットアップ

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
sudo curl "https://raw.githubusercontent.com/TetsuyaNegishi/dotfiles/master/scripts/brew-install.sh" | bash
```

リポジトリをホームディレクトリにクローンする

```
ghq get https://github.com/TetsuyaNegishi/dotfiles
```

setup.shを実行

```
cd path/to/dotfiles
./setup.sh
```

## 参考

- [Web系エンジニア必須の環境設定　＜その１＞dotfilesをGitHubで管理](http://tango-ruby.hatenablog.com/entry/2017/02/07/235714)
- [.gitconfig で他のファイルを include](https://qiita.com/t_uda/items/c3fd33604c3888e64868)
