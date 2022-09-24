# local_biometrics_auth

<?code-excerpt path-base="excerpts/packages/local_auth_example"?>

This package provide a means to authenticate a user with biometrics and securely cache sensitive information like password and tokens

On supported devices, this includes authentication with biometrics such as
fingerprint or facial recognition.

|             | Android   | iOS  | Windows     |
|-------------|-----------|------|-------------|
| **Support** | SDK 16+\* | 9.0+ | Windows 10+ |

## Usage


<?code-excerpt "readme_excerpts.dart (CanCheck)"?>
```dart
import 'package:local_biometrics_auth/local_biometrics_auth.dart';
// ···
  final BiometricsAuth auth =  BiometricsAuth.initialise();
  // ···
    final bool canUseBiometrics =  auth.canUseBiometrics;
    final bool isBiometricsSetup =  await auth.isBiometricsSetup;
```

You can authenticate users with the following option:

- BiometricType.face
- BiometricType.fingerprint


### Enrolled Biometrics

`canUseBiometrics` only indicates if the device is capable of using any of the biometrics options.


### Options

The `authenticate()` method authenticates the user and returns true if authentication was successful. 

you can set user authentication details(Password, token) after 

<?code-excerpt "readme_excerpts.dart (AuthAny)"?>
```dart
try {
    await auth.authenticate().then((value) {
      if (value == BiometricsResponse.success) {
        auth.setAuthKey(authKey: AuthKey(key: authData));
      }
    });
  // ···
} catch(e) {
  // ...
}
```


## Securely caching user data

- [Keychain](https://developer.apple.com/library/content/documentation/Security/Conceptual/keychainServConcepts/01introduction/introduction.html#//apple_ref/doc/uid/TP30000897-CH203-TP1) is used for iOS
- AES encryption is used for Android. AES secret key is encrypted with RSA and RSA key is stored in [KeyStore]


to save user details call  `auth.setAuthKey(authKey: AuthKey(key: authData))`


# Retrieving saved data;
- This data can be fetched only after biometric authentication

<?code-excerpt "readme_excerpts.dart (AuthAny)"?>
```dart
    auth.authenticateAndGetAuthKey().then((value) {
      if (value?.key != null) {
        //...
      }
    });
```

# Biometrics Only


To require biometric authentication only, set `biometricsOnly` to true when calling `BiometricsAuth.initialise()`

<?code-excerpt "readme_excerpts.dart (AuthBioOnly)"?>
```dart
    auth = await BiometricsAuth.initialise(biometricsOnly: true);

```

*Note*: `biometricOnly` is not supported on Windows since the Windows implementation's underlying API (Windows Hello) doesn't support selecting the authentication method.


## iOS Integration

Note that this plugin works with both Touch ID and Face ID. However, to use the latter,
you need to also add:

```xml
<key>NSFaceIDUsageDescription</key>
<string>Why is my app authenticating using face id?</string>
```

to your Info.plist file. Failure to do so results in a dialog that tells the user your
app has not been updated to use Face ID.

## Android Integration

### Activity Changes

Note that `local_auth` requires the use of a `FragmentActivity` instead of an
`Activity`. To update your application:

* If you are using `FlutterActivity` directly, change it to
`FlutterFragmentActivity` in your `AndroidManifest.xml`.
* If you are using a custom activity, update your `MainActivity.java`:

    ```java
    import io.flutter.embedding.android.FlutterFragmentActivity;

    public class MainActivity extends FlutterFragmentActivity {
        // ...
    }
    ```

    or MainActivity.kt:

    ```kotlin
    import io.flutter.embedding.android.FlutterFragmentActivity

    class MainActivity: FlutterFragmentActivity() {
        // ...
    }
    ```

    to inherit from `FlutterFragmentActivity`.

### Permissions

Update your project's `AndroidManifest.xml` file to include the
`USE_BIOMETRIC` permissions:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
          package="com.example.app">
  <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<manifest>
```

