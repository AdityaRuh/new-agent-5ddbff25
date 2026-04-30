---
name: ticket-intake-normalizer
version: 1.0.0
description: "Normalize raw intake into a template-compliant Linear ticket draft with validation and routing hints."
user-invocable: false
metadata:
  openclaw:
    requires:
      bins: [bash, python3, jq]
      env: [OPENAI_API_KEY, LINEAR_TEMPLATE_KEY, LINEAR_TEAM_MAP]
    primaryEnv: OPENAI_API_KEY
---
# Ticket Intake Normalizer

## I/O Contract

- **Input:** `/tmp/intake_${RUN_ID}.json`
- **Output:** `/tmp/ticket-intake-normalizer_${RUN_ID}.json`

## Execute

```bash
bash {baseDir}/scripts/run.sh
```
