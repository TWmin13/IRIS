import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'dart:math' as math;

class AuroraBackground extends StatefulWidget {
  final Widget child;
  final List<Color> colorStops;
  final double amplitude;
  final bool animate;

  const AuroraBackground({
    super.key,
    required this.child,
    this.colorStops = const [
      Color(0xFF1976D2), // Primary blue
      Color(0xFF2196F3), // Light blue
      Color(0xFF90CAF9), // Very light blue
    ],
    this.amplitude = 1.5, // Increased amplitude for more visible effect
    this.animate = true,
  }) : assert(colorStops.length == 3, 'Must provide exactly 3 colors');

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6), // Slower animation
    );

    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit
          .passthrough, // Changed to passthrough to respect parent constraints
      children: [
        // Base white background
        Container(
          color: Colors.white,
        ),
        // Aurora Effect
        ShaderBuilder(
          assetKey: 'assets/shaders/aurora.glsl',
          (context, shader, child) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _AuroraPainter(
                    shader: shader,
                    time: _controller.value,
                    amplitude: widget.amplitude,
                    colorStops: widget.colorStops,
                    resolution: MediaQuery.of(context).size,
                  ),
                );
              },
            );
          },
        ),
        // Content
        widget.child,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final FragmentShader shader;
  final double time;
  final double amplitude;
  final List<Color> colorStops;
  final Size resolution;

  _AuroraPainter({
    required this.shader,
    required this.time,
    required this.amplitude,
    required this.colorStops,
    required this.resolution,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time * 2 * math.pi)
      ..setFloat(3, amplitude)
      ..setFloat(4, colorStops[0].r / 255.0)
      ..setFloat(5, colorStops[0].g / 255.0)
      ..setFloat(6, colorStops[0].b / 255.0)
      ..setFloat(7, colorStops[1].r / 255.0)
      ..setFloat(8, colorStops[1].g / 255.0)
      ..setFloat(9, colorStops[1].b / 255.0)
      ..setFloat(10, colorStops[2].r / 255.0)
      ..setFloat(11, colorStops[2].g / 255.0)
      ..setFloat(12, colorStops[2].b / 255.0);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_AuroraPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
