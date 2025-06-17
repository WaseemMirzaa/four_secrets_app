import 'package:flutter/material.dart';

class TodoItem {
  String task;
  bool isCompleted;
  int category; // 0=0-1 Monat, 1=2-3 Monate, 2=4-6 Monate, 3=7-9 Monate, 4=10-12 Monate, 5=12+ Monate

  TodoItem({
    required this.task,
    this.isCompleted = false,
    required this.category,
  });

  // Konvertierung zu Map für Hive
  Map<String, dynamic> toMap() {
    return {
      'task': task,
      'isCompleted': isCompleted,
      'category': category,
    };
  }

  // Konvertierung von Map für Hive
  static TodoItem fromMap(Map<String, dynamic> map) {
    return TodoItem(
      task: map['task'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      category: map['category'] ?? 0,
    );
  }
}

class TodoCategory {
  final int id;
  final String name;
  final String description;

  TodoCategory({
    required this.id,
    required this.name,
    required this.description,
  });

  static final List<TodoCategory> categories = [
    TodoCategory(
        id: 0, name: "0-1 Monat", description: "0-1 Monat vor der Hochzeit"),
    TodoCategory(
        id: 1, name: "2-3 Monate", description: "2-3 Monate vor der Hochzeit"),
    TodoCategory(
        id: 2, name: "4-6 Monate", description: "4-6 Monate vor der Hochzeit"),
    TodoCategory(
        id: 3, name: "7-9 Monate", description: "7-9 Monate vor der Hochzeit"),
    TodoCategory(
        id: 4,
        name: "10-12 Monate",
        description: "10-12 Monate vor der Hochzeit"),
    TodoCategory(
        id: 5,
        name: "12+ Monate",
        description: "Mehr als 12 Monate vor der Hochzeit"),
  ];

  static String getCategoryName(int categoryId) {
    if (categoryId >= 0 && categoryId < categories.length) {
      return categories[categoryId].name;
    }
    return "Unbekannt";
  }
}

enum CategoryStatus {
  noDate, // Kein Hochzeitsdatum gesetzt
  active, // Aktueller Zeitraum
  overdue, // Überfälliger Zeitraum
  future, // Zukünftiger Zeitraum
}

class WeddingDateHelper {
  // App-weite Design-Konstanten
  static const Color _primaryColor = Color.fromARGB(255, 107, 69, 106);
  static const Color _containerLightColor = Color.fromARGB(255, 250, 250, 250);
  static const Color _containerDarkColor = Color.fromARGB(255, 240, 240, 240);
  // static const Color _headerLightColor = Color.fromARGB(255, 235, 235, 235);
  static const Color _headerDarkColor = Color.fromARGB(255, 220, 220, 220);
  // static const Color _textSecondaryColor = Color.fromARGB(255, 117, 117, 117);

  // Standard Elevation-Werte
  static const double _standardElevation = 2.5;
  static const double _highlightedElevation = 4.0;

  /// Berechnet die aktuelle Kategorie basierend auf dem Hochzeitsdatum
  static int getCurrentCategory(DateTime weddingDate) {
    final now = DateTime.now();
    final difference = weddingDate.difference(now).inDays;

    // Wenn das Hochzeitsdatum in der Vergangenheit liegt
    if (difference < 0) return -1;

    final months = difference / 30.44; // Durchschnittliche Tage pro Monat

    if (months <= 1) return 0; // 0-1 Monat
    if (months <= 3) return 1; // 2-3 Monate
    if (months <= 6) return 2; // 4-6 Monate
    if (months <= 9) return 3; // 7-9 Monate
    if (months <= 12) return 4; // 10-12 Monate
    return 5; // 12+ Monate
  }

  /// Bestimmt den Status einer Kategorie - KORRIGIERTE LOGIK
  static CategoryStatus getCategoryStatus(
      int categoryId, DateTime? weddingDate) {
    if (weddingDate == null) return CategoryStatus.noDate;

    final currentCategory = getCurrentCategory(weddingDate);

    // Wenn Hochzeit in der Vergangenheit liegt
    if (currentCategory == -1) return CategoryStatus.overdue;

    if (categoryId == currentCategory) return CategoryStatus.active;

    // KORRIGIERT: Höhere Kategorie-ID = sollte früher erledigt werden
    // Wenn categoryId > currentCategory, dann sollte diese Kategorie bereits erledigt sein (overdue)
    // Wenn categoryId < currentCategory, dann ist es noch zu früh (future)
    if (categoryId > currentCategory) return CategoryStatus.overdue;
    return CategoryStatus.future;
  }

  // Legacy-Methoden für Kompatibilität (können später entfernt werden)
  static bool isCategoryActive(int categoryId, DateTime? weddingDate) {
    return getCategoryStatus(categoryId, weddingDate) == CategoryStatus.active;
  }

  static bool isCategoryOverdue(int categoryId, DateTime? weddingDate) {
    return getCategoryStatus(categoryId, weddingDate) == CategoryStatus.overdue;
  }

