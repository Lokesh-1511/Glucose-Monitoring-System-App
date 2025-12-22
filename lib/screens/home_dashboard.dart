import 'package:flutter/material.dart';
import '../widgets/glucose_gauge.dart';
import '../widgets/common_widgets.dart';
import 'dart:math';

/// Home dashboard displaying current glucose level and navigation options
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({Key? key}) : super(key: key);

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  double currentGlucose = 112.0;
  double previousGlucose = 108.0;
  bool isRefreshing = false;
  DateTime lastReadingTime = DateTime.now();
  List<double> glucoseReadings = [105, 110, 115, 112]; // Last 4 readings

  /// Calculate glucose trend
  String _getGlucoseTrend() {
    double change = currentGlucose - previousGlucose;
    if (change.abs() < 5) {
      return 'Stable';
    } else if (change > 0) {
      return 'Rising';
    } else {
      return 'Falling';
    }
  }

  /// Get status color based on glucose level
  Color _getStatusColor() {
    if (currentGlucose < 70 || currentGlucose > 180) {
      return Colors.red;
    } else if (currentGlucose < 100 || currentGlucose > 140) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  /// Get status text based on glucose level
  String _getStatusText() {
    if (currentGlucose < 70) {
      return 'Low - Seek medical attention';
    } else if (currentGlucose < 100) {
      return 'Fasting - Acceptable';
    } else if (currentGlucose <= 140) {
      return 'Normal - Good range';
    } else if (currentGlucose <= 180) {
      return 'Elevated - Monitor';
    } else {
      return 'High - Seek medical attention';
    }
  }

  /// Simulate refreshing glucose data
  void _refreshGlucoseData() {
    setState(() {
      isRefreshing = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          previousGlucose = currentGlucose;
          // Simulate new reading between 70 and 180 with some trend
          double trend = (Random().nextDouble() - 0.5) * 20;
          currentGlucose = (currentGlucose + trend).clamp(70.0, 180.0);
          glucoseReadings.add(currentGlucose);
          if (glucoseReadings.length > 12) {
            glucoseReadings.removeAt(0); // Keep last 12 readings
          }
          lastReadingTime = DateTime.now();
          isRefreshing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Glucose: ${currentGlucose.toStringAsFixed(1)} mg/dL',
            ),
            backgroundColor: _getStatusColor(),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Glucose Monitor',
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Current time and date
            Text(
              'Today, ${DateTime.now().day} ${_getMonthName(DateTime.now().month)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),

            // Glucose gauge
            GlucoseGauge(value: currentGlucose),
            const SizedBox(height: 24),

            // Status indicator card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                border: Border.all(
                  color: _getStatusColor(),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getStatusColor(),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getStatusText(),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(),
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Trend: ${_getGlucoseTrend()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Refresh button
            PrimaryButton(
              label: 'Refresh Reading',
              isLoading: isRefreshing,
              onPressed: _refreshGlucoseData,
            ),
            const SizedBox(height: 30),

            // Last reading info with trend
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Reading',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Value',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${currentGlucose.toStringAsFixed(0)} mg/dL',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Time',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getCurrentTime(),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Change: ${(currentGlucose - previousGlucose).toStringAsFixed(1)} mg/dL',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

/// Navigation card widget for quick access to different screens
// Quick Access cards removed in favor of bottom navigation
