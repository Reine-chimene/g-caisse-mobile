import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../main.dart' show themeNotifier;
import 'login_screen.dart';
import 'forgot_pin_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const ProfileScreen({super.key, this.userData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool   _isDark             = false;
  bool   _pushNotifications  = true;
  double _balance            = 0.0;
  int    _trustScore         = 0;
  bool   _isLoading          = true;
  File?  _imageFile;

  late String _fullname;
  late String _phone;

  @override
  void initState() {
    super.initState();
    _fullname = widget.userData?['fullname'] ?? 'Membre G-Caisse';
    _phone    = widget.userData?['phone']    ?? '+237 ---';
    _loadSettings();
    _loadData();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDark = prefs.getBool('isDarkMode') ?? false);
  }

  Future<void> _toggleDark(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', val);
    setState(() => _isDark = val);
    // Met à jour le thème de TOUTE l'application via le ValueNotifier global
    themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
    // Adapter la status bar selon le thème
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: val ? Brightness.light : Brightness.dark,
    ));
  }

  Future<void> _loadData() async {
    try {
      final id = widget.userData?['id'] ?? 0;
      final results = await Future.wait([
        ApiService.getUserBalance(id),
        ApiService.getTrustScore(id),
      ]);
      if (mounted) {
        setState(() {
          _balance    = results[0] as double;
          _trustScore = results[1] as int;
          _isLoading  = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Photo de profil'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () { Navigator.pop(context); _getImage(ImageSource.camera); },
            child: const Text('Prendre une photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () { Navigator.pop(context); _getImage(ImageSource.gallery); },
            child: const Text('Choisir dans la galerie'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final img = await ImagePicker().pickImage(source: source, imageQuality: 60);
    if (img != null && mounted) setState(() => _imageFile = File(img.path));
  }

  void _logout() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Vous devrez vous reconnecter pour accéder à votre compte.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              await ApiService.clearToken();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg   = _isDark ? AppTheme.dark     : AppTheme.light;
    final card = _isDark ? AppTheme.darkCard  : Colors.white;
    final txt  = _isDark ? AppTheme.textLight : AppTheme.textDark;
    final sub  = _isDark ? AppTheme.textMuted : const Color(0xFF888888);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    // ── Header profil ──────────────────────────────
                    _buildHeader(txt, sub),
                    const SizedBox(height: 24),

                    // ── Carte solde + score ────────────────────────
                    _buildStatsCard(card, txt, sub),
                    const SizedBox(height: 28),

                    // ── Section Compte ─────────────────────────────
                    _sectionTitle('Compte', sub),
                    _settingsCard(card, [
                      _tile(
                        icon: Icons.person_outline_rounded,
                        title: 'Informations personnelles',
                        txtColor: txt,
                        onTap: () async {
                          final res = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EditProfileScreen(
                              userId: widget.userData?['id'] ?? 0,
                              currentName: _fullname,
                              currentPhone: _phone,
                            )),
                          );
                          if (res is Map<String, String> && mounted) {
                            setState(() {
                              _fullname = res['name'] ?? _fullname;
                              _phone    = res['phone'] ?? _phone;
                            });
                          }
                        },
                      ),
                      _divider(),
                      _tile(
                        icon: Icons.lock_reset_rounded,
                        title: 'Changer mon PIN',
                        txtColor: txt,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ForgotPinScreen()),
                        ),
                      ),
                      _divider(),
                      _tile(
                        icon: Icons.history_rounded,
                        title: 'Historique des transactions',
                        txtColor: txt,
                        onTap: () {},
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── Section Préférences ────────────────────────
                    _sectionTitle('Préférences', sub),
                    _settingsCard(card, [
                      _toggleTile(
                        icon: Icons.dark_mode_outlined,
                        title: 'Mode Sombre',
                        value: _isDark,
                        txtColor: txt,
                        onChanged: _toggleDark,
                      ),
                      _divider(),
                      _toggleTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications push',
                        value: _pushNotifications,
                        txtColor: txt,
                        onChanged: (v) => setState(() => _pushNotifications = v),
                      ),
                    ]),

                    const SizedBox(height: 32),

                    // ── Bouton déconnexion ─────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: AppTheme.error.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                        ),
                        icon: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
                        label: const Text('DÉCONNEXION',
                            style: TextStyle(
                                color: AppTheme.error,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        onPressed: _logout,
                      ),
                    ),

                    const SizedBox(height: 20),
                    Text(
                      'G-Caisse v1.0.0 · Yaoundé, CM',
                      style: TextStyle(color: sub.withValues(alpha: 0.4), fontSize: 11),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────

  Widget _buildHeader(Color txt, Color sub) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primary, width: 2.5),
                  boxShadow: AppTheme.primaryShadow,
                ),
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: AppTheme.darkSurface,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!) as ImageProvider
                      : const AssetImage('assets/logo.jpeg'),
                ),
              ),
            ),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(_fullname,
            style: TextStyle(color: txt, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(_phone, style: TextStyle(color: sub, fontSize: 14)),
      ],
    );
  }

  Widget _buildStatsCard(Color card, Color txt, Color sub) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(child: _statItem('Solde', '${_balance.toStringAsFixed(0)} F', txt, sub)),
          Container(width: 1, height: 36, color: AppTheme.textMuted.withValues(alpha: 0.15)),
          Expanded(child: _statItem('Score crédit', '$_trustScore%', txt, sub)),
          Container(width: 1, height: 36, color: AppTheme.textMuted.withValues(alpha: 0.15)),
          Expanded(child: _statItem('Statut', 'Actif ✓', AppTheme.success, sub)),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color valColor, Color subColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: subColor, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(color: valColor, fontSize: 16, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _sectionTitle(String title, Color sub) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(title,
          style: TextStyle(
              color: sub, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
    ),
  );

  Widget _settingsCard(Color card, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      boxShadow: AppTheme.cardShadow,
    ),
    child: Column(children: children),
  );

  Widget _tile({
    required IconData icon,
    required String title,
    required Color txtColor,
    required VoidCallback onTap,
  }) =>
      ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 18),
        ),
        title: Text(title, style: TextStyle(color: txtColor, fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
        onTap: onTap,
      );

  Widget _toggleTile({
    required IconData icon,
    required String title,
    required bool value,
    required Color txtColor,
    required ValueChanged<bool> onChanged,
  }) =>
      ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 18),
        ),
        title: Text(title, style: TextStyle(color: txtColor, fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: CupertinoSwitch(
          activeTrackColor: AppTheme.primary,
          value: value,
          onChanged: onChanged,
        ),
      );

  Widget _divider() => Divider(
    height: 1,
    indent: 56,
    endIndent: 16,
    color: AppTheme.textMuted.withValues(alpha: 0.1),
  );
}

