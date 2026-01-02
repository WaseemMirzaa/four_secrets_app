import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayer2 extends StatefulWidget {
  final String uri;

  const VideoPlayer2({super.key, required this.uri});

  @override
  State<VideoPlayer2> createState() => _VideoPlayer2State();
}

class _VideoPlayer2State extends State<VideoPlayer2> {
  late final Player _player;
  late final VideoController _controller;

  @override
  void initState() {
    super.initState();

    _player = Player();
    _controller = VideoController(_player);

    _player.open(Media(widget.uri));
    _player.play();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Zurück"),
          backgroundColor: Color.fromARGB(255, 107, 69, 106),
          foregroundColor: Colors.white,
        ),
        backgroundColor: Colors.black,
        body: Padding(
          padding: EdgeInsets.only(
            bottom: Platform.isAndroid
                ? MediaQuery.of(context).viewPadding.bottom + 10.0
                : 5,
          ),
          child: Video(controller: _controller, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
