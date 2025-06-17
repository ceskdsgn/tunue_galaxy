class ApiConfig {
  // IMPORTANTE: Sostituire con la propria chiave API OpenAI
  // Per sicurezza, in produzione usare variabili d'ambiente
  static const String openAIApiKey = '';

  // URL base per le API OpenAI
  static const String openAIBaseUrl =
      'https://api.openai.com/v1/chat/completions';

  // Modello da utilizzare
  static const String openAIModel = 'gpt-4';

  // Parametri di configurazione
  static const int maxTokens = 300;
  static const double temperature = 0.7;
}
