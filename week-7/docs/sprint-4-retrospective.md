# Sprint 4 Retrospective

## What Went Well

Our team was able to complete the security and backup requirements for Sprint 4. We successfully set up an automated backup workflow using GitHub Actions and tested our database recovery process. During the recovery drill, we were able to restore all 3 incident records in approximately 4 minutes, which was well below our 15-minute target. I think our team has gotten more comfortable working with Kubernetes and troubleshooting issues compared to earlier sprints.

## What Could Be Better

One thing that could be better is communication between teammates when working on different parts of the lab. Since our tasks depend on each other, it can sometimes be confusing to figure out what has already been completed and what still needs to be done. We also ran into some technical issues that took extra time to troubleshoot.

## What We'll Do Differently Next Sprint

Next sprint, we should communicate our progress more consistently and make sure everyone knows when a task is finished. We should also push our changes to GitHub as soon as they're ready so other teammates can continue their work without having to figure out what's missing.

## Team Contributions

Our team divided the work across different parts of the lab. I worked on the GitHub Actions backup workflow, completed the database recovery drill, and helped document the recovery process in our runbook. Other teammates worked on setting up MinIO, configuring restic backups, and completing the remaining security and validation tasks.

## Sprint 4 Results

- GitHub Actions backup workflow created and tested
- MinIO and restic backup system configured
- Database recovery drill completed successfully
- All 3 incident records restored
- RTO target: 15 minutes
- Actual RTO: Approximately 4 minutes
- Recovery runbook completed

## Notes

The backup workflow failed when trying to connect to MinIO from GitHub Actions, which was expected because the GitHub-hosted runner could not access our private server. This helped us understand the limitations of running automated backups from outside our network.
