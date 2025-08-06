import 'package:four_secrets_wedding_app/model/chatbot_config.dart';
import 'package:four_secrets_wedding_app/model/chatbot_system_promt.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:dash_chat_2/dash_chat_2.dart';

/// 🧠 In-Memory Chat Session Manager
/// Verwaltet Chat-History nur während der App-Session
/// Automatisches Reset bei App-Neustart = Token-Ersparnis
class ChatSessionManager {
  static final ChatSessionManager _instance = ChatSessionManager._internal();
  factory ChatSessionManager() => _instance;
  ChatSessionManager._internal() {
    print('🧠 ChatSessionManager initialisiert');
    _initializeSession();
  }

  // Session Data - nur im Arbeitsspeicher
  List<Messages> _conversationHistory = [];
  List<ChatMessage> _uiMessages = [];
  String? _currentUserId;
  bool _isInitialized = false;

  // User-Definitionen für UI
  final ChatUser currentUser = ChatUser(id: "user", firstName: "Du");
  final ChatUser assistantUser =
      ChatUser(id: "assistant", firstName: "Wedding", lastName: "Planer");

  /// Initialisiert eine neue Chat-Session
  void _initializeSession() {
    print('🔄 Neue Chat-Session gestartet');

    // System Prompt hinzufügen (nur für API)
    _conversationHistory = [
      Messages(role: Role.system, content: WeddingPrompts.systemPrompt)
    ];

    // UI-Messages starten leer - Welcome Message wird separat hinzugefügt
    _uiMessages = [];

    // Unique Session ID generieren
    _currentUserId = 'wedding_session_${DateTime.now().millisecondsSinceEpoch}';
    _isInitialized = true;

    print('✅ Chat-Session bereit - ID: $_currentUserId');
  }

  /// Fügt die Willkommensnachricht hinzu (nur einmal pro Session)
  void addWelcomeMessage() {
    // ✅ Prüfung: Willkommensnachricht bereits vorhanden?
    if (_hasWelcomeMessage()) {
      print(
          '💬 Willkommensnachricht bereits vorhanden - überspringe Hinzufügung');
      return;
    }

    print('💬 Willkommensnachricht wird hinzugefügt');

    final welcomeMessage = ChatMessage(
      user: assistantUser,
      createdAt: DateTime.now(),
      text: WeddingPrompts.welcomeMessage,
    );

    // Nur zur UI hinzufügen, NICHT zur API-History
    // (System Prompt in API ist bereits ausreichend)
    _uiMessages.insert(0, welcomeMessage);

    print('✅ Willkommensnachricht hinzugefügt');
  }

  /// 🔍 Prüft ob bereits eine Willkommensnachricht existiert
  bool _hasWelcomeMessage() {
    if (_uiMessages.isEmpty) return false;

    // Prüfe die letzte Message (sollte die Willkommensnachricht sein)
    final lastMessage = _uiMessages.last;
    return lastMessage.user.id == "assistant" &&
        lastMessage.text
            .contains("herzlich willkommen im 4secrets Wedding-Chat");
  }

  /// Gibt aktuelle UI-Messages zurück
  List<ChatMessage> get messages => List.unmodifiable(_uiMessages);

  /// Gibt Conversation History für API zurück
  List<Messages> get conversationHistory =>
      List.unmodifiable(_conversationHistory);

  /// Gibt aktuelle User ID zurück
  String get userId => _currentUserId ?? 'unknown';

  /// Prüft ob Session initialisiert ist
  bool get isInitialized => _isInitialized;

  /// Fügt eine User-Message hinzu
  void addUserMessage(ChatMessage message) {
    final previewText = message.text.length > 50
        ? message.text.substring(0, 50) + '...'
        : message.text;
    print('📤 User Message hinzugefügt: $previewText');

    // Zur UI hinzufügen
    _uiMessages.insert(0, message);

    // Zur API-History hinzufügen
    _conversationHistory.add(Messages(role: Role.user, content: message.text));

    // Token-Optimierung: Alte Messages entfernen wenn zu viele
    _optimizeTokenUsage();
  }

