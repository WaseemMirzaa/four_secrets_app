import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeyManager {
  static String? _apiKey;
  static bool _isInitialized = false;

  /// Gibt den aktuellen API Key zurück
  static String? get apiKey => _apiKey;

  /// Prüft ob der Manager initialisiert wurde
  static bool get isInitialized => _isInitialized;

  /// Initialisiert den API Key Manager
  /// Lädt den API Key aus der .env Datei
  static Future<void> initialize() async {
    try {
      print('🔑 Initialisiere API Key Manager...');

      // Lade .env Datei
      await dotenv.load(fileName: ".env");

      // Lade OpenAI API Key
      _apiKey = dotenv.env['OPENAI_API_KEY'];

      if (_apiKey == null || _apiKey!.isEmpty) {
        print('⚠️ OPENAI_API_KEY nicht in .env gefunden');
        _apiKey = null;
      } else {
        // Validiere API Key Format (sollte mit sk- beginnen)
        if (!_apiKey!.startsWith('sk-')) {
          print('⚠️ API Key hat falsches Format (sollte mit sk- beginnen)');
          _apiKey = null;
        } else {
          print(
              '✅ API Key erfolgreich geladen (${_apiKey!.substring(0, 10)}...)');
        }
      }

      _isInitialized = true;
    } catch (e) {
      print('❌ Fehler beim Laden der .env Datei: $e');
      print(
          '💡 Stelle sicher dass eine .env Datei im Root-Verzeichnis existiert');
      print('💡 Die Datei sollte enthalten: OPENAI_API_KEY=sk-proj-...');

      _apiKey = null;
      _isInitialized = true; // Trotzdem als initialisiert markieren
    }
  }

  /// Setzt den API Key manuell (für Tests oder Fallback)
  static void setApiKey(String apiKey) {
    if (apiKey.isNotEmpty && apiKey.startsWith('sk-')) {
      _apiKey = apiKey;
      print('✅ API Key manuell gesetzt');
    } else {
      print('⚠️ Ungültiger API Key beim manuellen Setzen');
    }
  }

  /// Validiert den aktuellen API Key
  static bool isValidApiKey() {
    return _apiKey != null &&
        _apiKey!.isNotEmpty &&
        _apiKey!.startsWith('sk-') &&
        _apiKey!.length > 20; // Mindestlänge für OpenAI Keys
  }

  /// Gibt Debug-Informationen zurück
  static Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'hasApiKey': _apiKey != null,
      'isValidFormat': _apiKey?.startsWith('sk-') ?? false,
      'keyLength': _apiKey?.length ?? 0,
      'keyPreview':
          _apiKey != null ? '${_apiKey!.substring(0, 10)}...' : 'null',
    };
  }

  /// Reset für Tests
  static void reset() {
    _apiKey = null;
    _isInitialized = false;
  }
}
