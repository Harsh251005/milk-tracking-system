import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/updates.dart';
import '../domain/release.dart';
import 'providers.dart';

/// Where an in-app update is: idle, downloading (0–1), or failed (message).
sealed class UpdateState {
  const UpdateState();
}

class UpdateIdle extends UpdateState {
  const UpdateIdle();
}

class UpdateDownloading extends UpdateState {
  const UpdateDownloading(this.progress);

  final double progress;
}

class UpdateFailed extends UpdateState {
  const UpdateFailed(this.message);

  final String message;
}

class UpdateController extends Notifier<UpdateState> {
  @override
  UpdateState build() => const UpdateIdle();

  Future<void> start(AppRelease release) async {
    if (state is UpdateDownloading) return;
    state = const UpdateDownloading(0);
    try {
      await ref
          .read(updatesProvider)
          .downloadAndInstall(
            release,
            onProgress: (p) => state = UpdateDownloading(p),
          );
      state = const UpdateIdle(); // the installer is on screen now
    } on UpdateException catch (e) {
      state = UpdateFailed(e.message);
    }
  }
}

final updateControllerProvider =
    NotifierProvider<UpdateController, UpdateState>(UpdateController.new);
