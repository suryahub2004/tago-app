import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/alert_repository.dart';
import '../../data/models/alert.dart';

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  return AlertRepository(ref.watch(apiClientProvider));
});

final alertsProvider = FutureProvider.autoDispose<List<AlertModel>>((ref) async {
  return ref.watch(alertRepositoryProvider).getAlerts();
});

final unreadCriticalAlertsCountProvider = Provider.autoDispose<int>((ref) {
  final alertsAsync = ref.watch(alertsProvider);
  return alertsAsync.maybeWhen(
    data: (alerts) => alerts.where((a) => !a.isAcknowledged && a.type == 'critical').length,
    orElse: () => 0,
  );
});
