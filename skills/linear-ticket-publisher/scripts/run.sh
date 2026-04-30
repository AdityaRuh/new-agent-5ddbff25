#!/usr/bin/env bash
# Auto-generated script for linear-ticket-publisher
# DO NOT MODIFY — this script is executed verbatim by the OpenClaw agent
set -euo pipefail

SKILL_ID="linear-ticket-publisher"
export SKILL_ID
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
export PROJECT_ROOT

# ── Environment validation ────────────────────────────────────────────────────
: "${LINEAR_API_KEY:?ERROR: LINEAR_API_KEY not set}"
: "${LINEAR_TEMPLATE_KEY:?ERROR: LINEAR_TEMPLATE_KEY not set}"
: "${LINEAR_TEAM_MAP:?ERROR: LINEAR_TEAM_MAP not set}"

# ── File paths ────────────────────────────────────────────────────────────────
INPUT_FILE="/tmp/ticket-intake-normalizer_${RUN_ID}.json"
OUTPUT_FILE="/tmp/linear-ticket-publisher_${RUN_ID}.json"
export INPUT_FILE OUTPUT_FILE

# ── Input validation ──────────────────────────────────────────────────────────
[ -s "${INPUT_FILE}" ] || { echo "ERROR: input missing: ${INPUT_FILE}" >&2; exit 1; }

# ── Main logic ────────────────────────────────────────────────────────────────
python3 - <<'PY'
import json
import os
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone

INPUT_FILE = os.environ["INPUT_FILE"]
OUTPUT_FILE = os.environ["OUTPUT_FILE"]
RUN_ID = os.environ["RUN_ID"]
LINEAR_API_KEY = os.environ["LINEAR_API_KEY"]
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


def coerce_dict(value):
    if isinstance(value, dict):
        return value
    if isinstance(value, str) and value.strip():
        try:
            parsed = json.loads(value)
            if isinstance(parsed, dict):
                return parsed
        except Exception:
            return {"raw": value}
    return {}


def coerce_list(value):
    if value is None:
        return []
    if isinstance(value, list):
        return [item for item in value if item not in (None, "")]
    if isinstance(value, str) and value.strip():
        return [line.strip("- •\t ") for line in value.splitlines() if line.strip()]
    return [str(value)]


def pick_first(*values):
    for value in values:
        if value not in (None, ""):
            return value
    return None


def http_json(url, payload, headers, timeout=90, retries=3):
    body = json.dumps(payload).encode("utf-8")
    last_error = None
    for attempt in range(retries):
        req = urllib.request.Request(url, data=body, headers=headers, method="POST")
        try:
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                raw = resp.read().decode("utf-8")
                status = getattr(resp, "status", 200)
        except urllib.error.HTTPError as e:
            raw = e.read().decode("utf-8", errors="replace")
            status = e.code
            last_error = f"HTTP {status} from {url}: {raw}"
            if status in (429, 500, 502, 503, 504) and attempt < retries - 1:
                time.sleep(2 ** attempt)
                continue
            raise RuntimeError(last_error) from e
        except urllib.error.URLError as e:
            last_error = f"Network error calling {url}: {e}"
            if attempt < retries - 1:
                time.sleep(2 ** attempt)
                continue
            raise RuntimeError(last_error) from e
        if status != 200:
            last_error = f"HTTP {status} from {url}: {raw}"
            if status in (429, 500, 502, 503, 504) and attempt < retries - 1:
                time.sleep(2 ** attempt)
                continue
            raise RuntimeError(last_error)
        return json.loads(raw)
    raise RuntimeError(last_error or f"Failed calling {url}")


def load_routing(value):
    if isinstance(value, dict):
        return value
    if isinstance(value, list):
        return {"routes": value}
    return coerce_dict(value)


