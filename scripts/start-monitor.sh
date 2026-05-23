#!/bin/bash
# Start Hermes Task Monitor - runs in background
# Usage: ./start-monitor.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../.hermes"
mkdir -p "$LOG_DIR"

nohup bash -c "while true; do '$SCRIPT_DIR/monitor-tasks.sh' >> '$LOG_DIR/cron-monitor.log' 2>&1; sleep 600; done" &
echo "Monitor started. PID: $!"
echo "Log: $LOG_DIR/cron-monitor.log"
echo "Status file: $LOG_DIR/monitor-status.json"
