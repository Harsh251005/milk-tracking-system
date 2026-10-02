import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../state/providers.dart';
import '../../ui/friendly_error.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/forms.dart';

/// First run: name -> milk -> milkman (skippable). Creates the household.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  static const _steps = 3;

  int _step = 0;
  String _name = '';
  late final _nameController = TextEditingController();
  MilkDraft _milk = const MilkDraft();
  MilkmanDraft _milkman = const MilkmanDraft();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canContinue => switch (_step) {
    0 => _name.trim().isNotEmpty,
    1 => _milk.isValid,
    _ => _milkman.isValid,
  };

  Future<void> _finish({required bool withMilkman}) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(accountRepositoryProvider)
          .createHousehold(
            memberName: _name.trim(),
            product: Product(
              id: newProductId(),
              name: _milk.name.trim(),
              ratePaise: _milk.ratePaise!,
              usualMl: _milk.usualMl,
            ),
            milkmanName: withMilkman ? _milkman.name.trim() : null,
            milkmanPhone: withMilkman ? _milkman.phone : null,
          );
      // AppGate switches to the home screen once the household id arrives.
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final err = friendlyError(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 10),
          content: Text('${err.message}\n${err.detail}'),
        ),
      );
    }
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_step < _steps - 1) {
      setState(() => _step++);
    } else {
      _finish(withMilkman: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final (title, subtitle) = switch (_step) {
      0 => ('Welcome', 'Keep track of daily milk and the monthly bill.'),
      1 => ('Your milk', 'You can change these any time in Settings.'),
      _ => ('Your milkman', 'Used to send him updates on WhatsApp.'),
    };

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _Progress(
                step: _step,
                steps: _steps,
                onBack: _step == 0 || _saving
                    ? null
                    : () => setState(() => _step--),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Text(title, style: t.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: t.bodyLarge?.copyWith(color: context.colors.muted),
                    ),
                    const SizedBox(height: 28),
                    switch (_step) {
                      0 => _NameStep(
                        controller: _nameController,
                        name: _name,
                        onChanged: (v) => setState(() => _name = v),
                      ),
                      1 => MilkForm(
                        initial: _milk,
                        onChanged: (d) => setState(() => _milk = d),
                      ),
                      _ => MilkmanForm(
                        initial: _milkman,
                        onChanged: (d) => setState(() => _milkman = d),
                      ),
                    },
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: _canContinue && !_saving ? _next : null,
                      child: _saving
                          ? const SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : Text(_step == _steps - 1 ? 'Finish' : 'Next'),
                    ),
                    if (_step == _steps - 1)
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => _finish(withMilkman: false),
                        child: const Text('Skip for now'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({
    required this.step,
    required this.steps,
    required this.onBack,
  });

  final int step;
  final int steps;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: onBack == null
                ? null
                : IconButton(
                    tooltip: 'Back',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
          ),
          const SizedBox(width: 8),
          for (var i = 0; i < steps; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 6,
                decoration: BoxDecoration(
                  color: i <= step ? scheme.primary : context.colors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({
    required this.controller,
    required this.name,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String name;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FieldLabel('What should we call you?'),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          onChanged: onChanged,
          decoration: const InputDecoration(hintText: 'Your name'),
        ),
        const SizedBox(height: 10),
        SuggestionChips(
          options: const ['Mom', 'Dad'],
          selected: name,
          onPick: (v) {
            controller.text = v;
            onChanged(v);
          },
        ),
        const SizedBox(height: 12),
        Text(
          'This shows next to the days you log, so the family knows who '
          'added what.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: context.colors.muted),
        ),
      ],
    );
  }
}
