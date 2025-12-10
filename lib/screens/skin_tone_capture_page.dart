import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../widgets/common_widgets.dart';
import 'skin_tone_adjust_page.dart';

/// First screen in skin tone calibration flow
/// Shows camera preview with overlay for wrist placement
class SkinToneCapturePage extends StatefulWidget {
  const SkinToneCapturePage({Key? key}) : super(key: key);

  @override
  State<SkinToneCapturePage> createState() => _SkinToneCaptureCapturePageState();
}

class _SkinToneCaptureCapturePageState extends State<SkinToneCapturePage> {
  bool _isCapturing = false;

  /// Simulate camera capture
  void _captureImage() {
    setState(() {
      _isCapturing = true;
    });

    // Simulate camera capture delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        // Generate a mock image (in a real app, this would come from the camera)
        final mockImageBytes = _generateMockImageBytes();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SkinToneAdjustPage(
              imageBytes: mockImageBytes,
            ),
          ),
        );
      }
    });
  }

  /// Generate mock image bytes for demonstration
  Uint8List _generateMockImageBytes() {
    // Create a simple mock image (100x100 pixels)
    // In a real app, this would be actual camera image
    List<int> pixels = [];
    for (int i = 0; i < 100 * 100; i++) {
      // Brownish/tan color for skin tone demo
      pixels.add(210); // R
      pixels.add(180); // G
      pixels.add(140); // B
      pixels.add(255); // A
    }
    return Uint8List.fromList(pixels);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Capture Skin Tone',
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Camera preview placeholder
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.grey.shade800,
                      child: Image.asset(
                        'assets/camera_placeholder.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade800,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.camera_alt,
                                  size: 60,
                                  color: Colors.white38,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Camera Preview',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.white38,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Overlay square for wrist placement
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.green,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    // Instructions
                    Positioned(
                      bottom: 80,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Position wrist in box',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Capture button
          Padding(
            padding: const EdgeInsets.all(24),
            child: PrimaryButton(
              label: _isCapturing ? 'Capturing...' : 'Capture Image',
              isLoading: _isCapturing,
              onPressed: _isCapturing ? () {} : _captureImage,
              width: 200,
              height: 60,
            ),
          ),
        ],
      ),
    );
  }
}
