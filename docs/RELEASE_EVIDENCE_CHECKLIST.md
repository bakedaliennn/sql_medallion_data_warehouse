# Release Evidence Checklist

**Purpose**: Standardize the artifacts required for any change (code, data, docs) to be approved for merge and production deployment.

**Status**: Approved (Phase 3: Evidence Enforcement — May 2026)  
**Owner**: Code Reviewer + Product Manager  
**Last Updated**: 2026-03-25

---

## Risk Classification Guide

Before filling evidence checklist, classify your change:

| Risk Level | Examples | Evidence Rigor | Merge Gate |
|-----------|----------|----------------|-----------|
| **Low** | Documentation typos, README updates, metadata changes, variable renames (no logic change) | Minimal (2 items) | Auto-approve if checklist complete |
| **Medium** | Single-table DDL, small Python changes, isolated feature additions, dependency updates | Standard (5-6 items) | Code Reviewer + domain owner approve |
| **High** | Cross-layer transformations, security changes, schema changes, core algorithm changes | Full (8+ items) | Code Reviewer + domain owner + Security + PM |

---

## Required Evidence by Change Type

### SQL / Data Pipeline Changes

**Risk Classification**: [Low / Medium / High]  
**Submitter**: Data Engineer or Senior Developer  
**Approval Required**: Code Reviewer + Database Optimizer

**Evidence Checklist**:

- [ ] Code review completed
  - Link to review comments / approval: [GitHub PR URL]
  - All blockers resolved: ☐ Yes ☐ No
  - Feedback-free or feedback incorporated: ☐ Both

- [ ] Quality gate results
  - SQL format check: ☐ PASS
  - Bronze layer contract check (if applicable): ☐ PASS
  - Silver layer contract check (if applicable): ☐ PASS
  - Gold layer contract check (if applicable): ☐ PASS
  - Reference to CI run: [GitHub Actions URL]

- [ ] Performance impact assessment
  - Query plan review: ☐ Completed by Database Optimizer
  - Index changes documented (if any): ☐ Yes ☐ N/A
  - Estimated execution time change: [old: Xs → new: Xs] (or N/A)
  - Database Optimizer sign-off: ☐ Approved ☐ Conditional ☐ Pending

- [ ] Data reconciliation proof (if data moving between layers)
  - Row count before/after comparison: [before: X rows → after: Y rows]
  - Sample data quality spot-check: ☐ Passed (no nulls/duplicates as expected)
  - Data freshness validated: ☐ Yes (last refresh: [timestamp])

- [ ] Rollback plan documented
  - Rollback script location: [path/to/rollback.sql]
  - Data recovery steps: [brief description of undo strategy]
  - Estimated rollback time: [X minutes]
  - Rollback tested in non-prod: ☐ Yes ☐ Not applicable

**Approval Gate**: ☐ Code Reviewer (mandatory) ☐ Database Optimizer (mandatory)

---

### Python / Export Script Changes

**Risk Classification**: [Low / Medium / High]  
**Submitter**: Data Engineer  
**Approval Required**: Code Reviewer + DevOps Automator

**Evidence Checklist**:

- [ ] Code review completed
  - Linting score: [score/10] (target: ≥ 8.0)
  - Security scan passed (no hardcoded credentials): ☐ Yes ☐ Issues found
  - Reference to review: [GitHub PR URL]

- [ ] Functional testing proof
  - Export run completed successfully: ☐ Yes ☐ Failed
  - Output file row counts match expectations: [expected: X → actual: X]
  - CSV schema validation passed: ☐ Yes ☐ Mismatch detected
  - ODBC driver detection working: ☐ Yes ☐ Manual driver required

- [ ] Performance baseline
  - Execution time: [X seconds]
  - Comparison to baseline (rolling 30-day avg): [faster/slower by X%]
  - Memory usage peak: [X MB]

