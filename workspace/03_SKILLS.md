# Step 3 of 5 — Skills

## Added Skills

| #    | Skill ID                  | Skill Name               | Mode   | Risk Level | Description                |
|------|---------------------------|--------------------------|--------|------------|----------------------------|
| S1   | `data-writer` | Data Writer | Auto | Low | Provision, write, and query the agent database schema via scripts/data_writer.py. Use for all PostgreSQL operations and any result-table persistence. |
| S2   | `result-query` | Result Query | Auto | Low | Read stored records from the agent result tables for inspection and follow-up questions. |
| S3   | `github-action` | GitHub Action | Auto | Low | Git branch + PR workflow for syncing agent changes to GitHub. Creates feature branches, commits changes, and opens pull requests against main. NEVER pushes to main directly. MANDATORY for every agent. |
| S4   | `ticket-intake-normalizer` | Ticket Intake Normalizer | Auto | Low | Normalize raw intake into a template-compliant Linear ticket draft with validation and routing hints. |
| S5   | `linear-ticket-publisher` | Linear Ticket Publisher | Auto | Low | Publish an approved ticket draft to Linear and return the issue link. |

## Skill Dependencies (Execution Order)

```
data-writer
result-query
github-action
ticket-intake-normalizer
linear-ticket-publisher ← depends on ticket-intake-normalizer
```

## Execution Mode Summary

| Mode  | Count          |
|-------|----------------|
| HiTL  | 0              |
| Auto  | 5 |
