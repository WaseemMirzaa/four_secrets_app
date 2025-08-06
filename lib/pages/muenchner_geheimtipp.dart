import 'package:four_secrets_wedding_app/data/muenchner_geheimtipp_content.dart';
import 'package:four_secrets_wedding_app/data/muenchner_geheimtipp_images.dart';
import 'package:four_secrets_wedding_app/data/muenchner_geheimtipp_routes.dart';
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/menue.dart';

class MuenchnerGeheimtipp extends StatelessWidget {
  MuenchnerGeheimtipp({super.key});
  final List<String> images = MuenchnerGeheimtippImages.getImages();
  final List<String> content = MuenchnerGeheimtippContent.getContent();
  final List routes = MuenchnerGeheimtippRoutes.getRoutes();
  final Key key = GlobalKey<MenueState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue.getInstance(key),
        appBar: AppBar(
          // automaticallyImplyLeading: false,
          title: const Text('Münchner Geheimtipp'),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
        ),
        body: Padding(
          padding: const EdgeInsets.all(15.0),
          child: GridView.builder(
            itemCount: images.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  Navigator.of(context).pushNamed(routes[index]);
                },
                splashColor: Colors.blueGrey.shade400,
                borderRadius: BorderRadius.circular(12.5),
                highlightColor: Colors.blueGrey.shade400,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.5),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(12.5), // Radius-Wert
                        child: Opacity(
                          opacity: 0.5,
                          child: Image.asset(
                            images[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            content[index],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              // Größe und andere Stile anpassen
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
