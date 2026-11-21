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
      ));
    } catch (_) {
      _initFuture = null;
      rethrow;
    }
  }

  /// Mở hộp thoại chọn tài khoản Google và đăng nhập Firebase Auth.
  /// Trả về `null` nếu người dùng đóng hộp thoại / hủy đăng nhập.
  static Future<UserCredential?> signInWithGoogle() async {
    await ensureInitialized();
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw StateError(
        'Nền tảng này chưa hỗ trợ đăng nhập Google trực tiếp.',
      );
    }

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
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

    String? accessToken;
    try {
      final authz = await account.authorizationClient.authorizationForScopes(
        const ['email', 'profile'],
      );
      accessToken = authz?.accessToken;
    } catch (_) {
      // Firebase Auth chỉ cần idToken khi xác thực bằng Google trên Android.
    }

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );
    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  /// Đăng xuất khỏi cả Firebase Auth và phiên Google Sign-In.
  static Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } finally {
      try {
        await ensureInitialized();
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Bỏ qua nếu thiết bị không có Google Play Services hoặc chưa đăng nhập Google.
      }
    }
  }
}
