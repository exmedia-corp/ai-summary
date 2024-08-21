#!/bin/bash

# AIへ要約を求めるプロンプト
PROMPT="以下のBacklogのログを元に、その一週間で発生した重要な出来事を要約してください。\
要約では、時系列ではなく、週単位で発生したイベントをまとめ、各イベントの経緯と結論に至るプロセスを明記してください。\
各出来事には必ず該当するBacklogの課題番号を含めてください。\
また、プロジェクトやタスクの進捗状況、課題解決のプロセスがどのように進行したかについても説明してください。"

# 環境変数からBacklogのスペースIDとAPIキーを取得
BACKLOG_SPACE="${BACKLOG_SPACE}"
API_KEY="${BACKLOG_API_KEY}"

# APIエンドポイント
ENDPOINT="https://${BACKLOG_SPACE}.backlog.com/api/v2/space/activities"

# オプションを指定
COUNT=100
PROJECT_KEY=""
DATE=$(date -u -v-1w +"%Y-%m-%d")

# オプションを解析
while getopts ":c:p:d:" opt; do
    case ${opt} in
        c )
            COUNT=$OPTARG
            ;;
        p )
            PROJECT_KEY=$OPTARG
            ;;
        d )
            DATE=$(date -u -j -f "%Y-%m-%d" "$OPTARG" +"%Y-%m-%dT%H:%M:%SZ")
            ;;
        \? )
            echo "Invalid option: $OPTARG" 1>&2
            usage
            ;;
        : )
            echo "Option -$OPTARG requires an argument." 1>&2
            usage
            ;;
    esac
done
shift $((OPTIND -1))

# type変換の関数
convert_type() {
  local type_value=$1
  case $type_value in
    1) echo "課題の追加" ;;
    2) echo "課題の更新" ;;
    3) echo "課題にコメント" ;;
    4) echo "課題の削除" ;;
    5) echo "Wikiを追加" ;;
    6) echo "Wikiを更新" ;;
    7) echo "Wikiを削除" ;;
    8) echo "共有ファイルを追加" ;;
    9) echo "共有ファイルを更新" ;;
    10) echo "共有ファイルを削除" ;;
    11) echo "Subversionコミット" ;;
    12) echo "GITプッシュ" ;;
    13) echo "GITリポジトリ作成" ;;
    14) echo "課題をまとめて更新" ;;
    15) echo "ユーザーがプロジェクトに参加" ;;
    16) echo "ユーザーがプロジェクトから脱退" ;;
    17) echo "コメントにお知らせを追加" ;;
    18) echo "プルリクエストの追加" ;;
    19) echo "プルリクエストの更新" ;;
    20) echo "プルリクエストにコメント" ;;
    21) echo "プルリクエストの削除" ;;
    22) echo "マイルストーンの追加" ;;
    23) echo "マイルストーンの更新" ;;
    24) echo "マイルストーンの削除" ;;
    25) echo "グループがプロジェクトに参加" ;;
    26) echo "グループがプロジェクトから脱退" ;;
    *) echo "不明なtype" ;;
  esac
}

# 最近の更新を取得
response=$(curl -s -X GET "${ENDPOINT}?apiKey=${BACKLOG_API_KEY}&count=${COUNT}" -H "Content-Type: application/json")

# 制御文字を除去
cleaned_response=$(echo "$response" | tr -d '\000-\037')

# JSONとして有効か確認
echo "$cleaned_response" | jq . > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: JSON is not valid."
    exit 1
fi

# 取得したデータをフィルタリングして表示
filtered_response=$(echo "$cleaned_response" | jq -r '
    .[] | {
        date: .created,
        name: .createdUser.name,
        type: (try (if .type == 1 then "課題の追加"
                    elif .type == 2 then "課題の更新"
                    elif .type == 3 then "課題にコメント"
                    else "不明なtype"
                    end) catch "不明なtype"),
        issueKey: "\(.project.projectKey)-\(.content.key_id)",
        summary: .content.summary,
        comment: .content.comment.content
    }'
)

# dateによってフィルタリング
filtered_response=$(echo "$filtered_response" | jq  "select(.date >= \"$DATE\")")

# issueKeyが指定されている場合はフィルタリング
if [ -n "$PROJECT_KEY" ]; then
    filtered_response=$(echo "$filtered_response" | jq "select(.issueKey | startswith(\"$PROJECT_KEY\"))")
fi

echo "$PROMPT\n"
echo "$filtered_response" | jq .
