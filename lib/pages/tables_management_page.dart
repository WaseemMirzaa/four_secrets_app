import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:four_secrets_wedding_app/model/table_dialog_box.dart';
import '../models/table_model.dart';
import '../services/table_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/Pdf/generate_table_pdf.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/pages/PdfViewPage.dart';
import 'package:four_secrets_wedding_app/services/native_download_service.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/widgets/custom_dialog.dart';
import 'package:four_secrets_wedding_app/widgets/table_mangemant_widget.dart';

class TablesManagementPage extends StatefulWidget {
  const TablesManagementPage({Key? key}) : super(key: key);

  @override
  State<TablesManagementPage> createState() => _TablesManagementPageState();
}

class _TablesManagementPageState extends State<TablesManagementPage> {
  final TableService _tableService = TableService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final key = GlobalKey<MenueState>();

  List<TableModel> _tables = [];
  List<Map<String, dynamic>> _guests = [];
  Map<String, List<Map<String, dynamic>>> _tableGuestsMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final tables = await _tableService.getTables();
      final guests = await _loadGuestsFromFirebase();

      Map<String, List<Map<String, dynamic>>> tableGuestsMap = {};
      for (var table in tables) {
        tableGuestsMap[table.id] = guests
            .where((guest) => table.assignedGuestIds.contains(guest['id']))
            .toList();
      }

      setState(() {
        _tables = tables;
        _guests = guests;
        _tableGuestsMap = tableGuestsMap;
      });
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
            context, '${AppConstants.loadDataError}$e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadGuestsFromFirebase() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('guests')
          .orderBy('name')
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

