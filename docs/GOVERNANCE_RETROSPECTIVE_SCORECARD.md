# Monthly Governance Retrospective Scorecard

**Purpose**: Track framework health across 11 dimensions; detect drift early; inform quarterly design reviews.

**Cadence**: First Monday of each month at 10am UTC  
**Duration**: 30 minutes (15 min scorecard review + 15 min action planning)  
**Participants**: All 11 hired agents + stakeholders  
**Output**: Scorecard archived in decision log; trends tracked for 6-month view  

---

## Scorecard Template (Copy & Fill Monthly)

### Month: [YYYY-MM]

| Dimension | Category | Baseline | Target | Actual | Status | Owner | Notes |
|-----------|----------|----------|--------|--------|--------|-------|-------|
| **SQL quality check pass rate** | Quality | — | 100% | [%] | 🟢/🟡/🔴 | Code Reviewer | Any failures tagged + RCA? |
| **Export validation success** | Quality | — | 100% | [%] | 🟢/🟡/🔴 | Data Engineer | Export time variance trending? |
| **BI reconciliation drift** | Quality | — | < 0.1% | [%] | 🟢/🟡/🔴 | Analytics Reporter | Root cause analysis done? |
| **Sprint QA first-pass rate** | Delivery | — | > 80% | [%] | 🟢/🟡/🔴 | Code Reviewer | Average retries per task? |
| **Release cycle time** | Delivery | — | < 10 days | [days] | 🟢/🟡/🔴 | Product Manager | Blockers identified? |
| **Documentation freshness** | Delivery | — | > 95% | [%] | 🟢/🟡/🔴 | Technical Writer | Stale docs corrected? |
| **Secrets in code detections** | Security | — | 0 | [#] | 🟢/🟡/🔴 | Security Engineer | Any findings? Remediation time? |
| **Security SLA compliance** | Security | — | 100% | [%] | 🟢/🟡/🔴 | Security Engineer | Findings exceeded SLA? |
| **Dependency vulnerability scans** | Security | — | 100% | [%] | 🟢/🟡/🔴 | DevOps Automator | Critical vulns closed? |
| **Query SLO compliance** | Performance | — | > 95% | [%] | 🟢/🟡/🔴 | Database Optimizer | Queries breaching SLO? |
| **Export pipeline P95 latency** | Performance | — | < 30s | [s] | 🟢/🟡/🔴 | Data Engineer | Trend improving/declining? |

---

## Key Learnings This Month

**1. What went well** (2-3 bullet points):
- [Learning 1]: [brief context; how will we repeat?]
- [Learning 2]: [brief context; how will we repeat?]
- [Learning 3]: [brief context; how will we repeat?]

**2. What could improve** (2-3 bullet points):
- [Gap 1]: [impact; root cause hypothesis]
- [Gap 2]: [impact; root cause hypothesis]
- [Gap 3]: [impact; root cause hypothesis]

**3. What we'll change next month** (2-3 action items):

| Action Item | Owner | Deadline | Expected Impact |
|-------------|-------|----------|-----------------|
| [Action 1] | [name] | [date] | [outcome if completed] |
| [Action 2] | [name] | [date] | [outcome if completed] |
| [Action 3] | [name] | [date] | [outcome if completed] |

---

## Cycle Health Assessment

Rate each dimension on 1-5 scale (5 = excellent, 1 = critical concern):

| Aspect | Rating | Assessment |
|--------|--------|------------|
| **Framework Clarity** | [1-5] | Are all agents clear on their role and responsibilities? |
| **Decision Velocity** | [1-5] | Are decisions being made and recorded on time? |
| **Evidence Quality** | [1-5] | Is evidence being linked consistently to decisions? |
| **Risk Control** | [1-5] | Are risks being identified and mitigated proactively? |
| **Scalability** | [1-5] | Is the framework able to accommodate growth without breaking? |
| **Team Morale** | [1-5] | Do agents feel the framework is enabling (not constraining)? |

**Average Score**: [sum/6] / 5.0  
**Trend vs. Last Month**: [↑ Improving / ↓ Declining / → Stable]

---

## Recommended Framework Adjustments for Next Cycle

Document any changes to framework based on this month's learnings:

- [ ] **Adjustment 1**: [Description]  
  **Rationale**: [Why this is needed]  
  **Owner**: [Name]  
  **Target Implementation**: [Month]  
  **Expected Impact**: [What improves if successful]

- [ ] **Adjustment 2**: [Description]  
  **Rationale**: [Why this is needed]  
  **Owner**: [Name]  
  **Target Implementation**: [Month]  
  **Expected Impact**: [What improves if successful]

---

## Historical Trends (Rolling 6 Months)

```
Month       | Clarity | Velocity | Evidence | Risk | Scalability | Morale | Overall
------------|---------|----------|----------|------|-------------|--------|----------
2026-03     | 9.2     | 9.1      | 9.0      | 9.5  | 9.0         | 8.8    | 9.1
2026-04     | [TBD]   | [TBD]    | [TBD]    | [TBD]| [TBD]       | [TBD]  | [TBD]
2026-05     | [TBD]   | [TBD]    | [TBD]    | [TBD]| [TBD]       | [TBD]  | [TBD]
...
```

**Trend Analysis**:
- If any dimension declining for 2+ months → escalate to quarterly design review
- If overall score < 8.0 → framework may need redesign
- If overall score consistently > 9.0 → framework validation successful

---

## Attendee Sign-off

| Role | Name | Status | Date |
|------|------|--------|------|
| Data Engineer | | ☐ Attended | |
| Database Optimizer | | ☐ Attended | |
| Analytics Reporter | | ☐ Attended | |
| DevOps Automator | | ☐ Attended | |
| Security Engineer | | ☐ Attended | |
| Code Reviewer | | ☐ Attended | |
| Technical Writer | | ☐ Attended | |
| AI Engineer | | ☐ Attended | |
| UX Architect | | ☐ Attended | |
| UI Designer | | ☐ Attended | |
| Product Manager | | ☐ Attended (Facilitator) | |

---

## Next Retrospective

**Scheduled**: [First Monday of next month] @ 10am UTC  
**Preparation**: All agents should review their scorecard contributions 24h before meeting  
**Archive**: This scorecard filed in `decision_log/retrospectives/YYYY-MM/`
