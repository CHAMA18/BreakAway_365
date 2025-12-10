import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AICoachView extends StatelessWidget {
  const AICoachView({super.key, required this.url});

  final String url;

  Future<void> _openExternal() async {
    final uri = Uri.parse(url);
    // Try preferred mode first, then fall back.
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.smart_toy_outlined, size: 52, color: Color(0xFF1F2937)),
          const SizedBox(height: 12),
          const Text(
            'Open Breakaway365 AI Coach',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          const Text(
            'We\'ll launch the AI Coach in your browser.',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openExternal,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B6EF5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open AI Coach'),
          ),
        ],
      ),
    );
  }
}
