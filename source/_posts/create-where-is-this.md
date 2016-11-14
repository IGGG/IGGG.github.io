---
title: ジオタグ解析アプリを作りました
date: 2016-10-19 19:41:38
tags:
- Heroku
- Ruby
- guntohfes
categories: Application
---

IGGG 名古屋支部 支部長の ひげ です。  
前回に続いて今回も群大理工学部の学園祭 [群桐祭](http://guntohfes.com/) のイベント、テクノドリームツアー用に作成した、ジオタグ解析アプリ、Where-is-This (名前は適当)について紹介したいと思います。

## Where-is-This とは

画像を与えると、画像の位置情報を解析して、Google Map にマッピングした情報が返ってくるというモノです。

![送信前(左)と送信後(右)](/images/create-where-is-this/whereisthis.jpg)

このプログラム自体は IGGG の期待の新星 [atpons](https://github.com/atpons) くんが10分くらいでこしらえてくれたものです(はやい)。
それを少しだけ修正して IGGG の [Heroku](https://dashboard.heroku.com/) にあげました。

[ココ](https://where-is-this.herokuapp.com/) でアクセスできますが、無料枠なんでアクセスが集中すると止まると思います。

コンセプトとしては、来場者に画像には位置情報が含まれているということを知ってもらおうというモノでした。
画像には位置情報が含まれていて、撮った場所を特定することできる。
なので、外にあげるときは気を付けよう、という感じです(まぁ最近のSNSは位置情報の部分を消されちゃうらしいですが)。

実はこのアプリ、結局のところ本番では、運用する余裕が無くて(テクノってすごく忙しいんです)、用意はしたのですが、使いませんでした...(ごめんね atpons)

(いいわけではないですけど、ジオタグがどーのこーのと説明する時間が無くて)

## 実装

別に私が作ったわけじゃないけど、ドヤ顔で紹介します。

Ruby で書かれていて、なんとたったの15行しかない！
流石 Ruby ですねぇ。

```ruby
require "sinatra"
require "exifr"

get "/" do
  erb :index
end

post "/upload" do
  if params[:file]
    file = EXIFR::JPEG.new(params[:file][:tempfile].path)
    @latitude = file.gps.latitude
    @longitude = file.gps.longitude
  end
  erb :upload
end
```

### Sinatra

2つのライブラリを使っています。
その一つが [Sinatra](http://www.sinatrarb.com/) です。
(公式サイト曰く) Sinatra は

> Sinatraは最小の労力でRubyによるWebアプリケーションを手早く作るためのDSL

だそうです。
Model View Controller（MVC）に基づかない設計で作成されており、小さく、柔軟性があるプログラミングが可能となるよう意識されている、そうです(wikipedia より)。

正直、Sinatra の仕組みについてちっっっとも知りませんが、なんとなく読める通りに動くのでしょう(適当)。

流石 Ruby ですねぇ。

### Exifr

もう一つが [Exifr](https://github.com/remvee/exifr) です。
察しの付く通り、Exif Reader ですね。
位置情報を含む画像の [Exif](https://ja.wikipedia.org/wiki/Exchangeable_image_file_format) をすごく簡単に取得するためのライブラリ群です。

上のコードの10-12行目が exifr に相当します。
正直、こっちも仕組みについてはちっっっとも知りませんが、なんとなく読める通りに動くのでしょう(適当)。

流石 Ruby ですねぇ(それしか言ってない)。

### 修正

Heroku にあげるために以下の点を修正しました。

- 次のように書かれた config.ru を作成
  - atpons のはローカルで動かすまでだったので無かった。
  - コレがないと Heroku とかではデプロイしても動かない(当たり前？)

```ruby
require 'bundler'
Bundler.require

require './app'
run Sinatra::Application
```

- Google Map の URL を HTTPs に変更
  - Heroku の URL が HTTPs なので、変更しないと動かないみたい

### その他

Heroku へのデプロイはググれば出てくる一般的な方法([こういうのとか](http://please-sleep.cou929.nu/deploy-sinatra-app-to-heroku.html))でできました。
ただ、Heroku のリモートリポジトリと、GitHub のリモートリポジトリで、そこら辺の知識なくて、ごっちゃんになり苦労しました。

## おわりに

正直、これ以上書くことないです。
すごく簡単なんで。

流石 Ruby ですねぇ。
