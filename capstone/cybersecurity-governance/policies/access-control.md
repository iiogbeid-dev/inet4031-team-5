# Access Control Policy

**Owner:** Sam Whitfield, Platform Team lead  
**Scope:** Team 5's course Kubernetes cluster, application ServiceAccounts, and
the repository's deployment changes.  
**Review:** At each course release or after an access-control incident.

## Policy

1. Workloads must use a named ServiceAccount when one is defined for the app.
2. Workload identities must receive only the verbs and resources needed for
   their function; cluster-wide grants require a documented exception.
3. The Flask identity must not read Kubernetes Secrets or administer workloads.
4. Changes to RBAC manifests must be reviewed through a pull request before
   deployment.
5. Authentication and authorization checks must be captured with the tested
   identity, predicted result, and actual result.

## Roles and verification

Sam owns the policy; engineers implement it; Elena reviews evidence for audit.
Controls C-06 through C-09 in `../controls.csv` verify the ServiceAccount and
its effective permissions.

## Exceptions

Request an exception from Sam, document business need, expiry, compensating
controls, and approver in `../risk-register.md`. Do not grant the exception
until it is approved.
