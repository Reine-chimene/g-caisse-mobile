import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../services/api_service.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'forgot_pin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _pinCtrl   = TextEditingController();
  bool _isLoading          = false;
  bool _obscurePin         = true;
  bool _biometricAvailable = false;
  List<BiometricType> _biometricTypes = [];

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    final available = await BiometricService.isAvailable();
    final enabled   = await BiometricService.isBiometricEnabled();
    final types     = await BiometricService.getAvailableTypes();
    if (mounted) {
      setState(() {
        _biometricAvailable = available && enabled;
        _biometricTypes = types;
      });
    }
    if (_biometricAvailable) _loginWithBiometric();
  }

  IconData get _biometricIcon {
    if (_biometricTypes.contains(BiometricType.face)) return Icons.face_unlock_outlined;
    return Icons.fingerprint_rounded;
  }

  String get _biometricLabel {
    if (_biometricTypes.contains(BiometricType.face) &&
        _biometricTypes.contains(BiometricType.fingerprint)) return 'Empreinte ou Face ID';
    if (_biometricTypes.contains(BiometricType.face)) return 'Connexion Face ID';
    return 'Connexion par empreinte';
  }

  Future<void> _loginWithBiometric() async {
    final credentials = await BiometricService.getCredentials();
    if (credentials == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Connectez-vous d\'abord avec votre PIN pour activer la biométrie'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }
    final reason = _biometricTypes.contains(BiometricType.face)
        ? 'Utilisez Face ID pour accéder à G-Caisse'
        : 'Utilisez votre empreinte pour accéder à G-Caisse';

    final authenticated = await BiometricService.authenticate(reason: reason);
    if (!authenticated || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final result = await ApiService.loginUser(credentials['phone']!, credentials['pin']!);
      if (mounted) {
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => HomeScreen(userData: result)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception:', '').trim()),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.loginUser(
        _phoneCtrl.text.trim(), _pinCtrl.text.trim());
      if (mounted) {
        await BiometricService.saveCredentials(
          _phoneCtrl.text.trim(), _pinCtrl.text.trim());
        final available = await BiometricService.isAvailable();
        if (available) await BiometricService.setBiometricEnabled(true);
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => HomeScreen(userData: result)));
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
      body: Stack(
        children: [
          Positioned(top: -80, right: -60,
            child: Container(width: 250, height: 250,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.08)))),
          Positioned(top: -40, right: 40,
            child: Container(width: 120, height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.12)))),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 50),
                    // Logo
                    Row(children: [
                      Container(width: 48, height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          image: const DecorationImage(
                            image: AssetImage('assets/logo.jpeg'), fit: BoxFit.cover))),
                      const SizedBox(width: 12),
                      const Text('G-CAISSE', style: TextStyle(
                        color: AppTheme.primary, fontSize: 22,
                        fontWeight: FontWeight.w900, letterSpacing: 3)),
                    ]),
                    const SizedBox(height: 50),
                    const Text('Bon retour !', style: TextStyle(
                      color: AppTheme.textLight, fontSize: 34,
                      fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    const Text('Connectez-vous pour accéder à votre compte',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 15)),
                    const SizedBox(height: 40),

                    // ── Bouton biométrique principal ──
                    if (_biometricAvailable) ...[
                      _buildBiometricButton(),
                      const SizedBox(height: 24),
                      Row(children: [
                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('ou avec le PIN', style: TextStyle(
                            color: AppTheme.textMuted.withValues(alpha: 0.6), fontSize: 13))),
                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
                      ]),
                      const SizedBox(height: 24),
                    ],

                    // Téléphone
                    _label('Numéro de téléphone'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: AppTheme.textLight, fontSize: 16),
                      decoration: AppTheme.fieldDecoration(
                        hint: '6XX XXX XXX', icon: Icons.phone_android_rounded, isDark: true),
                      validator: (v) => v!.isEmpty ? 'Entrez votre numéro' : null,
                    ),
                    const SizedBox(height: 20),

                    // PIN
                    _label('Code PIN'),
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
                        color: AppTheme.textLight, fontSize: 22,
                        letterSpacing: 10, fontWeight: FontWeight.w700),
                      decoration: AppTheme.fieldDecoration(
                        hint: '••••', icon: Icons.lock_outline_rounded, isDark: true,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppTheme.textMuted, size: 20),
                          onPressed: () => setState(() => _obscurePin = !_obscurePin),
                        ),
                      ),
                      validator: (v) => v!.length < 4 ? 'PIN à 4 chiffres requis' : null,
                    ),

                    // PIN oublié
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ForgotPinScreen())),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 8)),
                        child: const Text('PIN oublié ?',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Bouton connexion PIN
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        boxShadow: AppTheme.primaryShadow),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: AppTheme.primaryButton,
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('SE CONNECTER'),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Row(children: [
                      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('ou', style: TextStyle(
                          color: AppTheme.textMuted.withValues(alpha: 0.6), fontSize: 13))),
                      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
                    ]),
                    const SizedBox(height: 24),

                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Pas encore de compte ? ',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 15)),
                          GestureDetector(
                            onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen())),
                            child: const Text('Créer un compte', style: TextStyle(
                              color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 15)),
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
        ],
      ),
    );
  }

  Widget _buildBiometricButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _loginWithBiometric,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppTheme.primary.withValues(alpha: 0.15),
            AppTheme.primary.withValues(alpha: 0.08),
          ]),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
        ),
        child: Column(children: [
          Icon(_biometricIcon, color: AppTheme.primary, size: 44),
          const SizedBox(height: 10),
          Text(_biometricLabel, style: const TextStyle(
            color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Text('Appuyez pour vous connecter', style: TextStyle(
            color: AppTheme.textMuted.withValues(alpha: 0.7), fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(
    color: AppTheme.textMuted, fontSize: 13,
    fontWeight: FontWeight.w600, letterSpacing: 0.3));
}
