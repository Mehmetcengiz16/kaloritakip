import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/formatters.dart';
import '../auth/auth_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(meProvider);

    return Scaffold(
      body: SafeArea(
        child: async.when(
          data: (user) => ProfileContent(
            user: user,
            onNotificationsChanged: (v) async {
              try {
                await ref.read(meProvider.notifier).save({
                  'notifications_enabled': v,
                });
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(apiErrorMessage(e)),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(meProvider),
              child: Text(
                '${apiErrorMessage(e)}\nTekrar dene',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileContent extends StatelessWidget {
  const ProfileContent({
    super.key,
    required this.user,
    required this.onNotificationsChanged,
  });

  final AppUser user;
  final ValueChanged<bool> onNotificationsChanged;

  @override
  Widget build(BuildContext context) {
    final goal = user.profile?['goal'] as String?;
    final notifications =
        user.profile?['notifications_enabled'] as bool? ?? true;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Text(
          'Profil',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.track,
                child: Icon(
                  Icons.person_rounded,
                  size: 34,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hedef: ${goalLabels[goal] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (user.isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _PremiumCard(isPremium: user.isPremium),
        const SizedBox(height: 14),
        _MenuTile(
          icon: Icons.track_changes_rounded,
          label: 'Hedef ve Bilgilerim',
          onTap: () => context.push('/profile/goals'),
        ),
        _MenuTile(
          icon: Icons.notifications_none_rounded,
          label: 'Bildirimler',
          trailing: Switch(
            value: notifications,
            onChanged: onNotificationsChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
          ),
        ),
        _MenuTile(
          icon: Icons.bar_chart_rounded,
          label: 'Verilerim',
          onTap: () => context.push('/profile/data'),
        ),
        _MenuTile(
          icon: Icons.menu_book_outlined,
          label: 'Diyet Planım',
          onTap: () => context.go('/plan'),
        ),
        _MenuTile(
          icon: Icons.settings_outlined,
          label: 'Uygulama Ayarları',
          onTap: () => context.push('/profile/settings'),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: trailing == null ? 14 : 4,
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.textPrimary, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                trailing ??
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textPrimary,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Ink(
        decoration: BoxDecoration(
          gradient: isPremium ? null : AppColors.primaryGradient,
          color: isPremium ? AppColors.primarySoft : null,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => context.push('/premium'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  size: 30,
                  color: isPremium ? AppColors.primary : Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPremium ? 'Premium Üyeliğin' : "Premium'a Geç",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isPremium
                              ? AppColors.textPrimary
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPremium
                            ? 'Üyelik bilgilerini gör'
                            : 'Daha fazla AI analiz, tüm diyet planları',
                        style: TextStyle(
                          fontSize: 12,
                          color: isPremium
                              ? AppColors.textSecondary
                              : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isPremium ? AppColors.textPrimary : Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
