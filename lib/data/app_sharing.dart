import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../links.dart';

/// Shares the app itself: the APK installed on this phone, so the other
/// person installs straight from WhatsApp with no browser download.
abstract interface class AppSharing {
  /// Throws [AppShareException] if the app file can't be prepared.
  Future<void> shareApp({required String version});
}

class AppShareException implements Exception {
  const AppShareException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApkAppSharing implements AppSharing {
  static const _channel = MethodChannel('milk_tracker/app');

  @override
  Future<void> shareApp({required String version}) async {
    final File copy;
    try {
      final path = await _channel.invokeMethod<String>('installedApkPath');
      if (path == null) throw const AppShareException('No app file found.');
      // A readable name, in a temp folder the share sheet is allowed to read.
      final dir = await getTemporaryDirectory();
      copy = await File(path).copy('${dir.path}/Milk Tracker $version.apk');
    } on AppShareException {
      rethrow;
    } on Exception catch (e) {
      throw AppShareException("Couldn't prepare the app file ($e).");
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(copy.path, mimeType: 'application/vnd.android.package-archive'),
        ],
        text: shareAppCaption,
      ),
    );
  }
}
