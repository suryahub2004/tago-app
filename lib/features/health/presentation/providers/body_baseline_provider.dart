import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final bodyBaselineProvider = Provider<double?>((ref) {
  if (!Hive.isBoxOpen('settings')) return null;
  final box = Hive.box('settings');
  return box.get('skin_temp_baseline') as double?;
});
