import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/gestures.dart';

import '../../core/config/app_links.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_buttons.dart';
import '../onboarding/onboarding_state.dart';
import 'auth_repository.dart';

/// Onboarding sonrası hesap oluşturma. Kayıt olunca toplanan onboarding verisi gönderilir.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.register(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
      final user = await repo.submitOnboarding(
        ref.read(onboardingProvider).toJson(),
      );
      ref.read(sessionProvider.notifier).set(user);
      ref.read(onboardingProvider.notifier).reset();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) _showError(context, apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthLayout(
      title: 'Hesabını Oluştur',
      subtitle: 'Planın hazır! İlerlemeni kaydetmek\niçin bir hesap oluştur.',
      form: Form(
        key: _form,
        child: Column(
          children: [
            TextFormField(
              controller: _name,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Ad Soyad',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? 'Adını gir.' : null,
            ),
            const SizedBox(height: 12),
            _EmailField(controller: _email),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Şifre (en az 8 karakter)',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => (v == null || v.length < 8)
                  ? 'Şifre en az 8 karakter olmalı.'
                  : null,
            ),
          ],
        ),
      ),
      button: Column(
        children: [
          PrimaryButton(
            label: 'Hesap Oluştur',
            loading: _loading,
            onPressed: _submit,
          ),
          const SizedBox(height: 12),
          const ConsentText(),
        ],
      ),
      footer: TextButton(
        onPressed: () => context.push('/login'),
        child: const Text('Zaten hesabın var mı? Giriş Yap'),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .login(email: _email.text.trim(), password: _password.text);
      ref.read(sessionProvider.notifier).set(user);
      if (mounted)
        context.go(user.onboardingCompleted ? '/home' : '/onboarding');
    } catch (e) {
      if (mounted) _showError(context, apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthLayout(
      title: 'Tekrar Hoş Geldin',
      subtitle: 'Kaldığın yerden devam etmek için\ngiriş yap.',
      form: Form(
        key: _form,
        child: Column(
          children: [
            _EmailField(controller: _email),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                hintText: 'Şifre',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Şifreni gir.' : null,
            ),
          ],
        ),
      ),
      button: PrimaryButton(
        label: 'Giriş Yap',
        loading: _loading,
        onPressed: _submit,
      ),
      footer: TextButton(
        onPressed: () => context.go('/onboarding'),
        child: const Text('Hesabın yok mu? Hemen Başla'),
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.emailAddress,
    textInputAction: TextInputAction.next,
    autocorrect: false,
    decoration: const InputDecoration(
      hintText: 'E-posta',
      prefixIcon: Icon(Icons.mail_outline),
    ),
    validator: (v) =>
        (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()))
        ? 'Geçerli bir e-posta gir.'
        : null,
  );
}

class _AuthLayout extends StatelessWidget {
  const _AuthLayout({
    required this.title,
    required this.subtitle,
    required this.form,
    required this.button,
    required this.footer,
  });

  final String title;
  final String subtitle;
  final Widget form;
  final Widget button;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            form,
            const SizedBox(height: 24),
            button,
            const SizedBox(height: 8),
            Center(child: footer),
          ],
        ),
      ),
    );
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// "Hesap oluşturarak Kullanım Koşulları'nı ve Gizlilik Politikası'nı kabul edersin." (linkli)
class ConsentText extends StatefulWidget {
  const ConsentText({super.key});

  @override
  State<ConsentText> createState() => _ConsentTextState();
}

class _ConsentTextState extends State<ConsentText> {
  late final _terms = TapGestureRecognizer()
    ..onTap = () => openLink(AppLinks.terms);
  late final _privacy = TapGestureRecognizer()
    ..onTap = () => openLink(AppLinks.privacy);
  late final _kvkk = TapGestureRecognizer()
    ..onTap = () => openLink(AppLinks.kvkk);

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    _kvkk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const link = TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
    );
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 11.5,
          height: 1.5,
          color: AppColors.textSecondary,
        ),
        children: [
          const TextSpan(text: 'Hesap oluşturarak '),
          TextSpan(text: 'Kullanım Koşulları', style: link, recognizer: _terms),
          const TextSpan(text: "'nı ve "),
          TextSpan(
            text: 'Gizlilik Politikası',
            style: link,
            recognizer: _privacy,
          ),
          const TextSpan(text: "'nı kabul etmiş, "),
          TextSpan(
            text: 'KVKK Aydınlatma Metni',
            style: link,
            recognizer: _kvkk,
          ),
          const TextSpan(
            text:
                "'ni okumuş olursun. Girdiğin boy, kilo ve beslenme bilgileri yalnızca sana kişisel hedef hesaplamak için işlenir.",
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
