import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

class CoachEmbedView extends StatelessWidget {
  const CoachEmbedView({super.key, required this.url, this.borderRadius = const BorderRadius.all(Radius.circular(12))});

  final String url;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final viewType = 'coach-embed-${url.hashCode}-${identityHashCode(this)}';
    // Register a unique view factory per instance to ensure the iframe reloads with URL changes
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = url
        ..style.border = '0'
        ..allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen'
        ..allowFullscreen = true
        ..width = '100%'
        ..height = '100%';
      return iframe;
    });

    return ClipRRect(
      borderRadius: borderRadius,
      child: HtmlElementView(viewType: viewType),
    );
  }
}
