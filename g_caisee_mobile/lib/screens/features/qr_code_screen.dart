import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_theme.dart';

class QrCodeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const QrCodeScreen({super.key, required this.userData});

  @override
  State<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // Données encodées dans le QR : gcaisse://pay?phone=6XX&name=Nom
  String get _qrData =>
      'gcaisse://pay?phone=${widget.userData['phone']}&name=${Uri.encodeComponent(widget.userData['fullname'] ?? 'Membre')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textLight,
        title: const Text('QR Code Paiement',
            style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_2_rounded), text: 'Mon QR'),
            Tab(icon: Icon(Icons.qr_code_scanner_rounded), text: 'Scanner'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildMyQr(),
          _buildScanner(),
        ],
      ),
    );
  }

  // ── Mon QR Code ──────────────────────────────────────────

  Widget _buildMyQr() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Faites scanner ce code\npour recevoir un paiement',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 32),

          // QR Code
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: AppTheme.primaryShadow,
            ),
            child: Column(
              children: [
                QrImageView(
                  data: _qrData,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppTheme.dark,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppTheme.dark,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.userData['fullname'] ?? 'Membre G-Caisse',
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.userData['phone']?.toString() ?? '',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Votre QR code est unique. Ne le partagez qu\'avec des personnes de confiance.',
                    style: TextStyle(color: AppTheme.primary, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Scanner QR ───────────────────────────────────────────

  Widget _buildScanner() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              MobileScanner(
                onDetect: (capture) {
                  final barcode = capture.barcodes.firstOrNull;
                  if (barcode?.rawValue == null) return;
                  _handleScannedQr(barcode!.rawValue!);
                },
              ),
              // Overlay de visée
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primary, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          color: AppTheme.darkCard,
          child: const Text(
            'Pointez la caméra vers le QR Code G-Caisse\ndu destinataire pour initier un paiement',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5),
          ),
        ),
      ],
    );
  }

  void _handleScannedQr(String rawValue) {
    if (!rawValue.startsWith('gcaisse://pay')) return;

    final uri = Uri.parse(rawValue);
    final phone = uri.queryParameters['phone'] ?? '';
    final name  = Uri.decodeComponent(uri.queryParameters['name'] ?? 'Destinataire');

    if (phone.isEmpty) return;

    // Afficher le dialog de paiement
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PaymentSheet(
        receiverPhone: phone,
        receiverName: name,
        senderData: widget.userData,
      ),
    );
  }
}

// ── Sheet de paiement après scan ─────────────────────────────────────────────

class _PaymentSheet extends StatefulWidget {
  final String receiverPhone;
  final String receiverName;
  final Map<String, dynamic> senderData;

  const _PaymentSheet({
    required this.receiverPhone,
    required this.receiverName,
    required this.senderData,
  });

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _amountCtrl = TextEditingController();
  bool _isLoading   = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) return;

    setState(() => _isLoading = true);
    try {
      // TODO: appeler ApiService.transferMoney quand le destinataire est vérifié
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${amount.toInt()} FCFA envoyés à ${widget.receiverName} ✅'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception:', '').trim()),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          // Destinataire
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                child: Text(
                  widget.receiverName.isNotEmpty ? widget.receiverName[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.receiverName,
                      style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w700, fontSize: 16)),
                  Text(widget.receiverPhone,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(color: AppTheme.textLight, fontSize: 28, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '0 FCFA',
              hintStyle: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.4), fontSize: 28),
              filled: true,
              fillColor: AppTheme.darkSurface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _isLoading ? null : _send,
            style: AppTheme.primaryButton,
            child: _isLoading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('ENVOYER'),
          ),
        ],
      ),
    );
  }
}
