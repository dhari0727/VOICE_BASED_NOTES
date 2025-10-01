import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  static const _keyName = 'encryption_key_v1';
  final _secure = const FlutterSecureStorage();
  final _auth = LocalAuthentication();

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'Authenticate to access secure notes'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }

  Future<enc.Key> _getOrCreateKey() async {
    String? base64Key = await _secure.read(key: _keyName);
    if (base64Key == null) {
      final rng = Random.secure();
      final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
      base64Key = base64Encode(bytes);
      await _secure.write(key: _keyName, value: base64Key);
    }
    return enc.Key(base64.decode(base64Key));
  }

  Future<String> encryptText(String plaintext) async {
    final key = await _getOrCreateKey();
    final iv = enc.IV.fromSecureRandom(12); // GCM recommended IV size
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    final payload = {
      'iv': base64Encode(iv.bytes),
      'ct': encrypted.base64,
      // tag embedded in encrypted for this package
    };
    return base64Encode(utf8.encode(jsonEncode(payload)));
  }

  Future<String> decryptText(String blob) async {
    final key = await _getOrCreateKey();
    final decoded = utf8.decode(base64Decode(blob));
    final map = jsonDecode(decoded) as Map<String, dynamic>;
    final iv = enc.IV(base64Decode(map['iv'] as String));
    final ct = map['ct'] as String;
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final decrypted = encrypter.decrypt(enc.Encrypted.fromBase64(ct), iv: iv);
    return decrypted;
  }
}

