#!/bin/bash
# Stop Hermes Task Monitor
# Usage: ./stop-monitor.sh

pkill -f "monitor-tasks.sh" && echo "Monitor stopped" || echo "Monitor not running"
