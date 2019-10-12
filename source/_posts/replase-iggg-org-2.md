---
title: iggg.org を移行する その２
date: 2019-10-13 20:00:00
tags:
- GitHub
- Hugo
- Scrapbox.io
categories: Web
photos:
cover: "/images/replace-iggg-org/new-iggg-org.jpg"
---

これの続きです。

- [iggg.org を移行する｜群馬大学電子計算機研究会 IGGG](/2018/12/21/replace-iggg-org)

半年前...やりきりました。
実際に [iggg.org](https://www.iggg.org) はすでに新しくなっており、[IGGG/new.iggg.org](https://IGGG/new.iggg.org) というリポジトリで動いてます。

![](/images/replace-iggg-org/new-iggg-org.jpg)

## 前回からの残タスク

やったのはこれ

1. NEWSの記事の細かい修正
2. wiki の移行
3. コミットから自動生成
4. ドメインを iggg.org にする

## 1. NEWSの記事の細かい修正

鬼門その１。
いくつか古い記法が残っていました。

### 埋め込み系

まずは埋め込み系:

- [スライド の埋め込み](https://github.com/IGGG/new.iggg.org/commit/6fa930fcf125c3d370921bc985c8de72a07f080f) (SlideShare)
- [Twitter と YouTube の埋め込み](https://github.com/IGGG/new.iggg.org/commit/6e5552b94ce77eb81e90d0d9d277ce1c60e77ec2)

ええ、この辺りは機械的にやりようがないので。。。

1. 問題の箇所がどこか grep
2. 対応する旧ページを見に行く
3. Embed 記法を書き換える

愚直です（たいした数がないのでいいんですけど）。

### 画像

そして次は画像。
記法の変換は大体できていたのが、サイズがめちゃくちゃデカイので [Hugo のショートコードを設定して直した](https://github.com/IGGG/new.iggg.org/commit/e271fd2510d3e49082e60ada56eca556a143f58e):

```HTML
{{ $src := .Get "src" }}
{{ $scale := float (default "1" (.Get "scale" )) }}
{{ $title := .Get "title" }}
{{ $config := imageConfig (printf "/static/%s" $src) }}
<figure style="margin: 1em">
  <img src="{{ .Site.BaseURL | absLangURL }}{{$src}}"
       style="max-width: {{mul $config.Width $scale}}px"
       width="100%"
       alt="{{$title}}"
       title="{{$title}}">
  <figcaption>{{$title}}</figcaption>
</figure>
```

これを `layouts/shortcodes/img.html` に保存し、`{< img src="/path/to/image" scale="0.2" title="タイトル" >}}` と書くことでサイズを指定したり、正しいパスに変換してくれたりしてくれる。
完璧だ。

### alias

旧ページと新ページでページの URL が変わってしまう。
旧はページのタイトルや設定した URL になってるのだが、対して新は日付の URL。
さて、どうするか。
alias の設定自体は Hugo のフロントマターで指定できます:

```md
---
title: "本会の活動拠点が決定しました！"
date: 2014-06-16
aliases:
- /news/base-was-decided
---

## 場所は…？
...
```

ではどうやって元の URL と新しい URL を対応させるか。
**根性です。**
[根性しました](https://github.com/IGGG/new.iggg.org/commit/20016f3b0ce3c7055a6349a57b8a620fd1ba94a0)。

![根性の様子](/images/replace-iggg-org/tesagyo.jpg)

## 2. wiki の移行

鬼門その２。
静的サイトはキッツイので代替の要件から考えた。

- ページは公開されていい
- ユーザー登録は(多少)クローズド
- マークダウンか何かでインポートできる

以上を踏まえた結果 Scrapbox.io にしました:

- [IGGG - Scrapbox](https://scrapbox.io/iggg/)

で、以降手順はこんな感じ

1. PukiWiki のデータ全部抜く
2. PukiWiki から MD に変換
3. MD 内の wiki へのリンクを Scrapbox に差し替え
4. 画像も Scrapbox にいい感じに
5. MD を Scrapbox にインポート

### PukiWiki のデータ全部抜く

自分でセットアップしてないので、まずは PukiWiki のデータを探した:

```
$ ls /srv/http/wiki/wiki-data/wiki/ | head
32303137E5B9B4E5BAA620E381A1E381B3E381A3E5AD90E5A4A7E5ADA6.txt
32303138E5B9B4E5BAA620E381A1E381B3E381A3E5AD90E5A4A7E5ADA6.txt
32E3818BE38289E5A78BE381BEE3828BE695B4E695B0E58897.txt
3A526563656E7444656C65746564.txt
3A636F6E6669672F4261644265686176696F72.txt
3A636F6E6669672F617574682F6F70656E69642F6D697869.txt
3A636F6E6669672F6931386E2F746578742F6A615F4A50.txt
3A636F6E6669672F706C7567696E2F6174746163682F6D696D652D74797065.txt
3A636F6E6669672F706C7567696E2F63686172742F64656661756C74.txt
3A636F6E6669672F706C7567696E2F72656665726572.txt
```

発見。ファイル名はどうやら16進数でエンコードされたURL(タイトル)らしい。
Ruby で適当にデコードしてみた:

```
$ pwd
/srv/http/wiki/wiki-data/wiki
$ find . -name "*.txt" | xargs -INAME ruby -e 'puts [ARGV[0].delete("./").delete(".txt")].pack("H*")' NAME
MenuBar
群桐祭 2015
Ren'Pyで遊ぶ(その2)
Help/Plugin/D
Ziyuu
:config/plugin/attach/mime-type
C勉強会2015
ジャンク祭り 2017
ETロボコン2015
arthur63
メンバー会議 20160121
atpons
UML勉強会2018
FrontPage
IGGG Meetup 2016 Winter
CTFの大会
コアメンバー会議 20150327
ジャンク祭り 20150618
ﾄｷｵﾔﾏｸﾞﾁ
...
```

謎は解けたので後は固めて scp するだけ:

```
# これは SSH 先
$ sudo tar czvf wiki-data.tar.gz /srv/http/wiki/wiki-data/wiki
...
$ ls -lah wiki-data.tar.gz
-rw-r--r-- 1 root root 249K  9月 30 18:23 wiki-data.tar.gz

# これはローカル
$ scp hoge@fuga:/path/to/wiki-data.tar.gz .
$ tar xzvf wiki-data.tar.gz
...
```

### PukiWiki から MD に変換

魔法の sed 芸した:

- [PukiWiki の文書を Markdown に変換するワンライナー(一部 crowi-plus 仕様) - Qiita](https://qiita.com/yuki-takei/items/152e20f4421333ae8fd9)

とはいえいくつか漏れがある:

- `-hoge` みたいな h1 要素があり、スペースが無い
- `#contents` などもともとマジックワードのようなのがある
- 画像の形式が変
- `[[xxx:yyy]]` 形式のリンク

どうしようもないので手動で。。。
後、メタっぽいページはいらないので削除した(e.g. `Help`)。

後、タイトルを Ruby 芸:

```bash
ls | grep '.txt' | xargs -IORIG bash -c 'ruby -e "puts [ARGV[0].delete(%!.txt!)].pack(%!H*!).gsub(?\s, ?_)" ORIG | xargs -INEW echo mv ORIG NEW.md'
```

これでも漏れがあるので手動で直す。。。(空白とか)

### MD 内の wiki へのリンクを Scrapbox に差し替え

参照:

- [ページをリンクする - Scrapbox ヘルプ](https://scrapbox.io/help-jp/ページをリンクする)

タイトルと同じならこの記法に変換。
それ以外は普通のリンクに。

**ほぼ手作業で**。

### 画像も Scrapbox にいい感じに

まず画像を持ってくる:

```
$ cd /srv/http/wiki/wiki-data/attach
$ ls | grep -v '.log' | xargs file | grep PNG
32E3818BE38289E5A78BE381BEE3828BE695B4E695B0E58897_696D61676530312E706E67:                                              PNG image data, 225 x 31, 8-bit grayscale, non-interlaced
32E3818BE38289E5A78BE381BEE3828BE695B4E695B0E58897_696D61676530322E706E67:                                              PNG image data, 225 x 31, 8-bit grayscale, non-interlaced
427575_735F646F742E706E67:           PNG image data, 48 x 48, 8-bit/color RGBA, non-interlaced
457863656CE381A7E6A99FE6A2B0E5ADA6E7BF9228E69C80E8BF91E5828DE6B39529E38284E381A3E381A6E381BFE3828B_696D6730312E706E67:  PNG image data, 1462 x 1482, 8-bit/color RGBA, non-interlaced
457863656CE381A7E6A99FE6A2B0E5ADA6E7BF9228E69C80E8BF91E5828DE6B39529E38284E381A3E381A6E381BFE3828B_696D6730322E706E67:  PNG image data, 1456 x 1484, 8-bit/color RGBA, non-interlaced
...
```

やり方は `*.txt` と同じ(割愛)。
それを同じようにデコード(これは名前を出してみてるだけだけど):

```
$ ls | xargs -I{} ruby -e 'puts ARGV[0].split(?_).map{|x| [x].pack("H*")}.flatten.join(?/)' {}
2から始まる整数列/image01.png
2から始まる整数列/image02.png
Buu/s_dot.png
Excelで機械学習(最近傍法)やってみる/img01.png
Excelで機械学習(最近傍法)やってみる/img02.png
Excelで機械学習(最近傍法)やってみる/img03.png
Excelで機械学習(最近傍法)やってみる/img04.png
...
```

画像は Scrapbox にインポートできないっぽいので、大した量じゃないし雑なリポジトリを作って雑にあげた:

- [IGGG/resources - GitHub](https://github.com/IGGG/resources)

あとは画像のリンクを直すだけ(半ば手作業で)。

### MD を Scrapbox にインポート

参照:

- [ページをインポート・エクスポートする - Scrapbox ヘルプ](https://scrapbox.io/help-jp/ページをインポート・エクスポートする)

MD から Scrapbox にインポートできる形式に変換するには `scrapbox-converter` という CLI ツールを使う:

- [pastak/scrapbox-converter - GitHub](https://github.com/pastak/scrapbox-converter)

ガット変換して、試しにフォーマットして見て変な部分があれば **手作業で** 直してインポート！
やったね！

### new.iggg.org 側のリンクを修正

一括置換してみたが記法にいくつか種類があり、[半ば手作業](https://github.com/IGGG/new.iggg.org/commit/43b90c9d1f60460f3792e34bcdfad4f4d8725d86)(完)

## 3. コミットから自動生成

せっかくなので GitHub Actions を使った。
その辺りは前回の記事に書いた:

- [GitHub Actions を使ってみた｜群馬大学電子計算機研究会 IGGG](https://iggg.github.io/2019/10/11/use-github-actions/)

## 4. ドメインを iggg.org にする

あとはドメインの設定を変えるだけ。
リポジトリの Settings で別のカスタムドメインを設定すると勝手に [`CNAME` をプッシュしてくれる](https://github.com/IGGG/new.iggg.org/commit/c85253722a921fade55422e1b1d20ad1819b370a)。

## おしまい

無事管理するものを減らせたぜ。
