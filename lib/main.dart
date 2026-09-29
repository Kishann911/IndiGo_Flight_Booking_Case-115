import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/app_notification.dart';
import 'screens/home_shell.dart';
import 'screens/notifications_screen.dart';
import 'state/app_services.dart';
import 'state/shell_controller.dart';
import 'theme.dart';

export 'state/app_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await AppServices.create();
  // Periodic timers start only here, never in tests.
  services.flightStatus.start();
  runApp(IndigoApp(services: services));
}

/// Root widget. Tests build it with `AppServices.create(clock: ...)` and do
/// not call `flightStatus.start()`.
class IndigoApp extends StatefulWidget {
  const IndigoApp({super.key, required this.services, this.showPushBanners = true});

  final AppServices services;

  /// Show a SnackBar ("simulated push") for each new notification.
  final bool showPushBanners;

  @override
  State<IndigoApp> createState() => _IndigoAppState();
}

class _IndigoAppState extends State<IndigoApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final _shell = ShellController();
  StreamSubscription<AppNotification>? _sub;

  @override
  void initState() {
    super.initState();
    if (widget.showPushBanners) {
      _sub = widget.services.notifications.incoming.listen(_showPush);
    }
  }

  static IconData iconFor(String kind) => switch (kind) {
        NotificationKind.delay => Icons.schedule,
        NotificationKind.gate => Icons.door_front_door_outlined,
        NotificationKind.boarding => Icons.airline_seat_recline_normal,
        NotificationKind.baggage => Icons.luggage_outlined,
        _ => Icons.confirmation_number_outlined,
      };

  void _showPush(AppNotification n) {
    final messenger = _messengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        key: const ValueKey('push-snackbar'),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Icon(iconFor(n.kind), color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('${n.title}\n${n.body}', maxLines: 3, overflow: TextOverflow.ellipsis)),
          ],
        ),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _navigatorKey.currentState
              ?.push(MaterialPageRoute<void>(builder: (_) => const NotificationsScreen())),
        ),
      ));
  }

  @override
  void dispose() {
    _sub?.cancel();
    _shell.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.services;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: s.notifications),
        ChangeNotifierProvider.value(value: s.bookings),
        ChangeNotifierProvider.value(value: s.profile),
        ChangeNotifierProvider.value(value: s.flightStatus),
        ChangeNotifierProvider.value(value: s.baggage),
        ChangeNotifierProvider.value(value: _shell),
      ],
      child: MaterialApp(
        title: 'IndiGo Flight Booking — Case 115',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: _messengerKey,
        home: const HomeShell(),
      ),
    );
  }
}
