import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../widgets/common_widgets.dart';
import 'skin_tone_result_page.dart';

/// Second screen in skin tone calibration flow
/// Allows adjustment of brightness, saturation, and hue
class SkinToneAdjustPage extends StatefulWidget {
  final Uint8List imageBytes;

  const SkinToneAdjustPage({
    Key? key,
    required this.imageBytes,
  }) : super(key: key);

  @override
  State<SkinToneAdjustPage> createState() => _SkinToneAdjustPageState();
}

class _SkinToneAdjustPageState extends State<SkinToneAdjustPage> {
  double _brightness = 0.0; // -100 to 100
  double _saturation = 1.0; // 0 to 2
  double _hue = 0.0; // 0 to 360

  /// Get adjusted color based on sliders
  Color _getAdjustedColor() {
    // Base skin tone color
    int r = 210, g = 180, b = 140;

    // Apply brightness
    final brightnessMultiplier = 1.0 + (_brightness / 100.0);
    r = (r * brightnessMultiplier).clamp(0, 255).toInt();
    g = (g * brightnessMultiplier).clamp(0, 255).toInt();
    b = (b * brightnessMultiplier).clamp(0, 255).toInt();

    // Apply hue shift (simplified)
    final hueShift = _hue / 360.0;
    if (hueShift != 0) {
      final temp = r;
      r = (g + (hueShift * 50)).toInt().clamp(0, 255);
      g = (b + (hueShift * 25)).toInt().clamp(0, 255);
      b = (temp + (hueShift * 30)).toInt().clamp(0, 255);
    }

    // Apply saturation (desaturate towards gray, then saturate)
    final gray = (0.299 * r + 0.587 * g + 0.114 * b).toInt();
    r = (gray + (r - gray) * _saturation).clamp(0, 255).toInt();
    g = (gray + (g - gray) * _saturation).clamp(0, 255).toInt();
    b = (gray + (b - gray) * _saturation).clamp(0, 255).toInt();

    return Color.fromARGB(255, r, g, b);
  }

  /// Calculate melanin index from RGB
  double _calculateMelaninIndex() {
    final color = _getAdjustedColor();
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;

    // Y = luminance
    final y = 0.3 * r + 0.59 * g + 0.11 * b;
    if (y <= 0) return 0;

    // MI = 100 * ln(1/Y)
    final melaninIndex = 100 * (-y.log());
    return melaninIndex;
  }

  @override
  Widget build(BuildContext context) {
    final adjustedColor = _getAdjustedColor();
    final melaninIndex = _calculateMelaninIndex();

    return Scaffold(
      appBar: AppTopBar(
        title: 'Adjust Skin Tone',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color preview
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: adjustedColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Brightness slider
            _SliderControl(
              label: 'Brightness',
              value: _brightness,
              min: -100,
              max: 100,
              onChanged: (value) {
                setState(() {
                  _brightness = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // Saturation slider
            _SliderControl(
              label: 'Saturation',
              value: _saturation,
              min: 0,
              max: 2,
              onChanged: (value) {
                setState(() {
                  _saturation = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // Hue slider
            _SliderControl(
              label: 'Hue',
              value: _hue,
              min: 0,
              max: 360,
              onChanged: (value) {
                setState(() {
                  _hue = value;
                });
              },
            ),
            const SizedBox(height: 30),

            // Melanin index info
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Melanin Index (Preview)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Index Value:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        melaninIndex.toStringAsFixed(2),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Continue button
            PrimaryButton(
              label: 'Continue to Results',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SkinToneResultPage(
                    color: adjustedColor,
                    melaninIndex: melaninIndex,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slider control widget
class _SliderControl extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderControl({
    Key? key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value.toStringAsFixed(1),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          divisions: 100,
          label: value.toStringAsFixed(1),
        ),
      ],
    );
  }
}

extension on double {
  double log() => _ln();

  double _ln() {
    // Natural logarithm approximation
    if (this <= 0) return 0;
    double x = this;
    double result = 0;
    int i = 0;
    while (x > 2 && i < 100) {
      x = x / 2.71828;
      result += 1;
      i++;
    }
    // For small x, use Taylor series: ln(1+x) ≈ x - x²/2 + x³/3 - ...
    x = x - 1;
    double term = x;
    for (i = 2; i < 50; i++) {
      result += term / i;
      term *= -x;
    }
    return result;
  }
}
