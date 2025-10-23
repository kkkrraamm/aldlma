import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrdersService extends ChangeNotifier {
  static final OrdersService instance = OrdersService._internal();
  OrdersService._internal();

  static const String _kOrders = 'orders_v1';

  final List<Map<String, dynamic>> _orders = <Map<String, dynamic>>[];

  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_kOrders) ?? <String>[];
    _orders
      ..clear()
      ..addAll(raw.map((s) {
        try {
          final decoded = json.decode(s);
          if (decoded is Map<String, dynamic>) return decoded;
        } catch (_) {}
        return <String, dynamic>{};
      }).where((m) => m.isNotEmpty));
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _orders.map((o) => json.encode(o)).toList();
    await prefs.setStringList(_kOrders, data);
  }

  List<Map<String, dynamic>> getOrdersForPhone(String phone) {
    return _orders.where((o) => (o['customerPhone'] ?? '') == phone).toList();
  }

  Future<void> addOrder(Map<String, dynamic> order) async {
    _orders.add(order);
    await _persist();
    notifyListeners();
  }
}


