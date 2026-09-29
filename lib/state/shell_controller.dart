import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

enum ShellTab { book, trips, checkIn, status, profile }

/// Selected HomeShell tab, plus one-shot hand-offs between tabs.
class ShellController extends ChangeNotifier {
  ShellTab _tab = ShellTab.book;
  String? _checkInPnr;
  String? _checkInLastName;

  ShellTab get tab => _tab;

  /// PNR handed to the Check-in tab (e.g. from the confirmation screen).
  /// CheckInScreen reads it with [takeCheckInPnr].
  String? get pendingCheckInPnr => _checkInPnr;

  void select(ShellTab tab, {String? checkInPnr, String? checkInLastName}) {
    _tab = tab;
    if (checkInPnr != null) _checkInPnr = checkInPnr;
    if (checkInLastName != null) _checkInLastName = checkInLastName;
    notifyListeners();
  }

  /// Returns and clears the pending PNR (no notify).
  String? takeCheckInPnr() {
    final p = _checkInPnr;
    _checkInPnr = null;
    return p;
  }

  /// Returns and clears the last name handed over with the PNR (no notify).
  String? takeCheckInLastName() {
    final n = _checkInLastName;
    _checkInLastName = null;
    return n;
  }

  /// Pops back to HomeShell and switches to [tab].
  static void goTo(BuildContext context, ShellTab tab, {String? checkInPnr, String? checkInLastName}) {
    context.read<ShellController>().select(tab, checkInPnr: checkInPnr, checkInLastName: checkInLastName);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }
}
