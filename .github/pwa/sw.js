// Service worker сайта с рецептами: страницы и картинки, которые уже
// открывались, остаются доступны без интернета.
const CACHE = 'recipes-v3';

self.addEventListener('install', (event) => {
  // Главная страница нужна сразу, чтобы приложение открывалось офлайн.
  event.waitUntil(caches.open(CACHE).then((cache) => cache.add('./')));
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((key) => key !== CACHE).map((key) => caches.delete(key))))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (event) => {
  const { request } = event;
  if (request.method !== 'GET' || new URL(request.url).origin !== self.location.origin) return;

  if (request.mode === 'navigate') {
    // Страницы: сначала сеть, чтобы правки рецептов видны сразу; без сети — из кеша.
    event.respondWith(
      fetch(request)
        .then((response) => {
          if (response.ok) {
            const copy = response.clone();
            caches.open(CACHE).then((cache) => cache.put(request, copy));
          }
          return response;
        })
        .catch(() => caches.match(request).then((cached) => cached || caches.match('./'))),
    );
    return;
  }

  // Стили, скрипты, картинки: отдаём из кеша и тихо обновляем в фоне.
  event.respondWith(
    caches.open(CACHE).then((cache) =>
      cache.match(request).then((cached) => {
        const network = fetch(request)
          .then((response) => {
            if (response.ok) cache.put(request, response.clone());
            return response;
          })
          .catch(() => cached);
        if (cached) {
          event.waitUntil(network);
          return cached;
        }
        return network;
      }),
    ),
  );
});
