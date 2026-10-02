import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens WhatsApp with [text] ready to send to [phone] (`91XXXXXXXXXX`).
/// The person still presses send. Without a number, opens the share sheet.
/// Returns false if nothing could be opened.
Future<bool> sendToMilkman({
  required String? phone,
  required String text,
}) async {
  if (phone == null) {
    await SharePlus.instance.share(ShareParams(text: text));
    return true;
  }
  final uri = Uri.https('wa.me', '/$phone', {'text': text});
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
