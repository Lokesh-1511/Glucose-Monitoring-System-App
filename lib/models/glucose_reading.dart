/// Model representing a single glucose reading from the monitoring device
class GlucoseReading {
  final DateTime timestamp;
  final double value; // in mg/dL
  final String? source; // e.g., 'BLE Device', 'Manual Entry'

  GlucoseReading({
    required this.timestamp,
    required this.value,
    this.source,
  });

  /// Convert GlucoseReading to JSON
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'value': value,
    'source': source ?? 'BLE Device',
  };

  /// Create GlucoseReading from JSON
  factory GlucoseReading.fromJson(Map<String, dynamic> json) => GlucoseReading(
    timestamp: DateTime.parse(json['timestamp'] as String),
    value: (json['value'] as num).toDouble(),
    source: json['source'] as String?,
  );

  @override
  String toString() => 'GlucoseReading(value: $value mg/dL, time: $timestamp)';
}
