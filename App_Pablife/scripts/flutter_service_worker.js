// Substitui o service worker do Flutter (offline-first), que servia a versão
// antiga do app em cache até a visita seguinte. O build usa --pwa-strategy=none,
// então nada novo é registrado; este arquivo só existe para os navegadores que
// já tinham o worker antigo: ele apaga os caches, se desregistra e recarrega a
// página, que passa a vir direto do servidor.
self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(
      keys.filter((key) => key.startsWith('flutter-')).map((key) => caches.delete(key)),
    );
    await self.registration.unregister();
    const windows = await self.clients.matchAll({ type: 'window' });
    for (const client of windows) client.navigate(client.url);
  })());
});
