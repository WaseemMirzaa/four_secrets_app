import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/extension.dart';

// ignore: must_be_immutable
class SwipeableCardWidget extends StatefulWidget {
  List<String> images;
  double height;

  SwipeableCardWidget({
    super.key,
    required this.images,
    required this.height,
  });

  @override
  _SwipeableCardWidgetState createState() => _SwipeableCardWidgetState();
}

class _SwipeableCardWidgetState extends State<SwipeableCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;

  bool _isAnimating = false;
  Offset _dragOffset = Offset.zero;
  double _dragRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(2.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_isAnimating) return;
    _animationController.reset();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;

    setState(() {
      _dragOffset += details.delta;
      _dragRotation =
          _dragOffset.dx / 300 * 0.1; // Rotation based on horizontal drag
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimating) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.3;

    if (_dragOffset.dx.abs() > threshold) {
      // Swipe detected
      _swipeCard(_dragOffset.dx > 0);
    } else {
      // Return to center with animation
      _returnToCenter();
    }
  }

  void _returnToCenter() {
    _isAnimating = true;

    _slideAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: _dragRotation,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward().then((_) {
      setState(() {
        _dragOffset = Offset.zero;
        _dragRotation = 0.0;
        _isAnimating = false;
      });
      _animationController.reset();
    });
  }

  void _swipeCard(bool swipeRight) {
    _isAnimating = true;

    _slideAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(swipeRight ? 2.0 : -2.0, _dragOffset.dy),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: _dragRotation,
      end: swipeRight ? 0.3 : -0.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward().then((_) {
      if (mounted) {
        setState(() {
          // Move the first image to the end
          final firstImage = widget.images.removeAt(0);
          widget.images.add(firstImage);

          _dragOffset = Offset.zero;
          _dragRotation = 0.0;
          _isAnimating = false;
        });
        _animationController.reset();
      }
    });
  }

  Widget buildImage(
      BuildContext context, String image, int index, String mode) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
          // color: Colors.white,
          ),
      child: ClipRRect(
        // borderRadius: BorderRadius.circular(40),
        child: Image.asset(
          image,
          fit: _BoxFitMode(mode),
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }

  BoxFit? _BoxFitMode(String mode) {
    switch (mode) {
      case "cover":
        return BoxFit.cover;
      case "contain":
        return BoxFit.contain;
      case "fill":
        return BoxFit.fill;
      case "height":
        return BoxFit.fitHeight;
      case "width":
        return BoxFit.fitWidth;
      default:
        return BoxFit.contain;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background cards (tilted)
          for (int i = widget.images.length - 1; i >= 1; i--)
            _buildBackgroundCard(i),

          // Top card (interactive)
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: _isAnimating
                    ? Offset(
                        _slideAnimation.value.dx *
                            MediaQuery.of(context).size.width,
                        _slideAnimation.value.dy,
                      )
                    : _dragOffset,
                child: Transform.rotate(
                  angle:
                      _isAnimating ? _rotationAnimation.value : _dragRotation,
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: _buildCard(widget.images[0], 0),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundCard(int index) {
    final image = widget.images[index];
    final scale = 1.0 - (index * 0.05);
    final yOffset = index * 8.30;

    // Fixed tilt pattern: first background card tilts left, second tilts right
    double tiltAngle;
    if (index == 1) {
      tiltAngle = -0.13; // First background card tilts left
    } else if (index == 2) {
      tiltAngle = -0.28; // Second background card tilts right
    } else {
      // For additional cards, alternate the pattern
      tiltAngle = (index % 2 == 1) ? -0.05 : 0.05;
    }

    return Transform.translate(
      offset: Offset(0, yOffset),
      child: Transform.scale(
        scale: scale,
        child: Transform.rotate(
          angle: tiltAngle,
          child: _buildCard(image, index),
        ),
      ),
    );
  }

  Widget _buildCard(String imagePath, int index) {
    return Container(
      width: context.screenWidth * 0.67,
      height: widget.height,
      decoration: BoxDecoration(
        // color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        // borderRadius: BorderRadius.circular(40),
        child: buildImage(context, imagePath, index, "cover"),
      ),
    );
  }
}
