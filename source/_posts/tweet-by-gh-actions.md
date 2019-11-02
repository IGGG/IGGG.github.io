---
title: GitHub Actions でブログの更新をツイートする
date: 2019-11-03 10:00:00
tags:
  - GitHub
  - Python
  - JavaScript
categories: Web
cover: "/images/tweet-by-gh-actions/gh-actions-log.jpg"
photos: "/images/tweet-by-gh-actions/gh-actions-log.jpg"
---

![](/images/tweet-by-gh-actions/ikisatsu.jpg)

面白そうだったので先に作っちゃいました。
[GitHub Actions 自体はすでに導入した](https://iggg.github.io/2019/10/11/use-github-actions)ので、あとは Tweet をできるようにするだけです。

## ツイートメッセージを組み立てる

こういう感じにツイートしたい:

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">【ブログを更新しました】libnss-json 始めました <a href="https://t.co/M6g35h7vuj">https://t.co/M6g35h7vuj</a></p>&mdash; IGGG(群馬大学電子計算機研究会) (@IGGGorg) <a href="https://twitter.com/IGGGorg/status/1176865665635930112?ref_src=twsrc%5Etfw">September 25, 2019</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

このためには

1. 記事のタイトル
2. 記事のリンク

が必要ですね。これらを git の差分などから構築するために THE シェル芸します。

ブログは Hexo で作っており、記事は `source/_posts/hoge.md` に追加します。最終的なリンクは `[base_url]/YYYY/MM/DD/hoge` となるので、リンクを得るには日付の情報とファイル名が必要です。

マークダウンには front matter でタイトルや日付が書いてあります:

```markdown
---
title: GitHub Actions を使ってみた
date: 2019-10-11 00:00:00
tags:
  - GitHub
categories: Web
cover: "/images/use-github-actions/actions.jpg"
---

IGGG ソフトウェア基盤部のひげです。
...
```

これをよしなにパースします:

1. 更新の有無: `git diff fdd0928^...fdd0928 --name-only --diff-filter=A -- source/_posts/*.md`
2. (1) のファイルパス `path/to/file` からタイトル取得: `head path/to/file | grep '^title:' | sed 's/^title: *//g'`
3. (1) のファイルパスから日付を取得: `head path/to/file | grep '^date:' | sed -e 's/^date: *\([0-9]\{4\}\)-\([0-9]\{2\}\)-\([0-9]\{2\}\) .*$/\1\/\2\/\3/g'`
4. (1) のファイルパスから拡張子抜きのファイル名を取得: `echo path/to/file | sed -e 's/source\/_posts\/\(.*\)\.md/\1/'`
5. (3) の日付と (5) のファイル名から URL を取得: `echo "https://iggg,github.io/${date}/${file_name}"`

これらをするシェルスクリプトがこちら:

```bash
BASE_URL="https://iggg.github.io"
TWEET_MESSAGE=""
LATEST=0

DIFF_FILES=`git diff ${TARGET_BRANCH} --name-only --diff-filter=A -- source/_posts/*.md`
for FILE_PATH in $DIFF_FILES ; do
  TITLE=`head ${FILE_PATH} | grep '^title:' | sed 's/^title: *//g'`
  DATE=`head ${FILE_PATH} | grep '^date:' | sed -e 's/^date: *\([0-9]\{4\}\)-\([0-9]\{2\}\)-\([0-9]\{2\}\) .*$/\1\/\2\/\3/g'`
  FILE_NAME=`echo ${FILE_PATH} | sed -e 's/source\/_posts\/\(.*\)\.md/\1/'`
  MESSAGE="${TITLE} ${BASE_URL}/${DATE}/${FILE_NAME}"

  DATE_TIME=`date -d "${DATE}" '+%s'`
  if [ $DATE_TIME -gt $LATEST ] ; then
    TWEET_MESSAGE="【ブログを更新しました】${MESSAGE}"
    LATEST=${DATE_TIME}
  fi
done

echo ${TWEET_MESSAGE}
```

`TARGET_BRANCH` だけ外から与えます。ループしているのは、(1) で複数投稿があった場合に最新のものだけを拾うためです。

## ツイートする

最初は curl で API でも叩けばいいかなぁって思ってたけど、OAuth とかめんどいよね。そこでひらめく、せっかく GitHub Actions だし、アクションを使えばいいんだと(天才)。

ググってもなさそうだったので作りました:

- [actions/tweet at master · matsubara0507/actions](https://github.com/matsubara0507/actions/tree/master/tweet)

Python の [`tweepy`](https://www.tweepy.org/) を使っています。理由は (1) スクリプト系の言語で (2) 扱いが簡単(クライアントオブジェクト生成してメソッド叩くだけ)で (3) 今でもメンテナンスされているのがちょうどこれだったからです(Ruby の [`twitter`](https://rubygems.org/gems/twitter) gem は2017から更新止まってた)。

使い方はこんな感じ:

```yaml
uses: matsubara0507/actions/tweet@master
with:
  consumer_key: ${{ secrets.TWITTER_CONSUMER_KEY }}
  consumer_secret: ${{ secrets.TWITTER_CONSUMER_SECRET }}
  access_token: ${{ secrets.TWITTER_ACCESS_TOKEN }}
  access_token_secret: ${{ secrets.TWITTER_ACCESS_TOKEN_SECRET }}
  message: 'This is test tweet by GitHub Actions'
```

ここで問題が1つ。どうやってさっき生成したツイートメッセージを `with.message` に渡すか。
ここで、なんかしらのコマンドの実行を与えることはどうやらできないっぽい:

```yaml
- name: Build tweet message
  # この結果を
  run: ./.github/scripts/tweet-message.bash
  shell: bash
- name: Tweet
  uses: matsubara0507/actions/tweet@master
  with:
    message: # ここに与えたい
    ...
```

この位置で変数を使うには `steps.[step_id].outputs.hoge` を作る必要がある。
しかし、これはアクション側で事前に設定するもの(少なくとも現在は)で、独自で定義することはできない:

```yaml
# こう言うのができれば良いのに
- name: Build tweet message
  id: message
  run: ./.github/scripts/tweet-message.bash
  shell: bash
  output: result # こんな構文は無い
- name: Tweet
  uses: matsubara0507/actions/tweet@master
  with:
    message: ${{ steps.message.outputs.result }}
    ...
```

だったら、なんかスクリプト実行してその出力を outputs に退避させるアクションを使えばいいんだと(天才)。
はい、ググってなさそうだったんで、ないなら作る精神:

- [actions/outputs at master · matsubara0507/actions](https://github.com/matsubara0507/actions/tree/master/outputs)

これを利用するとこんな感じでツイートできました:

```yaml
jobs:
  tweet:
    runs-on: ubuntu-18.04
    steps:
    - uses: actions/checkout@v1
    - name: Build tweet message
      uses: matsubara0507/actions/outputs@master
      id: message
      env:
        TARGET_BRANCH: HEAD^
      with:
        script_path: ./.github/scripts/tweet-message.bash
    - name: Tweet
      uses: matsubara0507/actions/tweet@master
      with:
        consumer_key: ${{ secrets.TWITTER_CONSUMER_KEY }}
        consumer_secret: ${{ secrets.TWITTER_CONSUMER_SECRET }}
        access_token: ${{ secrets.TWITTER_ACCESS_TOKEN }}
        access_token_secret: ${{ secrets.TWITTER_ACCESS_TOKEN_SECRET }}
        message: ${{ steps.message.outputs.result }}
```

## おまけ: アクションの作り方

作り方は2つあります。JavaScript (TypeScript) を使う方法と Docker を使う方法。

|  | JavaScript | Docker |
| :-: | :-: | :-: |
| 仮想環境 | Linux, MacOS, Windows | Linux |
| 起動速度 | 速い | 遅い(pull or build) |
| 依存関係 | 前後に影響(たぶん) | アクションで独立 |

Docker の方が簡単ですが、JavaScript は次のステップにも影響を与えることができます。
ちなみに、`outputs` アクションは JavaScript で、`tweet` アクションは Docker で作りました。

両方とも、GitHub リポジトリにあげておけば直接利用できます。

### JavaScript の場合

- [ココを見て](https://help.github.com/en/github/automating-your-workflow-with-github-actions/creating-a-javascript-action)
- アクションのプリミティブなやつはだいたい [actions/toolkit](https://github.com/actions/toolkit) リポジトリにあります
- 使い方の例が TypeScript だったりするのが罠

### Docker の場合

- [ココを見て](https://help.github.com/en/github/automating-your-workflow-with-github-actions/creating-a-docker-container-action)
- GitHub リポジトリの場合は `docker build`
- レジストリにあげると `docker pull`

## おしまい

GitHub Actions は、いよいよ 11/13 に GA されるんで楽しみです！
