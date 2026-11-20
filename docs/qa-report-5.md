# QA Report: Sprint 4 Week 8

QA is responsible for running all validation checks and signing off before deliverables are submitted. This report documents the validation process.

**QA Team Member:** [Name]
**Date Completed:** [Date]

---

## Validation Checks

### Check 1: MinIO Is Running

**Test:** Run `kubectl get pods -n backup -l app=minio`

**Expected:** one pod, `1/1 Running`

**Actual Result:**
```
TODO: Paste the actual output
```

**Status:** TODO: [ ] Pass [ ] Fail

**Notes:** If it is not running, check `kubectl describe pod -n backup -l app=minio`. A missing `minio-credentials` Secret (Step 3) is the most common cause.

---

### Check 2: At Least One restic Snapshot Exists

**Test:** Run `source week-8/restic-env.sh && restic snapshots`

**Expected:** At least one snapshot row

**Actual Result:**
```
TODO: Paste the actual output
```

**Status:** TODO: [ ] Pass [ ] Fail

**Notes:** `restic-env.sh` reads the passwords from `week-8/.env.backup` itself, so that file must exist on the VM. The MinIO port-forward from Step 5 must also be running, or restic reports a connection error.

---

### Check 3: Recovery Drill Succeeded

**Test:** Compare the row count recorded before the drill (Step 15) to the row count after recovery (Step 22)

**Expected:** Post-restore count matches pre-drill count

**Actual Result:**
```
TODO: Pre-drill count: ___
TODO: Post-restore count: ___
```

**Status:** TODO: [ ] Pass [ ] Fail

**Notes:** If the count came back as `0` instead of matching, the restore in Step 21 most likely replayed an empty dump. Check `restic dump --tag pre-drill latest /statustracker.sql | wc -l` -- a count of `0` means the pre-drill backup itself was empty. Flask's own `CREATE TABLE IF NOT EXISTS` recreates an empty table when it starts, which can look like a successful recovery but isn't.

---

### Check 4: Check Script Passes

**Test:** Run `chmod +x ./scripts/check-week8.sh` then `./scripts/check-week8.sh`

**Expected:** All checks pass with exit code 0

**Actual Result:**
```
TODO: Paste the full output of the check script
```

**Status:** TODO: [ ] Pass [ ] Fail

**Notes:** This script cannot verify the recovery drill itself (Check 3) -- that's confirmed manually and recorded in the Google Doc and runbook.

---

## Acceptance Criteria Verification

Review the criteria below for each part of this week's deliverables. For each criterion, record whether it was met:

### Part 1: Provision MinIO

TODO: [ ] `week-8/.env.backup` created with `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`, and `RESTIC_PASSWORD`, added to `.gitignore`
TODO: [ ] `minio-credentials` Secret created in the `backup` namespace
TODO: [ ] `week-8/minio.yaml` applied; MinIO pod `1/1 Running` in the `backup` namespace
TODO: [ ] MinIO port-forward running on the team's assigned MinIO port
TODO: [ ] `backups` bucket created (via a single combined `docker run` session -- two separate `docker run --rm` calls will not share an `mc` alias between them)

### Part 2: Configure restic Backups

TODO: [ ] `week-8/restic-env.sh` updated with the team's MinIO port, and contains no literal passwords
TODO: [ ] restic repository initialized (`restic init`)
TODO: [ ] At least one test backup taken by piping `kubectl exec deploy/db -- pg_dump ...` into `restic backup --stdin`, and `restic dump latest /statustracker.sql | wc -l` shows a non-zero line count
TODO: [ ] Retention policy applied (`restic forget --prune --keep-daily 7 --keep-weekly 4 --keep-monthly 3`)

### Part 3: Automated Backups via GitHub Actions

TODO: [ ] `.github/workflows/backup.yml` committed with a daily cron trigger and `workflow_dispatch`
TODO: [ ] `RESTIC_REPOSITORY`, `RESTIC_PASSWORD`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` stored as GitHub Actions secrets
TODO: [ ] Workflow manually triggered; screenshot captured of the run **failing** at `restic snapshots` with a connection-refused error -- this is the expected, correct result. `RESTIC_REPOSITORY` points at `http://localhost:<your MinIO port>`, which only resolves to your team's own machine locally; a GitHub-hosted runner has no path to reach it. A green checkmark here would actually indicate something is misconfigured, not the reverse.

