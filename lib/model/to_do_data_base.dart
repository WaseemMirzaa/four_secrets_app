import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'todo_item.dart';

// Firestore-basiertes Checklist Model (für Cloud-Sync)
class ChecklistItemModel {
  final String id;
  final String taskName;
  bool isCompleted;
  final DateTime createdAt;
  final String userId;

  ChecklistItemModel({
    required this.id,
    required this.taskName,
    required this.isCompleted,
    required this.createdAt,
    required this.userId,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'taskName': taskName,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
    };
  }

  // Create from Firestore document
  factory ChecklistItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChecklistItemModel(
      id: doc.id,
      taskName: data['taskName'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
    );
  }

  // Create a copy with some fields changed
  ChecklistItemModel copyWith({
    String? id,
    String? taskName,
    bool? isCompleted,
    DateTime? createdAt,
    String? userId,
  }) {
    return ChecklistItemModel(
      id: id ?? this.id,
      taskName: taskName ?? this.taskName,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'ChecklistItemModel(id: $id, taskName: $taskName, isCompleted: $isCompleted, createdAt: $createdAt, userId: $userId)';
  }
}

// Hive-basierte lokale ToDo Database (für Offline-Funktionalität)
class ToDoDataBase {
  List<TodoItem> toDoList = [];
  DateTime? weddingDate;

  // Hive box reference
  final Box _myBoxToDo = Hive.box('myboxToDo');

  // run this method if this is the 1st time ever opening this app
  void createInitialDataToDo() {
    toDoList = [
      // 0-1 Monat vor Hochzeit
      TodoItem(task: "Rückmeldungen Gäste final prüfen", category: 0),
      TodoItem(task: "Ablaufplan finalisieren", category: 0),
      TodoItem(task: "Notfallset für Braut & Bräutigam vorbereiten", category: 0),
      TodoItem(task: "Schuhe einlaufen", category: 0),
      TodoItem(task: "Letzte Anprobe von Kleid & Anzug", category: 0),
      TodoItem(task: "Generalprobe (Trauung & Location)", category: 0),
      TodoItem(task: "Traurede schreiben", category: 0),
      TodoItem(task: "Playlist für DJ/Band zusammenstellen", category: 0),
      TodoItem(task: "Beauty-Termine wahrnehmen", category: 0),
      TodoItem(task: "Kleidung & Accessoires bereitlegen", category: 0),
      TodoItem(task: "Sitzplan & Namenskarten ausdrucken", category: 0),
      TodoItem(task: "Ringe bereitlegen", category: 0),
      TodoItem(task: "Ausweise und Dokumente prüfen", category: 0),
      TodoItem(task: "Handy aufladen", category: 0),
      TodoItem(task: "früh schlafen gehen", category: 0),

      // 2-3 Monate vor Hochzeit
      TodoItem(task: "Einladungen versenden", category: 1),
      TodoItem(task: "Sitzordnung planen", category: 1),
      TodoItem(task: "Gastgeschenke aussuchen", category: 1),
      TodoItem(task: "Event-Programm planen", category: 1),
      TodoItem(task: "Packliste erstellen", category: 1),
      TodoItem(task: "Junggesellenabschied planen", category: 1),

      // 4-6 Monate vor Hochzeit
      TodoItem(task: "Friseur- & Beautytermine vereinbaren", category: 2),
      TodoItem(task: "Floristen buchen", category: 2),
      TodoItem(task: "Trauredner buchen", category: 2),
      TodoItem(task: "Deko-Ideen konkretisieren", category: 2),
      TodoItem(task: "Einladungen gestalten", category: 2),
      TodoItem(task: "Trauzeugen Outfits festlegen", category: 2),
      TodoItem(task: "Personal-Training organisieren", category: 2),
      TodoItem(task: "Menü & Getränkeauswahl festlegen", category: 2),
      TodoItem(task: "Tagesablauf planen", category: 2),
      TodoItem(task: "Ablauf mit Dienstleister abstimmen", category: 2),
      TodoItem(task: "Tanzkurs beginnen", category: 2),

      // 7-9 Monate vor Hochzeit
      TodoItem(task: "Brautkleid aussuchen", category: 3),
      TodoItem(task: "Brautkleid Anprobe vereinbaren", category: 3),
      TodoItem(task: "Brätigam Anzug aussuchen", category: 3),
      TodoItem(task: "Brätigam Anprobe vereinbaren", category: 3),
      TodoItem(task: "Save-the-Date Karten versenden", category: 3),
      TodoItem(task: "Gästeliste finalisieren", category: 3),
      TodoItem(task: "Unterkunft für Gäste organisieren", category: 3),
      TodoItem(task: "Hochzeits-Fahrzeug organisieren", category: 3),
      TodoItem(task: "Gästetransport organisieren", category: 3),
      TodoItem(task: "Kinderbetreuung planen", category: 3),
      TodoItem(task: "Eheringe aussuchen", category: 3),
      TodoItem(task: "Flitterwochen planen", category: 3),
      TodoItem(task: "Torte bestellen", category: 3),

      // 10-12 Monate vor Hochzeit
      TodoItem(task: "Location aussuchen", category: 4),
      TodoItem(task: "Stil der Hochzeit überlegen", category: 4),
      TodoItem(task: "Gästeliste grob planen", category: 4),
      TodoItem(task: "Trauzeugen bestimmen", category: 4),
      TodoItem(task: "Hochzeitsversicherung prüfen", category: 4),
      TodoItem(task: "Standesamt & Kirche/Freie Trauung anfragen", category: 4),
      TodoItem(task: "Catering buchen", category: 4),
      TodoItem(task: "Band buchen", category: 4),
      TodoItem(task: "Fotograf/Videograf buchen", category: 4),

      // 12+ Monate vor Hochzeit
      TodoItem(task: "Budget festlegen", category: 5),
      TodoItem(task: "Hochzeitsdatum festlegen", category: 5),
    ];

    updateDataBaseToDo();
  }

