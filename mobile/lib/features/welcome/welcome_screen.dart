import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_buttons.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const _Logo(),
              const SizedBox(height: 16),
              const Text(
                'KaloriTakip',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Beslenmeni yönet, hedeflerine\ndaha hızlı ulaş.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              // Tasarımdaki meyve kasesi illüstrasyonu: assets/images/welcome_bowl.png
              Expanded(
                flex: 5,
                child: Image.asset(
                  'assets/images/welcome_bowl.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.rice_bowl_rounded,
                    size: 140,
                    color: AppColors.primarySoft,
                  ),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Hemen Başla',
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: () => context.push('/onboarding'),
              ),
              const SizedBox(height: 12),
              OutlineAppButton(
                label: 'Hesabın Var mı? Giriş Yap',
                onPressed: () => context.push('/login'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mor alev/damla logosu (gerçek logo dosyası gelince Image.asset ile değiştirilecek).
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        colors: [Color(0xFFA78BFA), AppColors.primaryDark],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect),
      child: const Icon(
        Icons.local_fire_department_rounded,
        size: 84,
        color: Colors.white,
      ),
    );
  }
}
