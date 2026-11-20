#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
EVIDENCE_ROOT="$SCRIPT_DIR/evidence"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="$EVIDENCE_ROOT/$RUN_ID"
START_SECONDS=$SECONDS
TIME_BUDGET=240
FAILURES=0
TEST_NAMESPACE="cyber-evidence-$$"
TEMP_PODS=()

if [[ -e "$OUT" ]]; then
  echo "Evidence directory already exists: $OUT" >&2
  exit 2
fi
mkdir -p "$OUT"

cleanup() {
  for pod_ref in "${TEMP_PODS[@]}"; do
    kubectl delete pod "$pod_ref" --ignore-not-found --wait=false >/dev/null 2>&1 || true
  done
  kubectl delete namespace "$TEST_NAMESPACE" --ignore-not-found --wait=false \
    >/dev/null 2>&1 || true
}
trap cleanup EXIT

remaining_seconds() {
  local remaining=$((TIME_BUDGET - (SECONDS - START_SECONDS)))
  if (( remaining < 1 )); then
    echo 1
  else
    echo "$remaining"
  fi
}

run_capture() {
  local label="$1"
  local output="$2"
  shift 2
  local rc

  {
    printf '$'
    printf ' %q' "$@"
    printf '\n'
  } >"$output"

  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'NOT RUN: required command not found: %s\n' "$1" >>"$output"
    rc=127
  elif command -v timeout >/dev/null 2>&1; then
    timeout --signal=TERM --kill-after=5 "$(remaining_seconds)" "$@" \
      >>"$output" 2>&1
    rc=$?
  else
    "$@" >>"$output" 2>&1
    rc=$?
  fi

  printf '\nExit code: %s\n' "$rc" >>"$output"
  if (( rc != 0 )); then
    printf '%s: command failed (exit %s); see %s\n' "$label" "$rc" "$output" \
      >>"$OUT/summary.txt"
    FAILURES=$((FAILURES + 1))
  else
    printf '%s: completed; see %s\n' "$label" "$output" >>"$OUT/summary.txt"
  fi
  return 0
}

run_scanner() {
  local label="$1"
  local report="$2"
  local command_name="$3"
  shift 3
  local rc
  local log="${report%.json}.log"

  {
    printf '$'
    printf ' %q' "$@"
    printf '\n'
  } >"$log"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'NOT RUN: required scanner not found: %s\n' "$command_name" \
      >"${report%.json}.NOT-RUN.txt"
    printf 'Exit code: 127\n' >>"$log"
    FAILURES=$((FAILURES + 1))
    printf '%s: scanner not found; see %s\n' "$label" "${report%.json}.NOT-RUN.txt" \
      >>"$OUT/summary.txt"
    return 0
  fi

  if (( SECONDS - START_SECONDS >= TIME_BUDGET )); then
    printf 'NOT RUN: collector time budget exhausted before %s\n' "$label" \
      >"${report%.json}.NOT-RUN.txt"
    printf 'Exit code: 124\n' >>"$log"
    FAILURES=$((FAILURES + 1))
    printf '%s: time budget exhausted\n' "$label" >>"$OUT/summary.txt"
    return 0
  fi

  timeout --signal=TERM --kill-after=5 "$(remaining_seconds)" "$@" \
    >>"$log" 2>&1
  rc=$?
  printf '\nExit code: %s\n' "$rc" >>"$log"
  if (( rc != 0 )); then
    FAILURES=$((FAILURES + 1))
    printf '%s: command failed (exit %s); see %s\n' "$label" "$rc" "$log" \
      >>"$OUT/summary.txt"
  else
    printf '%s: completed; see %s\n' "$label" "$report" >>"$OUT/summary.txt"
  fi
}

printf 'Evidence run: %s\n' "$RUN_ID" >"$OUT/summary.txt"
printf 'Repository: %s\n' "$REPO_ROOT" >"$OUT/metadata.txt"
git -C "$REPO_ROOT" rev-parse HEAD >>"$OUT/metadata.txt" 2>&1 || true
git -C "$REPO_ROOT" status --short >>"$OUT/metadata.txt" 2>&1 || true
kubectl config current-context >>"$OUT/metadata.txt" 2>&1 || true
date -u --iso-8601=seconds >>"$OUT/metadata.txt" 2>&1 || date -u >>"$OUT/metadata.txt"

run_capture "Cluster nodes" "$OUT/cluster-nodes.txt" \
  kubectl get nodes -o wide
run_capture "Application deployments" "$OUT/application-deployments.txt" \
  kubectl get deployments flask db nginx -o wide
run_capture "NetworkPolicies" "$OUT/network-policies.txt" \
  kubectl get networkpolicy -n default -o wide
run_capture "Flask security context" "$OUT/flask-security-context.txt" \
  kubectl get deployment flask -n default \
  -o 'jsonpath={.spec.template.spec.containers[0].securityContext}{"\n"}'
