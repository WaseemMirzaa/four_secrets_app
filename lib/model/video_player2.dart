import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

// ignore: must_be_immutable
class VideoPlayer2 extends StatefulWidget {
  VideoPlayer2({super.key});
  String uri = "";
  String asset = "";

  @override
  State<VideoPlayer2> createState() => _VideoPlayer2State();
}

class _VideoPlayer2State extends State<VideoPlayer2> {
  late FlickManager flickManager;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Zugriff auf die übergebenen Argumente
    final Map<String, dynamic>? arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Überprüfen Sie, ob die Argumente nicht null sind und die erwarteten Daten vorhanden sind
    if (arguments != null &&
        arguments.containsKey('uri') &&
        arguments.containsKey('asset') &&
        arguments.containsKey('ratio')) {
      widget.uri = arguments['uri'] ?? '';
      widget.asset = arguments['asset'] ?? '';
      // String ratio = arguments['ratio'] ?? '';
      // double finalRatio = ratio.isNotEmpty ? double.parse(ratio) : 0;
      _initializeVideoPlayer(uri: widget.uri, asset: widget.asset);
    }
  }

  void _initializeVideoPlayer({required String uri, required String asset}) {
    if (widget.uri.isNotEmpty) {
      flickManager = FlickManager(
        videoPlayerController: VideoPlayerController.networkUrl(
          Uri.parse(widget.uri),
        )..initialize().then((value) {
            setState(() {});
          }),
      );
    } else if (widget.asset.isNotEmpty) {
      flickManager = FlickManager(
        videoPlayerController: VideoPlayerController.asset(widget.asset)
          ..initialize().then((values) {
            setState(() {});
          }),
      );
    }
  }

  @override
  void dispose() {
    flickManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[300],
        appBar: AppBar(
          title: Text(
            "Zurück",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          toolbarHeight: 60,
          foregroundColor: Colors.white,
          backgroundColor: Color.fromARGB(255, 107, 69, 106),
        ),
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: FlickVideoPlayer(
            flickManager: flickManager,
            wakelockEnabled: false,
            flickVideoWithControls: const FlickVideoWithControls(
              controls: const FlickPortraitControls(
                iconSize: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
