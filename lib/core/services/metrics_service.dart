import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import 'metrics_record.dart';

/// Collects client-side telemetry (API latency, error rates) and periodically
/// flushes batches to the `app_metrics` Supabase table.
///
/// - Never blocks the UI thread — record() is synchronous O(1).
/// - Flush failures are logged but never propagated to callers.
/// - Buffer is capped at [_maxBufferSize] to prevent OOM.
class MetricsService {
  MetricsService(this._client);

  final SupabaseClient _client;

  static const int _flushIntervalSeconds = 30;
  static const int _maxBufferSize = 500;
  static const int _emergencyFlushAt = 400;

  final List<MetricsRecord> _buffer = [];
  Timer? _flushTimer;
  bool _isFlushing = false;

  /// Start the periodic flush timer. Call once at app startup.
  void start() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(
      const Duration(seconds: _flushIntervalSeconds),
      (_) => flush(),
    );
  }

  /// Stop the timer and flush any remaining records.
  Future<void> dispose() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    await flush();
  }

  /// Append a metric record to the in-memory buffer. Non-blocking.
  void record(MetricsRecord r) {
    _buffer.add(r);
    if (_buffer.length >= _emergencyFlushAt) flush();
  }

  /// Wrap [action], measure its latency, record success or failure,
  /// then return the result. Exceptions are re-thrown unchanged.
  Future<T> measure<T>({
    required String table,
    required String operation,
    required Future<T> Function() action,
    Map<String, dynamic>? metadata,
  }) async {
    final sw = Stopwatch()..start();
    try {
      final result = await action();
      sw.stop();
      record(MetricsRecord(
        tableName: table,
        operation: operation,
        latencyMs: sw.elapsedMilliseconds,
        isError: false,
        metadata: metadata,
      ));
      return result;
    } catch (e) {
      sw.stop();
      record(MetricsRecord(
        tableName: table,
        operation: operation,
        latencyMs: sw.elapsedMilliseconds,
        isError: true,
        errorType: e.runtimeType.toString(),
        metadata: metadata,
      ));
      rethrow;
    }
  }

  /// Flush buffered records to Supabase. Silently handles all errors.
  Future<void> flush() async {
    if (_isFlushing || _buffer.isEmpty) return;

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      // Not authenticated yet — trim buffer to avoid OOM
      if (_buffer.length > _maxBufferSize) {
        _buffer.removeRange(0, _buffer.length - _maxBufferSize);
      }
      return;
    }

    _isFlushing = true;
    final batch = List<MetricsRecord>.from(_buffer);
    _buffer.clear();

    try {
      final rows = batch.map((r) => r.toInsertJson(userId)).toList();
      await _client.from(AppConstants.appMetricsTable).insert(rows);
    } catch (e) {
      debugPrint('[MetricsService] flush error: $e');
      // Re-buffer failed records (capped to prevent OOM)
      final space = _maxBufferSize - _buffer.length;
      if (space > 0) {
        _buffer.insertAll(0, batch.take(space));
      }
    } finally {
      _isFlushing = false;
    }
  }
}
