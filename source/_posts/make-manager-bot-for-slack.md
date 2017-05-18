---
title: Slack と GAS と GitHub を使って部内の問題・情報管理を円滑にしたい話
---

IGGG ソフトウェア基盤部のひげです。

特定の GitHub リポジトリの任意の Issue を任意の Slack のチャンネルに通知を飛ばすための Bot (これは公式のインテグレーションではできないはず) を GAS で作った話です。

## いきさつ

IGGG では予てより [Slack](https://slack.com/) というチャットサービスを利用して日々 ~~雑談~~ ディスカッションをしております。
しかし、フリープランの Slack では **ログが一万件しか残らない！**
割と重要な事案が ~~しょーもない雑談~~ 活発な技術的な議論によって、気づいたら流れてしまう...。

皆を説得して有償プランにしようとか、ログの残るサービスに移ろうとか、何度かいろんな案で話し合ったのですが...いろいろな理由で難しい。
そこで、IGGG の ~~外圧担当~~ CTO こと [擬音](https://twitter.com/gion_U) より **GitHub の Issue で管理しよう** との提案が、今年の4月中旬ぐらいにされた。

![いい感じ](/images/make-manager-bot-for-slack.jpg)

しっかりと問題提起・議論が残り、とてもいい感じ。

## 問題

ただ、いくつか問題があった。

1. IGGG の GitHub 組織アカウントに所属しないと議論が見れない
    - 誰しもが GitHub アカウントを持ってるわけでは...
        - ~~もっておこうよ~~
    - Slack の GitHub Integration で特定のチャンネル(#management)に飛ばす
        - 飛ばしてるけど、決定事項(Issueの結論)だけ #general に飛ばしたい
        - 全部 #general に飛ばしたらうるさい
2. 特定のチャンネルで見たい特定の Issue がある
    - インフラチャンネルで *IPアドレスが欲しい* という Issue が見たいとか
    - いちいち #management に移るのめんどい

要するに 1) #general に Issue の Open と Close だけをコメント付きで通知したいのと、 2) 任意の Issue のコメントを任意のチャンネルに通知したい。

ということで、これらの問題を解決するために Slack の Bot を作った。

## 1. #general に Issue の Open と Close だけをコメント付きで通知する

GitHub インテグレーションでも、Issue の Open, Close だけを飛ばすという設定はある。

![GitHub インテグレーションにて](/images/make-manager-bot-for-slack/github_integration_setting.jpg)

だがしかし、これでは

![てすと](/images/make-manager-bot-for-slack/issue_test.jpg)

という感じの Issue に対し(`てててすと` というコメントは Close 時に書いたコメント)

![てーすと](/images/make-manager-bot-for-slack/slack_github_notification.jpg)

と感じに来る(そりゃそう)。
ここで、最後のコメントも通知してほしいのだ(Issueの結論を書いて)。

### Manager 1号

ということで Bot を作った。
ソースコードは[こちら](https://github.com/IGGG/google-apps-scripts/blob/master/management/GeneralManager.gs)。

以下の3つのGASライブラリを用いている。

- [SlackApp](https://github.com/soundTricker/SlackApp) : `M3W5Ut3Q39AaIwLquryEPMwV62A3znfOO`
- [GitHubAPI](https://github.com/matsubara0507/gasdump/tree/githubapi/GitHubAPI) : `1F4yn329GjHKdcXu9nm0uBZHFo40NGRUF8dfZCTHM1KjXpOXYr2BzIIcJ`
- [Underscore](https://github.com/simula-innovation/gas-underscore) : `M3i7wmUA_5n0NSEaa6NnNqOBao7QLBR4j`

また、[SlackBot の APIトークン](https://api.slack.com/custom-integrations/legacy-tokens) と [GitHub の APIトークン](https://github.com/blog/1509-personal-api-tokens) を利用している。

GitHub の Personal Token を利用しているので、念のため IGGG の GAS では無く、個人の GAS 上で作った。

### 実装

動作は Issue の Open と Close にフックして動作させ、POSTデータを解析し、適切なメッセージ作成して、Slack に投げている。

```JavaScript
function doPost(e) {
  var jsonString = e.postData.getDataAsString();
  var jsonData = JSON.parse(jsonString);
  postMessage(jsonData, 'general');
}

function postMessage(data, channelName) {
  var prop = PropertiesService.getScriptProperties().getProperties();
  const repo = prop.GITHUB_OWNER + '/' + prop.GITHUB_REPO;

  /* 念のためのフィルタリング */
  if (data['repository']['full_name'] != repo && data['comment'] == undefined && data['issue'] != undefined) {
    throw new Error("invalid repository.");
  }
  /* 余計なアクション(editedとか)は破棄 */
  if (data['action'] != 'opened'
      && data['action'] != 'closed'
      && data['action'] != 'reopened') {
    throw new Error("undefined action: " + data['action']);
  }

　/* メッセージを作成 */
  var number = data['issue']['number'];
  var message = makeMessage(data['action'], data['issue'], repo, prop);  

  /* Slackに投げる */
  var slackApp = SlackApp.create(prop.SLACK_API_TOKEN);
  const BOT_NAME = 'manager';
  const BOT_ICON = 'http://drive.google.com/uc?export=view&id=' + prop.ICON_ID;
  var option = { username : BOT_NAME, icon_url : BOT_ICON, link_names : 1 };
  var _ = Underscore.load();
  slackApp.postMessage(channelName, '', _.extend(option, message));
}
```

メッセージは Open, Close, ReOpen の場合に分けて作成している。
Close の場合だけ直近のコメントを GitHub API を使って取ってきている(`getIssueResentCommentBody`)。

```JavaScript
function makeMessage(action, issue, repo, prop) {
  var user = '<' + issue['user']['html_url'] + '|' + issue['user']['login'] + '>';
  /* アクションごとに分岐 */
  var actionText = '';
  var text = '';
  switch(action) {
    case 'opened':
      actionText = 'created';
      text = issue['body'];
      break;
    case 'closed':
      actionText = 'closed';
      text = getIssueResentCommentBody(issue['number'], prop);
      break;
    case 'reopened':
      actionText = 're-opened';
      text = issue['body'];
      break;
  }  
  var pretext = '[' + repo + '] Issue ' + actionText + ' by ' + user;

  /* いい感じなメッセージにするために */
  return {
    'attachments': JSON.stringify([{
      'pretext': pretext,
      'title': '#' + issue['number'] + ': ' + issue['title'],
      'title_link': issue['html_url'],
      'color': prop.COLOR,
      'text': text,
      'footer': '詳細は #management かリポジトリで'
    }])
  };
}

function getIssueResentCommentBody(number, prop) {
  var github = GitHubAPI.create(prop.GITHUB_OWNER, prop.GITHUB_REPO, prop.GITHUB_API_TOKEN);
  var comment = github.get("/issues/" + number + "/comments");
  return comment[comment.length-1]['body'];
}
```

[`attachments`](https://api.slack.com/docs/message-attachments)を使って、頑張っていい感じのメッセージにしている。
これを模索するために、テストとして無駄にメッセージを投げてしまった(ごめんね)。

ちなみに、webhook せずにテストするときは

```JavaScript
function test() {
  var prop = PropertiesService.getScriptProperties().getProperties();
  var data = {
    'action': 'closed',
    'repository': {
      'full_name': prop.GITHUB_OWNER + '/' + prop.GITHUB_REPO
    },
    'issue': {
      'number': 15,
      'title': 'このリポジトリは必要か',
      'user': {
        'login': 'matsubara0507',
        'html_url': 'https://github.com/matsubara0507'
      },
    'html_url': 'https://github.com/' + prop.GITHUB_OWNER + '/' + prop.GITHUB_REPO + '/issues/15',
    'body': 'なんか知らぬ間に決まってる感じもある\n自分で見に行けってのもあるけどサ'
    }
  };
  /* テスト！！*/
  postMessage(data, 'bot-test');
}
```

こんな感じの関数を作って実行する。

あとは、このスクリプトを、*公開* -> *ウェブアプリケーションとして導入* を押して webhook 用の URL を発行し、これを リポジトリの Webhook に設定するだけ。

![Issueだけチェックする](/images/make-manager-bot-for-slack/webhook_setting1.jpg)

### 実行

![いい感じ](/images/make-manager-bot-for-slack/slack_manager1_notification.jpg)

## 2. 任意の Issue のコメントを任意のチャンネルに通知する

GitHub インテグレーションは特定のリポジトリと特定のチェンネルをつなぐ。
よって、特定のリポジトリの特定の Issue と特定の特定のチャンネル繋ぐことはできない。

### Manager 2号

どのチャンネルにどの Issue のを通知するかの設定も Slack からしたいよね。
そのため、設定する側と、コメントにフックして通知する側の2つに分けて書くことにする。
それらのソースコードは、[これ(設定)](9https://github.com/IGGG/google-apps-scripts/blob/master/management/WriteManager.gs) と [これ(通知)](https://github.com/IGGG/google-apps-scripts/blob/master/management/ReadManager.gs)。

ライブラリは 1号のと同じ。

チャンネルと Issue の対応表は(めちゃ簡単な)スプレッドシートで残しておくことにした。

![雑な表](/images/make-manager-bot-for-slack/table_issue.jpg)

## 設定側の実装

Slack の Outgoing Webhook Integration にフックしてスプレッドシートに対応関係を書き込むことにする。

`@manager <cmd>: <issue-num>` というフォーマットでメッセージ送られてくると想定している。
コマンド (`<cmd>`)には、チャンネルと Issue の対応関係をセットする `set-issue` と、対応関係をアンセットする `unset-issue` がある。
また `set-issue` では、指定された Issue の番号 (`<issue-num>`) が本当に存在するかや、既にセット済みかを確認している(`existRow`)。

```JavaScript
function doPost(e) {
  var prop = PropertiesService.getScriptProperties().getProperties();  

  /* Spread Sheet の読み取り*/
  /* 割愛 */

  /* Slack の準備*/
  /* 割愛 */

  /* メッセージによって分岐 */  
  var message = e.parameter.text.split(' ');
  var channelName = e.parameter.channel_name;

  if (message[0] != ('@' + BOT_NAME)) {
    throw new Error('invalid bot name.');
  }

  var _ = Underscore.load();
  var subcmd = message[1];
  var text = '';
  switch(subcmd) {
    case 'set-issue:':
      var number = message[2];
      var issue = getIssue(number, prop);
      if (issue == 'error') {
        text = 'issuer #' + number + ' is not exist.';
        break;
      }
      if (existRow(table, channelName, number)) {
        text = 'issue <' + issue['html_url'] + '| #' + number + '> has already been set for #' + channelName;
      } else {
        text = 'OK! set issue.';
        var repo = prop.GITHUB_OWNER + '/' + prop.GITHUB_REPO;
        option = _.extend(option, makeMessage(issue, repo, prop));
        sheet.getRange(rowNum + 1, 1).setValue(channelName);
        sheet.getRange(rowNum + 1, 2).setValue(number);
      }
      break;
    case 'unset-issue:':
      var number = message[2];
      text = 'not set yet: ' + channelName + ' - ' + number;
      for(var i = 0; i < table.length; i++) {
        if (table[i][0] == channelName && table[i][1] == number) {
          sheet.getRange(i + 1, 1).setValue('');
          sheet.getRange(i + 1, 2).setValue('');
          text = 'OK! unset issue.';
        }
      }
      break;
    default:
      text = 'undefined cmd: ' + subcmd;
      break;
  }
  slackApp.postMessage(channelName, text, option);
}

function existRow(table, channelName, number) {
  for (var i = 0; i < table.length; i++) {
    if (table[i][1] == number && table[i][0] == channelName)
      return true;
  }
  return false;
}
```

指定された Issue の番号が本当に存在するかを確認するために、GitHubAPI をたたいて、リポジトリ内の Issue を全て取得し、愚直に線形探索している。
見つかれば、その Issue をそのまま返し、無い場合は `"error"` という文字列を返している。

```JavaScript
function getIssue(number, prop) {
  var github = GitHubAPI.create(prop.GITHUB_OWNER, prop.GITHUB_REPO, prop.GITHUB_API_TOKEN);
  var issues = github.get('/issues?state=all');
  for (var i = 0; i < issues.length; i++) {
    if (issues[i]['number'] == number)
      return issues[i];
  }
  return 'error';
}
```

こいつも `attachments` でいい感じのメッセージにしている。

```JavaScript
function makeMessage(issue, repo, prop) {
  var user = '<' + issue['user']['html_url'] + '|' + issue['user']['login'] + '>';
  var pretext = '[' + repo + ']  Issue created by ' + user;
  var title = '#' + issue['number'] + ' ' + issue['title'];
  var title_link = issue['html_url'];
  return {
    'attachments': JSON.stringify([{
      'pretext': pretext,
      'title': title,
      'title_link': title_link,
      'color': prop.COLOR,
      'text': issue['body']
    }])
  };
}
```

## 設定側の実行

![いい感じ](/images/make-manager-bot-for-slack/slack_manager2-1_notification.jpg)

## 通知側の実装

GitHub リポジトリに Issue のコメントだけに Webhook されるようにする。
そしたら POST データを解析し、スプレッドシートの中から2列目が等しい行の1列目だけ取ってきて(高階関数最高)、POST データからいい感じのメッセージ生成して、Slack Bot に通知している。

```JavaScript
function doPost(e) {
  var jsonString = e.postData.getDataAsString();
  var jsonData = JSON.parse(jsonString);
  postMessage(jsonData);
}

function postMessage(data) {
  var prop = PropertiesService.getScriptProperties().getProperties();
  const repo = prop.GITHUB_OWNER + '/' + prop.GITHUB_REPO;

  /* いい感じにフィルタリング */
  if (data['repository']['full_name'] != repo && data['comment'] != undefined && data['issue'] != undefined) {
    throw new Error('invalid repository.');
  }

  /* Spread Sheet の読み取り*/
  /* 割愛 */

　/* 表からフックされた Issue の番号を線形探索 */
  var number = data['issue']['number'];
  var channels = table.filter(function(row){
    return row[1] == number;
  }).map(function(row){ return row[0] });

  /* いい感じのメッセージを作成 */
  var message = makeMessage(data['action'], data['comment'], data['issue'], repo, prop);

  /* Slack の準備*/
  /* 割愛 */

  var _ = Underscore.load();
  channels.forEach(function(channelName){
    option = _.extend(option, message);
    slackApp.postMessage(channelName, '', option);  
  })
}
```

メッセージはコメントの作成・編集・削除ごとに異なる。
ただ、編集時には編集前のコメントしか手に入らないので、GitHub API をたたいて編集後のコメントを取りに行ってる(getIssueCommentBody)。

```JavaScript
function makeMessage(action, comment, issue, repo, prop) {
  var user = '<' + comment['user']['html_url'] + '|' + comment['user']['login'] + '>';
  var issueTitle = '<' + comment['html_url'] + '|' + '#' + issue['number'] + ': ' + issue['title'] + '>';

  var actionText = '';
  var text = '';
  switch(action) {
    case 'created':
      actionText = 'New';
      text = comment['body'];
      break;
    case 'edited':
      actionText = 'Edit';
      text = getIssueCommentBody(comment['id'], prop);
      break;
    case 'deleted':
      actionText = 'Delet';
      text = comment['body'];
      break;
  }

  var pretext = '[' + repo + '] ' + actionText + ' comment by ' + user + ' on isuue ' + issueTitle;
  return {
    'attachments': JSON.stringify([{
      'pretext': pretext,
      'color': prop.COLOR,
      'text': text
    }])
  };
}

function getIssueCommentBody(id, prop) {
  var github = GitHubAPI.create(prop.GITHUB_OWNER, prop.GITHUB_REPO, prop.GITHUB_API_TOKEN);
  var comment = github.get('/issues/comments/' + id);
  return comment['body'];
}
```

## 通知側の実行

![いい感じ](/images/make-manager-bot-for-slack/slack_manager2-2_notification.jpg)

## おしまい

これで部内の問題・情報管理がさらに円滑になるはず！(願望)