- [ ] Error handling tested
  - Database connection failure: ☐ Handled gracefully (tested)
  - ODBC driver unavailable: ☐ Handled gracefully (tested)
  - File write permission denied: ☐ Handled gracefully (tested)
  - Timeout on large export: ☐ Handled gracefully (tested) ☐ N/A

**Approval Gate**: ☐ Code Reviewer (mandatory) ☐ DevOps Automator (mandatory)

---

### Documentation Changes

**Risk Classification**: [Low / Medium]  
**Submitter**: Technical Writer  
**Approval Required**: Technical Writer + Code Reviewer (if referencing code)

**Evidence Checklist**:

- [ ] Content accuracy verified
  - Tested against actual scripts/queries: ☐ Yes ☐ N/A
  - No stale references detected: ☐ Confirmed
  - Code examples are current: ☐ Yes ☐ N/A

- [ ] Completeness check
  - All referenced PRs/changes included: ☐ Yes ☐ Missing items: [list]
  - No orphaned links: ☐ Confirmed (all links tested)
  - Runbook steps verified in test environment: ☐ Yes ☐ N/A

- [ ] Link integrity check
  - All internal links work: ☐ Yes ☐ Broken links: [list]
  - External references are accessible: ☐ Yes ☐ Offline resources: [list]

**Approval Gate**: ☐ Technical Writer (mandatory) ☐ Code Reviewer if code-adjacent (optional)

---

### Decision Log Entries

**Owner**: Product Manager  
**Approval Required**: Product Manager (self-review) + any domain-specific reviewers

**Required Fields** (fill before submission):

