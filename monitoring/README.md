# CoDarling Monitoring

Prometheus-compatible metrics endpoint via Supabase Edge Function,
visualized in Grafana.

## Architecture

```
Flutter App
  → MetricsService (buffers in memory, flushes every 30s)
  → app_metrics table (Supabase)

Supabase Edge Function GET /functions/v1/metrics
  → queries users, couples, photos counts  (server metrics)
  → aggregates app_metrics last 5 min       (client traffic)
  → returns Prometheus text format

Grafana Agent (running anywhere)
  → scrapes /metrics every 60s
  → remote_write → Grafana Cloud (or local Prometheus)

Grafana Dashboard
  → codarling_users_total
  → codarling_couples_total{status}
  → codarling_photos_today / codarling_photos_total
  → codarling_db_response_ms
  → codarling_requests_total{table, operation}
  → codarling_errors_total{table, operation}
  → codarling_latency_ms{table, operation, quantile}
```

## Setup

### 1. Apply migrations

Run `20260408100000_app_metrics.sql` in Supabase SQL editor:
- Creates `app_metrics` table (Flutter telemetry buffer)
- Creates `get_couple_counts()` RPC (used by Edge Function)
- Creates `cleanup_old_metrics()` function

Optionally enable the cleanup cron job (requires pg_cron on Pro plan):
```sql
select cron.schedule('cleanup-old-metrics', '0 3 * * *', 'select public.cleanup_old_metrics()');
```

### 2. Deploy the Edge Function

```bash
supabase functions deploy metrics --project-ref ecdshhuvypmgxalpriab
```

### 3. Verify the endpoint

```bash
curl -H "Authorization: Bearer <METRICS_SECRET>" \
  https://ecdshhuvypmgxalpriab.supabase.co/functions/v1/metrics
```

The `METRICS_SECRET` was set via `supabase secrets set METRICS_SECRET=...`. It is stored in
`.dart_define.json` under key `METRICS_SECRET` for local reference.

Expected output (Prometheus text format):
```
# HELP codarling_users_total Total registered users
# TYPE codarling_users_total gauge
codarling_users_total 2
...
```

### 4. Set up Grafana Cloud

1. Sign up at https://grafana.com/auth/sign-up/create-user (free tier)
2. Go to **My Account → Grafana Cloud → Details**
3. Note your **Prometheus remote_write URL**, **Instance ID**, and generate an **API key**

### 5. Install and run Grafana Agent

**Linux (no Docker):**
```bash
# Download
curl -Lo grafana-agent.zip \
  https://github.com/grafana/agent/releases/latest/download/grafana-agent-linux-amd64.zip
unzip grafana-agent.zip
chmod +x grafana-agent-linux-amd64

# Run
export SUPABASE_PROJECT_REF=ecdshhuvypmgxalpriab
export METRICS_SECRET=<your_metrics_secret>  # from supabase secrets / .dart_define.json
export PROMETHEUS_URL=<grafana_cloud_remote_write_url>
export PROMETHEUS_USER=<grafana_cloud_instance_id>
export PROMETHEUS_PASSWORD=<grafana_cloud_api_key>

./grafana-agent-linux-amd64 --config.file=./monitoring/grafana-agent.yaml
```

### 6. Create Grafana dashboards

Import a new dashboard in Grafana and add panels with these PromQL queries:

| Panel | Query |
|-------|-------|
| Total users | `codarling_users_total` |
| Active couples | `codarling_couples_total{status="active"}` |
| Photos today | `codarling_photos_today` |
| DB health (ms) | `codarling_db_response_ms` |
| Request rate | `sum by (table, operation)(codarling_requests_total)` |
| Error rate % | `sum(codarling_errors_total) / sum(codarling_requests_total) * 100` |
| p95 latency | `codarling_latency_ms{quantile="0.95"}` |

## Metrics Reference

| Metric | Type | Description |
|--------|------|-------------|
| `codarling_users_total` | gauge | Total registered users |
| `codarling_couples_total{status}` | gauge | Couples by status (active/pending) |
| `codarling_photos_today` | gauge | Photos posted today |
| `codarling_photos_total` | gauge | Total photos all time |
| `codarling_db_response_ms` | gauge | Database health probe latency |
| `codarling_requests_total{table,operation}` | gauge | Client API calls (last 5 min) |
| `codarling_errors_total{table,operation}` | gauge | Client API errors (last 5 min) |
| `codarling_latency_ms{table,operation,quantile}` | gauge | Client latency p50/p95/p99 (last 5 min, ms) |
