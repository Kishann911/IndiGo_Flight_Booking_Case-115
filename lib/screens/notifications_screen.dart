import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/formatters.dart';
import '../models/models.dart';
import '../state/notification_store.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/responsive.dart';
import '../widgets/simulated_tag.dart';

/// In-app (simulated push) notifications, newest first.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static IconData iconFor(String kind) => switch (kind) {
        NotificationKind.delay => Icons.schedule,
        NotificationKind.gate => Icons.door_front_door_outlined,
        NotificationKind.boarding => Icons.airline_seat_recline_normal,
        NotificationKind.baggage => Icons.luggage_outlined,
        _ => Icons.confirmation_number_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NotificationStore>();
    final items = store.items;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton.icon(
            key: const ValueKey('mark-all-read'),
            onPressed: store.unread == 0 ? null : store.markAllRead,
            icon: const Icon(Icons.done_all),
            label: const Text('Mark all read'),
          ),
          const SizedBox(width: AppSpace.s),
        ],
      ),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none,
              title: 'No notifications yet',
              message: 'Delays, gate changes, boarding calls and bag scans appear here.',
            )
          : MaxWidthBox(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.m),
                itemCount: items.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpace.s),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: AppSpace.xs),
                        child: SimulatedTag(label: 'simulated push notifications'),
                      ),
                    );
                  }
                  final n = items[i - 1];
                  return Card(
                    color: n.read ? null : theme.colorScheme.secondaryContainer,
                    child: ListTile(
                      key: ValueKey('notification-${n.id}'),
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                        child: Icon(iconFor(n.kind)),
                      ),
                      title: Text(n.title, style: n.read ? null : theme.textTheme.titleSmall),
                      subtitle: Text('${n.body}\n${Fmt.dayMonth(n.at)}, ${Fmt.time(n.at)}'),
                      isThreeLine: true,
                      trailing: n.read ? null : Icon(Icons.circle, size: 10, color: theme.colorScheme.primary),
                      onTap: n.read ? null : () => store.markRead(n.id),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
