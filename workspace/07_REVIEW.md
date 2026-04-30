# Review — Final Summary Before Deployment

## Agent Card

| Field              | Value                          |
|--------------------|--------------------------------|
| **Name**           | 🧾 Linear Ticket Generation Agent |
| **ID**             | `linear-ticket-generation-agent`           |
| **Version**        | 1.0.0 |
| **Scope**          | Slack-first agent that drafts, reviews, and publishes template-compliant Linear tickets after explicit human approval.      |
| **Tone**           | Clear, concise, operationally helpful, and approval-aware.             |
| **Model**          | claude-sonnet-4 (primary), claude-haiku-3 (fallback) |
| **Token Budget**   | 1500000 tokens/month |

## Skills Summary

| Skill                     | Mode         |
|---------------------------|--------------|
| Data Writer | 🟢 Auto |
| Result Query | 🟢 Auto |
| GitHub Action | 🟢 Auto |
| Ticket Intake Normalizer | 🟢 Auto |
| Linear Ticket Publisher | 🟢 Auto |

## Post-Deployment Checklist

- [ ] Verify all required environment variables are present
- [ ] Run environment validation and workflow tests successfully
- [ ] Confirm Slack intake, approval, and result delivery work end to end
- [ ] Confirm Linear metadata lookup and issue creation work with an approved draft
- [ ] Confirm the bundle contains no cron jobs or out-of-scope triggers for v1
