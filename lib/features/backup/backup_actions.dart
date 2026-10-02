import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/backup.dart';
import '../../state/providers.dart';
import '../../ui/friendly_error.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/section_card.dart';

void _snack(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
        duration: Duration(seconds: error ? 8 : 4),
        content: Text(text),
      ),
    );
}

String _message(Object e) =>
    e is BackupException ? e.message : friendlyError(e).message;

/// Links this account to Google, telling the person how it went.
Future<void> runBackup(BuildContext context, WidgetRef ref) async {
  try {
    final email = await ref.read(backupProvider).backUp();
    if (context.mounted) _snack(context, 'Backed up to $email.');
  } catch (e) {
    if (context.mounted) _snack(context, _message(e), error: true);
  }
}

/// Signs back in to a backed-up account (new or reset phone).
Future<void> runRestore(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(backupProvider).restore();
    final householdId = await ref.read(householdIdProvider.future);
    if (householdId == null && context.mounted) {
      _snack(
        context,
        'No milk log is backed up to that Google account. Set up as new, '
        'or join your family with a code.',
        error: true,
      );
    }
  } catch (e) {
    if (context.mounted) _snack(context, _message(e), error: true);
  }
}

/// On Today, until the account is backed up (or "Not now" for two weeks).
class BackupNudge extends ConsumerStatefulWidget {
  const BackupNudge({super.key});

  @override
  ConsumerState<BackupNudge> createState() => _BackupNudgeState();
}

class _BackupNudgeState extends ConsumerState<BackupNudge> {
  static const _key = 'backup.nudge.hiddenUntil';
  bool _hidden = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final until = DateTime.tryParse(p.getString(_key) ?? '');
      if (mounted) {
        setState(
          () => _hidden = until != null && DateTime.now().isBefore(until),
        );
      }
    });
  }

  Future<void> _notNow() async {
    setState(() => _hidden = true);
    (await SharedPreferences.getInstance()).setString(
      _key,
      DateTime.now().add(const Duration(days: 14)).toIso8601String(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backedUp = ref.watch(backupEmailProvider).value != null;
    if (_hidden || backedUp) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SectionCard(
        color: context.colors.missingSoft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_upload_rounded, color: context.colors.missing),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Keep your milk log safe', style: t.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Back up with your Google account, so you can get it back if '
              'this phone is lost, changed or reset.',
              style: t.bodyLarge,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _notNow,
                    child: const Text('Not now'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                    onPressed: () => runBackup(context, ref),
                    child: const Text('Back up'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
