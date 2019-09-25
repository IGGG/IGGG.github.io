---
title: libnss-json 始めました
date: 2019-09-25 00:00:00
tags:
- libnss-json
- Linux
categories: Infra
photos: "/images/libnss-json/libnss.png"
cover: "/images/libnss-json/libnss.png"
---

こんにちは。IGGG 何もしない部の[atpons](https://www.iggg.org/wiki/?atpons)です。みなさんはサークルのサーバのユーザ管理、どうしていますか？

われわれのサークルは、そこまで規模が大きくないため、サーバの数は少なく、一台のみVPSをレンタルしています。

なので、これまでは手作業でユーザの追加を行ったり、時にはLDAPを用いてユーザを管理していました。しかし、年々メンテナンスをしていくユーザが卒業していき、LDAPなどを全て停止していました。

正しく設定が変更されてLDAPとかが抜けていればいいのですが、実際`pam.d`以下をちゃんとみて`sssd`(サークルではSSSDを利用していました)を削除するのがつらく、あるあるなsudo遅い問題（解決しにいくため）などが多発していました。

## libnss-jsonを知る

先日行われた[技術書典7](https://techbookfest.org/)に参加し、[東工大デジタル創作同好会traP](https://trap.jp)のSysAd班が出している「[traP SysAd TechBook](https://techbookfest.org/event/tbf07/circle/5091367973814272)」を買って色々と読んでいたところ、libnss-jsonというのがあると言うことを知りました。

### libnssとは
Linux(*nixにもあるらしい)にはName Service Switch(NSS)と呼ばれる、`/etc/passwd`などをファイルからどこから読むのかを管理する機構があります。これにLDAPなどを読みに行くようなものを書けば、`getent`をした際にそこに読みに行きます、というワケです。これらは、NSSサービスとして書くことができます。

## libnss-jsonを使う
これをJSONファイルで定義して、なおかつリモートから読み込んでくれるようなNSSサービスが、[libnss-json](https://github.com/Aklakan/libnss-json)です。導入方法などは上で挙げたtraPの本がとても参考になりました。

実際に導入する際には、導入用のAnsible Playbookを用意したり、Vagrantでしっかりと動作確認できるようにしました。既存のサーバで適用する前に、さまざまなケースを試し、問題ないことを確認した上でデプロイしました。

traPの本では、traPがフォークした[このリポジトリ](https://github.com/traPtitech/nss)を使って紹介されていました。

## SSHも便利に使う
traPの本では、OpenSSHの設定で`AuthorizedKeysCommand`を上手く使って、上のJSONで定義したユーザ名を使ってGitHubの公開鍵と組み合わせていました。われわれのサークルもこの方式を採用させていただきました。

## おわりに
Name Service Switchのバックエンドをいろんなモノに差し替えるという発想は、最近だと[STNS](https://stns.jp/)が有名だと思います。ただ、大学のサークル、しかも小規模となると、あまりメンテナンス性とか（抜けることが少ない）、階層性についてこだわりたくないなと思っていました。実際、プロビジョニングツールを書いたりはしていたのですが…。

しかし、このlibnss-jsonでかなり**Lightweight**に管理できて個人的にはとても満足しています。

このlibnss-jsonを自動で展開するAnsible Playbookも書いたので、これで将来サーバが増えても簡単に管理できると思います！

さいごに、有益な情報を書いてくださったtraPのみなさまには感謝しかないです！
ありがとうございました。