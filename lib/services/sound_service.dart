import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameSound {
  click,
  join,
  start,
  tick,
  tickUrgent,
  select,
  correct,
  wrong,
  reveal,
  leaderboard,
  podium,
}

class SoundService extends ChangeNotifier {
  SoundService();

  static const _muteKey = 'adventquiz_muted';
  final AudioPlayer _player = AudioPlayer();
  bool _muted = false;
  bool _ready = false;
  int _lastTickSecond = -1;

  bool get muted => _muted;
  bool get ready => _ready;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _muted = prefs.getBool(_muteKey) ?? false;
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(0.85);
    _ready = true;
    notifyListeners();
  }

  Future<void> toggleMute() async {
    _muted = !_muted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_muteKey, _muted);
    if (_muted) {
      await _player.stop();
    }
    notifyListeners();
  }

  String _asset(GameSound sound) {
    return switch (sound) {
      GameSound.click => 'sounds/click.wav',
      GameSound.join => 'sounds/join.wav',
      GameSound.start => 'sounds/start.wav',
      GameSound.tick => 'sounds/tick.wav',
      GameSound.tickUrgent => 'sounds/tick_urgent.wav',
      GameSound.select => 'sounds/select.wav',
      GameSound.correct => 'sounds/correct.wav',
      GameSound.wrong => 'sounds/wrong.wav',
      GameSound.reveal => 'sounds/reveal.wav',
      GameSound.leaderboard => 'sounds/leaderboard.wav',
      GameSound.podium => 'sounds/podium.wav',
    };
  }

  Future<void> play(GameSound sound) async {
    if (_muted || !_ready) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(_asset(sound)));
    } catch (e) {
      debugPrint('Sound play failed: $e');
    }
  }

  void maybeTick(int remainingMs) {
    if (_muted || !_ready) return;
    final seconds = (remainingMs / 1000).ceil();
    if (seconds <= 0 || seconds > 5) {
      if (seconds > 5) _lastTickSecond = -1;
      return;
    }
    if (seconds == _lastTickSecond) return;
    _lastTickSecond = seconds;
    play(seconds <= 3 ? GameSound.tickUrgent : GameSound.tick);
  }

  void resetTickGate() => _lastTickSecond = -1;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
