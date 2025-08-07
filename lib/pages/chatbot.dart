import 'package:four_secrets_wedding_app/model/chatbot_api_key_manager.dart';
import 'package:four_secrets_wedding_app/model/chatbot_session_manager.dart';
import 'package:four_secrets_wedding_app/model/chatbot_config.dart';
import 'package:four_secrets_wedding_app/model/chatbot_rate_limiter.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class Chatbot extends StatefulWidget {
  const Chatbot({super.key});

  @override
  _ChatbotState createState() => _ChatbotState();
}

class _ChatbotState extends State<Chatbot> with TickerProviderStateMixin {
  // API & Session Management
  late final OpenAI _openAI;
  final ImprovedRateLimiter _rateLimiter = ImprovedRateLimiter();
  final ChatSessionManager _sessionManager = ChatSessionManager();

  // UX Improvements
  final FocusNode _inputFocusNode = FocusNode();
  final Key key = GlobalKey<MenueState>();
  final GlobalKey _dashChatKey = GlobalKey();

  // State Variables
  String OPENAI_API_KEY = "";
  bool _apiKeyLoaded = false;
  bool _hasError = false;
  String _errorMessage = "";
  bool _isTyping = false;

  // Vereinfachte Animation nur für sanftes Einblenden
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Design Konstanten
  static const Color _backgroundColor = Color(0xFFFAFAFA); // Sehr helles Grau
  static const Color _chatBackgroundColor = Colors.white;
  static const Color _primaryColor = Color.fromARGB(255, 107, 69, 106);

  @override
  void initState() {
    super.initState();
    print("🤖 Chatbot-Seite initialisiert");

    // Einfache Fade-Animation
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Focus Node für Auto-Scroll
    _inputFocusNode.addListener(_onFocusChange);

    _initializeApiKey();
  }

  /// 🎯 Focus Change Handler für Auto-Scroll
  void _onFocusChange() {
    if (_inputFocusNode.hasFocus) {
      _scrollToBottom();
    }
  }

  /// 📜 Auto-Scroll
  void _scrollToBottom() {
    if (mounted) {
      Future.delayed(Duration(milliseconds: 50), () {
        if (mounted) setState(() {});
      });
    }
  }

  /// 🔑 API Key Initialisierung
  Future<void> _initializeApiKey() async {
    try {
      print('🔑 Starte API Key Initialisierung...');

      await ApiKeyManager.initialize();

      if (mounted) {
        setState(() {
          OPENAI_API_KEY = ApiKeyManager.apiKey ?? "";
          _apiKeyLoaded = true;
        });

        if (ApiKeyManager.isValidApiKey()) {
          print('✅ API Key erfolgreich validiert');
          await _initializeChat();
        } else {
          print('⚠️ API Key ist ungültig oder fehlt');
          _setError('OpenAI API Key fehlt oder ist ungültig');
        }
      }
    } catch (e) {
      print("❌ API Key Initialisierung fehlgeschlagen: $e");
      if (mounted) {
        setState(() {
          OPENAI_API_KEY = "";
          _apiKeyLoaded = true;
        });
        _setError('API Key konnte nicht geladen werden: $e');
      }
    }
  }

