import 'dart:typed_data';
import 'ble_models.dart';

class RingProtocol {
  static HeartRateReading parseHeartRate(List<int> bytes) {
    if (bytes.isEmpty) throw BleParseException('Empty HR packet');
    final flags = bytes[0];
    final isUint16 = (flags & 0x01) != 0;
    final hrValue = isUint16
        ? ByteData.sublistView(Uint8List.fromList(bytes.sublist(1, 3))).getUint16(0, Endian.little)
        : bytes[1];
    return HeartRateReading(bpm: hrValue, timestamp: DateTime.now());
  }

  static SpO2Reading parseSpO2(List<int> bytes) {
    if (bytes.length < 2) throw BleParseException('SpO2 packet too short');
    return SpO2Reading(
      percentage: bytes[0].toDouble(),
      confidence: bytes[1].toDouble(),
      timestamp: DateTime.now(),
    );
  }

  static SkinTempReading parseSkinTemp(List<int> bytes) {
    if (bytes.length < 4) throw BleParseException('Skin temp packet too short');
    final tempC = bytes[0] + (bytes[1] / 100.0);
    final deviation = (bytes[2].toSigned(8)) / 10.0;
    return SkinTempReading(
      celsius: tempC,
      deviationFromBaseline: deviation,
      quality: bytes[3],
      timestamp: DateTime.now(),
    );
  }

  static StepsReading parseSteps(List<int> bytes) {
    if (bytes.length < 6) throw BleParseException('Steps packet too short');
    final bd = ByteData.sublistView(Uint8List.fromList(bytes));
    return StepsReading(
      count: bd.getUint32(0, Endian.little),
      calories: bd.getUint16(4, Endian.little) / 10.0,
      timestamp: DateTime.now(),
    );
  }

  static HrvReading parseHrv(List<int> bytes) {
    if (bytes.length < 4) throw BleParseException('HRV packet too short');
    final bd = ByteData.sublistView(Uint8List.fromList(bytes));
    return HrvReading(
      sdnn: bd.getUint16(0, Endian.little).toDouble(),
      rmssd: bd.getUint16(2, Endian.little).toDouble(),
      timestamp: DateTime.now(),
    );
  }

  static SleepReading parseSleep(List<int> bytes) {
    if (bytes.length < 8) throw BleParseException('Sleep packet too short');
    return SleepReading(
      score: bytes[0],
      totalMinutes: bytes[1] * 2,
      deepMinutes: bytes[2] * 2,
      remMinutes: bytes[3] * 2,
      lightMinutes: bytes[4] * 2,
      awakeMinutes: bytes[5],
      sleepStartMinutesFromMidnight: ByteData.sublistView(
        Uint8List.fromList(bytes.sublist(6, 8))).getUint16(0, Endian.little),
      timestamp: DateTime.now(),
    );
  }

  static DeviceInfo parseDeviceInfo(List<int> bytes) {
    if (bytes.length < 3) throw BleParseException('Device info packet too short');
    return DeviceInfo(
      firmwareVersion: '${bytes[0]}.${bytes[1]}.${bytes[2]}',
      deviceName: bytes.length > 3
          ? String.fromCharCodes(bytes.sublist(3))
          : 'SmartVital Ring',
    );
  }
}
