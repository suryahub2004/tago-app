import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/health/data/vitals_repository.dart';

final dailyReportProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(vitalsRepositoryProvider).getReport(period: 'daily');
});

final weeklyReportProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(vitalsRepositoryProvider).getReport(period: 'weekly');
});
