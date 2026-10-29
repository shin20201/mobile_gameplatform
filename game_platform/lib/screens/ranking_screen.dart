import 'package:flutter/material.dart';
import '../services/ranking_service.dart';
import '../services/auth_service.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  int _selectedGame = 0;
  static const _games = ['AIM', '1024', 'FLAPPY', 'CHESS'];
  static const _gameIds = ['aim_boost', 'game_1024', 'flappy_bird', 'chess'];
  late Stream<List<RankingEntry>> _ranking = RankingService.watchRanking(_gameIds[0]);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          '랭킹',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            _games.length,
            (index) => ChoiceChip(
              label: Text(_games[index]),
              selected: _selectedGame == index,
              showCheckmark: false,
              onSelected: (_) {
                if (_selectedGame == index) return;
                setState(() {
                  _selectedGame = index;
                  if (index != 3) _ranking = RankingService.watchRanking(_gameIds[index]);
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Row(
          children: [
            SizedBox(width: 48, child: Text('순위')),
            Expanded(child: Text('닉네임')),
            Text('점수 / 전적'),
          ],
        ),
        const Divider(height: 28),
        if (_selectedGame == 3)
          const Text('체스 랭킹 준비 중', textAlign: TextAlign.center)
        else
          StreamBuilder<List<RankingEntry>>(
            key: ValueKey(_selectedGame),
            stream: _ranking,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Column(children: [
                  const Text('랭킹을 불러오지 못했습니다. 연결 및 읽기 권한을 확인해 주세요.'),
                  TextButton(onPressed: () => setState(() {
                    _ranking = RankingService.watchRanking(_gameIds[_selectedGame]);
                  }), child: const Text('다시 시도')),
                ]);
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final entries = snapshot.data ?? <RankingEntry>[];
              if (entries.isEmpty) return const Text('아직 저장된 기록이 없습니다.', textAlign: TextAlign.center);
              var rank = 0;
              return Column(children: List.generate(entries.length, (index) {
                final entry = entries[index];
                if (index == 0 || entry.score != entries[index - 1].score) rank = index + 1;
                final isMe = entry.userId == AuthService.auth.currentUser?.uid;
                return Container(
                  color: isMe ? const Color(0xFFEAEAEA) : null,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                  child: Row(children: [
                    SizedBox(width: 44, child: Text('$rank')),
                    Expanded(child: Text('${entry.nickname}${isMe ? ' ' : ''}', overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text('${entry.score}'),
                  ]),
                );
              }));
            },
          ),
      ],
    );
  }
}
