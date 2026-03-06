import 'package:flutter/material.dart';

class DaylightProgressCircle extends StatelessWidget {
  final double progress;
  final String centerText;
  final double size;
  final double strokeWidth;

  const DaylightProgressCircle({
    super.key,
    required this.progress,
    required this.centerText,
    this.size = 240.0,
    this.strokeWidth = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular progress indicator matching Android version
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.butt, // Matches Android StrokeCap.Butt
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          // Center text
          Text(
            centerText,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}