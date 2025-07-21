import 'package:four_secrets_wedding_app/model/card_back_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';

// ignore: must_be_immutable
class CardWidget extends StatefulWidget {
  Object className;
  String avatarImage;
  String vorname;
  String nachname;
  String bezeichnung;
  String backCardTaetigkeit;
  String homepage;
  String email;
  String instagram;
  String videoRatio;
  String videoAsset;
  String videoUri;
  String phoneNumber;
  String slogan;

  CardWidget(
      {super.key,
      required Object this.className,
      required String this.avatarImage,
      required String this.vorname,
      required String this.nachname,
      required String this.bezeichnung,
      required String this.backCardTaetigkeit,
      required String this.homepage,
      required String this.email,
      required String this.slogan,
      required String this.phoneNumber,
      required String this.instagram,
      required String this.videoAsset,
      required String this.videoRatio,
      required String this.videoUri});

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget> with TickerProviderStateMixin {
  final controllerBtnFlip = GestureFlipCardController();
  late final AnimationController _controller;
  late final Animation<AlignmentGeometry> _animation;
  String urlMode = 'default'; // Now all sites in default mode

  initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _controller.repeat(reverse: true);

    _animation = Tween<AlignmentGeometry>(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.decelerate,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureFlipCard(
      axis: FlipAxis.vertical,
      frontWidget: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 10,
        margin: EdgeInsets.only(left: 20, right: 20, top: 25),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade200,
                Colors.grey.shade50
              ],
            ),
          ),
          height: 245,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: Color.fromARGB(255, 107, 69, 106),
                          radius: 64,
                          child: CircleAvatar(
                            backgroundImage: AssetImage(widget.avatarImage),
                            radius: 60,
                          ), //CircleAvatar
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        Text(
                          widget.vorname +
                              " " +
                              widget.nachname +
                              "\n" +
                              widget.bezeichnung,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 107, 69, 106),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    height: double.infinity,
                    width: 45,
                    child: AlignTransition(
                      alignment: _animation,
                      child: Icon(
                        Icons.keyboard_double_arrow_left_outlined,
                        size: 30,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      backWidget: CardBackWidget(
        className: widget.className,
        backCardTaetigkeit: widget.backCardTaetigkeit,
        homepage: widget.homepage,
        modeString: urlMode,
        email: widget.email,
        phoneNumber: widget.phoneNumber,
        slogan: widget.slogan,
        instagram: widget.instagram,
        videoAsset: widget.videoAsset,
        videoRatio: widget.videoRatio,
        videoUri: widget.videoUri,
      ),
      controller: controllerBtnFlip,
    );
  }
}
