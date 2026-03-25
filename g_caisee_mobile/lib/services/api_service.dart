import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://g-caisse-api.onrender.com/api';

  // Sauvegarde le token après login
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Récupère le token stocké
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Supprime le token (déconnexion)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Headers avec token JWT
  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer \$token",
    };
  }

  // ==========================================
  // 1. UTILISATEURS & PROFIL
  // ==========================================

  static Future<Map<String, dynamic>> loginUser(String phone, String pin) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone, "pincode": pin}),
      ).timeout(const Duration(seconds: 45));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        // Sauvegarder le token JWT reçu du serveur
        if (data['token'] != null) await saveToken(data['token']);
        return data;
      } else {
        throw Exception(data['message'] ?? "Identifiants incorrects");
      }
    } on TimeoutException {
      throw Exception("Le serveur est en cours de démarrage, réessaie dans 10 secondes.");
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<void> registerUser(String name, String phone, String pin) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"fullname": name, "phone": phone, "pincode": pin}),
      ).timeout(const Duration(seconds: 45));

      if (res.statusCode == 409) {
        throw Exception("Ce numéro est déjà enregistré");
      }
      if (res.statusCode != 201) {
        final data = jsonDecode(res.body);
        throw Exception(data['message'] ?? "Erreur d'inscription");
      }
    } on TimeoutException {
      throw Exception("Le serveur est en cours de démarrage, réessaie dans 10 secondes.");
    }
  }

  static Future<void> updateProfile(int userId, String fullname, String phone) async {
    final headers = await _authHeaders();
    final res = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: headers,
      body: jsonEncode({"fullname": fullname, "phone": phone}),
    );
    if (res.statusCode != 200) throw Exception("Erreur de mise à jour");
  }

  static Future<void> resetPin(String phone, String newPin) async {
    final res = await http.post(
      Uri.parse('$baseUrl/users/reset-pin'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phone": phone, "new_pin": newPin}),
    ).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Erreur réinitialisation PIN');
    }
  }

  static Future<double> getUserBalance(int userId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/balance'), headers: headers);
    if (res.statusCode == 200) {
      // Correction : tryParse pour éviter les erreurs de format
      return double.tryParse(jsonDecode(res.body)['balance'].toString()) ?? 0.0;
    }
    return 0.0;
  }

  static Future<int> getTrustScore(int userId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/trust-score'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body)['trust_score'];
    return 100;
  }

  static Future<String> getRecipientName(String phone, String operator) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/users/check?phone=$phone&operator=$operator'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body)['fullname'];
    return "Destinataire inconnu";
  }

  // ==========================================
  // 2. FINANCE (NOTCH PAY, TRANSFERTS, DEPÔTS)
  // ==========================================

  static Future<Map<String, dynamic>> initiatePayment(int userId, String phone, double amount, {String? name}) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/deposit'),
      headers: headers,
      body: jsonEncode({
        'user_id': userId, 
        'phone': phone,
        'amount': amount,
        'email': "user$userId@gcaisse.com", // Email requis par Notch Pay (généré automatiquement)
        'name': name ?? "Membre G-Caisse", // Aligné avec le backend
      }),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return body;
    } else {
      // On récupère le vrai message d'erreur du serveur s'il existe
      String msg = body['error'] ?? body['message'] ?? 'Erreur lors de l\'initialisation du dépôt';
      throw Exception(msg);
    }
  }

  static Future<Map<String, dynamic>> processPayout({
    required int userId,
    required double amount,
    required String phone,
    required String name,
    String? channel,
  }) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/payout'),
      headers: headers,
      body: jsonEncode({
        "user_id": userId,
        "amount": amount,
        "phone": phone,
        "name": name,
        "channel": channel ?? "cm.mobile"
      }),
    ).timeout(const Duration(seconds: 60));

    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      // Récupérer le statut réel du transfert Notch Pay
      final transferStatus = body['data']?['transfer']?['status'] ?? 'sent';
      return {...body, 'transfer_status': transferStatus};
    } else {
      throw Exception(body['message'] ?? "Erreur lors du retrait");
    }
  }

  static Future<void> transferMoney(int senderId, String receiverPhone, double amount) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/transfer'),
      headers: headers,
      body: jsonEncode({"sender_id": senderId, "receiver_phone": receiverPhone, "amount": amount}),
    );
    if (res.statusCode != 200) throw Exception("Erreur transfert");
  }

  static Future<Map<String, dynamic>> processDirectTransfer({
    required int senderId,
    required String receiverPhone,
    required double amount,
    required String operator,
  }) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/transfer'),
      headers: headers,
      body: jsonEncode({
        "sender_id": senderId, 
        "receiver_phone": receiverPhone, 
        "amount": amount, 
        "operator": operator
      }),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Échec du transfert direct");
  }

  // depositMoney est un doublon de initiatePayment — supprimé
  // Utilise initiatePayment() à la place

  static Future<List<dynamic>> getUserTransactions(int userId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/transactions'), headers: headers);
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<Map<String, dynamic>> getTransactionReceipt(int transactionId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/transactions/$transactionId/receipt'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Erreur reçu");
  }

  // ==========================================
  // 3. SERVICES (AIRTIME & FACTURES)
  // ==========================================

  static Future<Map<String, dynamic>> buyAirtimeOrData({
    required int userId,
    required String phoneNumber,
    required double amount,
    required String operator,
    required String type,
    String? plan,
  }) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/services/airtime'),
      headers: headers,
      body: jsonEncode({
        "user_id": userId,
        "receiver_phone": phoneNumber,
        "amount": amount,
        "operator": operator,       // cm.mtn | cm.orange
        "service_type": type,
        "plan_validity": plan
      }),
    ).timeout(const Duration(seconds: 30));

    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? "Erreur lors de la recharge");
  }

  static Future<Map<String, dynamic>> checkAirtimeStatus(String paymentReference) async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/services/airtime/status/$paymentReference'),
      headers: headers,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Erreur vérification statut recharge");
  }

  static Future<Map<String, dynamic>> payBill({
    required int userId,
    required String contractNumber,
    required double amount,
    required String billType,
    required String phone,
    required String operator,
  }) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/services/${billType.toLowerCase()}'),
      headers: headers,
      body: jsonEncode({
        "user_id": userId,
        "contract_number": contractNumber,
        "amount": amount,
        "phone": phone,
        "operator": operator,
      }),
    ).timeout(const Duration(seconds: 30));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? "Erreur paiement facture");
  }

  static Future<Map<String, dynamic>> checkBillStatus(String paymentReference) async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/services/bill/status/$paymentReference'),
      headers: headers,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Erreur vérification statut");
  }

  // ==========================================
  // 4. TONTINES & MESSAGERIE
  // ==========================================

  static Future<List<dynamic>> getTontines(int userId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/tontines?user_id=$userId'), headers: headers);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data;
      }
      return [];
    } else {
      debugPrint("Erreur serveur tontines: ${res.statusCode}");
      return [];
    }
  }

  static Future<void> processTontinePayment({required int userId, required int tontineId, required double amount, bool isLate = false}) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/payments/tontine'),
      headers: headers,
      body: jsonEncode({"user_id": userId, "tontine_id": tontineId, "amount": amount, "is_late": isLate}),
    );
    if (res.statusCode != 200) throw Exception("Échec du paiement tontine");
  }

  static Future<Map<String, dynamic>?> getCurrentWinner(int tontineId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/tontines/$tontineId/winner'), headers: headers);
    return res.statusCode == 200 ? jsonDecode(res.body) : null;
  }

  static Future<List<dynamic>> getTontineMembers(int tontineId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/tontines/$tontineId/members'), headers: headers);
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<Map<String, dynamic>> createTontine(String name, int adminId, String freq, double amount, double commission) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/tontines'),
      headers: headers,
      // "amount" correspond au champ attendu par le backend (mappé sur amount_to_pay en DB)
      body: jsonEncode({
        "name": name,
        "admin_id": adminId,
        "frequency": freq,
        "amount": amount,
        "commission_rate": commission
      }),
    );
    return res.statusCode == 201 ? jsonDecode(res.body) : throw Exception("Erreur lors de la création");
  }

  static Future<Map<String, dynamic>> updateTontine(int tontineId, Map<String, dynamic> data) async {
    final headers = await _authHeaders();
    final res = await http.put(
      Uri.parse('$baseUrl/tontines/$tontineId'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception("Échec de la mise à jour de la tontine");
  }

  static Future<List<dynamic>> getGroupMessages(int tontineId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/tontines/$tontineId/messages'), headers: headers);
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<void> sendMessage(int tontineId, int userId, String content) async {
    final headers = await _authHeaders();
    await http.post(
      Uri.parse('$baseUrl/tontines/$tontineId/messages'),
      headers: headers,
      body: jsonEncode({"user_id": userId, "content": content}),
    );
  }

  static Future<void> sendVoiceMessage({
    required int tontineId,
    required int userId,
    required String filePath,
    required int durationSec,
  }) async {
    final token = await getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/tontines/$tontineId/voice'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields['user_id'] = userId.toString();
    request.fields['duration_sec'] = durationSec.toString();
    request.files.add(await http.MultipartFile.fromPath('audio', filePath));

    final response = await request.send().timeout(const Duration(seconds: 30));
    if (response.statusCode != 201) {
      throw Exception('Erreur upload vocal : ${response.statusCode}');
    }
  }

  static Future<List<dynamic>> getAuctions(int tontineId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/tontines/$tontineId/auctions'), headers: headers);
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  // ==========================================
  // 5. ÉPARGNE, PRÊTS & SOCIAL
  // ==========================================

  static Future<double> getSavingsBalance(int userId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/savings'), headers: headers);
    if (res.statusCode == 200) {
      List data = jsonDecode(res.body);
      double total = 0;
      for (var goal in data) { total += double.tryParse(goal['current_amount'].toString()) ?? 0.0; }
      return total;
    }
    return 0.0;
  }

  static Future<List<dynamic>> getSavingsTransactions(int userId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/transactions'), headers: headers);
    if (res.statusCode == 200) {
      List allTxs = jsonDecode(res.body);
      return allTxs.where((tx) => tx['type'] == 'deposit' || tx['type'] == 'saving').toList();
    }
    return [];
  }

  // depositToSavings est un doublon de initiatePayment — supprimé
  // Utilise initiatePayment() à la place

  static Future<void> requestIslamicLoan(int userId, double amount, String purpose) async {
    final headers = await _authHeaders();
    await http.post(
      Uri.parse('$baseUrl/loans/islamic'),
      headers: headers,
      body: jsonEncode({"user_id": userId, "amount": amount, "purpose": purpose}),
    );
  }

  static Future<double> getSocialFund() async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/social/fund'), headers: headers);
    return res.statusCode == 200 ? double.parse(jsonDecode(res.body)['total'].toString()) : 0.0;
  }

  static Future<List<dynamic>> getSocialEvents() async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/social/events'), headers: headers);
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<void> makeDonation(int eventId, double amount) async {
    final headers = await _authHeaders();
    await http.post(
      Uri.parse('$baseUrl/social/donate'),
      headers: headers,
      body: jsonEncode({"event_id": eventId, "amount": amount}),
    );
  }

  // ==========================================
  // 6. RADAR & ADMIN
  // ==========================================

  static Future<void> updateFcmToken(int userId, String token) async {
    final headers = await _authHeaders();
    await http.put(
      Uri.parse('$baseUrl/users/$userId/fcm-token'),
      headers: headers,
      body: jsonEncode({"fcm_token": token}),
    );
  }

  static Future<void> updateUserLocation(int userId, double lat, double lng) async {
    final headers = await _authHeaders();
    await http.post(
      Uri.parse('$baseUrl/users/$userId/location'),
      headers: headers,
      body: jsonEncode({"latitude": lat, "longitude": lng}),
    );
  }

  static Future<List<dynamic>> getTontineMembersLocations(int tontineId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/tontines/$tontineId/locations'), headers: headers);
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<Map<String, dynamic>> getAdminStats() async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/admin/stats'), headers: headers);
    return res.statusCode == 200 ? jsonDecode(res.body) : {"total_fees": 0, "total_volume": 0};
  }
}