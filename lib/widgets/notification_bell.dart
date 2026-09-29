import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/baggage_screen.dart';
import '../screens/notifications_screen.dart';
import '../state/notification_store.dart';

/// Bell with unread badge; opens NotificationsScreen. Key: `notification-bell`.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationStore>().unread;
    return IconButton(
      key: const ValueKey('notification-bell'),
      tooltip: 'Notifications',
      onPressed: () =>
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NotificationsScreen())),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: Icon(unread > 0 ? Icons.notifications_active_outlined : Icons.notifications_outlined),
      ),
    );
  }
}

/// Standard AppBar actions for the 5 tab roots: baggage tracker + bell.
/// Use as `actions: const [AppBarActions()]`.
class AppBarActions extends StatelessWidget {
  const AppBarActions({super.key});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: const ValueKey('baggage-button'),
            tooltip: 'Baggage tracker',
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BaggageScreen())),
            icon: const Icon(Icons.luggage_outlined),
          ),
          const NotificationBell(),
          const SizedBox(width: 4),
        ],
      );
}
