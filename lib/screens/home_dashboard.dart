import 'package:flutter/material.dart';
import '../widgets/glucose_gauge.dart';
import '../widgets/common_widgets.dart';
import 'history_page.dart';
import 'profile_page.dart';
import 'device_connection_page.dart';
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

            // Navigation section
            Text(
              'Quick Access',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Grid of navigation buttons with icons
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _NavCard(
                  icon: Icons.history,
                  label: 'History',
                  description: 'View trends',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryPage()),
                  ),
                ),
                _NavCard(
                  icon: Icons.person,
                  label: 'Profile',
                  description: 'Calibrate',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  ),
                ),
                _NavCard(
                  icon: Icons.bluetooth_connected,
                  label: 'BLE Device',
                  description: 'Connect',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DeviceConnectionPage()),
                  ),
                ),
                _NavCard(
                  icon: Icons.settings,
                  label: 'Settings',
                  description: 'Configure',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings coming soon')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
class _NavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? description;
  final VoidCallback onTap;

  const _NavCard({
    Key? key,
    required this.icon,
    required this.label,
    this.description,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
