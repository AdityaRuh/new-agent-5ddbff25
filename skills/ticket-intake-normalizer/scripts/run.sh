#!/usr/bin/env bash
# Auto-generated script for ticket-intake-normalizer
# DO NOT MODIFY — this script is executed verbatim by the OpenClaw agent
set -euo pipefail

SKILL_ID="ticket-intake-normalizer"
export SKILL_ID
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
export PROJECT_ROOT

# ── Environment validation ────────────────────────────────────────────────────
: "${OPENAI_API_KEY:?ERROR: OPENAI_API_KEY not set}"
: "${LINEAR_TEMPLATE_KEY:?ERROR: LINEAR_TEMPLATE_KEY not set}"
: "${LINEAR_TEAM_MAP:?ERROR: LINEAR_TEAM_MAP not set}"

# ── File paths ────────────────────────────────────────────────────────────────
INPUT_FILE="/tmp/intake_${RUN_ID}.json"
OUTPUT_FILE="/tmp/ticket-intake-normalizer_${RUN_ID}.json"
export INPUT_FILE OUTPUT_FILE

# ── Input validation ──────────────────────────────────────────────────────────
[ -s "${INPUT_FILE}" ] || { echo "ERROR: input missing: ${INPUT_FILE}" >&2; exit 1; }

# ── Main logic ────────────────────────────────────────────────────────────────
python3 - <<'PY'
import json
import os
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone

INPUT_FILE = os.environ["INPUT_FILE"]
OUTPUT_FILE = os.environ["OUTPUT_FILE"]
RUN_ID = os.environ["RUN_ID"]
OPENAI_API_KEY = os.environ["OPENAI_API_KEY"]
OPENAI_MODEL = os.environ.get("OPENAI_MODEL", "gpt-4.1-mini")
DEFAULT_TEMPLATE_KEY = os.environ.get("LINEAR_TEMPLATE_KEY", "linear-ticket-v1")
DEFAULT_ROUTING_MAP = os.environ.get("LINEAR_TEAM_MAP", "{}")


def utc_now():
    return datetime.now(timezone.utc).isoformat()


def load_json_file(path, fallback):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return fallback


def load_routing(value):
    if isinstance(value, dict):
        return value
    if isinstance(value, list):
        return {"routes": value}
    if isinstance(value, str) and value.strip():
        try:
            parsed = json.loads(value)
            if isinstance(parsed, dict):
                return parsed
            if isinstance(parsed, list):
                return {"routes": parsed}
        except Exception:
            return {"raw": value}
    return {}


def http_json(url, payload, headers, timeout=90):
    body = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=body, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read().decode("utf-8")
            status = getattr(resp, "status", 200)
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {e.code} from {url}: {raw}") from e
    except urllib.error.URLError as e:
        raise RuntimeError(f"Network error calling {url}: {e}") from e
    if status != 200:
        raise RuntimeError(f"HTTP {status} from {url}: {raw}")
    return json.loads(raw)


def normalize_required_fields(template):
    required = template.get("required_fields") or ["title", "summary", "problem_statement", "acceptance_criteria"]
    if isinstance(required, dict):
        return list(required.keys())
    if isinstance(required, list):
        return required
    return ["title", "summary", "problem_statement", "acceptance_criteria"]


def coerce_list(value):
    if value is None:
        return []
    if isinstance(value, list):
        return [item for item in value if item not in (None, "")]
    if isinstance(value, str) and value.strip():
        return [line.strip("- •\t ") for line in value.splitlines() if line.strip()]
    return [str(value)]


