import 'package:firebase_auth/firebase_auth.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/model/checklist_item.dart';
import 'package:four_secrets_wedding_app/model/dialog_box.dart';
import 'package:four_secrets_wedding_app/services/check_list_service.dart';

class Checklist extends StatefulWidget {
  const Checklist({super.key});

  @override
  State<Checklist> createState() => _ChecklistState();
}

class _ChecklistState extends State<Checklist> {
  // reference the hive box
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final key = GlobalKey<MenueState>();

  ToDoDataBase db = ToDoDataBase();
  bool _isLoading = true;

  // text controller
  final _controller = TextEditingController();
  // list with Todo tasks

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    setState(() => _isLoading = true);

    if (_auth.currentUser == null) {
      print("User not logged in.");
      setState(() => _isLoading = false);
      return;
    }
    print("User is logged in ${_auth.currentUser!.uid}.");

    await db.loadDataToDo();

    setState(() => _isLoading = false);
  }

  // Checkbox was tapped
  void checkboxChanged(bool? value, int index) async {
    if (value == null) return;

    setState(() {
      // Update UI immediately for better UX
      db.toDoList[index].isCompleted = value;
    });

    // Update in Firebase
    await db.updateTaskStatus(index, value);
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
                    // Add task to Firebase
                    await db.addTask(_controller.text);
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
                isGuest: false);
          },
        );
      },
    );
    if (g == true) {
      _loadChecklist();
    }
  }

  void onDelete(int index) async {
    setState(() => _isLoading = true);

    // Delete from Firebase
    await db.deleteTask(index);

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue.getInstance(key),
        appBar: AppBar(
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          title: const Text('Checkliste'),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: createNewTask,
          child: const Icon(Icons.add),
        ),
        body: ListView(
          children: [
            Container(
              width: MediaQuery.sizeOf(context).width,
              child: Image.asset(
                'assets/images/checklist/checklist.jpg',
                fit: BoxFit.cover,
              ),
            ),
            FourSecretsDivider(),
            // if (db.toDoList.isEmpty)
            //       Padding(
            //         padding: const EdgeInsets.all(16.0),
            //         child: Center(
            //           child: Text(
            //             'Keine Aufgaben vorhanden. Füge deine erste Aufgabe hinzu!',
            //             style: TextStyle(fontSize: 16),
            //             textAlign: TextAlign.center,
            //           ),
            //         ),
            //       ),
            ListView.builder(
              physics: ClampingScrollPhysics(),
              padding: EdgeInsets.only(bottom: 90),
              itemCount: db.toDoList.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                print(db.toDoList.length);
                return CheckListItem(
                  taskName: db.toDoList[index].taskName,
                  taskCompleted: db.toDoList[index].isCompleted,
                  onChanged: (value) => checkboxChanged(value, index),
                  deleteFunction: (context) => onDelete(index),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
