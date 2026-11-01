/// UUID constants for SmartVital Ring (custom GATT profile).
class RingUUIDs {
  static const serviceUUID           = '0000FF00-0000-1000-8000-00805F9B34FB';
  static const heartRateChar         = '0000FF01-0000-1000-8000-00805F9B34FB'; // notify
  static const spo2Char              = '0000FF02-0000-1000-8000-00805F9B34FB'; // notify
  static const skinTempChar          = '0000FF03-0000-1000-8000-00805F9B34FB'; // notify
  static const stepsChar             = '0000FF04-0000-1000-8000-00805F9B34FB'; // read + notify
  static const hrvChar               = '0000FF05-0000-1000-8000-00805F9B34FB'; // notify
  static const sleepDataChar         = '0000FF06-0000-1000-8000-00805F9B34FB'; // read (on demand)
  static const batteryChar           = '00002A19-0000-1000-8000-00805F9B34FB'; // read (standard)
  static const deviceInfoChar        = '0000FF07-0000-1000-8000-00805F9B34FB'; // read
  static const commandChar           = '0000FF08-0000-1000-8000-00805F9B34FB'; // write (send commands)
}

/// UUID constants for SmartVital Band (custom GATT profile).
class BandUUIDs {
  static const serviceUUID           = '0000FE00-0000-1000-8000-00805F9B34FB';
  static const heartRateChar         = '0000FE01-0000-1000-8000-00805F9B34FB'; // notify
  static const hrvChar               = '0000FE02-0000-1000-8000-00805F9B34FB'; // notify
  static const respiratoryRateChar   = '0000FE03-0000-1000-8000-00805F9B34FB'; // notify
  static const strainChar            = '0000FE04-0000-1000-8000-00805F9B34FB'; // notify
  static const recoveryScoreChar     = '0000FE05-0000-1000-8000-00805F9B34FB'; // notify
  static const stepsChar             = '0000FE06-0000-1000-8000-00805F9B34FB'; // read + notify
  static const caloriesChar          = '0000FE07-0000-1000-8000-00805F9B34FB'; // read + notify
  static const vo2MaxChar            = '0000FE08-0000-1000-8000-00805F9B34FB'; // read
  static const sleepDataChar         = '0000FE09-0000-1000-8000-00805F9B34FB'; // read
  static const batteryChar           = '00002A19-0000-1000-8000-00805F9B34FB'; // standard
  static const deviceInfoChar        = '0000FE0A-0000-1000-8000-00805F9B34FB'; // read
  static const commandChar           = '0000FE0B-0000-1000-8000-00805F9B34FB'; // write
}

/// Standard Bluetooth SIG service & characteristic UUIDs.
/// Used for open-source rings (Colmi R02/R06, generic BLE health rings)
/// that implement the standard GATT Heart Rate and Battery profiles.
class StandardBleUUIDs {
  // ── Standard Services ─────────────────────────────────────────────────────
  /// Standard Heart Rate Service (0x180D)
  static const heartRateService      = '0000180D-0000-1000-8000-00805F9B34FB';
  /// Standard Battery Service (0x180F)
  static const batteryService        = '0000180F-0000-1000-8000-00805F9B34FB';
  /// Standard Device Information Service (0x180A)
  static const deviceInfoService     = '0000180A-0000-1000-8000-00805F9B34FB';
  /// Standard Health Thermometer Service (0x1809)
  static const healthThermometerService = '00001809-0000-1000-8000-00805F9B34FB';

  // ── Standard Characteristics ──────────────────────────────────────────────
  /// Heart Rate Measurement (0x2A37) — notify, standard HR Measurement format
  static const heartRateMeasurement  = '00002A37-0000-1000-8000-00805F9B34FB';
  /// Battery Level (0x2A19) — read/notify
  static const batteryLevel          = '00002A19-0000-1000-8000-00805F9B34FB';
  /// Firmware Revision String (0x2A26) — read
  static const firmwareRevision      = '00002A26-0000-1000-8000-00805F9B34FB';
  /// Manufacturer Name String (0x2A29) — read
  static const manufacturerName     = '00002A29-0000-1000-8000-00805F9B34FB';
  /// Temperature Measurement (0x2A1C) — indicate
  static const temperatureMeasurement = '00002A1C-0000-1000-8000-00805F9B34FB';
  /// Step Count (no standard UUID; many rings use 0xFFF1 in a custom service)
  static const stepCountChar         = '0000FFF1-0000-1000-8000-00805F9B34FB';
  /// SpO2 (no standard UUID; many rings use 0xFFF4 in a custom service)
  static const spo2Char              = '0000FFF4-0000-1000-8000-00805F9B34FB';

  // ── Colmi / Generic Ring Custom Service ───────────────────────────────────
  /// Common custom service UUID found on Colmi R02, R06, and similar rings
  static const colmiServiceUUID      = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  static const colmiWriteChar        = '6E400002-B5A3-F393-E0A9-E50E24DCCA9E'; // write
  static const colmiNotifyChar       = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E'; // notify
}
