import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final localCacheProvider = Provider<LocalCache>((ref) => LocalCache());

class LocalCache {
  final Map<String, Map<String, dynamic>> _fallback = {};

  Future<Box<dynamic>?> _box(String name) async {
    try {
      if (Hive.isBoxOpen(name)) return Hive.box(name);
      return Hive.openBox(name);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> readMap(String boxName, String key) async {
    final box = await _box(boxName);
    final value = box?.get(key) ?? _fallback[boxName]?[key];
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  Future<void> writeMap(
    String boxName,
    String key,
    Map<String, dynamic> value,
  ) async {
    _fallback.putIfAbsent(boxName, () => {})[key] = value;
    final box = await _box(boxName);
    await box?.put(key, value);
  }

  Future<List<Map<String, dynamic>>> readMapList(
    String boxName,
    String key,
  ) async {
    final box = await _box(boxName);
    final value = box?.get(key) ?? _fallback[boxName]?[key];
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const [];
  }

  Future<void> writeMapList(
    String boxName,
    String key,
    List<Map<String, dynamic>> value,
  ) async {
    _fallback.putIfAbsent(boxName, () => {})[key] = {'items': value};
    final box = await _box(boxName);
    await box?.put(key, value);
  }
}
