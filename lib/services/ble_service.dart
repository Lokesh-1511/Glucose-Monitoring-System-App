import 'dart:async';
import '../models/glucose_reading.dart';

/// Mock BLE service for device connection and glucose data streaming
/// In a real app, this would use the flutter_blue or flutter_reactive_ble package
class BLEService {
  static const String serviceUUID = "180D";
  static const String characteristicUUID = "2A18"; // Glucose characteristic

  bool isConnected = false;
  String? connectedDeviceId;
  String? connectedDeviceName;

  /// Available BLE devices (placeholder data)
  List<BLEDevice> discoveredDevices = [
    BLEDevice(id: 'device_1', name: 'Glucose Monitor 001', rssi: -45),
    BLEDevice(id: 'device_2', name: 'Glucose Monitor 002', rssi: -55),
    BLEDevice(id: 'device_3', name: 'Glucose Monitor 003', rssi: -60),
  ];

  /// Scan for available BLE devices
  Future<List<BLEDevice>> scanDevices({Duration timeout = const Duration(seconds: 5)}) async {
    print('Scanning for BLE devices...');
    
    // Simulate scanning delay
    await Future.delayed(const Duration(seconds: 2));
    
    print('Found ${discoveredDevices.length} devices');
    return discoveredDevices;
  }

  /// Connect to a specific BLE device
  Future<bool> connectToDevice(String deviceId) async {
    try {
      print('Connecting to device: $deviceId');
      
      // Simulate connection delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Find device in discovered list
      final device = discoveredDevices.firstWhere(
        (d) => d.id == deviceId,
        orElse: () => BLEDevice(id: deviceId, name: 'Unknown Device', rssi: -70),
      );
      
      isConnected = true;
      connectedDeviceId = deviceId;
      connectedDeviceName = device.name;
      
      print('Connected to: ${device.name}');
      return true;
    } catch (e) {
      print('Error connecting to device: $e');
      return false;
    }
  }

  /// Disconnect from current device
  Future<bool> disconnect() async {
    print('Disconnecting...');
    isConnected = false;
    connectedDeviceId = null;
    connectedDeviceName = null;
    print('Disconnected');
    return true;
  }

  /// Stream glucose values from the connected device
  Stream<GlucoseReading> streamGlucoseValues() async* {
    if (!isConnected) {
      throw Exception('Device not connected');
    }

    // Generate mock glucose readings every 5 seconds
    int counter = 0;
    while (isConnected) {
      await Future.delayed(const Duration(seconds: 5));
      
      counter++;
      final value = 80 + (counter % 3) * 15 + (counter % 2 == 0 ? 10 : -5).toDouble();
      
      yield GlucoseReading(
        timestamp: DateTime.now(),
        value: value.clamp(60, 180),
        source: 'BLE Device: $connectedDeviceName',
      );
    }
  }

  /// Get device connection status
  String getConnectionStatus() {
    if (isConnected && connectedDeviceName != null) {
      return 'Connected to $connectedDeviceName';
    }
    return 'Not connected';
  }
}

/// Model representing a BLE device
class BLEDevice {
  final String id;
  final String name;
  final int rssi; // Signal strength

  BLEDevice({
    required this.id,
    required this.name,
    required this.rssi,
  });

  String getSignalStrength() {
    if (rssi > -50) return 'Excellent';
    if (rssi > -60) return 'Good';
    if (rssi > -70) return 'Fair';
    return 'Weak';
  }
}
