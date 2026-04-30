# 🧾 Linear Ticket Generation Agent

Slack-first agent that drafts, reviews, and publishes template-compliant Linear tickets after explicit human approval.

## Quick Start

```bash
git clone git@github.com:${GITHUB_OWNER}/linear-ticket-generation-agent.git
cd linear-ticket-generation-agent

# 1. Configure
cp .env.example .env
# Edit .env with your credentials (see "Required Environment Variables" below)

# 2. One-shot setup: validates env, installs deps, provisions DB, registers cron
chmod +x setup.sh
./setup.sh
```

## Manual Setup (if you prefer step-by-step)

```bash
cp .env.example .env             # then edit it
set -a; source .env; set +a       # load vars into the current shell
bash check-environment.sh         # verify everything required is set
bash install-dependencies.sh      # pip install psycopg2-binary, pyyaml
python3 scripts/data_writer.py provision   # create tables in your schema

```

## Running

```bash
bash test-workflow.sh             # run every skill in order locally (smoke test)

openclaw cron list                # see registered jobs
openclaw cron runs                # see run history
```

## Required Environment Variables

| Variable | Description |
|----------|-------------|
| `PG_CONNECTION_STRING` | PostgreSQL connection string |
| `ORG_ID` | Organization ID |
| `AGENT_ID` | Agent ID |
| `DEFAULT_TIMEZONE` | Default timezone |
| `LINEAR_TEMPLATE_KEY` | Active Linear ticket template key |
| `LINEAR_TEAM_MAP` | Linear routing map payload |
| `LINEAR_API_KEY` | Linear API key |
| `OPENAI_API_KEY` | OpenAI API key |
| `GITHUB_TOKEN` | GitHub token for repository sync |
| `GITHUB_OWNER` | GitHub owner or organization |
| `AGENT_REPO_NAME` | Agent repository name |
| `SLACK_BOT_TOKEN` | Slack bot token |
| `SLACK_SIGNING_SECRET` | Slack signing secret |

## Skills

| Skill | Mode | Description |
|-------|------|-------------|
| `data-writer` | Auto | Provision, write, and query the agent database schema via scripts/data_writer.py. Use for all PostgreSQL operations and any result-table persistence. |
| `result-query` | User-invocable | Read stored records from the agent result tables for inspection and follow-up questions. |
| `github-action` | User-invocable | Git branch + PR workflow for syncing agent changes to GitHub. Creates feature branches, commits changes, and opens pull requests against main. NEVER pushes to main directly. MANDATORY for every agent. |
| `ticket-intake-normalizer` | Auto | Normalize raw intake into a template-compliant Linear ticket draft with validation and routing hints. |
| `linear-ticket-publisher` | Auto | Publish an approved ticket draft to Linear and return the issue link. |



## Architecture

- **Runtime**: OpenClaw AI agent framework
- **Data Layer**: PostgreSQL via `scripts/data_writer.py`
- **Scheduling**: OpenClaw cron
- **Schema**: `org_{org_id}_a_linear_ticket_generation_agent`

## Directory Structure

```
linear-ticket-generation-agent/
├── README.md
├── openclaw.json
├── result-schema.yml
├── env-manifest.yml
├── .env.example
├── requirements.txt
├── .gitignore
├── check-environment.sh
├── install-dependencies.sh
├── test-workflow.sh
├── cron/
├── workflows/
├── scripts/
│   ├── data_writer.py
│   └── github_action.py
├── skills/
└── workspace/
    ├── SOUL.md
    ├── 01_IDENTITY.md
    ├── 02_RULES.md
    ├── 03_SKILLS.md
    ├── 04_TRIGGERS.md
    ├── 05_ACCESS.md
    ├── 06_WORKFLOW.md
    └── 07_REVIEW.md
```
