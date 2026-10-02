import 'package:firebase_core/firebase_core.dart';

/// Plain-words message for an error, keeping the technical detail visible
/// underneath so it can be reported.
({String message, String detail}) friendlyError(Object error) {
  final code = error is FirebaseException ? error.code : null;
  final message = switch (code) {
    'network-request-failed' || 'unavailable' =>
      'No internet connection. Connect to Wi-Fi or mobile data and try again.',
    'permission-denied' =>
      "This phone isn't allowed to open this household's data.",
    'operator-not-allowed' || 'admin-restricted-operation' =>
      'Sign-in is switched off for this app. Ask Harsh to check Firebase.',
    _ => 'Something went wrong.',
  };
  final detail = error is FirebaseException
      ? '${error.plugin}/${error.code}: ${error.message ?? ''}'
      : '$error';
  return (message: message, detail: detail);
}
