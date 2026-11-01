import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/device_repository.dart';

final myDeviceProvider = Provider<DeviceRepository>((ref) {
  return ref.watch(deviceRepositoryProvider);
});
