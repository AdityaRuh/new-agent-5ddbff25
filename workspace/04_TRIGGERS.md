# Step 4 of 5 — Triggers

## Active Triggers

### slack-command-request — Slack command or in-thread request that starts draft generation and approval.

| Field       | Value                              |
|-------------|------------------------------------|
| **Type**    | conversational                     |
| **Status**  | enabled                   |
| **Channel** | Slack |

**Sample User Queries This Trigger Handles:**

- "Draft a Linear ticket from this Slack thread"
- "Turn this note into a ticket"

---

### cli-api-submission — Manual CLI or API submission that returns a reviewable draft and validation status.

| Field       | Value                              |
|-------------|------------------------------------|
| **Type**    | event                     |
| **Status**  | enabled                   |
| **Channel** | CLI/API |

**Sample User Queries This Trigger Handles:**

- "Submit raw text for ticket drafting"
- "Send structured JSON to draft a ticket"

---

### slack-approval-command — Explicit Slack approve/reject action that gates Linear publishing.

| Field       | Value                              |
|-------------|------------------------------------|
| **Type**    | conversational                     |
| **Status**  | enabled                   |
| **Channel** | Slack |

**Sample User Queries This Trigger Handles:**

- "Approve request 123"
- "Reject the draft"

