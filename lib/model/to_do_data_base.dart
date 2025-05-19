import 'package:hive_flutter/hive_flutter.dart';

class ToDoDataBase {
  List toDoList = [];

  // reference our box
  final _myBoxToDo = Hive.box('myboxToDo');

  // run this method if this is the 1st time ever opening this app
  void createInitialDataToDo() {
    toDoList = [
      ["Übernachtung Gäste", false],
      ["Flitterwochen organisieren", false],
      ["Fotograf organisieren", false],
      ["Location aussuchen/buchen", false],
      ["Trauzeugen bestimmen", false],
      ["Eheringe aussuchen", false],
      ["Brautkleid aussuchen/anprobieren", false],
      ["Hochzeitstorte bestellen", false],
      ["Geschenke für die Gäste?", false],
      ["Trauzeugen Outfit bestimmen", false],
      ["Eventprogramm planen", false],
      ["Sitzplan erstellen", false],
      ["Deko organisieren", false],
      ["Floristen aussuchen", false],
      ["Hochzeitsrede schreiben", false],
      ["Wedding Designer buchen", false],
      ["Personal Training organisieren", false],
      ["Tanzkurs besuchen", false],
      ["Jungg. Abschied planen/feiern", false],
      ["Ringkissen aussuchen", false],
      ["Fotograf organisieren", false]
    ];
  }

  // load the data from database ToDo
  void loadDataToDo() {
    toDoList = _myBoxToDo.get("TODOLIST");
  }

  // update the database ToDo
  void updateDataBaseToDo() {
    _myBoxToDo.put("TODOLIST", toDoList);
  }
}
