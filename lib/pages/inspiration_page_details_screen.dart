import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/config/theme/app_theme.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/models/inspiration_image.dart';
import 'package:four_secrets_wedding_app/services/inspiration_image_service.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
import 'package:four_secrets_wedding_app/widgets/custom_dialog.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import 'package:image_picker/image_picker.dart';

class InspirationDetailPage extends StatefulWidget {
  final InspirationImageModel inspirationImage;

  const InspirationDetailPage({
    Key? key,
    required this.inspirationImage,
  }) : super(key: key);

  @override
  State<InspirationDetailPage> createState() => _InspirationDetailPageState();
}

class _InspirationDetailPageState extends State<InspirationDetailPage> {
  InspirationImageService sp = InspirationImageService();

  bool isLoading = false;
  InspirationImageService inspirationImageService = InspirationImageService();
  final _controller = TextEditingController();
  File? imageFile;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.inspirationImage.title;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, size: 20),
            color: Colors.white,
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            AppConstants.inspirationFolderPageTitle,
          ),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
          actions: [
            PopupMenuButton(
              color: Colors.white,
              iconColor: Colors.white,
              iconSize: 30,
              itemBuilder: (_) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(FontAwesomeIcons.penToSquare,
                          size: 16, color: Colors.black),
                      SizedBox(width: 8),
                      Text("Bearbeiten", style: TextStyle(color: Colors.black)),
                    ],
                  ),
                  onTap: () => _showEditDialog(),
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(FontAwesomeIcons.trash, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Löschen", style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (_) {
                          return StatefulBuilder(builder: (context, statee) {
                            return CustomDialog(
                                isLoading: isLoading,
                                title: "Löschen",
                                message:
                                    "Möchten Sie dieses Bild wirklich löschen?",
                                confirmText: "Löschen",
                                cancelText: "Abbrechen",
                                onConfirm: () async {
                                  statee(() {
                                    isLoading = true;
                                  });
                                  await inspirationImageService.deleteImage(
                                      widget.inspirationImage.id!,
                                      widget.inspirationImage.imageUrl);
                                  // Navigator.of(context).pop();
                                  Navigator.of(context).pop(
                                      inspirationImageService.loadDataToDo());
                                  statee(() {
                                    isLoading = false;
                                  });
                                  Navigator.of(context).pop(true);
                                },
                                onCancel: () => Navigator.of(context).pop());
                          });
                        });
                    // delete logic, if needed
                  },
                ),
              ],
            ),
          ],
        ),
        body: Container(
          height: context.screenHeight,
          width: context.screenWidth,
          child: Column(
            children: [
              SizedBox(
                height: context.screenHeight * 0.5 + 50,
                width: context.screenWidth,
                child: Image.network(
                  widget.inspirationImage.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Transform.translate(
                  offset: Offset(0, -15),
                  child: Container(
                    height: context.screenHeight,
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 25),
                    width: context.screenWidth,
                    alignment: Alignment.topLeft,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      color: Colors.white,
                    ),
                    child: Column(
                      spacing: 10,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Keine Beschreibung verfügbar.",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        Text(
                          widget.inspirationImage.title,
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, stateDialog) => AlertDialog(
          backgroundColor: Colors.white,
          title: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 260,
                width: double.maxFinite,
                child: imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.file(imageFile!, fit: BoxFit.cover))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.network(widget.inspirationImage.imageUrl,
                            fit: BoxFit.cover)),
              ),
            ),
          ),
          titlePadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpacerWidget(height: 6),
              CustomButtonWidget(
                text: "Bild auswählen",
                color: Colors.white,
                onPressed: () async {
                  final picker = ImagePicker();
                  final XFile? picked =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    stateDialog(() => imageFile = File(picked.path));
                  }
                },
              ),
              SpacerWidget(height: 6),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  hintText: "Bildtitel eingeben",
                ),
              ),
              SpacerWidget(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                      child: CustomButtonWidget(
                    text: "Abbrechen",
                    color: Colors.white,
                    onPressed: () => Navigator.of(context).pop(),
                  )),
                  SizedBox(width: 24),
                  Expanded(
                    child: CustomButtonWidget(
                      text: "Speichern",
                      isLoading: isLoading,
                      textColor: Colors.white,
                      onPressed: () async {
                        stateDialog(() => isLoading = true);
                        if (_controller.text.isEmpty) {
                          SnackBarHelper.showErrorSnackBar(
                              context, "Bitte Titel eingeben");
                          stateDialog(() => isLoading = false);
                          return;
                        }
                        try {
                          await inspirationImageService.updateById(
                            id: widget.inspirationImage.id!,
                            currentImageUrl: widget.inspirationImage.imageUrl,
                            newTitle: _controller.text,
                            imageFile: imageFile,
                          );

                          Navigator.of(context).pop();
                          Navigator.of(context).pop(sp.loadDataToDo());
                        } catch (e) {
                          SnackBarHelper.showErrorSnackBar(
                              context, "Update fehlgeschlagen");
                          stateDialog(() => isLoading = false);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
