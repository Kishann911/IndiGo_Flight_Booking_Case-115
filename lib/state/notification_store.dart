import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';

/// In-app notification inbox (the simulated "push" channel).
/// Newest first; persisted under [prefsKey].
class NotificationStore extends ChangeNotifier {
  static const prefsKey = 'indigo_notifications_v1';
  static const maxItems = 100;

  NotificationStore({DateTime Function()? clock, Random? random})
      : clock = clock ?? DateTime.now,
        _random = random ?? Random();

  final DateTime Function() clock;
  final Random _random;
  final List<AppNotification> _items = [];
  final StreamController<AppNotification> _incoming = StreamController.broadcast();
  Future<void> _saving = Future.value();
  bool _loaded = false;

  /// Newest first.
  List<AppNotification> get items => List.unmodifiable(_items);
  int get unread => _items.where((n) => !n.read).length;
  bool get loaded => _loaded;

  /// Emits each notification as it is added (drives the SnackBar "push").
  Stream<AppNotification> get incoming => _incoming.stream;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    _items.clear();
    if (raw != null) {
      try {
        _items.addAll((jsonDecode(raw) as List)
            .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e as Map))));
      } catch (_) {
        // Corrupt data: start empty.
      }
    }
    _loaded = true;
    notifyListeners();
  }

  void add(AppNotification n) {
    _items.insert(0, n);
    if (_items.length > maxItems) _items.removeRange(maxItems, _items.length);
    _save();
    notifyListeners();
    if (!_incoming.isClosed) _incoming.add(n);
  }

  /// Creates, adds and returns a notification stamped with [clock].
  AppNotification push({required String title, required String body, required String kind}) {
    final n = AppNotification(
      id: 'n-${clock().microsecondsSinceEpoch}-${_random.nextInt(1 << 30)}',
      title: title,
      body: body,
      at: clock(),
      kind: kind,
    );
    add(n);
    return n;
  }

  void markRead(String id) {
    final i = _items.indexWhere((n) => n.id == id);
    if (i < 0 || _items[i].read) return;
    _items[i] = _items[i].copyWith(read: true);
    _save();
    notifyListeners();
  }

  void markAllRead() {
    if (unread == 0) return;
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(read: true);
    }
    _save();
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _save();
    notifyListeners();
  }

  /// Completes when all pending writes are done.
  Future<void> flush() => _saving;

  void _save() {
    final data = jsonEncode(_items.map((n) => n.toJson()).toList());
    _saving = _saving.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, data);
    });
  }

  @override
  void dispose() {
    _incoming.close();
    super.dispose();
  }
}
