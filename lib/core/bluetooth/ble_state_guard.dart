import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum BleAdapterReadyResult {
  ready,
  poweredOff,
  unavailable,
  unauthorized,
  timeout,
}

class BleStateGuard {
  /// Waits until the Bluetooth adapter is fully ON.
  /// Never reads adapterState synchronously — always streams.
  /// This safely bypasses the iOS CBCentralManager initialization delay
  /// where transient states (.unknown, .turningOn) are emitted.
  static Future<BleAdapterReadyResult> waitUntilReady({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final completer = Completer<BleAdapterReadyResult>();

    late StreamSubscription sub;
    bool resolved = false;

    sub = FlutterBluePlus.adapterState.listen((state) {
      if (resolved) return;

      switch (state) {
        case BluetoothAdapterState.on:
          resolved = true;
          completer.complete(BleAdapterReadyResult.ready);
          sub.cancel();
          break;
        case BluetoothAdapterState.off:
          resolved = true;
          completer.complete(BleAdapterReadyResult.poweredOff);
          sub.cancel();
          break;
        case BluetoothAdapterState.unavailable:
          resolved = true;
          completer.complete(BleAdapterReadyResult.unavailable);
          sub.cancel();
          break;
        case BluetoothAdapterState.unauthorized:
          resolved = true;
          completer.complete(BleAdapterReadyResult.unauthorized);
          sub.cancel();
          break;
        case BluetoothAdapterState.unknown:
        case BluetoothAdapterState.turningOn:
        case BluetoothAdapterState.turningOff:
          // iOS emits these transiently during init — WAIT, do not act
          break;
      }
    });

    // Timeout fallback — if OS never emits a definitive state
    Future.delayed(timeout, () {
      if (!resolved) {
        resolved = true;
        sub.cancel();
        completer.complete(BleAdapterReadyResult.timeout);
      }
    });

    return completer.future;
  }
}
