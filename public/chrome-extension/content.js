// Content script for LeetCode Tracker extension
// This script runs on LeetCode pages

console.log('LeetCode Tracker content script loaded');

// Listen for messages from the extension
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'getPageInfo') {
    // Extract basic page information
    const pageInfo = {
      url: window.location.href,
      title: document.title,
      timestamp: new Date().toISOString()
    };
    sendResponse(pageInfo);
  }
});

// Notify that content script is ready
chrome.runtime.sendMessage({ action: 'contentScriptReady' });
