import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import '../network/api_client.dart';
import 'ble_connection_state.dart';
import 'ble_constants.dart';
import 'ble_models.dart';
import 'ble_vital_buffer.dart';
import 'ring_protocol.dart';
import 'band_protocol.dart';
import '../ble/css_ring/css_ring_service.dart';
import '../health/apple_health_service.dart';

final bleManagerProvider = ChangeNotifierProvider<BleManager>((ref) {
  final api = ref.watch(apiClientProvider);
  final healthService = ref.watch(appleHealthServiceProvider);
  final buffer = BleVitalBuffer(api);
  // init() is async — fire it and let BleVitalBuffer guard writes until the box is ready
  buffer.init();
  return BleManager(buffer, api, healthService, ref);
});

class BleManager extends ChangeNotifier {

  final BleVitalBuffer _buffer;
  final ApiClient _api;
  final AppleHealthService _healthService;
  final Ref _ref;

  BleManager(this._buffer, this._api, this._healthService, this._ref);

  BluetoothDevice? _device;
  String? _deviceType; // 'ring' | 'band'
  BluetoothService? _cachedService;
  Timer? _pollTimer;
  
  int? _batteryLevel;
  int? _lastRssi;
  BleConnectionState _currentState = BleConnectionState.disconnected;

  BluetoothDevice? get connectedDevice => _device;
  int? get batteryLevel => _batteryLevel;
  int? get lastRssi => _lastRssi;
  BleConnectionState get currentState => _currentState;
  
  final _stateController = StreamController<BleConnectionState>.broadcast();
  Stream<BleConnectionState> get connectionStateStream => _stateController.stream;

  final _vitalController = StreamController<VitalReading>.broadcast();
  Stream<VitalReading> get vitals => _vitalController.stream;

  Stream<VitalReading> streamVitals(BluetoothDevice device) => vitals;

  void setDeviceType(String type) {
    _deviceType = type;
  }

  Stream<List<ScanResult>> scan({
    Duration timeout = const Duration(seconds: 20),
  }) {
    _startScanSafe(timeout);
    return FlutterBluePlus.scanResults;
  }

  Future<void> _startScanSafe(Duration timeout) async {
    try {
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
      await FlutterBluePlus.startScan(
        timeout: timeout,
        // Removed removeIfGone as it can be unreliable on some devices.
        // Removed androidUsesFineLocation as Android 12+ with neverForLocation does not need it.
      );
    } catch (e) {
      debugPrint('BLE startScan error: $e');
    }
  }

  Future<void> stopScan() async {
    try {
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
    } catch (_) {}
  }

  /// Auto-reconnect: scans for the last known device by its remote ID.
  /// No name filtering — matches purely by MAC/ID so any BLE device works.
  Future<BluetoothDevice?> scanForDevice({
    required String deviceType,
    String? targetDeviceId,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    _emit(BleConnectionState.scanning);

    BluetoothDevice? found;
    final expectedId = targetDeviceId ??
        (Hive.isBoxOpen('settings') ? Hive.box('settings').get('last_device_id') as String? : null);

    if (expectedId == null) {
      _emit(BleConnectionState.error);
      return null;
    }

    try {
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
      await FlutterBluePlus.startScan(timeout: timeout);
    } catch (e) {
      debugPrint('BLE scanForDevice error: $e');
    }
    
    await for (final result in FlutterBluePlus.scanResults) {
      for (final r in result) {
        if (r.device.remoteId.str == expectedId) {
          found = r.device;
          try {
            await FlutterBluePlus.stopScan();
          } catch (_) {}
          break;
        }
      }
      if (found != null) break;
    }

    if (found == null) {
      _emit(BleConnectionState.error);
      return null;
    }

    _device = found;
    _deviceType = deviceType;
    return found;
  }

  Future<void> connect(BluetoothDevice device) async {
    _emit(BleConnectionState.connecting);
    try {
      await device.connect(license: License.nonprofit);

      if (Platform.isAndroid) {
        try {
          await device.requestMtu(512);
        } catch (_) {}
      }

      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _cachedService = null;
          _pollTimer?.cancel();
          _emit(BleConnectionState.reconnecting);
          _reconnect();
        }
      });

