import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  GoogleAuthService._();

  // Web OAuth Client ID (client_type: 3) từ Firebase project quan-li-phong.
  static const _serverClientId =
      '744238998639-krci5o2vka5gnjfiagmkdv23ismp461q.apps.googleusercontent.com';

  static Future<void>? _initFuture;

  static Future<void> ensureInitialized() async {
    try {
      await (_initFuture ??= GoogleSignIn.instance.initialize(
        serverClientId: _serverClientId,
      )).timeout(const Duration(seconds: 10));
    } catch (_) {
      _initFuture = null;
      rethrow;
    }
  }

  /// Mở hộp thoại chọn tài khoản Google và đăng nhập Firebase Auth.
  /// Trả về `null` nếu người dùng đóng hộp thoại / hủy đăng nhập.
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      await ensureInitialized();
    } on TimeoutException {
      throw StateError(
        'Không khởi tạo được Google Play Services kịp thời. Vui lòng thử lại.',
      );
    }

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw StateError(
        'Nền tảng này chưa hỗ trợ đăng nhập Google trực tiếp.',
      );
    }

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance
          .authenticate()
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw StateError(
        'Google Play Services phản hồi quá lâu (thường gặp khi dịch vụ Google trên máy ảo bị nghẽn). '
        'Hãy nhấn nút Back để đóng hộp thoại Google rồi bấm đăng nhập lại.',
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
        throw StateError(
          'Cấu hình Google Sign-In chưa đúng (kiểm tra SHA-1 và google-services.json).',
        );
      }
      final detail = e.description?.trim();
      throw StateError(
        detail == null || detail.isEmpty
            ? 'Đăng nhập Google thất bại (${e.code.name}).'
            : 'Đăng nhập Google thất bại: $detail',
      );
    }

    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError(
        'Không lấy được ID Token từ Google. Vui lòng thử lại.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    try {
      return await FirebaseAuth.instance
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw StateError(
        'Kết nối xác thực Firebase quá thời gian chờ. Vui lòng kiểm tra mạng và thử lại.',
      );
    }
  }

  /// Đăng xuất khỏi cả Firebase Auth và phiên Google Sign-In.
  static Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } finally {
      try {
        await ensureInitialized();
        await GoogleSignIn.instance
            .signOut()
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Bỏ qua nếu thiết bị không có Google Play Services hoặc chưa đăng nhập Google.
      }
    }
  }
}
