---
title: ADVENTAR の更新を通知する Slack BOT を作ってみた
date: 2016-12-01 00:00:00
tags:
- Slack
- Bot
- Google Apps Script
categories: Web
photos:
cover: "/images/adventar-slack-bot/bot2bot.jpg"
---

IGGG 名古屋支部のひげです。

今年もとりあえずやってみた [群馬大学電子計算機研究会 IGGG Advent Calendar 2016](http://www.adventar.org/calendars/1572) 1日目の記事です。

1日目ということで、Advent Calendar に準じたネタを。

## いきさつ

去年、なんとなくやりはじめた Advent Calendar 。

その時の話。
とりあえずググってみた結果、まぁ、Qiita が人気ですよね。

![Qiitaが人気ですよね](/images/adventar-slack-bot/google_advent_calendar.jpg)

[ここ](http://blog.qiita.com/post/152366526084/adventcalendar2016?utm_source=qiita&utm_medium=advent_calendar_jumbotron) に簡単にまとめてある。

便利ではあるのだが、部活用の身内カレンダー(身内意外に書かれてもいいけど)を Qiita でやるのは憚られる。
で、次に使われてそうなのが [ADVENTAR](http://www.adventar.org/) 。

サークルとかでも使われた事例はある。

![サークルで使われてるのはADVENTAR](/images/adventar-slack-bot/google_advent_circle.jpg)

で、問題はここから。

Qiita は RSS による通知機能がある。
なので、これを利用して、記事の追加や更新を Slack 等へと簡単に飛ばせる。
しかし、**ADVENTAR にはない** 。

### ADVENTAR にはない

ということで、スクレイピングして飛ばすことにした。

あった。

![slack bot スクレイピング で検索](/images/adventar-slack-bot/google_slack_bot.jpg)

### Google Apps Script

画像の通り、一番上にヒットしたのが [Google Apps Script](https://developers.google.com/apps-script/) (GAS) を用いたモノだった。

これは、JavaScript like な言語で書いたスクリプトを Google Drive に置いておくことで実行できるというモノ。
定期的に自動実行させたり、Webフックして実行したり、Google Apps を拡張したり、イロイロ使える。
なにより、タダで使えるのがうれしい。

まぁ詳しくはググってみてださい。

## Goal

今回の目的のために、作る GAS プログラムを3つのステップに分ける。

1. ADVENTAR のサイトをWebスクレイピングして参加情報を取得くる
2. DBの代わりにスプレッドシートへ情報を保存・参照
3. 前の情報との差分を取って更新情報を Slack に送信

つまり、

1. GAS によるWebスクレイピング
2. GAS によるスプレッドシートの操作
3. GAS による Slack へのメッセージ送受信

を実現すればよい。

最終的なコードは[コチラ](https://gist.github.com/matsubara0507/dbe64f8bf319ab8b86d103a7cb04027d)

## 0. GAS の準備

まずは GAS の準備から。

GASは、スプレッドシートやドキュメントと異なり、デフォルトではインストールされていません。
なので、機能を追加する必要があります。

Google Drive で *右クリック* し、一番下の *その他* から *アプリを追加* をクリックします。

そしたら、`google apps script` を検索してインストール(接続)。

![google apps script を検索](/images/adventar-slack-bot/google_drive_search_gas.jpg)

あとは、スプレッドシートとかと同じように、Drive 内に作成できる。

専用のディレクトリを作成して、

- Bot 用の GAS ファイル
- DB 用のスプレッドシート
- Bot 用のアイコン画像

を置いておいてください。

## 1. GAS によるWebスクレイピング

![まぁありますよね](/images/adventar-slack-bot/google_gas_scraping.jpg)

まぁ出てきますよね。

適当に参考にしながら作った。

### 準備

最初は以下のサイトを参考にしながら DOM Tree っぽく処理しようとしたのだが、` XmlService.parse` という関数は[正しい形式の HTML でないとパース出来ない](http://stackoverflow.com/questions/19455158/what-is-the-best-way-to-parse-html-in-google-apps-script) 。

- 参考 : [［GAS］HTML/XMLをパースする - 技術のメモ帳](http://yoshiyuki-hirano.hatenablog.jp/entry/2015/10/01/231813)

よって、こっちの愚直にパースする方法をとることにした。

- 参考 : [Google Apps ScriptでスクレイピングしてSlackに定期ポストするbotを瞬殺で作った - Qiita](http://qiita.com/fireowl11/items/e703e35073b600528e7c)

[Parser](http://www.kutil.org/2016/01/easy-data-scrapping-with-google-apps.html) という外部ライブラリを用いる。

GAS に新しく外部ライブラリを追加するためには、以下の手順を行う必要がある。

1. GAS ファイルを開いてツールバーの *リソース* をクリック
2. *ライブラリ* をクリック
3. *ライブラリを検索* にキーを入力して追加

Parser のキーは `M1lugvAXKKtUxn_vdAG9JZleS6DrsjUUV` 。
バージョンは新しいのを選べばいいと思う(今回は 7 を使った)。

### テスト

例えば次のコードを書いて実行し、ログで確認。

```javascript
function postMessage() {
  var url = 'http://www.adventar.org/calendars/1137'
  var html = UrlFetchApp.fetch(url).getContentText();
  var doc = Parser.data(html)
                  .from('<div class="mod-calendarHeader"')
                  .to('</div>')
                  .build()  
  Logger.log(doc);
}
```

ログはツールバーの *表示* から *ログ* をクリック。

```
[16-11-08 21:42:01:217 JST]  style="background: #8AC5D2"><div>
  <h2>群馬大学電子計算機研究会 IGGG Advent Calendar 2015</h2>

  <div class="mod-calendarHeader-meta">
    <p>作成者：<a href="/users/8528" class="mod-userLink"><img src="http://www.gravatar.com/avatar/6491e85d52916cfb063372cec9edb6cc?size=23&amp;d=mm" width="23" height="23" class="mod-userIcon" /><span>noob</span></a></p>
    <p>登録状況：25/25人</p>
```

もちろん、頭から探索しているだけなので、括弧やHTMLタグの対応を取ってはくれない。
つまり、同じタグが入れ子になっていると、最初の方の閉じタグを取ってきてしまう。
欲しい情報を望んだとおりに取得するためには工夫が必要だ。

### ADVENTAR の場合

- 参考： [Adventerの日記をSlackに流してみよう一人プロジェクト - hotchpotch](https://hotchpotchj37.wordpress.com/2015/12/05/adventer%E3%81%AE%E6%97%A5%E8%A8%98%E3%82%92slack%E3%81%AB%E6%B5%81%E3%81%97%E3%81%A6%E3%81%BF%E3%82%88%E3%81%86%E4%B8%80%E4%BA%BA%E3%83%97%E3%83%AD%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88/)

なるほど、下の方を取ればいいのか。

適当に書いてから共通部分を関数化して、最終的に次のようになった。

```javascript
function doPost(e) {

  const YEAR = '2016';
  const URL = 'http://www.adventar.org/calendars/1572';

  /* Scraping */
  var html = UrlFetchApp.fetch(URL).getContentText();
  var table = parseByTagAndClassId(html, 'table', 'mod-entryList');
  // Entry is [date, user name, comment, title, url]
  var entries = Parser.data(table)
                      .from('<tr class="" id="list-')   
                      .to('</tr>')
                      .iterate()
                      .map(function(entry){ return parseEntry(entry, YEAR); });
}

function parseEntry(entry, year) {
  var date = year + '/' + parseByTagAndClassId(entry, 'th', 'mod-entryList-date');
  var user = parseByTag(parseByTagAndClassId(entry, 'a', 'mod-userLink'), 'span');
  var comment = parseByTagAndClassId(entry, 'div', 'mod-entryList-comment');
  var title = parseByTagAndClassId(entry, 'div', 'mod-entryList-title');
  var url = parseByTag(parseByTagAndClassId(entry, 'div', 'mod-entryList-url'), 'a');

  return [date,user,comment,title,url];
}

function parseByTagAndClassId(data, tag, classId) {
  var temp = Parser.data(data)
                   .from('<' + tag + ' class="' + classId + '"')
                   .to('</' + tag + '>')
                   .build();
  return temp.substring(temp.indexOf('>') + 1, temp.length);
}

function parseByTag(data, tag) {
  var temp = Parser.data(data)
                   .from('<' + tag)
                   .to('</' + tag + '>')
                   .build();
  return temp.substring(temp.indexOf('>') + 1, temp.length);
}     
```

この Parser ライブラリでは、たぶん、行末までパースというのができないので、`temp.substring(temp.indexOf('>') + 1, temp.length);` という感じに自分で書いた。

なんで、日付に年を加えてるのかと言うと、スプレッドシートに書き込むときに書いておかないと、今年の年を勝手に書き込むからだ。

## 2. GAS によるスプレッドシートの操作

次に、スプレッドシートをDB代わりとして操作する。

- 参考：[Google Apps Scriptのスプレッドシート読み書きを格段に高速化をする方法](http://tonari-it.com/gas-spreadsheet-speedup/)

と他にも Google の[公式ドキュメント](https://developers.google.com/apps-script/reference/spreadsheet/)を参考にした。

### Properties

実際にいじる前に必要な知識を一つ。

野生のコードを眺めてると、けっこう以下の行を見かける。

```javascript
var prop = PropertiesService.getScriptProperties().getProperties();
```

これは所謂、環境変数みたいのをとってきている。
なんらかのパスワードや ID を直接コードに書いておくのは望ましくないので、システムの中に書いておくのである。

正直はじめ、どーやって設定するかわからなかったがやっと見つけた。

ツールバーの *ファイル* から一番下の *プロジェクトのプロパティ* をクリック。
今回はスクリプト単位で設定したいので、スクリプトのプロパティに行を追加していく。

### スプレッドシートの準備

予めスプレッドシートを作っておく。
スプレッドシートの名前は何でも良い。
シート名は `2015` とか `2016` などの *年* にする。

### スプレッドシートの読み取り

読み取るためにはスプレッドシートの ID が必要だ。

開いたときのURL `docs.google.com/spreadsheets/d/XXXXX/edit#gid=0` の `XXXXX` という部分だ。
直書きしても良いが、前述した Properties に追加しておこう。

前のコードの `doPost` 関数を以下のように拡張する。

```javascript
function doPost(e) {

  /* Scraping */
  // ...

  const DAYS = [ '12/01', '12/02', '12/03', '12/04', '12/05'
               , '12/06', '12/07', '12/08', '12/09', '12/10'
               , '12/11', '12/12', '12/13', '12/14', '12/15'
               , '12/16', '12/17', '12/18', '12/19', '12/20'
               , '12/21', '12/22', '12/23', '12/24', '12/25'
               ];
  const COLUMN_NUM = 5;

  var prop = PropertiesService.getScriptProperties().getProperties();

  /* Load Spread Sheet */
  var sheet = SpreadsheetApp.openById(prop.SPREAD_SHEET_ID).getSheetByName(YEAR);
  var oldEntries = sheet.getRange(1, 1, DAYS.length, COLUMN_NUM).getValues();  
}
```

イロイロ考えた結果、日付を列挙しておいた方が楽だった。
`getRange(a,b,c,d).getValues()` で `(a,b)` から `(c,d)` までの範囲を2次元配列として取得する。

直接アクセスする方法もあるが、必要な分だけ予め配列として読み取って、JavaScript として処理した方が速いらしい。
なのでそうしてる。

### スプレッドシートの更新

スクレイピングして得た情報 `entries` から新しくスプレッドシートに書き込むデータを作成して、書き込む。

```javascript
function doPost(e) {

  /* Scraping */
  // ...

  /* Load Spread Sheet */
  // ...

  /* Update Spread Sheet */
  var newEntries = DAYS.map(function(d) { return [YEAR + '/' + d,'','','','']; });
  entries.map(
    function(entry){
      newEntries[getIndexByDate(newEntries, entry[0])] = entry;
    });
  sheet.getRange(1, 1, DAYS.length, COLUMN_NUM).setValues(newEntries);
}

function getIndexByDate(entries, date) {
  for (var i = 0; i < entries.length; i++) {
    if (entries[i][0] == date)
      return i;
  }
  return null;
}
```

見ての通り、`getRange(a,b,c,d).setValues()` で書き込んでいる。

## 3. GAS による Slack へのメッセージ送受信

最後にいよいよ Slack に Bot としてメッセージを飛ばす。

- 参考 : [非エンジニアがカップル専用アプリ「Slack」でGAS製Bot運用してみた - Webを楽しもう「リパレード」](https://reparade.com/log/tool/slackbot-gas.html)

GAS 側にタイマーを仕掛けて、一日一回とってくるのも良いが、おそらく12月に入るまで更新は少ないだろうから、Slack の Advent Calendar チャネルで特定のキーワードを打ったら返ってくるようにする。

### Slack の準備

*Outgoing WebHooks* というインテグレーションを追加する。

[ココ](https://iggg.slack.com/apps)にアクセスして *Outgoing WebHooks* と検索して追加。

設定項目のうち、重要なのは以下の4つ。

- Channel
- Trigger Word(s)
- URL(s)
- Token

`Channel` で指定したチャネルで、 `Trigger Word(s)` で指定したワードから始まるメッセージを送信すると、`URL(s)` で指定したプログラムが動く、と言う感じ。
`Token` は認証に使うので、`VERIFY_TOKEN` として GAS の Properties に追加しておく。

まぁ、認証は無くても良いが、GAS コードのURLが漏れると、実行されまくるので注意。

### Slack API for GAS

作ってくれてた、ありがたい。

- 参考 : [Slack BotをGASでいい感じで書くためのライブラリを作った - Qiita](http://qiita.com/soundTricker/items/43267609a870fc9c7453)

Parser ライブラリのときと同じように追加する。
キーは `M3W5Ut3Q39AaIwLquryEPMwV62A3znfOO` 。

Slack の API を使うには専用のトークンが必要なので、[ココ](https://api.slack.com/web)にアクセスして発行してもらう。
下の方にある *Generate test tokens* をクリックする。

生成されたトークンは `SLACK_API_TOKEN` として Properties に追加しておく。

### 画像を利用

最初の方に用意した Bot 用のアイコンを利用するにはひと工夫が必要である。

- 参考 : [Google Drive に保存した画像を直接呼び出せるURLの取得 - Qiita](http://qiita.com/arribux/items/0394968fa318d9309d33)

ドライブ中で画像を選択し、ツールバーの鎖のようなマークをクリックし、共有可能なリンクを取得する。
すると、`drive.google.com/open?id={id}`のようなフォーマットのURLを得るはずだ。

Webサイトなんかに埋め込むためには、このURLを `drive.google.com/uc?export=view&id={id}` のように書き換えて使う。

なので、この `{id}` を `ICON_ID` として Properties に追加しておく。

### GAS コード

以下のように拡張する。

```javascript
function doPost(e) {

  var prop = PropertiesService.getScriptProperties().getProperties();
  const BOT_NAME = 'Gunmer';
  const BOT_ICON = 'http://drive.google.com/uc?export=view&id=' + prop.ICON_ID;

  if (prop.VERIFY_TOKEN != e.parameter.token) {
    throw new Error("invalid token.");
  }

  /* Scraping */
  // ...

  /* Load Spread Sheet */
  // ...

  /* Update Spread Sheet */
  // ...

  /* Post Message to Slack */
  var slackApp = SlackApp.create(prop.SLACK_API_TOKEN);
  var channelId = slackApp.channelsList().channels[0].id;
  var option = { username : BOT_NAME, icon_url : BOT_ICON };

  var noUpdate = true;
  for(var i = 0; i < newEntries.length; i++) {
    var text = null;
    switch(diffEntry(newEntries[i], oldEntries[i])) {
      case 'updated':
        text = '更新がありました！\n' + makeMessage(newEntries[i]);
        break;
      case 'added_entry':
        text = '新しい記事です！\n' + makeMessage(newEntries[i]);
        break;
      case 'deleted_entry':
        var text = 'キャンセルがありました...\n'
                 + newEntries[i][0] +' の記事です';
        break;
    }
    if (text != null) {
      slackApp.postMessage(channelId, text, option);
      noUpdate = false;
    }
  }
  if (noUpdate)
    slackApp.postMessage(channelId, "更新はありません", option);    
}

function makeMessage(entry) {
  var title = entry[3];
  if (title == '')
    title = 'link this!';

  var message = entry[0] + ' : @' + entry[1] + '\n'
              + entry[2] + '\n';

  var url = entry[4];
  if (url != '')
   message = message + '<' + url + '|' + title + '>' ;
  return message;  
}

function diffEntry(newEntry, oldEntry) {
  var equality = true;
  for (var i = 1; i < newEntry.length; i++)
    equality = equality && newEntry[i] == oldEntry[i];

  if (equality)
    return 'no_update';
  if (isEntry(newEntry))
    return 'added_entry';
  if (isEntry(oldEntry))
    return 'deleted_entry';

  return 'updated';
}

function isEntry(entry) {
  return !(entry[1] == '' || entry[1] == undefined || entry[1] == null);
}
```
順に説明する。

#### 認証

```javascript
if (prop.VERIFY_TOKEN != e.parameter.token) {
  throw new Error("invalid token.");
}
```

は言わずもがな前述した認証を行っている。
これで、自分たちの Slack からしか実行できない。

#### メッセージの送信

```javascript
var noUpdate = true;
for(var i = 0; i < newEntries.length; i++) {
  var text = null;
  switch(diffEntry(newEntries[i], oldEntries[i])) {
    /* ... */
  }
  if (text != null) {
    slackApp.postMessage(channelId, text, option);
    noUpdate = false;
  }
}
if (noUpdate)
  slackApp.postMessage(channelId, "更新はありません", option);    
```

で日付ごとに前との差分を取って、更新があればメッセージを送信している。
なにも更新が無ければ、最後に `更新はありません` というメッセージを送信している。

#### 差分をとる

```javascript
function diffEntry(newEntry, oldEntry) {
  var equality = true;
  for (var i = 1; i < newEntry.length; i++)
    equality = equality && newEntry[i] == oldEntry[i];

  if (equality)
    return 'no_update';
  if (isEntry(newEntry) && isEntry(oldEntry))
    return 'updated';
  if (isEntry(newEntry))
    return 'added_entry';
  if (isEntry(oldEntry))
    return 'deleted_entry';

  return "undefined";}
```

で、差分をとっている。
引数はどちらも、要素数を5と仮定した配列で、同じ日付のエントリに関する新旧情報の行を想定している。

`for` 文を見ると、1から始まっている。
つまり、日付では比較していない。
理由は、スプレッドシートから読み込んだ旧情報の日付は `Date` 型として保存されており、文字列ではないので、比較できない(もとい必ず `false` が返る)。
なので、日付は同じと仮定して、比較している。

もし、

- 更新が無ければ `no_update` という文字列を、
- 何らかの更新はある場合は `updated`
- 記事が新しく追加された場合は `added_entry` を、
- 登録がキャンセルされている場合は `deleted_entry` を、
- それ以外の場合は (ないけど) `undefined`

という文字列を返す。

数値でもよかったが可読性優先して文字列にした。

#### メッセージの作成

```javascript
function makeMessage(entry) {
  var title = entry[3];
  if (title == '')
    title = 'link this!';

  var message = entry[0] + ' : @' + entry[1] + '\n'
              + entry[2] + '\n';

  var url = entry[4];
  if (url != '')
    message = message + '<' + url + '|' + title + '>' ;
  return message;  
}
```

`[日付, ユーザー名, 記事に関するコメント, 記事のタイトル, 記事のURL]` の配列を受け取って文字列を返している。
この文字列が Slack へ送信される。

こんなメッセージを想定している。

```
2016/12/01 : @noob
ADVENTAR の更新を Slack に通知させる Bot の作成
```

ユーザー名に `@` を付けてるのは、同一の slack でのユーザー名であればリンクが付くかと期待したからだ。
結局付かなかったので、わざわざ `@` を付ける必要はないです。

`message = message + '<' + url + '|' + title + '>' ;` でただURLを貼るのではなく、記事のタイトルにハイパーリンクを付けている。
ただし、記事によってはタイトルが無い場合があるので、2~4行目あたりで、タイトルがない場合は `link this!` という文字列を代用している。

### URLを指定する。

*Slack の準備* のとこで説明した、URL(s) に指定するURLを取得する。

GAS のツールバーの *公開* から *ウェブアプリケーションとして導入* をクリック。

ここで、*アプリケーションにアクセスできるユーザー* を *全員（匿名ユーザーを含む）* にする必要がある。

*導入* を押せば、URLが発行されるので、それを Slack のインテグレーションの Outgoing WebHooks の URL(s) にコピペする。

## 4. コードの更新

最後に注意点。

コードを ~~更新するたびに必要かはわからないが、~~ (必要でした) 更新してもうまく実行されない場合は、もう一度、上記の手順で
 *ウェブアプリケーションとして導入* をし、*プロジェクトのバージョン* をあげること。

ちなみに、仮にコードを更新するたびにバージョンをあげないといけないならば、ADVENTAR のURLや年が変わるたびに、あげないといけなくなる。
なので、最終的にはそれらを Properties にした。

## 最終的に

こんなかんじ

![ひとりさみしく](/images/adventar-slack-bot/slack_bot.jpg)

## ついでに

定期ポストしたい場合の手っ取り場合方法は、Bot をフックするためのメッセージを定期ポストする GAS コードの Slack Bot を作るのがよさそう。

コードはサクッとこんな感じ

```javascript
function postMessage() {

  var prop = PropertiesService.getScriptProperties().getProperties();

  const BOT_NAME = 'Gunmer BOT';
  const BOT_ICON = 'http://drive.google.com/uc?export=view&id=' + prop.ICON_ID;

  /* Post Message to Slack */
  var slackApp = SlackApp.create(prop.SLACK_API_TOKEN);
  var option = { username : BOT_NAME, icon_url : BOT_ICON };

  slackApp.postMessage(prop.CHANNEL_ID, prop.MESSAGE, option);
}
```

`CHANNEL_ID` は `#randome` とかで良い。
後は、GAS の設定で定期ポストをするだけ。

![半日置きに定期ポストされるはず](/images/adventar-slack-bot/regular_post.jpg)

![Bot から Bot へ](/images/adventar-slack-bot/bot2bot.jpg)


## おしまい