      _emit(BleConnectionState.discoveringServices);
      await _discoverAndSubscribe(device);
      _emit(BleConnectionState.connected);
    } catch (_) {
      _emit(BleConnectionState.error);
      rethrow;
    }
  }

  Future<void> _discoverAndSubscribe(BluetoothDevice device) async {
    _emit(BleConnectionState.subscribing);
    final services = await device.discoverServices();

    if (services.isEmpty) {
      throw BleParseException('No services found on device');
    }

    BluetoothService? primaryService;
    
    // Subscribe to ONLY known notifiable characteristics
    for (final service in services) {
      // Pick the first service with characteristics as our cached service fallback
      if (primaryService == null && service.characteristics.isNotEmpty) {
        primaryService = service;
      }
      
      for (final char in service.characteristics) {
        final uuid = char.uuid.toString().toUpperCase();
        
        // Listen to notifications
        if (char.properties.notify || char.properties.indicate) {
          bool shouldSubscribe = false;
          if (_deviceType == 'ring') {
            shouldSubscribe = [RingUUIDs.heartRateChar, RingUUIDs.spo2Char, RingUUIDs.skinTempChar, RingUUIDs.stepsChar, RingUUIDs.hrvChar].contains(uuid);
          } else if (_deviceType == 'band') {
            shouldSubscribe = [BandUUIDs.heartRateChar, BandUUIDs.hrvChar, BandUUIDs.respiratoryRateChar, BandUUIDs.strainChar, BandUUIDs.recoveryScoreChar, BandUUIDs.stepsChar, BandUUIDs.caloriesChar].contains(uuid);
          }
          if (shouldSubscribe) {
            try {
              await char.setNotifyValue(true);
              char.onValueReceived.listen((bytes) => _handleNotification(uuid, bytes));
            } catch (e) {
              debugPrint('Failed to subscribe to $uuid: $e');
            }
          }
        }
      }
    }

    if (primaryService == null) {
      throw BleParseException('No viable characteristics found on device');
    }
    
    _cachedService = primaryService;

    try {
      await _readStaticData(services);
    } catch (e) {
      debugPrint('Read static data failed: $e');
    }
    
    // Connect to the new CssRingService data pipeline
    debugPrint('[SmartVital] Calling onRingConnected for ${device.platformName}');
    final ringService = _ref.read(cssRingServiceProvider.notifier);
    ringService.setBuffer(_buffer);
    await ringService.onRingConnected(device, services);
  }

  void _handleNotification(String uuid, List<int> bytes) {
    if (bytes.isEmpty) return;
    final serial = _device?.remoteId.str;
    try {
      VitalReading? reading;
      if (_deviceType == 'ring') {
        reading = switch (uuid) {
          RingUUIDs.heartRateChar => VitalReading.fromHeartRate(RingProtocol.parseHeartRate(bytes), deviceSerial: serial),
          RingUUIDs.spo2Char      => VitalReading.fromSpO2(RingProtocol.parseSpO2(bytes), deviceSerial: serial),
          RingUUIDs.skinTempChar  => () {
            final r = RingProtocol.parseSkinTemp(bytes);
            if (Hive.isBoxOpen('settings')) {
              final baseline = r.celsius - r.deviationFromBaseline;
              Hive.box('settings').put('skin_temp_baseline', baseline);
            }
            return VitalReading.fromSkinTemp(r, deviceSerial: serial);
          }(),
          RingUUIDs.stepsChar     => VitalReading.fromSteps(RingProtocol.parseSteps(bytes), deviceSerial: serial),
          RingUUIDs.hrvChar       => VitalReading.fromHrv(RingProtocol.parseHrv(bytes), deviceSerial: serial),
          _ => null,
        };
      } else {
        reading = switch (uuid) {
          BandUUIDs.heartRateChar       => VitalReading.fromHeartRate(BandProtocol.parseHeartRate(bytes), deviceSerial: serial),
          BandUUIDs.hrvChar             => VitalReading.fromHrv(BandProtocol.parseHrv(bytes), deviceSerial: serial),
          BandUUIDs.respiratoryRateChar => VitalReading.fromRespiratoryRate(BandProtocol.parseRespiratoryRate(bytes), deviceSerial: serial),
          BandUUIDs.strainChar          => VitalReading.fromStrain(BandProtocol.parseStrain(bytes), deviceSerial: serial),
          BandUUIDs.recoveryScoreChar   => VitalReading.fromRecovery(BandProtocol.parseRecovery(bytes), deviceSerial: serial),
          BandUUIDs.stepsChar           => VitalReading.fromSteps(RingProtocol.parseSteps(bytes), deviceSerial: serial),
          BandUUIDs.caloriesChar        => VitalReading.fromCalories(BandProtocol.parseCalories(bytes), deviceSerial: serial),
          BandUUIDs.vo2MaxChar          => VitalReading(metricType: 'vo2max', value: BandProtocol.parseVo2Max(bytes).value, timestamp: DateTime.now(), deviceSerial: serial),
          _ => null,
        };
      }

      if (reading != null) {
        _vitalController.add(reading);
        _buffer.add(reading);
        _healthService.syncVitalReading(reading);

        // Bridge heart_rate readings to CssRingService state so the UI can
        // display live BPM. This is the SOLE notification path for SmartVital
        // Ring HR data (avoids double-subscription bugs).
        if (reading.metricType == 'heart_rate') {
          try {
            _ref.read(cssRingServiceProvider.notifier).onLiveHeartRate(reading.value.toInt());
          } catch (e) {
            debugPrint('[BleManager] Failed to bridge HR to CssRingService: $e');
          }
        }
      }
    } on BleParseException catch (e) {
      Logger().w('BLE parse error [$uuid]: $e');
    }
  }

  Future<void> _readStaticData(List<BluetoothService> services) async {
    final batteryCharId = _deviceType == 'ring' ? RingUUIDs.batteryChar : BandUUIDs.batteryChar;
    final infoCharId    = _deviceType == 'ring' ? RingUUIDs.deviceInfoChar : BandUUIDs.deviceInfoChar;
    final sleepCharId   = _deviceType == 'ring' ? RingUUIDs.sleepDataChar : BandUUIDs.sleepDataChar;
    final serial        = _device?.remoteId.str;

    for (final service in services) {
      for (final char in service.characteristics) {
        final uuid = char.uuid.toString().toUpperCase();
        if (!char.properties.read) continue;
        
        // Only attempt to read characteristics we explicitly need
        if (uuid != batteryCharId && uuid != infoCharId && uuid != sleepCharId) continue;
        
        final bytes = await char.read();

      if (uuid == batteryCharId) {
        final level = bytes.isNotEmpty ? bytes[0] : 0;
        _batteryLevel = level;
        notifyListeners();
        _buffer.add(VitalReading(metricType: 'battery', value: level, timestamp: DateTime.now(), deviceSerial: serial));
        if (serial != null) {
          await _api.patchMap('/devices/serial/$serial', data: {
            'batteryLevel': level,
            'lastSyncAt': DateTime.now().toIso8601String(),
          });
        }
      } else if (uuid == infoCharId) {
        final info = _deviceType == 'ring'
            ? RingProtocol.parseDeviceInfo(bytes)
            : BandProtocol.parseDeviceInfo(bytes);
        if (serial != null) {
          await _api.patchMap('/devices/serial/$serial', data: {
            'firmwareVersion': info.firmwareVersion,
            'deviceName': info.deviceName,
            'lastSyncAt': DateTime.now().toIso8601String(),
          });
        }
      } else if (uuid == sleepCharId) {
        final sleep = RingProtocol.parseSleep(bytes);
        final reading = VitalReading.fromSleep(sleep, deviceSerial: serial);
        _buffer.add(reading);
        _healthService.syncVitalReading(reading);
      }
      }
    }
  }


  Future<void> _reconnect() async {
    if (_device == null) { _emit(BleConnectionState.error); return; }
    await Future.delayed(const Duration(seconds: 3));
    int attempts = 0;
    while (attempts < 5) {
      if (_device == null) { _emit(BleConnectionState.error); return; }
      try {
        await connect(_device!);
        return;
      } catch (_) {
        attempts++;
        if (_device == null) return;
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    _emit(BleConnectionState.error);
  }

  Future<void> forgetDevice() async {
    _pollTimer?.cancel();
    if (_device != null) {
      await _device!.disconnect();
    }
    _device = null;
    _cachedService = null;
    _batteryLevel = null;
    _lastRssi = null;
    _deviceType = null;
    notifyListeners();
    
    if (Hive.isBoxOpen('settings')) {
      final settings = Hive.box('settings');
      await settings.delete('last_device_id');
      await settings.delete('last_device_type');
    }
    
    // Also disconnect the secondary ring service if active
    try {
      _ref.read(cssRingServiceProvider.notifier).disconnect();
    } catch (_) {}
    
    _emit(BleConnectionState.disconnected);
  }

  Future<void> sendHapticCommand() async => _sendCommand([0x01]);
  Future<void> requestFullSync() async => _sendCommand([0x02]);
  Future<void> startRealTimeMode() async => _sendCommand([0x03]);
  Future<void> stopRealTimeMode() async => _sendCommand([0x04]);

  Future<void> _sendCommand(List<int> command) async {
    if (_device == null) return;
    final charId = _deviceType == 'ring' ? RingUUIDs.commandChar.toUpperCase() : BandUUIDs.commandChar.toUpperCase();
    final service = _cachedService ?? (await _device!.discoverServices()).firstWhere(
      (s) => s.uuid.toString().toUpperCase() == (_deviceType == 'ring' ? RingUUIDs.serviceUUID.toUpperCase() : BandUUIDs.serviceUUID.toUpperCase()),
      orElse: () => throw BleParseException('SmartVital service not found on device'),
    );
    for (final char in service.characteristics) {
      if (char.uuid.toString().toUpperCase() == charId && char.properties.write) {
        await char.write(command, withoutResponse: false);
        return;
      }
    }
  }

  Future<int> readCurrentRssi() async {
    if (_device == null || _currentState != BleConnectionState.connected) return -100;
    try {
      final rssi = await _device!.readRssi();
      _lastRssi = rssi;
      notifyListeners();
      return rssi;
    } catch (_) {
      return -100;
    }
  }

  void _emit(BleConnectionState state) {
    _currentState = state;
    _stateController.add(state);
    notifyListeners();
  }
  
  @override
  void dispose() {
    _pollTimer?.cancel();
    _stateController.close();
    _vitalController.close();
    _buffer.dispose();
    super.dispose();
  }
}
