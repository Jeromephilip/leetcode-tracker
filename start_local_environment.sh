#!/bin/bash

# Local Environment Startup Script for LeetCode Tracker
# This script starts all required services for the session worker system

echo "🚀 Starting LeetCode Tracker Local Environment"
echo "=============================================="

# Function to check if a process is running
check_process() {
    if pgrep -f "$1" > /dev/null; then
        echo "✅ $1 is already running"
        return 0
    else
        return 1
    fi
}

# Function to start a service in background
start_service() {
    local service_name=$1
    local command=$2
    local log_file=$3
    
    if check_process "$service_name"; then
        return 0
    fi
    
    echo "🔄 Starting $service_name..."
    nohup $command > "$log_file" 2>&1 &
    local pid=$!
    echo "✅ $service_name started with PID: $pid"
    echo $pid > "tmp/pids/${service_name}.pid"
    sleep 2
}

# Create necessary directories
mkdir -p tmp/pids
mkdir -p log

echo ""
echo "📋 Checking Prerequisites..."

# Check Redis
if ! redis-cli ping > /dev/null 2>&1; then
    echo "❌ Redis is not running. Please start Redis first:"
    echo "   brew services start redis"
    echo "   or"
    echo "   redis-server"
    exit 1
else
    echo "✅ Redis is running"
fi

# Check if Rails server is already running
if check_process "rails server"; then
    echo "⚠️  Rails server is already running on port 3000"
else
    echo "🔄 Starting Rails server..."
    start_service "rails-server" "bundle exec rails server -p 3000" "log/rails.log"
fi

# Check if Sidekiq is already running
if check_process "sidekiq"; then
    echo "⚠️  Sidekiq is already running"
else
    echo "🔄 Starting Sidekiq..."
    start_service "sidekiq" "bundle exec sidekiq" "log/sidekiq.log"
fi

echo ""
echo "🎯 Environment Status:"
echo "======================"

# Check all services
services=("Redis" "Rails Server" "Sidekiq")
for service in "${services[@]}"; do
    if check_process "$service"; then
        echo "✅ $service: Running"
    else
        echo "❌ $service: Not running"
    fi
done

echo ""
echo "📊 Quick Health Check:"
echo "====================="

# Test database connection
if bundle exec rails runner "puts User.count" > /dev/null 2>&1; then
    echo "✅ Database: Connected"
else
    echo "❌ Database: Connection failed"
fi

# Test Redis connection
if bundle exec rails runner "require 'sidekiq/api'; puts Sidekiq::Stats.new.processed" > /dev/null 2>&1; then
    echo "✅ Sidekiq: Connected to Redis"
else
    echo "❌ Sidekiq: Redis connection failed"
fi

# Test job enqueueing
if bundle exec rails runner "LeetcodeSessionRefreshJob.perform_later(1)" > /dev/null 2>&1; then
    echo "✅ Jobs: Can be enqueued"
else
    echo "❌ Jobs: Enqueueing failed"
fi

echo ""
echo "🌐 Access Points:"
echo "================="
echo "📱 Web App: http://localhost:3000"
echo "📊 Dashboard: http://localhost:3000/dashboard"
echo "🔧 Sidekiq UI: http://localhost:3000/sidekiq (if configured)"

echo ""
echo "📝 Useful Commands:"
echo "==================="
echo "🔍 Check session health: bundle exec rake leetcode:check_session_health"
echo "🔄 Manual refresh: bundle exec rake leetcode:refresh_sessions"
echo "📊 Monitor jobs: tail -f log/sidekiq.log"
echo "🛑 Stop all services: ./stop_local_environment.sh"

echo ""
echo "✅ Local environment is ready!"
echo "=============================="
