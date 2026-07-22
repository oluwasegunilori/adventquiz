import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/visibility.dart';

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

/// Background jazz beds — soft lounge vs brighter celebration.
enum MusicBed {
  none,
  lounge,
  celebration,
}

class SoundService extends ChangeNotifier {
  SoundService();

  static const _muteKey = 'adventquiz_muted';

  /// Pool so rapid clicks don't cancel each other on web.
  final List<AudioPlayer> _pool = [];
  AudioPlayer? _music;
  MusicBed _bed = MusicBed.none;
  int _poolIndex = 0;
  bool _muted = false;
  bool _ready = false;
  bool _unlocked = false;
  bool _pageVisible = true;
  bool _musicWasPlaying = false;
  Future<void>? _initFuture;
  int _lastTickSecond = -1;
  StreamSubscription<bool>? _visibilitySub;

  bool get muted => _muted;
  bool get ready => _ready;
  bool get unlocked => _unlocked;
  MusicBed get bed => _bed;
  bool get pageVisible => _pageVisible;

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
      _music = AudioPlayer(playerId: 'adventquiz_music');
      await _music!.setReleaseMode(ReleaseMode.loop);
      await _music!.setVolume(0.28);
      _visibilitySub = watchPageVisibility().listen((visible) {
        if (visible) {
          unawaited(resumeFromBackground());
        } else {
          unawaited(pauseForBackground());
        }
      });
      _ready = true;
      notifyListeners();
    } catch (e, st) {
      debugPrint('SoundService.init failed: $e\n$st');
      rethrow;
    }
  }

  /// Pause SFX + music when the tab is hidden or the app is backgrounded.
  Future<void> pauseForBackground() async {
    if (!_pageVisible) return;
    _pageVisible = false;
    _musicWasPlaying =
        _music?.state == PlayerState.playing && _bed != MusicBed.none;
    try {
      for (final p in _pool) {
        await p.stop();
      }
      await _music?.pause();
    } catch (e) {
      debugPrint('Audio pause failed: $e');
      try {
        await _music?.stop();
      } catch (_) {}
    }
    notifyListeners();
  }

  /// Resume the music bed when returning to the tab/app.
  Future<void> resumeFromBackground() async {
    if (_pageVisible) return;
    _pageVisible = true;
    notifyListeners();
    if (_muted || !_unlocked) return;
    if (_musicWasPlaying && _bed != MusicBed.none) {
      try {
        final music = _music;
        if (music != null && music.state == PlayerState.paused) {
          await music.resume();
        } else {
          await _restartBed();
        }
      } catch (e) {
        debugPrint('Audio resume failed: $e');
        await _restartBed();
      }
    }
    _musicWasPlaying = false;
  }

  /// Flutter app lifecycle (mobile + web when supported).
  void handleAppLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(resumeFromBackground());
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(pauseForBackground());
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
      await _music?.stop();
      _musicWasPlaying = false;
    } else {
      // Unmuting is a user gesture — unlock web audio.
      await unlock();
      await play(GameSound.click);
      if (_pageVisible) await _restartBed();
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
      if (_pageVisible) await _restartBed();
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

  String? _musicAsset(MusicBed bed) {
    return switch (bed) {
      MusicBed.none => null,
      MusicBed.lounge => 'sounds/jazz_lounge.mp3',
      MusicBed.celebration => 'sounds/jazz_celebration.mp3',
    };
  }

  double _musicVolume(MusicBed bed) {
    return switch (bed) {
      MusicBed.none => 0,
      MusicBed.lounge => 0.26,
      MusicBed.celebration => 0.34,
    };
  }

  double _volumeFor(GameSound sound) {
    return switch (sound) {
      GameSound.click || GameSound.select => 1.0,
      GameSound.tick || GameSound.tickUrgent => 0.7,
      _ => 0.95,
    };
  }

  /// Soft jazz bed. Paused during questions so ticks stay clear.
  Future<void> setMusic(MusicBed bed) async {
    await init();
    if (_bed == bed) {
      if (bed != MusicBed.none &&
          !_muted &&
          _unlocked &&
          _pageVisible) {
        final state = _music?.state;
        if (state != PlayerState.playing) {
          await _restartBed();
        }
      }
      return;
    }
    _bed = bed;
    notifyListeners();
    if (_muted || bed == MusicBed.none) {
      await _music?.stop();
      _musicWasPlaying = false;
      return;
    }
    if (!_unlocked || !_pageVisible) return;
    await _restartBed();
  }

  Future<void> _restartBed() async {
    final bed = _bed;
    final asset = _musicAsset(bed);
    final music = _music;
    if (asset == null ||
        music == null ||
        _muted ||
        !_unlocked ||
        !_pageVisible) {
      await music?.stop();
      return;
    }
    try {
      await music.stop();
      await music.setReleaseMode(ReleaseMode.loop);
      await music.setVolume(_musicVolume(bed));
      await music.play(AssetSource(asset));
    } catch (e) {
      debugPrint('Music bed failed ($bed): $e');
    }
  }

  Future<void> play(GameSound sound) async {
    try {
      await init();
      if (_muted || !_pageVisible || _pool.isEmpty) return;
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
    if (_muted || !_ready || !_pageVisible) return;
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
    _visibilitySub?.cancel();
    for (final p in _pool) {
      p.dispose();
    }
    _music?.dispose();
    super.dispose();
  }
}

void unawaited(Future<void> future) {
  future.catchError((Object e, StackTrace st) {
    debugPrint('Sound async error: $e\n$st');
  });
}
