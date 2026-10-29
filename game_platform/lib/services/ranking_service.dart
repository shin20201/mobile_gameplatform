import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RankingService {
  static Stream<Map<String, int>> watchMyBestScores() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(<String, int>{});
    return FirebaseFirestore.instance.collection('scores')
        .where('userId', isEqualTo: user.uid).snapshots().map((snapshot) {
      final best = <String, int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final game = data['gameId'];
        final score = data['score'];
        if (game is String && score is num) {
          final value = score.toInt();
          if (!best.containsKey(game) || value > best[game]!) best[game] = value;
        }
      }
      return best;
    });
  }

  // 사용자별 최고 기록 하나만 표시합니다. 동점은 공동 순위입니다.
  static Stream<List<RankingEntry>> watchRanking(String game) {
    return FirebaseFirestore.instance.collection('scores')
        .where('gameId', isEqualTo: game).snapshots().map((snapshot) {
      final best = <String, RankingEntry>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final uid = data['userId'];
        final score = data['score'];
        if (uid is! String || score is! num) continue;
        final entry = RankingEntry(
          userId: uid,
          nickname: data['nickname'] is String ? data['nickname'] as String : 'Player',
          score: score.toInt(),
        );
        if (best[uid] == null || entry.score > best[uid]!.score) best[uid] = entry;
      }
      final entries = best.values.toList();
      entries.sort((a, b) {
        final result = b.score.compareTo(a.score);
        return result != 0 ? result : a.userId.compareTo(b.userId);
      });
      return entries;
    });
  }

  static String newScoreId() =>
      FirebaseFirestore.instance.collection('scores').doc().id;

  static Future<void> saveScore({
    required String game,
    required int score,
    required String scoreId,
    Map<String, int> stats = const {},
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('로그인이 필요합니다.');
    }
    if (score < 0) throw ArgumentError('점수는 0 이상이어야 합니다.');

    // 한 판마다 같은 ID를 사용하여 재시도해도 기록이 중복되지 않습니다.
    await FirebaseFirestore.instance.collection('scores').doc(scoreId).set({
      'userId': user.uid,
      'nickname': user.displayName ?? 'Player',
      'gameId': game,
      'score': score,
      'createdAt': FieldValue.serverTimestamp(),
      'stats': stats,
    }).timeout(const Duration(seconds: 15));
  }
}

class RankingEntry {
  const RankingEntry({required this.userId, required this.nickname, required this.score});
  final String userId;
  final String nickname;
  final int score;
}
