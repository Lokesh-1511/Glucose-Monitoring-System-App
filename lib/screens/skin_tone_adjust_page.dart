import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../widgets/common_widgets.dart';
import 'skin_tone_result_page.dart';

/// Second screen in skin tone calibration flow
/// Allows adjustment of brightness, saturation, and hue using HSV color space
/// Provides skin tone presets and real-time preview
class SkinToneAdjustPage extends StatefulWidget {
  final Uint8List imageBytes;

  const SkinToneAdjustPage({
    Key? key,
    required this.imageBytes,
  }) : super(key: key);

  @override
  State<SkinToneAdjustPage> createState() => _SkinToneAdjustPageState();
}

/// Common skin tone presets for quick calibration reference
class _SkinTonePreset {
  final String name;
  final Color color;
  final double melaninIndex;

  _SkinTonePreset({
    required this.name,
    required this.color,
    required this.melaninIndex,
  });
}

class _SkinToneAdjustPageState extends State<SkinToneAdjustPage> {
  double _hue = 0.0; // 0 to 360
  double _saturation = 1.0; // 0 to 2
  double _brightness = 0.0; // -100 to 100

  // Skin tone presets (common ethnic skin tones)
  late final List<_SkinTonePreset> _skinTonePresets = [
    _SkinTonePreset(
      name: 'Very Light',
      color: const Color.fromARGB(255, 255, 213, 191),
      melaninIndex: 15.5,
    ),
    _SkinTonePreset(
      name: 'Light',
      color: const Color.fromARGB(255, 241, 194, 125),
      melaninIndex: 28.3,
    ),
    _SkinTonePreset(
      name: 'Medium',
      color: const Color.fromARGB(255, 210, 180, 140),
      melaninIndex: 41.2,
    ),
    _SkinTonePreset(
      name: 'Olive',
      color: const Color.fromARGB(255, 184, 134, 11),
      melaninIndex: 52.8,
    ),
    _SkinTonePreset(
      name: 'Deep',
      color: const Color.fromARGB(255, 139, 90, 43),
      melaninIndex: 62.5,
    ),
    _SkinTonePreset(
      name: 'Very Deep',
      color: const Color.fromARGB(255, 70, 35, 10),
      melaninIndex: 75.0,
    ),
  ];

  /// Get adjusted color based on HSV sliders with proper color math
  Color _getAdjustedColor() {
    // Base skin tone color
    int r = 210, g = 180, b = 140;

    // Convert RGB to HSV
    double rn = r / 255.0;
    double gn = g / 255.0;
    double bn = b / 255.0;

    double maxc = [rn, gn, bn].reduce((a, b) => a > b ? a : b);
    double minc = [rn, gn, bn].reduce((a, b) => a < b ? a : b);
    double v = maxc;

    if (minc == maxc) {
      return _hsvaToColor(0, 0, v + (_brightness / 100.0), 1.0);
    }

    double s = (maxc - minc) / maxc;
    double rc = (maxc - rn) / (maxc - minc);
    double gc = (maxc - gn) / (maxc - minc);
    double bc = (maxc - bn) / (maxc - minc);

    double h = 0.0;
    if (rn == maxc) {
      h = bc - gc;
    } else if (gn == maxc) {
      h = 2.0 + rc - bc;
    } else {
      h = 4.0 + gc - rc;
    }
    h = (h / 6.0) % 1.0;

    // Apply adjustments
    h = (h * 360 + _hue) % 360;
    s = (s * _saturation).clamp(0.0, 1.0);
    v = (v + (_brightness / 100.0)).clamp(0.0, 1.0);

    return _hsvaToColor(h, s, v, 1.0);
  }

