**Incident:** Database data loss recovery

**Symptom:** Application returned a 500 Internal Server Error when trying to retrieve incidents because the incidents table was missing.

**Root Cause:** The incidents table was intentionally deleted using DROP TABLE incidents; to simulate data loss.

**Fix:**
1. Stop Flask to prevent writes: kubectl scale deployment flask --replicas=0
2. Identify the clean backup snapshot: restic snapshots
3. Restore the database: restic dump d22cc997 /statustracker.sql | kubectl exec -i deploy/db -- psql -U appuser -d statustracker
4. Import the Flask image and restart Flask: k3d image import week-2-flask:latest -c team-5 && kubectl scale deployment flask --replicas=1
5. Verify that the database contains 3 incidents and the application returns the records successfully

**Measured Before/After vs. Stated Target:**
- Row count before incident: 3
- Row count after restore: 3
- RTO target: 15 minutes
- Actual RTO: Approximately 4 minutes