### Part 4: Recovery Drill

TODO: [ ] Application healthy in the k3d cluster, MinIO port-forward running, and Flask replica count recorded before starting the drill
TODO: [ ] Pre-drill row count recorded (Step 16)
TODO: [ ] Fresh pre-drill backup taken with the `pre-drill` tag (Step 17)
TODO: [ ] `incidents` table dropped; `curl http://localhost:<your Kubernetes port>/incidents` confirmed an error response (Steps 18-19)
TODO: [ ] Flask scaled to 0 replicas before restoring (Step 20); `db` stays running, since a SQL restore goes through Postgres itself
TODO: [ ] Pre-drill dump replayed into the database with `restic dump ... | kubectl exec -i deploy/db -- psql ...` (Step 21)
TODO: [ ] Flask scaled back to its recorded replica count; post-restore row count matches pre-drill count (Steps 22-23)
TODO: [ ] RTO measured and recorded, compared against the 15-minute target (Step 24)

---

## Deliverables Verification

### Required Files

TODO: [ ] `week-8/minio.yaml` committed
TODO: [ ] `week-8/restic-env.sh` committed (MinIO port set, no passwords in it)
TODO: [ ] `.github/workflows/backup.yml` committed
TODO: [ ] `week-8/runbook.md` committed using the required format (Symptom, Root Cause, Fix, Measured Before/After)
TODO: [ ] `scripts/check-week8.sh` present and runs clean

### GitHub Repository

TODO: [ ] All changes merged into `main` through a pull request
TODO: [ ] No real MinIO/restic credentials appear anywhere in git history

### Google Doc

TODO: [ ] Screenshot of `restic snapshots` showing at least one snapshot is attached
TODO: [ ] Screenshot of the application error after `DROP TABLE` is attached
TODO: [ ] Screenshot of the application returning the correct row count after restore is attached
TODO: [ ] Screenshot of the backup workflow failing at `restic snapshots` (connection refused) is attached, with the reachability discussion answered
TODO: [ ] Screenshot of `./scripts/check-week8.sh` passing is attached
TODO: [ ] Recovery drill results recorded: start time, end time, measured RTO, row count before and after
TODO: [ ] Discussion answers recorded for Parts 1-4 (backup target failure domain, retention policy risk, RPO, RTO vs. target)
TODO: [ ] Week 8 storage check recorded, compared to Week 7 baseline

---

## Summary

**Overall Status:** [ ] ALL CHECKS PASS [ ] SOME CHECKS FAIL

**Blockers:** [List any blockers that prevent submission]

**Corrective Actions Taken:** [List any fixes applied during QA]

**QA Sign-Off:**

By signing below, QA certifies that all required validation checks have been executed and all deliverables meet the acceptance criteria.

**QA Signature:** _________________    **Date:** __________

---

## Notes for Sprint 5

[Any observations or recommendations for the next sprint]

# QA Report: Sprint 5 Week 9

QA is responsible for running validation checks and signing off before submission. This report documents the Week 9 performance investigation.

**QA Team Member:** [Name]
**Date Completed:** November 12, 2026

---

## Validation Checks

### Check 1: Database Row Count

**Test:** Verify the incidents table contains approximately 50,000 records.

**Expected:** Approximately 50,000 rows

**Actual Result:** 50,003 rows

**Status:** [x] Pass [ ] Fail

---

### Check 2: Database Index

**Test:** Verify idx_incidents_status_created exists.

**Expected:** Index exists and is used by PostgreSQL.

**Actual Result:**
- Index successfully created.
- EXPLAIN ANALYZE confirmed Index Scan.
- Query execution time: 0.174 ms.

**Status:** [x] Pass [ ] Fail

---

### Check 3: CPU Throttling

**Test:** Check Flask CPU throttling after restoring the CPU limit.

**Expected:** CPU throttling ratio below 0.01 (1%).

**Actual Result:**
- Initial manual validation: PASS
- Latest check-week9.sh result: 0.0560 (5.6%)
- CPU limit confirmed at 500m.

