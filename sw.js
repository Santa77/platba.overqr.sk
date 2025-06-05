const CACHE_NAME = 'overqr-v1';
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
    })
  );
});