  static bool isCategoryFuture(int categoryId, DateTime? weddingDate) {
    return getCategoryStatus(categoryId, weddingDate) == CategoryStatus.future;
  }

  /// Gibt die Containerfarben für eine Kategorie zurück (vereinheitlicht)
  static List<Color> getCategoryContainerColors(
      int categoryId, DateTime? weddingDate) {
    return [_containerLightColor, _containerDarkColor];
  }

  /// Gibt die Header-Farben für eine Kategorie zurück - ALLE KATEGORIEN GLEICH
  static List<Color> getCategoryHeaderColors(
      int categoryId, DateTime? weddingDate) {
    // Einheitliche Farben für alle Kategorien
    return [_headerDarkColor, Colors.grey.shade300];
  }

  /// Gibt den Status-Text für eine Kategorie zurück
  static String getCategoryStatusText(int categoryId, DateTime? weddingDate) {
    final status = getCategoryStatus(categoryId, weddingDate);

    switch (status) {
      case CategoryStatus.noDate:
        return 'Hochzeitsdatum festlegen';
      case CategoryStatus.active:
        return 'Aktueller Zeitraum';
      case CategoryStatus.overdue:
        return 'Sollte bereits erledigt sein';
      case CategoryStatus.future:
        return 'Zukünftig';
    }
  }

  /// Gibt die Icon-Farbe für eine Kategorie zurück
  static Color getCategoryIconColor(int categoryId, DateTime? weddingDate) {
    if (weddingDate == null) return Colors.grey.shade600;

    final status = getCategoryStatus(categoryId, weddingDate);

    switch (status) {
      case CategoryStatus.active:
        return Colors.green.shade700;
      case CategoryStatus.overdue:
        return Colors.orange.shade700;
      case CategoryStatus.future:
        return Colors.grey.shade600;
      case CategoryStatus.noDate:
        return _primaryColor; // Primärfarbe
    }
  }

  /// Gibt das Icon für eine Kategorie zurück
  static IconData getCategoryIcon(int categoryId, DateTime? weddingDate) {
    final status = getCategoryStatus(categoryId, weddingDate);

    switch (status) {
      case CategoryStatus.active:
        return Icons.access_time_filled; // Gefülltes Icon für aktive Kategorie
      case CategoryStatus.overdue:
        return Icons.warning_rounded; // Warnung für überfällig
      case CategoryStatus.future:
        return Icons.schedule_outlined; // Outline für zukünftig
      case CategoryStatus.noDate:
        return Icons.schedule_outlined;
    }
  }

  /// Gibt die Elevation für eine Kategorie zurück
  static double getCategoryElevation(int categoryId, DateTime? weddingDate) {
    final status = getCategoryStatus(categoryId, weddingDate);

    switch (status) {
      case CategoryStatus.active:
        return _highlightedElevation;
      case CategoryStatus.overdue:
        return _highlightedElevation; // Auch überfällige hervorheben
      default:
        return _standardElevation;
    }
  }

  /// Hilfsmethode für Debug-Informationen (optional)
  static String getDebugInfo(DateTime? weddingDate) {
    if (weddingDate == null) return 'Kein Hochzeitsdatum gesetzt';

    final now = DateTime.now();
    final difference = weddingDate.difference(now).inDays;
    final months = difference / 30.44;
    final currentCategory = getCurrentCategory(weddingDate);

    return 'Tage bis Hochzeit: $difference, Monate: ${months.toStringAsFixed(1)}, Aktuelle Kategorie: $currentCategory';
  }

  /// Gibt Statistiken für die Datenbank-Klasse zurück
  static Map<String, int> calculateStatistics(List<TodoItem> todos) {
    final total = todos.length;
    final completed = todos.where((todo) => todo.isCompleted).length;
    final pending = total - completed;

    return {
      'total': total,
      'completed': completed,
      'pending': pending,
    };
  }

  /// Hilfsmethode um zu prüfen, ob ein Hochzeitsdatum gültig ist
  static bool isValidWeddingDate(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date
        .isAfter(now.subtract(const Duration(days: 1))); // Erlaubt auch heute
  }

  /// Berechnet die Anzahl der Tage bis zur Hochzeit
  static int getDaysUntilWedding(DateTime weddingDate) {
    final now = DateTime.now();
    return weddingDate.difference(now).inDays;
  }

  /// Formatiert die Zeit bis zur Hochzeit als lesbaren String
  static String formatTimeUntilWedding(DateTime weddingDate) {
    final days = getDaysUntilWedding(weddingDate);

    if (days < 0) {
      return 'Hochzeit war vor ${days.abs()} ${days.abs() == 1 ? 'Tag' : 'Tagen'}';
    } else if (days == 0) {
      return 'Heute ist der große Tag! 🎉';
    } else if (days < 30) {
      return '$days ${days == 1 ? 'Tag' : 'Tage'} bis zur Hochzeit';
    } else {
      final months = (days / 30.44).round();
      if (months == 1) {
        return 'Noch 1 Monat bis zur Hochzeit';
      } else {
        return 'Noch $months Monate bis zur Hochzeit';
      }
    }
  }
}
