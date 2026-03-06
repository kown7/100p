import 'dart:math' as math;
import 'package:flutter/material.dart';

class DaylightProgressCircle extends StatelessWidget {
  final double progress;
  final String centerText;
  final bool isNight;

  const DaylightProgressCircle({
    super.key,
    required this.progress,
    required this.centerText,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        return SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(280, 280),
                painter: _SunRingPainter(progress: animated, isNight: isNight),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isNight ? 34.0 : 54.0,
                      fontWeight: FontWeight.w200,
                      letterSpacing: -1.5,
                    ),
                  ),
                  if (!isNight)
                    Text(
                      'OF DAY ELAPSED',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.38),
                        fontSize: 9,
                        letterSpacing: 3.5,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SunRingPainter extends CustomPainter {
  final double progress;
  final bool isNight;

  const _SunRingPainter({required this.progress, required this.isNight});

  static const double _strokeWidth = 22;
  static const double _startAngle = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - _strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Subtle track ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..color = Colors.white.withValues(alpha: 0.08),
    );

    if (progress <= 0) return;

    final sweepAngle = progress * 2 * math.pi;

    // Gradient arc: colours shift from dawn → noon → dusk around the ring
    final gradient = SweepGradient(
      startAngle: _startAngle,
      endAngle: _startAngle + 2 * math.pi,
      colors: isNight
          ? [
              const Color(0xFF29B6F6),
              const Color(0xFF9575CD),
              const Color(0xFFCE93D8),
              const Color(0xFF29B6F6),
            ]
          : [
              const Color(0xFFFF8F00), // dawn  – warm orange
              const Color(0xFFFFEE58), // noon  – bright gold
              const Color(0xFFF4511E), // dusk  – deep orange-red
              const Color(0xFFFF8F00), // loop back
            ],
      stops: const [0.0, 0.45, 0.90, 1.0],
    );

    canvas.drawArc(
      rect,
      _startAngle,
      sweepAngle,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.butt
        ..shader = gradient.createShader(rect),
    );

    // Glowing sun / moon dot at the arc tip
    final tipAngle = _startAngle + sweepAngle;
    final tipPos = Offset(
      center.dx + radius * math.cos(tipAngle),
      center.dy + radius * math.sin(tipAngle),
    );

    final glowColor = isNight ? const Color(0xFF80DEEA) : const Color(0xFFFFD700);

    // Wide diffuse halo
    canvas.drawCircle(
      tipPos,
      30,
      Paint()
        ..color = glowColor.withValues(alpha: 0.07)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    // Tighter inner glow
    canvas.drawCircle(
      tipPos,
      18,
      Paint()
        ..color = glowColor.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Solid core
    canvas.drawCircle(tipPos, 9, Paint()..color = glowColor);
    // Bright white centre
    canvas.drawCircle(tipPos, 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_SunRingPainter old) =>
      old.progress != progress || old.isNight != isNight;
}
