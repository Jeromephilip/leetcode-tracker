const API_BASE_URL = 'http://localhost:3000';

const statusEl = document.getElementById('status');
const linkAccountBtn = document.getElementById('linkAccount');
const syncProfileBtn = document.getElementById('syncProfile');
const disconnectBtn = document.getElementById('disconnect');
const statsEl = document.getElementById('stats');
const solvedCountEl = document.getElementById('solvedCount');
const totalCountEl = document.getElementById('totalCount');
const rankEl = document.getElementById('rank');

let isConnected = false;
let authToken = null;

document.addEventListener('DOMContentLoaded', function() {
  checkConnectionStatus();
  checkWebAppLogin();
  setupEventListeners();
});

function setupEventListeners() {
  document.getElementById('linkAccount').addEventListener('click', linkAccount);
  document.getElementById('syncProfile').addEventListener('click', syncProfile);
  document.getElementById('disconnect').addEventListener('click', disconnect);
  
  const checkUsernameBtn = document.getElementById('checkUsername');
  if (checkUsernameBtn) {
    checkUsernameBtn.addEventListener('click', async () => {
      const usernameInput = document.getElementById('usernameCheck');
      const usernameStatus = document.getElementById('usernameStatus');
      const username = usernameInput.value.trim();
      
      if (!username) {
        usernameStatus.textContent = 'Please enter a username to check';
        usernameStatus.style.color = '#721c24';
        return;
      }
      
      checkUsernameBtn.disabled = true;
      checkUsernameBtn.textContent = 'Checking...';
      
      const result = await checkUsernameAvailability(username);
      
      usernameStatus.textContent = result.message;
      usernameStatus.style.color = result.available ? '#155724' : '#721c24';
      
      checkUsernameBtn.disabled = false;
      checkUsernameBtn.textContent = 'Check';
    });
  }
}

async function checkConnectionStatus() {
  const token = await getStoredToken();
  if (token) {
    authToken = token;
    isConnected = true;
    updateUI();
    await loadUserStats();
  }
}

async function checkWebAppLogin() {
  try {
    const response = await fetch('http://localhost:3000/dashboard', {
      method: 'GET',
      credentials: 'include'
    });
    
    if (response.ok) {
      const webAppStatus = document.getElementById('webAppStatus');
      const webAppLinks = document.getElementById('webAppLinks');
      if (webAppStatus) {
        webAppStatus.style.display = 'block';
        webAppStatus.textContent = '✅ Logged into web app';
        webAppStatus.style.background = '#d4edda';
        webAppStatus.style.color = '#155724';
      }
      if (webAppLinks) {
        webAppLinks.innerHTML = '<a href="http://localhost:3000/dashboard" target="_blank" style="color: #007bff; text-decoration: none; font-size: 12px;">📊 Go to Dashboard</a>';
        webAppLinks.style.display = 'block';
      }
    } else {
      const webAppStatus = document.getElementById('webAppStatus');
      const webAppLinks = document.getElementById('webAppLinks');
      if (webAppStatus) {
        webAppStatus.style.display = 'block';
        webAppStatus.textContent = '❌ Not logged into web app';
        webAppStatus.style.background = '#f8d7da';
        webAppStatus.style.color = '#721c24';
      }
      if (webAppLinks) {
        webAppLinks.style.display = 'block';
      }
    }
  } catch (error) {
    console.error('Error checking web app login status:', error);
    const webAppStatus = document.getElementById('webAppStatus');
    const webAppLinks = document.getElementById('webAppLinks');
    if (webAppStatus) {
      webAppStatus.style.display = 'block';
      webAppStatus.textContent = '❌ Error checking login status';
      webAppStatus.style.background = '#f8d7da';
      webAppStatus.style.color = '#721c24';
    }
    if (webAppLinks) {
      webAppLinks.style.display = 'block';
    }
  }
}

