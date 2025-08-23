# LeetCode Tracker Chrome Extension

This Chrome extension allows you to link your LeetCode account to the LeetCode Tracker web application.

## Installation

1. Open Chrome and navigate to `chrome://extensions/`
2. Enable "Developer mode" in the top right corner
3. Click "Load unpacked" and select the `public/chrome-extension` folder from this project
4. The extension should now appear in your extensions list

## Usage

1. **Log in to LeetCode**: First, make sure you're logged into your LeetCode account at [leetcode.com](https://leetcode.com)
2. **Click the extension icon**: Click on the LeetCode Tracker extension icon in your Chrome toolbar
3. **Link your account**: Click "Link Account" to connect your LeetCode account to the tracker
4. **View your stats**: Once linked, you'll see your LeetCode statistics including problems solved and ranking

## Features

- **Secure Authentication**: Uses your LeetCode cookies to authenticate with the tracker app
- **Real-time Sync**: Sync your profile data to get the latest statistics
- **Account Management**: Easily connect and disconnect your LeetCode account

## How it Works

The extension:
1. Fetches your LeetCode authentication cookies (when you're logged in)
2. Sends these cookies to the LeetCode Tracker Rails application
3. The Rails app validates the cookies and creates/updates your user account
4. You can then sync your profile data and view your LeetCode statistics

## Security

- Cookies are only sent to your local development server (`localhost:3000`)
- No data is stored locally except for the authentication token
- The extension only requests necessary permissions (cookies for leetcode.com)

## Troubleshooting

- **"Please log in to LeetCode first"**: Make sure you're logged into LeetCode and refresh the extension popup
- **"Failed to link account"**: Check that your Rails server is running and accessible
- **Extension not working**: Try reloading the extension or restarting Chrome

## Development

To modify the extension:
1. Edit the files in the `public/chrome-extension` folder
2. Go to `chrome://extensions/` and click the refresh button on the extension
3. Test your changes

## API Endpoints

The extension communicates with these Rails API endpoints:
- `POST /api/v1/leetcode/authenticate` - Link LeetCode account
- `POST /api/v1/leetcode/sync_profile` - Sync user profile data