  // load the data from database ToDo
  void loadDataToDo() {
    try {
      // Lade die ToDo Liste
      final todoData = _myBoxToDo.get("TODOLIST");

      if (todoData != null && todoData is List) {
        toDoList.clear();

        for (final item in todoData) {
          try {
            if (item is Map<String, dynamic>) {
              toDoList.add(TodoItem.fromMap(item));
            } else if (item is Map) {
              // Fallback für Map<dynamic, dynamic>
              toDoList.add(TodoItem.fromMap(Map<String, dynamic>.from(item)));
            } else if (item is List && item.length >= 2) {
              // Fallback für alte Datenstruktur
              toDoList.add(TodoItem(
                task: item[0].toString(),
                isCompleted: item[1] as bool? ?? false,
                category: item.length > 2 ? (item[2] as int? ?? 2) : 2,
              ));
            }
            // Unbekannte Formate werden einfach übersprungen
          } catch (e) {
            // Einzelne fehlerhafte Items werden übersprungen
            continue;
          }
        }
      }

      // Lade das Hochzeitsdatum
      final weddingDateString = _myBoxToDo.get("WEDDING_DATE");
      if (weddingDateString != null) {
        try {
          weddingDate = DateTime.parse(weddingDateString);
        } catch (e) {
          weddingDate = null;
        }
      }
    } catch (e) {
      // Bei kritischen Fehlern: Liste leeren
      toDoList.clear();
    }
  }

  // update the database ToDo
  void updateDataBaseToDo() {
    try {
      final todoListMaps = toDoList.map((item) => item.toMap()).toList();
      _myBoxToDo.put("TODOLIST", todoListMaps);
    } catch (e) {
      // Fehler beim Speichern - könnte in Zukunft geloggt werden
    }
  }

  // Speichere das Hochzeitsdatum
  void updateWeddingDate(DateTime? date) {
    weddingDate = date;
    if (date != null) {
      _myBoxToDo.put("WEDDING_DATE", date.toIso8601String());
    } else {
      _myBoxToDo.delete("WEDDING_DATE");
    }
  }

  // Notfall-Reparatur: Setze Daten zurück, falls sie korrupt sind
  void repairCorruptedData() {
    // Prüfe auf Anzeichen von korrupten Daten
    bool hasCorruptedData = toDoList.any((todo) =>
        todo.task.trim().toLowerCase() == "unbekannt" ||
        todo.task.trim().toLowerCase() == "unknown" ||
        todo.task.trim().isEmpty);

    if (hasCorruptedData || toDoList.isEmpty) {
      // Sichere das Hochzeitsdatum
      final savedWeddingDate = weddingDate;

      // Lösche korrupte ToDo-Daten
      toDoList.clear();
      _myBoxToDo.delete("TODOLIST");

      // Stelle das Hochzeitsdatum wieder her
      if (savedWeddingDate != null) {
        updateWeddingDate(savedWeddingDate);
      }

      // Erstelle neue Initialdaten
      createInitialDataToDo();
    }
  }

  // Bereinige ungültige ToDos
  void cleanupTodos() {
    final originalCount = toDoList.length;

    // Entferne ungültige ToDos
    toDoList.removeWhere((todo) =>
        todo.category < 0 ||
        todo.category >= TodoCategory.categories.length ||
        todo.task.trim().isEmpty ||
        todo.task.trim().toLowerCase() == "unbekannt" ||
        todo.task.trim().toLowerCase() == "unknown");

    // Entferne Duplikate
    final Map<String, TodoItem> uniqueTodos = {};
    for (final todo in toDoList) {
      final key = todo.task.trim().toLowerCase();
      if (!uniqueTodos.containsKey(key)) {
        uniqueTodos[key] = todo;
      }
    }
    toDoList = uniqueTodos.values.toList();

    // Sortiere ToDos nach Kategorie
    toDoList.sort((a, b) => a.category.compareTo(b.category));

    // Wenn nach der Bereinigung keine ToDos mehr vorhanden sind
    if (toDoList.isEmpty && originalCount > 0) {
      createInitialDataToDo();
      return;
    }

    if (originalCount != toDoList.length) {
      updateDataBaseToDo();
    }
  }

