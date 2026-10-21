const http = require('http');
const fs = require('fs');
const path = require('path');
const net = require('net');
const WebSocket = require('ws');

const WEB_ROOT = process.argv[2] || '/tmp/novnc-ard';
const LISTEN_PORT = parseInt(process.argv[3] || '6080', 10);
const TCP_TARGET_PORT = parseInt(process.argv[4] || '5900', 10);

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

const wss = new WebSocket.Server({
  noServer: true,
  handleProtocols: (protocols, req) => {
    return 'binary';
  }
});

wss.on('connection', (ws, req) => {
  console.log(`[WS] Client connected from ${req.socket.remoteAddress}, bridging to TCP 127.0.0.1:${TCP_TARGET_PORT}...`);
  
  const tcpSocket = net.connect(TCP_TARGET_PORT, '127.0.0.1', () => {
    console.log(`[WS] TCP bridge established to port ${TCP_TARGET_PORT}`);
  });

  tcpSocket.on('data', (data) => {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(data, { binary: true });
    }
  });

  ws.on('message', (message) => {
    if (tcpSocket.writable) {
      tcpSocket.write(message);
    }
  });

  tcpSocket.on('error', (err) => {
    console.error(`[TCP Error] ${err.message}`);
    if (ws.readyState === WebSocket.OPEN) ws.close();
  });

  ws.on('error', (err) => {
    console.error(`[WS Error] ${err.message}`);
    tcpSocket.destroy();
  });

  tcpSocket.on('close', () => {
    console.log('[TCP] Socket closed');
    if (ws.readyState === WebSocket.OPEN) ws.close();
  });

  ws.on('close', () => {
    console.log('[WS] Client disconnected');
    tcpSocket.destroy();
  });
});

server.on('upgrade', (req, socket, head) => {
  console.log(`[HTTP Upgrade] ${req.method} ${req.url}`);
  wss.handleUpgrade(req, socket, head, (ws) => {
    wss.emit('connection', ws, req);
  });
});

server.listen(LISTEN_PORT, '127.0.0.1', () => {
  console.log(`Integrated HTTP + WebSocket-to-TCP server running on 127.0.0.1:${LISTEN_PORT} -> TCP :${TCP_TARGET_PORT}`);
});
