// Background script for LeetCode Tracker extension
chrome.runtime.onInstalled.addListener(() => {
  console.log('LeetCode Tracker extension installed');
});

// Handle messages from popup and content scripts
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'getCookies') {
    chrome.cookies.getAll({ domain: 'leetcode.com' }, (cookies) => {
      const cookieMap = {};
      cookies.forEach(cookie => {
        cookieMap[cookie.name] = cookie.value;
      });
      sendResponse({ cookies: cookieMap });
    });
    return true; // Keep message channel open for async response
  }
});
