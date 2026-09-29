import 'package:flutter/material.dart';

import '../widgets/notification_bell.dart';

/// Phase-1 placeholder. Phase 2 replaces the body (keep the class name and constructor).
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a flight'),
        actions: const [AppBarActions()],
      ),
      body: const Center(child: Text('Coming in phase 2')),
    );
  }
}
