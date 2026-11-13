# Sprint 5 Retrospective

## What Went Well

Our team was able to build on the work we completed in previous weeks and start testing our application's performance. We successfully loaded around 50,000 records into our database and ran a baseline load test using k6. Our baseline test passed with no failed requests, which showed that our application was working well under a smaller load. I think our team has also gotten more comfortable working with Kubernetes and troubleshooting issues compared to earlier sprints.

## What Could Be Better

One thing that slowed us down was dealing with technical issues in our environment. We had trouble starting our Kubernetes cluster because of a networking conflict, which prevented us from continuing with the lab until it was fixed. Since our tasks depend on the same environment, problems like this can slow down multiple people. I also think we could improve how we communicate when completing different parts of the lab.

## What We'll Do Differently Next Sprint

Next sprint, we should check that our environment is working before dividing up tasks. We should also communicate when we finish our parts and push our changes to GitHub so everyone has access to the latest files. This would help avoid confusion and make it easier for teammates to continue where someone else left off.

## Team Contributions

| Role | Name | Primary Contribution |
|---|---|---|
| Scrum Master | TBD | Coordinated sprint tasks and retrospective |
| System Admin | TBD | Managed Kubernetes and infrastructure |
| QA | TBD | Tested and validated the application |
| Developer 1 | TBD | Database seeding and performance testing |
| Developer 2+ | TBD | Performance diagnosis and fixes |

## Sprint Goals

- Load the incident tracker database with approximately 50,000 synthetic records
- Use k6 to run baseline and ramped load tests
- Diagnose database-layer bottleneck (missing index)
- Diagnose infrastructure-layer bottleneck (CPU throttling)
- Fix both issues and measure improvement
- Add k6 threshold gate to GitHub Actions CI

## Metrics Achieved

- Database rows seeded: Approximately 50,000 (final row count to confirm)
- Baseline P95 response time: 63.31 ms
- Baseline P50 response time: 46.07 ms
- Baseline error rate: 0%
- Post-fix P95 response time: TBD
- CPU throttle rate before fix: TBD
- CPU throttle rate after fix: TBD
- k6 threshold gate: Pending verification

## Notes

The baseline k6 test passed all checks with 5 virtual users running for one minute. We recorded approximately 4.76 requests per second and a P95 response time of 63.31 ms. These results will help us compare performance before and after fixing the database and infrastructure bottlenecks.
