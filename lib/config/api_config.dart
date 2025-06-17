class ApiConfig {
  // IMPORTANTE: Sostituire con la propria chiave API OpenAI
  // Per sicurezza, in produzione usare variabili d'ambiente
  static const String openAIApiKey =
      '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';

  // URL base per le API OpenAI
  static const String openAIBaseUrl =
      'https://api.openai.com/v1/chat/completions';

  // Modello da utilizzare
  static const String openAIModel = 'gpt-4';

  // Parametri di configurazione
  static const int maxTokens = 300;
  static const double temperature = 0.7;
}
