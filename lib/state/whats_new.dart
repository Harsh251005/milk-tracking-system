import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../changelog.dart';
import 'providers.dart';

/// Notes to show once after an update. Worked out at app start, before the
/// intro runs, so a fresh install is never mistaken for an update.
class WhatsNew extends AsyncNotifier<List<(String, List<String>)>> {
  static const _lastSeenKey = 'whatsNew.lastSeenVersion';

  @override
  Future<List<(String, List<String>)>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await ref.read(installedVersionProvider.future);
    final lastSeen = prefs.getString(_lastSeenKey);
    // Before 1.0.4 nothing recorded the version; an existing user is one who
    // has already been through the intro (stored since 1.0.1).
    final isUpgrade = lastSeen != null
        ? lastSeen != current
        : prefs.getBool('intro.seen') ?? false;
    await prefs.setString(_lastSeenKey, current);
    return whatsNewFor(
      current: current,
      lastSeen: lastSeen,
      isUpgrade: isUpgrade,
    );
  }

  void dismiss() => state = const AsyncData([]);
}

final whatsNewProvider =
    AsyncNotifierProvider<WhatsNew, List<(String, List<String>)>>(WhatsNew.new);
