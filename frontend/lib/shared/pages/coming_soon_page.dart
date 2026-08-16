import 'package:flutter/material.dart';

import '../widgets/empty_state.dart';

/// Placeholder screen for features not yet implemented in this phase.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const EmptyState(
        icon: Icons.construction_rounded,
        title: 'Segera Hadir',
        message: 'Modul ini sedang dalam pengembangan.',
      ),
    );
  }
}
