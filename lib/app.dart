import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/intro/intro_screen.dart';
import 'features/month/month_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/setup/setup_screen.dart';
import 'features/today/today_screen.dart';
import 'state/intro_provider.dart';
import 'state/providers.dart';
import 'state/reminder_providers.dart';
import 'ui/friendly_error.dart';
import 'ui/theme.dart';
import 'ui/widgets/status_views.dart';

class MilkTrackerApp extends StatelessWidget {
  const MilkTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Milk Tracker',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Screens without an app bar keep dark status-bar icons too.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: child!,
      ),
      home: const AppGate(),
    );
  }
}

/// Signs in, then shows first-run setup or the app.
class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AsyncView(
        value: ref.watch(signedInUidProvider),
        onRetry: () => ref.invalidate(signedInUidProvider),
        builder: (_) => AsyncView(
          value: ref.watch(householdIdProvider),
          onRetry: () => ref.invalidate(householdIdProvider),
          builder: (householdId) => householdId != null
              ? const HomeShell()
              : AsyncView(
                  value: ref.watch(introSeenProvider),
                  builder: (seen) => seen
                      ? const SetupScreen()
                      : IntroScreen(
                          onDone: () =>
                              ref.read(introSeenProvider.notifier).markSeen(),
                        ),
                ),
        ),
      ),
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0;
  StreamSubscription<Object>? _writeErrors;

  @override
  void initState() {
    super.initState();
    // A save the server rejected must never fail silently.
    _writeErrors = ref
        .read(milkRepositoryProvider)
        .writeErrors
        .listen(_showWriteError);
  }

  @override
  void dispose() {
    _writeErrors?.cancel();
    super.dispose();
  }

  void _showWriteError(Object error) {
    if (!mounted) return;
    final err = friendlyError(error);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 15),
          showCloseIcon: true,
          content: Text("Couldn't save: ${err.message}\n${err.detail}"),
        ),
      );
  }

  void _go(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    // Keeps reminders scheduled while the app runs; failures show in Settings.
    ref.watch(reminderSyncProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: [
            TodayScreen(onOpenMonth: () => _go(1)),
            const MonthScreen(),
            const SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _go,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny_rounded),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Month',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
