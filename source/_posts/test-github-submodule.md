---
title: Submodule と GitHub Pages についてイロイロとテストしてみた
date: 2016-12-05 11:29:48
tags:
  - GitHub
categories: Web
cover: "/images/404_github.jpg"
---

IGGG アドベントカレンダー5日目の記事です。

今回は C91 に向けて GitHub の使用をイロイロとテストしてみたときの話です。

## いきさつ

IGGG はココ何回か例の有名なコミケに出展しています。
とある事情より、前回(C90) は GitHub にて編集・管理を行いました。
今回(C91)も同様に GitHub で編集・管理しようと思ったのですが、部誌([Lollipop](https://iggg.github.io/lollipop/))用の Web ページを GitHub Pages で作ろうと考え、この野心との兼ね合いでイロイロと試行錯誤しました。

考えを整理すると以下の通りです。

- C90 のときのリポジトリがある (IGGG/lollipop-vol4)
- C91 のリポジトリを作りたい (IGGG/lollipop-vol5 ?)
- Lopllipop 用の GitHub Pages を作りたい

考え得る案は2つ

1. 1つのリポジトリで全てを実現
2. 全て各々のリポジトリで実現

前者の場合は既にある `lollipop-vol4` リポジトリを次のように改変することになる。

```
IGGG/lollipop
 | - lollipop-vol4
 | | - ...
 | - lollipop-vol5
 | | - ...
 | - README.md
 | ...
```

これは新しい巻が出るたびにクローンせずに済むので有り難い。
しかし、古い巻に関係ない人も全ての巻のデータを落とさないと行けなくなる(例えば vol.5 は寄稿するが vol.4 では寄稿しなかった人)。
これは重い気がする。

なので、後者を採用してひと工夫することにした。
それが Submodule である。

### Git Submodule

詳しくはググってください。

[この](http://qiita.com/kinpira/items/3309eb2e5a9a422199e9)あたりを読むとわかりやすい。

端的に言うと、Git Submodule は、リポジトリの下にリポジトリを追加する方法である。
自分的に一癖ある機能で、未だによくわかっていない。

### 最終的なリポジトリ構成

次のようなリポジトリ構成にした

- lollipop-vol4 : vol.4 のプライベートリポジトリ
- lollipop-vol5 : vol.5 のプライベートリポジトリ
- lollipop : lollipop 全体の管理用パブリックリポジトリ
    - submodule として lollipop-vol4 と lollipop-vol5 のリポジトリを持つ
    - gh-pages ブランチを持つ(もちろん GitHub Pages 用のブランチ)

[コレ](https://github.com/IGGG/lollipop)

## 本題

で、パブリックリポジトリがプライベートリポジトリの Submodule を持つ場合

- そもそも可能か？
- GitHub Pages の挙動はどうなるか
    - `docs` 以下に置いた場合
    - `gh-pages` ブランチに置いた場合

という疑問が沸いたので検証してみた。
という話。

## 検証

検証用に利用したリポジトリは[コチラ](https://github.com/matsubara0507/test-submodule)。


### パブリックリポジトリにプライベートリポジトリの Submodule を持たせる

できた。

ただし、プライベートリポジトリにリード権限が無い人が Submodule にアクセスしようとしても、エラーが返ってくる。

![クリック!](/images/test-github-submodule/click_private_submodule.jpg)

![404エラー...](/images/test-github-submodule/404_github.jpg)

### docs 以下に GitHub Pages を設定

最近のアップデートで、GitHub Pages の index.html を[プロジェクトページであれば master ブランチの docs に置いても良くなった](https://help.github.com/articles/configuring-a-publishing-source-for-github-pages/)。
その方が、無駄にブランチを分ける必要が無いので便利な場合がある。

今回も可能であればそうしようと思ったのだが...

どうやら、プライベートリポジトリの Submodule を持つビルドできないようだ。

![怒られた](/images/test-github-submodule/error.jpg)

メールまで飛んでくる始末である。

### gh-pages 以下に GitHub Pages を設定

うまくいった。

まぁそりゃそうか。

[コレ](https://github.com/matsubara0507/test-submodule/tree/gh-pages)と[ココ](https://matsubara0507.github.io/test-submodule/)

GitHub Pages は[リポジトリ内を漁れる](https://matsubara0507.github.io/test-submodule/README.md)ので注意。

## まとめ

- パブリックリポジトリにプライベートリポジトリの Submodule を持たせれる
- プライベートリポジトリの Submodule を持つリポジトリを GitHub Pages のソース置き場にできない
    - プライベートリポジトリの Submodule が無いブランチ(gh-pages)であれば可能

## おしまい
