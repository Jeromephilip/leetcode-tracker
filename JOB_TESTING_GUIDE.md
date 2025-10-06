# Job Testing Guide for LeetCode Session Worker

This guide shows you how to test and monitor the session worker jobs to ensure they're working correctly.

## Quick Status Check

### 1. **Check if Sidekiq is Running**
```bash
# Check if Sidekiq process is running
ps aux | grep sidekiq

# Or check if it's listening on the default port
lsof -i :6379  # Redis port
```

### 2. **Check Job Statistics**
```bash
# Quick stats check
rails runner "require 'sidekiq/api'; stats = Sidekiq::Stats.new; puts 'Processed: #{stats.processed}, Failed: #{stats.failed}, Busy: #{stats.workers_size}'"
```

### 3. **Run Comprehensive Monitor**
```bash
# Run the full monitoring script
rails runner monitor_jobs.rb
```

## Testing Job Functionality

### 1. **Test Job Enqueueing**
```bash
# Test if jobs can be enqueued
rails runner "LeetcodeSessionRefreshJob.perform_later(User.first.id); puts 'Job enqueued!'"
```

### 2. **Test Session Health Check**
```bash
# Check session health for all users
bundle exec rake leetcode:check_session_health
```

### 3. **Test Manual Session Refresh**
```bash
# Refresh sessions for users who need it
bundle exec rake leetcode:refresh_sessions
```

### 4. **Test Force Refresh**
```bash
# Force refresh all sessions (ignores timing)
bundle exec rake leetcode:force_refresh_all
```

### 5. **Test Specific User Refresh**
```bash
# Refresh session for specific user
bundle exec rake leetcode:refresh_user_session[USER_ID]
```

## Monitoring Job Execution

### 1. **Real-time Monitoring**
```bash
# Monitor jobs in real-time (updates every 5 seconds)
watch -n 5 'rails runner monitor_jobs.rb'
```

### 2. **Check Rails Logs**
```bash
# Monitor Rails logs for job activity
tail -f log/development.log | grep -i "session\|leetcode\|job"
```

### 3. **Check Sidekiq Logs**
```bash
# Monitor Sidekiq logs (if configured)
tail -f log/sidekiq.log
```

### 4. **Check Redis**
```bash
# Connect to Redis and check queues
redis-cli
> LLEN sidekiq:queue:default
> LRANGE sidekiq:queue:default 0 -1
```

## Expected Behavior

### ✅ **Jobs Working Correctly When:**

1. **Sidekiq Statistics Show:**
   - Processed count increases over time
   - Failed count remains 0 (or low)
   - Busy count shows active workers when jobs are running
   - Enqueued count is 0 when no jobs are waiting

2. **User Session Status Shows:**
   - Users have `leetcode_last_sync` timestamps
   - Activity levels are calculated correctly
   - Refresh intervals are appropriate
   - `session_needs_refresh?` returns correct values

3. **Rake Tasks Execute:**
   - `check_session_health` shows user status
   - `refresh_sessions` schedules jobs
   - No errors in output

4. **API Endpoints Respond:**
   - Return 302 (redirect to login) for unauthenticated requests
   - Return proper JSON for authenticated requests

### ❌ **Jobs Not Working When:**

1. **Sidekiq Statistics Show:**
   - Failed count is high
   - Dead jobs exist
   - Processed count doesn't increase

2. **Common Error Messages:**
   - "NoMethodError: undefined method `perform_later`"
   - "Redis connection failed"
   - "Sidekiq not running"

3. **Rake Tasks Fail:**
   - Database connection errors
   - User not found errors
   - Arel query errors

## Troubleshooting

### 1. **Jobs Not Processing**
```bash
# Check if Sidekiq is running
ps aux | grep sidekiq

# Start Sidekiq if not running
bundle exec sidekiq

# Check Redis connection
redis-cli ping
```

### 2. **Jobs Failing**
```bash
# Check failed jobs
rails runner "require 'sidekiq/api'; Sidekiq::RetrySet.new.each { |job| puts job.error_message }"

# Check dead jobs
rails runner "require 'sidekiq/api'; Sidekiq::DeadSet.new.each { |job| puts job.error_message }"
```

### 3. **Database Issues**
```bash
# Check database connection
rails runner "puts User.count"

# Check if users exist
rails runner "puts User.where.not(leetcode_cookies: nil).count"
```

### 4. **Redis Issues**
```bash
# Check Redis status
redis-cli ping

# Clear Redis if needed (WARNING: This will clear all job queues)
redis-cli FLUSHALL
```

## Performance Monitoring

### 1. **Job Execution Time**
```bash
# Monitor job execution times in logs
tail -f log/development.log | grep "Completed LeetcodeSessionRefreshJob"
```

### 2. **Memory Usage**
```bash
# Check Sidekiq memory usage
ps aux | grep sidekiq | awk '{print $6}' | head -1
```

### 3. **Queue Depth**
```bash
# Check queue depth
rails runner "require 'sidekiq/api'; puts Sidekiq::Queue.new('default').size"
```

## Continuous Monitoring

### 1. **Set up Monitoring Script**
```bash
# Make monitoring script executable
chmod +x monitor_jobs.rb

# Run every 5 minutes
*/5 * * * * cd /path/to/leetcode-tracker && rails runner monitor_jobs.rb >> log/job_monitor.log
```

### 2. **Set up Alerts**
```bash
# Alert if jobs are failing
rails runner "require 'sidekiq/api'; exit 1 if Sidekiq::Stats.new.failed > 10"
```

### 3. **Health Check Endpoint**
```bash
# Create a health check endpoint (add to routes.rb)
get '/health/jobs', to: 'health#jobs'
```

## Success Criteria

Your session worker is working correctly if:

- [ ] Sidekiq is running and processing jobs
- [ ] Jobs are being enqueued without errors
- [ ] Jobs are being processed successfully
- [ ] User session data is being updated
- [ ] Rake tasks execute without errors
- [ ] API endpoints respond correctly
- [ ] No jobs are failing or dead
- [ ] Session health checks work
- [ ] Manual refresh functionality works

## Next Steps

1. **Production Deployment:**
   - Set up Sidekiq as a system service
   - Configure Redis for production
   - Set up monitoring and alerting

2. **Performance Optimization:**
   - Monitor job execution times
   - Adjust concurrency settings
   - Implement job prioritization

3. **Error Handling:**
   - Set up error notifications
   - Implement retry strategies
   - Add circuit breakers for external APIs
