import 'package:flutter/material.dart';

class AddGuestBg extends StatelessWidget {
  final Widget child;

  const AddGuestBg({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color.fromARGB(255, 107, 69, 106);

    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/gaestelist/gaesteliste.png'),
          fit: BoxFit.fitWidth, // Changed from cover to contain
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.79),
        ),
        child: child,
      ),
    );
  }
}
