---
title: サムネイルを表示したい
date: 2016-12-03 15:55:01
tags:
  - JavaScript
  - HTML
categories: Web
cover: "/images/vs-thumbnail/before_after.png"
photos: "/images/vs-thumbnail/before_after.png"
---

IGGG 名古屋支部のひげです。
(そろそろ、他の人にも書いてほしいなーと思ってます。)

たまにはラフな話題を。

## かなしい

現在、[IGGG アドベントカレンダー](http://www.adventar.org/calendars/1572)をやっていて、このサイトをリンクさせたりしてたのですが...

![サムネがうまく表示されない](/images/vs-thumbnail/error_thumbnail.jpg)

## 結局

今使ってるテーマこのテーマには `cover` というパラメータがあって、それを設定してあげればよかっただけ...

```yaml
---
title: サムネイルを表示したい
date: 2016-12-03 15:55:01
tags:
  - JavaScript
categories: Web
cover: "/images/vs-thumbnail/before_after.png"
photos: "/images/vs-thumbnail/before_after.png"
---
```

デフォルトの設定がされてなかったのでエラーが出てた。
なので、`_config.yaml` に `cover: /IGGG_l.png` を追加した。

## 試行錯誤

こっからは無駄な試行錯誤...

サムネイル画像はそもそもどーやって決めてるのか分らなかったので、[去年のカレンダー](http://www.adventar.org/calendars/1137)を見て考えた。

なんとなく、一番最初の `img` タグをチェックしてるみたいだった(ホントはそれだけでは無かった)。

で、このサイトの最初の `img` タグの中身が空 `<img src="">` なのが問題なのかと思って(違う)、これを修正した。

## VS. 空の `img` タグ

この原因はココ

```html
<article class="<%= item.layout %>">
  <% if (item.photos){ %>
    <%- partial('post/gallery') %>
  <% } %>
  <div class="post-content">
```

本来、`photos` というパラメータが設定されてなければ書かれないはずなのだが、なぜか if 以下が実行される。
おそらく、デフォルトで食う文字が設定されている。

どこで設定されてるかは分らなかったので愚直に、

```html
<article class="<%= item.layout %>">
  <% if (item.photos && item.photos != ""){ %>
    <%- partial('post/gallery') %>
  <% } %>
  <div class="post-content">
```

とした。

***が直らない*** (そりゃそう)

ちなみに、このテーマは `photos` パラメータを設定すると、この記事の冒頭みたいな画像ギャラリーが出てくる。
知らなんだ。

## VS. 相対パス

きっと原因は画像のパスが相対パスに違いない！と思って(違う)、絶対パスの `img` タグを HTML ファイルの冒頭に埋め込むことにした。

`_config.yaml` に `url` として書いてあるのでそれと、`thumbnail` というパラメータを加えて

```html
<div class="thumbnail">
  <img src="<%- config.url %><%- item.thumbnail %>">
</div>
```

と頭に書いてみた。
CSS で `thumbnail` クラスの `display` パラメタを `none` にすれば画像は出てこない。

うまく、HTMLは埋め込めた。

***が直らない*** (そりゃそう)

## 急がば回れ

手詰まりになったので、 ***ちゃんと*** エラーのところを見ることにした(最初からそうしろ)。

`https://iggg.github.io/2016/12/01/adventar-slack-bot/undefined` が無いと怒られている...

undefined ... ?

HTML ソースコードを見ると

```html
 <meta property="og:image" content="undefined" />
```

おまえかー

ということで、これを設定しているコードを調べてみると

```html
<% if(page.cover) { %>
  <meta property="og:image" content="<%= page.cover %>" />
<% } else { %>
  <meta property="og:image" content="<%= config.cover %>"/>
<% } %>
```

あー、`cover` というパラメータがあるのね...
undefined が返ってたのは `_config.yaml` に `cover` が設定してなかったせいか...

前述したとおり、`_config.yaml` と記事の `cover` パラメータをちゃんと設定したら表示された。

![](/images/vs-thumbnail/ok_thumbnail.jpg)

## おしまい

こんなしょーもない事に4時間もかけてしまった...orz
