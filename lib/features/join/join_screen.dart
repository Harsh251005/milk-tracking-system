import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../domain/invite.dart';
import '../../state/providers.dart';
import '../../ui/friendly_error.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/forms.dart';

/// Joins a household someone else set up: code (typed or scanned) -> name.
class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key});

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  late final _codeController = TextEditingController();
  late final _nameController = TextEditingController();
  Invite? _invite;
  String? _problem;
  bool _busy = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String? get _code => parseInviteCode(_codeController.text);

  Future<void> _find([String? scanned]) async {
    final code = scanned ?? _code;
    if (code == null) return;
    if (scanned != null) _codeController.text = formatInviteCode(scanned);
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      final invite = await ref.read(accountRepositoryProvider).findInvite(code);
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (invite == null) {
          _problem =
              "That code doesn't match any family. Check the numbers and "
              'try again.';
        } else if (invite.isExpired(DateTime.now())) {
          _problem =
              'That code has expired. Ask ${invite.invitedBy} to make a new '
              'one in Settings → Family.';
        } else {
          _invite = invite;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _problem = friendlyError(e).message;
      });
    }
  }

  Future<void> _join() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _invite == null) return;
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      await ref
          .read(accountRepositoryProvider)
          .joinHousehold(invite: _invite!, memberName: name);
      // AppGate now shows the home screen underneath; reveal it.
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      final err = friendlyError(e);
      setState(() {
        _busy = false;
        _problem = '${err.message}\n${err.detail}';
      });
    }
  }

  Future<void> _scan() async {
    final scanned = await Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => const _ScanScreen()));
    if (scanned != null) await _find(scanned);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final invite = _invite;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  Text(
                    invite == null
                        ? "Join your family's tracker"
                        : "Join ${invite.invitedBy}'s tracker",
                    style: t.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    invite == null
                        ? 'On the phone that already has Milk Tracker, open '
                              'Settings → Family → Add a family member.'
                        : 'You will both see and add the same days.',
                    style: t.bodyLarge?.copyWith(color: context.colors.muted),
                  ),
                  const SizedBox(height: 28),
                  if (invite == null) ...[
                    FilledButton.icon(
                      onPressed: _busy ? null : _scan,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Scan the code'),
                    ),
                    const SizedBox(height: 24),
                    const FieldLabel('Or type the 6 numbers'),
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: t.headlineMedium?.copyWith(letterSpacing: 6),
                      onChanged: (_) => setState(() => _problem = null),
                      onSubmitted: (_) => _find(),
                      decoration: const InputDecoration(hintText: '000 000'),
                    ),
                  ] else ...[
                    const FieldLabel('What should we call you?'),
                    TextField(
                      controller: _nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(hintText: 'Your name'),
                    ),
                    const SizedBox(height: 10),
                    SuggestionChips(
                      options: const ['Mom', 'Dad'],
                      selected: _nameController.text,
                      onPick: (v) => setState(() => _nameController.text = v),
                    ),
                  ],
                  if (_problem != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(_problem!, style: t.bodyLarge),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: invite == null
                    ? OutlinedButton(
                        onPressed: _code != null && !_busy ? _find : null,
                        child: _busy
                            ? const _Spinner()
                            : const Text('Find my family'),
                      )
                    : FilledButton(
                        onPressed:
                            _nameController.text.trim().isNotEmpty && !_busy
                            ? _join
                            : null,
                        child: _busy
                            ? const _Spinner(light: true)
                            : const Text('Join'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner({this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 26,
    height: 26,
    child: CircularProgressIndicator(
      strokeWidth: 3,
      color: light ? Colors.white : null,
    ),
  );
}

/// Full-screen camera that returns the first valid family code it sees.
class _ScanScreen extends StatefulWidget {
  const _ScanScreen();

  @override
  State<_ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<_ScanScreen> {
  bool _done = false;

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final b in capture.barcodes) {
      final code = b.rawValue == null ? null : parseInviteCode(b.rawValue!);
      if (code != null) {
        _done = true;
        Navigator.of(context).pop(code);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Point at the code'),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            onDetect: _onDetect,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  error.errorCode == MobileScannerErrorCode.permissionDenied
                      ? 'Camera permission is off. Allow it in phone '
                            'Settings, or go back and type the numbers.'
                      : "The camera couldn't start. Go back and type the "
                            'numbers instead.\n(${error.errorCode.name})',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 4),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
