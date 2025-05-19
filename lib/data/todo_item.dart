class ToDo {
  String? id;
  String? todoText;
  bool isDone;

  ToDo({
    required this.id,
    required this.todoText,
    required this.isDone,
  });

  static List<ToDo> todoList() {
    return [
      ToDo(id: '01', todoText: 'Hochzeitstag festlegen', isDone: true),
      ToDo(
          id: '02',
          todoText: 'Anmeldung zur Eheschließung (Stndesamt/Kirche)',
          isDone: true),
      ToDo(id: '03', todoText: 'Gästeliste erstellen', isDone: false),
      ToDo(id: '04', todoText: 'Trauzeugen bestimmen', isDone: false),
      ToDo(id: '05', todoText: 'Junggesellenabschied planen', isDone: true),
    ];
  }
}
