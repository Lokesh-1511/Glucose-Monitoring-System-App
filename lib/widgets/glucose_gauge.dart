import 'package:flutter/material.dart';

/// Custom glucose gauge widget that displays glucose level in a circular format
/// with color coding based on glucose ranges
class GlucoseGauge extends StatelessWidget {
  final double value; // Glucose value in mg/dL
  final double minValue;
  final double maxValue;
  final double normalMin;
  final double normalMax;
  final double warningMin;
  final double warningMax;

  const GlucoseGauge({
    Key? key,
    required this.value,
    this.minValue = 40,
    this.maxValue = 400,
    this.normalMin = 70,
    this.normalMax = 100,
    this.warningMin = 100,
    this.warningMax = 140,
  }) : super(key: key);

  /// Determine color based on glucose value
  Color _getColor(double val) {
    if (val < normalMin) return Colors.red; // Low
    if (val <= normalMax) return Colors.green; // Normal
    if (val <= warningMax) return Colors.orange; // Warning
    return Colors.red; // High
  }

  /// Get status text based on glucose value
  String _getStatus(double val) {
    if (val < normalMin) return 'Low';
    if (val <= normalMax) return 'Normal';
    if (val <= warningMax) return 'Elevated';
    return 'High';
  }

  @override
  Widget build(BuildContext context) {
    final progress = ((value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);
    final gaugeColor = _getColor(value);
    final status = _getStatus(value);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular gauge
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 8),
                  ),
                ),
                // Progress circle
                CustomPaint(
                  size: const Size(200, 200),
                  painter: _CircularProgressPainter(
                    progress: progress,
                    color: gaugeColor,
                  ),
                ),
                // Center content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${value.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: gaugeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'mg/dL',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Status text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: gaugeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: gaugeColor, width: 2),
            ),
            child: Text(
              status,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: gaugeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Glucose ranges reference
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _RangeIndicator(color: Colors.red, label: 'Low\n<70'),
                _RangeIndicator(color: Colors.green, label: 'Normal\n70-100'),
                _RangeIndicator(color: Colors.orange, label: 'Elevated\n100-140'),
                _RangeIndicator(color: Colors.red, label: 'High\n>140'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the circular progress indicator
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // Start at top (-90 degrees)
      3.14159 * 2 * progress, // Sweep angle based on progress
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Small indicator widget for glucose ranges
class _RangeIndicator extends StatelessWidget {
  final Color color;
  final String label;

  const _RangeIndicator({
    Key? key,
    required this.color,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
