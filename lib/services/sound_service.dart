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

  /// Pool so rapid clicks don't cancel each other on web.
  final List<AudioPlayer> _pool = [];
  int _poolIndex = 0;
  bool _muted = false;
  bool _ready = false;
  bool _unlocked = false;
  Future<void>? _initFuture;
  int _lastTickSecond = -1;

  bool get muted => _muted;
  bool get ready => _ready;
  bool get unlocked => _unlocked;

  Future<void> init() {
    return _initFuture ??= _doInit();
  }

  Future<void> _doInit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _muted = prefs.getBool(_muteKey) ?? false;

      // Web needs a user gesture before audio works; we still prep players.
      for (var i = 0; i < 4; i++) {
        final p = AudioPlayer(playerId: 'adventquiz_$i');
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setVolume(1.0);
        if (!kIsWeb) {
          await p.setPlayerMode(PlayerMode.lowLatency);
        }
        _pool.add(p);
      }
      _ready = true;
      notifyListeners();
    } catch (e, st) {
      debugPrint('SoundService.init failed: $e\n$st');
      rethrow;
    }
  }

  Future<void> toggleMute() async {
    await init();
    _muted = !_muted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_muteKey, _muted);
    if (_muted) {
      for (final p in _pool) {
        await p.stop();
      }
    } else {
      // Unmuting is a user gesture — unlock web audio.
      await unlock();
      await play(GameSound.click);
    }
    notifyListeners();
  }

  /// Call from any button tap. Required for Chrome/Safari autoplay policy.
  Future<void> unlock() async {
    if (_unlocked) return;
    await init();
    if (_pool.isEmpty) return;
    try {
      final p = _pool.first;
      await p.setVolume(0.001);
      await p.play(AssetSource(_asset(GameSound.click)));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      await p.stop();
      await p.setVolume(1.0);
      _unlocked = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Audio unlock failed: $e');
    }
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

  double _volumeFor(GameSound sound) {
    return switch (sound) {
      GameSound.click || GameSound.select => 1.0,
      GameSound.tick || GameSound.tickUrgent => 0.7,
      _ => 0.95,
    };
  }

  Future<void> play(GameSound sound) async {
    try {
      await init();
      if (_muted || _pool.isEmpty) return;
      if (!_unlocked) {
        await unlock();
      }
      final player = _pool[_poolIndex % _pool.length];
      _poolIndex++;
      await player.stop();
      await player.setVolume(_volumeFor(sound));
      await player.play(AssetSource(_asset(sound)));
    } catch (e) {
      debugPrint('Sound play failed ($sound): $e');
    }
  }

  /// Fire-and-forget click for UI buttons.
  void tap() {
    unawaited(play(GameSound.click));
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
    unawaited(play(seconds <= 3 ? GameSound.tickUrgent : GameSound.tick));
  }

  void resetTickGate() => _lastTickSecond = -1;

  @override
  void dispose() {
    for (final p in _pool) {
      p.dispose();
    }
    super.dispose();
  }
}

void unawaited(Future<void> future) {
  future.catchError((Object e, StackTrace st) {
    debugPrint('Sound async error: $e\n$st');
  });
}
