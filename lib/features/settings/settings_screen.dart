import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/format.dart';
import '../../domain/models.dart';
import '../../domain/phone.dart';
import '../../domain/reminder.dart';
import '../../state/providers.dart';
import '../../state/reminder_providers.dart';
import '../../ui/friendly_error.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/forms.dart';
import '../../ui/widgets/section_card.dart';
import '../../ui/widgets/status_views.dart';
import '../backup/backup_actions.dart';
import '../family/invite_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.read(milkRepositoryProvider).currentUid;
    return AsyncView(
      value: ref.watch(householdProvider),
      builder: (h) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
          const SectionLabel('Milk'),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final p in h.products) ...[
                  _Row(
                    icon: Icons.water_drop_rounded,
                    title: p.name,
                    subtitle:
                        '${formatRupees(p.ratePaise)} per litre · '
                        'usually ${formatLitres(p.usualMl)}',
                    onTap: () => _editMilk(context, h, p),
                  ),
                  const _Divider(),
                ],
                _Row(
                  icon: Icons.add_rounded,
                  title: 'Add another milk type',
                  subtitle: 'e.g. buffalo milk, or curd',
                  onTap: () => _editMilk(context, h, null),
                ),
              ],
            ),
          ),
          const SectionLabel('Milkman'),
          SectionCard(
            padding: EdgeInsets.zero,
            child: _Row(
              icon: Icons.person_rounded,
              title: (h.milkmanName?.isNotEmpty ?? false)
                  ? h.milkmanName!
                  : 'Add milkman',
              subtitle: h.milkmanPhone == null
                  ? 'Add a WhatsApp number'
                  : formatIndianMobile(h.milkmanPhone!),
              onTap: () => _editMilkman(context, h),
            ),
          ),
          const SectionLabel('Reminder'),
          const SectionCard(padding: EdgeInsets.zero, child: _ReminderRow()),
          const SectionLabel('Family'),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // This phone first, then everyone else.
                for (final m
                    in h.members.entries.toList()..sort(
                      (a, b) => (a.key == currentUid ? 0 : 1).compareTo(
                        b.key == currentUid ? 0 : 1,
                      ),
                    )) ...[
                  _Row(
                    icon: Icons.phone_android_rounded,
                    title: m.value,
                    subtitle: m.key == currentUid
                        ? 'This phone · tap to change name'
                        : 'Linked phone',
                    onTap: m.key == currentUid
                        ? () => _editName(context, ref, m.value)
                        : () => _removeMember(context, ref, m.key, m.value),
                  ),
                  const _Divider(),
                ],
                _Row(
                  icon: Icons.group_add_rounded,
                  title: 'Add a family member',
                  subtitle: 'Link another phone to this tracker',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          InviteScreen(invitedBy: h.memberName(currentUid)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SectionLabel('Backup'),
          const SectionCard(padding: EdgeInsets.zero, child: _BackupRow()),
        ],
      ),
    );
  }

  void _editMilk(BuildContext context, Household h, Product? product) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _MilkSheet(
          product: product,
          canRemove: product != null && h.products.length > 1,
        ),
      );

  void _editMilkman(BuildContext context, Household h) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _MilkmanSheet(
          initial: MilkmanDraft(
            name: h.milkmanName ?? '',
            phoneText: h.milkmanPhone == null
                ? ''
                : h.milkmanPhone!.substring(2),
          ),
        ),
      );

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    String uid,
    String name,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove $name?'),
        content: Text(
          "$name's phone will stop seeing this tracker. Days they already "
          'logged stay. You can add them again with a new code.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(milkRepositoryProvider).removeMember(uid);
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(current: current),
    );
    if (name != null && name.trim().isNotEmpty) {
      await ref.read(milkRepositoryProvider).setMyName(name.trim());
    }
  }
}

/// Owns its text controller so it is disposed only after the dialog's
/// closing animation, never while the field is still on screen.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.current});

  final String current;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.current);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Your name'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      textCapitalization: TextCapitalization.words,
      onSubmitted: (v) => Navigator.pop(context, v),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, _controller.text),
        child: const Text('Save'),
      ),
    ],
  );
}

/// Bottom sheet with a title, scrolling body and a Save button that stays
/// above the keyboard.
class _EditSheet extends StatelessWidget {
  const _EditSheet({
    required this.title,
    required this.body,
    required this.onSave,
    this.extra,
  });

  final String title;
  final Widget body;
  final VoidCallback? onSave;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            body,
            const SizedBox(height: 24),
            FilledButton(onPressed: onSave, child: const Text('Save')),
            ?extra,
          ],
        ),
      ),
    );
  }
}

class _MilkSheet extends ConsumerStatefulWidget {
  const _MilkSheet({required this.product, required this.canRemove});

  final Product? product;
  final bool canRemove;

  @override
  ConsumerState<_MilkSheet> createState() => _MilkSheetState();
}

