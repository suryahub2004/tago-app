import 'dart:typed_data';
import 'ble_models.dart';
import 'ring_protocol.dart';

class BandProtocol {
  static HeartRateReading parseHeartRate(List<int> bytes) => RingProtocol.parseHeartRate(bytes);

  static HrvReading parseHrv(List<int> bytes) => RingProtocol.parseHrv(bytes);

  static RespiratoryRateReading parseRespiratoryRate(List<int> bytes) {
    return RespiratoryRateReading(
      breathsPerMinute: bytes[0].toDouble(),
      confidence: bytes[1].toDouble(),
      timestamp: DateTime.now(),
    );
  }

  static StrainReading parseStrain(List<int> bytes) {
    final bd = ByteData.sublistView(Uint8List.fromList(bytes));
    return StrainReading(
      current: bd.getUint16(0, Endian.little) / 10.0,
      target: bd.getUint16(2, Endian.little) / 10.0,
      timestamp: DateTime.now(),
    );
  }

  static RecoveryReading parseRecovery(List<int> bytes) {
    return RecoveryReading(
      score: bytes[0],
      hrvContribution: bytes[1],
      sleepContribution: bytes[2],
      timestamp: DateTime.now(),
    );
  }

  static Vo2MaxReading parseVo2Max(List<int> bytes) {
    final bd = ByteData.sublistView(Uint8List.fromList(bytes));
    return Vo2MaxReading(
      value: bd.getUint16(0, Endian.little) / 10.0,
      timestamp: DateTime.now(),
    );
  }

  static CaloriesReading parseCalories(List<int> bytes) {
    final bd = ByteData.sublistView(Uint8List.fromList(bytes));
    return CaloriesReading(
      active: bd.getUint16(0, Endian.little) / 10.0,
      resting: bd.getUint16(2, Endian.little) / 10.0,
      timestamp: DateTime.now(),
    );
  }

  static DeviceInfo parseDeviceInfo(List<int> bytes) {
    if (bytes.length < 3) throw BleParseException('Device info packet too short');
    return DeviceInfo(
      firmwareVersion: '${bytes[0]}.${bytes[1]}.${bytes[2]}',
      deviceName: bytes.length > 3
          ? String.fromCharCodes(bytes.sublist(3))
          : 'SmartVital Band',
    );
  }
}
