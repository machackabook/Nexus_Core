    self.addEventListener('fetch', event => {
        if (event.request.headers.get('handoff')) {
            event.respondWith(
                caches.match(event.request)
                    .then(response => response || fetch(event.request))
            );
        }
    });