// ── Écran modification du profil ─────────────────────────────────────────────

class EditProfileScreen extends StatefulWidget {
  final int    userId;
  final String currentName;
  final String currentPhone;

  const EditProfileScreen({
    super.key,
    required this.userId,
    required this.currentName,
    required this.currentPhone,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.currentName);
    _phoneCtrl = TextEditingController(text: widget.currentPhone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.updateProfile(widget.userId, _nameCtrl.text.trim(), _phoneCtrl.text.trim());
      if (mounted) {
        Navigator.pop(context, {'name': _nameCtrl.text.trim(), 'phone': _phoneCtrl.text.trim()});
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
        title: const Text('Modifier le profil',
            style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w700)),
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              _label('Nom complet'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: AppTheme.textLight, fontSize: 16),
                decoration: AppTheme.fieldDecoration(
                  hint: 'Votre nom complet',
                  icon: Icons.person_outline_rounded,
                  isDark: true,
                ),
              ),

              const SizedBox(height: 20),

              _label('Numéro de téléphone'),
              const SizedBox(height: 8),
              TextField(
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

              const SizedBox(height: 36),

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: AppTheme.primaryShadow,
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: AppTheme.primaryButton,
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('ENREGISTRER LES MODIFICATIONS'),
                ),
              ),
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
