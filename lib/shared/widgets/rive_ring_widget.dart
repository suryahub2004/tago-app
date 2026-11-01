import 'package:flutter/material.dart';

class RiveRingWidget extends StatefulWidget {
  final bool isPairing;
  final bool isSuccess;

  const RiveRingWidget({
    super.key,
    required this.isPairing,
    required this.isSuccess,
  });

  @override
  State<RiveRingWidget> createState() => _RiveRingWidgetState();
}

class _RiveRingWidgetState extends State<RiveRingWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.isSuccess) {
      return const Center(
        child: Icon(Icons.check_circle, size: 80, color: Colors.green),
      );
    }
    
    if (!widget.isPairing) {
      return const Center(
        child: Icon(Icons.ring_volume, size: 80, color: Colors.grey),
      );
    }

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.2),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: const Icon(Icons.ring_volume, size: 80, color: Colors.blue),
        ),
        onEnd: () => setState(() {}),
      ),
    );
  }
}
