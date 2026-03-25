import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final _phoneCtrl   = TextEditingController();
  final _newPinCtrl  = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLoading    = false;
  bool _obscureNew   = true;
  bool _obscureConf  = true;
  int  _step         = 1; // 1 = saisir téléphone, 2 = nouveau PIN

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _newPinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyPhone() async {
    if (_phoneCtrl.text.trim().length < 9) {
      _showMsg('Entrez un numéro valide', AppTheme.error);
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Vérifier que le numéro existe dans la base
      final name = await ApiService.getRecipientName(_phoneCtrl.text.trim(), '');
      if (name == 'Destinataire inconnu') {
        _showMsg('Numéro introuvable dans G-Caisse', AppTheme.error);
      } else {
        setState(() => _step = 2);
      }
    } catch (e) {
      _showMsg('Numéro introuvable dans G-Caisse', AppTheme.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPin() async {
    if (_newPinCtrl.text.length != 4) {
      _showMsg('Le PIN doit contenir 4 chiffres', AppTheme.error);
      return;
    }
    if (_newPinCtrl.text != _confirmCtrl.text) {
      _showMsg('Les PINs ne correspondent pas', AppTheme.error);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiService.resetPin(_phoneCtrl.text.trim(), _newPinCtrl.text.trim());
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) _showMsg(e.toString().replaceAll('Exception:', '').trim(), AppTheme.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(m),
      backgroundColor: c,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 50),
            ),
            const SizedBox(height: 20),
            const Text('PIN réinitialisé !',
                style: TextStyle(color: AppTheme.textLight, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Votre nouveau PIN a été enregistré avec succès.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: AppTheme.primaryButton,
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('SE CONNECTER'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textLight, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Icône
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.lock_reset_rounded, color: AppTheme.primary, size: 32),
              ),
              const SizedBox(height: 24),

              Text(
                _step == 1 ? 'PIN oublié ?' : 'Nouveau PIN',
                style: const TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _step == 1
                    ? 'Entrez votre numéro de téléphone pour réinitialiser votre PIN.'
                    : 'Choisissez un nouveau PIN à 4 chiffres pour votre compte.',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 15, height: 1.5),
              ),

              const SizedBox(height: 40),

              if (_step == 1) ...[
                // Étape 1 : numéro de téléphone
                _label('Numéro de téléphone'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: AppTheme.textLight, fontSize: 16),
                  decoration: AppTheme.fieldDecoration(
                    hint: '6XX XXX XXX',
                    icon: Icons.phone_android_rounded,
                    isDark: true,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: AppTheme.primaryShadow,
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyPhone,
                    style: AppTheme.primaryButton,
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('VÉRIFIER MON NUMÉRO'),
                  ),
                ),
              ] else ...[
                // Étape 2 : nouveau PIN
                // Indicateur de numéro vérifié
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.success.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: AppTheme.success, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Numéro vérifié : ${_phoneCtrl.text}',
                        style: const TextStyle(color: AppTheme.success, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _label('Nouveau PIN'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _newPinCtrl,
                  obscureText: _obscureNew,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  style: const TextStyle(
                    color: AppTheme.textLight, fontSize: 22,
                    letterSpacing: 10, fontWeight: FontWeight.w700,
                  ),
                  decoration: AppTheme.fieldDecoration(
                    hint: '••••',
                    icon: Icons.lock_outline_rounded,
                    isDark: true,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppTheme.textMuted, size: 20,
                      ),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _label('Confirmer le PIN'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConf,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  style: const TextStyle(
                    color: AppTheme.textLight, fontSize: 22,
                    letterSpacing: 10, fontWeight: FontWeight.w700,
                  ),
                  decoration: AppTheme.fieldDecoration(
                    hint: '••••',
                    icon: Icons.lock_outline_rounded,
                    isDark: true,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureConf ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppTheme.textMuted, size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConf = !_obscureConf),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: AppTheme.primaryShadow,
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPin,
                    style: AppTheme.primaryButton,
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('ENREGISTRER LE NOUVEAU PIN'),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: AppTheme.textMuted, fontSize: 13,
      fontWeight: FontWeight.w600, letterSpacing: 0.3,
    ),
  );
}