class _MilkSheetState extends ConsumerState<_MilkSheet> {
  late MilkDraft _draft = widget.product == null
      ? const MilkDraft()
      : MilkDraft(
          name: widget.product!.name,
          priceText: formatRupees(widget.product!.ratePaise)
              .replaceAll(RegExp(r'[₹,]'), ''),
          usualMl: widget.product!.usualMl,
        );

  Future<void> _save() async {
    await ref
        .read(milkRepositoryProvider)
        .saveProduct(
          Product(
            id: widget.product?.id ?? newProductId(),
            name: _draft.name.trim(),
            ratePaise: _draft.ratePaise!,
            usualMl: _draft.usualMl,
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    final p = widget.product!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${p.name}?'),
        content: Text(
          'Days already logged keep their ${p.name.toLowerCase()} and its '
          'price in the bill.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(milkRepositoryProvider).removeProduct(p.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final priceChanged =
        widget.product != null &&
        _draft.ratePaise != null &&
        _draft.ratePaise != widget.product!.ratePaise;
    return _EditSheet(
      title: widget.product == null ? 'Add milk type' : 'Edit milk',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MilkForm(
            initial: _draft,
            onChanged: (d) => setState(() => _draft = d),
          ),
          if (priceChanged) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.missingSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'The new price is used from now on. Days already logged '
                'keep their own price.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ],
      ),
      onSave: _draft.isValid ? _save : null,
      extra: widget.canRemove
          ? TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: _remove,
              child: const Text('Remove this milk type'),
            )
          : null,
    );
  }
}

class _MilkmanSheet extends ConsumerStatefulWidget {
  const _MilkmanSheet({required this.initial});

  final MilkmanDraft initial;

  @override
  ConsumerState<_MilkmanSheet> createState() => _MilkmanSheetState();
}

class _MilkmanSheetState extends ConsumerState<_MilkmanSheet> {
  late MilkmanDraft _draft = widget.initial;

  Future<void> _save() async {
    await ref
        .read(milkRepositoryProvider)
        .setMilkman(name: _draft.name.trim(), phone: _draft.phone);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => _EditSheet(
    title: 'Milkman',
    body: MilkmanForm(
      initial: _draft,
      onChanged: (d) => setState(() => _draft = d),
    ),
    onSave: _draft.isValid ? _save : null,
  );
}

class _BackupRow extends ConsumerWidget {
  const _BackupRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(backupEmailProvider).value;
    return email == null
        ? _Row(
            icon: Icons.cloud_upload_rounded,
            title: 'Back up with Google',
            subtitle: 'Get your log back on a new or reset phone',
            onTap: () => runBackup(context, ref),
          )
        : _Row(
            icon: Icons.cloud_done_rounded,
            title: 'Backed up',
            subtitle:
                '$email · restore it on a new phone from the '
                'welcome screen',
          );
  }
}

class _ReminderRow extends ConsumerWidget {
  const _ReminderRow();

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    ReminderSettings s,
    bool on,
  ) async {
    if (on && !await ref.read(remindersProvider).requestPermission()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 8),
          content: const Text(
            'Notifications are blocked for Milk Tracker. Allow them in the '
            "phone's Settings → Apps → Milk Tracker → Notifications.",
          ),
        ),
      );
      return;
    }
    await ref
        .read(reminderSettingsProvider.notifier)
        .set(s.copyWith(enabled: on));
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    ReminderSettings s,
  ) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: s.hour, minute: s.minute),
      helpText: 'Remind me at',
    );
    if (t == null) return;
    final timed = s.copyWith(hour: t.hour, minute: t.minute);
    await ref.read(reminderSettingsProvider.notifier).set(timed);
    // Picking a time means "remind me": switch it on (asks permission).
    if (!timed.enabled && context.mounted) {
      await _toggle(context, ref, timed, true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final settings = ref.watch(reminderSettingsProvider);
    final sync = ref.watch(reminderSyncProvider);
    final s = settings.value ?? const ReminderSettings();
    final time = TimeOfDay(hour: s.hour, minute: s.minute).format(context);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _pickTime(context, ref, s),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: scheme.primaryContainer,
              child: Icon(Icons.notifications_rounded, color: scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily reminder', style: t.titleMedium),
                  Text(
                    s.enabled
                        ? 'Every day at $time, if not logged yet'
                        : 'Off · tap to pick a time',
                    style: t.bodyMedium?.copyWith(color: context.colors.muted),
                  ),
                  if (sync.hasError)
                    Text(
                      "Couldn't set the reminder: "
                      '${friendlyError(sync.error!).detail}',
                      style: t.bodySmall?.copyWith(color: scheme.error),
                    ),
                ],
              ),
            ),
            Switch(
              value: s.enabled,
              onChanged: settings.hasValue
                  ? (on) => _toggle(context, ref, s, on)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: scheme.primaryContainer,
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.titleMedium),
                  Text(
                    subtitle,
                    style: t.bodyMedium?.copyWith(color: context.colors.muted),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded, color: context.colors.muted),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 76, color: context.colors.border);
}
