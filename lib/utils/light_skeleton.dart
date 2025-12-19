import 'package:flutter/material.dart';

class LightSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const LightSkeleton({
    super.key,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<LightSkeleton> createState() => _LightSkeletonState();
}

class _LightSkeletonState extends State<LightSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.65,
        end: 0.95,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: widget.borderRadius,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
