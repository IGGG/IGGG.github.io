---
title: GitHub Actions を使ってみた
date: 2019-10-11 00:00:00
tags:
  - GitHub
categories: Web
cover: "/images/use-github-actions/actions.jpg"
---

IGGG ソフトウェア基盤部のひげです。
GitHub Pages へのデプロイに GitHub Actions を使ってみたので、そのことについて記事を書きます。

ちなみに [IGGG/new.iggg.org](https://github.com/IGGG/new.iggg.org) と [IGGG/IGGG.github.io](https://github.com/IGGG/IGGG.github.io) に GitHub Actions を使ってみました。

## GitHub Actions

GitHub が用意した CI/CD。

`.github/workflows` 配下に YAML ファイルで設定を置くことができます。
まだベータ版な点に注意。

- [Features • GitHub Actions · GitHub](https://github.com/features/actions)

![](/images/use-github-actions/actions.jpg)

## 設定する

やりたいことは2つ:

1. PR では静的サイトを生成できるか試す
2. メインブランチ(`master`)なら静的サイトをデプロイする(GitHub Pages)

こんな感じにした:

```
/
 |- .github
 |  |- workflows
 |  |  |- verify.yml
 |  |  \- deploy.yml
 |  \- scripts
 |     \- deploy.bash
 ...
```

うまく Condition を使って一つの YAML にまとめてもよかったんだけど、めんどくさくなったので分けた。
ファイル名から察せれる通り、`verify.yml` が (1) を `deploy.yml` が (2) のための設定ファイルだ。

### verify.yml

`verify.yml` は次の通り:

```Yaml
name: Verify PR
on: pull_request
jobs:
  build:
    runs-on: ubuntu-18.04
    steps:
    - uses: actions/checkout@v1
      with:
        fetch-depth: 1
        submodules: true
    - name: Setup Hugo
      uses: peaceiris/actions-hugo@v2.2.1
      with:
        hugo-version: '0.58.3'
    - name: Build
      run: hugo --gc --cleanDestinationDir --minify --config config-prod.toml
    - name: display status
      uses: docker://buildpack-deps:18.04-scm
      with:
        entrypoint: git
        args: status
```

(ちなみにこれは IGGG/new.iggg.org の方で、これは Hugo による静的サイト)

`on: pull_request` と記述することで PR に対してのみ動作します。
`jobs` 以下が実際の動作の内容で、各ステップでは状態を共有します。
`uses` で GitHub Actions で実行するアクション(リポジトリ)を指定できます([`actions` で始まるものは公式です](https://github.com/actions)):

- [actions/checkout - GitHub](https://github.com/actions/checkout)
    - 対象のリポジトリのブランチへクローンしてチェックアウトする
    - `frtch-depth: 1` とすることでシャロークローンしてくれます
    - `submodules: true` とすることで `--recursive` オプション付きでクローンしてくれます(Hugo は利用するテーマを submodule として置くことが多い)
- [peaceiris/actions-hugo - GitHub](https://github.com/peaceiris/actions-hugo)
    - Hugo をセットアップする
    - `hugo-version` でバージョンを指定できる

`docker://xxx` という指定をすることで、Docker Hub などの Docker イメージのレジストリから直接指定することもできます。
で、結局このジョブは、単純に Hugo をビルドしてみてるだけですね。

### deploy.yml

ここからが鬼門。
対象は GitHub Pages なので、デプロイするとはすなわち GitHub にプッシュすることですね。
その時に CI 側に権限を与える必要があるのですが、個人的にパーソナルトークンを使うのがいやで、可能ならリポジトリごとに設定できる SSH 鍵を使いたい。

そのように設定した `deploy.yml` は次の通り:

```yaml
name: Deploy GitHub Pages
on:
  push:
    branches:
    - master
    paths-ignore:
    - "docs/**"
jobs:
  build:
    runs-on: ubuntu-18.04
    steps:
    - uses: actions/checkout@v1
      with:
        fetch-depth: 1
        submodules: true
    - name: Setup Hugo
      uses: peaceiris/actions-hugo@v2.2.1
      with:
        hugo-version: '0.58.3'
    - name: Build
      run: hugo --gc --cleanDestinationDir --minify --config config-prod.toml
    - name: deploy
      uses: docker://buildpack-deps:18.04-scm
      env:
        DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }}
        GIT_NAME: Bot
        GIT_EMAIL: example@example.com
        TARGET_BRANCH: master
      with:
        entrypoint: /bin/bash
        args: .github/scripts/deploy.bash
```

`on.push.branches` でこのワークフローが動作するブランチを指定しています。
`on.push.paths-ignore: ["docs/**"]` とすることで、もし **差分が `docs` 配下にしかない場合は動作しない** ようにしています。
この `paths-ignore` と `**` は最近追加された機能で、詳しくは後述します。

`jobs` の前半は `verify.yml` と同じです。
違うのは `name: deploy` のステップだけ。
これは `.github/scripts/deploy.bash` を実行しているだけですね。
中身を見てます:

```bash
#!/bin/bash
set -eux

# ssh agent のセットアップ
## DEPLOY_KEY 環境変数に secret から秘密鍵を与える
eval "$(ssh-agent -s)"
mkdir -p /root/.ssh
ssh-keyscan -t rsa github.com > /root/.ssh/known_hosts
echo "${DEPLOY_KEY}" > /root/.ssh/id_rsa
chmod 400 /root/.ssh/id_rsa

# コミットするための準備
## GITHUB_REPOSITORY は GitHub Actions が用意してくれてる環境変数
git config user.name "${GIT_NAME}"
git config user.email "${GIT_EMAIL}"
git remote set-url origin git@github.com:${GITHUB_REPOSITORY}.git

# docs 配下の差分だけ TARGET_BRANCH にプッシュする
git checkout ${TARGET_BRANCH}
git status
git add docs
git diff --staged --quiet || git commit -m "Update docs by GitHub Actions"
git push origin ${TARGET_BRANCH}
```

`DEPLOY_KEY` で指定する SSH 鍵はリポジトリごとに設定するものを指定しています(その方が権限管理が楽で個人的には好みです)。
`git diff --staged --quiet || git commit -m "..."` することで `docs` 配下に差分があった時にだけコミットを作ります。
もし差分がなく、コミットを作らなかった場合は `git push` は変更がなかったとメッセージを吐いて終了します。
`docs` 配下に差分があった時だけプッシュすることで `on.push.paths-ignore: ["docs/**"]` と組み合わさって、GitHub Actions によるプッシュ(デプロイ)で GitHub Actions が再度動作することは無くなります(残念ながら `skip ci` のような機能は現状無いので)。
さて、これでリポジトリごとの SSH 鍵でデプロイする設定ができました！

ちなみに、本当は Secret に秘密鍵を直接置くのは嫌なんですけど、、、まぁとりあえず妥協しました。

## 躓いたこと: on.push.paths

公式ドキュメントには当時、以下のようにすれば「`docs` 配下にのみ差分があったら動作しないようにできる」と書いてありました:

```yaml
on:
  push:
    paths:
    - '*'
    - '!/docs/*'
```

これではうまくいきません。
色々調べた結果、`*` はディレクトリ階層を掘ってはくれないのです。
[これ](https://github.community/t5/GitHub-Actions/GitHub-Actions-workflow-not-triggered-with-path/m-p/30321#M400)を読む限り、これはどうやら Go のモジュールの仕様らしいですね。
もし `*.md` の差分だけ動作して欲しい場合は:

```yaml
on:
  push:
    paths:
    - '*.md'
    - '*/*.md'
    - '*/*/*.md'
    - '*/*/*/*.md'    
```

みたいなアホな設定をする必要がありました。
「ベータだなぁ〜」って思ってた矢先、なんと神アップデートがありました:

- [GitHub Actions – event filtering updates](https://github.blog/changelog/2019-09-30-github-actions-event-filtering-updates)

`**` でディレクトリ階層を吸収してくれるのです。
つまり、`**/*.md` と書けば任意の深さのマークダウンの差分を検知してくれます。
また、`paths-ignore` は `!` を省くことができる機能ですね。

## おしまい

GitHub Actions を初めて使ってみましたが、結構満足してます(`paths` の修正のおかげで)。
あとはキャッシュぐらいかな。
それと、同じ GitHub 内だし GitHub Actions 用の SSH 鍵を設定する機能を公式が用意して欲しい。
