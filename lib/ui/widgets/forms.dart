import 'package:flutter/material.dart';

import '../../domain/format.dart';
import '../../domain/phone.dart';
import '../theme.dart';
import 'quantity_editor.dart';

/// Field label above an input, large enough to read without glasses.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

/// Text before or after an input that stays visible even when the field is
/// empty and unfocused (InputDecoration.prefixText only shows on focus).
class InputAffix extends StatelessWidget {
  const InputAffix(this.text, {super.key, this.trailing = false});

  final String text;
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        left: trailing ? 8 : 18,
        right: trailing ? 18 : 8,
      ),
      child: Text(
        text,
        style: trailing
            ? t.bodyMedium?.copyWith(color: context.colors.muted)
            : t.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Tap-to-fill suggestions under a text field.
class SuggestionChips extends StatelessWidget {
  const SuggestionChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onPick,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          ChoiceChip(
            label: Text(o),
            selected: o == selected,
            onSelected: (_) => onPick(o),
            showCheckmark: false,
            labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: o == selected ? scheme.onPrimary : scheme.onSurface,
            ),
            selectedColor: scheme.primary,
            backgroundColor: context.colors.card,
            side: BorderSide(
              color: o == selected ? scheme.primary : context.colors.border,
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
      ],
    );
  }
}

// --- Milk -------------------------------------------------------------------

class MilkDraft {
  const MilkDraft({this.name = '', this.priceText = '', this.usualMl = 0});

  final String name;
  final String priceText;
  final int usualMl;

  int? get ratePaise => parseRupees(priceText);
  bool get isValid =>
      name.trim().isNotEmpty && ratePaise != null && usualMl > 0;

  MilkDraft copyWith({String? name, String? priceText, int? usualMl}) =>
      MilkDraft(
        name: name ?? this.name,
        priceText: priceText ?? this.priceText,
        usualMl: usualMl ?? this.usualMl,
      );
}

const milkSuggestions = [
  'Cow milk',
  'Buffalo milk',
  'Toned milk',
  'Full cream',
];

/// Milk type, price per litre and usual daily quantity.
class MilkForm extends StatefulWidget {
  const MilkForm({super.key, required this.initial, required this.onChanged});

  final MilkDraft initial;
  final ValueChanged<MilkDraft> onChanged;

  @override
  State<MilkForm> createState() => _MilkFormState();
}

class _MilkFormState extends State<MilkForm> {
  late MilkDraft _draft = widget.initial;
  late final _name = TextEditingController(text: _draft.name);
  late final _price = TextEditingController(text: _draft.priceText);

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  void _update(MilkDraft d) {
    setState(() => _draft = d);
    widget.onChanged(d);
  }

  @override
  Widget build(BuildContext context) {
    final priceError =
        _draft.priceText.trim().isNotEmpty && _draft.ratePaise == null
        ? 'Enter a price like 70 or 72.50'
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FieldLabel('Which milk?'),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (v) => _update(_draft.copyWith(name: v)),
          decoration: const InputDecoration(hintText: 'e.g. Cow milk'),
        ),
        const SizedBox(height: 10),
        SuggestionChips(
          options: milkSuggestions,
          selected: _draft.name,
          onPick: (v) {
            _name.text = v;
            _update(_draft.copyWith(name: v));
          },
        ),
        const SizedBox(height: 24),
        const FieldLabel('Price per litre'),
        TextField(
          controller: _price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => _update(_draft.copyWith(priceText: v)),
          decoration: InputDecoration(
            prefixIcon: const InputAffix('₹'),
            hintText: 'e.g. 70',
            suffixIcon: const InputAffix('per litre', trailing: true),
            errorText: priceError,
          ),
        ),
        const SizedBox(height: 24),
        const FieldLabel('How much comes on a usual day?'),
        QuantityPicker(
          ml: _draft.usualMl,
          onChanged: (ml) => _update(_draft.copyWith(usualMl: ml)),
        ),
      ],
    );
  }
}

// --- Milkman ----------------------------------------------------------------

class MilkmanDraft {
  const MilkmanDraft({this.name = '', this.phoneText = ''});

  final String name;
  final String phoneText;

  /// `91XXXXXXXXXX`, or null if empty or invalid.
  String? get phone => normalizeIndianMobile(phoneText);
  bool get phoneInvalid => phoneText.trim().isNotEmpty && phone == null;
  bool get isValid => !phoneInvalid;

  MilkmanDraft copyWith({String? name, String? phoneText}) => MilkmanDraft(
    name: name ?? this.name,
    phoneText: phoneText ?? this.phoneText,
  );
}

class MilkmanForm extends StatefulWidget {
  const MilkmanForm({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final MilkmanDraft initial;
  final ValueChanged<MilkmanDraft> onChanged;

  @override
  State<MilkmanForm> createState() => _MilkmanFormState();
}

class _MilkmanFormState extends State<MilkmanForm> {
  late MilkmanDraft _draft = widget.initial;
  late final _name = TextEditingController(text: _draft.name);
  late final _phone = TextEditingController(text: _draft.phoneText);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _update(MilkmanDraft d) {
    setState(() => _draft = d);
    widget.onChanged(d);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FieldLabel("Milkman's name"),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          onChanged: (v) => _update(_draft.copyWith(name: v)),
          decoration: const InputDecoration(hintText: 'e.g. Ramesh bhaiya'),
        ),
        const SizedBox(height: 24),
        const FieldLabel('WhatsApp number'),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          onChanged: (v) => _update(_draft.copyWith(phoneText: v)),
          decoration: InputDecoration(
            prefixIcon: const InputAffix('+91'),
            hintText: '98765 43210',
            errorText: _draft.phoneInvalid
                ? 'Enter a 10-digit mobile number'
                : null,
          ),
        ),
      ],
    );
  }
}
