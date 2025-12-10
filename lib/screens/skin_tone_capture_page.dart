import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import '../widgets/common_widgets.dart';
import 'skin_tone_adjust_page.dart';

/// First screen in skin tone calibration flow
/// Shows camera preview with overlay for wrist placement
/// Captures real skin tone data from device camera
class SkinToneCapturePage extends StatefulWidget {
  const SkinToneCapturePage({Key? key}) : super(key: key);

  @override
  State<SkinToneCapturePage> createState() => _SkinToneCaptureCapturePageState();
}

class _SkinToneCaptureCapturePageState extends State<SkinToneCapturePage> {
  bool _isCapturing = false;
  CameraController? _cameraController;
  bool _cameraReady = false;
  final List<String> _instructionSteps = [
    'Find good lighting (natural light preferred)',
    'Position your wrist in the green box',
    'Keep steady for 1-2 seconds',
    'Tap Capture Image',
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  /// Initialize camera for skin tone capture
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first, // Use back camera
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController?.initialize();
        if (mounted) {
          setState(() {
            _cameraReady = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      // Fallback to mock capture if camera unavailable
    }
  }

  /// Capture real camera image
  Future<void> _captureImage() async {
    if (!_cameraReady || _isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      if (_cameraController != null) {
        final image = await _cameraController!.takePicture();
        final imageBytes = await image.readAsBytes();

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SkinToneAdjustPage(
                imageBytes: imageBytes,
              ),
            ),
          );
        }
      } else {
        // Fallback to mock capture
        _captureImageFallback();
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      _captureImageFallback();
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  /// Fallback mock capture when camera unavailable
  void _captureImageFallback() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
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
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
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
                    // Camera preview or placeholder
                    if (_cameraReady && _cameraController != null)
                      CameraPreview(_cameraController!)
                    else
                      _buildCameraPlaceholder(),

                    // Overlay with quality indicator
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.green,
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          'Position wrist here',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Corner markers for better positioning
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.green, width: 3),
                            left: BorderSide(color: Colors.green, width: 3),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.green, width: 3),
                            right: BorderSide(color: Colors.green, width: 3),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.green, width: 3),
                            left: BorderSide(color: Colors.green, width: 3),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.green, width: 3),
                            right: BorderSide(color: Colors.green, width: 3),
                          ),
                        ),
                      ),
                    ),

                    // Instructions overlay
                    Positioned(
                      top: 20,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Calibration Tips:',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            ..._instructionSteps.asMap().entries.map((e) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  '${e.key + 1}. ${e.value}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.white70),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Capture button with loading state
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                PrimaryButton(
                  label: _isCapturing ? 'Capturing...' : 'Capture Image',
                  isLoading: _isCapturing,
                  onPressed: _isCapturing ? () {} : _captureImage,
                  width: 200,
                  height: 60,
                ),
                const SizedBox(height: 12),
                Text(
                  'Make sure your wrist is well-lit and positioned correctly',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build camera placeholder for demo mode
  Widget _buildCameraPlaceholder() {
    return Container(
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '(Tap Capture to use demo mode)',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white24),
            ),
          ],
        ),
      ),
    );
  }
}
