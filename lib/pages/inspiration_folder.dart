import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/config/theme/app_theme.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/model/checklist_button.dart';
import 'package:four_secrets_wedding_app/model/dialog_box.dart';
import 'package:four_secrets_wedding_app/services/inspiration_image_service.dart';
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
    sp.loadDataToDo();
  }

    List<String> lsitImage = [
      'assets/images/inspirations/Band_DJ.jpg',
      'assets/images/inspirations/Braut_Braeutigam_Atelier.jpg',
      'assets/images/inspirations/Cake.jpg',
      'assets/images/inspirations/Fahrzeugservice.jpg',
      'assets/images/inspirations/Florist_Floristin.jpg',
      'assets/images/inspirations/Fotograf_Fotografin.jpg',
      'assets/images/inspirations/Tanzschule.jpg',
      'assets/images/inspirations/Kosmetische_Akupunktur.jpg',
      'assets/images/inspirations/Personal_Training.jpg',
      'assets/images/inspirations/Wedding_Designer.jpg',
    ];



  selectImage()async{
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        imageFile = File(image.path);
      });
    }

      if (imageFile == null) {
      setState(() => _isLoading = false);
      return;
    }
  }


    void saveNewTask() async {
   
    setState(() => _isLoading = true);

  
     
    // Add task to Firebase
    await sp.createInitialDataToDo(_controller.text, imageFile!);
    _controller.clear();
    
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
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          color: Colors.grey.shade100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Textfield for adding new items

              SizedBox(
                height: 200,
                width: double.maxFinite,
                child:  imageFile != null
                                    ?  Image.file(imageFile!, fit: BoxFit.cover,)
                                      
                                    : Image.asset("assets/images/background/noimage.png", fit: BoxFit.fill,),
              ),
                SpacerWidget(height: 6),


                    MyButton(onPressed: selectImage,   text: "Bild auswählen"),

                SpacerWidget(height: 3),
              TextField(
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
              // Buttons row
                SpacerWidget(height: 6),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // save button
                  isLoading
                      ? Container(
                          width: 100,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 107, 69, 106),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                        )
                      : MyButton(onPressed: saveNewTask, text: "Speichern"),
                  const SizedBox(
                    width: 35,
                  ),
                  // cancel button
                  MyButton(
                    onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                    text: "Stornieren",
                    color: isLoading ? Colors.grey : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // If you have other widgets above the grid, they go here,
                  // otherwise you can remove this Column and Expanded.
                  Expanded(
                    child: StaggeredGridView.countBuilder(
                      crossAxisCount: 2,
                      itemCount: lsitImage.length,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      //oldimageurl
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              lsitImage[index],
                              fit: BoxFit.cover,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
