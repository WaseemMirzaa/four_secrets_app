import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/menue.dart';

class WeddingCarService extends StatefulWidget {
  const WeddingCarService({super.key});

  @override
  State<WeddingCarService> createState() => _WeddingCarServiceState();
}

class _WeddingCarServiceState extends State<WeddingCarService> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue.getInstance(),
        appBar: AppBar(
          // automaticallyImplyLeading: false,
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          title: const Text('Wedding Car-Service'),
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
