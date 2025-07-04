// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';

class FourSecretsDivider extends StatelessWidget {
  
  const FourSecretsDivider({super.key, });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 25),
        ),
        Expanded(
          child: Divider(
            indent: 20,
            endIndent: 15,
            color: Colors.grey[500],
          ),
        ),
        Container(
          width: 30,
          child: Image.asset('assets/images/divider/wedding_rings.png'),
        ),
        Expanded(
          child: Divider(
            indent: 15,
            endIndent: 20,
            color: Colors.grey[500],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 25),
        ),
      ],
    );
  }
}
