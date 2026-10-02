import 'dart:async';

import 'package:milk_tracker/data/account_repository.dart';
import 'package:milk_tracker/data/app_sharing.dart';
import 'package:milk_tracker/data/backup.dart';
import 'package:milk_tracker/data/reminders.dart';
import 'package:milk_tracker/data/updates.dart';
import 'package:milk_tracker/domain/release.dart';
import 'package:milk_tracker/domain/reminder.dart';
import 'package:milk_tracker/domain/invite.dart';
import 'package:milk_tracker/domain/models.dart';

class FakeAccountRepository implements AccountRepository {
  FakeAccountRepository({this.invites = const {}});

  /// Codes the fake "server" knows about.
  final Map<String, Invite> invites;

  ({String name, Product product, String? milkmanName, String? phone})? created;
  ({Invite invite, String name})? joined;

  @override
  Stream<String?> watchHouseholdId() => Stream.value(null);

  @override
  Future<String> createHousehold({
    required String memberName,
    required Product product,
    String? milkmanName,
    String? milkmanPhone,
  }) async {
    created = (
      name: memberName,
      product: product,
      milkmanName: milkmanName,
      phone: milkmanPhone,
    );
    return 'h1';
  }

  @override
  Future<Invite?> findInvite(String code) async => invites[code];

  @override
  Future<void> joinHousehold({
    required Invite invite,
    required String memberName,
  }) async {
    joined = (invite: invite, name: memberName);
  }
}

class FakeReminders implements Reminders {
  FakeReminders({this.allowed = true, bool enabled = false})
    : settings = ReminderSettings(enabled: enabled);

  /// What the phone answers when asked for notification permission.
  final bool allowed;
  ReminderSettings settings;
  bool asked = false;
  List<DateTime> scheduled = const [];

  @override
  Future<ReminderSettings> load() async => settings;

  @override
  Future<void> save(ReminderSettings s) async => settings = s;

  @override
  Future<bool> requestPermission() async => allowed;

  @override
  Future<bool?> requestPermissionOnce() async {
    if (asked) return null;
    asked = true;
    return allowed;
  }

  @override
  Future<void> schedule(List<DateTime> times) async => scheduled = times;
}

class FakeBackup implements Backup {
  FakeBackup({String? email, this.fail}) : _current = email;

  /// When set, backUp/restore throw this message.
  final String? fail;
  final _email = StreamController<String?>.broadcast();
  String? _current;
  int restores = 0;

  @override
  Stream<String?> watchEmail() async* {
    yield _current;
    yield* _email.stream;
  }

  @override
  Future<String> backUp() async {
    if (fail != null) throw BackupException(fail!);
    _current = 'mom@gmail.com';
    _email.add(_current);
    return _current!;
  }

  @override
  Future<void> restore() async {
    if (fail != null) throw BackupException(fail!);
    restores++;
  }
}

class FakeUpdates implements Updates {
  FakeUpdates({this.installed = '1.0.0', this.published});

  final String installed;
  final AppRelease? published;

  @override
  Future<String> installedVersion() async => installed;

  @override
  Future<AppRelease?> latest() async => published;

  /// When set, downloadAndInstall fails with this message.
  String? failWith;
  int installs = 0;

  @override
  Future<void> downloadAndInstall(
    AppRelease release, {
    required void Function(double progress) onProgress,
  }) async {
    onProgress(0.5);
    if (failWith != null) throw UpdateException(failWith!);
    installs++;
  }
}

class FakeAppSharing implements AppSharing {
  final shared = <String>[];

  @override
  Future<void> shareApp({required String version}) async => shared.add(version);
}
