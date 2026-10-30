// O youtube_player_flutter depende de WebView nativa e não toca na web;
// lá usamos o iframe oficial do YouTube.
export 'youtube_web_embed_stub.dart'
    if (dart.library.js_interop) 'youtube_web_embed_web.dart';
