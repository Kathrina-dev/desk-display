import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeskTimerService extends ChangeNotifier {
  SharedPreferences? _preferences;
  Timer? _ticker;
  int _seconds = 0;
  int _unsavedSeconds = 0;

  int get elapsedSeconds => _seconds;

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    final key = _keyFor(DateTime.now());
    _seconds = _preferences!.getInt(key) ?? 0;
    notifyListeners();
  }

  void start() {
    if (_ticker != null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _seconds++;
      _unsavedSeconds++;
      notifyListeners();
      if (_unsavedSeconds >= 10) unawaited(flush());
    });
  }

  Future<void> pause() async {
    _ticker?.cancel();
    _ticker = null;
    await flush();
  }

  Future<void> flush() async {
    final preferences = _preferences;
    if (preferences == null || _unsavedSeconds == 0) return;
    await preferences.setInt(_keyFor(DateTime.now()), _seconds);
    _unsavedSeconds = 0;
  }

  String _keyFor(DateTime date) =>
      'desk_time_${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}