# INET 4031: Team 5 Repository

This is the semester-long repository for our team's INET 4031 Systems Administration
project: an incident-tracking application built and operated across nine weeks,
moving from Docker Compose through Kubernetes, Infrastructure as Code, CI/CD,
observability, security hardening, and backup/recovery.

**The full in-depth lab instructions for every week are in the "Wiki" tab of each week's lab repository.**

## Team

**Team Name:** 5

**Team Number:** 5

**Roster:**

| Name | 
|------|
|Ajibola|
|Obehi |
|Megan |
|Jechuly|



See `team-charter.md` for role assignments and the 7-sprint rotation schedule.

## Directory Structure

```
README.md              - this file
team-charter.md         - team roles, rotation schedule, operating agreements
ansible/                - playbook that grows one role per week (Weeks 1-4)
scripts/                - validation check scripts, one per week
docs/                   - sprint retrospectives, environment log, acceptance criteria, QA reports
week-1/ .. week-9/      - per-week working directories (some weeks' real deliverables
                          live in top-level dirs instead - manifests/, infrastructure/,
                          .github/workflows/ - see each week-N README for specifics)
```

## Getting Each Week's Starter Content

Starting Week 2, each week has a corresponding `inet4031-week0N` repo with starter
and reference files for that week. You pull only what you need from it into this one
repo, it will never replace this repository.

## Team Documents

**Google Doc:** https://docs.google.com/document/d/1E9aBJ_7PBr31woAIbSlTFrklVGIhTFYxEqSZ7CEm2-c/edit?tab=t.0

All sprint reflections, screenshots, and storage-check output are recorded in this
document as each week's wiki directions require.

## Getting Started

1. Read the Week 1 wiki directions completely before beginning.
2. Follow Part 1, then Part 2, then Part 3 in order.
3. Before submitting, run `./scripts/check-week1.sh` from the repo root to verify
   all Week 1 requirements are met.
4. Reference `docs/qa-report-1.md` for the sign-off checklist.

## How to Run This: Cybersecurity Governance Track

The final-sprint governance materials are in
[`capstone/cybersecurity-governance/`](capstone/cybersecurity-governance/).
These instructions target Team 5's Shared VM (RHEL) and use only this team's
cluster and ports. Do not use them against another team's cluster.

1. Clone this repository and verify `git`, `docker`, `k3d`, `kubectl`, `jq`,
   Trivy, gitleaks, kube-score, and the Checkov virtualenv are available. See
   [`TOOL-VERSIONS.txt`](capstone/cybersecurity-governance/TOOL-VERSIONS.txt)
   for the versions recorded during authoring. Never install packages system-wide
   on the Shared VM.
2. If the `team-5` cluster is not already present, create it (no sudo):

   ```bash
   k3d cluster create team-5 --agents 2 --port "8095:80@loadbalancer" \
     --k3s-arg "--disable=traefik@server:0" --subnet 100.97.5.0/24
   ```

3. Build and import the Flask image, then apply the committed app manifests:

   ```bash
   docker build --network host -t week-2-flask:latest week-2/app
   k3d image import week-2-flask:latest -c team-5
   kubectl apply -f manifests/
   kubectl rollout status deployment/flask --timeout=120s
   kubectl rollout status deployment/db --timeout=120s
   kubectl rollout status deployment/nginx --timeout=120s
   ```

   The manifest secrets contain lab credentials. This stack is for the course
   environment only; do not connect it to production data or reuse those
   credentials. Do not run Ansible or OpenTofu on the Shared VM.
4. Follow
   [`capstone/cybersecurity-governance/RUNBOOK.md`](capstone/cybersecurity-governance/RUNBOOK.md)
   to check the app, collect evidence, and recover from common failures. The
   evidence collector writes a new timestamped directory under
   `capstone/cybersecurity-governance/evidence/`; it exits non-zero if required
   scanners, cluster checks, or the before-image input are missing.

## Questions or Issues

1. Check the troubleshooting notes in the wiki.
2. Consult with your team's System Admin and QA roles.
3. Contact the course instructor if blocked.
