import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/config/theme/app_theme.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/model/checklist_button.dart';
import 'package:four_secrets_wedding_app/model/dialog_box.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:four_secrets_wedding_app/services/inspiration_image_service.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
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
        child: StatefulBuilder(builder: (_, stateDialog) { return   Container(
          color: Colors.grey.shade100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Textfield for adding new items

              SizedBox(
                height: 260,
                width: double.maxFinite,
                child:  imageFile != null
                                    ?  Image.file(imageFile!, fit: BoxFit.cover,)
                                      
                                    : Image.asset("assets/images/background/noimage.png", fit: BoxFit.fill,),
              ),
                SpacerWidget(height: 2),


                    MyButton(onPressed: ()async{
                       final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      stateDialog(() {
        imageFile = File(image.path);
      });
    }

      if (imageFile == null) {
      stateDialog(() => _isLoading = false);
      return;
    }
                    },   text: "Bild auswählen"),

                SpacerWidget(height: 3),
              Padding(
                         padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),

                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    hintText: 
                       "Bildtitel eingeben",
                    fillColor: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),
              // Buttons row
                SpacerWidget(height: 2),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                
                     Expanded(
                          child: CustomButtonWidget(
                            
                            text: "Speichern", isLoading: _isLoading, textColor: Colors.white, onPressed: () async {
                          stateDialog(() => _isLoading = true);
                  
                      if(_controller.text.isEmpty || imageFile == null) {
                      stateDialog(() => _isLoading = false);
                      if (_controller.text.isEmpty) {
                        SnackBarHelper.showErrorSnackBar(context, "Bitte geben Sie einen Titel ein.");
                      } else if (imageFile == null) {
                        SnackBarHelper.showErrorSnackBar(context, "Bitte wählen Sie ein Bild aus.");
                      } else {
                        SnackBarHelper.showErrorSnackBar(context, "Bitte füllen Sie alle Felder aus.");
                      }
                      return;
                    }
                  
                    // Add task to Firebase
                    await sp.addImageToDB(_controller.text, imageFile!);
                    Navigator.of(context).pop();
                    loadDataFromFirebase();
                    _controller.clear();
                    imageFile = null;
                    stateDialog(() => _isLoading = false);
                        }
                              ),
                        ),
                    // save button
                   
                        
                    const SizedBox(
                      width: 35,
                    ),
                    // cancel button
                          Expanded(child: CustomButtonWidget(text: "Abbrechen", color: Colors.white, onPressed: () => Navigator.of(context).pop(),)),
                
                  ],
                ),
              ),
                SpacerWidget(height: 4),

            ],
          ),
        );
        }
        )
      
      )
      
    );
      }
    );
  }



  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue.getInstance(key),
        appBar: AppBar(
          foregroundColor: Colors.white,
          title: const Text('Inspirationsordner'),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: createNewTask,
          child: const Icon(Icons.add),
        ),
        body: Stack(
          children: [
            // 1) Background image
            Positioned.fill(
              child: Image.asset(
                "assets/images/background/bg.jpg",
                fit: BoxFit.cover,
              ),
            ),

            // 2) Blur layer
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.2),
                ),
              ),
            ),

            // 3) Grid content
            //    Use Padding or SafeArea if you want margins

            // sp.inspirationImagesList.isEmpty ?  

            //   Center(
            //     child: Text("Please Add Images "),
            //   )

            // :

            _isLoading ?  Center(
              child: CupertinoActivityIndicator(),
            )  :
             sp.inspirationImagesList.isEmpty ?  

              Center(
                child: Text("Bitte fügen Sie Bilder hinzu, indem Sie auf das + Symbol klicken"),
              )
            :

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // If you have other widgets above the grid, they go here,
                  // otherwise you can remove this Column and Expanded.
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => loadDataFromFirebase(),
                      child: StaggeredGridView.countBuilder(
                        crossAxisCount: 2,
                        itemCount: sp.inspirationImagesList.length,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        //oldimageurl
                        itemBuilder: (context, index) {
                          
                          return GestureDetector(
                            onTap: (){
                          Navigator.of(context).pushNamed(RouteManager.inspirationDetailPage, arguments: {
                                'inspirationImage': sp.inspirationImagesList[index],
                              
                                'id': sp.inspirationImagesList[index].id!,
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    spreadRadius: 4,
                                    blurRadius: 15,
                                    offset: const Offset(0, 0),
                                  ),
                                ]
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child:  _isLoading ? Center(
                                      child: CircularProgressIndicator.adaptive(
                                        
                                          backgroundColor: AppTheme.backgroundColor,
                                          valueColor:  AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                      ),
                                      )  : Image.network(
                                    sp.inspirationImagesList[index].imageUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) {
                                      return child;
                                      }
                                      return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                            (loadingProgress.expectedTotalBytes ?? 1)
                                          : null,
                                          color: AppTheme.backgroundColor,
                                          valueColor:  AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                      ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                      child: Text(
                                        "Fehler beim Laden",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      );
                                    },
                                    ),
                              ),
                            ),
                          );
                        },
                        staggeredTileBuilder: (index) => StaggeredTile.extent(
                          1,
                          index % 2 == 0 ? 150 : 250,
                        ),
                      ),
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
