import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Future<double> get _height => Future<double>.value(200);
  AnimationController? _controller;
  final int timeInSeconds = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: timeInSeconds, milliseconds: 200),
      vsync: this,
    );

    _controller?.addListener(() {
      if (_controller?.status == AnimationStatus.completed) {
        // Animation ist abgeschlossen => Nachfolgend Aktion ausführen!
        Timer(const Duration(seconds: 2), () {
          _checkAuthAndNavigate();
        });
      }
    });
    _controller?.forward(); // Starten Sie die Animation.
  }

  Future<void> _checkAuthAndNavigate() async {
    // await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;

    if (user != null) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FutureBuilder<double>(
              future: _height,
              initialData: 0.0,
              builder: (context, snapshot) {
                return AnimatedContainer(
                  duration: Duration(seconds: timeInSeconds),
                  height: snapshot.data,
                  child: Image.asset(
                    'assets/icons/secrets-icon.png',
                    fit: BoxFit.contain, // Changed to contain
                  ),
                );
              },
            ),
            // Larger logo with border radius

            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