  /// 🧠 Chat Initialisierung mit Willkommensnachricht
  Future<void> _initializeChat() async {
    try {
      if (OPENAI_API_KEY.isEmpty || OPENAI_API_KEY == "YOUR_API_KEY_HERE") {
        throw Exception('Invalid API Key');
      }

      // OpenAI Client initialisieren
      _openAI = OpenAI.instance.build(
        token: OPENAI_API_KEY,
        baseOption: HttpSetup(
          receiveTimeout: ChatbotConfig.apiTimeout,
          sendTimeout: ChatbotConfig.apiTimeout,
          connectTimeout: ChatbotConfig.apiTimeout,
        ),
        enableLog: false,
      );

      print('✅ Chat erfolgreich initialisiert');

      // Willkommensnachricht hinzufügen
      _sessionManager.addWelcomeMessage();

      // Animation starten
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fadeController.forward();
        setState(() {});
      });
    } catch (e) {
      print('❌ Chat Initialization Error: $e');
      if (mounted) {
        _sessionManager.addAssistantMessage(
            "🚫 Entschuldigung, es gab ein Problem beim Starten des Chats. Bitte prüfe deine Internetverbindung und API-Konfiguration.");
        setState(() {});
      }
    }
  }

  void _setError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
    });
  }

  /// 🔧 API Key Setup Dialog
  void _showApiKeySetupDialog() {
    final debugInfo = ApiKeyManager.getDebugInfo();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Text('API Key Setup'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Es gibt ein Problem mit dem OpenAI API Key:\n'),
            Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Initialisiert: ${debugInfo['isInitialized']}'),
            Text('• Key vorhanden: ${debugInfo['hasApiKey']}'),
            Text('• Gültiges Format: ${debugInfo['isValidFormat']}'),
            Text('• Key Länge: ${debugInfo['keyLength']}'),
            const SizedBox(height: 16),
            Text('Lösung:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('1. Erstelle eine .env Datei im Root-Verzeichnis'),
            Text('2. Füge hinzu: OPENAI_API_KEY=sk-proj-...'),
            Text('3. Starte die App neu'),
            const SizedBox(height: 8),
            Text('Den API Key erhältst du auf: platform.openai.com',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: _primaryColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeApiKey();
            },
            child: Text('Erneut versuchen',
                style: TextStyle(color: _primaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue.getInstance(key),
        appBar: AppBar(
          foregroundColor: Colors.white,
          title: const Text('KI-Assistent'),
          backgroundColor: _primaryColor,
          elevation: 0, // Flaches Design
          actions: [
            IconButton(
              icon: Icon(
                _hasError ? Icons.error_outline : Icons.info_outline,
                color: _hasError ? Colors.red[200] : Colors.white,
              ),
              onPressed: () {
                if (_hasError || !ApiKeyManager.isValidApiKey()) {
                  _showApiKeySetupDialog();
                } else {
                  final sessionInfo = _sessionManager.getDebugInfo();
                  final sessionStats = _sessionManager.getSessionStats();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('✅ KI-Assistent ist bereit!'),
                          Text('💬 Messages: ${sessionStats['totalMessages']}'),
                          Text('🧠 Memory: ${sessionInfo['memoryUsage']}'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        backgroundColor: _backgroundColor, // Sanfte Hintergrundfarbe
        body: _buildChatContent(),
      ),
    );
  }

  /// 📱 Chat Content Builder
  Widget _buildChatContent() {
    if (!_apiKeyLoaded) {
      return _buildLoadingState();
    }

    if (_hasError || !ApiKeyManager.isValidApiKey()) {
      return _buildErrorState();
    }

    return _buildChatInterface();
  }

  /// ⏳ Eleganter Loading State
  Widget _buildLoadingState() {
    return Container(
      color: _backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: _primaryColor,
              strokeWidth: 2,
            ),
            const SizedBox(height: 24),
            Text(
              'KI-Assistent wird geladen...',
              style: TextStyle(
                fontSize: 16,
                color: _primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ❌ Clean Error State
  Widget _buildErrorState() {
    return Container(
      color: _backgroundColor,
      padding: EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 400),
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: Colors.orange.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'KI-Assistent Setup erforderlich',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage.isNotEmpty
                    ? _errorMessage
                    : 'OpenAI API Key ist nicht konfiguriert',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _showApiKeySetupDialog,
                icon: Icon(Icons.settings, color: Colors.white, size: 20),
                label: Text('Setup starten',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 💬 Fullscreen Chat Interface (clean & minimalistisch)
  Widget _buildChatInterface() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            color: _chatBackgroundColor, // Reiner weißer Hintergrund
            child: DashChat(
              key: _dashChatKey,
              currentUser: _sessionManager.currentUser,
              onSend: _handleSendMessage,
              messages: _sessionManager.messages,

              // Clean Input Design
              inputOptions: InputOptions(
                focusNode: _inputFocusNode,
                inputDecoration: InputDecoration(
                  hintText: "Frage mich...",
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: _primaryColor, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                sendButtonBuilder: (void Function() onSend) {
                  return Container(
                    margin: EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                      onPressed: onSend,
                      padding: EdgeInsets.all(10),
                    ),
                  );
                },
              ),

              // Clean Message Design
              messageOptions: MessageOptions(
                currentUserContainerColor: _primaryColor,
                containerColor: Colors.grey[100]!,
                textColor: Colors.black87,
                currentUserTextColor: Colors.white,
                showTime: true,
                showOtherUsersAvatar: true,
                showCurrentUserAvatar: true,
                showOtherUsersName: false, // Cleaner ohne Namen
                messagePadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                avatarBuilder: (user, onAvatarTap, onAvatarLongPress) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:
                          user.id == "user" ? _primaryColor : Colors.grey[300],
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      user.id == "user"
                          ? Icons.person_rounded
                          : Icons.favorite_rounded,
                      color:
                          user.id == "user" ? Colors.white : Colors.grey[600],
                      size: 18,
                    ),
                  );
                },
              ),

              // Typing Indicator
              typingUsers: _isTyping ? [_sessionManager.assistantUser] : [],
            ),
          ),
        );
      },
    );
  }

  /// 📤 Message Handler mit Input-Validierung
  Future<void> _handleSendMessage(ChatMessage chatMessage) async {
    // 🛡️ KRITISCH: Input-Validierung vor API-Call (Kostenschutz!)
    final validationResult = _validateUserInput(chatMessage.text);
    if (!validationResult['isValid']) {
      _showInputValidationMessage(validationResult['message']);
      return; // ⚠️ STOPP - Keine API-Kosten für invalide Inputs!
    }

    print(
        '✅ Input validiert: "${chatMessage.text.substring(0, math.min(50, chatMessage.text.length))}..."');

    HapticFeedback.lightImpact();

    _sessionManager.addUserMessage(chatMessage);

    setState(() {
      _isTyping = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    if (!_rateLimiter.canMakeRequest(_sessionManager.userId)) {
      _showRateLimitMessage();
      return;
    }

    try {
      final request = ChatCompleteText(
        model: Gpt4oMiniChatModel(),
        messages: _sessionManager.conversationHistory
            .map((msg) => msg.toJson())
            .toList(),
        stream: true,
        maxToken: ChatbotConfig.maxTokens,
        temperature: ChatbotConfig.temperature,
      );

      String fullResponse = '';
      ChatMessage? streamMessage;

      final stream = _openAI.onChatCompletionSSE(request: request);

      stream.listen(
        (response) {
          if (response.choices != null && response.choices!.isNotEmpty) {
            final choice = response.choices!.first;
            String? content = choice.message?.content;

            if (content != null && content.isNotEmpty) {
              fullResponse += content;

              if (streamMessage == null) {
                streamMessage =
                    _sessionManager.createStreamingMessage(fullResponse);
                if (mounted) {
                  setState(() {
                    _isTyping = false;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                }
              } else {
                if (mounted) {
                  setState(() {
                    _sessionManager.updateLastAssistantMessage(fullResponse);
                  });
                }
              }
            }
          }
        },
        onError: (error) => throw error,
        onDone: () {
          if (fullResponse.isNotEmpty) {
            _sessionManager.finalizeStreamingMessage(fullResponse);
          }
          if (mounted) {
            setState(() {
              _isTyping = false;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
        },
      );
    } catch (e) {
      String errorMessage = _getErrorMessage(e.toString());
      _addAssistantMessage(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
    }
  }

  String _getErrorMessage(String errorString) {
    if (errorString.contains('timeout')) {
      return "⏱️ Die Antwort dauert etwas länger. Bitte versuche es erneut!";
    } else if (errorString.contains('API key') || errorString.contains('401')) {
      return "🔑 API-Schlüssel Problem. Bitte kontaktiere den Support.";
    } else if (errorString.contains('quota') || errorString.contains('429')) {
      return "💳 API-Kontingent erschöpft. Bitte kontaktiere den Support.";
    } else {
      return "💭 Momentan habe ich technische Schwierigkeiten. Versuche es gleich nochmal!";
    }
  }

  /// 🛡️ KOSTENSCHUTZ: Validiert User-Input vor API-Calls
  Map<String, dynamic> _validateUserInput(String text) {
    // 1. ❌ Leere oder Whitespace-only Messages
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return {'isValid': false, 'message': ChatbotConfig.emptyInputError};
    }

    // 2. ❌ Zu kurze Messages
    if (trimmedText.length < ChatbotConfig.minInputLength) {
      return {'isValid': false, 'message': ChatbotConfig.tooShortInputError};
    }

    // 3. ❌ Nur Sonderzeichen oder Zahlen
    final hasLetters = RegExp(r'[a-zA-ZäöüÄÖÜß]').hasMatch(trimmedText);
    if (!hasLetters) {
      return {'isValid': false, 'message': ChatbotConfig.noLettersError};
    }

    // 4. ❌ Zu lange Messages (Token-Limit)
    if (trimmedText.length > ChatbotConfig.maxInputLength) {
      return {'isValid': false, 'message': ChatbotConfig.tooLongInputError};
    }

    // 5. ❌ Spam-Detection: Wiederholte identische Zeichen
    if (!ChatbotConfig.hasEnoughUniqueChars(trimmedText)) {
      return {'isValid': false, 'message': ChatbotConfig.spamDetectedError};
    }

    // 6. ❌ Repetitive Messages Detection
    if (_isRepetitiveMessage(trimmedText)) {
      return {
        'isValid': false,
        'message': ChatbotConfig.repetitiveMessageError
      };
    }

    // ✅ Alle Validierungen bestanden
    return {'isValid': true, 'message': 'valid'};
  }

  /// 🔍 Prüft auf repetitive Messages (konfigurierbare Anzahl)
  bool _isRepetitiveMessage(String newMessage) {
    final recentMessages = _sessionManager.messages
        .where((msg) => msg.user.id == "user")
        .take(ChatbotConfig.repetitiveMessageCheckCount)
        .map((msg) => msg.text.trim().toLowerCase())
        .toList();

    final newMessageLower = newMessage.trim().toLowerCase();

    return recentMessages.contains(newMessageLower);
  }

  /// 📢 Zeigt Input-Validierung Nachricht
  void _showInputValidationMessage(String message) {
    if (mounted) {
      // Kurzes Feedback für User
      HapticFeedback.selectionClick();

      // Zeige Validierungsfehler als Assistent-Message
      _sessionManager.addAssistantMessage(message);
      setState(() {});

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      print('🛡️ Input-Validierung: $message');
    }
  }

  void _showRateLimitMessage() {
    if (mounted) {
      setState(() {
        _isTyping = false;
      });
      _sessionManager.addAssistantMessage(
          _rateLimiter.getRateLimitMessage(_sessionManager.userId));
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _addAssistantMessage(String text) {
    if (mounted) {
      _sessionManager.addAssistantMessage(text);
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _inputFocusNode.dispose();

    if (DateTime.now().minute % 10 == 0) {
      _rateLimiter.cleanup();
    }

    super.dispose();
  }
}
