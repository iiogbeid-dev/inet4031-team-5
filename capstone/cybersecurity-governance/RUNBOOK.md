# Cybersecurity Governance Runbook

This runbook is for Team 5's Shared VM (RHEL) and its `team-5` k3d cluster.
Run commands as the normal course user; do not use sudo, Ansible, or OpenTofu
on the Shared VM. These instructions are for the course environment, not
production.

## 1. Prerequisites and first bring-up

Start from the repository root. Verify the tools listed in
[`TOOL-VERSIONS.txt`](TOOL-VERSIONS.txt) and in the capstone guide's Tools
Available section. Trivy, gitleaks, kube-score, Checkov, jq, kubectl, Docker,
and k3d are expected on the course VM. Install Checkov only in the documented
user virtualenv; never use system pip.

If the cluster does not exist, create the Team 5 cluster:

```bash
k3d cluster create team-5 --agents 2 --port "8095:80@loadbalancer" \
  --k3s-arg "--disable=traefik@server:0" --subnet 100.97.5.0/24
kubectl config use-context k3d-team-5
```

Build/import the app image, then apply the application and security manifests:

```bash
docker build --network host -t week-2-flask:latest week-2/app
k3d image import week-2-flask:latest -c team-5
kubectl apply -f manifests/
kubectl rollout status deployment/flask --timeout=120s
kubectl rollout status deployment/db --timeout=120s
kubectl rollout status deployment/nginx --timeout=120s
kubectl get nodes
kubectl get pods -A
```

If the existing deployment already uses a team-specific tag, build and import
that same tag instead; do not overwrite an image while it is running. The
manifests contain sample lab credentials; do not use this setup with production
data or real customer credentials.

## 2. Operate and check the application

```bash
kubectl get deployments,services,pods -n default -o wide
kubectl get networkpolicy -n default
kubectl get serviceaccount flask-app -n default -o yaml
curl -fsS http://localhost:8095/health
```

The HTTP check assumes the k3d load-balancer port mapping above. If the course
VM maps a different Team 5 port, use the port recorded by the VM administrator.
Check live health without printing Secret values:

```bash
kubectl rollout status deployment/flask --timeout=120s
kubectl rollout status deployment/db --timeout=120s
kubectl logs deployment/flask --tail=50
kubectl logs deployment/db --tail=50
kubectl get endpoints flask db nginx
```

Do not use `kubectl get secret -o yaml` in evidence or terminal recordings.

## 3. Collect audit evidence

Record a baseline image tag before remediation. The collector needs the
pre-remediation image as `CYBER_IMAGE_BEFORE`; it reads the live image from the
Flask Deployment for the after scan.

```bash
export CYBER_IMAGE_BEFORE='week-2-flask:<recorded-before-tag>'
./capstone/cybersecurity-governance/collect-evidence.sh
```

The script writes all output under
`capstone/cybersecurity-governance/evidence/<UTC timestamp>/`. A non-zero exit
means a required check failed, a tool/input was unavailable, or the five-minute
target was exceeded. Read `summary.txt`, then inspect the associated `.txt`,
`.log`, or redacted `.json` files. A scanner exit code can mean findings, so
review the report rather than treating every non-zero code identically.

The collector checks the Flask security context, cluster/deployments, 8
predicted `kubectl auth can-i` outcomes, and two negative database connectivity
tests. The network tests use temporary BusyBox pods (CPU/memory bounded), one
in `default` and one in a temporary namespace. The script cleans them up on
exit. Do not copy a report into the control matrix until its output has been
reviewed and the result matches the control's expected value.

Gitleaks is invoked with redaction and scans this repository's Git history.
Inspect its report for unresolved findings; do not commit a report containing
unredacted values. A confirmed credential must be rotated, not merely removed
from the current manifest.

## 4. Routine checks

```bash
kubectl get nodes
kubectl get pods -A
kubectl get networkpolicy -n default
kubectl auth can-i get secrets \
  --as=system:serviceaccount:default:flask-app -n default
git status --short
```

The Flask identity should not read Secrets. Run the full evidence script after
manifest, image, RBAC, or NetworkPolicy changes and before the final
presentation. Use only this team's cluster and image.

## 5. Recovery

### A workload is not ready

```bash
kubectl describe deployment flask
kubectl get pods -n default -o wide
kubectl describe pod <flask-pod-name> -n default
kubectl logs deployment/flask --tail=100
```

Confirm the image tag exists locally and was imported into `team-5`. Rebuild
from `week-2/app`, import the intended tag, and re-apply the manifest. Do not
delete the database PVC to troubleshoot app availability.

### Network access is broken

Inspect policies and labels before changing anything:

```bash
kubectl get networkpolicy -n default -o yaml
kubectl get pods -n default --show-labels
kubectl get endpoints db flask nginx
```

Restore only the intended narrow application paths from the reviewed manifests.
Do not remove `default-deny-ingress` or add an allow-all rule as a shortcut.
Re-run the evidence collector and verify both negative probes still block.

### A manifest change broke the deployment

Use the reviewed version from the current branch/PR and re-apply the specific
manifest. For an application rollback, inspect revisions first:

```bash
kubectl rollout history deployment/flask
kubectl rollout undo deployment/flask
kubectl rollout status deployment/flask --timeout=120s
```

Re-apply only the manifest files involved after review; avoid applying an old
directory snapshot that could revert unrelated resources. Preserve the DB
PersistentVolumeClaim and volume data.

### Cluster is unavailable

Check `k3d cluster list`, `kubectl config current-context`, and the course VM
status. If the cluster must be recreated, use the exact Team 5 cluster command
in Section 1, rebuild/import the image, and apply `manifests/`. Recreating a
cluster does not restore persistent database contents or Prometheus history;
restore data only from the course's approved backup process.

## 6. Rebuild and evidence integrity

The clean-VM rebuild has not yet been performed as of the authoring run. Follow
the course [REBUILD instructions](https://github.com/INET4031-Labs/inet4031-capstone-guide/blob/main/REBUILD.md)
on the scheduled Team 5 queue VM, log every unmentioned step in
[`REBUILD-GAPS.md`](REBUILD-GAPS.md), and replace the recorded tool versions
with those actually used. Do not claim proof-of-life until a fresh evidence
directory is produced and its results are checked against `controls.csv`.
