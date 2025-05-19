import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:four_secrets_wedding_app/model/to_do_data_base.dart';
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/model/checklist_item.dart';
import 'package:four_secrets_wedding_app/model/dialog_box.dart';
import 'package:hive/hive.dart';

class Checklist extends StatefulWidget {
  const Checklist({super.key});

  @override
  State<Checklist> createState() => _ChecklistState();
}

class _ChecklistState extends State<Checklist> {
  // reference the hive box
  final _myBoxToDo = Hive.box('myboxToDo');
  ToDoDataBase db = ToDoDataBase();
  // text controller
  final _controller = TextEditingController();
  // list with Todo tasks

  @override
  void initState() {
    // if this is the 1st time ever openin the app, then create default data
    if (_myBoxToDo.get("TODOLIST") == null) {
      db.createInitialDataToDo();
    } else {
      // there already exists data
      db.loadDataToDo();
    }

    super.initState();
  }

  // checkbox was tapped
  void checkboxChanged(bool? value, int index) {
    setState(
      () {
        db.toDoList[index][1] = !db.toDoList[index][1];
      },
    );
    db.updateDataBaseToDo();
  }

  void saveNewTask() {
    setState(() {
      if (_controller.text.isNotEmpty) {
        db.toDoList.add([_controller.text, false]);
        _controller.clear();
      }
      Navigator.of(context).pop();
      // createNewTask();
    });
    db.updateDataBaseToDo();
  }

  void createNewTask() {
    showDialog(
      context: context,
      builder: (context) {
        return DialogBox(
            controller: _controller,
            onSave: saveNewTask,
            onCancel: () => Navigator.of(context).pop(),
            isToDo: true,
            isGuest: false);
      },
    );
  }

  void onDelete(int index) {
    setState(() {
      db.toDoList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue.getInstance(),
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
              width: MediaQuery.of(context).size.width,
              child: Image.asset(
                'assets/images/checklist/checklist.jpg',
                fit: BoxFit.cover,
              ),
            ),
            FourSecretsDivider(),
            ListView.builder(
              physics: ClampingScrollPhysics(),
              padding: EdgeInsets.only(bottom: 90),
              itemCount: db.toDoList.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return CheckListItem(
                  taskName: db.toDoList[index][0],
                  taskCompleted: db.toDoList[index][1],
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
