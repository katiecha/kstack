---
name: create-chrome-extension
description: Create a new Chrome extension project from scratch. Use when the user wants to build a Chrome extension, start a new extension project, scaffold extension boilerplate, or create a browser extension with popup, content scripts, or background workers.
---

# Create a Chrome extension

Create a new Chrome extension project with Manifest V3.

## Usage

```
/create-chrome-extension [name] [type]
```

**Types:**
- `popup` - Extension with popup UI (default)
- `content` - Content script that runs on pages
- `background` - Background service worker
- `full` - All of the above combined

## Instructions

When this skill is invoked, create a Chrome extension project with the following structure based on the type requested.

### Step 1: Ask for details if not provided

If the user didn't specify a name or type, ask:
1. Extension name (e.g., "My Extension")
2. Extension type (popup, content, background, or full)
3. Brief description of what it should do

### Step 2: Create the project structure

Create a new directory with the extension name (kebab-case) containing:

#### For ALL types - manifest.json (Manifest V3)

```json
{
  "manifest_version": 3,
  "name": "Extension Name",
  "version": "1.0",
  "description": "Brief description",
  "permissions": [],
  "action": {}
}
```

#### For `popup` type:

**manifest.json additions:**
```json
{
  "permissions": ["activeTab", "scripting"],
  "action": {
    "default_popup": "popup.html"
  }
}
```

**popup.html:**
```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body {
      width: 300px;
      padding: 16px;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      font-size: 14px;
    }
    h3 {
      margin: 0 0 12px 0;
      font-size: 16px;
    }
    button {
      width: 100%;
      padding: 10px;
      margin-bottom: 8px;
      border: none;
      border-radius: 6px;
      cursor: pointer;
      font-size: 14px;
      background-color: #4285f4;
      color: white;
      transition: background-color 0.2s;
    }
    button:hover {
      background-color: #3367d6;
    }
    .status {
      margin-top: 8px;
      padding: 8px;
      border-radius: 4px;
      text-align: center;
      display: none;
    }
    .status.success {
      display: block;
      background-color: #e6f4ea;
      color: #137333;
    }
    .status.error {
      display: block;
      background-color: #fce8e6;
      color: #c5221f;
    }
  </style>
</head>
<body>
  <h3>Extension Name</h3>
  <button id="actionBtn">Do Action</button>
  <div id="status" class="status"></div>
  <script src="popup.js"></script>
</body>
</html>
```

**popup.js:**
```javascript
// Function to execute in the page context
function doAction() {
  // Your page manipulation code here
  return { success: true, message: 'Action completed' };
}

function showStatus(message, isError = false) {
  const status = document.getElementById('status');
  status.textContent = message;
  status.className = isError ? 'status error' : 'status success';
  setTimeout(() => {
    status.className = 'status';
  }, 2000);
}

document.getElementById('actionBtn').addEventListener('click', async () => {
  try {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });

    const results = await chrome.scripting.executeScript({
      target: { tabId: tab.id },
      func: doAction
    });

    const result = results[0]?.result;
    showStatus(result?.message || 'Done');
  } catch (error) {
    showStatus(error.message, true);
  }
});
```

#### For `content` type:

**manifest.json additions:**
```json
{
  "content_scripts": [
    {
      "matches": ["<all_urls>"],
      "js": ["content.js"],
      "css": ["content.css"]
    }
  ]
}
```

**content.js:**
```javascript
// Content script - runs automatically on matched pages
(function() {
  'use strict';

  // Your content script code here
  console.log('Extension loaded on:', window.location.href);

  // Example: Modify the page
  // document.body.style.border = '5px solid red';
})();
```

**content.css:**
```css
/* Styles injected into matched pages */
```

#### For `background` type:

**manifest.json additions:**
```json
{
  "background": {
    "service_worker": "background.js"
  },
  "permissions": ["storage"]
}
```

**background.js:**
```javascript
// Background service worker - runs in the background
chrome.runtime.onInstalled.addListener(() => {
  console.log('Extension installed');
});

// Listen for messages from content scripts or popup
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  console.log('Message received:', message);
  sendResponse({ status: 'ok' });
  return true; // Keep channel open for async response
});
```

#### For `full` type:

Combine all of the above into a single project.

### Step 3: Create README.md

```markdown
# extension-name

Brief description

## Installation

1. Open Chrome and go to `chrome://extensions/`
2. Enable **Developer mode** (toggle in top right)
3. Click **Load unpacked**
4. Select this folder

## Usage

Describe how to use the extension.

## Development

To reload after changes:
1. Go to `chrome://extensions/`
2. Click the refresh icon on your extension

## References

- [Chrome Extensions Documentation](https://developer.chrome.com/docs/extensions/)
- [Manifest V3 Migration](https://developer.chrome.com/docs/extensions/develop/migrate/what-is-mv3)
- [chrome-extensions-samples](https://github.com/GoogleChrome/chrome-extensions-samples)
```

### Step 4: Customize for the user's specific needs

After creating the boilerplate, ask the user what functionality they want and implement it.

## Common Permissions Reference

| Permission | Use Case |
|------------|----------|
| `activeTab` | Access current tab when user clicks extension |
| `scripting` | Execute scripts in pages |
| `storage` | Store data locally |
| `tabs` | Access tab URLs and titles |
| `contextMenus` | Add right-click menu items |
| `notifications` | Show desktop notifications |
| `alarms` | Schedule periodic tasks |
| `cookies` | Read/write cookies |
| `webRequest` | Intercept network requests |

## Common Match Patterns

| Pattern | Matches |
|---------|---------|
| `<all_urls>` | All URLs |
| `*://*.example.com/*` | All pages on example.com |
| `https://www.google.com/*` | Google pages only |
| `*://*/path/*` | Specific path on any domain |

## Tips

- Always use Manifest V3 (manifest_version: 3)
- Use `chrome.scripting.executeScript` instead of inline scripts
- Service workers (background.js) are event-driven and don't persist
- Content scripts run in an isolated world - use messaging for communication
- Test on `chrome://extensions/` with Developer mode enabled
