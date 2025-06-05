const APP_VERSION = '1.0.1';
const CACHE_NAME = `overqr-v${APP_VERSION}`;
const urlsToCache = [
  '/',
  '/index.html',
  '/manifest.json',
  '/logo.svg',
  'https://cdn.jsdelivr.net/npm/qrcode-generator@1.4.4/qrcode.min.js',
  'https://esm.sh/bysquare@latest',
  '/tailwindcss.3.4.16.js',
  'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css'
];

// Inštalácia Service Worker-a
self.addEventListener('install', function(event) {
  // Vykonaj inštaláciu
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(function(cache) {
        console.log('Cache otvorený');
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
  const cacheWhitelist = [CACHE_NAME];
  event.waitUntil(
    caches.keys().then(function(cacheNames) {
      return Promise.all(
        cacheNames.map(function(cacheName) {
          if (cacheWhitelist.indexOf(cacheName) === -1) {
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => {
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
    const response = await fetch('/version.json?nocache=' + new Date().getTime());
    if (response.ok) {
      const data = await response.json();
      if (data.version !== APP_VERSION) {
        // Oznámiť klientovi, že je dostupná nová verzia
        self.clients.matchAll().then(clients => {
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
    }
    return false;
  } catch (error) {
    console.error('Nemôžem skontrolovať aktualizácie:', error);
    return false;
  }
}

// Periodická kontrola aktualizácií
self.addEventListener('message', function(event) {
  if (event.data && event.data.type === 'CHECK_UPDATES') {
    event.waitUntil(checkForUpdates());
  }
});
