import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../widgets/common_widgets.dart';
import 'skin_tone_result_page.dart';
import 'skin_tone_capture_page.dart';

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
  
  Color? _baseAverageColor; // average color sampled from captured image
  bool _loadingImage = true;

  @override
  void initState() {
    super.initState();
    _initPreviewImage();
  }

  Future<void> _initPreviewImage() async {
    try {
      final codec = await ui.instantiateImageCodec(
        widget.imageBytes,
        targetWidth: 200,
      );
      final fi = await codec.getNextFrame();
      final img = fi.image;
      final avg = await _computeAverageColor(img);
      if (mounted) {
        setState(() {
          _baseAverageColor = avg;
          _loadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingImage = false);
      }
    }
  }

  Future<Color> _computeAverageColor(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return const Color(0xFFD2B48C); // fallback tan
    final bytes = byteData.buffer.asUint8List();
    final width = image.width;
    final height = image.height;
    final startX = (width * 0.25).floor();
    final startY = (height * 0.25).floor();
    final endX = (width * 0.75).floor();
    final endY = (height * 0.75).floor();
    int rSum = 0, gSum = 0, bSum = 0, count = 0;
    for (int y = startY; y < endY; y += 2) {
      for (int x = startX; x < endX; x += 2) {
        final idx = (y * width + x) * 4;
        final r = bytes[idx];
        final g = bytes[idx + 1];
        final b = bytes[idx + 2];
        rSum += r;
        gSum += g;
        bSum += b;
        count++;
      }
    }
    if (count == 0) return const Color(0xFFD2B48C);
    return Color.fromARGB(
      255,
      (rSum / count).round(),
      (gSum / count).round(),
      (bSum / count).round(),
    );
  }

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

  /// Convert RGB color to HSV and apply adjustments
  Color _applyHsvAdjustments(Color base) {
    double r = base.red / 255.0;
    double g = base.green / 255.0;
    double b = base.blue / 255.0;
    final maxc = [r, g, b].reduce((a, b) => a > b ? a : b);
    final minc = [r, g, b].reduce((a, b) => a < b ? a : b);
    double h = 0.0;
    double s = maxc == 0 ? 0.0 : (maxc - minc) / maxc;
    final v = maxc;
    if (minc != maxc) {
      final rc = (maxc - r) / (maxc - minc);
      final gc = (maxc - g) / (maxc - minc);
      final bc = (maxc - b) / (maxc - minc);
      if (r == maxc) {
        h = bc - gc;
      } else if (g == maxc) {
        h = 2.0 + rc - bc;
      } else {
        h = 4.0 + gc - rc;
      }
      h = (h / 6.0) % 1.0;
    }
    // Apply adjustments
    final newH = ((h * 360.0 + _hue) % 360.0);
    final newS = (s * _saturation).clamp(0.0, 1.0);
    final newV = (v + (_brightness / 100.0)).clamp(0.0, 1.0);
    return _hsvaToColor(newH, newS, newV, 1.0);
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

  /// Calculate melanin index from adjusted image average color
  double _calculateMelaninIndex() {
    final base = _baseAverageColor ?? const Color(0xFFD2B48C);
    final color = _applyHsvAdjustments(base);
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;
    final y = 0.2126 * r + 0.7152 * g + 0.0722 * b; // luminance
    // Avoid log(0)
    final safeY = y.clamp(0.0001, 0.9999);
    // Raw melanin index (unbounded)
    final miRaw = -100.0 * math.log(safeY);
    // Normalize to 0..100 using a practical range (bright ~10, dark ~300)
    const miMin = 10.0;
    const miMax = 300.0;
    final miNorm = ((miRaw - miMin) / (miMax - miMin) * 100.0).clamp(0.0, 100.0);
    return miNorm;
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
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _loadingImage
                          ? const Center(child: CircularProgressIndicator())
                          : ColorFiltered(
                              colorFilter: ColorFilter.matrix(
                                _composeColorMatrix(
                                  hueDegrees: _hue,
                                  saturationScale: _saturation,
                                  brightnessPercent: _brightness,
                                ),
                              ),
                              child: Image.memory(
                                widget.imageBytes,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Live Skin Image Preview',
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
                    imageBytes: widget.imageBytes,
                    hue: _hue,
                    saturation: _saturation,
                    brightness: _brightness,
                    melaninIndex: melaninIndex,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Discard & Retake button
            SecondaryButton(
              label: 'Discard & Retake',
              height: 48,
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SkinToneCapturePage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Compose color filter matrix for hue, saturation and brightness
  List<double> _composeColorMatrix({
    required double hueDegrees,
    required double saturationScale,
    required double brightnessPercent,
  }) {
    final h = hueDegrees * math.pi / 180.0;
    final cosH = math.cos(h);
    final sinH = math.sin(h);
    const rW = 0.213, gW = 0.715, bW = 0.072;
    final hue = <double>[
      rW + cosH * (1 - rW) + sinH * (-rW), gW + cosH * (-gW) + sinH * (-gW), bW + cosH * (-bW) + sinH * (1 - bW), 0, 0,
      rW + cosH * (-rW) + sinH * (0.143), gW + cosH * (1 - gW) + sinH * (0.140), bW + cosH * (-bW) + sinH * (-0.283), 0, 0,
      rW + cosH * (-rW) + sinH * (-(1 - rW)), gW + cosH * (-gW) + sinH * (gW), bW + cosH * (1 - bW) + sinH * (bW), 0, 0,
      0, 0, 0, 1, 0,
    ];

    final s = saturationScale;
    final sat = <double>[
      rW * (1 - s) + s, gW * (1 - s), bW * (1 - s), 0, 0,
      rW * (1 - s), gW * (1 - s) + s, bW * (1 - s), 0, 0,
      rW * (1 - s), gW * (1 - s), bW * (1 - s) + s, 0, 0,
      0, 0, 0, 1, 0,
    ];

    final v = 1.0 + (brightnessPercent / 100.0);
    final bright = <double>[
      v, 0, 0, 0, 0,
      0, v, 0, 0, 0,
      0, 0, v, 0, 0,
      0, 0, 0, 1, 0,
    ];

    return _multiplyColorMatrices(_multiplyColorMatrices(bright, sat), hue);
  }

  List<double> _multiplyColorMatrices(List<double> a, List<double> b) {
    // a and b are 4x5 matrices in row-major (20 elements)
    final out = List<double>.filled(20, 0);
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 5; col++) {
        double sum = 0;
        for (int k = 0; k < 4; k++) {
          sum += a[row * 5 + k] * b[k * 5 + col];
        }
        if (col == 4) sum += a[row * 5 + 4];
        out[row * 5 + col] = sum;
      }
    }
    return out;
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

// Removed broken log extension; using dart:math.log instead
