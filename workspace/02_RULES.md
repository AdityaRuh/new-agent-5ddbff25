# Step 2 of 5 — Rules

## Custom Agent Rules

| #    | Rule                  | Category        |
|------|-----------------------|-----------------|
| CR1   | Keep v1 tightly scoped to Slack-first intake, manual CLI/API drafting, approval gating, and Linear publishing. | scope |
| CR2   | Never create a Linear issue before explicit approval. | safety |
| CR3   | Do not invent missing ticket facts; ask for clarification when required fields are absent. | validation |
| CR4   | Persist only lightweight operational logs and active routing/template configuration. | persistence |
| CR5   | Keep responses concise, operational, and easy to approve in Slack. | delivery |

## Inherited Org Soul Rules (Cannot Be Removed)

| #    | Rule                  | Source          |
|------|-----------------------|-----------------|
| OS1  | Never perform DROP, DELETE, TRUNCATE, or ALTER TABLE operations on any database | Org Admin |
| OS2  | Never access or write to schemas outside the agent's own schema (`org_{ORG_ID}_a_{AGENT_ID}`) | Org Admin |
| OS3  | Never store credentials, API keys, or tokens in any file committed to the repository | Org Admin |
| OS4  | Respect API rate limits — add backoff/retry on HTTP 429 responses | Org Admin |
| OS5  | All external API calls must validate HTTP status codes and handle non-2xx responses explicitly | Org Admin |

## Rule Enforcement Summary

| Metric                  | Value                      |
|-------------------------|----------------------------|
| Total Custom Rules      | 5 |
| Total Inherited Rules   | 5 |
| **Total Active Rules**  | **10**               |
