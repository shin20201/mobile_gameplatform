import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('네 게임에 진입한 뒤 홈으로 돌아온다', (tester) async {
    await tester.pumpWidget(const MyApp());

    for (final game in ['Aim Boost', '1024', 'Flappy Bird', 'Chess']) {
      await tester.tap(find.widgetWithText(InkWell, game));
      await tester.pumpAndSettle();

      expect(find.text('$game 게임 준비 중'), findsOneWidget);
      expect(find.widgetWithText(AppBar, game), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Player님!'), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    }
  });
}
