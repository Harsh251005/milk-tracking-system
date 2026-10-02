import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ui/theme.dart';
import 'illustrations.dart';

/// First-launch welcome: three swipeable pages, then setup.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _pages = PageController();
  int _page = 0;

  static const _content = [
    (
      'Milk, logged in one tap',
      'Your usual amount is already filled in. Tap once when the milkman '
          'comes, and you are done for the day.',
    ),
    (
      'The whole family, in sync',
      'Link everyone at home to one tracker. Whoever logs it, all phones '
          'see it, even without internet.',
    ),
    (
      'The bill, ready on WhatsApp',
      "See the month's milk and bill at a glance, and send the milkman "
          'exactly what you choose.',
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool get _last => _page == _content.length - 1;

  void _next() {
    HapticFeedback.selectionClick();
    if (_last) {
      widget.onDone();
    } else {
      _pages.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 8, 0),
                child: AnimatedOpacity(
                  opacity: _last ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: _last ? null : widget.onDone,
                    child: const Text('Skip'),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _content.length,
                onPageChanged: (p) => setState(() => _page = p),
                itemBuilder: (context, i) => _Page(
                  illustration: switch (i) {
                    0 => const BottleIllustration(),
                    1 => const SyncIllustration(),
                    _ => const BillIllustration(),
                  },
                  title: _content[i].$1,
                  body: _content[i].$2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _content.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _page ? 26 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? Theme.of(context).colorScheme.primary
                                : context.colors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _last ? 'Get started' : 'Next',
                          key: ValueKey(_last),
                          style: t.labelLarge?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    required this.illustration,
    required this.title,
    required this.body,
  });

  final Widget illustration;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          // Full width: a CustomPaint in a Column otherwise gets zero
          // width and draws nothing.
          Expanded(
            flex: 5,
            child: SizedBox(width: double.infinity, child: illustration),
          ),
          const SizedBox(height: 12),
          // Fixed-height text area, top-aligned, so titles line up on every
          // page whatever the description's length.
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: t.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: t.bodyLarge?.copyWith(color: context.colors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
