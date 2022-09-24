library local_biometrics_auth;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricsAuth {
  BiometricsAuth._init(
      {String username = 'default_user',
      bool biometricsOnly = true,
      String localizedReason = "Authenticate to continue",
      String preferenceKeyPrefix = ''})
      : _username = username,
        _biometricsOnly = biometricsOnly,
        _localizedReason = localizedReason,
        _preferenceKeyPrefix = preferenceKeyPrefix;

  final String? _username;
  final bool _biometricsOnly;
  final String? _preferenceKeyPrefix;
  final String? _localizedReason;

  bool _canUseBiometrics = false;
  bool _isBiometricsSetup = false;
  bool _initialised = false;

  bool get canUseBiometrics => _canUseBiometrics;
  bool get isBiometricsSetup => _isBiometricsSetup;
  bool get initialised => _initialised;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  final _iosOptions = const IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device);
  final _androidOptions = const AndroidOptions(resetOnError: true);

  Future<void> refresh() async {
    return init();
  }

  static Future<BiometricsAuth> initialise(
      {String username = 'default_user',
      bool biometricsOnly = true,
      String localizedReason = "Authenticate to continue",
      String preferenceKeyPrefix = ''}) async {
    final d = BiometricsAuth._init(
        username: username,
        biometricsOnly: biometricsOnly,
        localizedReason: localizedReason,
        preferenceKeyPrefix: preferenceKeyPrefix);
    await d.init();
    return d;
  }

  Future<void> init() async {
    try {
      _canUseBiometrics = await _supportBiometrics;

      final biometricsAuthKey = await _getAuthKey;

      _isBiometricsSetup = _canUseBiometrics && biometricsAuthKey != null;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    _initialised = true;
  }

  Future<bool> get _supportBiometrics async {
    try {
      //Check if device support biometrics
      final canCheckBiometrics = await _localAuthentication.canCheckBiometrics;

      final isBiometricSupported =
          await _localAuthentication.isDeviceSupported();

      return canCheckBiometrics && isBiometricSupported;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return false;
    }
  }

  Future<AuthKey?> authenticateAndGetAuthKey({String? reason}) async {
    try {
      final didAuthenticate = await _localAuthentication.authenticate(
        localizedReason: reason ?? _localizedReason!,
        options: AuthenticationOptions(biometricOnly: _biometricsOnly),
      );
      if (didAuthenticate) {
        return AuthKey(key: await _getAuthKey);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return null;
    }
  }

  Future<BiometricsResponse> authenticate({
    String? reason,
  }) async {
    try {
      final didAuthenticate = await _localAuthentication.authenticate(
        localizedReason: reason ?? _localizedReason!,
        options: AuthenticationOptions(biometricOnly: _biometricsOnly),
      );
      if (didAuthenticate) {
        return BiometricsResponse.success;
      }

      return BiometricsResponse.failed;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return BiometricsResponse.failed;
    }
  }

  Future<bool> setAuthKey({required AuthKey authKey}) async {
    try {
      await _secureStorage.write(
          key: '$_username-${StorageKeys.usernameKey}',
          iOptions: _iosOptions,
          aOptions: _androidOptions,
          value: authKey.key);
      unawaited(refresh());
      return true;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return false;
    }
  }

  Future<bool> clear() async {
    try {
      await _secureStorage.delete(
        key: '$_username-${StorageKeys.usernameKey}',
        iOptions: _iosOptions,
        aOptions: _androidOptions,
      );

      unawaited(refresh());
      return true;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return false;
    }
  }

  Future<String?> get _getAuthKey async {
    try {
      return (await _secureStorage.read(
          key: '$_username-${StorageKeys.usernameKey}',
          iOptions: _iosOptions,
          aOptions: _androidOptions));
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      clear();
      return null;
    }
  }
}

class AuthKey {
  AuthKey({this.key});
  final String? key;
}

class StorageKeys {
  static const String enableBiometricsKey = 'enable_biometrics_key';
  static const String usernameKey = 'username_key';
}

enum BiometricsResponse { success, failed }

///TODO
///Parameters(String username, bool biometricsOnly)
///1. Implement Basic flow
///2. Make the class a Singleton
///3. Declare _refresh function but works locally
///4. Declare a refresh Function that works publically
///5. Encrypting password
