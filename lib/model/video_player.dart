import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  VideoPlayerWidget({super.key});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  late Future<void> _initializeVideoPlayerFuture;

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
      String uri = arguments['uri'] ?? '';
      String asset = arguments['asset'] ?? '';
      // String ratio = arguments['ratio'] ?? '';
      // double finalRatio = ratio.isNotEmpty ? double.parse(ratio) : 0;

      // Initialisieren Sie den VideoPlayerController mit den erhaltenen Daten
      _initializeVideoPlayer(uri: uri, asset: asset);
      _initializeVideoPlayerFuture = _videoPlayerController.initialize();
    }
  }

  void _initializeVideoPlayer({required String uri, required String asset}) {
    if (uri.isNotEmpty) {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(uri))
        ..initialize().then((value) {
          setState(() {});
        });
    } else if (asset.isNotEmpty) {
      _videoPlayerController = VideoPlayerController.asset(asset);
      _videoPlayerController.addListener(() {
        setState(() {});
      });
      _videoPlayerController.setLooping(true);
      _videoPlayerController.initialize().then((_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          toolbarHeight: 60,
          backgroundColor: Color.fromARGB(255, 107, 69, 106),
        ),
        body: Center(
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: FutureBuilder(
              future: _initializeVideoPlayerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  // If the VideoPlayerController has finished initialization, use
                  // the data it provides to limit the aspect ratio of the video.
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: AspectRatio(
                          aspectRatio: _videoPlayerController.value.aspectRatio,
                          // Use the VideoPlayer widget to display the video.
                          child: VideoPlayer(_videoPlayerController),
                        ),
                      ),
                      VideoProgressIndicator(
                        _videoPlayerController,
                        allowScrubbing: false,
                        padding: EdgeInsets.all(0),
                        colors: VideoProgressColors(
                          backgroundColor: Colors.white,
                          playedColor: Colors.red,
                        ),
                      ),
                      Padding(padding: EdgeInsets.all(8)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor:
                                    const Color.fromARGB(255, 107, 69, 106),
                                foregroundColor: Colors.white),
                            child: Icon(
                              FontAwesomeIcons.backward,
                              size: 22,
                            ),
                            onPressed: () {
                              setState(
                                () {
                                  _videoPlayerController.seekTo(
                                    Duration(
                                        seconds: _videoPlayerController
                                                .value.position.inSeconds -
                                            1),
                                  );
                                },
                              );
                            },
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor:
                                    const Color.fromARGB(255, 107, 69, 106),
                                foregroundColor: Colors.white),
                            child: Icon(FontAwesomeIcons.play, size: 21),
                            onPressed: () {
                              setState(() {
                                if (!_videoPlayerController.value.isPlaying) {
                                  _videoPlayerController.play();
                                }
                              });
                            },
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor:
                                    const Color.fromARGB(255, 107, 69, 106),
                                foregroundColor: Colors.white),
                            child: Icon(
                              FontAwesomeIcons.pause,
                              size: 22,
                            ),
                            onPressed: () {
                              setState(() {
                                if (_videoPlayerController.value.isPlaying) {
                                  _videoPlayerController.pause();
                                }
                              });
                            },
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor:
                                    const Color.fromARGB(255, 107, 69, 106),
                                foregroundColor: Colors.white),
                            child: Icon(
                              FontAwesomeIcons.forward,
                              size: 22,
                            ),
                            onPressed: () {
                              setState(
                                () {
                                  _videoPlayerController.seekTo(
                                    Duration(
                                        seconds: _videoPlayerController
                                                .value.position.inSeconds +
                                            1),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  // If the VideoPlayerController is still initializing, show a
                  // loading spinner.
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
