class CssRingConstants {
  static const String serviceUuid =
      '6E400004-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String heartRateChar =
      '6E400005-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String activityChar =
      '6E400006-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String hrvChar =
      '6E400007-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String bpTempChar =
      '6E400008-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String commandChar =
      '6E40000C-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String eventChar =
      '6E40000D-B5A3-F393-E0A9-E50E24DCCA9E';

  // ── Helper: Build a 17-byte 0xAA command with XOR checksum ──────────
  /// Bytes: [0xAA, cmdId, ...payload(14 bytes)..., checksum]
  /// Checksum = XOR of bytes[1] through bytes[15]
  static List<int> makeCommand(int cmdId, [List<int> payload = const []]) {
    final pkt = List<int>.filled(17, 0x00);
    pkt[0] = 0xAA;
    pkt[1] = cmdId;
    for (int i = 0; i < payload.length && i < 14; i++) {
      pkt[2 + i] = payload[i];
    }
    int checksum = 0;
    for (int i = 1; i < 16; i++) {
      checksum ^= pkt[i];
    }
    pkt[16] = checksum;
    return pkt;
  }

  // ── Commands: Fetch stored data (request latest record) ─────────────
  /// Request latest stored HR record from ring memory
  static const List<int> cmdGetHeartRate =
      [0xAA,0x11,0x00,0x00,0x00,0x00,0x00,0x00,
       0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x11];
  /// Request steps/activity data
  static const List<int> cmdGetSteps =
      [0xAA,0x21,0x00,0x00,0x00,0x00,0x00,0x00,
       0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x21];
  /// Request sleep data
  static const List<int> cmdGetSleep =
      [0xAA,0x31,0x00,0x00,0x00,0x00,0x00,0x00,
       0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x31];
  /// Request blood pressure data
  static const List<int> cmdGetBloodPressure =
      [0xAA,0x41,0x00,0x00,0x00,0x00,0x00,0x00,
       0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x41];

  // ── Commands: Real-time sensor control (turn green LED on/off) ──────
  //
  // CSS R16 rings use command IDs in the 0x11-0x19 range for HR control.
  // The exact command that turns on the green LED varies by firmware.
  // We try multiple candidates in sequence until the ring responds.
  //
  // Candidate A: 0x17 = real-time monitoring control, byte2=0x01 (enable HR)
  // Candidate B: 0x11 with byte2=0x01 (start HR with continuous flag)
  // Candidate C: 0x18 = alternative real-time HR
  // Candidate D: 0x15 = real-time continuous mode
  // Candidate E: 0x69 = Colmi-style real-time start

  /// Candidate commands to START real-time HR measurement (green LED ON)
  static final List<List<int>> cmdStartRealTimeHRCandidates = [
    makeCommand(0x14, [0x01]),           // A: Saksham's live HR command (most likely)
    makeCommand(0x17, [0x01]),           // B: Real-time monitoring enable HR
    makeCommand(0x11, [0x01]),           // C: Start HR with continuous flag
    makeCommand(0x18, [0x01]),           // D: Alternative real-time HR
    makeCommand(0x15, [0x01]),           // E: Continuous mode variant
    makeCommand(0x13, [0x01]),           // F: Activity / live measure query
    makeCommand(0x16, [0x01]),           // G: Alternate start HR
    makeCommand(0x19, [0x01]),           // H: Alternate start HR
    makeCommand(0x10, [0x01]),           // I: Alternate start HR
    makeCommand(0x12, [0x01]),           // J: Alternate start HR
    makeCommand(0x69, [0x01, 0x01]),     // K: Colmi-style real-time start
    makeCommand(0x11, [0x02]),           // L: Start HR mode 2
    makeCommand(0x14),                   // M: Saksham's live HR command (no payload)
    makeCommand(0x17),                   // N: Real-time monitoring enable HR (no payload)
    makeCommand(0x13),                   // O: Activity / live measure query (no payload)
    makeCommand(0x18),                   // P: Alternative real-time HR (no payload)
    makeCommand(0x15),                   // Q: Continuous mode variant (no payload)
    makeCommand(0x16),                   // R: Alternate start HR (no payload)
    makeCommand(0x19),                   // S: Alternate start HR (no payload)
    makeCommand(0x10),                   // T: Alternate start HR (no payload)
    makeCommand(0x12),                   // U: Alternate start HR (no payload)
    makeCommand(0x03, [0x01]),           // V: Command 0x03 with payload
    makeCommand(0x03),                   // W: Command 0x03 (no payload)
    makeCommand(0x04),                   // X: Command 0x04 (no payload)
    makeCommand(0x05),                   // Y: Command 0x05 (no payload)
    makeCommand(0x14, [0x01, 0x01]),     // Z0: Two-byte live HR command
    makeCommand(0x17, [0x01, 0x01]),     // Z1: Two-byte enable HR
    makeCommand(0x11, [0x01, 0x01]),     // Z2: Two-byte continuous HR
    makeCommand(0x18, [0x01, 0x01]),     // Z3: Two-byte alt HR
    makeCommand(0x15, [0x01, 0x01]),     // Z4: Two-byte continuous variant
    makeCommand(0x13, [0x01, 0x01]),     // Z5: Two-byte activity query
    makeCommand(0x16, [0x01, 0x01]),     // Z6: Two-byte alt start
    makeCommand(0x19, [0x01, 0x01]),     // Z7: Two-byte alt start
    makeCommand(0x10, [0x01, 0x01]),     // Z8: Two-byte alt start
    makeCommand(0x12, [0x01, 0x01]),     // Z9: Two-byte alt start
  ];

