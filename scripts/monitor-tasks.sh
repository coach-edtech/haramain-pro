#!/bin/bash
# Monitor Trae Tasks using OpenRouter API
# Project: HaramainPro

OPENROUTER_API_KEY="***"
TASKS_FOLDER="/Volumes/StartUp/Haramain-Pro/Trae-Tasks"
STATUS_FILE="/Volumes/StartUp/Haramain-Pro/.hermes/monitor-status.json"
LOG_FILE="/Volumes/StartUp/Haramain-Pro/.hermes/monitor.log"

mkdir -p "$(dirname "$STATUS_FILE")"

# Fixed: use newline as delimiter for find output
TASK_FILES=$(find "$TASKS_FOLDER" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
TASK_LIST=$(find "$TASKS_FOLDER" -maxdepth 1 -name "*.md" -type f 2>/dev/null | while read f; do basename "$f"; done)

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

TASKS_JSON="[]"
if [ -n "$TASK_LIST" ]; then
  TASKS_JSON=$(echo "$TASK_LIST" | jq -R . | jq -s .)
fi

cat > "$STATUS_FILE" << EOF
{
  "timestamp": "$TIMESTAMP",
  "project": "HaramainPro",
  "tasks_found": $TASK_FILES,
  "task_files": $TASKS_JSON,
  "source": "openrouter-monitor"
}
EOF

MONITOR_PROMPT="Task monitor status check. Current folder has $TASK_FILES pending tasks. Acknowledge receipt."

RESPONSE=$(curl -s -X POST "https://openrouter.ai/api/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "HTTP-Referer: https://haramain-pro.local" \
  -H "X-Title: HermesTaskMonitor" \
  -d "{
    \"model\": \"google/gemini-2.0-flash-exp\",
    \"messages\": [{\"role\": \"user\", \"content\": \"$MONITOR_PROMPT\"}],
    \"max_tokens\": 50
  }" 2>/dev/null)

HTTP_CODE=$?

echo "[$TIMESTAMP] Tasks: $TASK_FILES | OpenRouter exit: $HTTP_CODE" >> "$LOG_FILE"

if [ "$TASK_FILES" -gt 0 ]; then
  echo "Tasks pending: $TASK_FILES"
fi

exit 0