def build_prompt(payload):
    required_fields = payload["required_fields"]
    field_rules = payload["field_rules"]
    return [
        {
            "role": "system",
            "content": (
                "You normalize messy work requests into a single Linear-ready ticket draft. "
                "Return JSON only. Do not invent missing facts. If the input lacks required details, "
                "mark them missing and keep the draft conservative."
            ),
        },
        {
            "role": "user",
            "content": json.dumps(
                {
                    "request_id": payload["request_id"],
                    "source_channel": payload["source_channel"],
                    "source_ref": payload["source_ref"],
                    "raw_input": payload["raw_input"],
                    "structured_input": payload.get("structured_input"),
                    "template_key": payload["template_key"],
                    "template_version": payload.get("template_version"),
                    "required_fields": required_fields,
                    "field_rules": field_rules,
                    "routing_context": payload["routing_context"],
                    "output_shape": {
                        "draft": {
                            "title": "string",
                            "summary": "string",
                            "problem_statement": "string",
                            "acceptance_criteria": ["string"],
                            "labels": ["string"],
                            "priority": "string",
                            "team": {"name": "string", "linear_team_id": "string"},
                            "project": {"name": "string|null", "linear_project_id": "string|null"},
                            "assignee_hint": "string|null",
                        },
                        "validation": {
                            "status": "ready_for_review|needs_clarification|failed",
                            "missing_fields": ["string"],
                            "warnings": ["string"],
                        },
                        "clarification_prompt": "string|null",
                    },
                },
                ensure_ascii=False,
            ),
        },
    ]


def call_model(payload):
    url = "https://api.openai.com/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {OPENAI_API_KEY}",
        "Content-Type": "application/json",
    }
    request_payload = {
        "model": OPENAI_MODEL,
        "temperature": 0.2,
        "response_format": {"type": "json_object"},
        "messages": build_prompt(payload),
    }
    last_error = None
    for attempt in range(3):
        try:
            return http_json(url, request_payload, headers)
        except Exception as exc:
            last_error = str(exc)
            if attempt < 2:
                time.sleep(2 ** attempt)
                continue
    raise RuntimeError(last_error or "Unknown OpenAI error")


def pick_first(*values):
    for value in values:
        if value not in (None, ""):
            return value
    return None


