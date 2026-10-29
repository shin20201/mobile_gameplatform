import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:mobile/firebase_options.dart';
import 'package:mobile/main.dart' show MyApp;

// Android에서 실행하는 연결 진단 (기본은 읽기 전용):
// flutter run -d emulator-5554 -t tool/firebase_check.dart
// 임시 문서 쓰기/읽기/삭제도 검사: --dart-define=CHECK_WRITE=true
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 20));
    debugPrint('FIREBASE_CHECK INIT OK project=${app.options.projectId}');
    for (final name in ['users', 'scores', 'chessRooms']) {
      try {
        final result = await FirebaseFirestore.instance
            .collection(name)
            .limit(1)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 20));
        debugPrint(
          'FIREBASE_CHECK READ $name OK '
          'sampleCount=${result.docs.length} cache=${result.metadata.isFromCache}',
        );
      } on FirebaseException catch (error) {
        debugPrint('FIREBASE_CHECK READ $name FAIL code=${error.code}');
      } catch (error) {
        debugPrint('FIREBASE_CHECK READ $name FAIL type=${error.runtimeType}');
      }
    }
    if (const bool.fromEnvironment('CHECK_WRITE')) {
      final probe = FirebaseFirestore.instance
          .collection('_connectionChecks')
          .doc();
      try {
        await probe
            .set({'test': true, 'createdAt': FieldValue.serverTimestamp()})
            .timeout(const Duration(seconds: 20));
        debugPrint('FIREBASE_CHECK WRITE OK');
        final result = await probe
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 20));
        if (result.data()?['test'] != true ||
            result.data()?['createdAt'] is! Timestamp) {
          throw StateError('Stored values do not match');
        }
        debugPrint(
          'FIREBASE_CHECK VERIFY OK cache=${result.metadata.isFromCache}',
        );
      } catch (error) {
        debugPrint('FIREBASE_CHECK WRITE/VERIFY FAIL $error');
      } finally {
        try {
          await probe.delete().timeout(const Duration(seconds: 20));
          final result = await probe
              .get(const GetOptions(source: Source.server))
              .timeout(const Duration(seconds: 20));
          debugPrint('FIREBASE_CHECK CLEANUP ${result.exists ? 'FAIL' : 'OK'}');
        } catch (error) {
          debugPrint('FIREBASE_CHECK CLEANUP FAIL path=${probe.path} $error');
        }
      }
    }
    debugPrint('FIREBASE_CHECK DONE');
  } catch (error) {
    debugPrint('FIREBASE_CHECK INIT FAIL $error');
  }
  runApp(const MyApp());
}
