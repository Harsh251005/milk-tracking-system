import 'package:flutter_test/flutter_test.dart';
import 'package:milk_tracker/links.dart';

void main() {
  test('share text carries the stable download link', () {
    expect(
      downloadLink,
      endsWith('/releases/latest/download/milk-tracker-arm64-v8a.apk'),
    );
    expect(shareAppText, contains(downloadLink));
    expect(shareAppText, contains(releasesPage));
  });
}
