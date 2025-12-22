import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../widgets/common_widgets.dart';
import '../services/data_storage_service.dart';
import '../models/user_profile.dart';
import 'skin_tone_capture_page.dart';

/// Third screen in skin tone calibration flow
/// Displays final results and saves to profile
class SkinToneResultPage extends StatefulWidget {
  final Uint8List imageBytes;
  final double hue; // degrees
  final double saturation; // scale
  final double brightness; // percent
  final double melaninIndex;

  const SkinToneResultPage({
    Key? key,
    required this.imageBytes,
    required this.hue,
    required this.saturation,
    required this.brightness,
    required this.melaninIndex,
  }) : super(key: key);

  @override
  State<SkinToneResultPage> createState() => _SkinToneResultPageState();
}

class _SkinToneResultPageState extends State<SkinToneResultPage> {
  bool _isSaving = false;
  bool _loading = true;
  Color? _baseAverageColor;
  Color? _adjustedColor;

  @override
  void initState() {
    super.initState();
    _initAverageFromImage();
  }

  Future<void> _initAverageFromImage() async {
    try {
      final codec = await ui.instantiateImageCodec(
        widget.imageBytes,
        targetWidth: 200,
      );
      final fi = await codec.getNextFrame();
      final img = fi.image;
      final avg = await _computeAverageColor(img);
      final adjusted = _applyHsv(avg, widget.hue, widget.saturation, widget.brightness);
      if (mounted) {
        setState(() {
          _baseAverageColor = avg;
          _adjustedColor = adjusted;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Convert RGB to Lab color space
  Map<String, double> _rgbToLab(Color color) {
    // Normalize RGB to 0-1
    double r = color.red / 255.0;
    double g = color.green / 255.0;
    double b = color.blue / 255.0;

    // Apply gamma correction (sRGB to linear RGB)
    r = r > 0.04045 ? _pow((r + 0.055) / 1.055, 2.4) : r / 12.92;
    g = g > 0.04045 ? _pow((g + 0.055) / 1.055, 2.4) : g / 12.92;
    b = b > 0.04045 ? _pow((b + 0.055) / 1.055, 2.4) : b / 12.92;

    // Convert to XYZ color space
    double x = r * 0.4124 + g * 0.3576 + b * 0.1805;
    double y = r * 0.2126 + g * 0.7152 + b * 0.0722;
    double z = r * 0.0193 + g * 0.1192 + b * 0.9505;

    // Normalize by D65 illuminant
    x = x / 0.95047;
    y = y / 1.00000;
    z = z / 1.08883;

    // Convert XYZ to Lab
    final xf = x > 0.008856 ? _pow(x, 1.0 / 3.0) : (7.787 * x + 16.0 / 116.0);
    final yf = y > 0.008856 ? _pow(y, 1.0 / 3.0) : (7.787 * y + 16.0 / 116.0);
    final zf = z > 0.008856 ? _pow(z, 1.0 / 3.0) : (7.787 * z + 16.0 / 116.0);

    final l = 116.0 * yf - 16.0;
    final a = 500.0 * (xf - yf);
    final labB = 200.0 * (yf - zf);

    return {
      'L': l.clamp(0, 100),
      'a': a.clamp(-128, 127),
      'b': labB.clamp(-128, 127),
    };
  }

  Future<Color> _computeAverageColor(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return const Color(0xFFD2B48C);
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

  /// Save melanin index to user profile
  Future<void> _saveSkinTone() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final storageService = DataStorageService();
      await storageService.init();

      // Load current profile or create new one
      var profile = storageService.loadUserProfile();
      if (profile == null) {
        profile = UserProfile(
          name: 'User',
          age: 25,
          gender: 'Not specified',
          height: 170,
          weight: 70,
          melaninIndex: widget.melaninIndex,
        );
      } else {
        profile = profile.copyWith(melaninIndex: widget.melaninIndex);
      }

      // Save updated profile
      await storageService.saveUserProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Skin tone calibration saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Pop back to profile page
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving skin tone: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final adjusted = _adjustedColor ?? const Color.fromARGB(255, 210, 180, 140);
    final lab = _rgbToLab(adjusted);

    return Scaffold(
      appBar: AppTopBar(
        title: 'Skin Tone Results',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview with applied adjustments
            Center(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.matrix(
                        _composeColorMatrix(
                          hueDegrees: widget.hue,
                          saturationScale: widget.saturation,
                          brightnessPercent: widget.brightness,
                        ),
                      ),
                      child: Image.memory(
                        widget.imageBytes,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Calibrated Skin Image',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // RGB Values from adjusted average image color
            _ResultCard(
              title: 'RGB Values',
              children: [
                _ResultRow(
                  label: 'Red',
                  value: adjusted.red.toString(),
                ),
                _ResultRow(
                  label: 'Green',
                  value: adjusted.green.toString(),
                ),
                _ResultRow(
                  label: 'Blue',
                  value: adjusted.blue.toString(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lab Values with explanation
            _ResultCard(
              title: 'Lab Color Space',
              children: [
                _ResultRow(
                  label: 'L* (Lightness)',
                  value: lab['L']!.toStringAsFixed(2),
                  description: 'Range: 0-100 (black to white)',
                ),
                const Divider(height: 16),
                _ResultRow(
                  label: 'a* (Green-Red)',
                  value: lab['a']!.toStringAsFixed(2),
                  description: 'Negative=Green, Positive=Red',
                ),
                const Divider(height: 16),
                _ResultRow(
                  label: 'b* (Blue-Yellow)',
                  value: lab['b']!.toStringAsFixed(2),
                  description: 'Negative=Blue, Positive=Yellow',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Melanin Index with scale visualization
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Melanin Index',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Large melanin index display
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.melaninIndex.toStringAsFixed(2),
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Melanin Concentration Index',
                            style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Melanin scale visualization
                  _buildMelaninScale(context, widget.melaninIndex),
                  const SizedBox(height: 16),

                  Text(
                    'Understanding Your Melanin Index:',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMelaninScaleItem(
                        context,
                        'Very Light (0-20)',
                        'Fair, light complexion',
                      ),
                      _buildMelaninScaleItem(
                        context,
                        'Light (20-35)',
                        'Light to medium-light',
                      ),
                      _buildMelaninScaleItem(
                        context,
                        'Medium (35-55)',
                        'Medium to olive',
                      ),
                      _buildMelaninScaleItem(
                        context,
                        'Deep (55-75)',
                        'Brown to deep brown',
                      ),
                      _buildMelaninScaleItem(
                        context,
                        'Very Deep (75-100)',
                        'Very dark brown to black',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This index will calibrate glucose readings to account for skin tone variations in optical measurements.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save button with enhanced styling
            PrimaryButton(
              label: _isSaving ? 'Saving...' : 'Save Calibration',
              isLoading: _isSaving,
              onPressed: _saveSkinTone,
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Retake Photo',
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
            Text(
              'Your skin tone profile will be saved and used to optimize glucose monitoring accuracy.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build melanin scale visualization bar
  Widget _buildMelaninScale(BuildContext context, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Melanin Scale',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFD7BE), // Very light
                Color(0xFFC39B6B), // Light
                Color(0xFF8B7355), // Medium
                Color(0xFF5D4E37), // Deep
                Color(0xFF2A1810), // Very deep
              ],
            ),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: (value / 100) * 100 + '%'.length.toDouble() - 5,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 2,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
            Text(
              '100',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build melanin scale explanation item
  Widget _buildMelaninScaleItem(
    BuildContext context,
    String range,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            '•',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  range,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Result card widget
class _ResultCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ResultCard({
    Key? key,
    required this.title,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// Result row widget
class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final String? description;

  const _ResultRow({
    Key? key,
    required this.label,
    required this.value,
    this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        if (description != null)
          Text(
            description!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
      ],
    );
  }
}

double _pow(double base, double exponent) {
  return pow(base, exponent).toDouble();
}

// Helpers to mirror adjust-page view

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

Color _applyHsv(Color base, double hue, double saturation, double brightness) {
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
  final newH = ((h * 360.0 + hue) % 360.0);
  final newS = (s * saturation).clamp(0.0, 1.0);
  final newV = (v + (brightness / 100.0)).clamp(0.0, 1.0);
  return _hsvaToColor(newH, newS, newV, 1.0);
}

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
      r = v; g = t; b = p; break;
    case 1:
      r = q; g = v; b = p; break;
    case 2:
      r = p; g = v; b = t; break;
    case 3:
      r = p; g = q; b = v; break;
    case 4:
      r = t; g = p; b = v; break;
    default:
      r = v; g = p; b = q; break;
  }
  return Color.fromARGB((a * 255).toInt(), (r * 255).toInt(), (g * 255).toInt(), (b * 255).toInt());
}
