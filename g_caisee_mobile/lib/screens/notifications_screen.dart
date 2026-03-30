import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const NotificationsScreen({super.key, required this.userData});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await ApiService.getNotifications();
      if (mounted) setState(() {
        _notifications = data['notifications'] ?? [];
        _unreadCount = data['unread_count'] ?? 0;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    await ApiService.markAllNotificationsRead();
    _loadNotifications();
  }

  Future<void> _markRead(int id) async {
    await ApiService.markNotificationRead(id);
    _loadNotifications();
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'money_request': return Icons.request_page_rounded;
      case 'split_bill': return Icons.receipt_long_rounded;
      case 'tontine': return Icons.groups_rounded;
      case 'transfer': return Icons.send_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'money_request': return const Color(0xFF6366F1);
      case 'split_bill': return const Color(0xFFF59E0B);
      case 'tontine': return const Color(0xFF8B5CF6);
      case 'transfer': return AppTheme.primary;
      default: return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark,
      appBar: AppBar(
        title: Text("Notifications${_unreadCount > 0 ? ' ($_unreadCount)' : ''}", style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.dark,
        foregroundColor: AppTheme.textLight,
        actions: [
          if (_unreadCount > 0)
            TextButton(onPressed: _markAllRead, child: const Text("Tout lire", style: TextStyle(color: AppTheme.primary))),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _notifications.isEmpty
              ? const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_rounded, color: AppTheme.textMuted, size: 64),
                    SizedBox(height: 16),
                    Text("Aucune notification", style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                  ],
                ))
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: AppTheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _notifications.length,
                    itemBuilder: (context, i) {
                      final n = _notifications[i];
                      final isRead = n['is_read'] == true;
                      final color = _typeColor(n['type']);
                      return GestureDetector(
                        onTap: () => _markRead(n['id']),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isRead ? AppTheme.darkCard : AppTheme.darkCard.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: isRead ? null : Border.all(color: color.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                                child: Icon(_typeIcon(n['type']), color: color, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(n['title'] ?? '', style: TextStyle(color: AppTheme.textLight, fontWeight: isRead ? FontWeight.w500 : FontWeight.w700, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(n['body'] ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                ]),
                              ),
                              if (!isRead)
                                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
