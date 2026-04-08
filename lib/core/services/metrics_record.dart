/// Immutable data point buffered by [MetricsService] before being flushed
/// to the `app_metrics` Supabase table.
class MetricsRecord {
  const MetricsRecord({
    required this.tableName,
    required this.operation,
    required this.latencyMs,
    required this.isError,
    this.errorType,
    this.metadata,
  });

  final String tableName;
  final String operation;
  final int latencyMs;
  final bool isError;
  final String? errorType;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toInsertJson(String userId) => {
        'user_id': userId,
        'table_name': tableName,
        'operation': operation,
        'latency_ms': latencyMs,
        'is_error': isError,
        if (errorType != null) 'error_type': errorType,
        if (metadata != null) 'metadata': metadata,
      };
}
