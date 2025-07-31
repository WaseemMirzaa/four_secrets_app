import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/extension.dart';

// ignore: must_be_immutable
class SwipeableCardWidget extends StatefulWidget {
  List<String> images;
  double height;
  String imageFit; // New: Control how images are fitted
  bool showIndicators; // New: Control indicator visibility
  bool showSwipeHints; // New: Control swipe hint visibility

  SwipeableCardWidget({
    super.key,
    required this.images,
    required this.height,
    this.imageFit = "cover", // Default to cover to fill card shape
    this.showIndicators = true,
    this.showSwipeHints = true,
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
      duration: Duration(
          milliseconds: 200), // Faster animation for better responsiveness
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
    _animationController.stop(); // Fixed: Stop any ongoing animation
    _animationController.reset();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;

    setState(() {
      _dragOffset += details.delta;
      // Improved: More sensitive rotation calculation
      _dragRotation = (_dragOffset.dx / 200 * 0.15).clamp(-0.4, 0.4);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimating) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final threshold =
        screenWidth * 0.15; // Reduced from 0.3 to 0.15 for easier swiping
    final velocity = details.velocity.pixelsPerSecond.dx.abs();
    final velocityThreshold = 300; // Minimum velocity for quick swipes

    // Check for swipe based on distance OR velocity
    bool shouldSwipe =
        _dragOffset.dx.abs() > threshold || velocity > velocityThreshold;

    if (shouldSwipe) {
      // Swipe detected - determine direction
      bool swipeRight =
          _dragOffset.dx > 0 || details.velocity.pixelsPerSecond.dx > 0;
      _swipeCard(swipeRight);
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
      curve: Curves.easeOutBack, // Changed: Smoother return animation
    ));

    _rotationAnimation = Tween<double>(
      begin: _dragRotation,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack, // Changed: Smoother return animation
    ));

    _animationController.forward().then((_) {
      if (mounted) {
        // Fixed: Check if widget is still mounted
        setState(() {
          _dragOffset = Offset.zero;
          _dragRotation = 0.0;
          _isAnimating = false;
        });
        _animationController.reset();
      }
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
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100], // Background color for loading
        borderRadius: BorderRadius.circular(20),
      ),
      child: Image.asset(
        image,
        fit: _BoxFitMode(mode) ??
            BoxFit.cover, // Use the mode parameter and default to cover
        width: double.infinity,
        height: double.infinity,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.broken_image,
              color: Colors.grey[600],
              size: 50,
            ),
          );
        },
      ),
    );
  }

  BoxFit? _BoxFitMode(String mode) {
    switch (mode) {
      case "cover":
        return BoxFit.cover;
      case "contain":
        return BoxFit.contain; // Fixed: Better default to prevent cropping
      case "fill":
        return BoxFit.fill;
      case "height":
        return BoxFit.fitHeight;
      case "width":
        return BoxFit.fitWidth;
      case "scaleDown":
        return BoxFit.scaleDown; // New: Scale down if needed
      default:
        return BoxFit
            .contain; // Fixed: Use contain instead of cover to show full image
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
              // Calculate swipe progress for visual feedback
              final screenWidth = MediaQuery.of(context).size.width;
              final swipeProgress =
                  (_dragOffset.dx.abs() / (screenWidth * 0.15)).clamp(0.0, 1.0);
              final scale = 1.0 -
                  (swipeProgress * 0.05); // Slight scale down when swiping

              return Transform.scale(
                scale: scale,
                child: Transform.translate(
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
                      child: _buildCard(widget.images[0], 0, swipeProgress),
                    ),
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
          child: _buildCard(image, index, 0.0),
        ),
      ),
    );
  }

  Widget _buildCard(String imagePath, int index, [double swipeProgress = 0.0]) {
    // Visual feedback based on swipe direction
    Color overlayColor = Colors.transparent;
    if (swipeProgress > 0) {
      // Determine swipe direction
      if (_dragOffset.dx > 0) {
        // Swiping right - green success color
        overlayColor = Colors.green.withValues(alpha: 0.2 * swipeProgress);
      } else if (_dragOffset.dx < 0) {
        // Swiping left - blue info color
        overlayColor = Colors.blue.withValues(alpha: 0.2 * swipeProgress);
      }
    }

    return Container(
      width: context.screenWidth * 0.67,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1 + (0.1 * swipeProgress)),
            spreadRadius: 2 + swipeProgress,
            blurRadius: 10 + (5 * swipeProgress),
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Image with rounded corners
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: buildImage(context, imagePath, index, widget.imageFit),
          ),

          // Indicator dots at the bottom
          if (widget.showIndicators && widget.images.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (i) => Container(
                    margin: EdgeInsets.symmetric(horizontal: 3),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),

          // Swipe hint overlay
          if (widget.showSwipeHints && widget.images.length > 1)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                    ],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),

          // Swipe direction overlay
          if (swipeProgress > 0)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: overlayColor,
                ),
              ),
            ),

          // Swipe direction indicator
          if (swipeProgress > 0.3 && index == 0)
            Positioned(
              top: 0,
              bottom: 0,
              left: _dragOffset.dx > 0 ? null : 20,
              right: _dragOffset.dx > 0 ? 20 : null,
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _dragOffset.dx > 0
                        ? Colors.green.withValues(alpha: 0.8)
                        : Colors.blue.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _dragOffset.dx > 0 ? Icons.check : Icons.arrow_forward,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),

          // Swipe instruction hint (only shown for the top card when not swiping)
          // if (widget.showSwipeHints &&
          //     widget.images.length > 1 &&
          //     index == 0 &&
          //     swipeProgress < 0.1)
            // Positioned(
            //   bottom: widget.showIndicators ? 30 : 10,
            //   left: 0,
            //   right: 0,
            //   child: Center(
            //     child: Container(
            //       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            //       decoration: BoxDecoration(
            //         color: Colors.black.withValues(alpha: 0.5),
            //         borderRadius: BorderRadius.circular(15),
            //       ),
            //       child: Text(
            //         "← Swipe →",
            //         style: TextStyle(
            //           color: Colors.white,
            //           fontSize: 12,
            //           fontWeight: FontWeight.bold,
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
        ],
      ),
    );
  }
}