  // Filtere ToDos nach Kategorie
  List<TodoItem> getTodosByCategory(int category) {
    return toDoList.where((todo) => todo.category == category).toList();
  }

  // Füge ein neues ToDo hinzu
  void addTodo(String task, int category) {
    toDoList.add(TodoItem(task: task, category: category));
    updateDataBaseToDo();
  }

  // Lösche ein ToDo
  void deleteTodo(TodoItem todo) {
    toDoList.remove(todo);
    updateDataBaseToDo();
  }

  // Toggle den Completed-Status eines ToDos
  void toggleTodoCompleted(TodoItem todo) {
    todo.isCompleted = !todo.isCompleted;
    updateDataBaseToDo();
  }

  // Berechne Statistiken für die UI
  Map<String, int> getStatistics() {
    return WeddingDateHelper.calculateStatistics(toDoList);
  }

  // Hole ToDos nach Status
  List<TodoItem> getTodosByStatus(CategoryStatus status) {
    return toDoList.where((todo) {
      return WeddingDateHelper.getCategoryStatus(todo.category, weddingDate) ==
          status;
    }).toList();
  }

  // Berechne Fortschritt in Prozent
  double getProgressPercentage() {
    if (toDoList.isEmpty) return 0.0;
    final completedCount = toDoList.where((todo) => todo.isCompleted).length;
    return (completedCount / toDoList.length) * 100;
  }

  // Hole die nächsten anstehenden ToDos (aktive Kategorie)
  List<TodoItem> getUpcomingTodos() {
    if (weddingDate == null) return [];

    final currentCategory = WeddingDateHelper.getCurrentCategory(weddingDate!);
    if (currentCategory == -1) return [];

    return toDoList
        .where((todo) => todo.category == currentCategory && !todo.isCompleted)
        .toList();
  }

  // Hole überfällige ToDos
  List<TodoItem> getOverdueTodos() {
    if (weddingDate == null) return [];

    return toDoList.where((todo) {
      final status =
          WeddingDateHelper.getCategoryStatus(todo.category, weddingDate);
      return status == CategoryStatus.overdue && !todo.isCompleted;
    }).toList();
  }

  // Validierung vor dem Speichern eines ToDos
  bool isValidTodo(String task, int category) {
    if (task.trim().isEmpty) return false;
    if (category < 0 || category >= TodoCategory.categories.length)
      return false;

    // Überprüfe auf Duplikate
    final existingTasks =
        toDoList.map((todo) => todo.task.trim().toLowerCase()).toList();
    return !existingTasks.contains(task.trim().toLowerCase());
  }

  // Batch-Update für mehrere ToDos
  void updateMultipleTodos(List<TodoItem> todos, bool completed) {
    for (final todo in todos) {
      if (toDoList.contains(todo)) {
        todo.isCompleted = completed;
      }
    }
    updateDataBaseToDo();
  }

  // Export der ToDo-Liste als einfaches Format
  Map<String, dynamic> exportToMap() {
    return {
      'weddingDate': weddingDate?.toIso8601String(),
      'todos': toDoList.map((todo) => todo.toMap()).toList(),
      'statistics': getStatistics(),
    };
  }

  // === SYNC-METHODEN (Cloud-Sync zwischen Hive und Firestore) ===

  // Konvertiere lokale TodoItem zu Firestore ChecklistItemModel
  ChecklistItemModel todoItemToChecklistModel(TodoItem todoItem, String userId) {
    return ChecklistItemModel(
      id: '', // Firestore generiert die ID
      taskName: todoItem.task,
      isCompleted: todoItem.isCompleted,
      createdAt: DateTime.now(),
      userId: userId,
    );
  }

  // Konvertiere Firestore ChecklistItemModel zu lokale TodoItem
  TodoItem checklistModelToTodoItem(ChecklistItemModel checklistModel) {
    return TodoItem(
      task: checklistModel.taskName,
      isCompleted: checklistModel.isCompleted,
      category: 2, // Default-Kategorie, kann später angepasst werden
    );
  }

  // Synchronisiere lokale Daten mit Firestore
  Future<void> syncWithFirestore(String userId) async {
    // Implementation für Cloud-Sync würde hier stehen
    // Dies würde die lokalen Hive-Daten mit Firestore abgleichen
  }

  // === DEBUG-METHODEN (nur für Entwicklung) ===

  // Debugging-Methode: Zeige alle Daten in der Hive-Box (optional)
  void debugHiveContents() {
    print("🔍 === HIVE DEBUG INFO ===");
    print("Box Name: ${_myBoxToDo.name}");
    print("Box Keys: ${_myBoxToDo.keys.toList()}");

    for (var key in _myBoxToDo.keys) {
      final value = _myBoxToDo.get(key);
      print("Key: $key, Type: ${value?.runtimeType}");
    }
    print("🔍 === END DEBUG INFO ===");
  }

  // Bereinige die Hive-Box komplett (nur für Entwicklung)
  void clearAllData() {
    _myBoxToDo.clear();
    toDoList.clear();
    weddingDate = null;
  }
}