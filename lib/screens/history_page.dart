import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../widgets/common_widgets.dart';
import '../models/glucose_reading.dart';

/// History page displaying glucose trends and analytics
class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int selectedTab = 0;

  // Dummy data for demonstration
  late List<GlucoseReading> allReadings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generateDummyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Generate dummy glucose readings for demonstration
  void _generateDummyData() {
    allReadings = [];
    final now = DateTime.now();

    for (int i = 0; i < 144; i++) {
      // 144 readings = 24 hours at every 10 minutes
      final time = now.subtract(Duration(minutes: i * 10));
      final baseValue = 100.0 + (i % 30) - 15; // Oscillate around 100
      final value = ((baseValue + (i % 7).toDouble()).clamp(60, 180)) as double;

      allReadings.add(GlucoseReading(
        timestamp: time,
        value: value,
        source: 'BLE Device',
      ));
    }
    allReadings = allReadings.reversed.toList();
  }

  /// Get readings for selected tab (daily, weekly, monthly)
  List<GlucoseReading> _getFilteredReadings(int tabIndex) {
    final now = DateTime.now();
    switch (tabIndex) {
      case 0: // Daily
        return allReadings
            .where((r) => r.timestamp.isAfter(now.subtract(const Duration(days: 1))))
            .toList();
      case 1: // Weekly
        return allReadings
            .where((r) => r.timestamp.isAfter(now.subtract(const Duration(days: 7))))
            .toList();
      case 2: // Monthly
        return allReadings;
      default:
        return allReadings;
    }
  }

  /// Calculate analytics for current tab
  Map<String, double> _calculateAnalytics(List<GlucoseReading> readings) {
    if (readings.isEmpty) {
      return {
        'average': 0.0,
        'highest': 0.0,
        'lowest': 0.0,
        'variability': 0.0,
      };
    }

    final values = readings.map((r) => r.value).toList();
    final average = values.reduce((a, b) => a + b) / values.length;
    final highest = values.reduce((a, b) => a > b ? a : b);
    final lowest = values.reduce((a, b) => a < b ? a : b);

    // Calculate coefficient of variation (variability)
    final variance = values
        .map((v) => (v - average) * (v - average))
        .reduce((a, b) => a + b) / values.length;
    final stdDev = variance.isFinite ? sqrt(variance) : 0.0;
    final variability = average > 0 ? (stdDev / average * 100) : 0.0;

    return {
      'average': average,
      'highest': highest,
      'lowest': lowest,
      'variability': variability,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Glucose History',
      ),
      body: Column(
        children: [
          // Tab bar
          TabBar(
            controller: _tabController,
            onTap: (index) {
              setState(() {
                selectedTab = index;
              });
            },
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Daily'),
              Tab(text: 'Weekly'),
              Tab(text: 'Monthly'),
            ],
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(0),
                _buildTabContent(1),
                _buildTabContent(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(int tabIndex) {
    final filteredReadings = _getFilteredReadings(tabIndex);
    final analytics = _calculateAnalytics(filteredReadings);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Line chart
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Glucose Trend',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (filteredReadings.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: _buildChart(filteredReadings),
                  )
                else
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        'No data available',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Analytics summary
          Text(
            'Analytics Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _AnalyticsCard(
                label: 'Average',
                value: analytics['average']!.toStringAsFixed(1),
                unit: 'mg/dL',
              ),
              _AnalyticsCard(
                label: 'Highest',
                value: analytics['highest']!.toStringAsFixed(0),
                unit: 'mg/dL',
              ),
              _AnalyticsCard(
                label: 'Lowest',
                value: analytics['lowest']!.toStringAsFixed(0),
                unit: 'mg/dL',
              ),
              _AnalyticsCard(
                label: 'Variability',
                value: analytics['variability']!.toStringAsFixed(1),
                unit: '%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build line chart from glucose readings
  Widget _buildChart(List<GlucoseReading> readings) {
    if (readings.isEmpty) {
      return const Center(child: Text('No data'));
    }

    // Sample data for performance (show every nth reading)
    final step = (readings.length / 20).ceil();
    final sampledReadings = [
      for (int i = 0; i < readings.length; i += step)
        readings[i],
    ];

    final spots = List.generate(
      sampledReadings.length,
      (index) => FlSpot(
        index.toDouble(),
        sampledReadings[index].value,
      ),
    );

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        minY: 60,
        maxY: 180,
      ),
    );
  }
}

/// Analytics card widget
class _AnalyticsCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _AnalyticsCard({
    Key? key,
    required this.label,
    required this.value,
    required this.unit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unit,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

extension on double {
  double sqrt() => pow(this, 0.5) as double;
}
