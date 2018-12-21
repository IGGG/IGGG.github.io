---
title: iggg.org を移行する
date: 2018-12-22 00:00:00
tags:
- WordPress
- GitHub
- Hugo
categories: Web
photos:
cover: "/images/replace_iggg_org/new-iggg-org.jpg"
---

本記事は[IGGG アドベントカレンダー 2018](http://www.adventar.org/calendars/3217) 22日目の記事です。

本記事では前々からやろうとしていた [iggg.org](https://iggg.org) の移行作業について書こうと思います。
現状ほとんど出来上がっていて、あとは細かいところの確認とドメインの変更を残すだけです。
GitHub Pages としてホストしており、下記URLよりアクセスできます。

- [https://iggg.github.io/new.iggg.org](https://iggg.github.io/new.iggg.org/)

## なぜ移行するか

現在(2018/12/22) iggg.org はさくらのマシン上で WordPress を使って動いています。
諸々運用・管理がめんどくさくなってきた(アクティブな部員も少なってきたし)ので、(更新しなければ)運用コストゼロの静的サイトにしてしまおうとなったのです。

## 移行作業

実はうちには IGGG/management という議論用のプライベートリポジトリがあります。
作業はだいたい、そこの Issue に書いてあります。

![](/images/replace-iggg-org/issue.png)

社会人になってから Issue に途中作業を雑に書き連ねていく癖がついた。

### データを抽出

まずは WP にあるデータを抽出する必要があります:

- 記事のデータ: 可能なら Markdown として
- メディア系(主に画像)

記事のデータは最初 `wordpress-to-jekyll-exporter` を使おうとしましたが、なんかうまくいかず断念。
そこで以下の記事を参考にして抽出しました:

- [WordPress の Markdown 移行補助ツールを開発してみた - アカベコマイリ](http://akabeko.me/blog/2016/03/npm-wpxml2md-v1-0-0-release/)

結構古い記事ですが、ちゃんと動作しました。
記事自体は xml2md という自作ツールの紹介ですが、中盤に WordPress を XML としてエクスポートする方法が書かれています。
ただ、変な Markdown になっていたり、いらないページまで Markdown になっていたりするので、そこは手作業で間引きます。

さて、次にメディア系です。
メディア系の抽出にか以下の記事を参考にしました:

- [Wordpressのメディアファイルを一括ダウンロードするプラグイン「Export Media Library」｜Knowledge Base](https://www.momosiri.info/wppi/export-media-library/)

このプラグインを利用してローカルにダウンロードしました。
あとはこれらを適当に git リポジトリに入れてプッシュすれば抽出完了。

### Hugo

静的サイトジェネレーターには Hugo を使いました。
このサイトは Hexo (JS 製)だし、他の IGGG のサイトは Jekyll (Ruby 製)なのですが、せっかくなので使ったことないものを選択してみました。

CSS 職人になって WordPress で利用してたテーマを再現するのは苦行なので、なんとなく構造が似て入ればいいかなぐらいの気持ちで作ります。
そのため、なんとなく構造を再現できそうなテーマをベースとして選びました:

- [Hugo Theme Dopetrope｜Hugo Themes](https://themes.gohugo.io/hugo-theme-dopetrope/)

Hugo 利用するテーマをサブモジュールとして設定するみたいです(多分)。
なので、テーマをカスタマイズするためにベースにしたいテーマをフォークしました:

- [IGGG/hugo-theme-dopetrope - GitHub](https://github.com/IGGG/hugo-theme-dopetrope)

基本的にうちのサイトのホームには:

- 上部にナビゲーター
- 画像スライダー
- 最近の記事の更新
- IGGGについての説明
- イベントボード
- Twitter タイムライン

があります。
ナビゲーターは dopetrope のものを利用しています。
ただし，config からナビゲーターの要素を[次](https://github.com/IGGG/new.iggg.org/blob/c9498f8d30c3ca441708c51493282b12727853e4/config.toml#L15-L67)のように指定できるように変更しました:

```toml
[params.pages.home]
    title = "Home"
    link  = "/"
    internal = true
    order = 0

[params.pages.about]
    title = "About"
    link  = "/about"
    internal = true
    order = 1

...

[params.pages.wiki]
    title = "Wiki"
    link  = "https://www.iggg.org/wiki/?FrontPage"
    internal = false
    order = 5
```

順番をうまくコントロールすることができなかったので `order` というパラメタを持たせています。
呼び出し側は[次](https://github.com/IGGG/hugo-theme-dopetrope/blob/cd4ae533e9e1fdedfecfebb84bca4a3d43d0a787/layouts/partials/nav.html)のようになります:

```html
<nav id="nav">
    {{ $title   := .Page.Title }}
    {{ $relLink := .Page.RelPermalink }}
    {{ $baseUrl := .Site.BaseURL }}
    <ul>
        {{ range $page := sort .Site.Params.Pages "order" }}
            {{ if $page.internal }}
            <li {{ if or (eq $title $page.title) (eq $relLink $page.link) }} class="current" {{ end }}>
              <a href="{{ $baseUrl }}{{ $page.link }}">{{ $page.title }}</a>
            </li>
            {{ else }}
            <li><a href="{{ $page.link }}">{{ $page.title }}</a></li>
            {{ end }}
        {{ end }}
    </ul>
</nav>
```

`sort` 関数に配列とパラメタ名を渡すと、そのパラメタでソートしてイテレーターに渡してくれます。
Hugo のテンプレートには結構リッチな組み込み関数が多いので面白いですね．
結構詰まったのがスコープです。
`$baseUrl := .Site.BaseURL` のように `range` の外で変数に定義しないと、`range` の中で `.Site.BaseURL` を呼び出しても想定通り取得できません(もしかしたら別の方法があるかも)。

画像のスライダーには [balaramadurai/hugo-travelify-theme](https://github.com/balaramadurai/hugo-travelify-theme) のモノを拝借しました。
ただ、[次](https://github.com/IGGG/new.iggg.org/blob/c9498f8d30c3ca441708c51493282b12727853e4/config.toml#L69-L82)のように config からスライダーの画像を指定できるようにしています:

```toml
[params.slider]
    enable = true
    slides = [
      "2014/05/DSC03469.jpg",
      "2014/05/DSC08554_.jpg",
      "2014/05/DSC07319.jpg",
      "2014/05/2014-03-19-11.24.19.jpg",
      "2014/05/DSC08222.jpg",
      "2014/06/DSC09428.jpg",
      "2014/06/DSC09437.jpg",
      "2014/06/2014-06-23-17.05.10.jpg",
      "2014/06/2014-06-25-21.20.40.jpg",
      "2014/06/2014-06-28-17.54.04.jpg",
    ]
```

「最近の記事の更新」や「IGGGについての説明」は dopetrope のモノを使い、CSSで調整しています。
ちなみに、CSSを変更しても、うまく読み込まれず苦労しました(リロードしたり変更したり、結局正しいやり方は分からず)。
イベントボードは自作して、今まで同様に[外から設定できるように](https://github.com/IGGG/new.iggg.org/blob/c9498f8d30c3ca441708c51493282b12727853e4/data/footer/content.yaml)しています:

```yaml
sections:
- title: "What's New"

- title: 'TWITTER'

- title: 'EVENTS'
  events:
  - title: 'IGGG ADVENT CALENDAR 2017'
    imagelink: 'https://adventar.org/calendars/2300'
    imageurl: '/images/2017/11/igggAC2017.jpg'
```

Twitter のタイムラインは[ここ](https://publish.twitter.com)で生成したモノをただ単純に埋め込んでいます。

### GitHub Pages

さて、ここまでくれば後は Public にするだけだ(ここまでは Private リポジトリにしてた)。
Settings で Public に変更し、GitHub Pages の設定を `docs` にしてオンする。
意気揚々と `iggg.github.io/new.iggg,org` にアクセスすると。。。。

![](/images/replace-iggg-org/404-ghpages.png)

見れない！
あれ、なぜだ？？
答えはこれ:

- [How to fix page 404 on Github Page? - Stack Overflow](https://stackoverflow.com/questions/11577147/how-to-fix-page-404-on-github-page)

コミットしないと GitHub Pages の生成がされないらしい。
なので空コミットしたら無事表示された！

![](/images/replace-iggg-org/new-iggg-org-home.png)

## 残タスク

- 古いページは多分崩れてるので直さないと
- DNS を iggg.org にする
- コミットから自動生成する仕組み
- プレビュー機能

## おしまい

Hugo 結構使いやすい。
