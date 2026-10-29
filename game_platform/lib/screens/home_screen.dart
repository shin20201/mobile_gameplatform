import 'package:flutter/material.dart';

import '../games/aim_boost/aim_boost_screen.dart';
import '../games/chess/chess_screen.dart';
import '../games/flappy_bird/flappy_bird_screen.dart';
import '../games/game_1024/game_1024_screen.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';
import '../services/ranking_service.dart';
import 'ranking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final Stream<Map<String, int>> _bestScores = RankingService.watchMyBestScores();

  Widget _gameCard(String title, String recordLabel, Widget screen, {String record = '—'}) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFDADADA)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (context) => screen),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                recordLabel,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                record,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gamePage(Map<String, int> best, bool loading, bool failed) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      children: [
        const Text(
          '안녕하세요,',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          '${AuthService.auth.currentUser?.displayName ?? 'Player'}님!',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 28),
        if (failed) const Text('기록을 불러오지 못했습니다. 연결 및 읽기 권한을 확인해 주세요.'),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          mainAxisExtent: 200,
          children: [
            _gameCard('Aim Boost', '최고 점수', const AimBoostScreen(), record: failed ? '조회 실패' : loading ? '…' : best['aim_boost']?.toString() ?? '—'),
            _gameCard('1024', '최고 점수', const Game1024Screen(), record: failed ? '조회 실패' : loading ? '…' : best['game_1024']?.toString() ?? '—'),
            _gameCard('Flappy Bird', '최고 점수', const FlappyBirdScreen(), record: failed ? '조회 실패' : loading ? '…' : best['flappy_bird']?.toString() ?? '—'),
            _gameCard('Chess', '전적', const ChessScreen()),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<Map<String, int>>(
          stream: _bestScores,
          builder: (context, snapshot) {
            final best = snapshot.data ?? <String, int>{};
            final loading = snapshot.connectionState == ConnectionState.waiting;
            return IndexedStack(
              index: _selectedIndex,
              children: [
                _gamePage(best, loading, snapshot.hasError),
                const RankingScreen(),
                ProfileScreen(bestScores: best, loading: loading, loadFailed: snapshot.hasError),
              ],
            );
          },
        ),
      ),
      // 탭 전체 폭을 제한해 화면 중앙에 작게 모읍니다.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Center(
            heightFactor: 1,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 264),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDADADA)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _navButton(0, '게임', Icons.sports_esports_outlined),
                  _navButton(1, '랭킹', Icons.emoji_events_outlined),
                  _navButton(2, 'MY', Icons.person_outline),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navButton(int index, String label, IconData icon) {
    final selected = _selectedIndex == index;
    return Expanded(
      child: Semantics(
        selected: selected,
        child: TextButton(
          onPressed: () => setState(() => _selectedIndex = index),
          style: TextButton.styleFrom(
            foregroundColor: selected ? Colors.black : Colors.grey,
            backgroundColor: selected
                ? const Color(0xFFEAEAEA)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22),
              const SizedBox(height: 3),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
