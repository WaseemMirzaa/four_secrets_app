import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/menue.dart';

class BrautBraeutigam extends StatefulWidget {
  const BrautBraeutigam({super.key});

  @override
  State<BrautBraeutigam> createState() => _BrautBraeutigamState();
}

class _BrautBraeutigamState extends State<BrautBraeutigam> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: const Menue(),
        appBar: AppBar(
          // automaticallyImplyLeading: false,
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          title: const Text('Braut & Braeutigam Atelier'),
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
