# Step 5 of 5 — Access

## User Access

### Authorized Teams

| Team               | Access Level | Members (approx) |
|--------------------|-------------|-------------------|
| Product | draft, review, approve | Product managers and product operations |
| Engineering | draft, review, approve | Engineering leads and contributors creating implementation tickets |
| Operations/Program Management | draft, review, approve | Program managers and operations coordinators |

### Restricted From

| Team / Role          | Reason                          |
|----------------------|---------------------------------|
| External users | v1 is intended for internal teams and approved collaborators only. |
| Unapproved automation | Publishing must remain gated by explicit human approval. |
| Non-owned schemas or repos | The agent must stay within its own data and deployment boundaries. |

## HiTL Approvers

| Skill                | Action                         | Approver             | Fallback Approver    |
|----------------------|--------------------------------|----------------------|----------------------|
| ticket-intake-normalizer | approve draft readiness | Slack requester or thread owner | request clarification and keep the draft pending |
| linear-ticket-publisher | publish approved issue | Slack approver with request authority | do not publish and record the rejection |

## Model Configuration

| Field                | Value                          |
|----------------------|--------------------------------|
| **Primary Model**    | claude-sonnet-4   |
| **Fallback Model**   | claude-haiku-3  |

## Token Budget

| Field                  | Value                  |
|------------------------|------------------------|
| **Monthly Budget**     | 1500000 tokens |
| **Alert Threshold**    | 0.8 tokens |
| **Auto-Pause on Limit**| Yes |

## Security & Permissions

| Permission                         | Allowed    |
|------------------------------------|------------|
| Read and write lightweight PostgreSQL state | ✅ |
| Post Slack review and result messages | ✅ |
| Read Linear metadata and create issues after approval | ✅ |
| Call the configured LLM provider for draft normalization | ✅ |
| Access GitHub sync credentials for deployment bundles | ✅ |
