import 'dart:ui';

class ChatbotConfig {
  // Farben als Konstanten (besser als hardcoded values)
  static const Color primaryColor = Color.fromARGB(255, 107, 69, 106);
  static const Color primaryColorWithOpacity =
      Color.fromARGB(200, 107, 69, 106);

  // API Konfiguration - Optimiert für bessere Performance
  static const int maxTokens = 400; // Erhöht für bessere Antworten
  static const double temperature = 0.7; // Optimal für natürliche Antworten
  static const Duration apiTimeout =
      Duration(seconds: 45); // Erhöht für Stabilität

  // Rate Limiting - Optimiert
  static const int maxRequestsPerMinute = 12; // Reduziert für Stabilität
  static const int maxRequestsPerHour = 60; // Angepasst an typische Nutzung

  // Chat Konfiguration - Performance optimiert
  static const int maxConversationHistory = 12; // Erhöht für besseren Context
  static const int maxChatHistoryStorage = 100; // Begrenzt Chat-Speicher

  // 🛡️ INPUT VALIDIERUNG - Kostenschutz
  static const int minInputLength = 3; // Minimum Zeichen für gültigen Input
  static const int maxInputLength = 500; // Maximum Zeichen pro Message
  static const int minUniqueCharsForSpamCheck =
      4; // Minimum verschiedene Zeichen
  static const int repetitiveMessageCheckCount =
      3; // Prüfe letzte X Messages auf Duplikate

  // Performance Konfiguration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration debounceDelay = Duration(milliseconds: 300);
  static const int maxCachedMessages = 50;

  // UI Konfiguration
  static const double borderRadius = 20.0;
  static const double avatarSize = 35.0;
  static const double maxChatHeight = 0.9; // 90% der Bildschirmhöhe
  static const double minChatHeight = 0.5; // 50% der Bildschirmhöhe

  // Error Messages
  static const String apiKeyError =
      "🔑 API-Schlüssel Problem. Bitte kontaktiere den Support.";
  static const String timeoutError =
      "⏱️ Die Antwort dauert etwas länger. Bitte versuche es erneut!";
  static const String quotaError =
      "💳 API-Kontingent erschöpft. Bitte kontaktiere den Support.";
  static const String genericError =
      "💭 Momentan habe ich technische Schwierigkeiten. Versuche es gleich nochmal!";
  static const String networkError =
      "🌐 Netzwerkproblem. Bitte prüfe deine Internetverbindung.";

  // 🛡️ INPUT VALIDIERUNG Messages
  static const String emptyInputError =
      "🤔 Bitte stelle eine konkrete Frage! Leere Nachrichten kann ich nicht beantworten.";
  static const String tooShortInputError =
      "💭 Das ist etwas zu kurz für mich! Beschreibe deine Hochzeitsfrage etwas ausführlicher.";
  static const String noLettersError =
      "🔤 Bitte verwende Wörter für deine Hochzeitsfrage! Nur Zeichen oder Zahlen kann ich nicht verstehen.";
  static const String tooLongInputError =
      "📝 Das ist etwas zu lang! Bitte teile deine Frage in mehrere kürzere Nachrichten auf (max. 500 Zeichen).";
  static const String spamDetectedError =
      "🚫 Das sieht nach Spam aus! Bitte stelle eine echte Hochzeitsfrage.";
  static const String repetitiveMessageError =
      "🔄 Du hast das bereits gefragt! Bitte stelle eine neue Frage oder warte auf meine Antwort.";

  // Success Messages
  static const String chatInitialized = "✅ Chat erfolgreich gestartet!";
  static const String messageDelivered = "📤 Nachricht gesendet";

  // Validation
  static bool isValidTemperature(double temp) => temp >= 0.0 && temp <= 2.0;
  static bool isValidMaxTokens(int tokens) => tokens > 0 && tokens <= 2000;
  static bool isValidTimeout(Duration timeout) =>
      timeout.inSeconds >= 10 && timeout.inSeconds <= 120;

  // 🛡️ INPUT VALIDIERUNG Helper
  static bool isValidInputLength(String text) =>
      text.trim().length >= minInputLength &&
      text.trim().length <= maxInputLength;

  static bool hasEnoughUniqueChars(String text) {
    if (text.length <= 10) return true; // Kurze Texte sind OK
    final uniqueChars = text.split('').toSet().length;
    return uniqueChars >= minUniqueCharsForSpamCheck;
  }
}
