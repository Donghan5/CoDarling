import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import 'metrics_service.dart';

/// Singleton [MetricsService] provider.
/// Starts the flush timer on creation and disposes it when the scope is destroyed.
final metricsServiceProvider = Provider<MetricsService>((ref) {
  final service = MetricsService(ref.watch(supabaseClientProvider));
  service.start();
  ref.onDispose(service.dispose);
  return service;
});
