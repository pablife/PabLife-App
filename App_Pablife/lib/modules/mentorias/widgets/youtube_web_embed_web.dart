import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

final Set<String> _registeredViewTypes = {};

Widget buildYoutubeWebEmbed(String videoId) {
  final viewType = 'youtube-embed-$videoId';
  if (_registeredViewTypes.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final iframe = web.HTMLIFrameElement()
        ..src =
            'https://www.youtube.com/embed/$videoId?autoplay=1&rel=0&playsinline=1'
        ..allow = 'autoplay; encrypted-media; picture-in-picture; fullscreen'
        ..allowFullscreen = true;
      iframe.style
        ..border = 'none'
        ..width = '100%'
        ..height = '100%';
      return iframe;
    });
  }
  return HtmlElementView(viewType: viewType);
}
