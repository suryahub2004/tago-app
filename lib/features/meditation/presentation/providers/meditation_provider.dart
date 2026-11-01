import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/meditation_repository.dart';

final meditationProvider = Provider<MeditationRepository>((ref) {
  return ref.watch(meditationRepositoryProvider);
});
