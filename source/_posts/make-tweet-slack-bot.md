---
title: Slack から特定のアカウントでツイートする Bot を作った
date: 2017-06-01 23:29:36
tags:
- Slack
- Bot
- Google Apps Script
- Twitter
categories: Web
cover: "/images/make-tweet-slack-bot/test3.jpg"
---

IGGG ソフトウェア基盤部のひげです。

Slack をインターフェースにして特定の Twitter アカウントでツイートする Slack Bot を GAS で作った話。
なんか Bot ばっかり作ってる気がする。

## いきさつ

IGGG は部としての活動はあまりなく、個人での活動が多い(ちなみに、それを支援する部になればなぁと思ってます。)。
いっけん何もしてないように見えるが、各々で何かしてる場合があるので、それをもっと広報してみようという話が、この前の Meetup のときにあった。

そこで、個人の活動を PR するための [Twitter アカウント](https://twitter.com/IGGGorg_PR)を作って、活動、例えば、各々のWebサイトの更新や GitHub リポジトリの更新などをツイートしようとなった。

ただ、いちいちログインしてツイートするのはめんどくさい。
ということで、Slack の特定のチャンネルで発言すると、それを本文としてツイートできるようにすることにした。

## 作る

ステップバイステップに作ったので、せっかくだから、その過程を書いておく。
最終的な GAS コードは[ココ](https://github.com/IGGG/google-apps-scripts/blob/announcer/announcer/Announcer.gs)にある。
いくつかのプロパティの他に、以下の外部ライブラリを使用した。

- [SlackApp](https://github.com/soundTricker/SlackApp) : `M3W5Ut3Q39AaIwLquryEPMwV62A3znfOO`
- [OAuth1](https://github.com/googlesamples/apps-script-oauth1) : `1CXDCY5sqT9ph64fFwSzVtXnbjpSfWdRymafDrtIZ7Z_hwysTY7IIhi7s`
- [Underscore](https://github.com/simula-innovation/gas-underscore) : `M3i7wmUA_5n0NSEaa6NnNqOBao7QLBR4j`

### 1. とりあえずそのままツイート

まずは何も考えずにそのままツイートしてくれる Slack Bot を作る。
GAS なので、[Outgoing Webhook](https://iggg.slack.com/apps/A0F7VRG6Q-outgoing-webhooks) を使う。
Bot の名前を `announcer` にするということにして(Customize Name をいじるわけではない、いじってもいいけど)，`@announcer` を Trigger Word(s) に設定する。

イメージはこんな感じ

![](/images/make-tweet-slack-bot/image.jpg)

と打つと、Twitterで「こんにちは、テスト !!」をつぶやいてくれる。

- [Google Apps ScriptからTwitterに投稿する。｜ポンコツプログラマの開発日記](https://ameblo.jp/ponkotsuameba/entry-12206865120.html)

を参考にして作った。

#### 1-1. Twitter API Token の取得

Twitter API を叩くために必要。
電話番号が登録されているアカウントでないとダメなので、自分のツイッターアカウントで発行した(ちなみに、こういう開発での用途か ROM 専でしか使ってない、ぼくは)。
発行の手順は簡単

1. Twitter にログイン
2. https://dev.twitter.com/docs にアクセスして上の方にある `My apps` をクリック
3. `Create New App` をクリックして必要事項を埋める
    - `Name`, `Description`, `Website` を埋める必要があるが、正直なんでもいい
    - アプリで重要なのは `Callback URL` だが、まだ埋めなくても平気
4. `Keys and Access Tokens` というタブをクリックすると、そこに必要なトークンがある

![](/images/make-tweet-slack-bot/slack_api_keys.jpg)

#### 1-2. Bot を書く！

[サンプルコード](https://github.com/googlesamples/apps-script-oauth1/blob/master/samples/Twitter.gs)を参考にして、ソースコードはこんな感じ。

ちなみに、プロパティは以下のようになっている

- `VERIFY_TOKEN`: Outgoing Webhook Slack App の `Token`
- `SLACK_API_TOKEN`: [ココ](https://api.slack.com/custom-integrations/legacy-tokens)から発行できる Slack の API トークン
- `ICON_ID`: Google Drive にある Slack Bot のアイコンに使う画像の ID (別に無くてもいいし、URL を使うように書き換えたって良い)
- `TWITTER_CONSUMER_KEY`: 1-1 で用意した Consumer Key (API Key)
- `TWITTER_CONSUMER_SECRET`: 1-1 で用意した Consumer Secret (API Secret)

```JavaScript
function doPost(e) {
  var prop = PropertiesService.getScriptProperties().getProperties();

  if (prop.VERIFY_TOKEN != e.parameter.token) {
    throw new Error('invalid token.');
  }

  /* for Slack */
  var slackApp = SlackApp.create(prop.SLACK_API_TOKEN);

  const BOT_NAME = 'announcer';
  const BOT_ICON = 'http://drive.google.com/uc?export=view&id=' + prop.ICON_ID;
  var option = { username : BOT_NAME, icon_url : BOT_ICON, link_names : 1 };

  var message = e.parameter.text.split('\n');
  var channelName = e.parameter.channel_name;

  if (message[0] != ('@' + BOT_NAME)) {
    throw new Error('invalid bot name.');
  }

  var result = postTweet(message.slice(1, message.length).join('\n'));

  var text = '';
  if (result != 'error') {
    text = 'Success!\n' + 'https://twitter.com/IGGGorg_PR/status/' + result['id_str'];
  } else {
    text = 'Denied...'
  }
  Logger.log(slackApp.postMessage(channelName, text, option));
}

/**
 * Authorizes and makes a request to the Twitter API.
 */
function postTweet(text) {
  var service = getService();
  if (service.hasAccess()) {
    var url = 'https://api.twitter.com/1.1/statuses/update.json';
    var payload = {
      status: text
    };
    var response = service.fetch(url, {
      method: 'post',
      payload: payload
    });
    var result = JSON.parse(response.getContentText());
    Logger.log(JSON.stringify(result, null, 2));
    return result;
  } else {
    var authorizationUrl = service.authorize();
    Logger.log('Open the following URL and re-run the script: %s',
        authorizationUrl);
    return 'error';
  }
}

/**
 * Reset the authorization state, so that it can be re-tested.
 */
function reset() {
  var service = getService();
  service.reset();
}

/**
 * Configures the service.
 */
function getService() {
  var prop = PropertiesService.getScriptProperties().getProperties();  
  return OAuth1.createService('Twitter')
      // Set the endpoint URLs.
      .setAccessTokenUrl('https://api.twitter.com/oauth/access_token')
      .setRequestTokenUrl('https://api.twitter.com/oauth/request_token')
      .setAuthorizationUrl('https://api.twitter.com/oauth/authorize')

      // Set the consumer key and secret.
      .setConsumerKey(prop.TWITTER_CONSUMER_KEY)
      .setConsumerSecret(prop.TWITTER_CONSUMER_SECRET)

      // Set the name of the callback function in the script referenced
      // above that should be invoked to complete the OAuth flow.
      .setCallbackFunction('authCallback')

      // Set the property store where authorized tokens should be persisted.
      .setPropertyStore(PropertiesService.getUserProperties());
}

/**
 * Handles the OAuth callback.
 */
function authCallback(request) {
  var service = getService();
  var authorized = service.handleCallback(request);
  if (authorized) {
    return HtmlService.createHtmlOutput('Success!');
  } else {
    return HtmlService.createHtmlOutput('Denied');
  }
}
```

`reset`, `getService`, `authCallback` 関数はサンプルコードをそのまんま、 `postTweet` 関数はサンプルコードの `run` 関数を返り値があるように書き換えたモノだ。
いちど `postTweet` 関数を GAS 側で実行すると、**現在ログインしている Twitter アカウント** でのアプリケーション連携の認証ページへ飛ばされるので許可すればよい。

#### 1-3. ためしに実行

こんな感じ

![](/images/make-tweet-slack-bot/test1.jpg)

### 2. 適当にフィルタリング

なんでもかんでもツイートされては困るので、`http` ってキーワードとかでフィルターを掛けてみてはどうか、という話があったので、簡単にかけてみた。

```javascript
function doPost(e) {
  var prop = PropertiesService.getScriptProperties().getProperties();

  /* 同じなので割愛 */

  if (message[0] != ('@' + BOT_NAME)) {
    throw new Error('invalid bot name.');
  }

  var text = '';
  var messageBody = message.slice(1, message.length).join('\n');
  if (messageBody.indexOf('http') == -1) {
    text = 'Denied: do not include "http".';
  } else {
    var result = tweet(messageBody);
    if (result != 'error') {
      text = 'Success!\n' + 'https://twitter.com/IGGGorg_PR/status/' + result['id_str'];
    } else {
      text = 'Denied...';
    }
  }
  Logger.log(slackApp.postMessage(channelName, text, option));
}
```

GAS の JavaScript は古いため、文字列が任意の文字列を含むかどうかを `indexOf` メソッドで調べるしかないらしい。
雑な実装ですね...

### 3. Tweet Request (TR) によるレビュー

どう考えてもガバガバフィルターだなぁと思ってるところに神からのお告げが来た。

![](/images/make-tweet-slack-bot/otsuge_from_kami.jpg)

[Real Time Messaging API](https://api.slack.com/rtm) であれば何でも取得できるので実装できそうだったが、GAS では RTM は使えない...orz

だがしかし、Add Reaction をフックして投稿することはできないけど、

1. PR を作るように Tweet Request を作成するメッセージを打つ
2. TR に LGTM な Add Reaction をする
3. PR をマージするみたいに TR を許可(ツイート)する用のメッセージを打つ
    - 但し、Add Reaction が少ないとツイートできない

って感じに、リクエストの作成とツイートをポストするのを PR みたいに分ければできそうだ！
Add Reaction の取得自体は RTM じゃなくても、[Slack の REST API](https://api.slack.com/web) の [`reactions.get`](https://api.slack.com/methods/reactions.get) を使えばできる。

TR の管理にはスプレッドシートを使う(GitHub の Issue でもいい気はするけど)。
なので、スプレッドシート用に以下のプロパティを追加した。

- `SPREAD_SHEET_ID`: TRを管理するためのスプレッドシートのID
- `SHEET_NAME`: TRを管理するためのスプレッドシートのシート名

#### コード書き直す

ソースコードはこんな感じになった(無駄に長い気もする)

```JavaScript
function doPost(e) {
  var prop = PropertiesService.getScriptProperties().getProperties();

  if (prop.VERIFY_TOKEN != e.parameter.token) {
    throw new Error('invalid token.');
  }

  /* Load Spread Sheet */
  var sheet = SpreadsheetApp.openById(prop.SPREAD_SHEET_ID).getSheetByName(prop.SHEET_NAME);

  /* for Slack */
  var slackApp = SlackApp.create(prop.SLACK_API_TOKEN);

  const BOT_NAME = 'announcer';
  const BOT_ICON = 'http://drive.google.com/uc?export=view&id=' + prop.ICON_ID;
  var option = { username : BOT_NAME, icon_url : BOT_ICON, link_names : 1 };

  var body = e.parameter.text.slice(e.parameter.trigger_word.length).trim();
  var timestamp = e.parameter.timestamp;
  var channelId = e.parameter.channel_id;
  var text = '';
  var _ = Underscore.load();
  switch (e.parameter.trigger_word) {
    case '$tweet?':
      const rowNum = sheet.getLastRow() + 1;
      setTweetRequest(sheet, _.extend(e.parameter, {body: body, num: rowNum}));
      text = 'set tweet request: ' + rowNum;
      break;
    case '$tweet!':
      var tr = getTweetRequest(sheet, body);
      if (tr.ok) {
        var result = tweetWithCheck(tr, prop.SLACK_API_TOKEN);
        if (result.ok)
          sheet.getRange(tr.num, 4).setValue(1);
        text = result.text;
      } else {
        text = tr.error;
      }
      break;
    default:
      text = 'undefined trigger word: ' + e.parameter.trigger_word;
  }
  Logger.log(slackApp.postMessage(channelId, text, option));
//  Logger.log(text);
}

function getTweetRequest(sheet, rowNum) {
  if (isNaN(rowNum)) {
    return { ok: false, error: 'please input number: ' + rowNum };
  }
  var body = sheet.getRange(rowNum, 1).getValue();
  if (body == '') {
    return { ok: false, error: 'not found tweet request: ' + rowNum };
  }
  return {
    ok: true,
    body: body,
    channel_id: sheet.getRange(rowNum, 2).getValue(),
    timestamp: sheet.getRange(rowNum, 3).getValue().slice(1),
    num: rowNum,
    done: sheet.getRange(rowNum, 4).getValue() == 1
  };
}

function setTweetRequest(sheet, tr) {
  sheet.getRange(tr.num, 1).setValue(tr.body);
  sheet.getRange(tr.num, 2).setValue(tr.channel_id);
  sheet.getRange(tr.num, 3).setValue('t' + tr.timestamp);  
  sheet.getRange(tr.num, 4).setValue(tr.done ? 1 : 0);
}

function tweetWithCheck(tr, token) {
  if (tr.done) {
    return { ok: false, text: 'TR ' + tr.num + ' has already been tweeted.' };
  }
  var url = 'https://slack.com/api/reactions.get';
  var options = {
    method: 'post',
    payload: {
      token: token,
      channel: tr.channel_id,
      timestamp: tr.timestamp
    }
  };
  var result = JSON.parse(UrlFetchApp.fetch(url, options));
  if (!result.ok) {
    return { ok: false, text: 'error: ' + result.error };
  }
  const borderline = 2;
  var lgtm = 0;
  for (var i in result.message.reactions) {
    var reaction = result.message.reactions[i];
    if (reaction.name == '+1') {
      lgtm = reaction.count;
    }
  }
  var emassage = 'Few :+1: for tweet req: need ' + borderline + ', now ' + lgtm;
  return lgtm >= borderline ? tweet(tr) : { ok: false, text: emassage }
}

function tweet(body) {
  var result = postTweet(body);
//  var result = { id_str: 'tweet!!' };
  if (result == 'error') {
    return { ok: false, text: 'Denied...' };
  } else if (result.errors != undefined) {
    return { ok: false, text: 'Denied: ' + result.errors[0].code + ' ' + result.errors[0].message };
  } else {
    return { ok: true, text: 'Success!\n' + 'https://twitter.com/IGGGorg_PR/status/' + result['id_str'] };
  }
}
```

あんまりスプレッドシートのオブジェクトを伝搬させたくなくて、奇妙な返り値になっている。
まぁとりあえずはこれで良しとします...

[CTO](https://twitter.com/gion_U) の助言のもと、TRの作成とTRのツイートのコマンドを `$tweet?` と `$tweet!` にした。

スプレッドシートのカラムは、`ツイートしたい本文, チャンネルID, タイムスタンプ, ツイート済みかのフラグ` となっている。
`reactions.get` を使って特定のメッセージの Add Reaction を取得するには、メッセージを特定するために、チャンネルIDとタイムスタンプが必要だ(**チャンネル名ではダメ**)。

ちなみに、チャンネル名からチャンネルIDを調べるには、[ココ](https://api.slack.com/methods/channels.list/test) を使うのが良い[みたい](http://qiita.com/Yinaura/items/bd28c7b9ef614696fb7e)。
また、タイムスタンプはメッセージの時刻を右クリックして取得できる URL、例えば `https://iggg.slack.com/archives/C06FXCF4K/p1496313613432037` の `1496313613432037` を `1496313613.432037` のように前から10-11番目の数字の間に `.` を入れるだけで良い。
まぁ実際は Slack から飛んできたメッセージの情報に載ってるので、わざわざ手作業で集める必要はないんだけど、テストしたいときとかに使った。

Slack API を便利に使う GAS ライブラリでは `reactions.get` を実行でき無さそうだったので、`UrlFetchApp.fetch` を以下のように直接使った。

```javascript
var url = 'https://slack.com/api/reactions.get';
var options = {
  method: 'post',
  payload: {
    token: token,
    channel: tr.channel_id,
    timestamp: tr.timestamp
  }
};
var result = JSON.parse(UrlFetchApp.fetch(url, options));
```

## 実行

いい感じ b

![](/images/make-tweet-slack-bot/test3.jpg)

## おしまい

みんなツイートしてくれるといいなぁ。