run_capture "Flask ServiceAccount assignment" "$OUT/flask-serviceaccount-assignment.txt" \
  kubectl get deployment flask -n default \
  -o 'jsonpath={.spec.template.spec.serviceAccountName}{"\n"}'
run_capture "Flask ServiceAccount configuration" "$OUT/flask-serviceaccount-config.txt" \
  kubectl get serviceaccount flask-app -n default \
  -o 'jsonpath={.automountServiceAccountToken}{"\n"}'

IMAGE_AFTER="$(kubectl get deployment flask -n default \
  -o 'jsonpath={.spec.template.spec.containers[0].image}' 2>/dev/null || true)"
if [[ -z "$IMAGE_AFTER" ]]; then
  IMAGE_AFTER="week-2-flask:latest"
fi
printf 'Live Flask image: %s\n' "$IMAGE_AFTER" >"$OUT/image-targets.txt"

if [[ -n "${CYBER_IMAGE_BEFORE:-}" ]]; then
  printf 'Before image: %s\n' "$CYBER_IMAGE_BEFORE" >>"$OUT/image-targets.txt"
  run_scanner "Before-image vulnerability scan" \
    "$OUT/trivy-image-before.json" trivy \
    trivy image --scanners vuln --format json --output "$OUT/trivy-image-before.json" \
    --timeout 90s --exit-code 0 "$CYBER_IMAGE_BEFORE"
else
  printf 'NOT RUN: set CYBER_IMAGE_BEFORE to the recorded pre-remediation image tag.\n' \
    >"$OUT/trivy-image-before.NOT-RUN.txt"
  printf 'No before-image supplied; no before/after comparison can be claimed.\n' \
    >>"$OUT/image-targets.txt"
  FAILURES=$((FAILURES + 1))
fi

run_scanner "Live-image vulnerability scan" "$OUT/trivy-image-after.json" trivy \
  trivy image --scanners vuln --format json --output "$OUT/trivy-image-after.json" \
  --timeout 90s --exit-code 0 "$IMAGE_AFTER"
run_scanner "Manifest configuration scan" "$OUT/trivy-manifests.json" trivy \
  trivy config --format json --output "$OUT/trivy-manifests.json" \
  --timeout 90s "$REPO_ROOT/manifests"

if command -v gitleaks >/dev/null 2>&1; then
  (
    cd "$REPO_ROOT" &&
      gitleaks git --redact --report-format json \
        --report-path "$OUT/gitleaks-report.json"
  ) >"$OUT/gitleaks.log" 2>&1
  GITLEAKS_RC=$?
  printf 'Exit code: %s\n' "$GITLEAKS_RC" >>"$OUT/gitleaks.log"
  if (( GITLEAKS_RC != 0 )); then
    FAILURES=$((FAILURES + 1))
    printf 'Full-history gitleaks: findings or command error (exit %s); inspect the redacted report and log\n' \
      "$GITLEAKS_RC" >>"$OUT/summary.txt"
  else
    printf 'Full-history gitleaks: completed; redacted report at %s\n' \
      "$OUT/gitleaks-report.json" >>"$OUT/summary.txt"
  fi
else
  printf 'NOT RUN: gitleaks is not installed; no secrets scan result is claimed.\n' \
    >"$OUT/gitleaks-report.NOT-RUN.txt"
  FAILURES=$((FAILURES + 1))
  printf 'Full-history gitleaks: scanner not found\n' >>"$OUT/summary.txt"
fi

CHECKOV_BIN="${CHECKOV_BIN:-$HOME/cybersecurity-governance-venv/bin/checkov}"
if [[ -x "$CHECKOV_BIN" ]]; then
  run_capture "Kubernetes manifest policy scan" "$OUT/checkov-manifests.txt" \
    "$CHECKOV_BIN" -d "$REPO_ROOT/manifests" --framework kubernetes
else
  printf 'NOT RUN: Checkov not found at %s; install it in the course virtualenv.\n' \
    "$CHECKOV_BIN" >"$OUT/checkov-manifests.NOT-RUN.txt"
  FAILURES=$((FAILURES + 1))
fi

if command -v kube-score >/dev/null 2>&1; then
  {
    printf '$ kubectl get deployment flask db nginx -o yaml | kube-score score -\n'
    kubectl get deployment flask db nginx -n default -o yaml 2>&1 |
      kube-score score - 2>&1
    PIPE_RC=("${PIPESTATUS[@]}")
    printf '\nExit codes: kubectl=%s kube-score=%s\n' \
      "${PIPE_RC[0]}" "${PIPE_RC[1]}"
    if (( PIPE_RC[0] != 0 || PIPE_RC[1] != 0 )); then
      FAILURES=$((FAILURES + 1))
    fi
  } >"$OUT/kube-score-live-workloads.txt"
else
  printf 'NOT RUN: kube-score is not installed.\n' \
    >"$OUT/kube-score-live-workloads.NOT-RUN.txt"
  FAILURES=$((FAILURES + 1))
fi

