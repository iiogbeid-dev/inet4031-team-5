# Rebuild Gap Log

Rebuild date: Not performed in this workspace
VM: Existing Team 5 Shared VM workspace (not a clean rebuild VM)
Started from commit: `1d84d60`

The Week 13 clean-VM rebuild has not been run, so no rebuild failures or fixes
are claimed here. The following documentation gaps were found while preparing
the rebuild instructions; validate them during the scheduled clean-VM exercise.

| # | Step in README | What happened | Root cause | Fix (PR link) |
|---|---|---|---|---|
| 1 | Clone and follow the top-level README | The root README previously had no capstone bring-up instructions | Track setup existed only in the capstone guide | Added a concise Team 5 setup section; PR not opened |
| 2 | Run the evidence collector | Trivy, gitleaks, kube-score, and Checkov were unavailable in this workspace | Scanner toolchain differs from the course-provided Shared VM | Collector records missing tools as not run; verify on the rebuild VM |
| 3 | Compare image scan results | No known-good pre-remediation image tag was provided | No before-image reference was recorded in the repository | Collector requires `CYBER_IMAGE_BEFORE` and refuses to claim a comparison without it |

## What we would do differently

Run the rebuild contract on a clean Team 5 queue VM before calling the
documentation complete. Capture the tool versions, baseline image tag, exact
commands, and failures during that exercise, then replace these preparation
notes with the actual dated gap log and PR references.
