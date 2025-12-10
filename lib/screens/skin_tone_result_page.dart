import 'package:flutter/material.dart';
import 'dart:math';
import '../widgets/common_widgets.dart';
import '../services/data_storage_service.dart';
import '../models/user_profile.dart';

/// Third screen in skin tone calibration flow
/// Displays final results and saves to profile
class SkinToneResultPage extends StatefulWidget {
  final Color color;
  final double melaninIndex;

  const SkinToneResultPage({
    Key? key,
    required this.color,
    required this.melaninIndex,
  }) : super(key: key);

  @override
  State<SkinToneResultPage> createState() => _SkinToneResultPageState();
}

class _SkinToneResultPageState extends State<SkinToneResultPage> {
  bool _isSaving = false;

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
    final lab = _rgbToLab(widget.color);

    return Scaffold(
      appBar: AppTopBar(
        title: 'Skin Tone Results',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color preview
            Center(
              child: Column(
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: widget.color,
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
                    'Captured Skin Tone',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // RGB Values
            _ResultCard(
              title: 'RGB Values',
              children: [
                _ResultRow(
                  label: 'Red',
                  value: widget.color.red.toString(),
                ),
                _ResultRow(
                  label: 'Green',
                  value: widget.color.green.toString(),
                ),
                _ResultRow(
                  label: 'Blue',
                  value: widget.color.blue.toString(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lab Values
            _ResultCard(
              title: 'Lab Color Space',
              children: [
                _ResultRow(
                  label: 'L* (Lightness)',
                  value: lab['L']!.toStringAsFixed(2),
                ),
                _ResultRow(
                  label: 'a* (Green-Red)',
                  value: lab['a']!.toStringAsFixed(2),
                ),
                _ResultRow(
                  label: 'b* (Blue-Yellow)',
                  value: lab['b']!.toStringAsFixed(2),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Melanin Index
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
                  Text(
                    'This index represents the melanin concentration in your skin and will be used to calibrate glucose readings for improved accuracy.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            PrimaryButton(
              label: 'Save to Profile',
              isLoading: _isSaving,
              onPressed: _saveSkinTone,
            ),
          ],
        ),
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

  const _ResultRow({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}

double _pow(double base, double exponent) {
  return pow(base, exponent).toDouble();
}
