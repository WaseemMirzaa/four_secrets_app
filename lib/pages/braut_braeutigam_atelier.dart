import 'package:DreamWedding/data/braut_braeutigam_card_items.dart';
import 'package:flutter/material.dart';
import 'package:DreamWedding/menue.dart';

class BrautBraeutigam extends StatelessWidget {
  BrautBraeutigam({super.key});
  final List items = BrautBraeutigamCardItems.getCardItems();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: const Menue(),
        appBar: AppBar(
          // automaticallyImplyLeading: false,
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          title: const Text('Braut Atelier'),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        ),
        body: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              opacity: 0.4,
              image: AssetImage(
                  "assets/images/background/braut_und_braeutigam_back.jpg"),
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
