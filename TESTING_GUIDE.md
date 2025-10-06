# Testing Guide for LeetCode Session Worker

This guide shows you how to test the session worker implementation comprehensively.

## Quick Verification

### 1. **Basic Component Test**
```bash
# Test that all components load correctly
rails runner -e "puts 'Jobs: ' + [LeetcodeSessionRefreshJob, LeetcodeSessionRefreshSchedulerJob].map(&:name).join(', ')"
```

### 2. **User Model Methods Test**
```bash
# Test user model methods
rails runner "
user = User.first
puts 'Activity: ' + user.determine_activity_level.to_s
puts 'Interval: ' + user.calculate_refresh_interval.to_s
puts 'Needs refresh: ' + user.session_needs_refresh?.to_s
"
```

## Rake Task Testing

### 1. **Check Session Health**
```bash
# Check health of all user sessions
bundle exec rake leetcode:check_session_health
```

**Expected Output:**
```
Checking session health for X users...
User 1 (username): Healthy
User 2 (username): Expired
Session Health Summary:
  Healthy: 1
  Expired: 1
  Total: 2
```

### 2. **Manual Session Refresh**
```bash
# Refresh sessions for users who need it
bundle exec rake leetcode:refresh_sessions
```

**Expected Output:**
```
Found 2 users needing session refresh
Scheduled refresh for user 1 (username)
Scheduled refresh for user 2 (username)
Scheduled 2 session refresh jobs
```

### 3. **Refresh Specific User**
```bash
# Refresh session for specific user
bundle exec rake leetcode:refresh_user_session[USER_ID]
```

### 4. **Force Refresh All**
```bash
# Force refresh all sessions (ignores timing)
bundle exec rake leetcode:force_refresh_all
```

## Background Job Testing

### 1. **Start Sidekiq**
```bash
# Start Sidekiq to process background jobs
bundle exec sidekiq
```

### 2. **Schedule Periodic Refresh**
```bash
# Schedule periodic refresh jobs
bundle exec rake leetcode:schedule_periodic_refresh
```

### 3. **Monitor Jobs**
- Check Sidekiq web UI (if configured): `http://localhost:3000/sidekiq`
- Check Rails logs for job execution
- Monitor Redis for job queues

## API Endpoint Testing

### 1. **Session Health Check**
```bash
# Test session health endpoint
curl -X GET "http://localhost:3000/api/v1/leetcode/session_health" \
  -H "Content-Type: application/json" \
  -b "your_session_cookie"
```

**Expected Response:**
```json
{
  "healthy": true,
  "last_sync": "2025-01-15T10:30:00Z",
  "leetcode_username": "your_username",
  "activity_level": "active",
  "refresh_interval": 14400
}
```

### 2. **Manual Session Refresh**
```bash
# Trigger manual session refresh
curl -X POST "http://localhost:3000/api/v1/leetcode/refresh_session" \
  -H "Content-Type: application/json" \
  -b "your_session_cookie"
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Session refresh initiated. Please check back in a few minutes.",
  "user_id": 123,
  "leetcode_username": "your_username"
}
```

## Unit Testing

### 1. **Run Model Tests**
```bash
# Test user model methods
bundle exec rails test test/models/user_session_test.rb
```

### 2. **Run Job Tests**
```bash
# Test background jobs
bundle exec rails test test/jobs/leetcode_session_refresh_job_test.rb
```

### 3. **Run Integration Tests**
```bash
# Test API endpoints
bundle exec rails test test/integration/session_worker_integration_test.rb
```

## Real-World Testing

### 1. **With Real LeetCode Account**
1. Link a real LeetCode account through your app
2. Wait for background jobs to run
3. Check session health: `rake leetcode:check_session_health`
4. Verify data stays fresh

### 2. **Session Expiration Testing**
1. Wait for LeetCode session to expire (or manually expire cookies)
2. Run session health check
3. Verify system handles expiration gracefully
4. Test manual refresh functionality

### 3. **Load Testing**
```bash
# Test with multiple users
rails runner "
10.times do |i|
  user = User.create!(
    email: \"test#{i}@example.com\",
    password: 'password123',
    leetcode_cookies: {LEETCODE_SESSION: \"session_#{i}\"}.to_json
  )
  LeetcodeSessionRefreshJob.perform_later(user.id)
end
"
```

## Monitoring and Debugging

### 1. **Check Rails Logs**
```bash
# Monitor Rails logs for session refresh activity
tail -f log/development.log | grep -i "session\|leetcode"
```

### 2. **Check Sidekiq Logs**
```bash
# Monitor Sidekiq job execution
tail -f log/sidekiq.log
```

### 3. **Database Queries**
```sql
-- Check user session data
SELECT id, email, leetcode_username, leetcode_last_sync 
FROM users 
WHERE leetcode_cookies IS NOT NULL;

-- Check recent job activity
SELECT * FROM sidekiq_jobs 
WHERE class = 'LeetcodeSessionRefreshJob' 
ORDER BY created_at DESC 
LIMIT 10;
```

## Troubleshooting

### Common Issues:

1. **Jobs Not Processing**
   - Check if Sidekiq is running: `ps aux | grep sidekiq`
   - Check Redis connection
   - Verify job queue configuration

2. **Session Health Always False**
   - Check LeetCode cookies are valid
   - Verify network connectivity to LeetCode
   - Check for rate limiting

3. **API Endpoints Return 401**
   - Ensure user is authenticated
   - Check session cookies
   - Verify CSRF tokens

4. **Rake Tasks Fail**
   - Check database connection
   - Verify user fixtures exist
   - Check for syntax errors in job classes

## Success Criteria

Your session worker is working correctly if:

- [ ] Rake tasks execute without errors
- [ ] Background jobs are enqueued and processed
- [ ] API endpoints return proper responses
- [ ] Session health checks work
- [ ] User activity levels are calculated correctly
- [ ] Refresh intervals are appropriate
- [ ] Expired sessions are handled gracefully
- [ ] No user-facing "session expired" errors occur

## Next Steps

1. **Production Deployment**
   - Set up Sidekiq in production
   - Configure Redis for job queues
   - Set up monitoring and alerting

2. **Performance Optimization**
   - Monitor job execution times
   - Adjust refresh intervals based on usage
   - Implement job prioritization

3. **User Experience**
   - Add UI indicators for session health
   - Implement automatic refresh notifications
   - Add manual refresh buttons
