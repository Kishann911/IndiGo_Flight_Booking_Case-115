import 'package:flutter/material.dart';

import '../widgets/notification_bell.dart';

/// Phase-1 placeholder. Phase 2 replaces the body (keep the class name and constructor).
class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: const [AppBarActions()],
      ),
      body: const Center(child: Text('Coming in phase 2')),
    );
  }
}
