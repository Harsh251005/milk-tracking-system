import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether this phone has seen the first-launch intro.
class IntroSeen extends AsyncNotifier<bool> {
  static const _key = 'intro.seen';

  @override
  Future<bool> build() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? false;

  Future<void> markSeen() async {
    state = const AsyncData(true);
    await (await SharedPreferences.getInstance()).setBool(_key, true);
  }
}

final introSeenProvider = AsyncNotifierProvider<IntroSeen, bool>(IntroSeen.new);
