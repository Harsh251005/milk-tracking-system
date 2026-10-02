import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/changelog.dart';

void main() {
  test('nothing on a fresh install', () {
    expect(
      whatsNewFor(current: '1.0.4', lastSeen: null, isUpgrade: false),
      isEmpty,
    );
  });

  test('upgrading from before version tracking shows the current notes', () {
    final notes = whatsNewFor(
      current: '1.0.4',
      lastSeen: null,
      isUpgrade: true,
    );
    expect(notes.map((n) => n.$1), ['1.0.4']);
  });

  test('skipped versions are all shown, newest first', () {
    final notes = whatsNewFor(
      current: '1.0.4',
      lastSeen: '1.0.2',
      isUpgrade: true,
    );
    expect(notes.map((n) => n.$1), ['1.0.4']); // only 1.0.4 has notes so far
  });

  test('no notes when already on this version', () {
    expect(
      whatsNewFor(current: '1.0.4', lastSeen: '1.0.4', isUpgrade: false),
      isEmpty,
    );
  });

  test('every changelog entry has notes', () {
    for (final e in changelog.entries) {
      expect(e.value, isNotEmpty, reason: e.key);
    }
  });
}
