---
name: linear-ticket-publisher
version: 1.0.0
description: Publish an approved ticket draft to Linear and return the issue link.
user-invocable: false
metadata:
  openclaw:
    requires:
      bins: [bash, python3, curl, jq]
      env: [LINEAR_API_KEY, LINEAR_TEMPLATE_KEY, LINEAR_TEAM_MAP]
    primaryEnv: LINEAR_API_KEY
---
# Linear Ticket Publisher

## I/O Contract

- **Input:** `/tmp/ticket-intake-normalizer_${RUN_ID}.json`
- **Output:** `/tmp/linear-ticket-publisher_${RUN_ID}.json`

## Execute

```bash
bash {baseDir}/scripts/run.sh
```