**Status:** [ ] Pass [x] Fail

**Notes:** CPU throttling exceeded the target during the latest validation. Requires another measurement and investigation before final sign-off.

---

### Check 4: k6 Performance Tests

**Test:** Run smoke-test.js and ramped-test.js.

**Expected:**
- P95 response time below 500ms for smoke test.
- Error rate below 1% for smoke test.
- Before-and-after performance measurements recorded.

**Actual Result:**
- Both scripts exist.
- Performance measurements: [Add results from Google Doc]
- Threshold verification: [Pending confirmation]

**Status:** [ ] Pass [ ] Fail

---

### Check 5: Flask CPU Limit

**Test:** Verify the live Deployment and infrastructure/flask.tf.

**Expected:** CPU limit set to 500m.

**Actual Result:**
- Live Flask CPU limit: 500m
- infrastructure/flask.tf: 500m

**Status:** [x] Pass [ ] Fail

---

### Check 6: GitHub Actions CI Gate

**Test:** Verify load-test-gate is included in ci.yml and passes in GitHub Actions.

**Expected:** k6 threshold gate exists and completes successfully.

**Actual Result:**
- load-test-gate job added.
- Changes committed and merged into main.
- GitHub Actions result: [Pending confirmation]

**Status:** [ ] Pass [ ] Fail

---

### Check 7: PostgreSQL Monitoring

**Test:** Verify pg_stat_statements is loaded.

**Expected:** pg_stat_statements appears in shared_preload_libraries.

**Actual Result:** PASS

**Status:** [x] Pass [ ] Fail

---

### Check 8: Week 9 Validation Script

**Test:** Run ./scripts/check-week9.sh.

**Expected:** All validation checks pass.

**Actual Result:**
- Passed: 13
- Failed: 2
- CPU throttling warning: 0.0560

**Status:** [ ] Pass [x] Fail

**Notes:** Initial failures were caused by missing Sprint 5 retrospective and QA report files. Both need to be created and committed.

---

## Acceptance Criteria Verification

### Part 1: Database Seeding

- [x] Database contains approximately 50,000 incident records.

### Part 2: Baseline Load Test

- [x] smoke-test.js exists.
- [ ] Baseline performance measurements verified.

### Part 3: Performance Investigation

- [x] ramped-test.js exists.
- [x] pg_stat_statements enabled.
- [ ] CPU throttling and database baseline measurements verified.

### Part 4: Performance Fixes

- [x] Database index created.
- [x] EXPLAIN ANALYZE confirms Index Scan.
- [x] Flask CPU limit restored to 500m.
- [x] infrastructure/flask.tf specifies 500m.
- [ ] Before-and-after performance comparison verified.
- [ ] CPU throttling ratio confirmed below 1%.

### Part 5: GitHub Actions

- [x] load-test-gate added to ci.yml.
- [x] Changes merged into main.
- [ ] GitHub Actions threshold gate confirmed passing.

---

## Deliverables Verification

- [x] week-9/smoke-test.js exists.
- [x] week-9/ramped-test.js exists.
- [x] week-9/runbook.md created.
- [x] Database index created.
- [x] Flask CPU limit restored.
- [x] GitHub Actions workflow updated.
- [ ] Week 9 runbook committed.
- [ ] Sprint 5 retrospective completed.
- [ ] QA report committed.
- [ ] Google Doc measurements and screenshots verified.
- [ ] check-week9.sh passes without failures or warnings.

---

## Summary

**Overall Status:** [ ] ALL CHECKS PASS [x] SOME CHECKS FAIL

**Blockers:**
- CPU throttling ratio exceeded the target during the latest check.
- Final GitHub Actions results need verification.
- Performance measurements need to be confirmed in the Google Doc.
- Sprint 5 retrospective and QA report need to be committed.

**Corrective Actions Taken:**
- Created the missing Week 9 QA report.
- Restored Flask CPU limit to 500m.
- Created the database index.
- Added the k6 threshold gate to GitHub Actions.

**QA Sign-Off:**

QA Signature: __________________

Date: __________________

---

## Notes for Sprint 6

Continue monitoring CPU throttling under load and ensure that performance improvements are preserved in future deployments.
