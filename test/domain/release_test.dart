import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/domain/release.dart';

void main() {
  test('versions compare numerically and ignore v and build numbers', () {
    expect(compareVersions('1.0.10', '1.0.9'), greaterThan(0));
    expect(compareVersions('v1.2.0', '1.2.0+7'), 0);
    expect(compareVersions('0.7.0', '1.0.0'), lessThan(0));
    expect(compareVersions('1.1', '1.0.5'), greaterThan(0));
  });

  test('reads the APK from a GitHub release', () {
    final r = releaseFromGitHub({
      'tag_name': 'v1.0.1',
      'body': 'Fixes',
      'assets': [
        {'name': 'notes.txt', 'browser_download_url': 'https://x/notes.txt'},
        {
          'name': 'milk-tracker-v1.0.1.apk',
          'browser_download_url': 'https://x/a.apk',
        },
      ],
    });
    expect(r?.version, '1.0.1');
    expect(r?.apkUrl, 'https://x/a.apk');
  });

  test('a release without an APK is ignored', () {
    expect(releaseFromGitHub({'tag_name': 'v1.0.1', 'assets': []}), isNull);
  });

  test('only newer releases are offered', () {
    const latest = AppRelease(version: '1.0.1', apkUrl: 'u');
    expect(updateFor('1.0.0', latest), same(latest));
    expect(updateFor('1.0.1', latest), isNull);
    expect(updateFor('1.0.2', latest), isNull);
    expect(updateFor('1.0.0', null), isNull);
  });

  test('picks the APK built for this phone type', () {
    final json = {
      'tag_name': 'v1.0.1',
      'assets': [
        {
          'name': 'milk-tracker-v1.0.1-armeabi-v7a.apk',
          'browser_download_url': 'old',
        },
        {
          'name': 'milk-tracker-v1.0.1-arm64-v8a.apk',
          'browser_download_url': 'new',
        },
      ],
    };
    expect(releaseFromGitHub(json, abi: 'arm64-v8a')?.apkUrl, 'new');
    expect(releaseFromGitHub(json, abi: 'armeabi-v7a')?.apkUrl, 'old');
    expect(releaseFromGitHub(json, abi: 'x86_64')?.apkUrl, 'old');
  });
}
