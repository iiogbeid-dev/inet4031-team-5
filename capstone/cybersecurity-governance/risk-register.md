# Risk Register

Scores use likelihood × impact, each rated 1 (low) to 5 (high). Owners are
roles from the Harborlight scenario. “Accepted” applies only to the non-
production course exercise; it is not approval for customer or production use.

| ID | Risk | Likelihood | Impact | Score | Owner | Treatment / status |
|---|---|---:|---:|---:|---|---|
| R-01 | Unassessed vulnerabilities may remain in the Flask image because the required image scanner is not available in the authoring workspace. | 3 | 4 | 12 | Sam Whitfield | Open: run Trivy before release; remediate fixable HIGH/CRITICAL findings and retain before/after reports. |
| R-02 | Sample database credentials are embedded in tracked Kubernetes manifest files. | 4 | 5 | 20 | Sam Whitfield | Open: replace with runtime secret provisioning, rotate credentials before any non-course use, and never store live values in Git. |
| R-03 | A credential may exist in Git history; full-history secret scanning has not yet run in this workspace. | 3 | 5 | 15 | Elena Brandt | Open: run redacted gitleaks over full history; rotate any confirmed live credential and document false positives without values. |
| R-04 | Workload permissions may exceed the Flask application's minimum needs if live RBAC differs from the checked-in role. | 2 | 4 | 8 | Sam Whitfield | Verify: run all recorded `kubectl auth can-i` checks as both identities; remove unneeded grants. |
| R-05 | A NetworkPolicy change could unintentionally expose the database or interrupt required app traffic. | 3 | 4 | 12 | Sam Whitfield | Verify: maintain narrow allow rules and run both blocked-path tests after each policy change. |
| R-06 | Egress is not comprehensively restricted by the current ingress-focused policy set. | 3 | 3 | 9 | Sam Whitfield | Open: decide whether the course app requires egress restrictions; document required DNS/database flows before adding default-deny egress. |
| R-07 | The database and app share one physical VM; VM loss interrupts all cluster workloads. | 3 | 4 | 12 | Marcus Reyes | Accepted for the non-production course scope only: the exercise requires zero additional spend and a single existing server. Reassess before customer data or production use. |
| R-08 | Floating image tags can make a rebuild use different upstream content than the original deployment. | 3 | 3 | 9 | Platform Team engineer | Open: pin reviewed image versions or digests and record the built app image tag with each evidence run. |
| R-09 | Evidence can become stale or misleading if it is copied from the original VM instead of regenerated after rebuild. | 3 | 4 | 12 | Elena Brandt | Open: require a fresh timestamped run, record the commit/context, and verify matrix statuses against the new output. |

Review open risks with Elena and Sam before presenting. The accepted single-VM
availability trade-off is limited to this lab; its course-scope rationale is
not a risk approval for a real deployment.
