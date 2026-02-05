#!/bin/bash

# 求人広告分析ツール - デプロイスクリプト
# このスクリプトはGoogle Apps Scriptプロジェクトをデプロイします

set -e  # エラーが発生したら停止

echo "=============================================="
echo "  求人広告分析ツール - デプロイ"
echo "=============================================="
echo ""

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# .clasp.jsonが存在するか確認
if [ ! -f ".clasp.json" ]; then
    echo -e "${RED}❌ .clasp.jsonが見つかりません${NC}"
    echo "先に ./setup.sh を実行してください"
    exit 1
fi

# スクリプトIDを取得
SCRIPT_ID=$(grep "scriptId" .clasp.json | cut -d'"' -f4)

echo "📋 プロジェクト情報:"
echo "  • Script ID: $SCRIPT_ID"
echo "  • URL: https://script.google.com/d/$SCRIPT_ID/edit"
echo ""

# 最新のファイルをプッシュ
echo "📤 Step 1: 最新ファイルをアップロード"
echo "-------------------------------------------"

clasp push

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ファイルのアップロードに失敗しました${NC}"
    exit 1
fi

echo -e "${GREEN}✓ ファイルがアップロードされました${NC}"
echo ""

# デプロイ
echo "🚀 Step 2: デプロイ実行"
echo "-------------------------------------------"
echo ""

# 既存のデプロイを確認
echo "既存のデプロイを確認中..."
DEPLOYMENTS=$(clasp deployments 2>&1)

# デプロイIDを抽出（@HEADを除く）
DEPLOYMENT_ID=$(echo "$DEPLOYMENTS" | grep -E "^- " | grep -v "@HEAD" | head -1 | awk '{print $2}')

if [ -z "$DEPLOYMENT_ID" ]; then
    echo -e "${YELLOW}新規デプロイを作成します${NC}"
    echo ""

    # 新規デプロイ
    DEPLOY_OUTPUT=$(clasp deploy --description "Production deployment $(date '+%Y-%m-%d %H:%M:%S')")

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ デプロイに失敗しました${NC}"
        echo "$DEPLOY_OUTPUT"
        exit 1
    fi

    # デプロイIDを取得
    NEW_DEPLOYMENT_ID=$(echo "$DEPLOY_OUTPUT" | grep -oE '@[0-9]+' | head -1 | sed 's/@//')

    echo -e "${GREEN}✓ 新規デプロイが作成されました (ID: $NEW_DEPLOYMENT_ID)${NC}"

else
    echo -e "${YELLOW}既存のデプロイを更新します (ID: $DEPLOYMENT_ID)${NC}"
    echo ""

    # バージョンを作成
    clasp version "Update: $(date '+%Y-%m-%d %H:%M:%S')"

    # 既存のデプロイを更新
    DEPLOY_OUTPUT=$(clasp deploy --deploymentId "$DEPLOYMENT_ID" --description "Updated deployment $(date '+%Y-%m-%d %H:%M:%S')")

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ デプロイの更新に失敗しました${NC}"
        echo "$DEPLOY_OUTPUT"
        exit 1
    fi

    echo -e "${GREEN}✓ デプロイが更新されました${NC}"
fi

echo ""

# WebアプリのURLを取得
echo "🌐 Step 3: WebアプリURL取得"
echo "-------------------------------------------"
echo ""

# デプロイ情報を再取得
DEPLOYMENTS=$(clasp deployments)

# WebアプリのURLを抽出
WEB_APP_URL=$(echo "$DEPLOYMENTS" | grep -oE 'https://[^ ]*exec' | head -1)

if [ -z "$WEB_APP_URL" ]; then
    echo -e "${YELLOW}⚠️  WebアプリのURLを自動取得できませんでした${NC}"
    echo ""
    echo "以下のURLで手動で確認してください:"
    echo "https://script.google.com/d/$SCRIPT_ID/edit"
    echo ""
    echo "確認方法:"
    echo "1. 右上の「デプロイ」→「デプロイを管理」"
    echo "2. 「ウェブアプリ」のURLをコピー"
else
    echo -e "${GREEN}✓ WebアプリのURLを取得しました${NC}"
fi

echo ""
echo "=============================================="
echo -e "${GREEN}🎉 デプロイが完了しました！${NC}"
echo "=============================================="
echo ""

if [ ! -z "$WEB_APP_URL" ]; then
    echo "🌐 アプリのURL:"
    echo ""
    echo "  ${BLUE}${WEB_APP_URL}${NC}"
    echo ""
    echo "このURLをブラウザで開いてアプリを使用できます"
else
    echo "📍 次のステップ:"
    echo ""
    echo "1. Google Apps Scriptエディタを開く:"
    echo "   https://script.google.com/d/$SCRIPT_ID/edit"
    echo ""
    echo "2. 右上の「デプロイ」→「デプロイを管理」"
    echo ""
    echo "3. 「ウェブアプリ」のURLをコピー"
fi

echo ""
echo "=============================================="
echo ""

# 設定確認関数の実行を提案
echo -e "${BLUE}💡 Tips:${NC}"
echo ""
echo "• スクリプトプロパティが正しく設定されているか確認:"
echo "  Apps Scriptエディタで以下を実行:"
echo "  関数: checkConfiguration"
echo ""
echo "• サンプルデータでテスト:"
echo "  関数: testWithSampleData"
echo ""
