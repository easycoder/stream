/*
 * Service worker — Eclecity admin panel.
 *
 * The app is served at the site root (index.html boots admin-main.allspeak),
 * and also at admin.html. The installed app is a shell, not an offline copy
 * of the books: it opens from cache so the window comes up at once, but
 * everything that carries data — the PHP endpoints, data/ — is left to the
 * network, untouched. A cached booking list would be worse than no list.
 *
 * The site's .htaccess says the layout and script files are rebuilt on every
 * deploy, and warns against pairing a new script with an old layout. So the
 * shell is network-first: the cache is a fallback for a dropped connection,
 * never a source for a stale admin-main.allspeak beside a fresh admin.json.
 *
 * Requests arrive with a cache-buster query (`admin.json?cb=...`), so entries
 * are stored under the path alone and matched with ignoreSearch.
 */

const CACHE = 'eclecity-admin-shell-v1';

const SHELL = [
    '/',
    'admin.html',
    'admin.json',
    'admin-main.allspeak',
    'allspeak.js',
    'manifest.json',
    'icons/icon-192.png',
    'icons/icon-512.png',
    'icons/icon-maskable-512.png',
    'icons/apple-touch-icon-180.png'
];

// Which page a navigation is allowed to fall back to, and the cache entry it
// shares. `/admin` is the old address and the server redirects it to `/`.
const APP_PAGE_KEYS = new Map([
    ['/', '/'],
    ['/index.html', '/'],
    ['/admin', '/'],
    ['/admin/', '/'],
    ['/admin.html', '/admin.html']
]);

const absolute = path => new URL(path, self.location).href;
const SHELL_PATHS = new Set(SHELL.map(path => new URL(path, self.location).pathname));

self.addEventListener('install', event => {
    event.waitUntil((async () => {
        const cache = await caches.open(CACHE);
        // allSettled, not all: one file missing after a partial deploy must
        // not leave the app unable to install at all.
        await Promise.allSettled(SHELL.map(async path => {
            const url = absolute(path);
            const response = await fetch(url, { cache: 'reload' });
            if (response.ok) await cache.put(url, response);
        }));
        await self.skipWaiting();
    })());
});

self.addEventListener('activate', event => {
    event.waitUntil((async () => {
        const names = await caches.keys();
        await Promise.all(names.filter(name => name !== CACHE).map(name => caches.delete(name)));
        await self.clients.claim();
    })());
});

const networkFirst = async (request, cacheUrl) => {
    const cache = await caches.open(CACHE);
    try {
        const response = await fetch(request);
        if (response.ok) {
            // Caching is best-effort: a failed write (a redirect, a quota
            // error) must not turn a good network response into a failure.
            try {
                await cache.put(cacheUrl.href, response.clone());
            } catch (ignored) {}
        }
        return response;
    } catch (error) {
        const cached = await cache.match(cacheUrl.href, { ignoreSearch: true });
        if (cached) return cached;
        throw error;
    }
};

self.addEventListener('fetch', event => {
    const request = event.request;
    if (request.method !== 'GET') return;

    const url = new URL(request.url);
    if (url.origin !== self.location.origin) return;

    // Anything that carries data stays live: PHP endpoints, data/, uploads.
    if (url.pathname.endsWith('.php') || url.pathname.startsWith('/data/')) return;

    // Only the admin app is cached. The per-slug stream viewers are
    // deliberately not: a stale viewer is a family looking at the wrong
    // funeral.
    if (request.mode === 'navigate') {
        const key = APP_PAGE_KEYS.get(url.pathname);
        if (key) {
            event.respondWith(networkFirst(request, new URL(key, self.location)));
        }
        return;
    }

    if (SHELL_PATHS.has(url.pathname)) {
        // Key by path: the page asks for `admin.json?cb=<random>` and
        // `allspeak.js?v=<timestamp>`, and the query must not fragment the
        // cache or let a fallback match the wrong entry.
        event.respondWith(networkFirst(request, new URL(url.pathname, self.location)));
    }
});