{
  printf 'identity\tverb\tresource\texpected\tactual\tresult\n'
  RBAC_CASES=(
    'system:serviceaccount:default:flask-app|get|configmaps|yes'
    'system:serviceaccount:default:flask-app|list|configmaps|yes'
    'system:serviceaccount:default:flask-app|get|secrets|no'
    'system:serviceaccount:default:flask-app|get|pods|no'
    'system:serviceaccount:default:flask-app|create|configmaps|no'
    'system:serviceaccount:default:default|get|configmaps|no'
    'system:serviceaccount:default:default|get|secrets|no'
    'system:serviceaccount:default:default|get|pods|no'
  )
  for case in "${RBAC_CASES[@]}"; do
    IFS='|' read -r identity verb resource expected <<<"$case"
    actual="$(kubectl auth can-i "$verb" "$resource" --as="$identity" \
      -n default 2>&1)"
    rc=$?
    if (( rc <= 1 )) && [[ "$actual" == "$expected" ]]; then
      result="PASS"
    else
      result="FAIL"
      FAILURES=$((FAILURES + 1))
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$identity" "$verb" "$resource" \
      "$expected" "$actual" "$result"
  done
} >"$OUT/rbac-checks.txt"

probe_network_policy() {
  local namespace="$1"
  local pod="$2"
  local target="db.default.svc.cluster.local"
  local report="$3"

  {
    printf 'Test: pod in namespace %s must not connect to %s:5432\n' \
      "$namespace" "$target"
    printf 'Expected: DNS resolves; TCP connection is blocked by NetworkPolicy.\n'
  } >"$report"

  local overrides
  overrides="$(printf '{"apiVersion":"v1","spec":{"containers":[{"name":"%s","image":"busybox:1.36","command":["sleep"],"args":["180"],"resources":{"requests":{"cpu":"10m","memory":"16Mi"},"limits":{"cpu":"100m","memory":"32Mi"}}}]}}' "$pod")"
  if ! kubectl run "$pod" -n "$namespace" --image=busybox:1.36 \
    --restart=Never --overrides="$overrides" \
    >>"$report" 2>&1; then
    printf 'RESULT: ERROR - unable to create the temporary test pod.\n' >>"$report"
    FAILURES=$((FAILURES + 1))
    return
  fi
  TEMP_PODS+=("$namespace/$pod")

  if ! kubectl wait --for=condition=Ready "pod/$pod" -n "$namespace" \
    --timeout=50s >>"$report" 2>&1; then
    printf 'RESULT: ERROR - test pod did not become ready; not counted as blocked.\n' \
      >>"$report"
    FAILURES=$((FAILURES + 1))
    return
  fi

  if ! kubectl exec "$pod" -n "$namespace" -- nslookup "$target" \
    >>"$report" 2>&1; then
    printf 'RESULT: ERROR - DNS failed; not counted as a NetworkPolicy block.\n' \
      >>"$report"
    FAILURES=$((FAILURES + 1))
    return
  fi

  if kubectl exec "$pod" -n "$namespace" -- nc -z -w 3 "$target" 5432 \
    >>"$report" 2>&1; then
    printf 'RESULT: FAIL - TCP connection unexpectedly succeeded.\n' >>"$report"
    FAILURES=$((FAILURES + 1))
  else
    printf 'RESULT: PASS - TCP connection was blocked after DNS succeeded.\n' \
      >>"$report"
  fi
}

{
  printf 'NetworkPolicy negative tests; only temporary pods created by this script are used.\n'
  printf 'The temporary test namespace is %s.\n' "$TEST_NAMESPACE"
} >"$OUT/netpol-tests.txt"
probe_network_policy default "cyber-evidence-default-$$" \
  "$OUT/netpol-default-namespace.txt"
if kubectl create namespace "$TEST_NAMESPACE" >>"$OUT/netpol-tests.txt" 2>&1; then
  probe_network_policy "$TEST_NAMESPACE" "cyber-evidence-other-$$" \
    "$OUT/netpol-other-namespace.txt"
else
  printf 'RESULT: ERROR - unable to create a temporary namespace; second test not run.\n' \
    >"$OUT/netpol-other-namespace.txt"
  FAILURES=$((FAILURES + 1))
fi
cat "$OUT/netpol-default-namespace.txt" "$OUT/netpol-other-namespace.txt" \
  >>"$OUT/netpol-tests.txt"

ELAPSED=$((SECONDS - START_SECONDS))
{
  printf '\nElapsed seconds: %s\n' "$ELAPSED"
  printf 'Failure/not-run count: %s\n' "$FAILURES"
  if (( ELAPSED < 300 )); then
    printf 'Five-minute target: met for this collector run.\n'
  else
    printf 'Five-minute target: NOT met for this collector run.\n'
  fi
  printf 'Evidence directory: %s\n' "$OUT"
} >>"$OUT/summary.txt"
cat "$OUT/summary.txt"

if (( FAILURES > 0 || ELAPSED >= 300 )); then
  exit 1
fi
