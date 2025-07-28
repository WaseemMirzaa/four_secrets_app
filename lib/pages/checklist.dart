// checklist.dart - Erweitert mit Drag-and-Drop-Funktionalität
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:four_secrets_wedding_app/model/dialog_box.dart';
import 'package:four_secrets_wedding_app/model/to_do_data_base.dart';
import 'package:four_secrets_wedding_app/model/todo_item.dart';
import 'package:four_secrets_wedding_app/model/checklist_item.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:four_secrets_wedding_app/menue.dart';

class Checklist extends StatefulWidget {
  const Checklist({super.key});

  @override
  State<Checklist> createState() => _ChecklistState();
}

class _ChecklistState extends State<Checklist> with TickerProviderStateMixin {
  // reference the hive box
  final Box _myBoxToDo = Hive.box('myboxToDo');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Key key = GlobalKey<MenueState>();

  ToDoDataBase db = ToDoDataBase();
  bool _isLoading = false;

  // text controller
  final _controller = TextEditingController();

  // Performance-Optimierung: Cache für Kategorie-Status
  Map<int, CategoryStatus> _categoryStatusCache = {};
  DateTime? _lastCalculatedDate;

  // State für Expand/Collapse der Kategorien
  Map<int, bool> _categoryExpandedState = {};

  // NEU: Drag-and-Drop State
  TodoItem? _draggingItem;
  int? _dragOverCategory;

