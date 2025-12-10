import 'package:flutter/material.dart';

class CoachEmbedView extends StatelessWidget {
  const CoachEmbedView({super.key, required this.url, this.borderRadius = const BorderRadius.all(Radius.circular(12))});

  final String url;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: const Text(
        'Embedding is available in Web preview.\nThis platform shows a placeholder.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF6B7280)),
      ),
    );
  }
}
