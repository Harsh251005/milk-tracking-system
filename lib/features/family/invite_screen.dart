import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/invite.dart';
import '../../state/providers.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/section_card.dart';
import '../../ui/widgets/status_views.dart';

/// Shows a QR code and 6-digit code another phone can use to join.
class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key, required this.invitedBy});

  final String invitedBy;

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  late Future<Invite> _invite = _create();

  Future<Invite> _create() => ref
      .read(milkRepositoryProvider)
      .createInvite(invitedBy: widget.invitedBy);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a family member')),
      body: FutureBuilder<Invite>(
        future: _invite,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorPanel(
              error: snap.error!,
              onRetry: () => setState(() => _invite = _create()),
            );
          }
          if (!snap.hasData) return const LoadingView();
          return _InviteBody(invite: snap.data!);
        },
      ),
    );
  }
}

class _InviteBody extends StatelessWidget {
  const _InviteBody({required this.invite});

  final Invite invite;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final validUntil = DateFormat("h:mm a 'on' EEE, d MMM")
        .format(invite.expiresAt)
        .replaceAll('AM', 'am')
        .replaceAll('PM', 'pm');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text('On the other phone', style: t.titleLarge),
        const SizedBox(height: 8),
        for (final (i, step) in const [
          'Install Milk Tracker and open it',
          'Tap "Join their tracker"',
          'Scan this code, or type the numbers',
        ].indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    '${i + 1}',
                    style: t.labelMedium?.copyWith(color: scheme.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(step, style: t.bodyLarge)),
              ],
            ),
          ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            children: [
              QrImageView(
                data: inviteQrPayload(invite.code),
                size: 220,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: scheme.primary,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: scheme.primary,
                ),
                semanticsLabel: 'Family code ${invite.code}',
              ),
              const SizedBox(height: 12),
              Text(
                formatInviteCode(invite.code),
                style: t.displaySmall?.copyWith(letterSpacing: 6),
              ),
              const SizedBox(height: 4),
              Text(
                'Works until $validUntil',
                textAlign: TextAlign.center,
                style: t.bodyMedium?.copyWith(color: context.colors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => SharePlus.instance.share(
            ShareParams(
              text:
                  'Join our milk tracker: open Milk Tracker, tap '
                  '"Join their tracker" and enter code '
                  '${formatInviteCode(invite.code)}',
            ),
          ),
          icon: const Icon(Icons.share_rounded),
          label: const Text('Send the code'),
        ),
        const SizedBox(height: 12),
        Text(
          'Anyone with this code can see and add to your milk log until it '
          'expires, so only share it with family.',
          textAlign: TextAlign.center,
          style: t.bodySmall?.copyWith(color: context.colors.muted),
        ),
      ],
    );
  }
}
