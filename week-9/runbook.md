
# Week 9 Performance Investigation Runbook

## Incident 1: CPU Throttling Under Load

### Symptom
During the ramped k6 load test, Flask experienced CPU throttling because the Deployment's CPU limit was intentionally lowered to 100m. This limited the application's ability to process requests under heavy traffic.

### Root Cause
The Flask Deployment CPU limit was set to 100m instead of 500m. As the load increased toward 50 virtual users, the container had insufficient CPU resources.

### Fix
1. Check CPU throttling using:
   `rate(container_cpu_cfs_throttled_periods_total{container="flask"}[5m])`
2. Check the current Deployment CPU limit.
3. Restore the CPU limit using:
   `kubectl set resources deployment flask -c flask --limits=cpu=500m`
4. Verify that `infrastructure/flask.tf` also specifies 500m.
5. Rerun the k6 load test and check CPU throttling again.

### Measured Before/After vs. Stated Target
- P95 before fix: [ENTER VALUE] ms
- P95 after fix: [ENTER VALUE] ms
- CPU throttle rate before: [ENTER VALUE]
- CPU throttle rate after: 0
- Target: P95 < 500ms

---

## Incident 2: Sequential Scan on Incidents Table

### Symptom
The database was performing sequential scans when retrieving incidents filtered by status and sorted by creation date. This becomes inefficient as the number of records increases.

### Root Cause
The incidents table was missing an index on the `status` and `created_at` columns. PostgreSQL needed to scan more records to retrieve the requested results.

### Fix
1. Run `EXPLAIN (ANALYZE, BUFFERS)` to inspect the query execution plan.
2. Identify the sequential scan.
3. Create the database index:

   `CREATE INDEX CONCURRENTLY idx_incidents_status_created ON incidents(status, created_at DESC);`

4. Run `EXPLAIN (ANALYZE, BUFFERS)` again.
5. Confirm PostgreSQL uses `Index Scan` instead of `Seq Scan`.

### Measured Before/After vs. Stated Target
- Mean query time before index: [ENTER VALUE] ms
- Mean query time after index: [ENTER VALUE] ms
- Observed query execution time after index: 0.174 ms
- P95 before fix: [ENTER VALUE] ms
- P95 after fix: [ENTER VALUE] ms
- Target: P95 < 500ms

## Summary

The investigation identified two performance bottlenecks: CPU throttling and inefficient database queries. Restoring Flask's CPU limit to 500m eliminated the observed CPU throttling, while adding the composite index allowed PostgreSQL to use an index scan. Both changes improved the application's ability to handle larger workloads.

