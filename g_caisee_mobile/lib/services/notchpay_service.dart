import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';

/// Service centralisé pour les paiements Notch Pay dans G-Caisse.
/// Utilise url_launcher pour ouvrir la page de paiement Notch Pay
/// et le polling backend pour confirmer le statut.
class NotchPayService {

  // ── DÉPÔT ────────────────────────────────────────────────────────────────

  /// Retourne la référence du paiement pour vérification ultérieure
  static Future<String> deposit({
    required BuildContext context,
    required int userId,
    required double amount,
    required String phone,
    required String name,
  }) async {
    final res = await ApiService.initiatePayment(userId, phone, amount, name: name);
    final paymentUrl = res['payment_url'] as String?;
    if (paymentUrl == null) throw Exception("URL de paiement manquante");

    final uri = Uri.parse(paymentUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Impossible d'ouvrir la page de paiement");
    }
    // Retourner la référence pour vérification du statut
    return res['reference'] as String? ?? '';
  }

  // ── RECHARGE AIRTIME / DATA ───────────────────────────────────────────────

  static Future<Map<String, dynamic>> buyAirtime({
    required BuildContext context,
    required int userId,
    required String receiverPhone,
    required double amount,
    required String operator,
    required String type,
    String? plan,
  }) async {
    return await ApiService.buyAirtimeOrData(
      userId: userId,
      phoneNumber: receiverPhone,
      amount: amount,
      operator: operator,
      type: type,
      plan: plan,
    );
  }

  // ── PAIEMENT FACTURE ──────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> payBill({
    required BuildContext context,
    required int userId,
    required String contractNumber,
    required double amount,
    required String billType,
    required String phone,
    required String operator,
  }) async {
    final res = await ApiService.payBill(
      userId: userId,
      contractNumber: contractNumber,
      amount: amount,
      billType: billType,
      phone: phone,
      operator: operator,
    );

    // Ouvrir la page de paiement Notch Pay
    final paymentUrl = res['payment_url'] as String?;
    if (paymentUrl != null) {
      final uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    return res;
  }
}
