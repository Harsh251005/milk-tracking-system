import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/release.dart';
import '../links.dart';

abstract interface class Updates {
  Future<String> installedVersion();

  /// Newest published release, or null if none / offline.
  Future<AppRelease?> latest();

  /// Downloads [release]'s APK (reporting 0–1 progress) and opens Android's
  /// installer on it. Throws [UpdateException] with a plain message.
  Future<void> downloadAndInstall(
    AppRelease release, {
    required void Function(double progress) onProgress,
  });
}

class UpdateException implements Exception {
  const UpdateException(this.message);

  final String message;

  @override
  String toString() => message;
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

  @override
  Future<void> downloadAndInstall(
    AppRelease release, {
    required void Function(double progress) onProgress,
  }) async {
    // Kept until the next version, so tapping Update again (e.g. after
    // allowing installs) reopens the installer without re-downloading.
    final dir = (await getTemporaryDirectory()).path;
    final file = File('$dir/update-${release.version}.apk');
    if (!await file.exists()) {
      await _download(release, File('${file.path}.part'), onProgress);
      await File('${file.path}.part').rename(file.path);
    }
    onProgress(1);
    // Android asks once to "allow installs from Milk Tracker", then shows
    // its Update screen. Data is kept: same app, same signing key.
    final opened = await OpenFilex.open(
      file.path,
      type: 'application/vnd.android.package-archive',
    );
    if (opened.type != ResultType.done) {
      throw UpdateException("Couldn't open the installer (${opened.message}).");
    }
  }

  Future<void> _download(
    AppRelease release,
    File part,
    void Function(double progress) onProgress,
  ) async {
    final client = http.Client();
    try {
      final res = await client
          .send(http.Request('GET', Uri.parse(release.apkUrl)))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) {
        throw UpdateException(
          "Couldn't download the update (error ${res.statusCode}).",
        );
      }
      final total = res.contentLength ?? 0;
      var received = 0;
      final sink = part.openWrite();
      await for (final chunk in res.stream.timeout(
        const Duration(seconds: 30),
      )) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress(received / total);
      }
      await sink.close();
    } on UpdateException {
      rethrow;
    } on Exception {
      throw const UpdateException(
        'The download stopped. Check the internet and try again.',
      );
    } finally {
      client.close();
    }
  }
}
