import 'package:flutter/material.dart';

import '../../domain/format.dart';
import 'forms.dart';

/// Asks for a price per litre. Returns paise, or null if cancelled.
Future<int?> showPriceInputDialog(
  BuildContext context, {
  required String productName,
  required int currentPaise,
}) => showDialog<int>(
  context: context,
  builder: (_) =>
      _PriceInputDialog(productName: productName, currentPaise: currentPaise),
);

class _PriceInputDialog extends StatefulWidget {
  const _PriceInputDialog({
    required this.productName,
    required this.currentPaise,
  });

  final String productName;
  final int currentPaise;

  @override
  State<_PriceInputDialog> createState() => _PriceInputDialogState();
}

class _PriceInputDialogState extends State<_PriceInputDialog> {
  late final _controller = TextEditingController(
    text: formatRupees(widget.currentPaise).replaceAll(RegExp(r'[₹,]'), ''),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final paise = parseRupees(_controller.text);
    if (paise == null) {
      setState(() => _error = 'Enter a price like 70 or 72.50');
      return;
    }
    Navigator.of(context).pop(paise);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text('${widget.productName} price'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: t.headlineMedium,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          prefixIcon: const InputAffix('₹'),
          prefixIconConstraints: const BoxConstraints(),
          suffixIcon: const InputAffix('per litre', trailing: true),
          suffixIconConstraints: const BoxConstraints(),
          errorText: _error,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Done')),
      ],
    );
  }
}