  /// Candidate commands to STOP real-time HR measurement (green LED OFF)
  static final List<List<int>> cmdStopRealTimeHRCandidates = [
    makeCommand(0x14, [0x00]),           // A: Saksham's stop HR
    makeCommand(0x17, [0x00]),           // B: Real-time monitoring disable
    makeCommand(0x12),                   // C: Stop HR (original)
    makeCommand(0x18, [0x00]),           // D: Alternative stop
    makeCommand(0x15, [0x00]),           // E: Continuous mode stop
    makeCommand(0x13, [0x00]),           // F: Stop F
    makeCommand(0x16, [0x00]),           // G: Stop G
    makeCommand(0x19, [0x00]),           // H: Stop H
    makeCommand(0x10, [0x00]),           // I: Stop I
    makeCommand(0x12, [0x00]),           // J: Stop J
    makeCommand(0x6A, [0x01, 0x00]),     // K: Colmi-style stop
    makeCommand(0x11, [0x00]),           // L: Stop L
    makeCommand(0x14, [0x00]),           // M: Stop M
    makeCommand(0x17, [0x00]),           // N: Stop N
    makeCommand(0x13, [0x00]),           // O: Stop O
    makeCommand(0x18, [0x00]),           // P: Stop P
    makeCommand(0x15, [0x00]),           // Q: Stop Q
    makeCommand(0x16, [0x00]),           // R: Stop R
    makeCommand(0x19, [0x00]),           // S: Stop S
    makeCommand(0x10, [0x00]),           // T: Stop T
    makeCommand(0x12, [0x00]),           // U: Stop U
    makeCommand(0x03, [0x00]),           // V: Stop V
    makeCommand(0x03, [0x00]),           // W: Stop W
    makeCommand(0x04, [0x00]),           // X: Stop X
    makeCommand(0x05, [0x00]),           // Y: Stop Y
    makeCommand(0x14, [0x01, 0x00]),     // Z0: Stop Z0
    makeCommand(0x17, [0x01, 0x00]),     // Z1: Stop Z1
    makeCommand(0x11, [0x01, 0x00]),     // Z2: Stop Z2
    makeCommand(0x18, [0x01, 0x00]),     // Z3: Stop Z3
    makeCommand(0x15, [0x01, 0x00]),     // Z4: Stop Z4
    makeCommand(0x13, [0x01, 0x00]),     // Z5: Stop Z5
    makeCommand(0x16, [0x01, 0x00]),     // Z6: Stop Z6
    makeCommand(0x19, [0x01, 0x00]),     // Z7: Stop Z7
    makeCommand(0x10, [0x01, 0x00]),     // Z8: Stop Z8
    makeCommand(0x12, [0x01, 0x00]),     // Z9: Stop Z9
  ];

  // ── Legacy aliases (kept for backward compatibility) ────────────────
  static const List<int> cmdStartHeartRate =
      [0xAA,0x11,0x00,0x00,0x00,0x00,0x00,0x00,
       0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x11];
  static const List<int> cmdStopHeartRate =
      [0xAA,0x12,0x00,0x00,0x00,0x00,0x00,0x00,
       0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x12];
}
