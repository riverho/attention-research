#!/bin/bash
#
# attention-research: Research Executor
# Usage: research-executor.sh --slot morning|afternoon

set -euo pipefail

SLOT=""
RESEARCH_ROOT="${RESEARCH_ROOT:-$HOME/.openclaw/workspace/notes/research-v2}"
SKILL_ROOT="${ATTENTION_RESEARCH_ROOT:-$HOME/.openclaw/skills/attention-research}"
CONFIG_DIR="$SKILL_ROOT/CONFIG"
STATE_FILE="$HOME/.openclaw/workspace/memory/heartbeat-state.json"
TODAY=$(date +%Y-%m-%d)
NOW=$(date +%Y-%m-%dT%H:%M:%S%z)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --slot) SLOT="$2"; shift 2 ;;
    --help) echo "Usage: $0 --slot morning|afternoon"; exit 0 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

[[ -z "$SLOT" ]] && { echo "ERROR: --slot required"; exit 1; }
[[ "$SLOT" != "morning" && "$SLOT" != "afternoon" ]] && { echo "ERROR: --slot must be morning or afternoon"; exit 1; }

meta_check_fresh() {
  local topic="$1"
  local meta_file="$RESEARCH_ROOT/topics/$topic/META.json"
  local slot_field="last${SLOT^}Update"
  [[ ! -f "$meta_file" ]] && { echo "fresh"; return; }
  local last_update
  last_update=$(python3 -c "import json; d=json.load(open('$meta_file')); print(d.get('$slot_field') or '')" 2>/dev/null || echo "")
  [[ "$last_update" == "$TODAY" ]] && { echo "fresh"; return; }
  local retry_count retry_date
  retry_count=$(python3 -c "import json; d=json.load(open('$meta_file')); print(d.get('retryCount', 0))" 2>/dev/null || echo "0")
  retry_date=$(python3 -c "import json; d=json.load(open('$meta_file')); print(d.get('retryDate', ''))" 2>/dev/null || echo "")
  if [[ "$retry_date" == "$TODAY" && "$retry_count" -ge 2 ]]; then echo "exhausted"; else echo "stale"; fi
}

meta_record_success() {
  local topic="$1"
  local meta_file="$RESEARCH_ROOT/topics/$topic/META.json"
  [[ ! -f "$meta_file" ]] && return
  python3 - <<PY
import json
meta = json.load(open('$meta_file'))
meta['retryCount'] = 0
meta['lastError'] = None
meta['lastHeartbeatUpdate'] = '$NOW'
meta['last${SLOT^}Update'] = '$TODAY'
json.dump(meta, open('$meta_file', 'w'), indent=2)
PY
}

get_topics() {
  python3 -c "
import yaml
with open('$CONFIG_DIR/topics.yaml') as f:
    cfg = yaml.safe_load(f)
for t, v in cfg.get('topics', {}).items():
    if v.get('enabled', True):
        print(t)
" 2>/dev/null
}

init_topic_meta() {
  local topic="$1"
  local meta_file="$RESEARCH_ROOT/topics/$topic/META.json"
  [[ -f "$meta_file" ]] && return
  mkdir -p "$(dirname "$meta_file")"
  python3 - <<PY > "$meta_file"
import json
meta = {
    "schema": "attention-research.v1",
    "topic": "$topic",
    "lastHeartbeatUpdate": None,
    "lastMorningUpdate": None,
    "lastAfternoonUpdate": None,
    "retryCount": 0,
    "retryDate": None,
    "lastError": None,
    "note": None
}
print(json.dumps(meta, indent=2))
PY
}

main() {
  echo "=== attention-research $SLOT: $TODAY ==="
  [[ ! -d "$RESEARCH_ROOT" ]] && { echo "ERROR: RESEARCH_ROOT not found: $RESEARCH_ROOT"; exit 1; }

  for topic in $(get_topics); do
    init_topic_meta "$topic"
    freshness=$(meta_check_fresh "$topic")
    echo "Topic $topic: $freshness"
    [[ "$freshness" == "fresh" ]] && continue
    [[ "$freshness" == "exhausted" ]] && continue
    # Sub-agent handles Tavily search and news file writing
    # This script manages state and coordination
    meta_record_success "$topic"
    echo "Topic $topic: research complete"
  done

  python3 - <<PY
import json, pathlib
p = pathlib.Path('$STATE_FILE')
d = json.load(open(p)) if p.exists() else {}
d['lastDigest'] = '$TODAY'
d['lastDigestType'] = '$SLOT'
json.dump(d, open(p, 'w'), indent=2)
PY
  echo "=== Done ==="
}

main