# SLO Tracking Dashboard Specification

**Purpose**: Monitor query performance against established SLOs and trigger optimization actions when thresholds are breached.

**Status**: Approved for Implementation (Phase 2: April 2026)  
**Owner**: Database Optimizer + Analytics Reporter  
**Last Updated**: 2026-03-25

---

## SLO Definitions

| Query Pattern | P95 Target | P99 Target | Breach Protocol | Owner |
|--------------|-----------|-----------|-----------------|-------|
| Gold semantic reads | 2.0s | 3.5s | 2 consecutive breaches → Database Optimizer review within 24h | Database Optimizer |
| Monthly reporting views | 3.0s | 5.0s | Immediate escalation if > 5.0s; page on-call | Analytics Reporter |
| Fact-level analytical joins | 4.0s | 7.0s | Index effectiveness audit within 48h | Database Optimizer |
| Export to CSV pipeline | 30s | 60s | Check for data volume growth or new transformations | Data Engineer |
| BI reconciliation check | < 100ms | < 200ms | Manual investigation if drift detected; check data freshness | Analytics Reporter |

---

## Dashboard Metrics

### Real-Time Performance Panel
- Query execution time distribution (P50, P75, P95, P99)
- Active query count and queue depth
- Connection pool utilization (ODBC connections, threads)
- Error rate by query pattern (target: < 0.1%)

### SLO Compliance Panel
- Pass/fail status per query SLO (🟢/🟡/🔴)
- Trend visualization (30-day rolling window)
- Days since last breach
- Breach count this month (compared to last month)

### Index Effectiveness Panel
- Queries using sequential scans (should be < 5% of queries)
- Index fragmentation by table (< 10%)
- Unused indexes in gold schema (candidates for cleanup)
- Missing index recommendations (from sys.dm_db_missing_index_details)

### Data Freshness Panel
- Export run completion time (last run timestamp)
- BI reconciliation pass rate (%)
- Replication lag to reporting views (if applicable)
- Last successful gold refresh timestamp

---

## Alert Rules

| Condition | Severity | Owner | Action | SLA |
|-----------|----------|-------|--------|-----|
| Query P95 > SLO for 2 consecutive runs | High | Domain Owner | Page owner; investigate within 24h | 24h |
| Query error rate > 1% | Critical | DevOps Automator | Immediate escalation; page on-call | 1h |
| Export pipeline P95 > 60s | High | Data Engineer + DevOps | Page owners; check data volume + log | 2h |
| BI reconciliation drift detected | Medium | Analytics Reporter | Notify reporter; auto-run quality_checks_gold.sql | 4h |
| Index fragmentation > 30% | Medium | Database Optimizer | Schedule maintenance window | 48h |
| Connection pool utilization > 80% | Medium | DevOps Automator | Investigate connection leaks; assess pooling needs | 24h |

---

## Data Sources

**SQL Server DMVs:**
- `sys.dm_exec_query_stats` — Query execution times (P95/P99)
- `sys.dm_exec_requests` — Active queries
- `sys.dm_db_index_physical_stats` — Index fragmentation
- `sys.dm_db_missing_index_details` — Index recommendations
- `sys.dm_os_waiting_tasks` — Query wait analysis

**Application Logs:**
- Export run timestamps and row counts
- Export error logs (ODBC connection failures, file write errors)
- BI platform reconciliation check pass/fail + timestamps

**Manual Inputs:**
- Planned maintenance windows
- Known performance anomalies (during data loads, reindexing)

---

## Implementation Phases

### Phase 1: Data Collection (April 2026 — Week 1-2)
- Wire SQL queries to capture metrics from DMVs every 5 minutes
- Create temp staging table to persist query metrics
- Export metrics feed for dashboard consumption
- **Owner**: Database Optimizer + Data Engineer
- **Success Criteria**: Metrics captured every 5 min; no gaps > 10 min

### Phase 2: Dashboard Build (April 2026 — Week 3-4)
- Implement Power BI / Tableau dashboard
- Connect to metrics feed
- Build real-time performance + SLO compliance panels
- Test alert triggers
- **Owner**: Analytics Reporter
- **Success Criteria**: Dashboard deployed; all metrics visible; alert rules firing correctly

### Phase 3: Operationalization (May 2026)
- Alert integration (email, Slack, on-call paging)
- Runbook creation (what to do when alert fires)
- Team training on dashboard interpretation
- **Owner**: DevOps Automator + Analytics Reporter
- **Success Criteria**: Alerts route to correct teams; first 3 breaches handled per protocol

---

## Success Criteria

1. Dashboard updated automatically every 5 minutes with current metrics
2. Alerts triggered within 5 minutes of SLO breach
3. Historical trending data retained for 90 days (enables root cause analysis)
4. No false positives (>95% alert accuracy; < 5% noise)
5. Alert routing: correct team receives notification within 1 minute
6. RCA cycle: 80% of breaches investigated + root cause documented within 48h

---

## Escalation Path

```
SLO Breach Detected (Alert fires)
    ↓
Owner notified (within 5 min)
    ↓
Owner investigates (within 1h)
    ↓
If easy fix (cache issue, temp spike):
    → Fix applied, breach resolved, close ticket
    ↓
If structural issue (missing index, query rewrite needed):
    → Escalate to Database Optimizer + Data Engineer
    → Schedule spike/fix in next sprint
    ↓
If infrastructure strain (connection leak, CPU maxed):
    → Page DevOps Automator
    → Assess scaling needs
```

---

## v1.1 Enhancements (Scoped for Q3 2026)

- Query recompilation rate tracking (leading indicator for parameter sniffing)
- Wait analysis by query (identify blocking locks, latch contention)
- Cost-per-query trending (identify expensive analytical queries creeping into interactive workloads)
- Automated index recommendation acceptance workflow
