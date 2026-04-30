#!/usr/bin/env bash
# One-time setup for Linear Ticket Generation Agent.
# Idempotent — safe to run multiple times.
set -euo pipefail

cd "$(dirname "$0")"

echo "Setting up Linear Ticket Generation Agent (linear-ticket-generation-agent)"
echo ""

echo "[1/5] Preparing .env..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo "  created .env from .env.example — EDIT IT before continuing"
    echo "  required vars listed in README.md → 'Required Environment Variables'"
    exit 1
fi
echo "  .env exists"

echo ""
echo "[2/5] Validating environment..."
# shellcheck disable=SC1091
set -a; source .env; set +a
bash check-environment.sh

echo ""
echo "[3/5] Installing Python dependencies..."
bash install-dependencies.sh

echo ""
echo "[4/5] Provisioning database schema..."
python3 scripts/data_writer.py provision

echo ""
echo "[5/5] No cron jobs to register."

echo ""
echo "OK: Linear Ticket Generation Agent is ready."
echo ""
echo "Useful commands:"
echo "  bash test-workflow.sh                      # smoke-test all skills locally"

echo "  python3 scripts/data_writer.py query --table <name> --limit 10"
