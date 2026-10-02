import 'dart:convert';
import 'dart:ffi';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../domain/release.dart';
import '../links.dart';

abstract interface class Updates {
  Future<String> installedVersion();

  /// Newest published release, or null if none / offline.
  Future<AppRelease?> latest();
}

class GitHubUpdates implements Updates {
  @override
  Future<String> installedVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  @override
  Future<AppRelease?> latest() async {
    try {
      final res = await http
          .get(
            Uri.parse(latestReleaseApi),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return releaseFromGitHub(
        jsonDecode(res.body) as Map<String, dynamic>,
        abi: _androidAbi(),
      );
    } on Exception {
      // Offline or GitHub unreachable: just don't offer an update now.
      return null;
    }
  }

  /// Android's name for this phone's processor type, matching the APK names
  /// `flutter build apk --split-per-abi` produces.
  static String? _androidAbi() => switch (Abi.current()) {
    Abi.androidArm64 => 'arm64-v8a',
    Abi.androidArm => 'armeabi-v7a',
    Abi.androidX64 => 'x86_64',
    _ => null,
  };
}
