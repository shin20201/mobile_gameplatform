import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../services/ranking_service.dart';

class AimBoostScreen extends StatefulWidget {
  const AimBoostScreen({super.key});

  @override
  State<AimBoostScreen> createState() => _AimBoostScreenState();
}

class _AimBoostScreenState extends State<AimBoostScreen>
    with WidgetsBindingObserver {
  static const _durationMs = 30000;
  static const _targetLifeMs = 1500;
  static const _targetSize = 64.0;
  final _random = Random();
  final _watch = Stopwatch();
  Timer? _timer;
  bool _playing = false;
  bool _finished = false;
  bool _paused = false;
  int _hits = 0;
  int _misses = 0;
  int _expired = 0;
  int _elapsedMs = 0;
  int _targetDeadline = 0;
  Offset _position = const Offset(0.5, 0.5);
  String? _scoreId;
  bool _saving = false;
  bool _saved = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _watch.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _playing && !_paused) {
      _pause();
    }
  }

  void _spawnTarget() {
    _position = Offset(_random.nextDouble(), _random.nextDouble());
    _targetDeadline = _watch.elapsedMilliseconds + _targetLifeMs;
  }

  void _start() {
    _timer?.cancel();
    _watch..reset()..start();
    setState(() {
      _scoreId = RankingService.newScoreId();
      _saving = _saved = false;
      _saveError = null;
      _hits = _misses = _expired = _elapsedMs = 0;
      _playing = true;
      _finished = _paused = false;
      _spawnTarget();
    });
    // 실제 경과 시간은 Stopwatch로 계산해 타이머 지연에 영향을 받지 않습니다.
    _timer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!_paused) setState(_updateTime);
    });
  }

  void _updateTime() {
    _elapsedMs = min(_watch.elapsedMilliseconds, _durationMs);
    if (_elapsedMs >= _durationMs) {
      _watch.stop();
      _timer?.cancel();
      _playing = false;
      _finished = true;
      // 현재 setState가 끝난 뒤 저장 상태를 갱신합니다.
      scheduleMicrotask(() {
        if (mounted && _finished) _saveResult();
      });
    } else if (_elapsedMs >= _targetDeadline) {
      _expired++;
      _spawnTarget();
    }
  }

  void _pause() {
    _watch.stop();
    setState(() => _paused = true);
  }

  Future<void> _saveResult() async {
    if (_saving || _saved || _scoreId == null) return;
    final scoreId = _scoreId!;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await RankingService.saveScore(
        game: 'aim_boost',
        score: _hits * 100,
        scoreId: scoreId,
        stats: {'hits': _hits, 'misses': _misses, 'expired': _expired},
      );
      if (mounted && _scoreId == scoreId) {
        setState(() => _saved = true);
      }
    } catch (_) {
      if (mounted && _scoreId == scoreId) {
        setState(() => _saveError = '저장을 확인하지 못했습니다. 인터넷 연결을 확인하고 다시 시도해 주세요.');
      }
    } finally {
      if (mounted && _scoreId == scoreId) {
        setState(() => _saving = false);
      }
    }
  }

  void _resume() {
    _watch.start();
    setState(() => _paused = false);
  }

  void _tap(Offset tap, Offset targetCenter) {
    if (!_playing || _paused) return;
    setState(() {
      // 만료 직전의 화면을 눌러 새 타겟까지 맞히는 일이 없도록 확인합니다.
      final targetExpired = _watch.elapsedMilliseconds >= _targetDeadline;
      _updateTime();
      if (!_playing) return;
      if (!targetExpired && (tap - targetCenter).distance <= _targetSize / 2) {
        _hits++;
        _spawnTarget();
      } else {
        _misses++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aim Boost'),
        actions: [
          if (_playing && !_paused)
            IconButton(onPressed: _pause, icon: const Icon(Icons.pause), tooltip: '일시정지'),
        ],
      ),
      body: SafeArea(
        child: _playing ? _playArea() : _summary(),
      ),
    );
  }

  Widget _playArea() {
    final seconds = ((_durationMs - _elapsedMs) / 1000).ceil();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('점수 ${_hits * 100}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text('$seconds초', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        LinearProgressIndicator(value: (_durationMs - _elapsedMs) / _durationMs),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text('명중 $_hits  ·  빗나감 $_misses  ·  놓침 $_expired'),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < _targetSize + 16 || constraints.maxHeight < _targetSize + 16) {
                  return const Center(child: Text('게임 영역이 작습니다. 화면을 세로로 돌려 주세요.', textAlign: TextAlign.center));
                }
                final center = Offset(
                  8 + _targetSize / 2 + _position.dx * (constraints.maxWidth - _targetSize - 16),
                  8 + _targetSize / 2 + _position.dy * (constraints.maxHeight - _targetSize - 16),
                );
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) => _tap(details.localPosition, center),
                        child: ColoredBox(
                          color: const Color(0xFFF1F1F1),
                          child: Stack(children: [
                            Positioned(
                              left: center.dx - _targetSize / 2,
                              top: center.dy - _targetSize / 2,
                              child: Semantics(
                                label: '타겟',
                                child: Container(
                                  width: _targetSize, height: _targetSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(color: Colors.black87, width: 5),
                                  ),
                                  child: Center(child: Container(
                                    width: 24, height: 24,
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black87),
                                  )),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                      if (_paused)
                        ColoredBox(
                          color: Colors.white,
                          child: Center(child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('일시정지', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 20),
                              ElevatedButton(onPressed: _resume, child: const Text('계속하기')),
                            ],
                          )),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _summary() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_finished ? '게임 종료' : 'Aim Boost', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            if (_finished) ...[
              Text('${_hits * 100}점', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Text('명중한 타겟: $_hits개\n빗나간 터치: $_misses회\n놓친 타겟: $_expired개', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, height: 1.8)),
              const SizedBox(height: 20),
              if (_saving) const Text('기록 저장 중…'),
              if (_saved) const Text('기록이 저장되었습니다.'),
              if (_saveError != null) ...[
                Text(_saveError!, textAlign: TextAlign.center),
                TextButton(
                  onPressed: _saving ? null : _saveResult,
                  child: const Text('저장 다시 시도'),
                ),
              ],
            ] else
              const Text(
                '30초 동안 타겟을 빠르게 터치하세요!\n\n명중하면 100점\n타겟은 한 번에 하나씩 등장\n명중하거나 1.5초가 지나면 새 타겟 등장\n빗나가거나 놓쳐도 점수 차감 없음',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.8),
              ),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: _start, child: Text(_finished ? '다시 시작' : '게임 시작')),
            if (_finished)
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('홈으로')),
          ],
        ),
      ),
    );
  }
}
