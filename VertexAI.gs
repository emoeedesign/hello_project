/**
 * Vertex AI (Gemini) 連携モジュール
 *
 * セットアップ:
 * 1. スクリプトプロパティに以下を設定:
 *    - VERTEX_AI_PROJECT_ID: GCPプロジェクトID
 *    - VERTEX_AI_LOCATION: リージョン（例: us-central1）
 * 2. GASプロジェクトでGoogle Cloud Platformプロジェクトを設定
 * 3. Vertex AI APIを有効化
 */

class VertexAIClient {
  constructor() {
    const props = PropertiesService.getScriptProperties();
    this.projectId = props.getProperty('VERTEX_AI_PROJECT_ID');
    this.location = props.getProperty('VERTEX_AI_LOCATION') || 'us-central1';
    this.model = 'gemini-1.5-pro';

    if (!this.projectId) {
      throw new Error('VERTEX_AI_PROJECT_IDが設定されていません。スクリプトプロパティを確認してください。');
    }
  }

  /**
   * Geminiにテキストリクエストを送信
   * @param {string} prompt - プロンプト
   * @param {Object} options - オプション設定
   * @param {number} options.temperature - 温度（0-1）
   * @param {number} options.maxOutputTokens - 最大トークン数
   * @returns {string} レスポンステキスト
   */
  generateText(prompt, options = {}) {
    const temperature = options.temperature || 0.7;
    const maxOutputTokens = options.maxOutputTokens || 2048;

    const endpoint = `https://${this.location}-aiplatform.googleapis.com/v1/projects/${this.projectId}/locations/${this.location}/publishers/google/models/${this.model}:generateContent`;

    const payload = {
      contents: [{
        role: 'user',
        parts: [{
          text: prompt
        }]
      }],
      generationConfig: {
        temperature: temperature,
        maxOutputTokens: maxOutputTokens,
        topP: 0.95,
        topK: 40
      },
      safetySettings: [
        {
          category: 'HARM_CATEGORY_HARASSMENT',
          threshold: 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          category: 'HARM_CATEGORY_HATE_SPEECH',
          threshold: 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          threshold: 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          category: 'HARM_CATEGORY_DANGEROUS_CONTENT',
          threshold: 'BLOCK_MEDIUM_AND_ABOVE'
        }
      ]
    };

    try {
      const response = UrlFetchApp.fetch(endpoint, {
        method: 'post',
        contentType: 'application/json',
        headers: {
          'Authorization': 'Bearer ' + ScriptApp.getOAuthToken()
        },
        payload: JSON.stringify(payload),
        muteHttpExceptions: false
      });

      const result = JSON.parse(response.getContentText());

      if (result.candidates && result.candidates.length > 0) {
        const candidate = result.candidates[0];
        if (candidate.content && candidate.content.parts && candidate.content.parts.length > 0) {
          return candidate.content.parts[0].text;
        }
      }

      throw new Error('レスポンスが空です');

    } catch (error) {
      Logger.log('Vertex AI API Error: ' + error.toString());
      throw new Error('AI処理に失敗しました: ' + error.message);
    }
  }

  /**
   * JSON形式でのレスポンスを期待するリクエスト
   * @param {string} prompt - プロンプト
   * @param {Object} options - オプション設定
   * @returns {Object} パースされたJSONオブジェクト
   */
  generateJSON(prompt, options = {}) {
    const text = this.generateText(prompt, options);

    try {
      // JSON部分を抽出（マークダウンコードブロックを除去）
      let jsonText = text.trim();

      // ```json ... ``` の形式を処理
      if (jsonText.startsWith('```')) {
        const lines = jsonText.split('\n');
        lines.shift(); // 最初の```jsonを削除
        if (lines[lines.length - 1].trim() === '```') {
          lines.pop(); // 最後の```を削除
        }
        jsonText = lines.join('\n');
      }

      return JSON.parse(jsonText);

    } catch (error) {
      Logger.log('JSON Parse Error: ' + error.toString());
      Logger.log('Response Text: ' + text);
      throw new Error('JSONのパースに失敗しました: ' + error.message);
    }
  }
}

/**
 * モジュールのテスト関数
 */
function testVertexAI() {
  const client = new VertexAIClient();
  const result = client.generateText('こんにちは！あなたの名前を教えてください。', {
    temperature: 0.5,
    maxOutputTokens: 100
  });
  Logger.log(result);
}
