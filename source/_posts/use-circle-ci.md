---
title: Github Pages + Hexo + CircleCI + Heroku で自動デプロイ管理
tags:
  - CircleCI
  - Heroku
  - GitHub
categories: Web
date: 2016-05-30 23:38:49
---


IGGG 名古屋支部 支部長の ひげ です。  
今回も寂しく孤軍奮闘しております。  
嘘です。
Slack 使って騒いでるんで一人ではないです。  
早速プルリクエストあったし。

さて、今回は前言通り デプロイの自動化 を行いました。

実は GitHub Pages 利用する少し前に Slack 上で CI (継続的インテグレーション) について(ほんの少しだけ)話していて、
GitHub Pages の話題が上がったときに、CI の簡単な例がだよ、といつものお意見番が下記の記事を教えてくれました。

- [チームブログをGitHubとHexoではじめよう！](http://blog.otakumode.com/2014/08/08/Blogging-with-hexoio/)

早速、 ~~パクッて~~ 参考にしてみました！

## Goal
結局何をしたいのかというと

1. GitHub に大本である source ブランチを **プッシュしたら自動でデプロイ** してほしい
2. source ブランチ以外をプッシュした場合は **ステージ環境に自動でデプロイ** してほしい

の2点です。
前者の理由は単純に手間を省くためです。
後者の理由は、新しい記事の精査を実行環境のない人でも行えるようにです。

(まぁ本音は単純に私が面白そうだと思ったからですけど)

そのために、GitHub へのプッシュに対して自動でデプロイしてくれるサービスとステージング環境が必要です。  
前述した記事を参考にして、前者には [CircleCI](https://circleci.com/) を、後者には [Heroku](https://dashboard.heroku.com/) を利用したいと思います。  

**追記 (2016.6.2)**  
ブランチの構成を変更しました。
例の相談役さんがステージング環境へのデプロイが競合しないようにステージング用のブランチを作った方が良いと助言してくれました。
なので

- **source** master へ自動デプロイされるブランチ
- **staging** ステージング環境へ自動デプロイされるブランチ
- それ以外のブランチはデプロイされない

の構成に変更しました。
変更箇所は後述します。

## CircleCI
CircleCI は GitHub と連携して実行やテスト、デプロイなどを自動で行ってくれるサービスです。  
このように、プログラミングに付随する様々な作業を自動化して継続的に管理する事を **継続的インテグレーション** と言います(たぶん)。  
私はコノコトについてちゃんと勉強してないので、後は自分で調べてください(おい)

継続的インテグレーションをサポートするサービスは他にもイロイロあります。
CircleCI の特徴については以下のスライドでも見てください(おい)

- [はじめての CircleCI](http://www.slideshare.net/mogproject/circleci-51253223)

では順に準備を行っていきます。

## CircleCI の準備
CircleCI は既存の GitHub と認証を行います。  
今回は、私のアカウントを使う事にします。

まず、[公式サイト](https://circleci.com/) に行きます。
後は、Sign up のところを押して、ポチポチしていくだけです(ざっくり)。

登録が完了したら、GitHub の方で認証を行います(たぶん)。
[ココ](https://GitHub.com/integrations/circle-ci)に行って Add to GitHub を押せばいいはずです。

これで、CircleCI のダッシュボードに GitHub のリポジトリが出てくるはずです。

出てきたら、CircleCI で管理したいリポジトリを選択します。

選択すると早速リポジトリのビルドを始めようとしますが、設定ファイルを入れてないのでコケるはずです。

## Heroku
いったんハナシを脱線して Heroku について簡単に説明します。
Heroku とは **AWSのIaaS上に構築されたPaaSで、Gitでデプロイできたり、Webアプリの開発から公開までがミラクルスペシャルウルトラスーパーメガトン簡単にできるプラットフォーム** だそうです。
次のサイトに書いてありました。
残りは参照してください(おい)

- [Heroku導入メモ - GitHub](https://gist.GitHub.com/konitter/5370904)

と言っても、上記のサイトの情報は少し古く、料金体系が結構変わって、無料枠の容量の上限が 300MB に増えていたり、無料枠では日に6時間はスリープさせないといけなかったり、になっています。
そのうえ、また無料枠を変更するみたいです。

まぁ、詳しくは公式サイトを読めばいいんじゃないかな...(おいおい)

## Heroku の準備
イロイロと料金体系が変わっているみたいですが、(たぶん)ステージング環境としてならまだ使えそうなんで使っていきます。

まず、[公式サイト](https://dashboard.heroku.com/) にアクセスして、Sign Up します。  
**Pick your primary development language** は単純によく使うプログラミングを聞いてるだけです。

次に App を作成します。
[Heroku Toolkit](https://toolbelt.heroku.com/) をインストールして、下記コマンドを実行しても良いですし、ダッシュボードからでもできるはずです。

~~~
$ heroku login
$ heroku create
~~~

## CircleCI と Heroku を連携させる
[公式サイト](https://circleci.com/docs/continuous-deployment-with-heroku/) の指示に従って、CircleCI から Heroku を認証させます。

CircleCI のダッシュボードでリポジトリ固有のページに移動します。
そしたら、右上の `Project Settings` をクリックします。  
次に、左下の方にある `Heroku Deployment` をクリックします。

- **Step 1**
  CircleCI アカウントの[コノページ](https://circleci.com/account/heroku)に Heroku API Key を登録します。
  Heroku API Key は [Heroku のアカウントページ](https://dashboard-preview.heroku.com/account) の下の方にあります。
- **Strp 2**
  Heroku と SSH 認証を設定します。
  とはいっても、Heroku Deployment の Step 2 のところをクリックするだけで出来てしまいます。

後は、リポジトリに circle.yml という設定ファイルを置くだけです。

## circle.yml の作成
最初に紹介したサイトを参考にして、GitHub Pages 用のリポジトリに以下のような設定ファイル(circle.yml)を加えました。

~~~yaml
machine:
  timezone: Asia/Tokyo
  node:
    version: 4.4.5
deployment:
  production:
    branch: source
    commands:
      - git config --global user.name "IGGGorg"
      - git config --global user.email "contact@iggg.org"
      - git submodule init
      - git submodule update
      - ./node_modules/.bin/hexo clean
      - ./node_modules/.bin/hexo generate
      - ./node_modules/.bin/hexo deploy
  staging:
    branch: /.*/
    commands:
      - git config --global user.name "IGGGorg"
      - git config --global user.email "contcat@iggg.org"
      - ./node_modules/.bin/hexo clean
      - ./node_modules/.bin/hexo generate
      - ./node_modules/.bin/hexo deploy --branch $CIRCLE_BRANCH --config _staging_config.yml
general:
  branches:
    ignore:
      - master
test:
  override:
    - echo "test"
~~~

source ブランチか、それ以外かでデプロイ内容を分けています。  
但し、ページ自体のブランチである、master ブランチは無視するように下の方に書いてあります。
`hexo deploy --branch $CIRCLE_BRANCH --config _staging_config.yml` とすることで、デプロイの際に参照する Hexo の設定ファイルを `_staging_config.yml` に指定できます。

**追記 (2016.6.2)**  
前述したとおり、ブランチ構成を変更したので、上記の circle.yml を一部書き換えました。

~~~diff
staging:
-     branch: /.*/
+     branch: staging
  commands:
~~~

追記終わり。


次に、その設定ファイル(`_staging_config.yml`)を加えましょう。
またもや、例のサイトを参考にして、`deployment` のところを次のように書き換えます。

~~~yml
# Deployment
## Docs: https://hexo.io/docs/deployment.html
deploy:
  type: heroku
  repo: git@heroku.com:<作成したAPP名>.git
~~~

更に、上の方の `url:` も書き換えておきましょう。  

## package.json ファイルの書き換え
最後に、`package.json` を書き換えます。

Hexo で Heroku にデプロイするには専用のパッケージ、`hexo-deployer-heroku` が必要です。  
`package.json` の `"dependencies":` に書き加えましょう。

## push !
後はプッシュするだけのはずです ！

**追記 (2016.6.2)**  
もし、source ブランチの自動デプロイで ssh 鍵について怒られた場合は以下のページを参考にしてください。

- [Adding read/write deployment key - CircleCI](https://circleci.com/docs/adding-read-write-deployment-key/)

たぶん、hexo でデプロイするときに master の内容を完全に入れ替えてるため、ssh鍵に write 権限が無くて怒られるようです。
手順通りに、Github で新しい ssh 鍵を生成して、CircleCI に公開鍵を登録すればいいはずです。
ちなみに、Github で鍵を生成する際にパスフレーズを付けないようにと注意書きされてます。
まぁ、こっちは秘密鍵を Github サンで管理するから安全で、付けなくてもいいのかな。

## おわりに

実は、こういうサービスいじるの初めてでして、まぁまぁてこずりました(笑)

IGGG のみんな、つかってくれるとうれしいなぁ。
