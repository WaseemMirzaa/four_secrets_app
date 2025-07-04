import 'package:four_secrets_wedding_app/data/wedding_designer_card_items.dart';
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/menue.dart';

class WeddingDesigner extends StatelessWidget {
  WeddingDesigner({super.key});
  final List items = WeddingDesignerCardItems.getCardItems();


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue(),
        appBar: AppBar(
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          // automaticallyImplyLeading: false,
          title: const Text('Wedding Designer'),
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
