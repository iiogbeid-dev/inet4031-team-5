# ADR-001: Security Tools and Evidence Collection

**Team:** Team 5  
**Track:** Cybersecurity and Governance  
**Date:** November 19, 2026  
**Status:** Proposed

## Context

Harborlight Logistics needs to provide security evidence for an external audit. The company already has some security controls in place, but there is not enough documentation to prove they are working.

Our team needs to review the existing Flask application and Kubernetes environment, collect security evidence, and document our findings without using paid services.

## Decision

Our team plans to use free security tools to check the application and its configurations.

We will use Trivy to scan for vulnerabilities, gitleaks to check for exposed secrets, kube-score and Checkov to review configurations, and kubectl to check access permissions and network policies.

We will save our results in GitHub and organize them using a control matrix, risk register, and security policies. We also plan to create a script to make collecting evidence easier.

## Reasoning

We chose this approach because the tools are free and work with our existing environment. Each tool checks different security issues, allowing us to review multiple parts of our system.

Using GitHub will also help us organize our findings and keep track of changes.

## Consequences

This approach allows us to check our system's security without adding extra costs. It also gives us a way to save and review our findings.

However, these tools cannot catch every security issue. Our team will still need to review the results, fix issues when possible, and document any remaining risks.

## Expected Outcome

By the end of the capstone, we plan to have security scan reports, a control matrix, a risk register, three security policies, and a script that can repeat the security checks.