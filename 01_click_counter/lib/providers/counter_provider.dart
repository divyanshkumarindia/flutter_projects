import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_entry.dart';

class CounterProvider extends ChangeNotifier {
  static const _kCounter = 'counter_value';
  static const _kSavedList = 'counter_saved_list';

  int _count = 0;
  List<SavedEntry> _saved = [];
  DateTime? _lastUpdated;
  bool _shouldAnimate = false;

  int get count => _count;
  List<SavedEntry> get saved => List.unmodifiable(_saved);
  DateTime? get lastUpdated => _lastUpdated;

  CounterProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _count = prefs.getInt(_kCounter) ?? 0;
    final list = prefs.getStringList(_kSavedList) ?? [];
    _saved = list.map((s) {
      try {
        final m = json.decode(s) as Map<String, dynamic>;
        return SavedEntry.fromJson(m);
      } catch (_) {
        // legacy: stored as plain int
        final v = int.tryParse(s) ?? 0;
        return SavedEntry(value: v, savedAt: DateTime.now());
      }
    }).toList();
    final lastMillis = prefs.getInt('counter_last_updated');
    _lastUpdated = lastMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(lastMillis)
        : null;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCounter, _count);
    await prefs.setStringList(
      _kSavedList,
      _saved.map((e) => json.encode(e.toJson())).toList(),
    );
    await prefs.setInt(
      'counter_last_updated',
      _lastUpdated?.millisecondsSinceEpoch ?? 0,
    );
  }

  // Maintain previous API: allow an `animate` named parameter and expose
  // a shouldAnimate flag that widgets can read and clear.
  void increment({bool animate = true}) {
    _count++;
    _lastUpdated = DateTime.now().toUtc();
    _shouldAnimate = animate;
    notifyListeners();
    _saveToPrefs();
  }

  void decrement({bool animate = false}) {
    if (_count <= 0) return;
    _count--;
    _lastUpdated = DateTime.now().toUtc();
    _shouldAnimate = animate;
    notifyListeners();
    _saveToPrefs();
  }

  // synchronous reset to match previous usage
  void reset() {
    _count = 0;
    _lastUpdated = DateTime.now().toUtc();
    notifyListeners();
    _saveToPrefs();
  }

  Future<void> saveCurrent({String? label}) async {
    final entry = SavedEntry(
      value: _count,
      savedAt: DateTime.now().toUtc(),
      label: label,
    );
    _saved.insert(0, entry);
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> deleteSavedAt(int index) async {
    if (index < 0 || index >= _saved.length) return;
    _saved.removeAt(index);
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> clearSaved() async {
    _saved.clear();
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> restoreSavedAt(int index) async {
    if (index < 0 || index >= _saved.length) return;
    _count = _saved[index].value;
    _lastUpdated = DateTime.now().toUtc();
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> renameSavedAt(int index, String? newLabel) async {
    if (index < 0 || index >= _saved.length) return;
    _saved[index] = _saved[index].copyWith(label: newLabel);
    notifyListeners();
    await _saveToPrefs();
  }

  bool get shouldAnimate => _shouldAnimate;

  void clearAnimateFlag() {
    _shouldAnimate = false;
  }
}
