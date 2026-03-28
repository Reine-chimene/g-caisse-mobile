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

  // Headers avec token JWT - CORRIGÉ
  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      "Content-Type": "application/json",
      // Suppression du backslash \ qui empêchait la lecture du token
      if (token != null) "Authorization": "Bearer $token", 
    };
  }

  // ==========================================
  // 1. UTILISATEURS & PROFIL (Inchangé)
  // ==========================================

  static Future<Map<String, dynamic>> loginUser(String phone, String pin) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone.trim(), "pincode": pin.trim()}),
      ).timeout(const Duration(seconds: 45));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        if (data['token'] != null) await saveToken(data['token']);
        return data;
      } else {
        throw Exception(data['message'] ?? "Identifiants incorrects");
      }
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
      if (res.statusCode == 409) throw Exception("Ce numéro est déjà enregistré");
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
    final res = await http.put(Uri.parse('$baseUrl/users/$userId'), headers: headers, body: jsonEncode({"fullname": fullname, "phone": phone}));
    if (res.statusCode != 200) throw Exception("Erreur de mise à jour");
  }

  static Future<void> resetPin(String phone, String newPin) async {
    final res = await http.post(Uri.parse('$baseUrl/users/reset-pin'), headers: {"Content-Type": "application/json"}, body: jsonEncode({"phone": phone, "new_pin": newPin})).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) throw Exception(jsonDecode(res.body)['message'] ?? 'Erreur réinitialisation PIN');
  }

  static Future<double> getUserBalance(int userId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/balance'), headers: headers);
    if (res.statusCode == 200) return double.tryParse(jsonDecode(res.body)['balance'].toString()) ?? 0.0;
    return 0.0;
  }

  static Future<int> getTrustScore(int userId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/trust-score'), headers: headers);
    if (res.statusCode == 200) {
      return int.tryParse(jsonDecode(res.body)['trust_score']?.toString() ?? '100') ?? 100;
    }
    return 100;
  }

  static Future<String> getRecipientName(String phone, String operator) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/users/check?phone=$phone&operator=$operator'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body)['fullname'];
    return "Destinataire inconnu";
  }

  // ==========================================
  // 2. FINANCE (Inchangé)
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
        'email': "user$userId@gcaisse.com",
        'name': name ?? "Membre G-Caisse",
      }),
    ).timeout(const Duration(seconds: 30));
    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['payment_url'] != null) return body;
    throw Exception(body['details'] ?? body['error'] ?? body['message'] ?? 'Erreur dépôt');
  }

  static Future<Map<String, dynamic>> processPayout({required int userId, required double amount, required String phone, required String name, String? channel}) async {
    final headers = await _authHeaders();
    final res = await http.post(Uri.parse('$baseUrl/payout'), headers: headers, body: jsonEncode({"user_id": userId, "amount": amount, "phone": phone, "name": name, "channel": channel ?? "cm.mobile"})).timeout(const Duration(seconds: 60));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return {...body, 'transfer_status': body['data']?['transfer']?['status'] ?? 'sent'};
    throw Exception(body['message'] ?? "Erreur retrait");
  }

  static Future<void> transferMoney(int senderId, String receiverPhone, double amount) async {
    final headers = await _authHeaders();
    final res = await http.post(Uri.parse('$baseUrl/transfer'), headers: headers, body: jsonEncode({"sender_id": senderId, "receiver_phone": receiverPhone, "amount": amount}));
    if (res.statusCode != 200) throw Exception("Erreur transfert");
  }

  static Future<Map<String, dynamic>> processDirectTransfer({required int senderId, required String receiverPhone, required double amount, required String operator}) async {
    final headers = await _authHeaders();
    final res = await http.post(Uri.parse('$baseUrl/transfer'), headers: headers, body: jsonEncode({"sender_id": senderId, "receiver_phone": receiverPhone, "amount": amount, "operator": operator}));
    if (res.statusCode == 200) return jsonDecode(res.body);
    final body = jsonDecode(res.body);
    throw Exception(body['message'] ?? "Échec transfert");
  }

  static Future<Map<String, dynamic>> initiateDirectTransfer({
    required int senderId, required String senderPhone, required String senderOperator,
    required String receiverPhone, required String receiverOperator, required double amount,
  }) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/transfer/direct'),
      headers: headers,
      body: jsonEncode({
        "sender_id": senderId, "sender_phone": senderPhone,
        "sender_operator": senderOperator,
        "receiver_phone": receiverPhone,
        "receiver_operator": receiverOperator,
        "amount": amount,
      }),
    ).timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) return jsonDecode(res.body);
    final body = jsonDecode(res.body);
    throw Exception(body['message'] ?? "Échec initiation transfert");
  }

  static Future<Map<String, dynamic>> getDirectTransferStatus(String reference) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/transfer/direct/status/$reference'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Statut introuvable");
  }

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
  // 3. SERVICES (Inchangé)
  // ==========================================

  static Future<Map<String, dynamic>> buyAirtimeOrData({required int userId, required String phoneNumber, required double amount, required String operator, required String type, String? plan}) async {
    final headers = await _authHeaders();
    final res = await http.post(Uri.parse('$baseUrl/services/airtime'), headers: headers, body: jsonEncode({"user_id": userId, "receiver_phone": phoneNumber, "amount": amount, "operator": operator, "service_type": type, "plan_validity": plan})).timeout(const Duration(seconds: 30));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? "Erreur recharge");
  }

  static Future<Map<String, dynamic>> checkAirtimeStatus(String paymentReference) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/services/airtime/status/$paymentReference'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Erreur statut");
  }

  static Future<Map<String, dynamic>> payBill({required int userId, required String contractNumber, required double amount, required String billType, required String phone, required String operator}) async {
    final headers = await _authHeaders();
    final res = await http.post(Uri.parse('$baseUrl/services/${billType.toLowerCase()}'), headers: headers, body: jsonEncode({"user_id": userId, "contract_number": contractNumber, "amount": amount, "phone": phone, "operator": operator})).timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) return jsonDecode(res.body);
    final body = jsonDecode(res.body);
    throw Exception(body['message'] ?? "Erreur facture");
  }

  static Future<Map<String, dynamic>> checkBillStatus(String paymentReference) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/services/bill/status/$paymentReference'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Erreur statut");
  }

  // ==========================================
  // 4. TONTINES & MESSAGERIE (CORRIGÉ)
  // ==========================================

  static Future<List<dynamic>> getTontines(int userId) async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(
        Uri.parse('$baseUrl/tontines?user_id=$userId'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data is List ? data : [];
      } else {
        debugPrint("Erreur serveur tontines: ${res.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Erreur réseau tontines: $e");
      return [];
    }
  }

  static Future<void> processTontinePayment({required int userId, required int tontineId, required double amount, bool isLate = false}) async {
    final headers = await _authHeaders();
    final res = await http.post(Uri.parse('$baseUrl/payments/tontine'), headers: headers, body: jsonEncode({"user_id": userId, "tontine_id": tontineId, "amount": amount, "is_late": isLate}));
    if (res.statusCode != 200) throw Exception("Échec paiement tontine");
  }

  // Payer le fond de caisse
  static Future<void> payCaisseFund({required int userId, required int tontineId, required double amount}) async {
    final headers = await _authHeaders();
    final res = await http.post(Uri.parse('$baseUrl/payments/caisse'), headers: headers,
        body: jsonEncode({"user_id": userId, "tontine_id": tontineId, "amount": amount}));
    if (res.statusCode != 200) throw Exception(jsonDecode(res.body)['message'] ?? 'Erreur fond de caisse');
  }

  // Déclencher le débit automatique (admin seulement)
  static Future<Map<String, dynamic>> autoDebit(int tontineId) async {
    final headers = await _authHeaders();
    final res = await http.post(Uri.parse('$baseUrl/tontines/$tontineId/auto-debit'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception(jsonDecode(res.body)['message'] ?? 'Erreur débit automatique');
  }

  // Statut d'un membre dans une tontine
  static Future<Map<String, dynamic>> getMemberStatus(int tontineId, int userId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/tontines/$tontineId/member-status/$userId'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return {};
  }

  // Classement des membres (qui reçoit quel mois)
  static Future<List<dynamic>> getTontineSchedule(int tontineId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/tontines/$tontineId/schedule'), headers: headers);
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  // Générer le classement (admin)
  static Future<void> generateSchedule(int tontineId) async {
    final headers = await _authHeaders();
    final res = await http.post(Uri.parse('$baseUrl/tontines/$tontineId/schedule'), headers: headers);
    if (res.statusCode != 200) throw Exception(jsonDecode(res.body)['message'] ?? 'Erreur classement');
  }

  // Total de la cagnotte du cycle actuel
  static Future<Map<String, dynamic>> getTontinesCagnotte(int tontineId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/tontines/$tontineId/cagnotte'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return {};
  }

  // Envoyer la cagnotte au bénéficiaire (admin)
  static Future<Map<String, dynamic>> sendCagnotte({
    required int tontineId,
    required int beneficiaryId,
    required String payoutMethod,
  }) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/tontines/$tontineId/payout'),
      headers: headers,
      body: jsonEncode({'beneficiary_id': beneficiaryId, 'payout_method': payoutMethod}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception(jsonDecode(res.body)['message'] ?? 'Erreur envoi cagnotte');
  }

  // Préparer les rappels WhatsApp
  static Future<Map<String, dynamic>> getWhatsAppReminders(int tontineId) async {
    final headers = await _authHeaders();
    final res = await http.post(Uri.parse('$baseUrl/tontines/$tontineId/whatsapp-reminder'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Erreur rappels');
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

  static Future<Map<String, dynamic>> createTontine(
    String name, int adminId, String freq, double amount, double commission, {
    String deadlineTime = '23:59',
    int deadlineDay = 28,
    bool hasCaisseFund = false,
    double caisseFundAmount = 0,
  }) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/tontines'),
      headers: headers,
      body: jsonEncode({
        "name": name, "admin_id": adminId, "frequency": freq,
        "amount": amount, "commission_rate": commission,
        "deadline_time": deadlineTime, "deadline_day": deadlineDay,
        "has_caisse_fund": hasCaisseFund, "caisse_fund_amount": caisseFundAmount,
      }),
    ).timeout(const Duration(seconds: 30));
    if (res.statusCode == 201 || res.statusCode == 200) return jsonDecode(res.body);
    final body = jsonDecode(res.body);
    throw Exception(body['error'] ?? body['message'] ?? body['detail'] ?? "Erreur lors de la création (${res.statusCode})");
  }

  static Future<Map<String, dynamic>> updateTontine(int tontineId, Map<String, dynamic> data) async {
    final headers = await _authHeaders();
    final res = await http.put(Uri.parse('$baseUrl/tontines/$tontineId'), headers: headers, body: jsonEncode(data));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Échec mise à jour");
  }

  static Future<List<dynamic>> getGroupMessages(int tontineId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/tontines/$tontineId/messages'), headers: headers);
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<void> sendMessage(int tontineId, int userId, String content) async {
    final headers = await _authHeaders();
    await http.post(Uri.parse('$baseUrl/tontines/$tontineId/messages'), headers: headers, body: jsonEncode({"user_id": userId, "content": content}));
  }

  static Future<void> sendVoiceMessage({required int tontineId, required int userId, required String filePath, required int durationSec}) async {
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/tontines/$tontineId/voice'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields['user_id'] = userId.toString();
    request.fields['duration_sec'] = durationSec.toString();
    request.files.add(await http.MultipartFile.fromPath('audio', filePath));
    final response = await request.send().timeout(const Duration(seconds: 30));
    if (response.statusCode != 201) throw Exception('Erreur upload vocal');
  }

  static Future<List<dynamic>> getAuctions(int tontineId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/tontines/$tontineId/auctions'), headers: headers);
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  // ==========================================
  // 5. ÉPARGNE, PRÊTS (Inchangé)
  // ==========================================

  static Future<double> getSavingsBalance(int userId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/savings'), headers: headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) {
        double total = 0;
        for (var goal in data) { total += double.tryParse(goal['current_amount']?.toString() ?? '0') ?? 0.0; }
        return total;
      }
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

  static Future<void> requestIslamicLoan(int userId, double amount, String purpose) async {
    final headers = await _authHeaders();
    await http.post(Uri.parse('$baseUrl/loans/islamic'), headers: headers, body: jsonEncode({"user_id": userId, "amount": amount, "purpose": purpose}));
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

  // Événements sociaux d'une tontine spécifique
  static Future<List<dynamic>> getTontineSocialEvents(int tontineId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/tontines/$tontineId/social/events'), headers: headers);
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  // Créer un événement social dans une tontine
  static Future<Map<String, dynamic>> createSocialEvent({
    required int tontineId,
    required int createdBy,
    required String eventType,
    required String description,
    required double targetAmount,
    String beneficiaryName = '',
  }) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/tontines/$tontineId/social/events'),
      headers: headers,
      body: jsonEncode({
        'event_type': eventType,
        'description': description,
        'target_amount': targetAmount,
        'created_by': createdBy,
        'beneficiary_name': beneficiaryName,
      }),
    );
    if (res.statusCode == 201) return jsonDecode(res.body);
    throw Exception(jsonDecode(res.body)['message'] ?? 'Erreur création événement');
  }

  static Future<void> makeDonation(int eventId, double amount, int userId) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/social/donate'),
      headers: headers,
      body: jsonEncode({"event_id": eventId, "amount": amount, "user_id": userId}),
    );
    if (res.statusCode != 200) throw Exception(jsonDecode(res.body)['message'] ?? 'Erreur don');
  }

  // ==========================================
  // 6. RADAR & ADMIN (Inchangé)
  // ==========================================

  static Future<void> updateFcmToken(int userId, String token) async {
    final headers = await _authHeaders();
    await http.put(Uri.parse('$baseUrl/users/$userId/fcm-token'), headers: headers, body: jsonEncode({"fcm_token": token}));
  }

  static Future<void> updateUserLocation(int userId, double lat, double lng) async {
    final headers = await _authHeaders();
    await http.post(Uri.parse('$baseUrl/users/$userId/location'), headers: headers, body: jsonEncode({"latitude": lat, "longitude": lng}));
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

  // ==========================================
  // 7. DÉPÔT PAR VIREMENT BANCAIRE
  // ==========================================

  static Future<Map<String, dynamic>> getBankInfo() async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/bank-deposit/info'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return {};
  }

  static Future<Map<String, dynamic>> declareBankDeposit({
    required int userId, required double amount, required String bankName, String senderName = '',
  }) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/bank-deposit'),
      headers: headers,
      body: jsonEncode({"user_id": userId, "amount": amount, "bank_name": bankName, "sender_name": senderName}),
    ).timeout(const Duration(seconds: 30));
    if (res.statusCode == 201) return jsonDecode(res.body);
    final body = jsonDecode(res.body);
    throw Exception(body['message'] ?? "Erreur déclaration virement");
  }

  static Future<List<dynamic>> getMyBankDeposits(int userId) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/bank-deposit/my?user_id=$userId'), headers: headers);
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<List<dynamic>> getPendingBankDeposits() async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/admin/bank-deposits?status=pending'), headers: headers);
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<void> validateBankDeposit(int depositId, {String note = ''}) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/admin/bank-deposits/$depositId/validate'),
      headers: headers,
      body: jsonEncode({"admin_note": note}),
    );
    if (res.statusCode != 200) throw Exception(jsonDecode(res.body)['message'] ?? "Erreur validation");
  }

  static Future<void> rejectBankDeposit(int depositId, {String note = ''}) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/admin/bank-deposits/$depositId/reject'),
      headers: headers,
      body: jsonEncode({"admin_note": note}),
    );
    if (res.statusCode != 200) throw Exception(jsonDecode(res.body)['message'] ?? "Erreur rejet");
  }
}