def resolve_route(input_doc):
    routing_context = load_routing(input_doc.get("routing_context") or input_doc.get("routing") or {})
    if not routing_context:
        routing_context = load_routing(DEFAULT_ROUTING_MAP)
    draft = input_doc.get("draft") or {}
    team = draft.get("team") or routing_context.get("team") or {}
    project = draft.get("project") or routing_context.get("project") or {}
    return {
        "routing_key": pick_first(routing_context.get("routing_key"), input_doc.get("routing_key"), "default"),
        "linear_team_id": pick_first(team.get("linear_team_id"), routing_context.get("linear_team_id"), input_doc.get("linear_team_id")),
        "team_name": pick_first(team.get("name"), routing_context.get("team_name"), input_doc.get("team_name")),
        "linear_project_id": pick_first(project.get("linear_project_id"), routing_context.get("linear_project_id"), input_doc.get("linear_project_id")),
        "project_name": pick_first(project.get("name"), routing_context.get("project_name"), input_doc.get("project_name")),
        "label_ids": coerce_list(routing_context.get("label_ids") or draft.get("label_ids") or input_doc.get("label_ids")),
        "label_names": coerce_list(routing_context.get("labels") or draft.get("labels") or input_doc.get("labels")),
        "priority": pick_first(routing_context.get("priority"), draft.get("priority"), input_doc.get("priority"), "no_priority"),
        "assignee_id": pick_first(routing_context.get("assignee_id"), draft.get("assignee_id"), input_doc.get("assignee_id")),
    }


def build_description(input_doc, draft, route):
    parts = []
    if draft.get("summary"):
        parts.append(f"## Summary\n{draft['summary']}")
    if draft.get("problem_statement"):
        parts.append(f"## Problem Statement\n{draft['problem_statement']}")
    acceptance = draft.get("acceptance_criteria") or []
    if acceptance:
        parts.append("## Acceptance Criteria\n" + "\n".join(f"- {item}" for item in acceptance))
    source_ref = input_doc.get("source_ref")
    if source_ref:
        parts.append(f"## Source\n{source_ref}")
    if route.get("routing_key"):
        parts.append(f"## Routing\n{route['routing_key']}")
    return "\n\n".join(parts).strip()


def validate_ready(input_doc):
    approval_status = input_doc.get("approval_status") or input_doc.get("approval", {}).get("status")
    validation_status = input_doc.get("validation_status") or (input_doc.get("validation") or {}).get("status")
    draft = input_doc.get("draft") or {}
    required = ["title", "summary", "problem_statement", "acceptance_criteria"]
    missing = []
    for field in required:
        if field == "acceptance_criteria":
            if not coerce_list(draft.get("acceptance_criteria")):
                missing.append(field)
        elif not pick_first(draft.get(field), ""):
            missing.append(field)
    if approval_status != "approved":
        return False, "approval_missing_or_rejected", f"Publish blocked because approval_status is '{approval_status or 'missing'}'."
    if validation_status not in ("ready_for_review", "approved"):
        return False, "draft_not_ready", f"Publish blocked because validation_status is '{validation_status or 'missing'}'."
    if missing:
        return False, "missing_required_fields", "Publish blocked because the approved draft is still missing: " + ", ".join(missing)
    return True, None, None


def query_linear(headers, query, variables):
    return http_json(
        "https://api.linear.app/graphql",
        {"query": query, "variables": variables},
        headers,
        timeout=90,
        retries=3,
    )


def resolve_priority(value):
    if value is None:
        return 0
    mapping = {
        "none": 0,
        "no_priority": 0,
        "urgent": 1,
        "high": 2,
        "medium": 3,
        "normal": 3,
        "low": 4,
    }
    if isinstance(value, int):
        return value
    return mapping.get(str(value).strip().lower(), 0)


