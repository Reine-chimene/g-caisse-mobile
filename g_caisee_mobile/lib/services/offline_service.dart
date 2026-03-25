import 'package:hive_flutter/hive_flutter.dart';

/// Service de cache local pour le mode hors-ligne
class OfflineService {
  static late Box _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('gcaisse_cache');
  }

  // ── Solde ─────────────────────────────────────────────
  static Future<void> saveBalance(double balance) async =>
      _box.put('balance', balance);

  static double getBalance() => _box.get('balance', defaultValue: 0.0);

  // ── Transactions ──────────────────────────────────────
  static Future<void> saveTransactions(List<dynamic> txs) async =>
      _box.put('transactions', txs);

  static List<dynamic> getTransactions() =>
      List<dynamic>.from(_box.get('transactions', defaultValue: []));

  // ── Tontines ──────────────────────────────────────────
  static Future<void> saveTontines(List<dynamic> tontines) async =>
      _box.put('tontines', tontines);

  static List<dynamic> getTontines() =>
      List<dynamic>.from(_box.get('tontines', defaultValue: []));

  // ── Données utilisateur ───────────────────────────────
  static Future<void> saveUserData(Map<String, dynamic> data) async =>
      _box.put('user_data', data);

  static Map<String, dynamic>? getUserData() {
    final data = _box.get('user_data');
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  // ── Transactions en attente (mode hors-ligne) ─────────
  static Future<void> addPendingTransaction(Map<String, dynamic> tx) async {
    final pending = getPendingTransactions();
    pending.add(tx);
    await _box.put('pending_transactions', pending);
  }

  static List<Map<String, dynamic>> getPendingTransactions() {
    final raw = _box.get('pending_transactions', defaultValue: []);
    return List<Map<String, dynamic>>.from(
        (raw as List).map((e) => Map<String, dynamic>.from(e)));
  }

  static Future<void> clearPendingTransactions() async =>
      _box.delete('pending_transactions');

  // ── Vérifier si des données sont en cache ─────────────
  static bool hasCache() => _box.containsKey('balance');

  static Future<void> clearAll() async => _box.clear();
}
