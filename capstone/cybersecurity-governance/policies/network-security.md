# Network Security Policy

**Owner:** Sam Whitfield, Platform Team lead  
**Scope:** Network traffic between the nginx, Flask, database, and monitoring
workloads in the Team 5 course cluster.  
**Review:** At each course release or after a network-policy change.

## Policy

1. The database must accept traffic only from the Flask application on TCP 5432.
2. Default-deny ingress must remain in force for protected application pods.
3. Each required application or monitoring path must have a narrowly scoped
   NetworkPolicy allow rule.
4. New workloads must not be presumed isolated; their ingress behavior must be
   tested before use.
5. Negative connectivity tests must capture both the source identity/namespace
   and expected blocked destination.

## Roles and verification

Sam owns policy configuration; engineers maintain manifests; Elena reviews the
saved test evidence. Controls C-10 through C-12 in `../controls.csv` link to
the NetworkPolicy inspection and probes.

## Exceptions

Request approval from Sam, record the affected flow, expiry, and mitigation in
`../risk-register.md`, and retain the approval with the evidence. No broad
allow-all exception is permitted for the course app.
