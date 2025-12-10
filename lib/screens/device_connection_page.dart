import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';
import '../services/ble_service.dart';
import '../models/glucose_reading.dart';

/// Device connection page for BLE device management
class DeviceConnectionPage extends StatefulWidget {
  const DeviceConnectionPage({Key? key}) : super(key: key);

  @override
  State<DeviceConnectionPage> createState() => _DeviceConnectionPageState();
}

class _DeviceConnectionPageState extends State<DeviceConnectionPage> {
  late BLEService _bleService;
  bool _isScanning = false;
  bool _isConnecting = false;
  List<BLEDevice> _discoveredDevices = [];
  String? _selectedDeviceId;
  bool _isConnected = false;
  Stream<GlucoseReading>? _glucoseStream;

  @override
  void initState() {
    super.initState();
    _bleService = BLEService();
  }

  /// Scan for available BLE devices
  Future<void> _scanForDevices() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final devices = await _bleService.scanDevices();
      setState(() {
        _discoveredDevices = devices;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${devices.length} device(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning devices: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  /// Connect to selected device
  Future<void> _connectToDevice(String deviceId) async {
    setState(() {
      _isConnecting = true;
      _selectedDeviceId = deviceId;
    });

    try {
      final success = await _bleService.connectToDevice(deviceId);
      if (success) {
        setState(() {
          _isConnected = true;
          _glucoseStream = _bleService.streamGlucoseValues();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Connected to ${_bleService.connectedDeviceName}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error connecting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  /// Disconnect from device
  Future<void> _disconnect() async {
    await _bleService.disconnect();
    setState(() {
      _isConnected = false;
      _glucoseStream = null;
      _selectedDeviceId = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Disconnected'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'BLE Device Connection',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isConnected) ...[
              // Connection status
              AppCard(
                child: Row(
                  children: [
                    const StatusIndicator(
                      isConnected: false,
                      label: 'Not Connected',
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Select a device to begin',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Scan button
              PrimaryButton(
                label: _isScanning ? 'Scanning...' : 'Scan for Devices',
                isLoading: _isScanning,
                onPressed: _scanForDevices,
              ),
              const SizedBox(height: 24),

              if (_discoveredDevices.isNotEmpty) ...[
                // Available devices
                Text(
                  'Available Devices',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _discoveredDevices.length,
                  itemBuilder: (context, index) {
                    final device = _discoveredDevices[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DeviceListItem(
                        device: device,
                        isSelected: _selectedDeviceId == device.id,
                        isConnecting: _isConnecting && _selectedDeviceId == device.id,
                        onTap: () => _connectToDevice(device.id),
                      ),
                    );
                  },
                ),
              ],
            ] else ...[
              // Connected state
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const StatusIndicator(
                          isConnected: true,
                          label: 'Connected',
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _bleService.connectedDeviceName ?? 'Device',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SecondaryButton(
                      label: 'Disconnect',
                      onPressed: _disconnect,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Live glucose readings
              Text(
                'Live Glucose Readings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (_glucoseStream != null)
                StreamBuilder<GlucoseReading>(
                  stream: _glucoseStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return AppCard(
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 40,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Error receiving data',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const AppCard(
                        child: SizedBox(
                          height: 60,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    }

                    final reading = snapshot.data!;
                    return _GlucoseReadingCard(reading: reading);
                  },
                ),
            ],

            const SizedBox(height: 24),

            // Device information section
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Device Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    label: 'Status',
                    value: _bleService.getConnectionStatus(),
                  ),
                  _InfoRow(
                    label: 'Device Name',
                    value: _bleService.connectedDeviceName ?? 'N/A',
                  ),
                  _InfoRow(
                    label: 'Service UUID',
                    value: BLEService.serviceUUID,
                  ),
                  _InfoRow(
                    label: 'Characteristic UUID',
                    value: BLEService.characteristicUUID,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Device list item widget
class _DeviceListItem extends StatelessWidget {
  final BLEDevice device;
  final bool isSelected;
  final bool isConnecting;
  final VoidCallback onTap;

  const _DeviceListItem({
    Key? key,
    required this.device,
    required this.isSelected,
    required this.isConnecting,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isConnecting ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AppCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.signal_cellular_4_bar,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${device.rssi} dBm (${device.getSignalStrength()})',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isConnecting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Glucose reading card widget
class _GlucoseReadingCard extends StatelessWidget {
  final GlucoseReading reading;

  const _GlucoseReadingCard({Key? key, required this.reading}) : super(key: key);

  Color _getColor(double value) {
    if (value < 70) return Colors.red;
    if (value <= 100) return Colors.green;
    if (value <= 140) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(reading.value);

    return AppCard(
      child: Column(
        children: [
          Text(
            'Current Reading',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${reading.value.toStringAsFixed(0)} mg/dL',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reading.timestamp.toString().split('.')[0],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Information row widget
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
