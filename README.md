# IGGG.github.io
Github Pages for IGGG  
このブランチはページ構築用のリソースブランチです。

[公式サイト](http://www.iggg.org/) や [IGGG Wiki](http://www.iggg.org/wiki/) では書きにくい、技術よりなネタをこのページ書いていこうかなー、と思ってます。  
By ひげ

## 準備
めちゃくちゃ基本的なことも含めて説明します。

### 1. Github アカウントの作成と
してください。  
[公式サイト](https://github.com/)で適当にポチポチしてけば出来るはずです。  
登録したら、**Github の IGGGグループに参加** させてもらってください。  
noob とか gion あたりに聞けばいいよ。

### 2. git コマンドのインストール
各OSで適当にやってください．  
Windows なら [Git for Windows](https://git-for-windows.github.io/) でいいんじゃないんかな。
ついでに、クライアントアプリとしてAtlassian の [SourceTree](https://ja.atlassian.com/software/sourcetree) も入れるといいんじゃないかな。  
後者は任意です。

### 3. SSH Kye の作成と登録
SSH Key を作成(持ってたらもちろんいらない)して public key を Github に登録してください。
作成方法は適当にググってもらってもいいんだけど....

1. `$ ssh-keygen -t rsa -C "<mail address>"` でカギを生成  
  ~~このとき、パスフレーズは設定しないようにしてください。~~  
  セキュリティ上パスフレーズの設定はしましょう
2. windows なら `$ clip < ~/.ssh/id_rsa.pub` でクリップボードに公開鍵をコピーして
3. https://github.com/settings/keys の右上の `New SSH key` を押して、下の Key の欄にペースト(title は何でもいい)

`$ ssh -T git@github.com` でエラーが吐かれなければ問題なし(吐かれた場合はIGGG Slackで聞いて)．

Note
:   デプロイ時に `Error: Permission denied (publickey).` と怒られた場合、パスフレーズが原因の可能性が高いです。
    `ssh-agent` を起動し、`ssh-add <privatekey>` を入力して秘密鍵を登録することで回避できます。

### 4. Node.js をインストール
[公式サイト](https://nodejs.org/en/)で直接インストールしてもいいし，[nodist](https://github.com/marcelklehr/nodist) のようなバージョン管理ツールからインストールしてもいい。
好きにして。  

### 5. Hexo をインストール
`$ npm install hexo` でおしまい。

### 6. IGGG.github.io をクローン
してください。  
コマンドでやってもいいし、SourceTree でやってもいいです。

### 7. source ブランチへチェックアウト
してください。  
もしかしたらする必要ないかも。

### 8. npm module をインストール
クーロンしたディレクトリでコンソール(コマンドプロンプトやパワーシェルでも)を開いて
```
$ npm install
```
を入力する。  
以上で準備完了

## 編集
というか、Hexo の基本的なコマンドを書いとくよ

- 新しいページを作成
```
$ hexo new <title>
```
- ローカルで確認
```
$ hexo server
```
して、ブラウザで `localhost:4000` に接続すればいい
- Github にデプロイ
```
$ hexo generate -deploy
```

テーマやら何やらの変え方はまだわからない。  
少しずつ調べます。  
プラグイン入れることでもっといろんなコトできるらしい。

ちなみに利用できるテーマ一覧は[こちら](https://github.com/hexojs/hexo/wiki/Themes)