def main():
    input_doc = load_json_file(INPUT_FILE, {})
    request_id = pick_first(input_doc.get("request_id"), os.environ.get("REQUEST_ID"), RUN_ID)
    template_key = pick_first(input_doc.get("template_key"), DEFAULT_TEMPLATE_KEY)
    draft = input_doc.get("draft") or {}
    route = resolve_route(input_doc)

    output = {
        "request_id": request_id,
        "template_key": template_key,
        "source_channel": pick_first(input_doc.get("source_channel"), "slack"),
        "source_ref": input_doc.get("source_ref"),
        "approval_status": pick_first(input_doc.get("approval_status"), (input_doc.get("approval") or {}).get("status"), "pending"),
        "validation_status": pick_first(input_doc.get("validation_status"), (input_doc.get("validation") or {}).get("status"), "failed"),
        "draft": draft,
        "routing_context": route,
        "publish_status": "failed",
        "linear_issue_id": input_doc.get("linear_issue_id"),
        "linear_issue_url": input_doc.get("linear_issue_url"),
        "error_code": None,
        "error_message": None,
        "created_at": input_doc.get("created_at") or utc_now(),
        "updated_at": utc_now(),
    }

    if output["linear_issue_id"] and output["linear_issue_url"]:
        output["publish_status"] = "skipped"
        output["error_code"] = "already_published"
        output["error_message"] = "Request already has a published Linear issue."
        with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
            json.dump(output, f, indent=2, sort_keys=True, ensure_ascii=False)
        return

    ok, error_code, error_message = validate_ready(input_doc)
    if not ok:
        output["publish_status"] = "blocked"
        output["error_code"] = error_code
        output["error_message"] = error_message
        with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
            json.dump(output, f, indent=2, sort_keys=True, ensure_ascii=False)
        return

    if not route.get("linear_team_id"):
        output["publish_status"] = "blocked"
        output["error_code"] = "missing_team_id"
        output["error_message"] = "Publish blocked because no Linear team id was supplied in the routing context."
        with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
            json.dump(output, f, indent=2, sort_keys=True, ensure_ascii=False)
        return

    headers = {
        "Authorization": f"Bearer {LINEAR_API_KEY}",
        "Content-Type": "application/json",
    }

    try:
        team_query = "query ($id: String!) { team(id: $id) { id name } }"
        team_resp = query_linear(headers, team_query, {"id": route["linear_team_id"]})
        team = (((team_resp or {}).get("data") or {}).get("team"))
        if not team:
            raise RuntimeError(f"Linear team not found for id {route['linear_team_id']}")

        project_id = route.get("linear_project_id")
        if project_id:
            project_query = "query ($id: String!) { project(id: $id) { id name } }"
            project_resp = query_linear(headers, project_query, {"id": project_id})
            project = (((project_resp or {}).get("data") or {}).get("project"))
            if not project:
                raise RuntimeError(f"Linear project not found for id {project_id}")

        description = build_description(input_doc, draft, route)
        issue_input = {
            "teamId": route["linear_team_id"],
            "title": draft.get("title") or "Untitled ticket",
            "description": description,
            "priority": resolve_priority(route.get("priority")),
        }
        if route.get("linear_project_id"):
            issue_input["projectId"] = route["linear_project_id"]
        if route.get("label_ids"):
            issue_input["labelIds"] = route["label_ids"]
        if route.get("assignee_id"):
            issue_input["assigneeId"] = route["assignee_id"]

        create_mutation = """
        mutation ($input: IssueCreateInput!) {
          issueCreate(input: $input) {
            success
            issue {
              id
              identifier
              url
            }
          }
        }
        """
        create_resp = query_linear(headers, create_mutation, {"input": issue_input})
        create_data = ((create_resp or {}).get("data") or {}).get("issueCreate") or {}
        issue = create_data.get("issue") or {}
        if not issue:
            raise RuntimeError(json.dumps(create_resp, ensure_ascii=False))

        output["publish_status"] = "published"
        output["linear_issue_id"] = issue.get("id") or issue.get("identifier")
        output["linear_issue_url"] = issue.get("url")
        output["error_code"] = None
        output["error_message"] = None
    except Exception as exc:
        output["publish_status"] = "failed"
        output["error_code"] = "linear_publish_failed"
        output["error_message"] = str(exc)

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

echo "OK: linear-ticket-publisher complete"
