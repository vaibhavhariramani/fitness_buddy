import 'package:flutter/material.dart';

import 'empty_state.dart';

class ComingSoonPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const ComingSoonPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: icon,
      title: '$title — coming soon',
      message: message,
    );
  }
}
