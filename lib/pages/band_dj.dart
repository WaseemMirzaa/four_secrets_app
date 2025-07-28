import 'package:four_secrets_wedding_app/data/band_dj_card_items.dart';
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/menue.dart';

class BandDj extends StatelessWidget {
  BandDj({super.key});

  final List items = BandDjCardItems.getCardItems();


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
<<<<<<< HEAD
        drawer: Menue(),
=======
        drawer: const Menue(),
>>>>>>> merge-elena-wazeem
        appBar: AppBar(
          // automaticallyImplyLeading: false,
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          title: const Text('Band & DJ'),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        ),
        body: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              opacity: 0.4,
              image: AssetImage("assets/images/background/band_back.jpg"),
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
