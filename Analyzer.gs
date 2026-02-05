/**
 * 求人広告分析モジュール
 *
 * 重要な思想:
 * - 0点や全否定をしない
 * - 必ずGoodポイントを1つ以上提示する
 * - 改善点は行動単位で提示する
 * - 点数より「状態」と「変化」を重視する
 */

class JobPostingAnalyzer {
  constructor() {
    this.aiClient = new VertexAIClient();
  }

  /**
   * 求人広告を分析（フェーズ1）
   * @param {string} jobPosting - 求人広告のテキスト
   * @returns {Object} 分析結果
   */
  analyzeJobPosting(jobPosting) {
    if (!jobPosting || jobPosting.trim().length === 0) {
      throw new Error('求人広告の内容を入力してください');
    }

    const prompt = this._buildAnalysisPrompt(jobPosting);

    try {
      const result = this.aiClient.generateJSON(prompt, {
        temperature: 0.5,
        maxOutputTokens: 2048
      });

      // バリデーションと正規化
      return this._normalizeAnalysisResult(result);

    } catch (error) {
      Logger.log('Analysis Error: ' + error.toString());
      throw new Error('分析に失敗しました: ' + error.message);
    }
  }

  /**
   * 改善サンプルを生成（フェーズ2、オプション）
   * @param {string} jobPosting - 元の求人広告
   * @param {Object} analysisResult - フェーズ1の分析結果
   * @returns {string} 改善サンプル原稿
   */
  generateSample(jobPosting, analysisResult) {
    if (!jobPosting || !analysisResult) {
      throw new Error('元の求人広告と分析結果が必要です');
    }

    const prompt = this._buildSamplePrompt(jobPosting, analysisResult);

    try {
      const sample = this.aiClient.generateText(prompt, {
        temperature: 0.7,
        maxOutputTokens: 3000
      });

      return sample.trim();

    } catch (error) {
      Logger.log('Sample Generation Error: ' + error.toString());
      throw new Error('サンプル生成に失敗しました: ' + error.message);
    }
  }

  /**
   * 分析プロンプトを構築
   * @private
   */
  _buildAnalysisPrompt(jobPosting) {
    return `あなたは求人広告の専門家です。以下の求人広告を分析し、応募獲得力を評価してください。

【重要な評価方針】
- 必ず良い点を1つ以上見つけて褒めること
- 0点や全否定は絶対にしない（最低でも40点以上）
- 改善点は「具体的な行動」として提示すること
- 点数よりも「状態」と「どれくらい改善できるか」を重視すること

【求人広告】
${jobPosting}

【出力形式（JSON）】
以下のJSON形式で回答してください。マークダウンは不要です。

{
  "status": "excellent または good または needsImprovement のいずれか",
  "statusLabel": "応募獲得力のステータスを一言で（例: 強い訴求力あり、改善の余地あり、など）",
  "score": {
    "total": "総合スコア（40-100）",
    "details": {
      "title": "タイトルのスコア（10-25）",
      "description": "仕事内容のスコア（10-25）",
      "conditions": "条件・待遇のスコア（10-25）",
      "appeal": "魅力・差別化のスコア（10-25）"
    }
  },
  "goodPoints": [
    "良い点1（具体的に）",
    "良い点2（具体的に）",
    "良い点3（あれば）"
  ],
  "improvements": [
    {
      "area": "改善エリア名",
      "action": "具体的にどう改善すればいいか（行動単位で）",
      "impact": "high または medium または low",
      "impactLabel": "改善した場合の応募数への影響目安（例: +10-15%、+5-10%）"
    }
  ],
  "nextAction": "今すぐ実行すべき1つのアクション（最も効果的な改善施策）"
}

【ステータス判定基準】
- excellent: 総合75点以上。すでに高い応募獲得力あり
- good: 総合60-74点。基本は押さえているが改善余地あり
- needsImprovement: 総合40-59点。いくつかの改善で大きく向上可能

JSON形式で回答してください。`;
  }

  /**
   * サンプル生成プロンプトを構築
   * @private
   */
  _buildSamplePrompt(jobPosting, analysisResult) {
    const improvements = analysisResult.improvements || [];
    const improvementText = improvements.map(imp =>
      `・${imp.area}: ${imp.action}`
    ).join('\n');

    return `あなたは求人広告のライターです。以下の求人広告を、分析結果をもとに改善したサンプル原稿を作成してください。

【元の求人広告】
${jobPosting}

【改善すべきポイント】
${improvementText}

【次の一手】
${analysisResult.nextAction}

【出力要件】
- 元の求人広告の良い点は残す
- 改善ポイントを反映させる
- 自然で読みやすい文章にする
- 応募者の行動を促す表現を使う
- タイトルから本文まで、完全な求人広告として出力する
- 説明や前置きは不要。サンプル原稿のみを出力してください

改善サンプル原稿:`;
  }

  /**
   * 分析結果を正規化
   * @private
   */
  _normalizeAnalysisResult(result) {
    // デフォルト値を設定
    const normalized = {
      status: result.status || 'needsImprovement',
      statusLabel: result.statusLabel || '評価中',
      score: {
        total: Math.max(40, Math.min(100, result.score?.total || 50)),
        details: {
          title: result.score?.details?.title || 12,
          description: result.score?.details?.description || 12,
          conditions: result.score?.details?.conditions || 12,
          appeal: result.score?.details?.appeal || 12
        }
      },
      goodPoints: Array.isArray(result.goodPoints) && result.goodPoints.length > 0
        ? result.goodPoints
        : ['入力された内容から求人の意図が伝わっています'],
      improvements: Array.isArray(result.improvements) ? result.improvements : [],
      nextAction: result.nextAction || '求人内容をより具体的に記載しましょう'
    };

    // スコアが極端に低い場合は底上げ（全否定しない方針）
    if (normalized.score.total < 40) {
      normalized.score.total = 40;
    }

    // ステータスとスコアの整合性チェック
    if (normalized.score.total >= 75 && normalized.status !== 'excellent') {
      normalized.status = 'excellent';
    } else if (normalized.score.total >= 60 && normalized.score.total < 75 && normalized.status === 'needsImprovement') {
      normalized.status = 'good';
    }

    // goodPointsが空の場合は必ず1つ追加
    if (!normalized.goodPoints || normalized.goodPoints.length === 0) {
      normalized.goodPoints = ['求人情報を作成する意欲が素晴らしいです'];
    }

    return normalized;
  }
}

/**
 * テスト用関数
 */
function testAnalyzer() {
  const analyzer = new JobPostingAnalyzer();

  const sampleJob = `【募集職種】Webエンジニア

【仕事内容】
自社サービスの開発を担当していただきます。

【必須スキル】
- JavaScript経験1年以上

【待遇】
- 年収400万円〜
- リモートワーク可`;

  const result = analyzer.analyzeJobPosting(sampleJob);
  Logger.log(JSON.stringify(result, null, 2));
}
