/**
 * 求人広告分析 Web App - メインエントリーポイント
 *
 * Google Apps Script Web Appとして動作
 */

/**
 * Web Appのエントリーポイント
 * @returns {HtmlOutput} HTMLページ
 */
function doGet() {
  try {
    return HtmlService.createHtmlOutputFromFile('index')
      .setTitle('求人広告 応募獲得力分析')
      .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
  } catch (error) {
    Logger.log('doGet Error: ' + error.toString());
    return HtmlService.createHtmlOutput(
      '<h1>エラー</h1><p>アプリケーションの読み込みに失敗しました。</p>' +
      '<p>エラー: ' + error.message + '</p>'
    );
  }
}

/**
 * 求人広告を分析（フェーズ1）
 * フロントエンドから呼び出されるAPI
 *
 * @param {string} jobPosting - 求人広告のテキスト
 * @returns {Object} 分析結果
 */
function analyzeJobPostingAPI(jobPosting) {
  try {
    // 入力検証
    if (!jobPosting || typeof jobPosting !== 'string') {
      throw new Error('求人広告のテキストを入力してください');
    }

    if (jobPosting.trim().length < 10) {
      throw new Error('求人広告の内容が短すぎます。もう少し詳しく入力してください。');
    }

    if (jobPosting.length > 10000) {
      throw new Error('求人広告の内容が長すぎます。10,000文字以内にしてください。');
    }

    // 分析実行
    const analyzer = new JobPostingAnalyzer();
    const result = analyzer.analyzeJobPosting(jobPosting);

    // ログ記録（デバッグ用）
    Logger.log('Analysis completed successfully');
    Logger.log('Status: ' + result.status);
    Logger.log('Score: ' + result.score.total);

    return {
      success: true,
      data: result
    };

  } catch (error) {
    Logger.log('analyzeJobPostingAPI Error: ' + error.toString());

    // エラーレスポンス
    return {
      success: false,
      error: error.message || '分析中にエラーが発生しました'
    };
  }
}

/**
 * 改善サンプルを生成（フェーズ2）
 * フロントエンドから呼び出されるAPI
 *
 * @param {string} jobPosting - 元の求人広告
 * @param {Object} analysisResult - フェーズ1の分析結果
 * @returns {Object} サンプル生成結果
 */
function generateSampleAPI(jobPosting, analysisResult) {
  try {
    // 入力検証
    if (!jobPosting || typeof jobPosting !== 'string') {
      throw new Error('元の求人広告が必要です');
    }

    if (!analysisResult || typeof analysisResult !== 'object') {
      throw new Error('分析結果が必要です');
    }

    // サンプル生成
    const analyzer = new JobPostingAnalyzer();
    const sample = analyzer.generateSample(jobPosting, analysisResult);

    // ログ記録
    Logger.log('Sample generation completed successfully');
    Logger.log('Sample length: ' + sample.length);

    return {
      success: true,
      data: {
        sample: sample
      }
    };

  } catch (error) {
    Logger.log('generateSampleAPI Error: ' + error.toString());

    return {
      success: false,
      error: error.message || 'サンプル生成中にエラーが発生しました'
    };
  }
}

/**
 * スクリプトプロパティの設定状況を確認
 * デバッグ用関数
 */
function checkConfiguration() {
  const props = PropertiesService.getScriptProperties();
  const projectId = props.getProperty('VERTEX_AI_PROJECT_ID');
  const location = props.getProperty('VERTEX_AI_LOCATION');

  Logger.log('=== Configuration Check ===');
  Logger.log('VERTEX_AI_PROJECT_ID: ' + (projectId ? '設定済み' : '未設定'));
  Logger.log('VERTEX_AI_LOCATION: ' + (location || 'デフォルト (us-central1)'));

  if (!projectId) {
    Logger.log('⚠️ VERTEX_AI_PROJECT_IDを設定してください');
    Logger.log('設定方法: プロジェクト設定 > スクリプト プロパティ');
  } else {
    Logger.log('✅ 設定完了');
  }
}

/**
 * サンプルデータでテスト実行
 * デバッグ用関数
 */
function testWithSampleData() {
  const sampleJob = `【募集職種】Webエンジニア（フルスタック）

【仕事内容】
当社の自社プロダクト開発チームにて、フロントエンドからバックエンドまで幅広く開発を担当していただきます。
React、Node.js、AWSを使用した開発経験を活かせるポジションです。

【必須スキル】
- JavaScript/TypeScript経験2年以上
- Reactでの開発経験1年以上
- チーム開発の経験

【歓迎スキル】
- Node.js、Express
- AWS (EC2, S3, Lambda等)
- Docker, Kubernetes

【待遇・福利厚生】
- 年収450万円〜700万円（経験・スキルに応じて決定）
- リモートワーク可（週2-3日出社）
- フレックスタイム制
- 各種社会保険完備
- 書籍購入補助

【勤務地】
東京都渋谷区（渋谷駅徒歩5分）`;

  Logger.log('=== Testing with sample data ===');

  const result = analyzeJobPostingAPI(sampleJob);

  if (result.success) {
    Logger.log('✅ Analysis successful');
    Logger.log(JSON.stringify(result.data, null, 2));
  } else {
    Logger.log('❌ Analysis failed');
    Logger.log('Error: ' + result.error);
  }
}
