import 'package:four_secrets_wedding_app/data/papeterie_card_items.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:flutter/material.dart';

class Papeterie extends StatelessWidget {
  Papeterie({super.key});

  final List items = PapeterieCardItems.getCardItems();
  final Key key = GlobalKey<MenueState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue.getInstance(key),
        appBar: AppBar(
          // automaticallyImplyLeading: false,
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          title: const Text('Papeterie'),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        ),
        body: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              opacity: 0.4,
              image: AssetImage("assets/images/background/papeterie_back.jpg"),
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
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
