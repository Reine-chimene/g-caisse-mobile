import 'dart:convert';
import 'package:flutter/foundation.dart'; // Nécessaire pour debugPrint
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://g-caisse-api.onrender.com/api';

  // ✅ AJOUT : Créer l'intention de paiement Stripe
  static Future<String> createStripePaymentIntent(int userId, double amount) async {
    final res = await http.post(
      Uri.parse('$baseUrl/create-payment-intent'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "amount": (amount * 100).toInt(), // Stripe travaille en centimes
        "currency": "eur" // ou "usd" selon ton compte Stripe test
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['clientSecret']; // C'est ce code que le SDK Stripe utilisera
    } else {
      throw Exception("Erreur lors de la création du paiement par carte");
    }
  }

  static Future<Map<String, dynamic>> loginUser(String phone, String pin) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phone": phone, "pincode": pin}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Identifiants incorrects");
  }

  static Future<void> registerUser(String name, String phone, String pin) async {
    final res = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "fullname": name, 
        "phone": phone, 
        "pincode": pin
      }),
    );
    if (res.statusCode != 201) throw Exception("Erreur d'inscription");
  }

  // ==========================================
  // NOUVELLES MÉTHODES (TRANSFERT, DÉPÔT, PROFIL)
  // ==========================================

  static Future<void> updateProfile(int userId, String fullname, String phone) async {
    final res = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"fullname": fullname, "phone": phone}),
    );
    if (res.statusCode != 200) throw Exception("Erreur de mise à jour du profil");
  }

  static Future<void> transferMoney(int senderId, String receiverPhone, double amount) async {
    final res = await http.post(
      Uri.parse('$baseUrl/transfer'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "sender_id": senderId,
        "receiver_phone": receiverPhone,
        "amount": amount
      }),
    );
    if (res.statusCode != 200) {
      var errorData = jsonDecode(res.body);
      throw Exception(errorData['message'] ?? "Erreur lors du transfert");
    }
  }

  static Future<void> depositMoney(int userId, double amount) async {
    final res = await http.post(
      Uri.parse('$baseUrl/deposit'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "amount": amount}),
    );
    if (res.statusCode != 200) throw Exception("Erreur lors du dépôt");
  }

  // ==========================================
  // TONTINES, MESSAGES & AUTRES
  // ==========================================

  static Future<List<dynamic>> getTontines(int userId) async {
    try {
      debugPrint("=== APPEL API : Récupération des tontines pour le User ID: $userId ===");
      final res = await http.get(Uri.parse('$baseUrl/tontines?user_id=$userId'));
      
      debugPrint("=== REPONSE API STATUT : ${res.statusCode} ===");
      debugPrint("=== REPONSE API BODY : ${res.body} ===");

      if (res.statusCode == 200) {
         final decodedData = jsonDecode(res.body);
         if (decodedData is List) {
             return decodedData;
         } else if (decodedData is Map && decodedData.containsKey('data')) {
             return decodedData['data'];
         } else {
             debugPrint("=== ERREUR: Le format de réponse n'est pas une liste. ===");
             return [];
         }
      }
      return [];
    } catch (e) {
      debugPrint("=== ERREUR API getTontines : $e ===");
      return [];
    }
  }

  static Future<Map<String, dynamic>> createTontine(String name, int adminId, String freq, double amount, double commission) async {
    final res = await http.post(
      Uri.parse('$baseUrl/tontines'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name, 
        "admin_id": adminId, 
        "frequency": freq, 
        "amount": amount, 
        "commission_rate": commission
      }),
    );
    if (res.statusCode == 201) return jsonDecode(res.body);
    throw Exception("Erreur lors de la création");
  }

  static Future<List<dynamic>> getTontineMembers(int tontineId) async {
    final res = await http.get(Uri.parse('$baseUrl/tontines/$tontineId/members'));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<void> leaveTontine(int tontineId, int userId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/tontines/$tontineId/leave'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId}), 
    );
    if (res.statusCode != 200) {
      throw Exception("Erreur lors de la sortie de la tontine");
    }
  }

  static Future<double> getUserBalance(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/balance'));
    if (res.statusCode == 200) {
      return double.parse(jsonDecode(res.body)['balance'].toString());
    }
    return 0.0;
  }

  static Future<List<dynamic>> getSavingGoals(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/savings'));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<List<dynamic>> getGroupMessages(int tontineId) async {
    final res = await http.get(Uri.parse('$baseUrl/tontines/$tontineId/messages'));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<void> sendMessage(int tontineId, int userId, String content) async {
    await http.post(
      Uri.parse('$baseUrl/tontines/$tontineId/messages'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "content": content}),
    );
  }

  static Future<Map<String, dynamic>> initiatePayment(String phone, double amount, {String? name, String? email}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pay'), 
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'phone': phone,
        'amount': amount,
        'name': name ?? "Membre G-CAISE",
        'email': email ?? "contact@g-caise.cm"
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      var errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Échec de la communication avec le serveur');
    }
  }

  static Future<List<dynamic>> getAuctions(int tontineId) async {
    final res = await http.get(Uri.parse('$baseUrl/tontines/$tontineId/auctions'));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<List<dynamic>> getMembersLocations() async {
    final res = await http.get(Uri.parse('$baseUrl/users/locations'));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<double> getSocialFund() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/social/fund'));
      if (res.statusCode == 200) {
        return double.parse(jsonDecode(res.body)['total'].toString());
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  static Future<List<dynamic>> getSocialEvents() async {
    final res = await http.get(Uri.parse('$baseUrl/social/events'));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<void> makeDonation(int eventId, double amount) async {
    final res = await http.post(
      Uri.parse('$baseUrl/social/donate'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"event_id": eventId, "amount": amount}),
    );
    if (res.statusCode != 200) throw Exception("Erreur lors du don");
  }

  static Future<void> triggerWhatsappReminder(int tontineId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/tontines/$tontineId/notify-whatsapp'),
      headers: {"Content-Type": "application/json"},
    );
    if (res.statusCode != 200) throw Exception("Erreur d'envoi WhatsApp");
  }

  static Future<double> getSavingsBalance(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/savings'));
    if (res.statusCode == 200) {
      List data = jsonDecode(res.body);
      double total = 0;
      for (var goal in data) {
        total += double.tryParse(goal['current_amount'].toString()) ?? 0.0;
      }
      return total;
    }
    return 0.0;
  }

  static Future<void> depositToSavings(int userId, double amount) async {
    final res = await http.post(
      Uri.parse('$baseUrl/deposit'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "amount": amount}),
    );
    if (res.statusCode != 200) throw Exception("Échec du dépôt d'épargne");
  }

  static Future<List<dynamic>> getSavingsTransactions(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/transactions'));
    if (res.statusCode == 200) {
      List allTxs = jsonDecode(res.body);
      return allTxs.where((tx) => tx['type'] == 'deposit' || tx['type'] == 'saving').toList();
    }
    return [];
  }

  static Future<void> requestIslamicLoan(int userId, double amount, String purpose) async {
    final res = await http.post(
      Uri.parse('$baseUrl/loans/islamic'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "amount": amount,
        "purpose": purpose
      }),
    );
    if (res.statusCode != 201) throw Exception("Échec de la demande de prêt");
  }

  static Future<List<dynamic>> getTransactions(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/transactions'));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<int> getTrustScore(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/trust-score'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['trust_score'];
    }
    return 0;
  }

  static Future<List<dynamic>> getUserTransactions(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/transactions'));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<Map<String, dynamic>> createStripeIntent(double amount) async {
    final res = await http.post(
      Uri.parse('$baseUrl/create-payment-intent'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"amount": (amount * 100).toInt()}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Erreur Stripe");
  }

  static Future<Map<String, dynamic>> getAdminStats() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/stats'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return {"total_fees": 0, "total_volume": 0, "user_count": 0};
  }

  // ==========================================
  // ✅ AJOUTS POUR LE RADAR (GÉOLOCALISATION)
  // ==========================================

  static Future<void> updateUserLocation(int userId, double lat, double lng) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/users/$userId/location'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"latitude": lat, "longitude": lng}),
      );
    } catch (e) {
      debugPrint("Erreur mise à jour localisation: $e");
    }
  }

  static Future<List<dynamic>> getTontineMembersLocations(int tontineId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/tontines/$tontineId/locations'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (e) {
      debugPrint("Erreur récupération positions membres: $e");
      return [];
    }
  }
}