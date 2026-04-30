#!/usr/bin/env bash
# Smoke-test the workflow by running each skill in order.
set -euo pipefail

export RUN_ID="test-$(date +%s)"
echo "RUN_ID=${RUN_ID}"

for skill_dir in skills/*/; do
    name=$(basename "$skill_dir")
    runner="${skill_dir}scripts/run.sh"
    if [ -x "$runner" ]; then
        echo "--- Running $name ---"
        bash "$runner" || { echo "FAIL: $name"; exit 1; }
    fi
done
echo "OK: all skills ran without errors"
