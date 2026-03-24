import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://g-caisse-api.onrender.com/api';

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
    final res = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"fullname": name, "phone": phone, "pincode": pin}),
    );
    if (res.statusCode != 201) throw Exception("Erreur d'inscription");
  }

  static Future<void> updateProfile(int userId, String fullname, String phone) async {
    final res = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"fullname": fullname, "phone": phone}),
    );
    if (res.statusCode != 200) throw Exception("Erreur de mise à jour");
  }

  static Future<double> getUserBalance(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/balance'));
    if (res.statusCode == 200) {
      // Correction : tryParse pour éviter les erreurs de format
      return double.tryParse(jsonDecode(res.body)['balance'].toString()) ?? 0.0;
    }
    return 0.0;
  }

  static Future<int> getTrustScore(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/trust-score'));
    if (res.statusCode == 200) return jsonDecode(res.body)['trust_score'];
    return 100;
  }

  static Future<String> getRecipientName(String phone, String operator) async {
    final res = await http.get(Uri.parse('$baseUrl/users/check?phone=$phone&operator=$operator'));
    if (res.statusCode == 200) return jsonDecode(res.body)['fullname'];
    return "Destinataire inconnu";
  }

  // ==========================================
  // 2. FINANCE (NOTCH PAY, TRANSFERTS, DEPÔTS)
  // ==========================================

  static Future<Map<String, dynamic>> initiatePayment(int userId, String phone, double amount, {String? name}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/deposit'), 
      headers: {"Content-Type": "application/json"},
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
    final res = await http.post(
      Uri.parse('$baseUrl/payout'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "amount": amount,
        "phone": phone,
        "name": name,
        "channel": channel ?? "cm.mobile"
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? "Erreur lors du retrait");
    }
  }

  static Future<void> transferMoney(int senderId, String receiverPhone, double amount) async {
    final res = await http.post(
      Uri.parse('$baseUrl/transfer'),
      headers: {"Content-Type": "application/json"},
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
    final res = await http.post(
      Uri.parse('$baseUrl/transfer'),
      headers: {"Content-Type": "application/json"},
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

  static Future<void> depositMoney(int userId, double amount) async {
    final res = await http.post(
      Uri.parse('$baseUrl/deposit'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId, 
        "amount": amount,
        "email": "user$userId@gcaisse.com", // Ajout pour cohérence Notch Pay
        "name": "Membre G-Caisse"           // Ajout pour cohérence Notch Pay
      }),
    );
    if (res.statusCode != 200) throw Exception("Erreur dépôt");
  }

  static Future<List<dynamic>> getUserTransactions(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/transactions'));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<Map<String, dynamic>> getTransactionReceipt(int transactionId) async {
    final res = await http.get(Uri.parse('$baseUrl/transactions/$transactionId/receipt'));
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
    final res = await http.post(
      Uri.parse('$baseUrl/services/airtime'), 
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId, 
        "receiver_phone": phoneNumber, 
        "amount": amount, 
        "operator": operator,
        "service_type": type, 
        "plan_validity": plan 
      }),
    );
    
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? "Erreur lors de l'opération");
    }
  }

  static Future<Map<String, dynamic>> payBill({required int userId, required String contractNumber, required double amount, required String billType}) async {
    final res = await http.post(Uri.parse('$baseUrl/services/${billType.toLowerCase()}'), headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "contract_number": contractNumber, "amount": amount}),
    );
    return res.statusCode == 200 ? jsonDecode(res.body) : throw Exception("Erreur Facture");
  }

  // ==========================================
  // 4. TONTINES & MESSAGERIE
  // ==========================================

  static Future<List<dynamic>> getTontines(int userId) async {
    // Correction : On ajoute le user_id en paramètre de requête pour le backend
    final res = await http.get(Uri.parse('$baseUrl/tontines?user_id=$userId'));
    
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data;
      }
      return [];
    } else {
      print("Erreur serveur tontines: ${res.statusCode}");
      return [];
    }
  }

  static Future<void> processTontinePayment({required int userId, required int tontineId, required double amount, bool isLate = false}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/payments/tontine'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "tontine_id": tontineId, "amount": amount, "is_late": isLate}),
    );
    if (res.statusCode != 200) throw Exception("Échec du paiement tontine");
  }

  static Future<Map<String, dynamic>?> getCurrentWinner(int tontineId) async {
    final res = await http.get(Uri.parse('$baseUrl/tontines/$tontineId/winner'));
    return res.statusCode == 200 ? jsonDecode(res.body) : null;
  }

  static Future<List<dynamic>> getTontineMembers(int tontineId) async {
    final res = await http.get(Uri.parse('$baseUrl/tontines/$tontineId/members'));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<Map<String, dynamic>> createTontine(String name, int adminId, String freq, double amount, double commission) async {
    final res = await http.post(Uri.parse('$baseUrl/tontines'), headers: {"Content-Type": "application/json"},
      // Correction : amount_to_pay pour correspondre à ta table SQL
      body: jsonEncode({
        "name": name, 
        "admin_id": adminId, 
        "frequency": freq, 
        "amount_to_pay": amount, // Correction appliquée selon votre note SQL
        "commission_rate": commission
      }),
    );
    return res.statusCode == 201 ? jsonDecode(res.body) : throw Exception("Erreur lors de la création");
  }

  static Future<List<dynamic>> getGroupMessages(int tontineId) async {
    final res = await http.get(Uri.parse('$baseUrl/tontines/$tontineId/messages'));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<void> sendMessage(int tontineId, int userId, String content) async {
    await http.post(Uri.parse('$baseUrl/tontines/$tontineId/messages'), headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "content": content}),
    );
  }

  static Future<List<dynamic>> getAuctions(int tontineId) async {
    final res = await http.get(Uri.parse('$baseUrl/tontines/$tontineId/auctions'));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  // ==========================================
  // 5. ÉPARGNE, PRÊTS & SOCIAL
  // ==========================================

  static Future<double> getSavingsBalance(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/savings'));
    if (res.statusCode == 200) {
      List data = jsonDecode(res.body);
      double total = 0;
      for (var goal in data) { total += double.tryParse(goal['current_amount'].toString()) ?? 0.0; }
      return total;
    }
    return 0.0;
  }

  static Future<List<dynamic>> getSavingsTransactions(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/transactions'));
    if (res.statusCode == 200) {
      List allTxs = jsonDecode(res.body);
      return allTxs.where((tx) => tx['type'] == 'deposit' || tx['type'] == 'saving').toList();
    }
    return [];
  }

  static Future<void> depositToSavings(int userId, double amount) async {
    await http.post(Uri.parse('$baseUrl/deposit'), headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId, 
        "amount": amount,
        "email": "user$userId@gcaisse.com", // Ajout pour cohérence Notch Pay
        "name": "Épargne G-Caisse"          // Ajout pour cohérence Notch Pay
      }),
    );
  }

  static Future<void> requestIslamicLoan(int userId, double amount, String purpose) async {
    await http.post(Uri.parse('$baseUrl/loans/islamic'), headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "amount": amount, "purpose": purpose}),
    );
  }

  static Future<double> getSocialFund() async {
    final res = await http.get(Uri.parse('$baseUrl/social/fund'));
    return res.statusCode == 200 ? double.parse(jsonDecode(res.body)['total'].toString()) : 0.0;
  }

  static Future<List<dynamic>> getSocialEvents() async {
    final res = await http.get(Uri.parse('$baseUrl/social/events'));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<void> makeDonation(int eventId, double amount) async {
    await http.post(Uri.parse('$baseUrl/social/donate'), headers: {"Content-Type": "application/json"},
      body: jsonEncode({"event_id": eventId, "amount": amount}),
    );
  }

  // ==========================================
  // 6. RADAR & ADMIN
  // ==========================================

  static Future<void> updateUserLocation(int userId, double lat, double lng) async {
    await http.post(Uri.parse('$baseUrl/users/$userId/location'), headers: {"Content-Type": "application/json"},
      body: jsonEncode({"latitude": lat, "longitude": lng}),
    );
  }

  static Future<List<dynamic>> getTontineMembersLocations(int tontineId) async {
    final res = await http.get(Uri.parse('$baseUrl/tontines/$tontineId/locations'));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<Map<String, dynamic>> getAdminStats() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/stats'));
    return res.statusCode == 200 ? jsonDecode(res.body) : {"total_fees": 0, "total_volume": 0};
  }
}