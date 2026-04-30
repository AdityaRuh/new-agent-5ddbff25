#!/usr/bin/env bash
# Check required environment variables are set.
set -euo pipefail

missing=0
if [ -z "${PG_CONNECTION_STRING:-}" ]; then echo "MISSING: PG_CONNECTION_STRING"; missing=$((missing+1)); fi
if [ -z "${ORG_ID:-}" ]; then echo "MISSING: ORG_ID"; missing=$((missing+1)); fi
if [ -z "${AGENT_ID:-}" ]; then echo "MISSING: AGENT_ID"; missing=$((missing+1)); fi
if [ -z "${DEFAULT_TIMEZONE:-}" ]; then echo "MISSING: DEFAULT_TIMEZONE"; missing=$((missing+1)); fi
if [ -z "${LINEAR_TEMPLATE_KEY:-}" ]; then echo "MISSING: LINEAR_TEMPLATE_KEY"; missing=$((missing+1)); fi
if [ -z "${LINEAR_TEAM_MAP:-}" ]; then echo "MISSING: LINEAR_TEAM_MAP"; missing=$((missing+1)); fi
if [ -z "${LINEAR_API_KEY:-}" ]; then echo "MISSING: LINEAR_API_KEY"; missing=$((missing+1)); fi
if [ -z "${OPENAI_API_KEY:-}" ]; then echo "MISSING: OPENAI_API_KEY"; missing=$((missing+1)); fi
if [ -z "${GITHUB_TOKEN:-}" ]; then echo "MISSING: GITHUB_TOKEN"; missing=$((missing+1)); fi
if [ -z "${GITHUB_OWNER:-}" ]; then echo "MISSING: GITHUB_OWNER"; missing=$((missing+1)); fi
if [ -z "${AGENT_REPO_NAME:-}" ]; then echo "MISSING: AGENT_REPO_NAME"; missing=$((missing+1)); fi
if [ -z "${SLACK_BOT_TOKEN:-}" ]; then echo "MISSING: SLACK_BOT_TOKEN"; missing=$((missing+1)); fi
if [ -z "${SLACK_SIGNING_SECRET:-}" ]; then echo "MISSING: SLACK_SIGNING_SECRET"; missing=$((missing+1)); fi

if [ $missing -gt 0 ]; then
    echo "$missing required env var(s) missing"
    exit 1
fi
echo "OK: all required env vars set"
