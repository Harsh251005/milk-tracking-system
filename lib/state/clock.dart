import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/dates.dart';

/// The current calendar day. Phones keep apps alive in the background, so
/// this refreshes at midnight and whenever the app comes back to the
/// foreground; otherwise "Today" would still show yesterday next morning.
class CurrentDay extends Notifier<DateTime> with WidgetsBindingObserver {
  Timer? _midnight;

  @override
  DateTime build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _midnight?.cancel();
    });
    _scheduleMidnight();
    return dateOnly(DateTime.now());
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(
      next.difference(now) + const Duration(seconds: 1),
      _refresh,
    );
  }

  void _refresh() {
    final day = dateOnly(DateTime.now());
    if (day != state) state = day;
    _scheduleMidnight();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }
}

final currentDayProvider = NotifierProvider<CurrentDay, DateTime>(
  CurrentDay.new,
);
