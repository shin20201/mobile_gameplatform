import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.bestScores = const {}, this.loading = false, this.loadFailed = false});
  final Map<String, int> bestScores;
  final bool loading;
  final bool loadFailed;

  String _record(String label) {
    if (label == 'CHESS') return '—';
    if (loadFailed) return '조회 실패';
    if (loading) return '…';
    final game = {'AIM': 'aim_boost', '1024': 'game_1024', 'FLAPPY': 'flappy_bird'}[label];
    return bestScores[game]?.toString() ?? '—';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'MY',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 48),
        Center(
          child: Text(
            AuthService.auth.currentUser?.displayName ?? 'Player',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(AuthService.auth.currentUser?.email ?? '', style: const TextStyle(color: Colors.grey)),
        ),
        const SizedBox(height: 32),
        TextButton(
          onPressed: () async {
            try {
              await AuthService.auth.signOut();
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그아웃에 실패했습니다. 다시 시도해 주세요.')));
              }
            }
          },
          child: const Text('로그아웃'),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDADADA)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: ['AIM', '1024', 'FLAPPY', 'CHESS']
                .map(
                  (game) => Expanded(
                    child: Column(
                      children: [
                        Text(game, style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 12),
                        Text(_record(game), style: const TextStyle(fontSize: 20)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          loadFailed ? '기록을 불러오지 못했습니다. 연결 및 읽기 권한을 확인해 주세요.' : '게임별 최고 점수입니다. 기록이 없으면 —로 표시됩니다.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
