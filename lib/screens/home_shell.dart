import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/shell_controller.dart';
import '../widgets/responsive.dart';
import 'checkin_screen.dart';
import 'flight_status_screen.dart';
import 'my_trips_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

/// App shell: 5 tabs. NavigationBar on phone, NavigationRail at ≥ 900 px.
/// Tab roots keep their state (IndexedStack); flows push MaterialPageRoutes.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  static const _destinations = [
    (ShellTab.book, Icons.flight_takeoff_outlined, Icons.flight_takeoff, 'Book'),
    (ShellTab.trips, Icons.luggage_outlined, Icons.luggage, 'My Trips'),
    (ShellTab.checkIn, Icons.how_to_reg_outlined, Icons.how_to_reg, 'Check-in'),
    (ShellTab.status, Icons.radar_outlined, Icons.radar, 'Flight Status'),
    (ShellTab.profile, Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellController>();
    final index = shell.tab.index;
    void onSelect(int i) => shell.select(ShellTab.values[i]);

    const body = [SearchScreen(), MyTripsScreen(), CheckInScreen(), FlightStatusScreen(), ProfileScreen()];
    final stack = IndexedStack(index: index, children: body);

    if (Breakpoints.isRail(context)) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: index,
                onDestinationSelected: onSelect,
                labelType: NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    child: const Icon(Icons.flight),
                  ),
                ),
                destinations: [
                  for (final d in _destinations)
                    NavigationRailDestination(icon: Icon(d.$2), selectedIcon: Icon(d.$3), label: Text(d.$4)),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: stack),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: stack,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onSelect,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(icon: Icon(d.$2), selectedIcon: Icon(d.$3), label: d.$4),
        ],
      ),
    );
  }
}
