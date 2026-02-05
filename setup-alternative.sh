#!/bin/bash

# 求人広告分析ツール - 代替セットアップスクリプト
# 既存ファイルがある場合の対応版

set -e

echo "=============================================="
echo "  求人広告分析ツール - 自動セットアップ"
echo "=============================================="
echo ""

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# claspがインストールされているか確認
if ! command -v clasp &> /dev/null; then
    echo -e "${RED}❌ claspがインストールされていません${NC}"
    echo "以下のコマンドでインストールしてください:"
    echo "  npm install -g @google/clasp"
    exit 1
fi

echo -e "${GREEN}✓ clasp がインストールされています ($(clasp --version))${NC}"
echo ""

# Step 1: ログイン確認
echo "📝 Step 1: Google アカウントへのログイン"
echo "-------------------------------------------"

if ! clasp list &> /dev/null; then
    echo -e "${YELLOW}⚠️  claspにログインしていません${NC}"
    echo ""
    echo "これからブラウザが開きますので、以下の手順で認証してください:"
    echo "  1. Googleアカウントを選択"
    echo "  2. 「Google Apps Script API」へのアクセスを許可"
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

# Step 2: 一時ディレクトリでプロジェクト作成
echo "📦 Step 2: Google Apps Script プロジェクト作成"
echo "-------------------------------------------"

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

# 一時ディレクトリを作成
TEMP_DIR=$(mktemp -d)
echo "一時ディレクトリ: $TEMP_DIR"

cd "$TEMP_DIR"

# 空のディレクトリでプロジェクト作成
clasp create --type webapp --title "求人広告分析ツール"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ プロジェクトの作成に失敗しました${NC}"
    cd -
    rm -rf "$TEMP_DIR"
    exit 1
fi

# .clasp.jsonを元のディレクトリにコピー
if [ -f ".clasp.json" ]; then
    cp .clasp.json "$OLDPWD/"
    echo -e "${GREEN}✓ プロジェクトが作成されました${NC}"
else
    echo -e "${RED}❌ .clasp.jsonが見つかりません${NC}"
    cd -
    rm -rf "$TEMP_DIR"
    exit 1
fi

# 元のディレクトリに戻る
cd "$OLDPWD"

# 一時ディレクトリを削除
rm -rf "$TEMP_DIR"

echo ""

# Step 3: カスタムappsscript.jsonで上書き
echo "📝 Step 3: カスタム設定を適用"
echo "-------------------------------------------"

# appsscript.jsonが既に存在する場合はそのまま使用
if [ -f "appsscript.json" ]; then
    echo -e "${GREEN}✓ カスタムappsscript.jsonを使用します${NC}"
else
    echo -e "${YELLOW}⚠️  appsscript.jsonが見つかりません${NC}"
fi

echo ""

# Step 4: ファイルをプッシュ
echo "📤 Step 4: ファイルをアップロード"
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
