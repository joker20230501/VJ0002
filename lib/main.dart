name: Build APK

on: [push, workflow_dispatch]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Java 17
        uses: actions/setup-java@v4
        with:
          distribution: zulu
          java-version: "17"

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: 3.19.6
          channel: stable

      - name: Setup and Build App
        run: |
          rm -rf mobile_app
          flutter create mobile_app --platforms=android --org=vn.vieclambando --project-name=vn_job_map
          cd mobile_app
          sed -i 's/minSdkVersion flutter.minSdkVersion/minSdkVersion 21/g' android/app/build.gradle
          sed -i 's/minSdkVersion = flutter.minSdkVersion/minSdkVersion = 21/g' android/app/build.gradle
          sed -i "s/ext.kotlin_version = .*/ext.kotlin_version = '1.9.22'/g" android/build.gradle || true
          sed -i 's/id "org.jetbrains.kotlin.android" version "[^"]*"/id "org.jetbrains.kotlin.android" version "1.9.22"/g' android/settings.gradle || true
          sed -i 's/<application/<uses-permission android:name="android.permission.INTERNET"\/><uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"\/><application/g' android/app/src/main/AndroidManifest.xml
          flutter pub add flutter_map latlong2 geolocator http intl
          
          if [ -f "../lib/main.dart" ]; then
            cp -f ../lib/main.dart lib/main.dart
          fi

          flutter build apk --release --no-tree-shake-icons
          flutter build appbundle --release --no-tree-shake-icons

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: app-release-apk-install-now
          path: mobile_app/build/app/outputs/flutter-apk/app-release.apk

      - name: Upload AAB
        uses: actions/upload-artifact@v4
        with:
          name: google-play-app-release-aab
          path: mobile_app/build/app/outputs/bundle/release/app-release.aab
