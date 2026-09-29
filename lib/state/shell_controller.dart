import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

enum ShellTab { book, trips, checkIn, status, profile }

/// Selected HomeShell tab, plus one-shot hand-offs between tabs.
class ShellController extends ChangeNotifier {
  ShellTab _tab = ShellTab.book;
  String? _checkInPnr;

  ShellTab get tab => _tab;

  /// PNR handed to the Check-in tab (e.g. from the confirmation screen).
  /// CheckInScreen reads it with [takeCheckInPnr].
  String? get pendingCheckInPnr => _checkInPnr;

  void select(ShellTab tab, {String? checkInPnr}) {
    _tab = tab;
    if (checkInPnr != null) _checkInPnr = checkInPnr;
    notifyListeners();
  }

  /// Returns and clears the pending PNR (no notify).
  String? takeCheckInPnr() {
    final p = _checkInPnr;
    _checkInPnr = null;
    return p;
  }

  /// Pops back to HomeShell and switches to [tab].
  static void goTo(BuildContext context, ShellTab tab, {String? checkInPnr}) {
    context.read<ShellController>().select(tab, checkInPnr: checkInPnr);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }
}
