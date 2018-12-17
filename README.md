# ConfigFile

個人的に使ってる環境設定用のファイルをまとめたものです。

## 使い方

リポジトリをホームディレクトリにクローンする

```
cd ~/
git clone https://github.com/TetsuyaNegishi/ConfigFile
```

シンボリックリンクをホームディレクトリ上に生成

```
./ConfigFile/link.sh
```

### git

.gitconfig.localをコピーしてホームディレクトリに生成

```
cp ConfigFile/gitconfig.local.example .gitconfig.local
```

.gitconfig.localの内部のnameとemailを適宜変更する

### brew

Brewfileのアプリをインストールする

```
brew bundle
```

### zsh

端末固有のコマンドを定義したいときは`~/.zshrc.local`に書く

## 参考

- [Web系エンジニア必須の環境設定　＜その１＞dotfilesをGitHubで管理](http://tango-ruby.hatenablog.com/entry/2017/02/07/235714)
- [.gitconfig で他のファイルを include](https://qiita.com/t_uda/items/c3fd33604c3888e64868)