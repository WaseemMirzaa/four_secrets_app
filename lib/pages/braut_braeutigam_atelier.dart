import 'package:four_secrets_wedding_app/data/braut_braeutigam_card_items.dart';
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/menue.dart';

class BrautBraeutigam extends StatelessWidget {
  BrautBraeutigam({super.key});
  final List items = BrautBraeutigamCardItems.getCardItems();
  final key = GlobalKey<MenueState>();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue.getInstance(key!),
        appBar: AppBar(
          foregroundColor: const Color.fromARGB(255, 255, 255, 255),
          title: const Text('Braut Atelier'),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        ),
        body: Container(
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              opacity: 0.4,
              image: AssetImage(
                  "assets/images/background/braut_und_braeutigam_back.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: ListView(
            physics: const ClampingScrollPhysics(),
            children: [
              ListView.builder(
                primary: false, // disable scrolling
                shrinkWrap: true, // limit height
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return items[index];
                },
              ),
              SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
