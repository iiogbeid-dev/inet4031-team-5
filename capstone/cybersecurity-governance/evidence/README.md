# Evidence Directory

Run `../collect-evidence.sh` from the repository root or this directory's
parent. Each invocation writes a new UTC-timestamped subdirectory. Reports are
not overwritten.

The collector runs Kubernetes workload, RBAC, and NetworkPolicy checks and
invokes the available image/configuration/secret scanners. It reports an absent
tool or missing baseline image as **not run**, never as a pass. Network tests
create only uniquely named, resource-limited temporary pods and a temporary
namespace, then remove them.

## Authoring-workspace limitation

During authoring, kubectl/k3d and the Team 5 cluster were available, but Trivy,
gitleaks, kube-score, and Checkov were not installed. No scan report or clean
secret-scan result is claimed from this environment. No pre-remediation image
tag was supplied either. Run the collector on the course VM with the scanner
toolchain and set `CYBER_IMAGE_BEFORE` to the actual recorded baseline tag
before marking image scanning complete.

Never commit unredacted secret-scan output. The collector requests redaction
from gitleaks; inspect generated reports before committing them.
