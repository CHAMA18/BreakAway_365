// Web implementation: embeds the AI Coach as an iframe.
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui; // Provides platformViewRegistry on web
import 'dart:async';
import '../widgets/shimmer_skeleton.dart';

class AICoachView extends StatefulWidget {
  const AICoachView({super.key, required this.url});

  final String url;

  @override
  State<AICoachView> createState() => _AICoachViewState();
}

class _AICoachViewState extends State<AICoachView> {
  late final String _viewType;
  static final Set<String> _registered = <String>{};
  bool _isLoading = true;
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    // Unique view type per URL to avoid collisions.
    _viewType = 'breakaway-aicoach-iframe-${widget.url.hashCode}';

    if (!_registered.contains(_viewType)) {
      try {
        ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
          final element = html.IFrameElement()
            ..src = widget.url
            ..style.border = '0'
            ..allow = 'clipboard-read; clipboard-write; microphone; camera; display-capture;'
            ..width = '100%'
            ..height = '100%';
          return element;
        });
        _registered.add(_viewType);
      } catch (_) {
        // ignore: avoid_print
        // print('View factory for $_viewType already registered.');
      }
    }

    // Show shimmer for 2.5 seconds while iframe loads
    _loadingTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: _ResponsiveFramePadding(
        child: Stack(
          children: [
            const _IFrameContainer(),
            if (_isLoading)
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: _isLoading ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: const _AICoachShimmer(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResponsiveFramePadding extends StatelessWidget {
  const _ResponsiveFramePadding({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double pad = constraints.maxWidth > 1180 ? 24 : 12;
        return Padding(
          padding: EdgeInsets.fromLTRB(pad, 16, pad, 16),
          child: child,
        );
      },
    );
  }
}

class _IFrameContainer extends StatelessWidget {
  const _IFrameContainer();

  @override
  Widget build(BuildContext context) {
    // Fill remaining space
    return SizedBox.expand(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: HtmlElementView(viewType: (context.findAncestorStateOfType<_AICoachViewState>())!._viewType),
      ),
    );
  }
}

class _AICoachShimmer extends StatelessWidget {
  const _AICoachShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          // Header shimmer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              children: [
                ShimmerContainer(
                  width: 40,
                  height: 40,
                  borderRadius: 20,
                  baseColor: Colors.grey.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerContainer(
                        width: 150,
                        height: 18,
                        borderRadius: 6,
                        baseColor: Colors.grey.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 8),
                      ShimmerContainer(
                        width: 100,
                        height: 14,
                        borderRadius: 6,
                        baseColor: Colors.grey.withValues(alpha: 0.15),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Chat messages shimmer
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _MessageShimmer(isUser: false),
                const SizedBox(height: 16),
                _MessageShimmer(isUser: true),
                const SizedBox(height: 16),
                _MessageShimmer(isUser: false),
              ],
            ),
          ),
          // Input box shimmer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ShimmerContainer(
                    height: 50,
                    borderRadius: 25,
                    baseColor: Colors.grey.withValues(alpha: 0.15),
                  ),
                ),
                const SizedBox(width: 12),
                ShimmerContainer(
                  width: 50,
                  height: 50,
                  borderRadius: 25,
                  baseColor: Colors.grey.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageShimmer extends StatelessWidget {
  const _MessageShimmer({required this.isUser});

  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          ShimmerContainer(
            width: 32,
            height: 32,
            borderRadius: 16,
            baseColor: Colors.grey.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                ShimmerContainer(
                  width: isUser ? 300 : 400,
                  height: 80,
                  borderRadius: 12,
                  baseColor: isUser 
                      ? Colors.blue.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.15),
                ),
              ],
            ),
          ),
        ),
        if (isUser) ...[
          const SizedBox(width: 12),
          ShimmerContainer(
            width: 32,
            height: 32,
            borderRadius: 16,
            baseColor: Colors.grey.withValues(alpha: 0.2),
          ),
        ],
      ],
    );
  }
}
