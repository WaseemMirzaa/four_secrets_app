import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/config/theme/app_theme.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/model/checklist_button.dart';
import 'package:four_secrets_wedding_app/models/inspiration_image.dart';
import 'package:four_secrets_wedding_app/services/image_upload_service.dart';
import 'package:four_secrets_wedding_app/services/inspiration_image_service.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
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
        body: Container(
          height: context.screenHeight,
          width: context.screenWidth,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(widget.inspirationImage.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              // Top blurred app bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 70,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      width: context.screenWidth,
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        color: Colors.black.withValues(alpha: 0.2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, size: 30),
                            color: Colors.white,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Text(
                            "Inspiration Details",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          PopupMenuButton(
                            color: Colors.white,
                            iconColor: Colors.white,
                            iconSize: 30,
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(FontAwesomeIcons.penToSquare, size: 16, color: Colors.black),
                                    SizedBox(width: 8),
                                    Text("Bearbeiten", style: TextStyle(color: Colors.black)),
                                  ],
                                ),
                                onTap: () => _showEditDialog(),
                              ),
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(FontAwesomeIcons.trash, size: 16, color: Colors.black),
                                    SizedBox(width: 8),
                                    Text("Löschen", style: TextStyle(color: Colors.black)),
                                  ],
                                ),
                                onTap: () {
                                  showDialog(context: context, builder: (_){
                                    return AlertDialog(
                                      title: Text("Löschen"),
                                      content: Text("Möchten Sie dieses Bild wirklich löschen?"),
                                      actions: [
                                        Row(
                                          spacing: 10,
                                          children: [
                                            Expanded(child: CustomButtonWidget(text: "Abbrechen", color: Colors.white, onPressed: () => Navigator.of(context).pop(),)),
                                            Expanded(
                                              child: CustomButtonWidget(text: "Löschen", 
                                              color: Colors.red.withValues(alpha: 0.8),
                                              textColor: Colors.white, 
                                              onPressed: () async {
                                                await inspirationImageService.deleteImage(widget.inspirationImage.id!, widget.inspirationImage.imageUrl);
                                                Navigator.of(context).pop();
                                                Navigator.of(context).pop();
                                              },),
                                            ),
                                          ],
                                        ),
                                        
                                      ],
                                    );
                                  });
                                  // delete logic, if needed
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom title overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      height: context.screenHeight * 0.2,
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      width: context.screenWidth,
                      alignment: Alignment.topCenter,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        color: Colors.black.withValues(alpha: 0.2),
                      ),
                      child: Text(
                        widget.inspirationImage.title,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
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
          title:  ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
                child: SizedBox(
                  height: 260,
                  width: double.maxFinite,
                  child: imageFile != null
                      ? Image.file(imageFile!, fit: BoxFit.cover)
                      : Image.network(widget.inspirationImage.imageUrl, fit: BoxFit.cover),
                ),
              ),
              titlePadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
             
              SpacerWidget(height: 6),

              CustomButtonWidget(text: "Bild auswählen", color: Colors.white, onPressed: () async {
                final picker = ImagePicker();
                final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  stateDialog(() => imageFile = File(picked.path));
                }
              },),
              
              SpacerWidget(height: 6),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  hintText: "Bildtitel eingeben",
                ),
              ),
              SpacerWidget(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                      Expanded(
                        child: CustomButtonWidget(
                          
                          text: "Speichern", isLoading: isLoading, textColor: Colors.white, onPressed: () async {
                              stateDialog(() => isLoading = true);
                              if (_controller.text.isEmpty) {
                                SnackBarHelper.showErrorSnackBar(context, "Bitte Titel eingeben");
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
                                SnackBarHelper.showErrorSnackBar(context, "Update fehlgeschlagen");
                                stateDialog(() => isLoading = false);
                              }
                            },
                            ),
                      ),
                                 
                  SizedBox(width: 24),
                  Expanded(child: CustomButtonWidget(text: "Abbrechen", color: Colors.white, onPressed: () => Navigator.of(context).pop(),)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
