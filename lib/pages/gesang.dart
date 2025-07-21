import 'package:four_secrets_wedding_app/data/gesang_card_items.dart';
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/menue.dart';

class Gesang extends StatelessWidget {
  Gesang({super.key});
  final List items = GesangCardItems.getCardItems();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: const Menue(),
        appBar: AppBar(
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          // automaticallyImplyLeading: false,
          title: const Text('Gesang'),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        ),
        body: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              opacity: 0.4,
              image: AssetImage(
                  "assets/images/background/wedding_design_back.jpg"),
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
