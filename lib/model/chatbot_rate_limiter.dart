import 'package:four_secrets_wedding_app/model/chatbot_config.dart';

class ImprovedRateLimiter {
  static final ImprovedRateLimiter _instance = ImprovedRateLimiter._internal();
  factory ImprovedRateLimiter() => _instance;
  ImprovedRateLimiter._internal();

  final Map<String, List<DateTime>> _userRequests = {};
  DateTime? _lastCleanup;

  /// Prüft ob ein User eine neue Anfrage stellen kann
  bool canMakeRequest(String userId) {
    final now = DateTime.now();

    // 🔧 PERFORMANCE: Cleanup nur alle 5 Minuten automatisch
    _performAutomaticCleanup(now);

    final userHistory = _userRequests[userId] ?? [];

    // Bereinige alte Einträge für diesen User (älter als 1 Stunde)
    userHistory.removeWhere((time) => now.difference(time).inHours >= 1);

    // Prüfe Minuten-Limit (letzte 1 Minute)
    final recentRequests =
        userHistory.where((time) => now.difference(time).inMinutes < 1).length;

    if (recentRequests >= ChatbotConfig.maxRequestsPerMinute) {
      print(
          '⚠️ Rate limit erreicht: $recentRequests Anfragen in der letzten Minute');
      return false;
    }

    // Prüfe Stunden-Limit
    if (userHistory.length >= ChatbotConfig.maxRequestsPerHour) {
      print('⚠️ Stunden-Limit erreicht: ${userHistory.length} Anfragen');
      return false;
    }

    // Füge neue Anfrage hinzu
    userHistory.add(now);
    _userRequests[userId] = userHistory;

    print(
        '✅ Anfrage erlaubt: ${userHistory.length}/${ChatbotConfig.maxRequestsPerHour} (Stunde), $recentRequests/${ChatbotConfig.maxRequestsPerMinute} (Minute)');
    return true;
  }

  /// Gibt die passende Rate-Limit Nachricht zurück
  String getRateLimitMessage(String userId) {
    final now = DateTime.now();
    final userHistory = _userRequests[userId] ?? [];

    final recentRequests =
        userHistory.where((time) => now.difference(time).inMinutes < 1).length;

    if (recentRequests >= ChatbotConfig.maxRequestsPerMinute) {
      final nextAllowedTime = userHistory
          .where((time) => now.difference(time).inMinutes < 1)
          .reduce((a, b) => a.isAfter(b) ? a : b)
          .add(Duration(minutes: 1));

      final waitTime = nextAllowedTime.difference(now).inSeconds;

      return "⏰ Zu viele Fragen! Bitte warte $waitTime Sekunden, damit ich dir optimal helfen kann. 💭";
    }

    final nextResetTime = userHistory.isNotEmpty
        ? userHistory.first.add(Duration(hours: 1))
        : now.add(Duration(hours: 1));

    final timeUntilReset = nextResetTime.difference(now);
    final hoursLeft = timeUntilReset.inHours;
    final minutesLeft = timeUntilReset.inMinutes % 60;

    return "📝 Du hast dein Stunden-Limit erreicht. Komm in ${hoursLeft}h ${minutesLeft}m wieder! 🌟";
  }

  /// Gibt Debug-Informationen für einen User zurück
  Map<String, dynamic> getUserStats(String userId) {
    final now = DateTime.now();
    final userHistory = _userRequests[userId] ?? [];

    final recentRequests =
        userHistory.where((time) => now.difference(time).inMinutes < 1).length;

    return {
      'userId': userId,
      'totalRequests': userHistory.length,
      'recentRequests': recentRequests,
      'remainingThisMinute':
          ChatbotConfig.maxRequestsPerMinute - recentRequests,
      'remainingThisHour':
          ChatbotConfig.maxRequestsPerHour - userHistory.length,
      'canMakeRequest': canMakeRequest(userId),
      'oldestRequest': userHistory.isNotEmpty ? userHistory.first : null,
      'newestRequest': userHistory.isNotEmpty ? userHistory.last : null,
    };
  }

  /// Gibt Gesamtstatistiken zurück
  Map<String, dynamic> getGlobalStats() {
    final now = DateTime.now();
    int totalUsers = _userRequests.length;
    int totalRequests = 0;
    int activeUsers = 0;

    for (var userHistory in _userRequests.values) {
      totalRequests += userHistory.length;
      if (userHistory.any((time) => now.difference(time).inMinutes < 60)) {
        activeUsers++;
      }
    }

    return {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'totalRequests': totalRequests,
      'averageRequestsPerUser': totalUsers > 0 ? totalRequests / totalUsers : 0,
      'lastCleanup': _lastCleanup,
    };
  }

  /// 🔧 PERFORMANCE: Automatisches Cleanup nur alle 5 Minuten
  void _performAutomaticCleanup(DateTime now) {
    if (_lastCleanup == null || now.difference(_lastCleanup!).inMinutes >= 5) {
      cleanup();
      _lastCleanup = now;
    }
  }

  /// Manuelle Bereinigung - Entfernt alte Daten
  void cleanup() {
    final now = DateTime.now();
    int removedUsers = 0;
    int removedRequests = 0;

    _userRequests.removeWhere((userId, requests) {
      final initialCount = requests.length;

      // Entferne Requests älter als 2 Stunden
      requests.removeWhere((time) => now.difference(time).inHours >= 2);

      removedRequests += (initialCount - requests.length);

      // Entferne User ohne aktuelle Requests
      if (requests.isEmpty) {
        removedUsers++;
        return true;
      }
      return false;
    });

    if (removedUsers > 0 || removedRequests > 0) {
      print(
          '🧹 Cleanup: $removedUsers Users und $removedRequests Requests entfernt');
      print('📊 Verbleibend: ${_userRequests.length} aktive Users');
    }
  }

  /// Reset für Tests und Debugging
  void reset() {
    _userRequests.clear();
    _lastCleanup = null;
    print('🔄 Rate Limiter zurückgesetzt');
  }

  /// Entfernt einen spezifischen User (für Tests oder Admin-Funktionen)
  void removeUser(String userId) {
    final removed = _userRequests.remove(userId);
    if (removed != null) {
      print('🗑️ User $userId aus Rate Limiter entfernt');
    }
  }
}
