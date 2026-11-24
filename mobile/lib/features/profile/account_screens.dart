import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_links.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_repository.dart';

/// Verilerim: hesap bilgisi ve kalıcı hesap silme (KVKK / App Store zorunluluğu).
class MyDataScreen extends ConsumerStatefulWidget {
  const MyDataScreen({super.key});

  @override
  ConsumerState<MyDataScreen> createState() => _MyDataScreenState();
}

class _MyDataScreenState extends ConsumerState<MyDataScreen> {
  bool _deleting = false;

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hesabını sil'),
        content: const Text(
          'Hesabın ve tüm verilerin (öğünler, kilo geçmişi, su ve aktivite kayıtları, AI analizleri) '
          'kalıcı olarak silinecek. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Kalıcı olarak sil',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _deleting = true);
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      ref.read(sessionProvider.notifier).set(null);
      if (mounted) context.go('/welcome');
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(apiErrorMessage(e)),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(meProvider).value;

    return _SubPage(
      title: 'Verilerim',
      children: [
        _InfoRow(label: 'Ad Soyad', value: user?.name ?? '-'),
        _InfoRow(label: 'E-posta', value: user?.email ?? '-'),
        _InfoRow(
          label: 'Üyelik',
          value: user?.isPremium == true ? 'Premium' : 'Ücretsiz',
        ),
        const SizedBox(height: 8),
        const Text(
          'Verilerin yalnızca sana kalori takibi sunmak için saklanır ve üçüncü kişilerle paylaşılmaz. '
          'Yemek fotoğrafların analiz için yapay zekâ servisine gönderilir.',
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        if (user?.isPremium == true) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hesabını silmek ${AppLinks.storeName} aboneliğini otomatik iptal etmez. '
                  'Ücretlendirilmemek için önce aboneliği iptal et.',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      openLink(AppLinks.manageSubscription, external: true),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Text('Aboneliği Yönet →'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: _deleting ? null : _delete,
          icon: _deleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_forever_outlined),
          label: const Text('Hesabımı ve verilerimi sil'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
        ),
      ],
    );
  }
}

/// Uygulama Ayarları: dil, yasal metinler, çıkış.
class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> logout() async {
      await ref.read(authRepositoryProvider).logout();
      ref.read(sessionProvider.notifier).set(null);
      if (context.mounted) context.go('/welcome');
    }

    return _SubPage(
      title: 'Uygulama Ayarları',
      children: [
        const _InfoRow(label: 'Dil', value: 'Türkçe'),
        const _InfoRow(label: 'Sürüm', value: '1.0.0'),
        const SizedBox(height: 14),
        const Text(
          'Yasal',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        for (final (icon, label, url) in [
          (Icons.privacy_tip_outlined, 'Gizlilik Politikası', AppLinks.privacy),
          (
            Icons.description_outlined,
            'Kullanım Koşulları (EULA)',
            AppLinks.terms,
          ),
          (
            Icons.autorenew_rounded,
            'Abonelik Koşulları',
            AppLinks.subscriptionTerms,
          ),
          (Icons.shield_outlined, 'KVKK Aydınlatma Metni', AppLinks.kvkk),
          (Icons.support_agent_rounded, 'Destek', AppLinks.support),
        ])
          _LinkRow(icon: icon, label: label, onTap: () => openLink(url)),
        const SizedBox(height: 8),
        const Text(
          'Uygulamadaki kalori ve besin değerleri tahminidir; tıbbi tavsiye yerine geçmez. '
          'Sağlık durumunla ilgili kararlar için bir uzmana danış.',
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: logout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Çıkış Yap'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
        ),
      ],
    );
  }
}

class _SubPage extends StatelessWidget {
  const _SubPage({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: children,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.button),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.textPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
