import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/screens/budget_item.dart';
import 'package:four_secrets_wedding_app/screens/dialog_box.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';

class Budget extends StatefulWidget {
  Budget({super.key});

  @override
  State<Budget> createState() => _BudgetState();
}

class _BudgetState extends State<Budget> {
  // text controller
  final _controller = TextEditingController();
  final _wholeBudgetController = TextEditingController();
  final node1 = FocusNode();
  int wholeBudget = 0;
  int _tempBudget = 0;
  int _maxWholeBudget = 999999;

  final key = GlobalKey<MenueState>();

  List budgetList = [
    ["Fotograph", 0],
    ["Location", 0]
  ];

  @override
  void initState() {
    _wholeBudgetController.addListener(_initializeBudget);
    super.initState();
  }

  void _initializeBudget() {
    if (int.tryParse(_wholeBudgetController.text) != null) {
      int newBudget = int.parse(_wholeBudgetController.text);
      if (newBudget >= 0 && newBudget <= _maxWholeBudget) {
        wholeBudget = newBudget;
        int tempCosts = calculateCosts();
        calculateBudget(tempCosts);
      }
    }
  }

  void _budgetChanged(String value, int index) {
    setState(
      () {
        if (int.tryParse(value) != null) {
          int costs = int.parse(value);
          if (costs >= 0 && costs <= _maxWholeBudget) {
            budgetList[index][1] = costs;
          }
        } else {
          budgetList[index][1] = 0;
        }
      },
    );
    calculateCosts();
  }

  int calculateCosts() {
    int costs = 0;
    for (var element in budgetList) {
      costs += element[1] as int;
    }
    calculateBudget(costs);
    return costs;
  }

  void calculateBudget(int costs) {
    var tempResult = wholeBudget - costs;
    _tempBudget = tempResult >= 0 ? tempResult : 0;
  }

  void createNewTask() {
    showDialog(
      context: context,
      builder: (context) {
        return DialogBox(
            controller: _controller,
            onSave: saveNewTask,
            onCancel: () => Navigator.of(context).pop(),
            isToDo: false,
            isGuest: false,
            isBudget: true);
      },
    );
  }

  void saveNewTask() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        budgetList.add([_controller.text, 0]);
        _controller.clear();
      });
      Navigator.of(context).pop();
    } else {
      // Show error message using the app-wide error snackbar
      SnackBarHelper.showErrorSnackBar(
        context,
        'Bitte geben Sie einen Namen für den Budgetposten ein.',
      );
    }
  }

  void onDelete(int index) {
    setState(() {
      budgetList.removeAt(index);
    });
  }

  void dispose() {
    // Wichtig: Den Listener entfernen, um Speicherlecks zu vermeiden
    _controller.dispose();
    _wholeBudgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue.getInstance(key),
        appBar: AppBar(
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          title: const Text('Budget'),
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
                'assets/images/budget/budget.png',
                fit: BoxFit.cover,
              ),
            ),
            FourSecretsDivider(),
            Container(
              padding: EdgeInsets.only(left: 25, right: 25, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Budget:",
                    style: TextStyle(color: Colors.black, fontSize: 20),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                  Container(
                    height: 40,
                    width: 120,
                    child: GestureDetector(
                      onTap: () => FocusScope.of(context).requestFocus(node1),
                      child: TextField(
                        focusNode: node1,
                        controller: _wholeBudgetController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          label: Text(
                            "Betrag",
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[500]),
                          ),
                          isCollapsed: true,
                          prefixIcon: Icon(
                            Icons.euro_symbol_rounded,
                            size: 18,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 126, 80, 123),
                                width: 2),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListView.builder(
              physics: ClampingScrollPhysics(),
              padding: EdgeInsets.only(bottom: 10),
              itemCount: budgetList.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return BudgetItem(
                  taskName: budgetList[index][0],
                  onChanged: (value) => _budgetChanged(value, index),
                  deleteFunction: (context) => onDelete(index),
                );
              },
            ),
            FourSecretsDivider(),
            Container(
              padding: EdgeInsets.only(left: 25, right: 25, top: 10),
              child: Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color.fromARGB(255, 107, 69, 106),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Guthaben:",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          Text(
                            "${_tempBudget.toString()} €",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Ausgaben:",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "${calculateCosts().toString()} €",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 45),
            ),
          ],
        ),
      ),
    );
  }
}
