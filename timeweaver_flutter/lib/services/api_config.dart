class ApiConfig {
  static const appId = String.fromEnvironment('VLM_APP_ID');
  static const apiKey = String.fromEnvironment('VLM_API_KEY');
  static const modelName = String.fromEnvironment(
    'VLM_MODEL_NAME',
    defaultValue: 'Volc-DeepSeek-V3.2',
  );
  static const apiEndpoint = String.fromEnvironment(
    'VLM_API_ENDPOINT',
    defaultValue: 'https://api-ai.vivo.com.cn/v1/chat/completions',
  );
  static const ocrEndpoint = String.fromEnvironment(
    'VLM_OCR_ENDPOINT',
    defaultValue: 'https://api-ai.vivo.com.cn/ocr/general_recognition',
  );

  static bool get hasChatConfig => apiKey.trim().isNotEmpty;

  static bool get hasOcrConfig =>
      appId.trim().isNotEmpty && apiKey.trim().isNotEmpty;
}
