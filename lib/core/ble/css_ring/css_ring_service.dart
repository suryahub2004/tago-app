import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'css_ring_constants.dart';
import 'css_ring_models.dart';
import 'css_ring_parser.dart';
import '../../bluetooth/ble_vital_buffer.dart';
import '../../bluetooth/ble_models.dart';
import '../../bluetooth/ble_constants.dart';
import '../../bluetooth/ring_protocol.dart';

import '../../health/apple_health_service.dart';

final cssRingServiceProvider =
    StateNotifierProvider<CssRingService, CssRingState>(
  (ref) {
    final healthService = ref.watch(appleHealthServiceProvider);
    return CssRingService(healthService);
  },
);

class CssRingService extends StateNotifier<CssRingState> {
  final AppleHealthService _healthService;
  CssRingService(this._healthService) : super(const CssRingState());

  final List<StreamSubscription> _subs = [];
  BluetoothCharacteristic? _commandChar;
  final List<BluetoothCharacteristic> _commandChars = [];
  BleVitalBuffer? _buffer;
  String? _deviceSerial;
  Timer? _periodicTimer;
  Timer? _measurementTimer;
  Timer? _safetyTimeoutTimer;
  bool _isSmartVitalRing = false;
  int _workingCmdIndex = -1; // Index of the working start command (-1 = unknown, probe all)
  final List<List<int>> _candidates = [];
  bool _hasReceivedHrNotification = false;
  
  // Batch processing state
  final List<CssRingVitals> _hrBatch = [];
  DateTime? _lastSyncedTimestamp;

  /// Set the buffer so CSS ring data is also uploaded to the backend.
  void setBuffer(BleVitalBuffer buffer) => _buffer = buffer;

  // ── Called from existing connect flow ──────────────────────────────
  // Hooked in BleManager after discoverServices() succeeds.
  Future<void> onRingConnected(
    BluetoothDevice device,
    List<BluetoothService> services,
  ) async {
    _cleanupSubscriptions();
    _isSmartVitalRing = false;

    _deviceSerial = device.remoteId.str;
    state = state.copyWith(isConnected: true, isConnecting: false, error: null);

    await _setupCharacteristics(services);

    // Watch disconnection (do NOT attempt reconnect here; BleManager handles it)
    _subs.add(device.connectionState.listen((s) {
      if (s == BluetoothConnectionState.disconnected) {
        state = state.copyWith(isConnected: false, isMonitoring: false);
      }
    }));

    await Future.delayed(const Duration(milliseconds: 500));
    await _syncTime();
    // Do NOT auto-start the live optical sensor here.
    // The user will manually start it via the UI to prevent battery drain and disconnects.
  }

