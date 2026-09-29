import 'package:flutter/material.dart';

import '../widgets/notification_bell.dart';

/// Phase-1 placeholder. Phase 2 replaces the body (keep the class name and constructor).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: const [AppBarActions()],
      ),
      body: const Center(child: Text('Coming in phase 2')),
    );
  }
}
