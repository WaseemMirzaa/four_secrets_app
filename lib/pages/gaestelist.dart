import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/model/dialog_box.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:four_secrets_wedding_app/model/gaestelist_item.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';

class Gaestelist extends StatefulWidget {
  const Gaestelist({super.key});

  @override
  State<Gaestelist> createState() => _GaestelistState();
}

class _GaestelistState extends State<Gaestelist> {
  // Firebase references
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Key key = GlobalKey<MenueState>();

  // List to store guests
  List<Map<String, dynamic>> guestList = [];

  // Text controller
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGuests();
  }

  // Load guests from Firestore
  Future<void> _loadGuests() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        // Handle not logged in case
        return;
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('guests')
          .orderBy('createdAt',
              descending: false) // Sort by creation time, oldest first
          .get();

      final List<Map<String, dynamic>> loadedGuests = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        loadedGuests.add({
          'id': doc.id,
          'name': data['name'] ?? '',
          'takePart': data['takePart'] ?? false,
          'mayBeTakePart': data['mayBeTakePart'] ?? false,
          'canceled': data['canceled'] ?? false,
        });
      }

      setState(() {
        guestList = loadedGuests;
      });
    } catch (e) {
      print('${AppConstants.loadGuestsError}$e');
    }
  }

  void statusChanged(
    String selectedName,
    int index,
  ) async {
    final guest = guestList[index];
    final guestId = guest['id'];
    final userId = _auth.currentUser?.uid;

    if (userId == null) return;

    try {
      Map<String, dynamic> updates = {};

      setState(() {
        if (selectedName == States.takePart.name) {
          guestList[index]['takePart'] = !guestList[index]['takePart'];
          guestList[index]['mayBeTakePart'] = false;
          guestList[index]['canceled'] = false;

          updates = {
            'takePart': guestList[index]['takePart'],
            'mayBeTakePart': false,
            'canceled': false,
          };
        } else if (selectedName == States.mayBeTakePart.name) {
          guestList[index]['mayBeTakePart'] =
              !guestList[index]['mayBeTakePart'];
          guestList[index]['takePart'] = false;
          guestList[index]['canceled'] = false;

          updates = {
            'takePart': false,
            'mayBeTakePart': guestList[index]['mayBeTakePart'],
            'canceled': false,
          };
        } else if (selectedName == States.canceled.name) {
          guestList[index]['canceled'] = !guestList[index]['canceled'];
          guestList[index]['takePart'] = false;
          guestList[index]['mayBeTakePart'] = false;

          updates = {
            'takePart': false,
            'mayBeTakePart': false,
            'canceled': guestList[index]['canceled'],
          };
        }
      });

      // Update in Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('guests')
          .doc(guestId)
          .update(updates);
    } catch (e) {
      print('${AppConstants.updateGuestStatusError}$e');
      // Reload guests to ensure UI is in sync with database
      _loadGuests();
    }
  }

  void createNewTask() {
    bool _isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DialogBox(
              controller: _controller,
              onSave: () async {
                // Set loading state immediately
                setState(() {
                  _isLoading = true;
                });

                try {
                  if (_controller.text.isEmpty) {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                    return;
                  }

                  final userId = _auth.currentUser?.uid;
                  if (userId == null) {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                    return;
                  }

                  try {
                    final guestName = _controller.text;
                    _controller.clear();

                    // Add to Firestore
                    await _firestore
                        .collection('users')
                        .doc(userId)
                        .collection('guests')
                        .add({
                      'name': guestName,
                      'takePart': false,
                      'mayBeTakePart': false,
                      'canceled': false,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    // Close dialog first
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }

                    // Then reload guests
                    await _loadGuests();
                  } catch (e) {
                    print('Error adding guest: $e');
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      SnackBarHelper.showErrorSnackBar(
                          context, 'Error adding guest: $e');
                    }
                  }
                } catch (e) {
                  print('Error in createNewTask: $e');
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              onCancel: () {
                if (!_isLoading) {
                  Navigator.of(context).pop();
                }
              },
              isToDo: false,
              isGuest: true,
              isLoading: _isLoading,
            );
          },
        );
      },
    );
  }

  void onDelete(int index) async {
    final guest = guestList[index];
    final guestId = guest['id'];
    final userId = _auth.currentUser?.uid;

    if (userId == null) return;

    try {
      // Remove from local state
      setState(() {
        guestList.removeAt(index);
      });

      // Delete from Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('guests')
          .doc(guestId)
          .delete();
    } catch (e) {
      print('${AppConstants.deleteGuestError}$e');
      // Reload guests to ensure UI is in sync with database
      _loadGuests();
    }
  }

  bool isPressedBtn1 = false;

  void buttonIsPressed(int id) {
    setState(() {
      if (id == 1) {
        isPressedBtn1 = true;
      }
    });
  }

  (int, int) calculateAmountOfGuests() {
    int sumTakePart = 0;
    int sumMayBeTakePart = 0;

    for (var guest in guestList) {
      if (guest['takePart'] == true) {
        sumTakePart += 1;
      }
      if (guest['mayBeTakePart'] == true) {
        sumMayBeTakePart += 1;
      }
    }

    return (sumTakePart, sumMayBeTakePart);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue.getInstance(key),
        appBar: AppBar(
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          title: Text(AppConstants.gaestelistTitle),
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
                AppConstants.gaestelistBackground,
                fit: BoxFit.cover,
                // Optimize image quality for better performance
                filterQuality: FilterQuality.medium,
                // Add caching for better performance
                cacheWidth: MediaQuery.of(context).size.width.toInt(),
              ),
            ),
            FourSecretsDivider(),
            Container(
              padding: const EdgeInsets.only(left: 25, right: 25, top: 5),
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 107, 69, 106),
                      const Color.fromARGB(255, 107, 69, 106),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      children: [
                        Text(
                          AppConstants.confirmedLabel,
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Icon(
                          Icons.check_box_outlined,
                          color: Colors.green,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          AppConstants.maybeLabel,
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Icon(
                          Icons.check_box_outlined,
                          color: Colors.amber,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          AppConstants.declinedLabel,
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Icon(
                          Icons.check_box_outlined,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            guestList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        AppConstants.noGuestsMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: ClampingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 25),
                    itemCount: guestList.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return GaestelistItem(
                          guestName: guestList[index]['name'],
                          takePart: guestList[index]['takePart'],
                          mayBeTakePart: guestList[index]['mayBeTakePart'],
                          canceled: guestList[index]['canceled'],
                          deleteFunction: (context) => onDelete(index),
                          statusChanged: (context) =>
                              statusChanged(context, index));
                    },
                  ),
            FourSecretsDivider(),
            Container(
              padding: const EdgeInsets.only(left: 25, right: 25, top: 5),
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 107, 69, 106),
                      const Color.fromARGB(255, 107, 69, 106),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      children: [
                        Text(
                          AppConstants.guestCountLabel,
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2.5),
                        ),
                        Icon(
                          Icons.check_box_outlined,
                          color: Colors.green,
                        ),
                        Text(
                          ":",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                        ),
                        Text(
                          "${calculateAmountOfGuests().$1}",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                        ),
                        Text(
                          AppConstants.guestCountLabel,
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2.5),
                        ),
                        Icon(
                          Icons.check_box_outlined,
                          color: Colors.amber,
                        ),
                        Text(
                          ":",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                        ),
                        Text(
                          "${calculateAmountOfGuests().$2}",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            FourSecretsDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Color.fromARGB(255, 107, 69, 106),
                          padding: const EdgeInsets.all(15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 5,
                          backgroundColor: isPressedBtn1
                              ? Color.fromARGB(255, 204, 145, 203)
                              : Colors.white,
                        ),
                        onPressed: () {
                          buttonIsPressed(1);
                          Navigator.of(context)
                              .pushNamed(RouteManager.tablesManagementPage);
                        },
                        label: const Text(
                          AppConstants.tableManagementButtonLabel,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        icon: const Icon(Icons.arrow_forward_ios_sharp),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 25),
            ),
          ],
        ),
      ),
    );
  }
}

enum States { takePart, mayBeTakePart, canceled }

// Add this function outside the class to be used with compute()
// ignore: unused_element
Future<Map<String, dynamic>> _addGuestInBackground(
    Map<String, dynamic> params) async {
  try {
    // This function runs in a separate isolate
    return {
      'success': true,
      'name': params['name'],
    };
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}
