#!/bin/bash

. .env

url="https://${BACKLOG_SPACE_ID}.backlog.com/api/v2/projects/${BACKLOG_PROJECT_KEY}/activities?apiKey=${BACKLOG_API_KEY}&count=100"
curl -s $url > _output.json

current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
one_week_ago=$(date -u -v-7d +"%Y-%m-%dT13:00:00")

json=$(jq --arg start_date "$one_week_ago" --arg end_date "$current_date" '
    .[] | select(.created >= $start_date and .created <= $end_date)
' _output.json)


echo "<ask>
以下の指示に従ってください。

- 活動ログに含まれる全てのチケットの進捗状況を説明してください。
- 各チケットの課題がどのように解決されたのか、または進行中であれば現状の状況を説明してください。
- content.summaryはチケットの概要です。
- content.key_idがチケットのキーです。
- 出力例:
     - <Backlogの課題キーと課題名>
      イベント: <詳細なイベント(最大200文字程度)>
      経緯: <詳細な経緯(最大200文字程度)>
      結論: <詳細な結論(最大200文字程度)>
</ask>
<!-- 以下のJSONはBacklogの活動ログを含みます。 -->
<json>
$json
</json>"
