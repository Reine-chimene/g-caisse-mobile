import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://g-caisse-api.onrender.com/api';

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

  static Future<List<dynamic>> getTontines() async {
    final res = await http.get(Uri.parse('$baseUrl/tontines'));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  static Future<void> createTontine(String name, int adminId, String freq, double amount, double commission) async {
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
    if (res.statusCode != 201) throw Exception("Erreur lors de la création");
  }

  static Future<List<dynamic>> getTontineMembers(int tontineId) async {
    final res = await http.get(Uri.parse('$baseUrl/tontines/$tontineId/members'));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
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
        'name': name ?? "Membre G-Caisse",
        'email': email ?? "client@g-caisse.cm"
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
}