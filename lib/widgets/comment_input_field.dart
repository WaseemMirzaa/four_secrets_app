import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../services/collaboration_todo_service.dart';
import '../utils/snackbar_helper.dart';

class CommentInputField extends StatefulWidget {
  final String collabId;
  final String label;
  final IconData sendIcon;
  final Color loadingColor;
  final Future<void> Function(String value)? onSend;
  final TextEditingController? controller;
  final bool editMode;
  final Future<void> Function(String value)? onEdit;
  final VoidCallback? onCancel;

  const CommentInputField({
    Key? key,
    required this.collabId,
    this.label = 'Kommentar hinzufügen...',
    this.sendIcon = Icons.send,
    this.loadingColor = Colors.purple,
    this.onSend,
    this.controller,
    this.editMode = false,
    this.onEdit,
    this.onCancel,
  }) : super(key: key);

  @override
  State<CommentInputField> createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<CommentInputField> {
  TextEditingController? _internalController;
  TextEditingController get _controller =>
      widget.controller ?? _internalController!;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = TextEditingController();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomTextField(
            controller: _controller,
            label: widget.label,
            inputDecoration: InputDecoration(
              fillColor: Colors.white,
              filled: true,
              hintText: widget.label,
              hintStyle: TextStyle(color: Colors.black, fontSize: 12),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onSubmit: (value) async {
              await _handleSendOrEdit();
            },
          ),
        ),
        SizedBox(width: 8),
        IconButton(
          icon: _isSending
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: widget.loadingColor))
              : Icon(widget.sendIcon, color: widget.loadingColor),
          onPressed: _isSending ? null : _handleSendOrEdit,
        ),
        if (widget.editMode)
          IconButton(
            icon: Icon(Icons.close, color: Colors.red),
            onPressed: () {
              _controller.clear();
              if (widget.onCancel != null) widget.onCancel!();
            },
          ),
      ],
    );
  }

  Future<void> _handleSendOrEdit() async {
    final value = _controller.text.trim();
    if (value.isNotEmpty) {
      setState(() => _isSending = true);
      try {
        if (widget.editMode && widget.onEdit != null) {
          await widget.onEdit!(value);
        } else if (widget.onSend != null) {
          await widget.onSend!(value);
        } else {
          final service = CollaborationTodoService();
          await service.addComment(widget.collabId, value);
        }
        _controller.clear();
      } catch (e) {
        if (context.mounted) {
          SnackBarHelper.showErrorSnackBar(
              context, "Fehler beim Senden des Kommentars: $e");
        }
      } finally {
        setState(() => _isSending = false);
      }
    }
  }
}
