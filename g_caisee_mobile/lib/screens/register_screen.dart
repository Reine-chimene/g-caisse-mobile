import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _pinCtrl    = TextEditingController();
  final _referralCtrl = TextEditingController();
  bool  _isLoading  = false;
  bool  _obscurePin = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.registerUser(
        _nameCtrl.text.trim(),
        _phoneCtrl.text.trim(),
        _pinCtrl.text.trim(),
        referralCode: _referralCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Compte créé avec succès ! Connectez-vous.'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception:', '').trim()),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Titre
                const Text(
                  'Créer un compte',
                  style: TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Rejoignez la communauté G-Caisse en quelques secondes.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 15, height: 1.4),
                ),

                const SizedBox(height: 36),

                // Nom complet
                _label('Nom complet'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: AppTheme.textLight, fontSize: 16),
                  decoration: AppTheme.fieldDecoration(
                    hint: 'Ex: Reine Ngono',
                    icon: Icons.person_outline_rounded,
                    isDark: true,
                  ),
                  validator: (v) => v!.trim().isEmpty ? 'Champ obligatoire' : null,
                ),

                const SizedBox(height: 20),

                // Téléphone
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
                  validator: (v) => v!.length < 9 ? 'Numéro invalide' : null,
                ),

                const SizedBox(height: 20),

                // PIN
                _label('Créer un code PIN secret'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _pinCtrl,
                  obscureText: _obscurePin,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 22,
                    letterSpacing: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: AppTheme.fieldDecoration(
                    hint: '••••',
                    icon: Icons.lock_outline_rounded,
                    isDark: true,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppTheme.textMuted, size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePin = !_obscurePin),
                    ),
                  ),
                  validator: (v) => v!.length != 4 ? 'PIN à 4 chiffres requis' : null,
                ),

                const SizedBox(height: 12),

                // Info PIN
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 16),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Mémorisez bien votre PIN. Il sera nécessaire pour chaque connexion.',
                          style: TextStyle(color: AppTheme.primary, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Code parrainage (optionnel)
                _label('Code parrainage (optionnel)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _referralCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: AppTheme.textLight, fontSize: 16, letterSpacing: 3),
                  decoration: AppTheme.fieldDecoration(
                    hint: 'Ex: GC00042',
                    icon: Icons.card_giftcard_outlined,
                    isDark: true,
                  ),
                ),

                const SizedBox(height: 36),

                // Bouton
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: AppTheme.primaryShadow,
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: AppTheme.primaryButton,
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text("S'INSCRIRE"),
                  ),
                ),

                const SizedBox(height: 28),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Déjà un compte ? ',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 15)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Se connecter',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
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
