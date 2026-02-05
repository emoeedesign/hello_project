#!/bin/bash

# 求人広告分析ツール - セットアップスクリプト
# このスクリプトはGoogle Apps Scriptプロジェクトを作成し、ファイルをアップロードします

set -e  # エラーが発生したら停止

echo "=============================================="
echo "  求人広告分析ツール - 自動セットアップ"
echo "=============================================="
echo ""

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# claspがインストールされているか確認
if ! command -v clasp &> /dev/null; then
    echo -e "${RED}❌ claspがインストールされていません${NC}"
    echo "以下のコマンドでインストールしてください:"
    echo "  npm install -g @google/clasp"
    exit 1
fi

echo -e "${GREEN}✓ clasp がインストールされています ($(clasp --version))${NC}"
echo ""

# ログイン状態を確認
echo "📝 Step 1: Google アカウントへのログイン"
echo "-------------------------------------------"

if clasp login --status 2>&1 | grep -q "not logged in"; then
    echo -e "${YELLOW}⚠️  claspにログインしていません${NC}"
    echo ""
    echo "これからブラウザが開きますので、以下の手順で認証してください:"
    echo "  1. Googleアカウントを選択"
    echo "  2. 「Google Apps Script API」へのアクセスを許可"
    echo "  3. 「このアプリは確認されていません」と表示される場合:"
    echo "     → 「詳細」をクリック → 「(プロジェクト名)に移動」をクリック"
    echo ""
    read -p "準備ができたらEnterキーを押してください..."

    clasp login

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ ログインに失敗しました${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ すでにログイン済みです${NC}"
fi

echo ""

# 既存の.clasp.jsonがあるか確認
if [ -f ".clasp.json" ]; then
    echo -e "${YELLOW}⚠️  既存の.clasp.jsonが見つかりました${NC}"
    read -p "上書きして新しいプロジェクトを作成しますか? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "セットアップをキャンセルしました"
        exit 0
    fi
    rm .clasp.json
fi

# appsscript.jsonを一時的にバックアップ
if [ -f "appsscript.json" ]; then
    echo "appsscript.jsonをバックアップ中..."
    mv appsscript.json appsscript.json.backup
fi

# Google Apps Scriptプロジェクトを作成
echo ""
echo "📦 Step 2: Google Apps Script プロジェクト作成"
echo "-------------------------------------------"
echo "プロジェクト名: 求人広告分析ツール"
echo ""

clasp create --type webapp --title "求人広告分析ツール"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ プロジェクトの作成に失敗しました${NC}"
    # バックアップを復元
    if [ -f "appsscript.json.backup" ]; then
        mv appsscript.json.backup appsscript.json
    fi
    exit 1
fi

# カスタムappsscript.jsonを復元
if [ -f "appsscript.json.backup" ]; then
    echo "カスタム設定を復元中..."
    mv appsscript.json.backup appsscript.json
fi

echo -e "${GREEN}✓ プロジェクトが作成されました${NC}"
echo ""

# ファイルをプッシュ
echo "📤 Step 3: ファイルをアップロード"
echo "-------------------------------------------"

clasp push

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ファイルのアップロードに失敗しました${NC}"
    exit 1
fi

echo -e "${GREEN}✓ ファイルがアップロードされました${NC}"
echo ""

# プロジェクト情報を取得
SCRIPT_ID=$(grep "scriptId" .clasp.json | cut -d'"' -f4)

echo "=============================================="
echo -e "${GREEN}🎉 セットアップが完了しました！${NC}"
echo "=============================================="
echo ""
echo "📋 プロジェクト情報:"
echo "  • Script ID: $SCRIPT_ID"
echo "  • URL: https://script.google.com/d/$SCRIPT_ID/edit"
echo ""
echo "📍 次のステップ:"
echo ""
echo -e "${BLUE}1. Google Cloud Platform の設定${NC}"
echo "   以下のURLにアクセスしてください:"
echo "   https://console.cloud.google.com/"
echo ""
echo "   実施内容:"
echo "   a) 新しいプロジェクトを作成（または既存を選択）"
echo "   b) Vertex AI API を有効化"
echo "   c) プロジェクトIDをメモ"
echo ""
echo -e "${BLUE}2. Google Apps Script でGCPプロジェクトをリンク${NC}"
echo "   https://script.google.com/d/$SCRIPT_ID/edit"
echo ""
echo "   実施内容:"
echo "   a) 左メニューの「プロジェクトの設定」（⚙アイコン）を開く"
echo "   b) 「Google Cloud Platform (GCP) プロジェクト」で「プロジェクトを変更」"
echo "   c) GCPプロジェクト番号を入力"
echo ""
echo -e "${BLUE}3. スクリプトプロパティの設定${NC}"
echo "   同じ設定画面で:"
echo ""
echo "   a) 「スクリプト プロパティ」セクションで「プロパティを追加」"
echo "   b) 以下を追加:"
echo "      プロパティ: VERTEX_AI_PROJECT_ID"
echo "      値: <あなたのGCPプロジェクトID>"
echo ""
echo -e "${BLUE}4. デプロイ${NC}"
echo "   設定が完了したら、以下のコマンドを実行:"
echo ""
echo "   ${GREEN}./deploy.sh${NC}"
echo ""
echo "=============================================="
echo ""
