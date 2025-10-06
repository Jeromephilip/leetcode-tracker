#!/bin/bash

# Local Environment Shutdown Script for LeetCode Tracker
# This script stops all services started by start_local_environment.sh

echo "🛑 Stopping LeetCode Tracker Local Environment"
echo "=============================================="

# Function to stop a service by PID file
stop_service() {
    local service_name=$1
    local pid_file="tmp/pids/${service_name}.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo "🔄 Stopping $service_name (PID: $pid)..."
            kill "$pid"
            sleep 2
            if kill -0 "$pid" 2>/dev/null; then
                echo "⚠️  Force killing $service_name..."
                kill -9 "$pid"
            fi
            echo "✅ $service_name stopped"
        else
            echo "⚠️  $service_name was not running"
        fi
        rm -f "$pid_file"
    else
        echo "⚠️  No PID file found for $service_name"
    fi
}

# Stop services
stop_service "rails-server"
stop_service "sidekiq"

# Also try to stop any remaining processes
echo ""
echo "🧹 Cleaning up any remaining processes..."

# Stop Rails server processes
pkill -f "rails server" 2>/dev/null && echo "✅ Stopped remaining Rails processes"

# Stop Sidekiq processes
pkill -f "sidekiq" 2>/dev/null && echo "✅ Stopped remaining Sidekiq processes"

echo ""
echo "✅ Local environment stopped!"
echo "============================="
echo ""
echo "💡 Note: Redis will continue running in the background."
echo "   To stop Redis: brew services stop redis"
