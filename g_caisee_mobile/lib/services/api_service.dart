import 'dart:convert';
import 'dart:async'; // Ajouté pour le Timeout
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
      ).timeout(const Duration(seconds: 45)); // Correction : Attendre le réveil de Render

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return data; // Retourne l'objet user pour la navigation
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
      return double.parse(jsonDecode(res.body)['balance'].toString());
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

  static Future<Map<String, dynamic>> initiatePayment(String phone, double amount, {String? name, String? email}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pay'), 
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'phone': phone,
        'amount': amount,
        'name': name ?? "Membre",
        'email': email ?? "contact@g-caise.cm"
      }),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(response.statusCode == 400 ? jsonDecode(response.body)['message'] : 'Erreur NotchPay');
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
      body: jsonEncode({"user_id": userId, "amount": amount}),
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

  static Future<Map<String, dynamic>> buyAirtime({required int userId, required String phone, required double amount, required String operator}) async {
    final res = await http.post(Uri.parse('$baseUrl/services/airtime'), headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "receiver_phone": phone, "amount": amount, "operator": operator}),
    );
    return res.statusCode == 200 ? jsonDecode(res.body) : throw Exception("Erreur Airtime");
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
    final res = await http.get(Uri.parse('$baseUrl/tontines?user_id=$userId'));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
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
      body: jsonEncode({"name": name, "admin_id": adminId, "frequency": freq, "amount": amount, "commission_rate": commission}),
    );
    return res.statusCode == 201 ? jsonDecode(res.body) : throw Exception("Erreur");
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
      body: jsonEncode({"user_id": userId, "amount": amount}),
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

  static Future<String> createStripePaymentIntent(int userId, double amount) async {
    final res = await http.post(Uri.parse('$baseUrl/create-payment-intent'), headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "amount": (amount * 100).toInt(), "currency": "eur"}),
    );
    return res.statusCode == 200 ? jsonDecode(res.body)['clientSecret'] : throw Exception("Stripe Error");
  }
}