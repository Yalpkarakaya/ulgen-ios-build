const http = require('http');
const fs = require('fs');
const path = require('path');
const net = require('net');

const WEB_ROOT = process.argv[2] || '/tmp/novnc-ard';
const LISTEN_PORT = parseInt(process.argv[3] || '6080', 10);
const WS_TARGET_PORT = parseInt(process.argv[4] || '6081', 10);

const MIMES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.mjs': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.ico': 'image/x-icon',
  '.wav': 'audio/wav',
  '.json': 'application/json'
};

const server = http.createServer((req, res) => {
  let reqPath = req.url.split('?')[0];
  if (reqPath === '/' || reqPath === '') reqPath = '/ard.html';
  
  const safeSuffix = path.normalize(reqPath).replace(/^(\.\.[\/\\])+/, '');
  const filePath = path.join(WEB_ROOT, safeSuffix);

  fs.stat(filePath, (err, stat) => {
    if (err || !stat.isFile()) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      return res.end('File not found: ' + reqPath);
    }
    const ext = path.extname(filePath).toLowerCase();
    res.writeHead(200, {
      'Content-Type': MIMES[ext] || 'application/octet-stream',
      'Content-Length': stat.size,
      'Cache-Control': 'public, max-age=3600'
    });
    fs.createReadStream(filePath).pipe(res);
  });
});

server.on('upgrade', (req, socket, head) => {
  console.log(`[WS] Upgrading: ${req.url}`);
  const proxySocket = net.connect(WS_TARGET_PORT, '127.0.0.1', () => {
    let headerStr = `${req.method} ${req.url} HTTP/1.1\r\n`;
    for (const [k, v] of Object.entries(req.headers)) {
      headerStr += `${k}: ${v}\r\n`;
    }
    headerStr += '\r\n';
    proxySocket.write(headerStr);
    if (head && head.length > 0) {
      proxySocket.write(head);
    }
    socket.pipe(proxySocket);
    proxySocket.pipe(socket);
  });

  proxySocket.on('error', (err) => {
    console.error('[WS Proxy Error]', err.message);
    socket.destroy();
  });

  socket.on('error', (err) => {
    console.error('[Client Socket Error]', err.message);
    proxySocket.destroy();
  });
});

server.listen(LISTEN_PORT, '127.0.0.1', () => {
  console.log(`Ultra-fast Node server listening on 127.0.0.1:${LISTEN_PORT}, WS proxying to ${WS_TARGET_PORT}`);
});
