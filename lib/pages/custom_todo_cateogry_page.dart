import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';

class CustomTodoCategoryPage extends StatefulWidget {
  const CustomTodoCategoryPage({super.key});

  @override
  State<CustomTodoCategoryPage> createState() => _CustomTodoCategoryPageState();
}

class _CustomTodoCategoryPageState extends State<CustomTodoCategoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Color.fromARGB(255, 255, 255, 255),
        title: CustomTextWidget(
          text: "Eigene To-Do Kategorie",
          fontSize: 20,
          color: Colors.white,
        ),
        backgroundColor: const Color.fromARGB(255, 107, 69, 106),
      ),
      body: Column(
        children: [
          CustomTextWidget(
            text: "Eigene To-Do Kategorie",
            fontSize: 20,
            color: Colors.black,
          ),
        ],
      ),
    );
  }
}
