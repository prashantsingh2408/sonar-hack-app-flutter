import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// Maps Android/iOS [PlatformException]s from [GoogleSignIn] into readable text.
/// `sign_in_failed` with null message is common when the OAuth Android client or SHA-1 is missing.
String formatGoogleSignInPlatformError(PlatformException e) {
  final code = e.code;
  final msg = e.message;
  final detail = e.details;
  final tail = StringBuffer();
  if (msg != null && msg.trim().isNotEmpty) {
    tail.write(msg.trim());
  }
  if (detail != null && '$detail'.trim().isNotEmpty) {
    if (tail.isNotEmpty) tail.write(' ');
    tail.write('$detail'.trim());
  }

  if (code == 'sign_in_failed' ||
      code == 'SIGN_IN_FAILED' ||
      code == 'sign_in_required') {
    final intro =
        'Google Sign-In failed${tail.isNotEmpty ? ': $tail' : ''}. '
        'On Android this often means the app\'s signing keys are not registered in '
        'Google Cloud Console for OAuth (Android client for package '
        '`com.example.hacklens` + SHA-1). Run `cd android && ./gradlew signingReport` '
        'and add the SHA-1 for the build you install (debug vs release). '
        'Also build with `--dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id>` '
        'so the backend can verify ID tokens.';
    return intro;
  }

  return tail.isNotEmpty ? '${e.code}: $tail' : '${e.code}: ${e.message ?? 'unknown error'}';
}

class AuthUser {
  AuthUser({required this.userId, required this.email, this.name, this.imageUrl});

  final String userId;
  final String email;
  final String? name;
  final String? imageUrl;
}

class AuthState extends ChangeNotifier {
  AuthState() {
    const id = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    _google = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: id.trim().isEmpty ? null : id.trim(),
    );
  }

  late final GoogleSignIn _google;

  static const _kToken = 'hacklens_mobile_access_token';
  static const _kEmail = 'hacklens_mobile_email';
  static const _kName = 'hacklens_mobile_name';
  static const _kImage = 'hacklens_mobile_image';
  static const _kUserId = 'hacklens_mobile_user_id';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  String? accessToken;
  AuthUser? user;

  bool get isSignedIn => accessToken != null && accessToken!.isNotEmpty && user != null;

  Future<void> restoreSession() async {
    final token = await _secure.read(key: _kToken);
    final email = await _secure.read(key: _kEmail);
    final name = await _secure.read(key: _kName);
    final image = await _secure.read(key: _kImage);
    final uid = await _secure.read(key: _kUserId);
    if (token != null &&
        token.isNotEmpty &&
        email != null &&
        email.isNotEmpty &&
        uid != null &&
        uid.isNotEmpty) {
      accessToken = token;
      user = AuthUser(userId: uid, email: email, name: name, imageUrl: image);
    }
    notifyListeners();
  }

  Future<void> signInWithGoogle(String apiOrigin) async {
    final origin = apiOrigin.replaceAll(RegExp(r'/$'), '');
    GoogleSignInAccount? account;
    try {
      account = await _google.signIn();
    } on PlatformException catch (e) {
      throw StateError(formatGoogleSignInPlatformError(e));
    }
    if (account == null) return;

    GoogleSignInAuthentication auth;
    try {
      auth = await account.authentication;
    } on PlatformException catch (e) {
      throw StateError(formatGoogleSignInPlatformError(e));
    }
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError(
        'Google did not return an ID token. Set GOOGLE_SERVER_CLIENT_ID (web OAuth client) '
        'via --dart-define so the token validates against hacklens.vercel.app.',
      );
    }

    final uri = Uri.parse('$origin/api/mobile/verify-google');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      var detail = res.body;
      try {
        final j = jsonDecode(res.body);
        if (j is Map<String, dynamic>) {
          final err = j['error'];
          final hint = j['hint'];
          if (err != null) {
            detail = err.toString();
            if (hint != null) detail = '$detail ($hint)';
          }
        }
      } catch (_) {}
      throw StateError('verify-google failed (${res.statusCode}): $detail');
    }

    final json = jsonDecode(res.body);
    if (json is! Map<String, dynamic>) throw StateError('Invalid verify response');
    if (json['ok'] != true) throw StateError(json['error']?.toString() ?? 'verify failed');

    final token = json['accessToken'] as String?;
    final u = json['user'];
    if (token == null || u is! Map<String, dynamic>) throw StateError('Missing token or user');

    final email = u['email'] as String? ?? '';
    final uid = u['userId'] as String? ?? '';
    if (email.isEmpty || uid.isEmpty) throw StateError('Invalid user payload');

    accessToken = token;
    user = AuthUser(
      userId: uid,
      email: email,
      name: u['name'] as String?,
      imageUrl: u['image'] as String?,
    );

    await _secure.write(key: _kToken, value: token);
    await _secure.write(key: _kEmail, value: email);
    await _secure.write(key: _kUserId, value: uid);
    await _secure.write(key: _kName, value: user!.name ?? '');
    await _secure.write(key: _kImage, value: user!.imageUrl ?? '');

    notifyListeners();
  }

  Future<void> signOut() async {
    accessToken = null;
    user = null;
    await _secure.delete(key: _kToken);
    await _secure.delete(key: _kEmail);
    await _secure.delete(key: _kName);
    await _secure.delete(key: _kImage);
    await _secure.delete(key: _kUserId);
    try {
      await _google.signOut();
    } catch (_) {}
    notifyListeners();
  }
}
