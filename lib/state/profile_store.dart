import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/sample_data.dart';
import '../models/passenger.dart';

/// The traveller's own profile (with frequent flyer no.) and saved
/// travellers, persisted under [prefsKey].
class ProfileStore extends ChangeNotifier {
  static const prefsKey = 'indigo_profile_v1';

  ProfileStore({DateTime Function()? clock, Random? random})
      : clock = clock ?? DateTime.now,
        _random = random ?? Random();

  final DateTime Function() clock;
  final Random _random;
  Passenger _me = SampleData.defaultProfile;
  final List<Passenger> _saved = [...SampleData.defaultSavedTravellers];
  bool _loaded = false;
  Future<void> _saving = Future.value();

  Passenger get me => _me;
  String? get frequentFlyerNo => _me.frequentFlyerNo;
  List<Passenger> get savedTravellers => List.unmodifiable(_saved);

  /// [me] followed by saved travellers (for the "pick from saved" chooser).
  List<Passenger> get allTravellers => [_me, ..._saved];
  bool get loaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw != null) {
      try {
        final j = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        _me = Passenger.fromJson(Map<String, dynamic>.from(j['me'] as Map));
        _saved
          ..clear()
          ..addAll((j['savedTravellers'] as List)
              .map((e) => Passenger.fromJson(Map<String, dynamic>.from(e as Map))));
      } catch (e) {
        debugPrint('ProfileStore: corrupt saved data, keeping defaults: $e');
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> flush() => _saving;

  /// null or blank clears it.
  void setFrequentFlyerNo(String? number) {
    final v = number?.trim();
    _me = (v == null || v.isEmpty) ? _me.copyWith(clearFrequentFlyerNo: true) : _me.copyWith(frequentFlyerNo: v);
    _changed();
  }

  /// Adds a saved traveller; an empty id is replaced with a new one. Returns the stored value.
  Passenger addTraveller(Passenger p) {
    var stored = p;
    if (p.id.isEmpty || _saved.any((x) => x.id == p.id)) {
      stored = p.copyWith(id: 'st-${clock().millisecondsSinceEpoch}-${_random.nextInt(1 << 20)}');
    }
    _saved.add(stored);
    _changed();
    return stored;
  }

  /// Replaces the saved traveller with the same id. Returns false if absent.
  bool updateTraveller(Passenger p) {
    final i = _saved.indexWhere((x) => x.id == p.id);
    if (i < 0) return false;
    _saved[i] = p;
    _changed();
    return true;
  }

  void removeTraveller(String id) {
    _saved.removeWhere((x) => x.id == id);
    _changed();
  }

  void _changed() {
    final data = jsonEncode({'me': _me.toJson(), 'savedTravellers': _saved.map((p) => p.toJson()).toList()});
    _saving = _saving.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(prefsKey, data);
      } catch (e) {
        debugPrint('ProfileStore: saving profile failed: $e');
      }
    });
    notifyListeners();
  }
}
