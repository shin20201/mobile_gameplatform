import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final auth = FirebaseAuth.instance;

  static Future<void> login(String email, String password) async {
    await auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  static Future<void> signup(String nickname, String email, String password) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(), password: password,
    );
    final user = credential.user!;
    try {
      await user.updateDisplayName(nickname.trim());
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'nickname': nickname.trim(),
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // 프로필 저장 실패 시 방금 만든 계정을 정리해 재가입할 수 있게 합니다.
      try {
        await user.delete();
      } catch (_) {
        throw Exception('계정은 생성됐지만 프로필 저장에 실패했습니다. 로그인 후 관리자에게 문의해 주세요.');
      } finally {
        await auth.signOut();
      }
      throw Exception('회원정보 저장에 실패했습니다. 네트워크와 Firestore 권한을 확인하고 다시 시도해 주세요.');
    }
  }

  static String errorMessage(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-email' => '올바른 이메일을 입력해 주세요.',
        'email-already-in-use' => '이미 가입된 이메일입니다.',
        'weak-password' => '비밀번호가 너무 약합니다. 더 강한 비밀번호를 사용해 주세요.',
        'invalid-credential' || 'wrong-password' || 'user-not-found' => '이메일 또는 비밀번호가 올바르지 않습니다.',
        'user-disabled' => '사용이 중지된 계정입니다.',
        'network-request-failed' => '인터넷 연결을 확인해 주세요.',
        'too-many-requests' => '요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.',
        'operation-not-allowed' => 'Firebase에서 이메일/비밀번호 로그인을 활성화해 주세요.',
        _ => '인증에 실패했습니다. 다시 시도해 주세요. (${error.code})',
      };
    }
    return error.toString().replaceFirst('Exception: ', '');
  }
}
