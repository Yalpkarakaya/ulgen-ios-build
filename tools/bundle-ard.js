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
window.addEventListener('DOMContentLoaded', () => {
  console.log('[AutoConnect] DOM ready, monitoring for ARD authentication dialog...');
  let submitted = false;
  const observer = new MutationObserver(() => {
    const dlg = document.getElementById('noVNC_credentials_dlg');
    if (dlg && dlg.classList.contains('noVNC_open') && !submitted) {
      const userInput = document.getElementById('noVNC_username_input');
      const passInput = document.getElementById('noVNC_password_input');
      const submitBtn = document.getElementById('noVNC_credentials_button');
      if (userInput && passInput && submitBtn) {
        submitted = true;
        console.log('[AutoConnect] ARD authentication required. Injecting ulgen / ulgen123...');
        userInput.value = 'ulgen';
        passInput.value = 'ulgen123';
        setTimeout(() => {
          submitBtn.click();
          console.log('[AutoConnect] Credentials submitted successfully!');
        }, 150);
      }
    } else if (dlg && !dlg.classList.contains('noVNC_open')) {
      submitted = false;
    }
  });
  const dlgEl = document.getElementById('noVNC_credentials_dlg') || document.body;
  observer.observe(dlgEl, { attributes: true, attributeFilter: ['class'] });
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