      return loadedGuests;
    } catch (e) {
      print('Error loading guests: $e');
      return [];
    }
  }

  Future<void> _navigateToAddEditTable([TableModel? table]) async {
    final nameController = TextEditingController();
    final maxGuestsController = TextEditingController();
    var selectedTableType; // Default value
    final tableTypes = [
      AppConstants.tableTypeRound,
      AppConstants.tableTypeOval,
      AppConstants.tableTypeRectangular,
      AppConstants.tableTypeSquare
    ];
    bool _isLoading = false; // Track loading state

    // If editing, populate the controllers with existing data
    if (table != null) {
      nameController.text = table.nameOrNumber;
      maxGuestsController.text = table.maxGuests.toString();
      selectedTableType = table.tableType;
    }

    await showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while loading
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return TableDialogBox(
            nameController: nameController,
            maxGuestsController: maxGuestsController,
            onSave: () async {
              // Set loading state
              setState(() {
                _isLoading = true;
              });

              // Validate inputs
              if (nameController.text.isEmpty) {
                setState(() {
                  _isLoading = false;
                });
                SnackBarHelper.showErrorSnackBar(
                    context, AppConstants.enterTableNumberError);
                return;
              }

              final maxGuests = int.tryParse(maxGuestsController.text);
              if (maxGuests == null || maxGuests <= 0) {
                setState(() {
                  _isLoading = false;
                });
                SnackBarHelper.showErrorSnackBar(
                    context, AppConstants.enterValidGuestsError);
                return;
              }

              // Check for duplicate table names when adding a new table
              if (table == null) {
                bool tableNameExists = _tables.any((existingTable) =>
                    existingTable.nameOrNumber.toLowerCase() ==
                    nameController.text.toLowerCase());

                if (tableNameExists) {
                  setState(() {
                    _isLoading = false;
                  });
                  SnackBarHelper.showErrorSnackBar(
                      context, AppConstants.tableNameExistsError);
                  return;
                }
              } else {
                // When editing, check if the new name conflicts with any table other than the current one
                bool tableNameExists = _tables.any((existingTable) =>
                    existingTable.id != table.id &&
                    existingTable.nameOrNumber.toLowerCase() ==
                        nameController.text.toLowerCase());

                if (tableNameExists) {
                  setState(() {
                    _isLoading = false;
                  });
                  SnackBarHelper.showErrorSnackBar(
                      context, AppConstants.tableNameExistsError);
                  return;
                }
              }

              try {
                if (table == null) {
                  // Create new table
                  final newTable = TableModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    nameOrNumber: nameController.text,
                    tableType: selectedTableType,
                    maxGuests: maxGuests,
                    assignedGuestIds: [],
                  );
                  await _tableService.addTable(newTable);
                } else {
                  // Update existing table
                  final updatedTable = TableModel(
                    id: table.id,
                    nameOrNumber: nameController.text,
                    tableType: selectedTableType,
                    maxGuests: maxGuests,
                    assignedGuestIds: table.assignedGuestIds,
                  );
                  await _tableService.updateTable(updatedTable);
                }

                if (!mounted) return;
                Navigator.pop(context);
                _loadData();
              } catch (e) {
                if (!mounted) return;
                setState(() {
                  _isLoading = false;
                });
                SnackBarHelper.showErrorSnackBar(context,
                    '${table == null ? AppConstants.addTableError : AppConstants.updateTableError}$e');
              }
            },
            onCancel: () => Navigator.pop(context),
            selectedTableType: selectedTableType,
            onTableTypeChanged: (String newValue) {
              setState(() {
                selectedTableType = newValue;
              });
            },
            tableTypes: tableTypes,
            isLoading: _isLoading, // Pass loading state to dialog
          );
        });
      },
    );
  }

  Future<void> _showAssignGuestDialog(TableModel table) async {
    // Filter for guests who have confirmed attendance (takePart = true)
    // and are not already assigned to any table
    final availableGuests = _guests
        .where((guest) =>
            guest['takePart'] == true &&
            !_tables.any((t) => t.assignedGuestIds.contains(guest['id'])))
        .toList();

    if (availableGuests.isEmpty) {
      SnackBarHelper.showInfoSnackBar(context, AppConstants.noAvailableGuests);
      return;
    }

    // Track selected guests
    List<String> selectedGuestIds = [];
    // Flag to track if capacity warning was shown
    bool capacityWarningShown = false;
    // Loading state for buttons
    bool isAssigning = false;
    bool isCancelling = false;

    await showDialog(
      context: context,
      barrierDismissible:
          !isAssigning && !isCancelling, // Prevent dismissal during loading
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              contentPadding: EdgeInsets.zero,
              content: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.maxFinite,
                  color: Colors.grey.shade100,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        width: double.infinity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                              child: Text(
                                AppConstants.assignGuestTitle,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 12.0, right: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: availableGuests
                                  .map((guest) => Container(
                                        margin: EdgeInsets.only(top: 4.0),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: selectedGuestIds
                                                    .contains(guest['id'])
                                                ? Color.fromARGB(
                                                    255, 107, 69, 106)
                                                : Colors.black,
                                            width: selectedGuestIds
                                                    .contains(guest['id'])
                                                ? 2
                                                : 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: InkWell(
                                          onTap: isAssigning || isCancelling
                                              ? null // Disable during loading
                                              : () {
                                                  setState(() {
                                                    if (selectedGuestIds
                                                        .contains(
                                                            guest['id'])) {
                                                      selectedGuestIds
                                                          .remove(guest['id']);
                                                      // Reset warning flag when removing a guest
                                                      capacityWarningShown =
                                                          false;
                                                    } else {
                                                      // Check if adding this guest would exceed the table's capacity
                                                      if (table.assignedGuestIds
                                                                  .length +
                                                              selectedGuestIds
                                                                  .length <
                                                          table.maxGuests) {
                                                        selectedGuestIds
                                                            .add(guest['id']);
                                                      } else if (!capacityWarningShown) {
                                                        // Only show warning if it hasn't been shown yet
                                                        SnackBarHelper
                                                            .showInfoSnackBar(
                                                                context,
                                                                AppConstants
                                                                    .maxCapacityWarning);
                                                        capacityWarningShown =
                                                            true;
                                                      }
                                                    }
                                                  });
                                                },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0,
                                                vertical: 12.0),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        guest['name'].isNotEmpty
                                                            ? guest['name'][0]
                                                                    .toUpperCase() +
                                                                guest['name']
                                                                    .substring(
                                                                        1)
                                                            : '',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        guest['takePart']
                                                            ? 'Bestätigt'
                                                            : guest['mayBeTakePart']
                                                                ? 'Vielleicht'
                                                                : 'Abgelehnt',
                                                        style: TextStyle(
                                                          color: guest[
                                                                  'takePart']
                                                              ? Colors
                                                                  .green[700]
                                                              : guest[
                                                                      'mayBeTakePart']
                                                                  ? Colors.amber[
                                                                      700]
                                                                  : Colors
                                                                      .red[400],
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Icon(
                                                  selectedGuestIds
                                                          .contains(guest['id'])
                                                      ? Icons.check_circle
                                                      : Icons
                                                          .add_circle_outline,
                                                  color: Color.fromARGB(
                                                      255, 107, 69, 106),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 8.0, right: 8, top: 0, bottom: 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: ElevatedButton(
                                onPressed: isAssigning || isCancelling
                                    ? null
                                    : () async {
                                        setState(() {
                                          isCancelling = true;
                                        });

                                        // Add a small delay to show loading state
                                        await Future.delayed(
                                            Duration(milliseconds: 200));

                                        if (!mounted) return;
                                        Navigator.pop(context);
                                      },
                                style: ElevatedButton.styleFrom(
                                  elevation: 4,
                                  backgroundColor:
                                      Color.fromARGB(255, 107, 69, 106),
                                  foregroundColor:
                                      Color.fromARGB(255, 107, 69, 106),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isCancelling
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Text(
                                        AppConstants.cancelButtonText,
                                        style: TextStyle(color: Colors.white),
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: ElevatedButton(
                                onPressed: isAssigning ||
                                        isCancelling ||
                                        selectedGuestIds.isEmpty
                                    ? null
                                    : () async {
                                        setState(() {
                                          isAssigning = true;
                                        });

                                        try {
                                          // Assign all selected guests to the table
                                          for (String guestId
                                              in selectedGuestIds) {
                                            await _tableService
                                                .assignGuestToTable(
                                                    table.id, guestId);
                                          }

                                          if (!mounted) return;
                                          Navigator.pop(context);
                                          _loadData();

                                          // Show success message
                                          if (selectedGuestIds.length == 1) {
                                            SnackBarHelper.showSuccessSnackBar(
                                                context,
                                                AppConstants
                                                    .oneGuestAssignedSuccess);
                                          } else {
                                            SnackBarHelper.showSuccessSnackBar(
                                                context,
                                                AppConstants
                                                    .multipleGuestsAssignedSuccess);
                                          }
                                        } catch (e) {
                                          if (!mounted) return;
                                          setState(() {
                                            isAssigning = false;
                                          });
                                          SnackBarHelper.showErrorSnackBar(
                                              context,
                                              'Fehler beim Zuweisen: $e');
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  elevation: 4,
                                  backgroundColor:
                                      Color.fromARGB(255, 107, 69, 106),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isAssigning
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Text(
                                        AppConstants.assignGuestsButtonText,
                                        style: TextStyle(
                                            color: selectedGuestIds.isEmpty
                                                ? Colors.black
                                                : Colors.white),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(String tableId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CustomDialog(
          title: AppConstants.deleteTableTitle,
          message: AppConstants.deleteTableConfirmation,
          onConfirm: () async {
            await _deleteTable(tableId);
            Navigator.of(context).pop();
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
          confirmText: AppConstants.deleteButton,
          cancelText: AppConstants.cancelButton,
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(AppConstants.errorTitle),
        content: Text(message),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: Text(AppConstants.okButton),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTable(String tableId) async {
    try {
      await _tableService.deleteTable(tableId);

      // Optimistically update UI
      setState(() {
        _tables.removeWhere((table) => table.id == tableId);
      });

      if (mounted) {
        SnackBarHelper.showSuccessSnackBar(
            context, AppConstants.tableDeletedSuccess);
      }
    } catch (e) {
      // If error occurs, reload data
      _loadData();
      if (mounted) {
        _showErrorDialog('${AppConstants.deleteTableError}$e');
      }
    }
  }

  Widget _buildTableCard(TableModel table) {
    final assignedGuests = _tableGuestsMap[table.id] ?? [];
    final confirmedGuestCount =
        assignedGuests.where((g) => g['takePart'] == true).length;

    // Function to get the appropriate icon for each table type
    String getTableTypeIcon(String tableType) {
      if (tableType.isEmpty) return AppConstants.tableIconSquare;

      switch (tableType.toLowerCase()) {
        case 'rund':
          return AppConstants.tableIconCircle;
        case 'oval':
          return AppConstants.tableIconOval;
        case 'recheckig':
          return AppConstants.tableIconRectangle;
        case 'quadratisch':
          return AppConstants.tableIconSquare;
        default:
          return AppConstants.tableIconSquare;
      }
    }

    // Check if table type is oval to use image instead of icon
    // ignore: unused_local_variable
    bool isOvalTable = table.tableType.toLowerCase() == 'oval';

    return Card(
      color: Colors.grey.shade300,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: EdgeInsets.fromLTRB(24, 10, 24, 0),
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  table.nameOrNumber.isNotEmpty
                                      ? table.nameOrNumber[0].toUpperCase() +
                                          table.nameOrNumber.substring(1)
                                      : '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  AppConstants.tableTypePrefix,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                // Table type icon or image
                                Image.asset(
                                  getTableTypeIcon(table.tableType),
                                  width: 20,
                                  height: 20,
                                  color: Color.fromARGB(255, 107, 69, 106),
                                )
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${AppConstants.maxGuestsDisplay}${table.maxGuests}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(FontAwesomeIcons.penToSquare),
                      onPressed: () => _navigateToAddEditTable(table),
                      color: Color.fromARGB(255, 107, 69, 106),
                    ),
                    IconButton(
                      icon: const Icon(FontAwesomeIcons.trashCan,
                          size: 18, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(table.id),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppConstants.assignedGuestsCount}$confirmedGuestCount/${table.maxGuests})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...assignedGuests.map((guest) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      guest['name'].isNotEmpty
                                          ? guest['name'][0].toUpperCase() +
                                              guest['name'].substring(1)
                                          : '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      guest['takePart']
                                          ? 'Bestätigt'
                                          : guest['mayBeTakePart']
                                              ? 'Vielleicht'
                                              : 'Abgelehnt',
                                      style: TextStyle(
                                        color: guest['takePart']
                                            ? Colors.green[700]
                                            : guest['mayBeTakePart']
                                                ? Colors.amber[700]
                                                : Colors.red[400],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () async {
                                await _tableService.removeGuestFromTable(
                                    table.id, guest['id']);
                                _loadData();
                              },
                              color: Colors.red[400],
                              iconSize: 22,
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                      )),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(
                      AppConstants.assignGuestButton,
                      style:
                          TextStyle(color: Color.fromARGB(255, 107, 69, 106)),
                    ),
                    onPressed: confirmedGuestCount < table.maxGuests
                        ? () => _showAssignGuestDialog(table)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTableDialog() {
    _navigateToAddEditTable();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // backgroundColor: Colors.white,
        drawer: Menue.getInstance(key),
        appBar: AppBar(
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          title: Text(AppConstants.tableManagementTitle),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
          actions: [
            IconButton(
              icon: Icon(
                FontAwesomeIcons.download,
                size: 20,
              ),
              tooltip: AppConstants.addTableTooltip,
              onPressed: () async {
                await _downloadPdf();
              },
            ),
            // View PDF button
            IconButton(
              icon: Icon(
                FontAwesomeIcons.eye,
                size: 20,
              ),
              tooltip: 'View PDF',
              onPressed: () async {
                Uint8List? pdfBytes = await generateTableManagementPdf(
                  _tables,
                  _tableGuestsMap,
                );

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PdfViewPage(
                      pdfBytes: pdfBytes,
                      title: 'Tischverwaltung',
                    ),
                  ),
                );
              },
            ),
            // Add table button in app bar
            IconButton(
              icon: const Icon(Icons.assignment_outlined),
              tooltip: AppConstants.addTableTooltip,
              onPressed: _showAddTableDialog,
            ),
          ],
        ),
        // Add floating action button
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddTableDialog,
          child: const Icon(Icons.add),
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color.fromARGB(255, 107, 69, 106),
          child: ListView(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                child: Image.asset(
                  AppConstants.tableManagementBackground,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppConstants.tableManagementTitle,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              _tables.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          AppConstants.noTablesAvailable,
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
                      itemCount: _tables.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return TableCardWidget(
                          table: _tables[index],
                          assignedGuests:
                              _tableGuestsMap[_tables[index].id] ?? [],
                          confirmedGuestCount:
                              _tableGuestsMap[_tables[index].id]
                                      ?.where((g) => g['takePart'] == true)
                                      .length ??
                                  0,
                          onEdit: () => _navigateToAddEditTable(_tables[index]),
                          onDelete: () =>
                              _showDeleteConfirmation(_tables[index].id),
                          onAssignGuest: (_tableGuestsMap[_tables[index].id]
                                          ?.where((g) => g['takePart'] == true)
                                          .length ??
                                      0) <
                                  _tables[index].maxGuests
                              ? () => _showAssignGuestDialog(_tables[index])
                              : null,
                          onRemoveGuest: (guestId) async {
                            await _tableService.removeGuestFromTable(
                                _tables[index].id, guestId);
                            _loadData();
                          },
                        );
                      },
                    ),
              FourSecretsDivider(),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 45),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onCancel() {
    Navigator.of(context).pop();
  }

  Future<void> _downloadPdf() async {
    try {
      print('🔵 ===== TABLE MANAGEMENT DOWNLOAD STARTED =====');
      print('🔵 Tables count: ${_tables.length}');

      print('🔵 Generating PDF bytes...');
      final pdfBytes =
          await generateTableManagementPdf(_tables, _tableGuestsMap);
      print('🔵 PDF bytes generated: ${pdfBytes.length} bytes');

      final filename =
          NativeDownloadService.generateTimestampedFilename('Tischverwaltung');
      print('🔵 Generated filename: $filename');

      // Use native download service
      print('🔵 Calling native download service...');
      final result = await NativeDownloadService.downloadPdf(
        context: context,
        pdfBytes: pdfBytes,
        filename: filename,
        successMessage: 'Tischverwaltung PDF erfolgreich heruntergeladen',
      );

      print('🔵 Download result: $result');
    } catch (e) {
      print('🔴 Error in _downloadPdf: $e');
      print('🔴 Stack trace: ${StackTrace.current}');
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
            context, 'Fehler beim Herunterladen: $e');
      }
    }
  }
}