def main():
    input_doc = load_json_file(INPUT_FILE, {})
    request_id = pick_first(input_doc.get("request_id"), os.environ.get("REQUEST_ID"), RUN_ID)
    source_channel = pick_first(input_doc.get("source_channel"), "slack")
    source_ref = pick_first(input_doc.get("source_ref"), "")
    raw_input = pick_first(input_doc.get("raw_input"), input_doc.get("text"), "")
    structured_input = input_doc.get("structured_input")

    template = input_doc.get("template") or {}
    routing_map = input_doc.get("routing_map") or input_doc.get("routing") or {}
    template_key = pick_first(template.get("template_key"), input_doc.get("template_key"), DEFAULT_TEMPLATE_KEY)
    template_version = template.get("version") or input_doc.get("template_version")
    required_fields = normalize_required_fields(template)
    field_rules = template.get("field_rules") or {}
    routing_context = load_routing(routing_map) or load_routing(DEFAULT_ROUTING_MAP)

    payload = {
        "request_id": request_id,
        "source_channel": source_channel,
        "source_ref": source_ref,
        "raw_input": raw_input,
        "structured_input": structured_input,
        "template_key": template_key,
        "template_version": template_version,
        "required_fields": required_fields,
        "field_rules": field_rules,
        "routing_context": routing_context,
    }

    output = {
        "request_id": request_id,
        "template_key": template_key,
        "template_version": template_version,
        "source_channel": source_channel,
        "source_ref": source_ref,
        "raw_input": raw_input,
        "structured_input": structured_input,
        "draft": {
            "title": "",
            "summary": "",
            "problem_statement": "",
            "acceptance_criteria": [],
            "labels": [],
            "priority": "",
            "team": {"name": "", "linear_team_id": ""},
            "project": {"name": None, "linear_project_id": None},
            "assignee_hint": None,
        },
        "routing_context": routing_context,
        "validation_status": "failed",
        "validation": {"status": "failed", "missing_fields": [], "warnings": []},
        "clarification_prompt": None,
        "approval_status": "pending",
        "publish_status": "not_published",
        "linear_issue_id": None,
        "linear_issue_url": None,
        "error_code": None,
        "error_message": None,
        "created_at": utc_now(),
        "updated_at": utc_now(),
    }

    try:
        response = call_model(payload)
        content = response["choices"][0]["message"]["content"]
        model_draft = json.loads(content)
    except Exception as exc:
        output["error_code"] = "llm_normalization_failed"
        output["error_message"] = str(exc)
        output["clarification_prompt"] = "I could not reliably structure this request. Please resend with a clearer title, summary, problem statement, and acceptance criteria."
        with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
            json.dump(output, f, indent=2, sort_keys=True, ensure_ascii=False)
        return

    draft = model_draft.get("draft") if isinstance(model_draft, dict) else None
    validation = model_draft.get("validation") if isinstance(model_draft, dict) else None
    clarification_prompt = model_draft.get("clarification_prompt") if isinstance(model_draft, dict) else None
    if not isinstance(draft, dict):
        draft = model_draft if isinstance(model_draft, dict) else {}

    normalized = {
        "title": pick_first(draft.get("title"), input_doc.get("title"), "").strip(),
        "summary": pick_first(draft.get("summary"), input_doc.get("summary"), "").strip(),
        "problem_statement": pick_first(draft.get("problem_statement"), input_doc.get("problem_statement"), "").strip(),
        "acceptance_criteria": coerce_list(pick_first(draft.get("acceptance_criteria"), input_doc.get("acceptance_criteria"))),
        "labels": coerce_list(draft.get("labels") or input_doc.get("labels")),
        "priority": pick_first(draft.get("priority"), input_doc.get("priority"), "").strip(),
        "team": {
            "name": pick_first((draft.get("team") or {}).get("name"), (routing_context.get("team") or {}).get("name"), input_doc.get("team_name"), "").strip(),
            "linear_team_id": pick_first((draft.get("team") or {}).get("linear_team_id"), (routing_context.get("team") or {}).get("linear_team_id"), input_doc.get("linear_team_id"), "").strip(),
        },
        "project": {
            "name": pick_first((draft.get("project") or {}).get("name"), (routing_context.get("project") or {}).get("name")),
            "linear_project_id": pick_first((draft.get("project") or {}).get("linear_project_id"), (routing_context.get("project") or {}).get("linear_project_id"), input_doc.get("linear_project_id")),
        },
        "assignee_hint": pick_first(draft.get("assignee_hint"), input_doc.get("assignee_hint")),
    }

    missing_fields = []
    for field in required_fields:
        if field == "acceptance_criteria":
            if not normalized["acceptance_criteria"]:
                missing_fields.append(field)
        elif not normalized.get(field):
            missing_fields.append(field)

    warnings = []
    if validation and isinstance(validation, dict):
        warnings.extend(coerce_list(validation.get("warnings")))
        for item in coerce_list(validation.get("missing_fields")):
            if item not in missing_fields:
                missing_fields.append(item)

    status = "ready_for_review" if not missing_fields else "needs_clarification"
    if validation and isinstance(validation, dict) and validation.get("status") == "failed":
        status = "failed"

    if not clarification_prompt and missing_fields:
        clarification_prompt = (
            "I can draft this, but I still need: " + ", ".join(missing_fields) + ". "
            "Please add those details or approve a revised draft once complete."
        )

    output.update(
        {
            "draft": normalized,
            "validation_status": status,
            "validation": {
                "status": status,
                "missing_fields": missing_fields,
                "warnings": warnings,
            },
            "clarification_prompt": clarification_prompt,
            "error_code": None,
            "error_message": None,
        }
    )

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(output, f, indent=2, sort_keys=True, ensure_ascii=False)


if __name__ == "__main__":
    main()
PY

python3 "${PROJECT_ROOT}/scripts/data_writer.py" write \
  --table result_ticket_intake_log \
  --conflict "request_id" \
  --run-id "${RUN_ID}" \
  --records "$(cat "$OUTPUT_FILE")"

# ── Output validation ─────────────────────────────────────────────────────────
[ -s "${OUTPUT_FILE}" ] || { echo "ERROR: output empty: ${OUTPUT_FILE}" >&2; exit 1; }

echo "OK: ticket-intake-normalizer complete"
