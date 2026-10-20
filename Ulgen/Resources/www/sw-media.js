// Service Worker — IndexedDB Media Proxy
// Intercepts requests to /media/<mediaId> and serves them directly from IndexedDB

const CACHE_NAME = 'takip-media-cache-v1';

self.addEventListener('install', (event) => {
    self.skipWaiting();
});

self.addEventListener('activate', (event) => {
    event.waitUntil(
        caches.keys().then(names =>
            Promise.all(
                names.filter(name => name !== CACHE_NAME).map(name => caches.delete(name))
            )
        ).then(() => self.clients.claim())
    );
});

// Helper function to read a file from IndexedDB
function getFileFromIDB(mediaId) {
    return new Promise((resolve, reject) => {
        const request = indexedDB.open('TakipMediaDB', 1);
        request.onerror = (e) => reject(e);
        request.onsuccess = (e) => {
            const db = e.target.result;
            try {
                const tx = db.transaction('mediaFiles', 'readonly');
                const store = tx.objectStore('mediaFiles');
                const getReq = store.get(mediaId);
                getReq.onsuccess = () => {
                    resolve(getReq.result);
                };
                getReq.onerror = (err) => reject(err);
            } catch (err) {
                reject(err);
            }
        };
    });
}

// Fetch: Intercept /media/ requests and serve from IndexedDB
self.addEventListener('fetch', (event) => {
    const url = new URL(event.request.url);

    if (url.pathname.startsWith('/media/')) {
        const mediaId = decodeURIComponent(url.pathname.substring(7)); // remove '/media/'
        
        event.respondWith(
            getFileFromIDB(mediaId).then((record) => {
                if (record && record.data) {
                    let contentType = 'application/octet-stream';
                    
                    // Simple content-type guessing from IDB record metadata if present, or defaults
                    if (record.type) {
                        contentType = record.type;
                    } else if (mediaId.startsWith('thumb_')) {
                        contentType = 'image/jpeg';
                    }
                    
                    return new Response(record.data, {
                        headers: { 
                            'Content-Type': contentType,
                            'Cache-Control': 'public, max-age=31536000'
                        }
                    });
                }
                return new Response('Not Found', { status: 404 });
            }).catch((err) => {
                console.error('[SW IDB Fetch Error]', err);
                return new Response('Error loading from IndexedDB', { status: 500 });
            })
        );
    }
});