- [ ] **Decision ID**: YYYY-MM-DD-[001]
- [ ] **Decision Title**: [clear, concise title — 5-10 words max]
- [ ] **Owner**: [agent/stakeholder name]
- [ ] **Risk Class**: [Low/Medium/High/Critical] — [brief justification]
- [ ] **Rationale**: [2-3 sentences explaining why this decision; link to evidence]
- [ ] **Trade-offs**: [What we gained] / [What we gave up]
- [ ] **Success Metric(s)**: [How we'll measure if it worked; quantified where possible]
- [ ] **Rollback Rule**: [When/how we'd reverse this decision]
- [ ] **Verification Link**: [Link to evidence artifact (PR URL, design doc, RCA)]
- [ ] **Review Date**: [When to revisit this decision — quarterly or annually]
- [ ] **Decision Status**: ☐ Draft ☐ In Review ☐ Approved ☐ Verified/Closed

**Approval Gate**: ☐ Product Manager (mandatory) ☐ Domain expert if high-risk (conditional)

---

## Release Checklist Before Deploy

**Gate Owner**: DevOps Automator + Product Manager  
**Timing**: Run 24 hours before planned deploy  
**Status Classification**: ☐ Pilot (5% of traffic) ☐ Staged (20% then 100%) ☐ Full (100% immediate)

### Pre-Deployment Validation (Run 24h before)

1. [ ] All quality gates passing for ≥ 24 consecutive hours
   - CI workflow run: [GitHub Actions URL]
   - All 7 gates: ☐ SQL Lint ☐ Bronze ☐ Silver ☐ Gold ☐ Export ☐ Security ☐ Consolidated

2. [ ] All evidence checklists completed and approved
   - Code changes: ☐ All evidence linked
   - Tests passing: ☐ Automated tests ☐ Manual spot-checks where applicable
   - Rollback plan: ☐ Tested ☐ Owner identified

3. [ ] No critical security findings open
   - Secrets scan: ☐ Clean
   - Dependency vulns: ☐ All critical closed
   - Code review security flags: ☐ None remaining

4. [ ] Rollback plan tested (if applicable)
   - Dry-run in staging: ☐ Successful
   - Rollback time confirmed: [X minutes]
   - Data recovery verified: ☐ Yes ☐ N/A

5. [ ] Stakeholders notified of planned deployment
   - Slack notification sent: ☐ Yes
   - Change ticket created: ☐ Yes [ticket URL]
   - Team ready for monitoring: ☐ On-call briefed

6. [ ] Monitoring/alerting configured for the change
   - SLO alerts active: ☐ Yes ☐ N/A
   - Error tracking enabled: ☐ Yes
   - Data freshness check scheduled: ☐ Yes ☐ N/A

7. [ ] BI reconciliation check scheduled
   - Reconciliation run: ☐ Scheduled for 24h post-deploy
   - Alert if drift detected: ☐ Config confirmed

8. [ ] All related documentation updated and published
   - README updated: ☐ Yes ☐ N/A
   - Runbooks current: ☐ Yes ☐ N/A
   - Change log entry: ☐ Yes

---

## Deploy Approval Sign-off

**Three-role approval required before proceeding to deployment:**

| Role | Name | Approval | Notes | Timestamp |
|------|------|----------|-------|-----------|
| DevOps Automator | | 🟢 APPROVED / 🟡 CONDITIONAL / 🔴 BLOCKED | [conditions if conditional] | |
| Product Manager | | 🟢 APPROVED / 🟡 CONDITIONAL / 🔴 BLOCKED | [conditions if conditional] | |
| Security Engineer | | 🟢 APPROVED / 🟡 CONDITIONAL / 🔴 BLOCKED | [conditions if conditional] | |

**Deploy Window**: [YYYY-MM-DD HH:MM UTC]  
**Estimated Duration**: [X minutes]  
**Rollback Owner** (if needed): [Name + phone/Slack]  
**On-Call Contact**: [Name + phone + Slack]  

---

## Post-Deploy Verification (Within 24h)

**Execution Owner**: Analytics Reporter + Database Optimizer  
**Timeline**: All checks must complete within 24 hours of deploy

- [ ] Core KPI metrics within expected range
  - [KPI 1]: [expected range] — actual: [value] — ☐ In range
  - [KPI 2]: [expected range] — actual: [value] — ☐ In range

- [ ] No data quality degradation detected
  - Row counts: ☐ Expected volumes flowing
  - No unexpected nulls: ☐ Confirmed
  - Duplicate check: ☐ Clean

- [ ] Export pipeline ran successfully
  - Last export time: [timestamp]
  - Export duration: [seconds] (compare to SLO: [target])
  - Row count match: ☐ Yes

- [ ] BI reconciliation check passed
  - Reconciliation run: ☐ Completed
  - Result: ☐ PASS ☐ FAIL (if fail, initiate RCA)
  - Drift detected: ☐ No ☐ Yes (if yes, investigate immediately)

- [ ] Error rates normal
  - Application error rate: [X%] (target: < 0.1%)
  - Query timeout rate: [X%] (target: < 1%)

- [ ] Performance metrics within SLO
  - Query SLO compliance: [X%] (target: > 95%)
  - P95 latency: [X seconds]

---

## Post-Deploy Sign-off

**Change Locked In** (if all verifications passed):
```
☐ All verifications passed → Change is approved and locked in production
  Post-deploy owner: [name]
  Sign-off timestamp: [timestamp]
```

**Escalation Required** (if issue detected):
```
☐ Issue detected → Immediate rollback initiated
  Issue: [description]
  RCA owner: [name]
  Rollback initiated: [timestamp]
  Rollback completed: [timestamp]
```

---

## Archive & Audit

All evidence files are retained according to:
- **Operational**: 30 days (accessible via release notes + decision log)
- **Audit**: 1 year (archived to secure storage)
- **Compliance**: 3 years (if applicable per data governance policy)

---

## v1.1 Enhancements (Scoped for Q3 2026)

- Automated evidence collection in CI/CD (pre-populate checklist from commit diff)
- GitHub branch protection rules enforcement (auto-block merge if evidence missing)
- Automated risk classification (machine learning model to suggest risk level)
