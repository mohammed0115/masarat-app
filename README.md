# مسارات — تطبيق ولي الأمر والمعلم (iOS / Android)

The app is a Flutter shell around the MASARAT web portals. The screens come from the server, so a portal change
reaches the app without a new store release:

- Login: `https://marhaba-edu.com/login`. After sign-in the server sends each account to its own portal
  (`masarat.portal_router`): guardian → `/masarat_portal`, teacher → `/teacher-portal`.
- Pages of the same server open in the app. Other links, `tel:`, `mailto:` and WhatsApp open in the phone's apps.
- Native extras: splash, app icon, pull to refresh, Android back button, an Arabic offline screen with retry, camera
  and photos for file fields, and printing.
- User agent ends with `MasaratApp/1.0`, so the server can tell the app from a browser.

## Icon

«مسارات» = paths: three roads rise and meet at a gold goal (the middle, gold road is the student's own path),
in the login page navy and cream. It is drawn by `tool/icon_gen_test.dart` with Flutter's canvas:

    flutter test tool/icon_gen_test.dart && dart run flutter_launcher_icons && dart run flutter_native_splash:create

Preview: `docs/icon_preview.png` (Android circle mask, iOS rounded square).

## Build

Toolchain on this machine: Flutter in `~/sdk/flutter`, Android SDK in `~/sdk/android`, JDK 21 in `~/sdk/jdk-21`
(`flutter config --jdk-dir`); the system Java 25 is a runtime without `javac`. `flutter_inappwebview` is on
6.2.0-beta.3 because 6.1.5 does not build with Android Gradle Plugin 9.

The release APK is signed with the debug key: fine for trying on phones, not for Google Play (needs an upload key).

    export PATH=$HOME/sdk/flutter/bin:$PATH
    flutter test && flutter analyze
    flutter build apk --release          # Android (needs the Android SDK)
    flutter build appbundle --release    # Google Play
    flutter build ipa --release          # iOS: needs a Mac with Xcode and an Apple developer account

Another server (e.g. a local bench seen from the Android emulator):

    flutter run --dart-define=MASARAT_URL=http://10.0.2.2:8000

IDs: Android `com.marhabaedu.masarat`, iOS `com.marhabaedu.masarat`. Icons and splash are generated from
`assets/icon/*.png` (`dart run flutter_launcher_icons`, `dart run flutter_native_splash:create`).
