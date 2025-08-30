// lib/widgets/border_beam.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class BorderBeam extends StatefulWidget {
  final Widget child;
  final double duration;
  final double borderWidth;
  final Color colorFrom;
  final Color colorTo;
  final Color staticBorderColor;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  const BorderBeam({
    Key? key,
    required this.child,
    this.duration = 15,
    this.borderWidth = 1.5,
    this.colorFrom = const Color(0xFFFFAA40),
    this.colorTo = const Color(0xFF9C40FF),
    this.staticBorderColor = const Color(0xFFCCCCCC),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  @override
  _BorderBeamState createState() => _BorderBeamState();
}

class _BorderBeamState extends State<BorderBeam>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: widget.duration.toInt()),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: BorderBeamPainter(
            progress: _animation.value,
            borderWidth: widget.borderWidth,
            colorFrom: widget.colorFrom,
            colorTo: widget.colorTo,
            staticBorderColor: widget.staticBorderColor,
            borderRadius: widget.borderRadius,
          ),
          child: Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        );
      },
    );
  }
}

class BorderBeamPainter extends CustomPainter {
  final double progress;
  final double borderWidth;
  final Color colorFrom;
  final Color colorTo;
  final Color staticBorderColor;
  final BorderRadius borderRadius;

  BorderBeamPainter({
    required this.progress,
    required this.borderWidth,
    required this.colorFrom,
    required this.colorTo,
    required this.staticBorderColor,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = borderRadius.toRRect(rect);

    // Static border
    final staticPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..color = staticBorderColor;

    canvas.drawRRect(rrect, staticPaint); // ✅ here

    // Moving beam
    final path = Path()..addRRect(rrect);
    final metric = path.computeMetrics().first;
    final pathLength = metric.length;

    final animationProgress = progress % 1.0;
    final start = animationProgress * pathLength;

    const double coverage = 0.98; // tweak 0.2–1.0
    final sweep = pathLength * coverage;
    final end = (start + sweep) % pathLength;

    Path extractPath;
    if (end > start) {
      extractPath = metric.extractPath(start, end);
    } else {
      extractPath = metric.extractPath(start, pathLength)
        ..addPath(metric.extractPath(0, end), Offset.zero);
    }

    final gradientStart =
        metric.getTangentForOffset(start)?.position ?? Offset.zero;
    final gradientEnd = metric
            .getTangentForOffset((start + sweep * 0.5) % pathLength)
            ?.position ??
        Offset.zero;

    final mid = Color.lerp(colorFrom, colorTo, 0.5)!;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(
        gradientStart,
        gradientEnd,
        [colorFrom, mid, colorTo.withOpacity(.90), colorTo.withOpacity(0.0)],
        [0.0, 0.45, 0.85, 1.0],
      );

    canvas.drawPath(extractPath, paint);

  }

  @override
  bool shouldRepaint(covariant BorderBeamPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
