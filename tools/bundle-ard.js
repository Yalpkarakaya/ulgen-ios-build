const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const targetDir = process.argv[2] || '/tmp/novnc-ard';
const ardHtmlPath = path.join(targetDir, 'ard.html');

console.log('Bundling noVNC-ARD for maximum speed and zero network latency...');

let html = fs.readFileSync(ardHtmlPath, 'utf8');

// Find the main module script
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

  // Replace inline script with bundled script in ard.html
  const newHtml = html.replace(scriptMatch[0], '<script type="module" src="app-bundle.js"></script>');
  fs.writeFileSync(ardHtmlPath, newHtml);
  console.log('ard.html updated to use app-bundle.js!');
} catch (e) {
  console.error('esbuild failed:', e.message);
}