  /// Cancel all stream subscriptions without resetting state.
  /// Used on reconnect to avoid duplicate listeners.
  void _cleanupSubscriptions() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _commandChar = null;
  }

  Future<void> _setupCharacteristics(List<BluetoothService> services) async {
    _commandChars.clear();

    // Debug dump all services and characteristics discovered
    for (final service in services) {
      final sId = service.serviceUuid.str.toUpperCase();
      debugPrint('[Ring] Discovered Service: $sId');
      for (final char in service.characteristics) {
        final cId = char.characteristicUuid.str.toUpperCase();
        debugPrint('[Ring]   Char: $cId properties: write=${char.properties.write}, writeWithoutResponse=${char.properties.writeWithoutResponse}, notify=${char.properties.notify}');
      }
    }

    for (final service in services) {
      final sId = service.serviceUuid.str.toUpperCase();

      // CSS Ring health data service
      if (sId == CssRingConstants.serviceUuid.toUpperCase()) {
        for (final char in service.characteristics) {
          final cId = char.characteristicUuid.str.toUpperCase();
          // CSS Ring command char lives on this service
          if (cId == CssRingConstants.commandChar.toUpperCase()) {
            if (!_commandChars.contains(char)) _commandChars.add(char);
            await _subscribe(char, _onCmdResponse);
          } else if (cId == CssRingConstants.heartRateChar.toUpperCase()) {
            await _subscribe(char, _onHRData);
          } else if (cId == CssRingConstants.activityChar.toUpperCase()) {
            await _subscribe(char, _onActivityData);
          } else if (cId == CssRingConstants.hrvChar.toUpperCase()) {
            await _subscribe(char, _onHRVData);
          } else if (cId == CssRingConstants.bpTempChar.toUpperCase()) {
            await _subscribe(char, _onBPData);
          } else if (cId == CssRingConstants.eventChar.toUpperCase()) {
            await _subscribe(char, _onEvent);
          }
        }
      }

      // SmartVital Ring custom service
      else if (sId == RingUUIDs.serviceUUID.toUpperCase()) {
        _isSmartVitalRing = true;
        debugPrint('[Ring] SmartVital Ring detected on service $sId');
        for (final char in service.characteristics) {
          final cId = char.characteristicUuid.str.toUpperCase();
          if (cId == RingUUIDs.commandChar.toUpperCase()) {
            if (!_commandChars.contains(char)) _commandChars.add(char);
            debugPrint('[Ring] SmartVital command char found: $cId');
          }
        }
      }

      // Command service for CSS R16
      else if (sId == '6E40000A-B5A3-F393-E0A9-E50E24DCCA9E') {
        for (final char in service.characteristics) {
          final cId = char.characteristicUuid.str.toUpperCase();
          if (cId == CssRingConstants.commandChar.toUpperCase()) {
            if (!_commandChars.contains(char)) _commandChars.add(char);
            await _subscribe(char, _onCmdResponse);
          }
        }
      }
      
      // Fallback Colmi / Standard ring service
      else if (sId == '6E400001-B5A3-F393-E0A9-E50E24DCCA9E') {
        for (final char in service.characteristics) {
          final cId = char.characteristicUuid.str.toUpperCase();
          if (cId == '6E400002-B5A3-F393-E0A9-E50E24DCCA9E') {
            if (!_commandChars.contains(char)) _commandChars.add(char);
          }
        }
      }

      // Standard Heart Rate Service
      else if (sId.contains('180D')) {
        for (final char in service.characteristics) {
          if (char.characteristicUuid.str.toUpperCase().contains('2A37')) {
            await _subscribe(char, _onStandardHRData);
          }
        }
      }

      // Battery service
      else if (sId.contains('180F')) {
        for (final char in service.characteristics) {
          if (char.characteristicUuid.str.toUpperCase().contains('2A19')) {
            await _subscribe(char, _onBatteryData);
            char.read().then(_onBatteryData).catchError((_) {});
          }
        }
      }
    }

    // Set fallback single _commandChar for backward compatibility
    _commandChar = _commandChars.isNotEmpty ? _commandChars.first : null;
  }

  Future<void> _subscribe(BluetoothCharacteristic c, void Function(List<int>) fn) async {
    try {
      if (c.properties.notify || c.properties.indicate) {
        await c.setNotifyValue(true);
        _subs.add(c.onValueReceived.listen(
          (b) {
            if (b.isNotEmpty) {
              if (kDebugMode) {
                debugPrint('[Ring] ${c.characteristicUuid.str}: ${CssRingParser.toHex(b)}');
              }
              fn(b);
            }
          },
          onError: (e) => debugPrint('[Ring] Error: $e'),
        ));
        // Add a small delay between concurrent descriptor writes
        await Future.delayed(const Duration(milliseconds: 150));
      }
    } catch (e) {
      debugPrint('[Ring] Subscribe error for ${c.characteristicUuid.str}: $e');
    }
  }

  // ── Bridge to BleVitalBuffer ──────────────────────────────────────
  /// Push a VitalReading into the BleVitalBuffer for backend upload.
  void _pushToBuffer(VitalReading reading) {
    _buffer?.add(reading);
    _healthService.syncVitalReading(reading);
  }

  // ── Data Handlers ──────────────────────────────────────────────────
  void _onStandardHRData(List<int> b) {
    if (b.length >= 2) {
      final is16Bit = (b[0] & 0x01) != 0;
      final hr = is16Bit ? ((b[2] << 8) | b[1]) : b[1];
      
      // Merge with existing vitals or create new
      state = state.copyWith(
        vitals: CssRingVitals(
          heartRate: hr,
          spo2: state.vitals?.spo2 ?? 0,
          hrv: state.vitals?.hrv ?? 0,
          stress: state.vitals?.stress ?? 0,
          timestamp: DateTime.now(),
        ),
        liveHeartRate: hr,
      );

      // Bridge to backend
      if (hr > 0) {
        _pushToBuffer(VitalReading(
          metricType: 'heart_rate', value: hr,
          timestamp: DateTime.now(), deviceSerial: _deviceSerial,
        ));
      }
    }
  }

  void _onSmartVitalHRData(List<int> bytes) {
    try {
      final hrReading = RingProtocol.parseHeartRate(bytes);
      final hr = hrReading.bpm;

      // Update state
      if (hr > 0) {
        state = state.copyWith(
          vitals: CssRingVitals(
            heartRate: hr,
            spo2: state.vitals?.spo2 ?? 0,
            hrv: state.vitals?.hrv ?? 0,
            stress: state.vitals?.stress ?? 0,
            timestamp: DateTime.now(),
          ),
          liveHeartRate: hr,
        );
        _pushToBuffer(VitalReading(
          metricType: 'heart_rate', value: hr,
          timestamp: DateTime.now(), deviceSerial: _deviceSerial,
        ));
      } else {
        // If it is 0, set liveHeartRate to 0 (warmup)
        state = state.copyWith(liveHeartRate: 0);
      }
    } catch (e) {
      debugPrint('[Ring] SmartVital HR parse error: $e');
    }
  }

  void _onHRData(List<int> bytes) {
    _hasReceivedHrNotification = true;
    if (bytes.length < 7) return;
    
    final sequence = bytes[1];
    final totalRecords = bytes[2];
    
    final v = CssRingParser.parseVitals(bytes);
    if (v != null) {
      if (totalRecords == 0) {
        // LIVE STREAMING PACKET: Instantly update UI and push to backend
        // Force the timestamp to be DateTime.now() so it's always recognized as fresh by the UI
        final liveV = CssRingVitals(
          heartRate: v.heartRate,
          spo2: v.spo2,
          hrv: v.hrv,
          stress: v.stress,
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          vitals: liveV,
          liveHeartRate: v.heartRate,
        );
        if (v.heartRate > 0) {
          _pushToBuffer(VitalReading(
            metricType: 'heart_rate', value: v.heartRate,
            timestamp: DateTime.now(), deviceSerial: _deviceSerial,
          ));
        }
      } else {
        // HISTORICAL BATCH PACKET: Add to batch buffer
        _hrBatch.add(v);
        // When the batch is complete, process it
        if (sequence == totalRecords && _hrBatch.isNotEmpty) {
          _processHRBatch();
        }
      }
    } else {
      // If vitals parsing failed (e.g. out of range), check if it's a live packet
      // with a raw value of 0 or 255 which indicates the sensor is warming up.
      if (totalRecords == 0) {
        final rawHr = bytes[6];
        if (rawHr == 0 || rawHr == 255) {
          state = state.copyWith(liveHeartRate: 0);
        }
      }
    }
  }

  void _processHRBatch() {
    // 1. Sort chronological (oldest first, so last is newest)
    _hrBatch.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // 2. Select the absolute latest valid HR to show on the UI
    final latestValid = _hrBatch.isNotEmpty ? _hrBatch.last : null;
    if (latestValid != null) {
      state = state.copyWith(vitals: latestValid);
    }

    // 3. Deduplicate and push to backend
    for (final v in _hrBatch) {
      // Only push records strictly NEWER than what we've already synced
      if (_lastSyncedTimestamp == null || v.timestamp.isAfter(_lastSyncedTimestamp!)) {
        if (v.heartRate > 0) {
          _pushToBuffer(VitalReading(
            metricType: 'heart_rate', value: v.heartRate,
            timestamp: v.timestamp, deviceSerial: _deviceSerial,
          ));
        }
        if (v.spo2 > 0) {
          _pushToBuffer(VitalReading(
            metricType: 'spo2', value: v.spo2,
            timestamp: v.timestamp, deviceSerial: _deviceSerial,
          ));
        }
        if (v.hrv > 0) {
          _pushToBuffer(VitalReading(
            metricType: 'hrv', value: v.hrv,
            timestamp: v.timestamp, deviceSerial: _deviceSerial,
          ));
        }
        _lastSyncedTimestamp = v.timestamp; // Update watermark
      }
    }

    // 4. Clear batch for next cycle
    _hrBatch.clear();
  }

  void _onActivityData(List<int> b) {
    final a = CssRingParser.parseActivity(b);
    if (a != null) {
      state = state.copyWith(activity: a);
      // Bridge steps/calories to backend
      if (a.steps > 0) {
        _pushToBuffer(VitalReading(
          metricType: 'steps', value: a.steps,
          timestamp: a.timestamp, deviceSerial: _deviceSerial,
        ));
      }
      if (a.calories > 0) {
        _pushToBuffer(VitalReading(
          metricType: 'calories', value: a.calories,
          timestamp: a.timestamp, deviceSerial: _deviceSerial,
        ));
      }
    }
  }

  void _onHRVData(List<int> b) {
    if (b.length > 2 && state.vitals != null) {
      final hrv = b[1];
      final stress = b.length > 2 ? b[2] : state.vitals!.stress;
      state = state.copyWith(
        vitals: CssRingVitals(
          heartRate: state.vitals!.heartRate,
          spo2: state.vitals!.spo2,
          hrv: hrv,
          stress: stress,
          timestamp: DateTime.now(),
        ),
      );
      if (hrv > 0) {
        _pushToBuffer(VitalReading(
          metricType: 'hrv', value: hrv,
          timestamp: DateTime.now(), deviceSerial: _deviceSerial,
        ));
      }
    }
  }

  void _onBPData(List<int> b) {
    final bp = CssRingParser.parseBloodPressure(b);
    if (bp != null) state = state.copyWith(bloodPressure: bp);
  }

  void _onBatteryData(List<int> b) =>
      state = state.copyWith(battery: CssRingParser.parseBattery(b));

  void _onCmdResponse(List<int> b) {
    if (kDebugMode) debugPrint('[Ring] CMD: ${CssRingParser.toHex(b)}');
    if (b.isNotEmpty && b[0] == 0x31) {
      final s = CssRingParser.parseSleep(b);
      if (s != null) state = state.copyWith(sleep: s);
    }
  }

  void _onEvent(List<int> b) {
    if (kDebugMode) debugPrint('[Ring] Event: ${CssRingParser.toHex(b)}');
  }

  // ── Commands ───────────────────────────────────────────────────────
  Future<void> measureHeartRate() async {
    if (state.isMonitoring) {
      await stopHeartRateMeasurement();
    } else {
      await startHeartRateMeasurement();
    }
  }

  Future<void> startHeartRateMeasurement() async {
    if (state.isMonitoring) return;

    debugPrint('[Ring] startHeartRateMeasurement: isSmartVital=$_isSmartVitalRing, commandChar=${_commandChar?.characteristicUuid.str}, isConnected=${state.isConnected}');

    // Clear live BPM on start so we don't display stale values
    state = state.copyWith(
      isMonitoring: true,
      clearLiveHeartRate: true,
    );

    if (_isSmartVitalRing) {
      // SmartVital Ring: single known command
      debugPrint('[Ring] Sending SmartVital start real-time command [0x03]');
      await _write([0x03]);
    } else {
      // WAKE UP HANDSHAKE: Send time sync (0x51) and activity Summary request (0x21)
      // to ensure the ring is out of low-power sleep and ready to receive sensor commands.
      debugPrint('[Ring] Sending wake-up handshake (Time sync and steps query) before probing...');
      await _syncTime();
      await Future.delayed(const Duration(milliseconds: 300));
      await _write(CssRingConstants.cmdGetSteps);
      await Future.delayed(const Duration(milliseconds: 500));

      // CSS R16 Ring: probe multiple candidate commands to find the one
      // that turns on the green LED sensor for real-time HR.
      await _probeCssRealTimeHRCommands();
    }

    // Set a safety auto-timeout timer (240 seconds during probe to allow trying all candidates)
    _safetyTimeoutTimer?.cancel();
    _safetyTimeoutTimer = Timer(const Duration(seconds: 240), () async {
      if (state.isMonitoring) {
        debugPrint('[Ring] Safety timeout reached, stopping measurement');
        await stopHeartRateMeasurement();
      }
    });
  }

  List<List<int>> _generateCandidates() {
    final List<List<int>> list = [];
    
    // Prepend 20-byte JRING-style commands
    list.add(List<int>.from([0x14, 0xB4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]));
    list.add(List<int>.from([0x14, 0x01, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]));

    // Prepend 16-byte Colmi R02 commands (0x69 with payload [1, 1] -> sum checksum 0x6B)
    list.add(List<int>.from([0x69, 0x01, 0x01, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x6B]));

    final opcodes = [
      0x14, 0x17, 0x11, 0x18, 0x1E, 0x15, 0x16, 0x19, 0x10, 0x12, 0x13, 0x1A, 0x1B, 0x1C, 0x1D, 0x1F, 0x69, 0x03, 0x04, 0x05
    ];
    final payloads = [
      [0x01],
      [0x01, 0x01],
      [],
      [0x01, 0x00],
      [0x02],
      [0x02, 0x01]
    ];
    
    bool containsPacket(List<int> pkt) {
      for (final existing in list) {
        if (existing.length == pkt.length) {
          bool match = true;
          for (int i = 0; i < pkt.length; i++) {
            if (existing[i] != pkt[i]) {
              match = false;
              break;
            }
          }
          if (match) return true;
        }
      }
      return false;
    }

    // Group 1: 17-byte AA-header (High Priority opcodes)
    final priorityOpcodes = [0x14, 0x17, 0x11, 0x18, 0x1E, 0x13];
    for (final op in priorityOpcodes) {
      for (final pl in payloads) {
        // XOR
        final pktXor = List<int>.filled(17, 0x00);
        pktXor[0] = 0xAA;
        pktXor[1] = op;
        for (int i = 0; i < pl.length && i < 14; i++) {
          pktXor[2 + i] = pl[i];
        }
        int csXor = 0;
        for (int i = 1; i < 16; i++) {
          csXor ^= pktXor[i];
        }
        pktXor[16] = csXor;
        if (!containsPacket(pktXor)) list.add(pktXor);

        // SUM
        final pktSum = List<int>.filled(17, 0x00);
        pktSum[0] = 0xAA;
        pktSum[1] = op;
        for (int i = 0; i < pl.length && i < 14; i++) {
          pktSum[2 + i] = pl[i];
        }
        int csSum = 0;
        for (int i = 1; i < 16; i++) {
          csSum += pktSum[i];
        }
        pktSum[16] = csSum & 0xFF;
        if (!containsPacket(pktSum)) list.add(pktSum);
      }
    }

    // Group 2: 17-byte AA-header (Other opcodes)
    final fallbackOpcodes = opcodes.where((op) => !priorityOpcodes.contains(op)).toList();
    for (final op in fallbackOpcodes) {
      for (final pl in payloads) {
        // XOR
        final pktXor = List<int>.filled(17, 0x00);
        pktXor[0] = 0xAA;
        pktXor[1] = op;
        for (int i = 0; i < pl.length && i < 14; i++) {
          pktXor[2 + i] = pl[i];
        }
        int csXor = 0;
        for (int i = 1; i < 16; i++) {
          csXor ^= pktXor[i];
        }
        pktXor[16] = csXor;
        if (!containsPacket(pktXor)) list.add(pktXor);

        // SUM
        final pktSum = List<int>.filled(17, 0x00);
        pktSum[0] = 0xAA;
        pktSum[1] = op;
        for (int i = 0; i < pl.length && i < 14; i++) {
          pktSum[2 + i] = pl[i];
        }
        int csSum = 0;
        for (int i = 1; i < 16; i++) {
          csSum += pktSum[i];
        }
        pktSum[16] = csSum & 0xFF;
        if (!containsPacket(pktSum)) list.add(pktSum);
      }
    }

    // Group 3: 16-byte AA-header
    for (final op in opcodes) {
      for (final pl in payloads) {
        // XOR
        final pktXor = List<int>.filled(16, 0x00);
        pktXor[0] = 0xAA;
        pktXor[1] = op;
        for (int i = 0; i < pl.length && i < 13; i++) {
          pktXor[2 + i] = pl[i];
        }
        int csXor = 0;
        for (int i = 1; i < 15; i++) {
          csXor ^= pktXor[i];
        }
        pktXor[15] = csXor;
        if (!containsPacket(pktXor)) list.add(pktXor);

        // SUM
        final pktSum = List<int>.filled(16, 0x00);
        pktSum[0] = 0xAA;
        pktSum[1] = op;
        for (int i = 0; i < pl.length && i < 13; i++) {
          pktSum[2 + i] = pl[i];
        }
        int csSum = 0;
        for (int i = 1; i < 15; i++) {
          csSum += pktSum[i];
        }
        pktSum[15] = csSum & 0xFF;
        if (!containsPacket(pktSum)) list.add(pktSum);
      }
    }

    // Group 4: 16-byte Colmi-style
    for (final op in opcodes) {
      for (final pl in payloads) {
        // Mod 255
        final pkt255 = List<int>.filled(16, 0x00);
        pkt255[0] = op;
        for (int i = 0; i < pl.length && i < 14; i++) {
          pkt255[1 + i] = pl[i];
        }
        int cs255 = 0;
        for (int i = 0; i < 15; i++) {
          cs255 += pkt255[i];
        }
        pkt255[15] = cs255 % 255;
        if (!containsPacket(pkt255)) list.add(pkt255);

        // Mod 256
        final pkt256 = List<int>.filled(16, 0x00);
        pkt256[0] = op;
        for (int i = 0; i < pl.length && i < 14; i++) {
          pkt256[1 + i] = pl[i];
        }
        int cs256 = 0;
        for (int i = 0; i < 15; i++) {
          cs256 += pkt256[i];
        }
        pkt256[15] = cs256 & 0xFF;
        if (!containsPacket(pkt256)) list.add(pkt256);
      }
    }

    return list;
  }

  List<int> _buildStopPacket(List<int> startPacket) {
    final stopPacket = List<int>.from(startPacket);
    if (stopPacket.isEmpty) return [];
    
    // JRING 20-byte check: starts with 0x14, size is 20
    if (startPacket[0] == 0x14 && startPacket.length == 20) {
      return List<int>.filled(20, 0x00)..[0] = 0x15;
    }

    // Colmi R02 check: starts with 0x69 (105), size is 16
    if (startPacket[0] == 0x69 && startPacket.length == 16) {
      final stop = List<int>.filled(16, 0x00);
      stop[0] = 0x6A; // CMD_STOP_REAL_TIME = 106 (0x6A)
      stop[1] = startPacket[1]; // reading_type
      stop[15] = (0x6A + stop[1]) & 0xFF;
      return stop;
    }
    
    if (stopPacket[0] == 0xAA) {
      // AA header format: typically payload starts at index 2
      // If the start packet has a 2-byte payload (e.g. [type, enable]),
      // preserve the type at index 2 and change the enable byte at index 3 to 0x00.
      // Otherwise, clear the payload starting from index 2.
      final hasTwoBytePayload = startPacket.length > 3 && startPacket[3] != 0;
      final startClearIdx = hasTwoBytePayload ? 3 : 2;
      
      for (int i = startClearIdx; i < stopPacket.length - 1; i++) {
        stopPacket[i] = 0x00;
      }
      // Recalculate checksum at the last index
      final lastIdx = stopPacket.length - 1;
      int expectedCs = startPacket[lastIdx];
      int sumCs = 0;
      int xorCs = 0;
      for (int i = 1; i < lastIdx; i++) {
        sumCs += startPacket[i];
        xorCs ^= startPacket[i];
      }
      sumCs &= 0xFF;
      
      bool isXor = true;
      if (expectedCs == sumCs && expectedCs != xorCs) {
        isXor = false;
      }
      
      // Calculate new checksum for stopPacket
      int newCs = 0;
      for (int i = 1; i < lastIdx; i++) {
        if (isXor) {
          newCs ^= stopPacket[i];
        } else {
          newCs += stopPacket[i];
        }
      }
      stopPacket[lastIdx] = isXor ? newCs : (newCs & 0xFF);
    } else {
      // Colmi format: starts with opcode, payload starts at index 1
      for (int i = 1; i < stopPacket.length - 1; i++) {
        stopPacket[i] = 0x00;
      }
      // Checksum at last byte is sum of first 15 bytes % 255 (or % 256)
      final lastIdx = stopPacket.length - 1;
      int expectedCs = startPacket[lastIdx];
      int sumVal = 0;
      for (int i = 0; i < lastIdx; i++) {
        sumVal += startPacket[i];
      }
      bool isMod255 = (expectedCs == sumVal % 255);
      
      int newSum = 0;
      for (int i = 0; i < lastIdx; i++) {
        newSum += stopPacket[i];
      }
      stopPacket[lastIdx] = isMod255 ? (newSum % 255) : (newSum & 0xFF);
    }
    return stopPacket;
  }

  Future<void> _probeCssRealTimeHRCommands() async {
    if (_candidates.isEmpty) {
      _candidates.addAll(_generateCandidates());
      debugPrint('[Ring] Generated ${_candidates.length} unique candidates.');
    }

    if (_workingCmdIndex >= 0 && _workingCmdIndex < _candidates.length) {
      // We already know which command works — use it directly
      debugPrint('[Ring] Using known working command index $_workingCmdIndex');
      await _write(_candidates[_workingCmdIndex]);
      return;
    }

    _hasReceivedHrNotification = false;
    debugPrint('[Ring] Probing ${_candidates.length} CSS R16 real-time HR command candidates...');

    for (int i = 0; i < _candidates.length; i++) {
      if (!state.isMonitoring || !state.isConnected) break;

      _hasReceivedHrNotification = false; // Reset for this candidate
      final cmd = _candidates[i];
      final label = 'C$i';
      debugPrint('[Ring] Trying candidate $label (index $i): ${cmd.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').toList()}');
      await _write(cmd);

      // Wait 1.2 seconds for the ring to respond (green LED should turn on and start notifying)
      await Future.delayed(const Duration(milliseconds: 1200));

      // Check if we got any HR notification (even warmup values like 0 or 255 count as success)
      if (_hasReceivedHrNotification) {
        _workingCmdIndex = i;
        debugPrint('[Ring] ✓ Candidate $label WORKED! HR Notification received. Saving index $i for future use.');
        
        // Reset safety timeout to standard 60 seconds now that sensor is active
        _safetyTimeoutTimer?.cancel();
        _safetyTimeoutTimer = Timer(const Duration(seconds: 60), () async {
          if (state.isMonitoring) {
            debugPrint('[Ring] Safety timeout reached, stopping measurement');
            await stopHeartRateMeasurement();
          }
        });
        return;
      }
      debugPrint('[Ring] ✗ Candidate $label — no HR response yet, trying next...');
    }

    debugPrint('[Ring] All candidates tried. The green LED may take longer to warm up — waiting for data...');
  }

  Future<void> stopHeartRateMeasurement() async {
    _measurementTimer?.cancel();
    _measurementTimer = null;
    _safetyTimeoutTimer?.cancel();
    _safetyTimeoutTimer = null;

    if (state.isConnected) {
      if (_isSmartVitalRing) {
        // Stop real-time mode for SmartVital Ring
        await _write([0x04]);
      } else {
        if (_workingCmdIndex >= 0 && _workingCmdIndex < _candidates.length) {
          debugPrint('[Ring] Sending matching stop command for working index $_workingCmdIndex...');
          final stopCmd = _buildStopPacket(_candidates[_workingCmdIndex]);
          await _write(stopCmd);
        } else {
          // Send ALL stop candidates as a fallback to ensure the sensor turns off
          debugPrint('[Ring] Sending all legacy CSS R16 stop commands...');
          for (final cmd in CssRingConstants.cmdStopRealTimeHRCandidates) {
            await _write(cmd);
            await Future.delayed(const Duration(milliseconds: 200));
          }
        }
      }
    }

    state = state.copyWith(
      isMonitoring: false,
      clearLiveHeartRate: true,
    );
  }

  Future<void> startMonitoring() async {
    state = state.copyWith(isMonitoring: true);
    
    // Fallback if needed, but UI now uses measureHeartRate
    await _write(CssRingConstants.cmdStartHeartRate);
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Then request steps/activity
    await _write(CssRingConstants.cmdGetSteps);
    await Future.delayed(const Duration(milliseconds: 300));
    
    await requestSleep();
    await Future.delayed(const Duration(milliseconds: 200));
    await requestBP();
    
    // Set up periodic refresh every 30 seconds
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) async {
        if (state.isConnected && state.isMonitoring) {
          await Future.delayed(const Duration(milliseconds: 200));
          await _write(CssRingConstants.cmdGetSteps);
        }
      },
    );
  }

  Future<void> stopMonitoring() async {
    await stopHeartRateMeasurement();
  }

  Future<void> requestSleep() => _write(CssRingConstants.cmdGetSleep);
  Future<void> requestBP()    => _write(CssRingConstants.cmdGetBloodPressure);

  Future<void> _syncTime() async {
    final n = DateTime.now();
    
    // 1. 20-byte JRING Time Sync
    final ts = n.millisecondsSinceEpoch ~/ 1000;
    final tz = n.timeZoneOffset.inHours;
    final jringTimeSync = List<int>.filled(20, 0x00);
    jringTimeSync[0] = 0x01;
    jringTimeSync[1] = ts & 0xFF;
    jringTimeSync[2] = (ts >> 8) & 0xFF;
    jringTimeSync[3] = (ts >> 16) & 0xFF;
    jringTimeSync[4] = (ts >> 24) & 0xFF;
    jringTimeSync[5] = tz;
    debugPrint('[Ring] Sending 20-byte JRING time sync...');
    await _write(jringTimeSync);
    await Future.delayed(const Duration(milliseconds: 200));

    // 2. Legacy 17-byte AA time sync
    final bytes = [
      0xAA, 0x51,
      n.year - 2000, n.month, n.day, n.hour, n.minute, n.second,
      0,0,0,0,0,0,0,0,
    ];
    int checksum = 0;
    // Calculate checksum by XORing bytes from index 1 (excluding header 0xAA)
    for (int i = 1; i < bytes.length; i++) {
      checksum ^= bytes[i];
    }
    bytes.add(checksum);
    await _write(bytes);
  }

  // ── Public bridge for BleManager to push live HR readings ────────
  /// Called by BleManager._handleNotification when a heart_rate reading
  /// is received from the ring. This is the SOLE path for SmartVital Ring
  /// HR data to reach CssRingState (no double-subscription).
  void onLiveHeartRate(int hr) {
    debugPrint('[Ring] onLiveHeartRate: $hr (isMonitoring=${state.isMonitoring})');
    if (hr > 0) {
      state = state.copyWith(
        vitals: CssRingVitals(
          heartRate: hr,
          spo2: state.vitals?.spo2 ?? 0,
          hrv: state.vitals?.hrv ?? 0,
          stress: state.vitals?.stress ?? 0,
          timestamp: DateTime.now(),
        ),
        liveHeartRate: hr,
      );
    } else {
      // hr == 0 means the sensor is warming up
      state = state.copyWith(liveHeartRate: 0);
    }
  }

  Future<void> _write(List<int> bytes) async {
    if (_commandChars.isEmpty || !state.isConnected) {
      debugPrint('[Ring] _write skipped: commandChars is empty, isConnected=${state.isConnected}');
      return;
    }
    for (final char in _commandChars) {
      try {
        final withoutResp = char.properties.writeWithoutResponse && !char.properties.write;
        debugPrint('[Ring] _write ${bytes.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').toList()} to ${char.characteristicUuid.str} (withoutResp=$withoutResp) on service ${char.serviceUuid.str}');
        await char.write(bytes, withoutResponse: withoutResp);
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        debugPrint('[Ring] Write error on ${char.characteristicUuid.str}: $e');
      }
    }
  }

  void disconnect() {
    _periodicTimer?.cancel();
    _measurementTimer?.cancel();
    _safetyTimeoutTimer?.cancel();
    _cleanupSubscriptions();
    _deviceSerial = null;
    _hrBatch.clear();
    _lastSyncedTimestamp = null;
    _commandChars.clear();
    _workingCmdIndex = -1;
    _candidates.clear();
    _hasReceivedHrNotification = false;
    state = const CssRingState();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
