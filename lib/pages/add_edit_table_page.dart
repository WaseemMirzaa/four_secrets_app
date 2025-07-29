import 'package:flutter/material.dart';
import '../models/table_model.dart';
import '../services/table_service.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/custom_text_field.dart';

class AddEditTablePage extends StatefulWidget {
  final TableModel? table;

  const AddEditTablePage({Key? key, this.table}) : super(key: key);

  @override
  State<AddEditTablePage> createState() => _AddEditTablePageState();
}

class _AddEditTablePageState extends State<AddEditTablePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameOrNumberController = TextEditingController();
  final _maxGuestsController = TextEditingController();
  final _tableTypeController = TextEditingController();
  final _tableService = TableService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.table != null) {
      _nameOrNumberController.text = widget.table!.nameOrNumber;
      _maxGuestsController.text = widget.table!.maxGuests.toString();
      _tableTypeController.text = widget.table!.tableType;
    }
  }

  Future<void> _saveTable() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final TableModel newTable = TableModel(
        id: widget.table?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        nameOrNumber: _nameOrNumberController.text.trim(),
        tableType: _tableTypeController.text.trim(),
        maxGuests: int.parse(_maxGuestsController.text.trim()),
        assignedGuestIds: widget.table?.assignedGuestIds ?? [],
      );

      if (widget.table == null) {
        await _tableService.addTable(newTable);
      } else {
        await _tableService.updateTable(newTable);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showErrorSnackBar(
            context, 'Dishes konnte nicht gespeichert werden: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        elevation: 0,
        title: Text(
          widget.table == null ? 'Neue Dishes hinzufügen' : 'Dishes bearbeiten',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _nameOrNumberController,
                    label: 'Dishesnname',
                    hint: 'Geben Sie den Tischnamen oder die Tischnummer ein',
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _maxGuestsController,
                    label: 'Max. Gäste',
                    hint: 'Geben Sie die maximale Anzahl an Gästen ein',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter max. gäste';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Bitte geben Sie eine gültige Nummer ein';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _tableTypeController,
                    label: 'Dishesntyp',
                    hint: 'Geben Sie den Tischtyp ein (z. B. "Normal", "VIP")',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveTable,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 107, 69, 106),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              widget.table == null
                                  ? 'Dishes hinzufügen'
                                  : 'Dishes aktualisieren',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameOrNumberController.dispose();
    _maxGuestsController.dispose();
    _tableTypeController.dispose();
    super.dispose();
  }
}
