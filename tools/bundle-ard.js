const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const targetDir = process.argv[2] || '/tmp/novnc-ard';
const ardHtmlPath = path.join(targetDir, 'ard.html');

console.log('Bundling noVNC-ARD for maximum speed and zero network latency...');

let html = fs.readFileSync(ardHtmlPath, 'utf8');

const scriptMatch = html.match(/<script type="module">([\s\S]*?)<\/script>/);
if (!scriptMatch) {
  console.log('No inline module script found in ard.html, skipping bundle.');
  process.exit(0);
}

const inlineJs = scriptMatch[1];
const entryPath = path.join(targetDir, 'app-entry.js');
const bundlePath = path.join(targetDir, 'app-bundle.js');

fs.writeFileSync(entryPath, inlineJs);
console.log('Wrote app-entry.js');

try {
  execSync(`npx -y esbuild "${entryPath}" --bundle --format=esm --outfile="${bundlePath}"`, {
    cwd: targetDir,
    stdio: 'inherit'
  });
  console.log('esbuild bundle created successfully: app-bundle.js');

  const autoConnectSnippet = `
<script>
window.addEventListener('load', () => {
  console.log('[AutoConnect] Page loaded, initializing automated connection...');
  let connectInterval = setInterval(() => {
    const btn = document.getElementById('noVNC_connect_button');
    if (btn && btn.offsetParent !== null) {
      console.log('[AutoConnect] Clicking Connect button...');
      btn.click();
      clearInterval(connectInterval);
    }
  }, 300);

  // Auto-respond to credentials dialog with user 'ulgen'
  let submitted = false;
  const observer = new MutationObserver(() => {
    const dlg = document.getElementById('noVNC_credentials_dlg');
    if (dlg && window.getComputedStyle(dlg).display !== 'none' && !submitted) {
      const userInput = document.getElementById('noVNC_username_input');
      const passInput = document.getElementById('noVNC_password_input');
      const submitBtn = document.getElementById('noVNC_credentials_button');
      if (userInput && passInput && submitBtn) {
        submitted = true;
        console.log('[AutoConnect] Injecting ulgen / ulgen123 credentials...');
        userInput.value = 'ulgen';
        userInput.dispatchEvent(new Event('input', { bubbles: true }));
        userInput.dispatchEvent(new Event('change', { bubbles: true }));
        passInput.value = 'ulgen123';
        passInput.dispatchEvent(new Event('input', { bubbles: true }));
        passInput.dispatchEvent(new Event('change', { bubbles: true }));
        submitBtn.click();
      }
    } else if (dlg && window.getComputedStyle(dlg).display === 'none') {
      submitted = false;
    }
  });
  observer.observe(document.body, { childList: true, subtree: true, attributes: true });
});
</script>
`;

  let newHtml = html.replace(scriptMatch[0], '<script type="module" src="app-bundle.js"></script>');
  newHtml = newHtml.replace('</body>', `${autoConnectSnippet}\n</body>`);
  fs.writeFileSync(ardHtmlPath, newHtml);
  console.log('ard.html updated with app-bundle.js and seamless auto-auth!');
} catch (e) {
  console.error('esbuild failed:', e.message);
}
