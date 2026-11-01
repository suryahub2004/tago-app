import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/sv_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/bluetooth/ble_manager.dart';
import '../../../../core/bluetooth/ble_permission_handler.dart';
import '../../../../core/bluetooth/ble_state_guard.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/rive_ring_widget.dart';
import '../../../../shared/widgets/signal_bars.dart';

class DevicePairingScreen extends ConsumerStatefulWidget {
  const DevicePairingScreen({super.key});

  @override
  ConsumerState<DevicePairingScreen> createState() =>
      _DevicePairingScreenState();
}

class _DevicePairingScreenState extends ConsumerState<DevicePairingScreen>
    with SingleTickerProviderStateMixin {
  bool _scanning = false;
  bool _paired = false;
  bool _permissionsGranted = false;
  Stream<List<ScanResult>>? _scanStream;
  late AnimationController _radarController;
  List<BluetoothDevice> _systemDevices = [];
  String? _connectedDeviceName;
  String? _connectingDeviceId;
  StreamSubscription? _btOnSub;

  Future<void> _fetchSystemDevices() async {
    try {
      final devices = await FlutterBluePlus.systemDevices([
        Guid('6E400004-B5A3-F393-E0A9-E50E24DCCA9E'),
        Guid('1812'),
        Guid('3802'),
      ]);
      if (mounted) {
        setState(() {
          _systemDevices = devices;
        });
      }
    } catch (_) {}
  }
  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBleSetup();
    });
  }

  @override
  void dispose() {
    _btOnSub?.cancel();
    ref.read(bleManagerProvider).stopScan();
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _startBleSetup() async {
    final result = await BlePermissionHandler.requestAndCheck();
    if (!mounted) return;

    if (result != BlePermissionResult.granted) {
      if (mounted) setState(() => _permissionsGranted = false);
      switch (result) {
        case BlePermissionResult.adapterOff:
          _showBluetoothOffDialog();
        case BlePermissionResult.denied:
        case BlePermissionResult.permanentlyDenied:
          _showOpenSettingsDialog();
        case BlePermissionResult.unavailable:
          _showBleUnavailableDialog();
        case BlePermissionResult.locationServicesOff:
          _showLocationServicesDialog();
        case BlePermissionResult.granted:
          break; // Unreachable
      }
      return;
    }

    if (mounted) setState(() => _permissionsGranted = true);

    // Step 2: Wait for adapter — handles iOS CBCentralManager init delay
    final adapterResult = await BleStateGuard.waitUntilReady(
      timeout: const Duration(seconds: 8),
    );
    if (!mounted) return;

    switch (adapterResult) {
      case BleAdapterReadyResult.ready:
        _startScan();
        break;
      case BleAdapterReadyResult.poweredOff:
        _showBluetoothOffDialog();
        break;
      case BleAdapterReadyResult.unavailable:
        _showBleUnavailableDialog();
        break;
      case BleAdapterReadyResult.unauthorized:
        _showOpenSettingsDialog();
        break;
      case BleAdapterReadyResult.timeout:
        // Retry once after a short delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) _startBleSetup();
        break;
    }
  }

  void _showBluetoothOffDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Bluetooth is Off'),
        content: const Text(
          'Please turn on Bluetooth to scan for nearby devices.\n\n'
          'Go to Settings → Bluetooth and turn it on, '
          'then return to SmartVital.',
        ),
        actions: [
          if (Platform.isAndroid)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await FlutterBluePlus.turnOn();
                _listenForBluetoothOn();
              },
              child: const Text('Turn On'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _listenForBluetoothOn();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _listenForBluetoothOn() {
    _btOnSub?.cancel();
    _btOnSub = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on && mounted) {
        _btOnSub?.cancel();
        _startBleSetup();
      }
    });
  }



  void _showOpenSettingsDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Permission Denied'),
      content: const Text('Please open settings and enable Bluetooth access for SmartVital.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await openAppSettings();
          },
          child: const Text('Open Settings'),
        ),
      ],
    ));
  }

  void _showBleUnavailableDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Bluetooth Unavailable'),
      content: const Text('This device (or Emulator) does not support Bluetooth hardware.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
      ],
    ));
  }

  void _showLocationServicesDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Location Services Off'),
      content: const Text('Android requires Location Services to be enabled to scan for nearby Bluetooth devices. Please turn on Location in your device settings.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _startBleSetup();
          },
          child: const Text('Retry'),
        ),
      ],
    ));
  }

  void _startScan() {
    setState(() {
      _scanning = true;
      // No name/prefix filter — stream ALL nearby BLE devices so the user can
      // pick any ring, band, or generic BLE peripheral.
      _scanStream = ref.read(bleManagerProvider).scan();
      _radarController.repeat();
    });
    _fetchSystemDevices();
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    final manager = ref.read(bleManagerProvider);

    // Determine device type from advertised name (best-effort; defaults to 'ring')
    final nameLower = device.platformName.toLowerCase();
    final deviceType = nameLower.contains('band') ? 'band' : 'ring';
    manager.setDeviceType(deviceType);

    setState(() {
      _connectingDeviceId = device.remoteId.str;
    });

    try {
      await manager.connect(device);
      if (!mounted) return;

      // ── 1. Register the device with the backend ───────────────────────────
      try {
        final api = ref.read(apiClientProvider);
        await api.postMap('/devices/pair', data: {
          'deviceSerial': device.remoteId.str,
          'deviceType': deviceType == 'ring' ? 'SMART_RING' : 'WHOOP_BAND',
          'deviceName': device.platformName.isNotEmpty
              ? device.platformName
              : 'Unknown Device',
        });
      } catch (e) {
        // Non-fatal — device may already be paired; continue
        debugPrint('Device pair API call failed (non-fatal): $e');
      }

      // ── 2. Persist for auto-reconnect on next launch ───────────────────────
      if (Hive.isBoxOpen('settings')) {
        final settings = Hive.box('settings');
        settings.put('last_device_id', device.remoteId.str);
        settings.put('last_device_type', deviceType);
      }

      if (mounted) {
        setState(() {
          _connectedDeviceName = device.platformName.isNotEmpty
              ? device.platformName
              : (deviceType == 'ring' ? 'Smart Ring' : 'Whoop Band');
          _paired = true;
          _scanning = false;
          _radarController.stop();
        });
        
        // Auto navigate to the app after showing success for a brief moment
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) _finish();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectingDeviceId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _finish() async {
    final user = ref.read(currentUserProvider);
    final profile = user?.healthProfile.copyWith(onboardingComplete: true);
    if (profile != null) {
      // 1. Save onboardingComplete: true to the local cache + state immediately
      //    so the router sees it and doesn't redirect back to onboarding.
      await ref.read(authProvider.notifier).updateHealthProfile(profile);

      // 2. Persist to the backend so subsequent logins also see the flag.
      //    saveFullHealthProfile calls PATCH /users/me/health-profile.
      await ref.read(authProvider.notifier).saveFullHealthProfile(
        profile.toJson(),
      );
    }
    if (!mounted) return;
    context.go('/home/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final deviceType =
        ref.watch(currentUserProvider)?.healthProfile.deviceType?.name ??
        'Smart Ring';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pair Device'),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(color: AppColors.background),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_permissionsGranted) ...[
                    const Spacer(),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bluetooth_disabled_rounded, size: 48, color: AppColors.danger),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const Text(
                      'Bluetooth Access Required',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.2),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Bluetooth is needed to discover and link with your device.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    SvButton(
                      label: 'Grant Permissions',
                      onPressed: _startBleSetup,
                    ),
                    const Spacer(),
                  ] else ...[
                    const SizedBox(height: AppSpacing.xl),
                    // Centered Ring pairing graphic with animation
                    Center(
                      child: SizedBox(
                        width: 240,
                        height: 240,
                        child: RiveRingWidget(
                          isPairing: _scanning && !_paired,
                          isSuccess: _paired,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      _paired
                          ? 'Found your device'
                          : _scanning
                              ? 'Searching for your $deviceType...'
                              : 'Let\'s begin by pairing your $deviceType',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.w600, 
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _paired
                          ? (_connectedDeviceName ?? 'Smart Ring Gen3')
                          : _scanning
                              ? 'Searching...'
                              : 'Nearby Devices',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.w800, 
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    
                    // Discovered devices list
                    if (_scanning && !_paired && _scanStream != null)
                      Expanded(
                        child: StreamBuilder<List<ScanResult>>(
                          stream: _scanStream,
                          builder: (context, snapshot) {
                            final scannedResults = snapshot.data ?? [];
                            
                            // Merge scanned devices and system devices
                            final allDevices = <BluetoothDevice>[];
                            final deviceIds = <String>{};
                            final rssiMap = <String, int>{};
                            final advNameMap = <String, String>{};
                            
                            // Add system devices first
                            for (final d in _systemDevices) {
                              if (deviceIds.add(d.remoteId.str)) {
                                allDevices.add(d);
                              }
                            }
                            
                            // Add scanned devices
                            for (final r in scannedResults) {
                              if (deviceIds.add(r.device.remoteId.str)) {
                                allDevices.add(r.device);
                              }
                              rssiMap[r.device.remoteId.str] = r.rssi;
                              if (r.advertisementData.advName.isNotEmpty) {
                                advNameMap[r.device.remoteId.str] = r.advertisementData.advName;
                              }
                            }

                            if (allDevices.isEmpty) {
                              return const Center(
                                child: Text(
                                  'Scanning for devices nearby...',
                                  style: TextStyle(color: AppColors.textTertiary, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              );
                            }

                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border, width: 0.5),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: ListView.separated(
                                  padding: EdgeInsets.zero,
                                  itemCount: allDevices.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 56, color: AppColors.border),
                                  itemBuilder: (context, index) {
                                    final device = allDevices[index];
                                    final rssi = rssiMap[device.remoteId.str];
                                    final advName = advNameMap[device.remoteId.str];
                                    
                                    // Resolve name: platformName -> advertisement name -> UUID fallback
                                    String name = '';
                                    if (device.platformName.isNotEmpty) {
                                      name = device.platformName;
                                    } else if (advName != null && advName.isNotEmpty) {
                                      name = advName;
                                    } else {
                                      name = device.remoteId.str;
                                    }
                                        
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      leading: const Icon(Icons.bluetooth, color: AppColors.primary, size: 22),
                                      title: Text(
                                        name, 
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 16, letterSpacing: -0.2),
                                      ),
                                      subtitle: Row(
                                        children: [
                                          if (rssi != null) ...[
                                            SignalBars(rssi: rssi),
                                            const SizedBox(width: 8),
                                            Text(
                                              '$rssi dBm', 
                                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                            ),
                                          ] else ...[
                                            const Icon(Icons.link_rounded, color: AppColors.primary, size: 14),
                                            const SizedBox(width: 6),
                                            const Text(
                                              'Connected to iOS',
                                              style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ],
                                      ),
                                      trailing: _connectingDeviceId == device.remoteId.str
                                          ? TweenAnimationBuilder<double>(
                                              tween: Tween(begin: 0.0, end: 1.0),
                                              duration: const Duration(milliseconds: 300),
                                              builder: (context, value, child) {
                                                return Container(
                                                  height: 32,
                                                  width: 110,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(16),
                                                    border: Border.all(color: AppColors.primary.withValues(alpha: value)),
                                                    color: AppColors.primary.withValues(alpha: 0.1 * value),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      const SizedBox(
                                                        width: 12,
                                                        height: 12,
                                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Connecting',
                                                        style: TextStyle(
                                                          color: AppColors.primary,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                          letterSpacing: -0.2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            )
                                          : SizedBox(
                                              height: 32,
                                              width: 80,
                                              child: SvButton(
                                                label: 'Connect',
                                                fullWidth: false,
                                                onPressed: () => _connectToDevice(device),
                                              ),
                                            ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      const Spacer(),
                  ],
                  
                  if (!_scanning && !_paired && _permissionsGranted) ...[
                    SvButton(
                      label: 'Begin Pairing',
                      onPressed: _startBleSetup,
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  SvButton(
                    label: _paired
                        ? 'Continue to App'
                        : _scanning
                            ? 'Cancel and Skip'
                            : 'Skip pairing',
                    variant: _paired ? SvButtonVariant.primary : SvButtonVariant.secondary,
                    onPressed: _finish,
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