  /// Fügt eine Assistant-Message hinzu
  void addAssistantMessage(String content) {
    final previewText =
        content.length > 50 ? content.substring(0, 50) + '...' : content;
    print('📥 Assistant Message hinzugefügt: $previewText');

    final message = ChatMessage(
      user: assistantUser,
      createdAt: DateTime.now(),
      text: content,
    );

    // Zur UI hinzufügen
    _uiMessages.insert(0, message);

    // Zur API-History hinzufügen
    _conversationHistory.add(Messages(role: Role.assistant, content: content));

    // Token-Optimierung
    _optimizeTokenUsage();
  }

  /// 💰 Token-Optimierung: Entfernt alte Messages
  void _optimizeTokenUsage() {
    // Maximal erlaubte Messages in History (ohne System Prompt)
    final maxMessages = ChatbotConfig.maxConversationHistory;

    if (_conversationHistory.length > maxMessages + 1) {
      // +1 für System Prompt
      print('🔧 Token-Optimierung: Entferne alte Messages');

      // System Prompt behalten, alte Messages entfernen
      final systemPrompt = _conversationHistory.first;
      final recentMessages = _conversationHistory
          .skip(_conversationHistory.length - maxMessages)
          .toList();

      _conversationHistory = [systemPrompt] + recentMessages;

      print(
          '💰 Token-Optimierung: ${_conversationHistory.length - 1} Messages beibehalten');
    }
  }

  /// Aktualisiert die letzte Assistant Message (für Streaming)
  void updateLastAssistantMessage(String content) {
    if (_uiMessages.isNotEmpty && _uiMessages.first.user.id == "assistant") {
      _uiMessages.first.text = content;
    }

    // Auch in Conversation History aktualisieren
    // Da Messages immutable ist, entfernen wir die letzte und fügen eine neue hinzu
    if (_conversationHistory.isNotEmpty &&
        _conversationHistory.last.role == Role.assistant) {
      _conversationHistory.removeLast();
      _conversationHistory
          .add(Messages(role: Role.assistant, content: content));
    }
  }

  /// Fügt eine neue Assistant Message für Streaming hinzu
  ChatMessage createStreamingMessage(String initialContent) {
    final message = ChatMessage(
      user: assistantUser,
      createdAt: DateTime.now(),
      text: initialContent,
    );

    _uiMessages.insert(0, message);
    return message;
  }

  /// Beendet Streaming und fügt zur History hinzu
  void finalizeStreamingMessage(String finalContent) {
    // Zur API-History hinzufügen
    _conversationHistory
        .add(Messages(role: Role.assistant, content: finalContent));

    // Token-Optimierung
    _optimizeTokenUsage();
  }

  /// Manueller Session-Reset (falls gewünscht)
  void resetSession() {
    print('🔄 Chat-Session wird zurückgesetzt');
    _initializeSession();
  }

  /// Debug-Informationen
  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'userId': _currentUserId,
      'uiMessagesCount': _uiMessages.length,
      'conversationHistoryCount': _conversationHistory.length,
      'hasSystemPrompt': _conversationHistory.isNotEmpty &&
          _conversationHistory.first.role == Role.system,
      'hasWelcomeMessage': _hasWelcomeMessage(),
      'memoryUsage':
          '${(_conversationHistory.length + _uiMessages.length)} objects',
      'lastActivity':
          _uiMessages.isNotEmpty ? _uiMessages.first.createdAt : null,
      'welcomeMessageProtected': true, // ✅ Neue Debug-Info
    };
  }

  /// Session-Statistiken für Monitoring
  Map<String, dynamic> getSessionStats() {
    final userMessages =
        _conversationHistory.where((msg) => msg.role == Role.user).length;
    final assistantMessages =
        _conversationHistory.where((msg) => msg.role == Role.assistant).length;

    return {
      'totalMessages': _conversationHistory.length - 1, // -1 für System Prompt
      'userMessages': userMessages,
      'assistantMessages': assistantMessages,
      'averageTokensPerMessage':
          'estimated: ${_conversationHistory.length * 50}',
      'sessionDuration': _currentUserId != null
          ? DateTime.now().millisecondsSinceEpoch -
              int.parse(_currentUserId!.split('_').last)
          : 0,
      'tokenOptimized': true,
      'welcomeMessageActive':
          _uiMessages.isNotEmpty && _uiMessages.last.user.id == "assistant",
    };
  }
}
