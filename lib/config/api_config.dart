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
