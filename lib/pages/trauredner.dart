import 'package:four_secrets_wedding_app/data/trauredner_cart_items.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:flutter/material.dart';

class Trauredner extends StatelessWidget {
  Trauredner({super.key});

  final List items = TraurednerCardItems.getCardItems();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue.getInstance(key),
        appBar: AppBar(
          // automaticallyImplyLeading: false,
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          title: const Text('Trauredner'),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        ),
        body: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              opacity: 0.4,
              image: AssetImage("assets/images/inspirations/Trauredner.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: ListView(
            physics: ClampingScrollPhysics(),
            children: [
              ListView.builder(
                primary: false, // disable scrolling
                shrinkWrap: true, // limit height
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return items[index];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
