import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/share_text.dart';

/// Remembers the message options on this phone between uses.
class SharePrefs {
  static const _billKey = 'share.bill';
  static const _todayPriceKey = 'share.today.price';

  Future<BillOptions> loadBill() async {
    final raw = (await SharedPreferences.getInstance()).getString(_billKey);
    if (raw == null) return const BillOptions();
    try {
      return BillOptions.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return const BillOptions();
    }
  }

  Future<void> saveBill(BillOptions o) async =>
      (await SharedPreferences.getInstance()).setString(
        _billKey,
        jsonEncode(o.toJson()),
      );

  Future<bool> loadTodayPrice() async =>
      (await SharedPreferences.getInstance()).getBool(_todayPriceKey) ?? false;

  Future<void> saveTodayPrice(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_todayPriceKey, v);
}
