
# Sprint 5 Retrospective: Week 9

## Overview

During Sprint 5, our team investigated performance issues in our incident tracker application. We seeded the PostgreSQL database with approximately 50,000 records, performed load testing with k6, investigated database queries and CPU throttling, and implemented performance improvements.

## What Went Well

Our team successfully divided the lab into separate parts, which allowed us to work on different tasks while still contributing to the overall project. We created the k6 testing scripts, added a database index, restored the Flask CPU limit to 500m, and integrated a performance testing gate into GitHub Actions.

## What Could Be Better

One challenge was coordinating tasks that depended on earlier testing results. We also found that some required documentation files were missing during final validation. Additionally, the validation script reported CPU throttling above the expected threshold, so we still need to investigate that result.

## What We'll Do Differently Next Sprint

Next sprint, we should establish clear responsibilities for each part earlier and make sure everyone updates the shared documentation as they finish. We should also run validation checks throughout the sprint instead of waiting until the end.

## Team Contributions

| Team Member | Contribution |
|---|---|
| [Name] | Week 9 setup and database preparation |
| [Name] | Baseline k6 testing |
| [Name] | Ramped load testing and performance investigation |
| Ajibola | Database index, CPU limit restoration, k6 CI gate, documentation |
| [Name] | QA and sprint coordination |

## Sprint 5 Summary

The team implemented the main performance improvements and automated testing requirements. Final validation remains in progress, particularly confirming that CPU throttling stays below the required threshold.
