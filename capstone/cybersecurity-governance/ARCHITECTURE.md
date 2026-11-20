# Architecture and Evidence Flow

## Current deployment

```mermaid
flowchart TB
    subgraph VM["Team 5 Shared VM (RHEL)"]
        subgraph K3D["k3d cluster: team-5 (K3s)"]
            IN["nginx ingress / service"]
            APP["Flask Deployment\nweek-2-flask:latest"]
            DB["PostgreSQL Deployment\npersistent volume"]
            PROM["Prometheus\nmonitoring namespace"]
            IN --> APP
            APP --> DB
            PROM --> APP
        end
        TOOLS["Host CLI tools\nkubectl, Trivy, gitleaks,\nkube-score, Checkov, jq"]
        REPO["Git repository\nmanifests/, week-2/app/"]
        COLLECT["collect-evidence.sh"]
        EVID["evidence/<UTC timestamp>/"]
        REPO --> COLLECT
        TOOLS --> COLLECT
        K3D --> COLLECT
        COLLECT --> EVID
        CM["controls.csv"]
        RR["risk-register.md"]
        POL["policies/"]
        EVID --> CM
        CM --> RR
        POL --> CM
    end
    CLIENT["Course users"] -->|"Team 5 port 8095"| IN
```

The app and cluster are existing course components. The new governance
components are the control matrix, risk register, policies, runbook,
architecture description, QA report, and evidence collector/output.

## What we changed and why

- Added a collector that records command, output, exit status, and commit context
  into a fresh UTC-stamped evidence directory.
- Captured actual RBAC predictions/results and two default-deny NetworkPolicy
  probes using temporary, resource-limited test pods.
- Separated an explicitly supplied before-image from the live after-image so a
  scan comparison cannot silently compare an image to itself.
- Added governance documents linking control IDs to test evidence and the
  responsible Harborlight role.

The scanner outputs and cluster observations are environment-specific. A
missing scanner or before-image is recorded as not run; it is not represented as
a passing control.