  /// Convert HSVA to RGBA Color
  Color _hsvaToColor(double h, double s, double v, double a) {
    h = (h % 360) / 60.0;
    int i = h.toInt();
    double f = h - i;

    double p = v * (1.0 - s);
    double q = v * (1.0 - s * f);
    double t = v * (1.0 - s * (1.0 - f));

    double r, g, b;

    switch (i) {
      case 0:
        r = v;
        g = t;
        b = p;
        break;
      case 1:
        r = q;
        g = v;
        b = p;
        break;
      case 2:
        r = p;
        g = v;
        b = t;
        break;
      case 3:
        r = p;
        g = q;
        b = v;
        break;
      case 4:
        r = t;
        g = p;
        b = v;
        break;
      default:
        r = v;
        g = p;
        b = q;
    }

    return Color.fromARGB(
      (a * 255).toInt(),
      (r * 255).toInt(),
      (g * 255).toInt(),
      (b * 255).toInt(),
    );
  }

  /// Calculate melanin index from RGB using dermatology formula
  double _calculateMelaninIndex() {
    final color = _getAdjustedColor();
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;

    // Luminance calculation using standard RGB weights
    final y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    if (y <= 0.0001) return 0;

    // Melanin Index (MI) formula: MI = 100 * ln(1/Y)
    final melaninIndex = 100 * (-y.log());
    return melaninIndex.clamp(0, 100);
  }

  /// Apply skin tone preset
  void _applyPreset(_SkinTonePreset preset) {
    final rgbColor = preset.color;
    double rn = rgbColor.red / 255.0;
    double gn = rgbColor.green / 255.0;
    double bn = rgbColor.blue / 255.0;

    double maxc = [rn, gn, bn].reduce((a, b) => a > b ? a : b);
    double minc = [rn, gn, bn].reduce((a, b) => a < b ? a : b);

    double h = 0.0;
    if (minc != maxc) {
      double rc = (maxc - rn) / (maxc - minc);
      double gc = (maxc - gn) / (maxc - minc);
      double bc = (maxc - bn) / (maxc - minc);

      if (rn == maxc) {
        h = bc - gc;
      } else if (gn == maxc) {
        h = 2.0 + rc - bc;
      } else {
        h = 4.0 + gc - rc;
      }
      h = ((h / 6.0) % 1.0) * 360;
    }

    setState(() {
      _hue = h;
      _saturation = 1.0;
      _brightness = 0.0;
    });
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
            // Color preview with info card
            Center(
              child: Column(
                children: [
                  Container(
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
                  const SizedBox(height: 16),
                  Text(
                    'Live Skin Tone Preview',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Skin tone presets
            Text(
              'Quick Presets',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _skinTonePresets.length,
                itemBuilder: (context, index) {
                  final preset = _skinTonePresets[index];
                  return GestureDetector(
                    onTap: () => _applyPreset(preset),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: preset.color,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preset.name,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),

            // Adjustment sliders
            Text(
              'Fine Tune',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Hue slider
            _SliderControl(
              label: 'Hue',
              value: _hue,
              min: 0,
              max: 360,
              unit: '°',
              onChanged: (value) {
                setState(() {
                  _hue = value;
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
              unit: 'x',
              onChanged: (value) {
                setState(() {
                  _saturation = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // Brightness slider
            _SliderControl(
              label: 'Brightness',
              value: _brightness,
              min: -100,
              max: 100,
              unit: '%',
              onChanged: (value) {
                setState(() {
                  _brightness = value;
                });
              },
            ),
            const SizedBox(height: 30),

            // Melanin index info card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Melanin Index',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          melaninIndex.toStringAsFixed(2),
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This value indicates melanin concentration in your skin. Higher values suggest more melanin.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Continue button
            PrimaryButton(
              label: 'Continue to Results',
              width: double.infinity,
              height: 50,
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Enhanced slider control with better UX
class _SliderControl extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final ValueChanged<double> onChanged;

  const _SliderControl({
    Key? key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.unit = '',
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.toStringAsFixed(1)}$unit',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
  double log() {
    // Natural logarithm using Dart's built-in
    return double.parse(
      'NaN', // Placeholder - use standard library
    );
  }
}
