const APP_VERSION = '1.1.4';
const CACHE_NAME = `leqr-v${APP_VERSION}`;
const urlsToCache = [
  '/',
  '/index.html',
  '/manifest.json',
  '/logo.svg',
  'https://cdn.jsdelivr.net/npm/qrcode-generator@1.4.4/qrcode.min.js',
  'https://esm.sh/bysquare@3.2.0',
  '/tailwindcss.3.4.16.js',
  'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css'
];

// Inštalácia Service Worker-a
self.addEventListener('install', function(event) {
  // Vykonaj inštaláciu
  console.log(`Inštalujem nový Service Worker verzie ${APP_VERSION}`);
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(function(cache) {
        console.log(`Cache ${CACHE_NAME} otvorený`);
        return cache.addAll(urlsToCache);
      })
  );
});

// Cache a network stratégia
self.addEventListener('fetch', function(event) {
  // Preskočenie cachevania pre non-HTTP/HTTPS URL (ako chrome-extension://)
  const url = new URL(event.request.url);
  if (url.protocol !== 'http:' && url.protocol !== 'https:') {
    return; // Nepokúšaj sa cachovať non-HTTP URL
  }

  // Always try network-first for critical update files to avoid being stuck on old HTML/SW
  const pathname = url.pathname;
  const isIndex = pathname.endsWith('/index.html') || pathname === '/index.html' || pathname === '/';
  const isVersionJson = pathname.endsWith('/version.json') || pathname === '/version.json';
  if (isIndex || isVersionJson) {
    event.respondWith(
      fetch(event.request)
        .then((response) => {
          if (!response || response.status !== 200) {
            return response;
          }

          // Do not cache version.json - we want it always fresh
          if (isVersionJson) {
            return response;
          }

          const responseToCache = response.clone();
          caches.open(CACHE_NAME).then((cache) => {
            try {
              cache.put(event.request, responseToCache);
            } catch (e) {
              console.error('Zlyhanie pri cachovaní:', e);
            }
          });
          return response;
        })
        .catch(() => {
          return caches.match(event.request);
        })
    );
    return;
  }
  
  event.respondWith(
    caches.match(event.request)
      .then(function(response) {
        // Cache hit - vráť response
        if (response) {
          return response;
        }

        return fetch(event.request).then(
          function(response) {
            // Skontroluj či response je validný
            if(!response || response.status !== 200 || response.type !== 'basic') {
              return response;
            }

            // Klonovanie response, pretože je stream a použitý len raz
            var responseToCache = response.clone();

            caches.open(CACHE_NAME)
              .then(function(cache) {
                try {
                  cache.put(event.request, responseToCache);
                } catch (e) {
                  console.error('Zlyhanie pri cachovaní:', e);
                }
              });

            return response;
          }
        );
      })
    );
});

// Aktivovanie nového Service Worker-a
self.addEventListener('activate', function(event) {
  // Vymazanie starých cache
  const cacheAllowlist = [CACHE_NAME];
  
  console.log(`Aktivujem nový Service Worker verzie ${APP_VERSION}`);
  
  event.waitUntil(
    Promise.all([
      // Vymaž staré cache
      caches.keys().then(function(cacheNames) {
        return Promise.all(
          cacheNames.map(function(cacheName) {
            if (cacheAllowlist.indexOf(cacheName) === -1) {
              console.log('Vymazávam starý cache:', cacheName);
              return caches.delete(cacheName);
            }
          })
        );
      }),
      // Prevzi kontrolu okamžite
      self.clients.claim()
    ]).then(() => {
      // Oznámiť verziu klientom
      return self.clients.matchAll().then(clients => {
        clients.forEach(client => {
          client.postMessage({
            type: 'APP_VERSION',
            version: APP_VERSION
          });
        });
      });
    })
  );
});

// Funkcia na kontrolu aktualizácií
async function checkForUpdates() {
  // Stiahnite verziu z version.json súboru na serveri
  try {
    console.log('[SW] checkForUpdates: fetching /version.json', { currentSwVersion: APP_VERSION });
    const response = await fetch('/version.json?nocache=' + new Date().getTime());
    if (response.ok) {
      const data = await response.json();
      console.log('[SW] checkForUpdates: version.json loaded', { version: data && data.version });
      if (data.version !== APP_VERSION) {
        console.log('[SW] checkForUpdates: UPDATE_AVAILABLE', { current: APP_VERSION, available: data.version });
        // Oznámiť klientovi, že je dostupná nová verzia
        self.clients.matchAll().then(clients => {
          console.log('[SW] checkForUpdates: notifying clients', { count: clients.length });
          clients.forEach(client => {
            client.postMessage({
              type: 'UPDATE_AVAILABLE',
              currentVersion: APP_VERSION,
              newVersion: data.version
            });
          });
        });
        return true;
      }
      console.log('[SW] checkForUpdates: no update available', { current: APP_VERSION });
    }
    return false;
  } catch (error) {
    console.error('Nemôžem skontrolovať aktualizácie:', error);
    return false;
  }
}

// Sledovanie správ a handle 'SKIP_WAITING'
self.addEventListener('message', function(event) {
  if (event.data && event.data.type) {
    console.log('[SW] message received', {
      type: event.data.type,
      fromClientId: event.source && event.source.id ? event.source.id : null,
      swVersion: APP_VERSION
    });
  }

  // Periodická kontrola aktualizácií
  if (event.data && event.data.type === 'CHECK_UPDATES') {
    event.waitUntil(checkForUpdates());
  }
  
  // Prinúť service workera k okamžitej aktivácii
  if (event.data && event.data.type === 'SKIP_WAITING') {
    console.log('[SW] SKIP_WAITING received -> calling self.skipWaiting()', { swVersion: APP_VERSION });
    event.waitUntil(self.skipWaiting());
  }
});





