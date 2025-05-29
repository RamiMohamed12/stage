import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:frontend/constants/colors.dart';

class LoadingIndicator extends StatefulWidget {
  final double animationSize;
  final Duration delay;

  const LoadingIndicator({
    super.key,
    this.animationSize = 200.0, // Increased default size
    this.delay = const Duration(milliseconds: 200), // Added a default delay
  });

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator> {
  bool _showAnimation = false;

  @override
  void initState() {
    super.initState();
    // Start a timer to show the animation after the specified delay
    Timer(widget.delay, () {
      if (mounted) { // Check if the widget is still in the tree
        setState(() {
          _showAnimation = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // This container provides the full-screen white background
      width: double.infinity,
      height: double.infinity,
      color: AppColors.whiteColor, // Fully white background
      alignment: Alignment.center, // Centers the child (Lottie animation)
      child: AnimatedOpacity(
        opacity: _showAnimation ? 1.0 : 0.0, // Control visibility with opacity
        duration: const Duration(milliseconds: 300), // Fade-in duration
        child: Lottie.asset(
          'assets/lottie/loading_animation.json',
          width: widget.animationSize,
          height: widget.animationSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}