  // Animation Controller für Drag-Feedback
  late AnimationController _dragAnimationController;
  late Animation<double> _dragAnimation;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initializeExpandedState();
    _initializeAnimations();
    _loadChecklist();
  }

  void _initializeAnimations() {
    _dragAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _dragAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _dragAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializeData() {
    // Prüfe, ob bereits Daten vorhanden sind
    if (_myBoxToDo.get("TODOLIST") == null) {
      // Erstmaliger App-Start - erstelle initiale Daten
      db.createInitialDataToDo();
    } else {
      // Lade vorhandene Daten
      db.loadDataToDo();

      // Repariere korrupte Daten falls vorhanden
      db.repairCorruptedData();

      // Sicherheitscheck: Falls nach Reparatur keine Daten vorhanden sind
      if (db.toDoList.isEmpty) {
        db.createInitialDataToDo();
      }
    }

    // Finale Bereinigung
    db.cleanupTodos();

    // Cache-Initialisierung
    _updateCategoryCache();
  }

  void _initializeExpandedState() {
    // Lade gespeicherte States oder setze Smart Defaults
    final savedExpandedState = _myBoxToDo.get("CATEGORY_EXPANDED_STATE");

    if (savedExpandedState != null && savedExpandedState is Map) {
      // Lade gespeicherte States
      _categoryExpandedState = Map<int, bool>.from(savedExpandedState);
    } else {
      // Smart Defaults: Aktive und überfällige Kategorien expanded, zukünftige collapsed
      for (int i = 0; i < TodoCategory.categories.length; i++) {
        final status = WeddingDateHelper.getCategoryStatus(i, db.weddingDate);
        _categoryExpandedState[i] = status == CategoryStatus.active ||
            status == CategoryStatus.overdue ||
            status == CategoryStatus.noDate;
      }
    }

    // Stelle sicher, dass alle Kategorien einen State haben
    for (int i = 0; i < TodoCategory.categories.length; i++) {
      _categoryExpandedState[i] ??= true;
    }
  }

  void _saveExpandedState() {
    _myBoxToDo.put("CATEGORY_EXPANDED_STATE", _categoryExpandedState);
  }

  void _toggleCategory(int categoryId) {
    setState(() {
      _categoryExpandedState[categoryId] =
          !(_categoryExpandedState[categoryId] ?? true);
    });
    _saveExpandedState();
  }

  // Performance-Optimierung: Update Category Cache nur wenn nötig
  void _updateCategoryCache() {
    if (db.weddingDate != _lastCalculatedDate) {
      _categoryStatusCache.clear();

      for (int i = 0; i < TodoCategory.categories.length; i++) {
        _categoryStatusCache[i] = WeddingDateHelper.getCategoryStatus(
          i,
          db.weddingDate,
        );
      }

      _lastCalculatedDate = db.weddingDate;
    }
  }

  int _getOpenTasksCount(int categoryId) {
    final categoryTodos = db.getTodosByCategory(categoryId);
    return categoryTodos.where((todo) => !todo.isCompleted).length;
  }

  // Firebase Integration für Cloud-Sync
  Future<void> _loadChecklist() async {
    if (_auth.currentUser == null) {
      print("User not logged in.");
      return;
    }
    print("User is logged in ${_auth.currentUser!.uid}.");

    // Hier könnte eine Firebase-Integration implementiert werden
    // Für jetzt verwenden wir die lokale Hive-Implementierung
  }

  // NEU: Prüfe ob Drop in Kategorie erlaubt ist
  bool _canDropInCategory(int targetCategory) {
    if (db.weddingDate == null)
      return true; // Wenn kein Datum gesetzt, erlaube alles

    final status =
        WeddingDateHelper.getCategoryStatus(targetCategory, db.weddingDate);
    return status == CategoryStatus.active ||
        status == CategoryStatus.future ||
        status == CategoryStatus.noDate;
  }

  // NEU: Drag-and-Drop Handlers
  void _onDragStarted(TodoItem item) {
    setState(() {
      _draggingItem = item;
    });
    _dragAnimationController.forward();

    // Haptic Feedback
    HapticFeedback.lightImpact();
  }

  void _onDragEnd() {
    setState(() {
      _draggingItem = null;
      _dragOverCategory = null;
    });
    _dragAnimationController.reverse();
  }

  void _onDragEnter(int categoryId) {
    if (_canDropInCategory(categoryId)) {
      setState(() {
        _dragOverCategory = categoryId;
      });
    }
  }

  void _onDragLeave() {
    setState(() {
      _dragOverCategory = null;
    });
  }

  bool _onDragAccept(TodoItem item, int targetCategory) {
    if (!_canDropInCategory(targetCategory)) {
      _showDropNotAllowedMessage();
      return false;
    }

    if (item.category == targetCategory) {
      return false; // Keine Änderung nötig
    }

    // Führe die Verschiebung durch
    setState(() {
      item.category = targetCategory;
      db.updateDataBaseToDo();
      _updateCategoryCache();

      // Auto-expand Ziel-Kategorie
      _categoryExpandedState[targetCategory] = true;
    });

    _saveExpandedState();

    // Erfolgs-Feedback
    HapticFeedback.mediumImpact();
    _showSuccessMessage(item.task, targetCategory);

    return true;
  }

  void _showDropNotAllowedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.block, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Verschiebung nur in aktuelle oder zukünftige Zeiträume möglich',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessMessage(String taskName, int targetCategory) {
    final categoryName = TodoCategory.getCategoryName(targetCategory);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '"$taskName" zu "$categoryName" verschoben',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // checkbox was tapped
  void checkboxChanged(TodoItem todo) {
    setState(() {
      db.toggleTodoCompleted(todo);
    });
  }

  void saveNewTask(String task, int category) {
    if (task.trim().isNotEmpty && db.isValidTodo(task, category)) {
      setState(() {
        db.addTodo(task, category);
        _updateCategoryCache();

        // Auto-expand die Kategorie wenn ein neues ToDo hinzugefügt wird
        _categoryExpandedState[category] = true;
      });

      _saveExpandedState();

      // Erfolgs-Feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aufgabe "${task.trim()}" wurde hinzugefügt'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        ),
      );
    }

    _controller.clear();
  }

  void createNewTask() async {
    var g = await showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing dialog while loading
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return DialogBox(
              controller: _controller,
              isLoading: _isLoading,
              onSave: () async {
                if (_controller.text.isEmpty) {
                  Navigator.of(context).pop();
                  return;
                }

                // Set loading state within dialog
                setDialogState(() => _isLoading = true);

                try {
                  // Add task with default category (current active category or 0)
                  int targetCategory = 0;
                  if (db.weddingDate != null) {
                    targetCategory =
                        WeddingDateHelper.getCurrentCategory(db.weddingDate!);
                  }

                  saveNewTask(_controller.text, targetCategory);
                  _controller.clear();

                  // Close dialog after successful save
                  if (context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                } catch (e) {
                  // Handle error if needed
                  print("Error adding task: $e");
                } finally {
                  // Reset loading state
                  setDialogState(() => _isLoading = false);
                }
              },
              onCancel: () => Navigator.of(context).pop(),
              isToDo: true,
              isGuest: false,
            );
          },
        );
      },
    );
    if (g == true) {
      _loadChecklist();
    }
  }

  void onDelete(TodoItem todo) {
    setState(() {
      db.deleteTodo(todo);
      _updateCategoryCache();
    });
  }

  void _selectWeddingDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          db.weddingDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      helpText: 'Hochzeitsdatum auswählen',
      cancelText: 'Abbrechen',
      confirmText: 'Bestätigen',
      fieldHintText: 'dd.mm.yyyy',
      fieldLabelText: 'Datum eingeben',
      errorFormatText: 'Ungültiges Datumsformat',
      errorInvalidText: 'Ungültiges Datum',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color.fromARGB(255, 107, 69, 106),
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != db.weddingDate) {
      setState(() {
        db.updateWeddingDate(picked);
        _updateCategoryCache();

        // Smart Update der Expanded States nach Datum-Änderung
        _updateExpandedStateAfterDateChange();
      });
      _saveExpandedState();
    }
  }

  void _updateExpandedStateAfterDateChange() {
    for (int i = 0; i < TodoCategory.categories.length; i++) {
      final status = WeddingDateHelper.getCategoryStatus(i, db.weddingDate);
      if (status == CategoryStatus.active || status == CategoryStatus.overdue) {
        _categoryExpandedState[i] = true;
      }
    }
  }

  Widget _buildStatisticItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getTimeUntilWedding() {
    if (db.weddingDate == null) return '';
    return WeddingDateHelper.formatTimeUntilWedding(db.weddingDate!);
  }

  Widget _buildWeddingDateSection() {
    final statistics = db.getStatistics();
    final progressPercentage = db.getProgressPercentage();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 16),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        elevation: 3.0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(25, 107, 69, 106),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Color.fromARGB(255, 107, 69, 106),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Hochzeitsdatum',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 107, 69, 106),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Datum und Button Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          db.weddingDate != null
                              ? '${db.weddingDate!.day.toString().padLeft(2, '0')}.${db.weddingDate!.month.toString().padLeft(2, '0')}.${db.weddingDate!.year}'
                              : 'Noch nicht festgelegt',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: db.weddingDate != null
                                ? Colors.black87
                                : Colors.grey[600],
                          ),
                        ),
                        if (db.weddingDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _getTimeUntilWedding(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            maxLines: 2,
                          ),
                        ],
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _selectWeddingDate,
                    icon: Icon(
                      db.weddingDate != null ? Icons.edit : Icons.add,
                      size: 18,
                    ),
                    label: Text(
                      db.weddingDate != null ? 'Ändern' : 'Festlegen',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 107, 69, 106),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),

              // Fortschrittsbalken
              if (statistics['total']! > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      // Fortschrittsbalken
                      Row(
                        children: [
                          Icon(Icons.trending_up,
                              color: const Color.fromARGB(255, 107, 69, 106),
                              size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Fortschritt: ${progressPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progressPercentage / 100,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color.fromARGB(255, 107, 69, 106),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Statistics Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatisticItem(
                              'Gesamt',
                              statistics['total']!.toString(),
                              Icons.list_alt,
                              Color.fromARGB(255, 107, 69, 106),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey.shade300,
                          ),
                          Expanded(
                            child: _buildStatisticItem(
                              'Erledigt',
                              statistics['completed']!.toString(),
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey.shade300,
                          ),
                          Expanded(
                            child: _buildStatisticItem(
                              'Offen',
                              statistics['pending']!.toString(),
                              Icons.schedule,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Info-Box für Drag-and-Drop
              if (db.toDoList.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 107, 69, 106)
                        .withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color.fromARGB(255, 107, 69, 106)
                          .withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.touch_app,
                        color: const Color.fromARGB(255, 107, 69, 106),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tipp: Halte eine Aufgabe gedrückt, um sie in einen anderen Zeitraum zu verschieben',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color.fromARGB(255, 107, 69, 106),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Warning wenn kein Datum gesetzt
              if (db.weddingDate == null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Legen Sie Ihr Hochzeitsdatum fest, um die intelligente Zeitplanung zu aktivieren!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // NEU: Erweiterte Kategorie-Sektion mit DragTarget
  Widget _buildCategorySection(int categoryId) {
    final category = TodoCategory.categories[categoryId];
    final categoryTodos = db.getTodosByCategory(categoryId);
    final openTasksCount = _getOpenTasksCount(categoryId);
    final isExpanded = _categoryExpandedState[categoryId] ?? true;
    final canDropHere = _canDropInCategory(categoryId);
    final isDragOver = _dragOverCategory == categoryId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      child: DragTarget<TodoItem>(
        onAcceptWithDetails: (details) =>
            _onDragAccept(details.data, categoryId),
        onMove: (details) {
          if (canDropHere && _draggingItem != null) {
            _onDragEnter(categoryId);
          }
        },
        onLeave: (item) => _onDragLeave(),
        builder: (context, candidateData, rejectedData) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isDragOver && canDropHere
                  ? Border.all(
                      color: const Color.fromARGB(255, 107, 69, 106),
                      width: 2,
                    )
                  : null,
              boxShadow: isDragOver && canDropHere
                  ? [
                      BoxShadow(
                        color: const Color.fromARGB(255, 107, 69, 106)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Material(
              borderRadius: BorderRadius.circular(12),
              elevation: WeddingDateHelper.getCategoryElevation(
                categoryId,
                db.weddingDate,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: WeddingDateHelper.getCategoryContainerColors(
                      categoryId,
                      db.weddingDate,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Kategorie-Header
                    InkWell(
                      onTap: () => _toggleCategory(categoryId),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: isExpanded
                            ? Radius.zero
                            : const Radius.circular(12),
                        bottomRight: isExpanded
                            ? Radius.zero
                            : const Radius.circular(12),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: WeddingDateHelper.getCategoryHeaderColors(
                              categoryId,
                              db.weddingDate,
                            ),
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isExpanded
                                ? Radius.zero
                                : const Radius.circular(12),
                            bottomRight: isExpanded
                                ? Radius.zero
                                : const Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        category.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      // NEU: Drop-Zone Indikator
                                      if (_draggingItem != null) ...[
                                        const SizedBox(width: 8),
                                        Icon(
                                          canDropHere
                                              ? Icons.check_circle
                                              : Icons.block,
                                          size: 16,
                                          color: canDropHere
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        WeddingDateHelper.getCategoryIcon(
                                          categoryId,
                                          db.weddingDate,
                                        ),
                                        size: 14,
                                        color: WeddingDateHelper
                                            .getCategoryIconColor(
                                          categoryId,
                                          db.weddingDate,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          WeddingDateHelper
                                              .getCategoryStatusText(
                                            categoryId,
                                            db.weddingDate,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: WeddingDateHelper
                                                .getCategoryIconColor(
                                              categoryId,
                                              db.weddingDate,
                                            ),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color.fromARGB(229, 255, 255, 255),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Color.fromARGB(77, 255, 255, 255),
                                    ),
                                  ),
                                  child: Text(
                                    '$openTasksCount ${openTasksCount == 1 ? 'Aufgabe' : 'Aufgaben'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                AnimatedRotation(
                                  turns: isExpanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: const Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 24,
                                    color: Color.fromARGB(255, 107, 69, 106),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ToDo Items mit Drag-and-Drop
                    AnimatedCrossFade(
                      firstChild:
                          const SizedBox(width: double.infinity, height: 0),
                      secondChild: categoryTodos.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                children: categoryTodos.map((todo) {
                                  return _buildDraggableCheckListItem(todo);
                                }).toList(),
                              ),
                            )
                          : _buildEmptyCategory(categoryId),
                      crossFadeState: isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                      sizeCurve: Curves.easeInOut,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // NEU: Draggable CheckListItem
  Widget _buildDraggableCheckListItem(TodoItem todo) {
    return Draggable<TodoItem>(
      data: todo,
      onDragStarted: () => _onDragStarted(todo),
      onDragEnd: (details) => _onDragEnd(),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: ScaleTransition(
        scale: _dragAnimation,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: MediaQuery.of(context).size.width - 100,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 107, 69, 106).withOpacity(0.9),
                  const Color.fromARGB(255, 107, 69, 106).withOpacity(0.7),
                ],
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.drag_indicator,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    todo.task,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: CheckListItem(
          taskName: todo.task,
          taskCompleted: todo.isCompleted,
          onChanged: (value) => checkboxChanged(todo),
          deleteFunction: (context) => onDelete(todo),
        ),
      ),
      child: CheckListItem(
        taskName: todo.task,
        taskCompleted: todo.isCompleted,
        onChanged: (value) => checkboxChanged(todo),
        deleteFunction: (context) => onDelete(todo),
      ),
    );
  }

  Widget _buildEmptyCategory(int categoryId) {
    final canDropHere = _canDropInCategory(categoryId);
    final isDragOver = _dragOverCategory == categoryId;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDragOver && canDropHere
                  ? const Color.fromARGB(255, 107, 69, 106).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isDragOver && canDropHere
                  ? Border.all(
                      color: const Color.fromARGB(255, 107, 69, 106),
                      width: 2,
                      style: BorderStyle.solid,
                    )
                  : Border.all(color: Colors.transparent),
            ),
            child: Column(
              children: [
                Icon(
                  isDragOver && canDropHere
                      ? Icons.add_circle_outline
                      : Icons.check_circle_outline,
                  color: isDragOver && canDropHere
                      ? const Color.fromARGB(255, 107, 69, 106)
                      : Colors.grey.shade400,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  isDragOver && canDropHere
                      ? 'Hier ablegen'
                      : 'Noch keine Aufgaben in diesem Zeitraum',
                  style: TextStyle(
                    color: isDragOver && canDropHere
                        ? const Color.fromARGB(255, 107, 69, 106)
                        : Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                    fontWeight: isDragOver && canDropHere
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<int> _getSortedCategoryIds() {
    return List.generate(TodoCategory.categories.length,
        (index) => TodoCategory.categories.length - 1 - index);
  }

  @override
  void dispose() {
    _controller.dispose();
    _dragAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _updateCategoryCache();

    return SafeArea(
      child: Scaffold(
        drawer: Menue.getInstance(key),
        appBar: AppBar(
          foregroundColor: const Color.fromARGB(255, 255, 255, 255),
          title: const Text('Checkliste'),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
          elevation: 2.0,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: createNewTask,
          elevation: 6.0,
          child: const Icon(Icons.add),
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            // Header Bild
            Container(
              width: MediaQuery.sizeOf(context).width,
              child: Image.asset(
                'assets/images/checklist/checklist.jpg',
                fit: BoxFit.cover,
              ),
            ),

            // Divider
            FourSecretsDivider(),

            // Hochzeitsdatum Section
            _buildWeddingDateSection(),

            // Kategorie Sections mit Drag-and-Drop
            ..._getSortedCategoryIds().map((categoryId) {
              return _buildCategorySection(categoryId);
            }).toList(),

            // Bottom Padding für FloatingActionButton
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
