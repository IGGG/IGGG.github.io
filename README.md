# IGGG.github.io
GitHub Pages for IGGG  
このブランチはページ構築用のリソースブランチです。

[公式サイト](http://www.iggg.org/) や [IGGG Wiki](http://www.iggg.org/wiki/) では書きにくい、技術よりなネタをこのページ書いていこうかなー、と思ってます。  
By ひげ

## ブランチの構成と管理
- **master**
  GitHub Pages は master ブランチのHTMLファイルからページを構築します。
  うちは Hexo 使って自動生成してるので、**このブランチは直接いじらないで**
- **source**
  ページ構築用の本流ブランチです。
  このブランチの更新が自動で master にデプロイされます。
- **staging**
  ステージング環境用のブランチです。
  このブランチの更新が自動でステージング環境にデプロイされます。

基本的に **staging ブランチをクローンして、そこから新しくブランチを切ってから、新しい記事を作成してください。**
その後、プルリクエストを送ってくれれば staging ブランチにマージし、ステージング環境で確認します。
ステージング環境で問題が無い、あった場合は修正をして、source ブランチにマージします。

## 準備
ローカルでビルドする方法として、めちゃくちゃ基本的なことも含めて説明します。
[Docker を使う方法](#docker)もあります。

### 1. GitHub アカウントの作成と
してください。  
[公式サイト](https://github.com/)で適当にポチポチしてけば出来るはずです。  
登録したら、**GitHub の IGGGグループに参加** させてもらってください。  
noob とか gion あたりに聞けばいいよ。

### 2. git コマンドのインストール
各OSで適当にやってください．  
Windows なら [Git for Windows](https://git-for-windows.github.io/) でいいんじゃないんかな。
ついでに、クライアントアプリとしてAtlassian の [SourceTree](https://ja.atlassian.com/software/sourcetree) も入れるといいんじゃないかな。  
後者は任意です。

### 3. SSH Key の作成と登録
SSH Key を作成(持ってたらもちろんいらない)して public key を GitHub に登録してください。
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
というか、Hexo の基本的なコマンドを書いとくよ。
現在は **staging ブランチ** に居ると仮定します。

- 新しいページ用のブランチを作成
- 新しいページを作成
```
$ hexo new <title>
```
- ローカルで確認
```
$ hexo server
```
して、ブラウザで `localhost:4000` に接続すればいい
- GitHub に **新しく作成したブランチ** をプッシュ
- GitHub で **staging ブランチ** にプルリクエスト
- プルリクエストが承認されたらステージング環境で確認し問題なければ **source ブランチ** にプルリクエスト
- プルリクエストが承認されると master ブランチ(本番環境)にデプロイされる

~~テーマやら何やらの変え方はまだわからない。~~ テーマは変えました。
少しずつ調べます。  
プラグイン入れることでもっといろんなコトできるらしい。

ちなみに利用できるテーマ一覧は[こちら](https://github.com/hexojs/hexo/wiki/Themes)

## 注意点
***Hexo コマンドでのデプロイはしないでください。***

以下のコマンドのことです。

```
$ hexo generate -deploy
```

このコマンドを実行すると **いっきに master ブランチにデプロイ** されます。
しかし、もし実行しても CircleCI をいじればすぐ治せるはずなので、焦らず Slack で報告してください。

## Docker

Docker を使う場合は、準備手順の 4,5,8 を行う必要はありません。
それ以外を行い、Dockerをインストールしたうえで、

```
$ docker-compose up -d
```

とすれば起動できます(`-d` オプションでバックグランドで起動するようになる)。

また、起動した Dockerコンテナの ID が `ffb4277f8ee4` であるならば、

```
$ docker exec ffb4277f8ee4 hexo new test
INFO  Created: /app/source/_posts/test.md
```

で `./source/_posts/test.m` に新しい記事が作成できます。
