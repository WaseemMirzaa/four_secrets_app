import 'package:four_secrets_wedding_app/data/inspirations_content.dart';
import 'package:four_secrets_wedding_app/data/inspirations_images.dart';
import 'package:four_secrets_wedding_app/data/inspirations_routes.dart';
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/menue.dart';

class Inspirations extends StatelessWidget {
  Inspirations({super.key});
  final List<String> images = InspirationsImages.getImages();
  final List<String> content = InspirationsContent.getContent();
  final List routes = InspirationsRoutes.getRoutes();

  final key = GlobalKey<MenueState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue(),
        appBar: AppBar(
          centerTitle: true,
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
