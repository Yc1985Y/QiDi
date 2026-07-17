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
  static const vivoAsrEndpoint = String.fromEnvironment(
    'VIVO_ASR_ENDPOINT',
    defaultValue: 'wss://api-ai.vivo.com.cn/asr/v2',
  );
  static const vivoAsrEngineId = String.fromEnvironment(
    'VIVO_ASR_ENGINE_ID',
    defaultValue: 'shortasrinput',
  );

  static bool get hasChatConfig => apiKey.trim().isNotEmpty;

  static bool get hasOcrConfig =>
      appId.trim().isNotEmpty && apiKey.trim().isNotEmpty;

  static bool get hasVivoAsrConfig =>
      apiKey.trim().isNotEmpty &&
      vivoAsrEndpoint.trim().isNotEmpty &&
      vivoAsrEngineId.trim().isNotEmpty;
}
