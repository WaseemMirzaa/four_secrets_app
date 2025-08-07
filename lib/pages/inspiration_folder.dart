import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/config/theme/app_theme.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/model/checklist_button.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/services/inspiration_image_service.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:staggered_grid_view/flutter_staggered_grid_view.dart';

class InspirationFolder extends StatefulWidget {
  const InspirationFolder({super.key});

  @override
  State<InspirationFolder> createState() => _InspirationFolderState();
}

class _InspirationFolderState extends State<InspirationFolder> {
  InspirationImageService sp = InspirationImageService();

  final key = GlobalKey<MenueState>();
  bool _isLoading = false;
  bool isLoading = false;
  final _controller = TextEditingController();
  File? imageFile;

  @override
  void initState() {
    super.initState();
    loadDataFromFirebase();
    print("init func");
  }

  loadDataFromFirebase() async {
    setState(() => _isLoading = true);
    await sp.loadDataToDo();
    setState(() => _isLoading = false);
  }

  void createNewTask() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              contentPadding: EdgeInsets.zero,
              content: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: StatefulBuilder(builder: (_, stateDialog) {
                    return Container(
                      color: Colors.grey.shade100,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Textfield for adding new items

                            SizedBox(
                                height: 260,
                                width: double.maxFinite,
                                child: imageFile != null
                                    ? Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            child: Image.file(
                                              imageFile!,
                                              fit: BoxFit.cover,
                                            )),
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: InkWell(
                                          onTap: () async {
                                            final ImagePicker picker =
                                                ImagePicker();
                                            final XFile? image =
                                                await picker.pickImage(
                                                    source:
                                                        ImageSource.gallery);

                                            if (image != null) {
                                              stateDialog(() {
                                                imageFile = File(image.path);
                                              });
                                            }

                                            if (imageFile == null) {
                                              stateDialog(
                                                  () => _isLoading = false);
                                              return;
                                            }
                                          },
                                          child: DottedBorder(
                                            radius: Radius.circular(15),
                                            dashPattern: [8, 4],
                                            color: Color.fromARGB(
                                                255, 107, 69, 106),
                                            strokeWidth: 1.5,
                                            borderType: BorderType.RRect,
                                            child: Container(
                                              height: 260,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                  color: Color.fromARGB(
                                                          255, 107, 69, 106)
                                                      .withValues(alpha: 0.3),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15)),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                      Icons
                                                          .cloud_upload_outlined,
                                                      size: 48,
                                                      color: AppTheme
                                                          .primaryColor),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    AppConstants
                                                        .inspirationImageSelectText,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppTheme.primaryColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      )),
                            SpacerWidget(height: 2),
                            if (imageFile != null)
                              MyButton(
                                  onPressed: () async {
                                    final ImagePicker picker = ImagePicker();
                                    final XFile? image = await picker.pickImage(
                                        source: ImageSource.gallery);

                                    if (image != null) {
                                      stateDialog(() {
                                        imageFile = File(image.path);
                                      });
                                    }

                                    if (imageFile == null) {
                                      stateDialog(() => _isLoading = false);
                                      return;
                                    }
                                  },
                                  text: AppConstants
                                      .inspirationFolderPageImageUpdate),

                            SpacerWidget(height: 3),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 15),
                              child: TextField(
                                controller: _controller,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  hintText:
                                      "${AppConstants.inspirationFolderPageImageTitle} eingeben",
                                  fillColor: Color.fromARGB(255, 255, 255, 255),
                                ),
                              ),
                            ),
                            // Buttons row
                            SpacerWidget(height: 2),

                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                      child: CustomButtonWidget(
                                    text:
                                        '${AppConstants.inspirationFolderPageCancelButton}',
                                    color: Colors.white,
                                    onPressed: () {
                                      _controller.clear();
                                      imageFile = null;
                                      Navigator.of(context).pop();
                                    },
                                  )),
                                  // save button

                                  const SizedBox(
                                    width: 35,
                                  ),
                                  // cancel button

                                  Expanded(
                                    child: CustomButtonWidget(
                                        text: AppConstants
                                            .inspirationFolderPageSave,
                                        isLoading: _isLoading,
                                        textColor: Colors.white,
                                        onPressed: () async {
                                          stateDialog(() => _isLoading = true);

                                          if (_controller.text.isEmpty ||
                                              imageFile == null) {
                                            stateDialog(
                                                () => _isLoading = false);
                                            if (_controller.text.isEmpty) {
                                              SnackBarHelper.showErrorSnackBar(
                                                  context,
                                                  AppConstants
                                                      .inspirationFolderPageImageTitleError);
                                            } else if (imageFile == null) {
                                              SnackBarHelper.showErrorSnackBar(
                                                  context,
                                                  AppConstants
                                                      .inspirationFolderPageImageSelectError);
                                            } else {
                                              SnackBarHelper.showErrorSnackBar(
                                                  context,
                                                  AppConstants
                                                      .inspirationFolderPageImageSelectError2);
                                            }
                                            return;
                                          }

                                          // Add task to Firebase
                                          await sp.addImageToDB(
                                              _controller.text, imageFile!);
                                          Navigator.of(context).pop();
                                          loadDataFromFirebase();
                                          _controller.clear();
                                          imageFile = null;
                                          stateDialog(() => _isLoading = false);
                                        }),
                                  ),
                                ],
                              ),
                            ),
                            SpacerWidget(height: 4),
                          ],
                        ),
                      ),
                    );
                  })));
        });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        drawer: Menue.getInstance(key),
        appBar: AppBar(
          foregroundColor: Colors.white,
          title: const Text(AppConstants.inspirationFolderPageTitle),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: createNewTask,
          child: const Icon(Icons.add),
        ),
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => loadDataFromFirebase(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Image.asset("assets/images/background/inspiration.png"),
                        SpacerWidget(height: 5),
                        FourSecretsDivider(),
                        SpacerWidget(height: 5),
                      ],
                    ),
                  ),
                  _isLoading
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : sp.inspirationImagesList.isEmpty
                          ? SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: CustomTextWidget(
                                    textAlign: TextAlign.center,
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                    text:
                                        "Noch Keine Bilder hinzugefügt. Tippe auf das + Symbol unten rechts."),
                              ),
                            )
                          : SliverPadding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 15),
                              sliver: SliverStaggeredGrid.countBuilder(
                                crossAxisCount: 2,
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                                itemCount: sp.inspirationImagesList.length,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () async {
                                      var result = Navigator.of(context)
                                          .pushNamed(
                                              RouteManager
                                                  .inspirationDetailPage,
                                              arguments: {
                                            'inspirationImage':
                                                sp.inspirationImagesList[index],
                                            'id': sp
                                                .inspirationImagesList[index]
                                                .id!,
                                          });

                                      print(
                                          "Returned value: $result"); // <-- You should see this when popped

                                      result.then((v) {
                                        loadDataFromFirebase();
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: _isLoading
                                            ? Center(
                                                child: CircularProgressIndicator
                                                    .adaptive(
                                                  backgroundColor:
                                                      AppTheme.backgroundColor,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                              Color>(
                                                          AppTheme
                                                              .primaryColor),
                                                ),
                                              )
                                            : Image.network(
                                                sp.inspirationImagesList[index]
                                                    .imageUrl,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }
                                                  return Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      value: loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              (loadingProgress
                                                                      .expectedTotalBytes ??
                                                                  1)
                                                          : null,
                                                      color: AppTheme
                                                          .backgroundColor,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                                  Color>(
                                                              AppTheme
                                                                  .primaryColor),
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Center(
                                                    child: Text(
                                                      "Fehler beim Laden",
                                                      style: TextStyle(
                                                          color: Colors.red),
                                                    ),
                                                  );
                                                },
                                                cacheWidth: 300,
                                                cacheHeight: 300,
                                              ),
                                      ),
                                    ),
                                  );
                                },
                                staggeredTileBuilder: (index) =>
                                    StaggeredTile.extent(
                                  1,
                                  index % 2 == 0 ? 150 : 250,
                                ),
                              ),
                            ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 20,
                    ),
                  ),
                  if (sp.inspirationImagesList.isNotEmpty)
                    SliverToBoxAdapter(
                      child: FourSecretsDivider(),
                    ),
                  SliverToBoxAdapter(
                    child: SpacerWidget(
                      height: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
