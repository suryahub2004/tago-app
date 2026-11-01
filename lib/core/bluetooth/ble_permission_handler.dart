import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum BlePermissionResult {
  granted,
  denied,
  permanentlyDenied,
  adapterOff,
  unavailable,
  locationServicesOff,
}

class BlePermissionHandler {
  /// Call this BEFORE any BLE scan/connect operation.
  ///
  /// On iOS the flow is:
  ///   1. Always call `Permission.bluetooth.request()` — iOS only shows the
  ///      system prompt once. On subsequent calls it returns the cached result.
  ///   2. After the request, check `FlutterBluePlus.adapterState` to see if
  ///      the radio is actually on.
  ///
  /// On Android the flow is the same as before (runtime permission request
  /// followed by adapter state check).
  static Future<BlePermissionResult> requestAndCheck() async {
    if (Platform.isIOS) {
      return await _requestIOS();
    } else if (Platform.isAndroid) {
      return await _requestAndroid();
    }
    return BlePermissionResult.granted;
  }

  // ── iOS ──────────────────────────────────────────────────────────────────
  static Future<BlePermissionResult> _requestIOS() async {
    // On iOS, Core Bluetooth has its OWN permission system.
    // Instead of manually reading adapterState here (which causes race conditions 
    // because CBCentralManager takes time to initialize), we immediately return 
    // granted. The BleStateGuard.waitUntilReady() function will correctly wait 
    // for the adapter and catch any unauthorized states.
    return BlePermissionResult.granted;
  }

  // ── Android ──────────────────────────────────────────────────────────────
  static Future<BlePermissionResult> _requestAndroid() async {
    // Step 1: Request runtime permissions.
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkVersion = androidInfo.version.sdkInt;

    final List<Permission> permissions;
    if (sdkVersion >= 31) {
      // Android 12+ uses the new BLE permissions.
      // Also request fine location as it is required for reliable scanning
      permissions = [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse
      ];
    } else {
      // Android < 12 needs location for BLE scanning.
      permissions = [Permission.bluetooth, Permission.locationWhenInUse];
    }

    final statuses = await permissions.request();
    final allGranted = statuses.values.every(
      (s) => s == PermissionStatus.granted || s == PermissionStatus.limited,
    );

    if (!allGranted) {
      final permanentlyDenied =
          statuses.values.any((s) => s == PermissionStatus.permanentlyDenied);
      return permanentlyDenied
          ? BlePermissionResult.permanentlyDenied
          : BlePermissionResult.denied;
    }

    // Step 2: Check adapter state.
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState == BluetoothAdapterState.off) {
      return BlePermissionResult.adapterOff;
    }
    if (adapterState == BluetoothAdapterState.unavailable) {
      return BlePermissionResult.unavailable;
    }

    // Step 3: Check Location Services (Required for BLE scanning on Android)
    final locationServiceEnabled = await Permission.locationWhenInUse.serviceStatus.isEnabled;
    if (!locationServiceEnabled) {
      return BlePermissionResult.locationServicesOff;
    }

    return BlePermissionResult.granted;
  }
}
