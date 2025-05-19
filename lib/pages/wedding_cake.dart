import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/menue.dart';

class WeddingCake extends StatefulWidget {
  const WeddingCake({super.key});

  @override
  State<WeddingCake> createState() => _WeddingCakeState();
}

class _WeddingCakeState extends State<WeddingCake> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue.getInstance(),
        appBar: AppBar(
          // automaticallyImplyLeading: false,
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          title: const Text('Wedding Cake'),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Hier entsteht in Kürze eine weiter Seite'),
            ],
          ),
        ),
      ),
    );
  }
}
