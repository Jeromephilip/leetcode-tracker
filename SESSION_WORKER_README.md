# LeetCode Session Worker Implementation

This implementation provides automatic session refresh for LeetCode accounts without requiring users to re-link their accounts.

## Components

### 1. Background Jobs
- **LeetcodeSessionRefreshJob**: Refreshes individual user sessions
- **LeetcodeSessionRefreshSchedulerJob**: Schedules periodic refreshes for all users

### 2. Service Methods
- **LeetcodeService#refresh_session**: Attempts to refresh LeetCode session
- **LeetcodeService#session_healthy?**: Checks if session is still valid
- **LeetcodeService#cookies_expired?**: Determines if cookies have expired

### 3. User Model Methods
- **User#session_needs_refresh?**: Checks if session needs refresh based on timing
- **User#calculate_refresh_interval**: Calculates refresh interval based on user activity
- **User#determine_activity_level**: Determines user activity level (active/weekly/monthly/inactive)
- **User#schedule_session_refresh**: Schedules a session refresh job
- **User#leetcode_session_healthy?**: Checks session health for the user

### 4. API Endpoints
- **POST /api/v1/leetcode/refresh_session**: Manually trigger session refresh
- **GET /api/v1/leetcode/session_health**: Check session health status

### 5. Rake Tasks
- **rake leetcode:refresh_sessions**: Refresh sessions for users who need it
- **rake leetcode:refresh_user_session[user_id]**: Refresh session for specific user
- **rake leetcode:check_session_health**: Check health of all user sessions
- **rake leetcode:schedule_periodic_refresh**: Schedule periodic refresh jobs
- **rake leetcode:force_refresh_all**: Force refresh all sessions (ignores timing)

## Usage

### Starting the Session Worker
```bash
# Start Sidekiq to process background jobs
bundle exec sidekiq

# In another terminal, schedule periodic refreshes
rake leetcode:schedule_periodic_refresh
```

### Manual Session Refresh
```bash
# Refresh all sessions that need it
rake leetcode:refresh_sessions

# Refresh specific user
rake leetcode:refresh_user_session[123]

# Force refresh all sessions
rake leetcode:force_refresh_all
```

### API Usage
```javascript
// Check session health
fetch('/api/v1/leetcode/session_health', {
  method: 'GET',
  headers: {
    'Authorization': 'Bearer your_token',
    'Content-Type': 'application/json'
  }
})

// Trigger session refresh
fetch('/api/v1/leetcode/refresh_session', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer your_token',
    'Content-Type': 'application/json'
  }
})
```

## How It Works

1. **Proactive Refresh**: Sessions are refreshed before they expire, not after
2. **Activity-Based Intervals**: Active users get more frequent refreshes than inactive ones
3. **Background Processing**: All refresh operations happen in the background
4. **Graceful Degradation**: When sessions do expire, the system handles it gracefully
5. **Retry Logic**: Failed refresh attempts are retried with exponential backoff

## User Activity Levels

- **Active** (updated in last 7 days): Refresh every 4 hours
- **Weekly** (updated in last 30 days): Refresh every 12 hours  
- **Monthly** (updated in last 90 days): Refresh daily
- **Inactive** (90+ days): Refresh weekly

## Benefits

- **Seamless User Experience**: Users don't see "session expired" errors
- **Reduced Support**: Fewer users need to re-link accounts
- **Better Data Freshness**: User data stays up-to-date automatically
- **Scalable**: Handles multiple users efficiently with background jobs
- **Resilient**: Handles network issues and API rate limits gracefully

## Testing

Run the test script to verify implementation:
```bash
rails runner test_session_worker.rb
```

## Monitoring

Check Sidekiq web UI to monitor job status:
- Visit `/sidekiq` (if configured)
- Check Rails logs for session refresh activity
- Use `rake leetcode:check_session_health` to monitor session health