async function linkAccount() {
  try {
    console.log('linkAccount function called');
    updateStatus('Linking account...', 'info');
    linkAccountBtn.disabled = true;
    
    console.log('About to fetch cookies...');
    const cookies = await getLeetcodeCookies();
    console.log('Fetched cookies:', cookies);
    
    if (!cookies || Object.keys(cookies).length === 0) {
      console.log('No cookies found, showing error');
      updateStatus('Please log in to LeetCode first and refresh this popup', 'error');
      linkAccountBtn.disabled = false;
      return;
    }
    
    updateStatus('Checking account availability...', 'info');
    
    const requestBody = { cookies: cookies };
    console.log('Sending request body:', requestBody);
    
    const response = await fetch(`${API_BASE_URL}/api/v1/leetcode/authenticate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(requestBody)
    });
    
    const data = await response.json();
    
    if (response.ok) {
      if (data.action === 'account_created') {
        updateStatus('Account created and linked successfully! Redirecting to login...', 'success');
        setTimeout(() => {
          window.open('http://localhost:3000/users/sign_in', '_blank');
        }, 1500);
      } else {
        updateStatus('Account linked successfully! Redirecting to dashboard...', 'success');
        setTimeout(() => {
          if (data.redirect_url) {
            window.open(data.redirect_url, '_blank');
          }
        }, 1500);
      }
      
      updateUI();
      await loadUserStats();
    } else {
      if (response.status === 409 && data.error === 'LeetCode account already linked') {
        const errorMessage = `❌ LeetCode Account Already Linked!\n\n` +
                           `The username "${data.leetcode_username}" is already linked to another account.\n\n` +
                           `Currently owned by: ${data.existing_user_email}\n\n` +
                           `If this is your account, please log in with that email instead.`;
        updateStatus(errorMessage, 'error');
      } else if (data.details) {
        updateStatus(`Error: ${data.error}\n\n${data.details}`, 'error');
      } else {
        updateStatus(`Error: ${data.error}`, 'error');
      }
    }
  } catch (error) {
    console.error('Error linking account:', error);
    updateStatus('Failed to link account. Please try again.', 'error');
  } finally {
    linkAccountBtn.disabled = false;
  }
}

async function syncProfile() {
  try {
    updateStatus('Syncing profile...', 'info');
    syncProfileBtn.disabled = true;
    
    const response = await fetch(`${API_BASE_URL}/api/v1/leetcode/sync_profile`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authToken}`
      }
    });
    
    const data = await response.json();
    
    if (response.ok) {
      updateStatus('Profile synced successfully!', 'success');
      await loadUserStats();
    } else {
      updateStatus(`Error: ${data.error}`, 'error');
    }
  } catch (error) {
    console.error('Error syncing profile:', error);
    updateStatus('Failed to sync profile. Please try again.', 'error');
  } finally {
    syncProfileBtn.disabled = false;
  }
}

async function disconnect() {
  try {
    await removeStoredToken();
    authToken = null;
    isConnected = false;
    updateStatus('Account disconnected', 'info');
    updateUI();
    hideStats();
  } catch (error) {
    console.error('Error disconnecting:', error);
    updateStatus('Failed to disconnect. Please try again.', 'error');
  }
}

async function loadUserStats() {
  try {
    const response = await fetch(`${API_BASE_URL}/api/v1/leetcode/sync_profile`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authToken}`
      }
    });
    
    const data = await response.json();
    
    if (response.ok) {
      showStats(data.leetcode_stats);
    }
  } catch (error) {
    console.error('Error loading stats:', error);
  }
}

async function getLeetcodeCookies() {
  return new Promise((resolve) => {
    console.log('Fetching cookies for leetcode.com...');
    
    if (chrome.cookies && chrome.cookies.getAll) {
      chrome.cookies.getAll({ domain: 'leetcode.com' }, (cookies) => {
        console.log('Raw cookies from Chrome:', cookies);
        const cookieMap = {};
        if (cookies && cookies.length > 0) {
          cookies.forEach(cookie => {
            cookieMap[cookie.name] = cookie.value;
          });
        }
        console.log('Processed cookie map:', cookieMap);
        resolve(cookieMap);
      });
    } else {
      console.error('Chrome cookies API not available');
      resolve({});
    }
  });
}

async function checkUsernameAvailability(username) {
  try {
    const response = await fetch(`${API_BASE_URL}/api/v1/leetcode/check_username/${encodeURIComponent(username)}`);
    const data = await response.json();
    
    if (response.ok) {
      if (data.available) {
        return { available: true, message: `✅ Username "${username}" is available!` };
      } else {
        return { 
          available: false, 
          message: `❌ Username "${username}" is already taken by ${data.existing_user.email}` 
        };
      }
    } else {
      return { available: false, message: `Error: ${data.error}` };
    }
  } catch (error) {
    console.error('Error checking username availability:', error);
    return { available: false, message: 'Failed to check username availability' };
  }
}

function updateUI() {
  if (isConnected) {
    linkAccountBtn.style.display = 'none';
    syncProfileBtn.style.display = 'inline-block';
    disconnectBtn.style.display = 'inline-block';
  } else {
    linkAccountBtn.style.display = 'inline-block';
    syncProfileBtn.style.display = 'none';
    disconnectBtn.style.display = 'none';
    hideStats();
  }
}

function showStats(stats) {
  solvedCountEl.textContent = stats.solved_count || '-';
  totalCountEl.textContent = stats.total_count || '-';
  rankEl.textContent = stats.rank || '-';
  statsEl.style.display = 'block';
}

function hideStats() {
  statsEl.style.display = 'none';
}

function updateStatus(message, type) {
  statusEl.textContent = message;
  statusEl.className = `status ${type}`;
}

async function storeToken(token) {
  return new Promise((resolve) => {
    chrome.storage.local.set({ authToken: token }, resolve);
  });
}

async function getStoredToken() {
  return new Promise((resolve) => {
    chrome.storage.local.get(['authToken'], (result) => {
      resolve(result.authToken);
    });
  });
}

async function removeStoredToken() {
  return new Promise((resolve) => {
    chrome.storage.local.remove(['authToken'], resolve);
  });
}


