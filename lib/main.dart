import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Android reads its Firebase config from android/app/google-services.json.
  await Firebase.initializeApp();
  runApp(const MilkTrackerApp());
}

class MilkTrackerApp extends StatelessWidget {
  const MilkTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Milk Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF1F4E79)),
      home: const HomeShell(),
    );
  }
}

/// M0 placeholder: three tabs plus a live check that anonymous sign-in works.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  late final Future<User> _signIn = _signInAnonymously();

  static Future<User> _signInAnonymously() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser ?? (await auth.signInAnonymously()).user;
    return user!;
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['Today', 'Month', 'Settings'];
    return Scaffold(
      appBar: AppBar(title: Text(titles[_tab])),
      body: Center(
        child: FutureBuilder<User>(
          future: _signIn,
          builder: (context, snap) {
            if (snap.hasError) {
              return _Status(
                icon: Icons.error,
                color: Theme.of(context).colorScheme.error,
                text: 'Could not connect\n${snap.error}',
              );
            }
            if (!snap.hasData) return const CircularProgressIndicator();
            return _Status(
              icon: Icons.check_circle,
              color: Colors.green.shade700,
              text: 'Connected\nuser ${snap.data!.uid.substring(0, 8)}…',
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Month'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 64),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}
