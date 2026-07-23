import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../services/sync_service.dart';

class LoginDialog extends ConsumerStatefulWidget {
  const LoginDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const LoginDialog(),
    );
    return result ?? false;
  }

  @override
  ConsumerState<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends ConsumerState<LoginDialog> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isSignUpMode = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    final lang = ref.read(localeProvider).languageCode;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang == 'bn'
                ? 'ইমেইল এবং পাসওয়ার্ড প্রদান করুন'
                : 'Please enter email and password',
          ),
          backgroundColor: Colors.amber.shade900,
        ),
      );
      return;
    }

    final authNotifier = ref.read(authProvider.notifier);
    final success = _isSignUpMode
        ? await authNotifier.signUp(email: email, password: password)
        : await authNotifier.signIn(email: email, password: password);

    if (mounted) {
      if (success) {
        // Trigger background data restore from Supabase on login without dialog context
        ref.read(syncServiceProvider.notifier).restoreFromSupabase();

        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang == 'bn'
                  ? (_isSignUpMode
                        ? 'অ্যাকাউন্ট তৈরি সফল হয়েছে!'
                        : 'লগইন সফল হয়েছে!')
                  : (_isSignUpMode
                        ? 'Account created successfully!'
                        : 'Signed in successfully!'),
            ),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      } else {
        final err =
            ref.read(authProvider).errorMessage ?? 'Authentication failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      color: cs.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSignUpMode
                              ? (lang == 'bn'
                                  ? 'শিক্ষক অ্যাকাউন্ট তৈরি'
                                  : 'Create Teacher Account')
                              : (lang == 'bn'
                                  ? 'শিক্ষক বা এডমিন লগইন'
                                  : 'Teacher / Admin Login'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          lang == 'bn'
                              ? 'ডাটা এডিট বা পরিবর্তন করতে লগইন করুন'
                              : 'Authenticate to modify or save data',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Email Field
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: lang == 'bn' ? 'ইমেইল অ্যাড্রেস' : 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Password Field
              TextField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: lang == 'bn' ? 'পাসওয়ার্ড' : 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              FilledButton(
                onPressed: authState.isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: authState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isSignUpMode
                            ? (lang == 'bn' ? 'রেজিস্ট্রেশন করুন' : 'Sign Up')
                            : (lang == 'bn' ? 'প্রবেশ করুন' : 'Sign In'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
              const SizedBox(height: 10),

              // TextButton(
              //   onPressed: () =>
              //       setState(() => _isSignUpMode = !_isSignUpMode),
              //   child: Text(
              //     _isSignUpMode
              //         ? (lang == 'bn'
              //             ? 'ইতিমধ্যে অ্যাকাউন্ট আছে? প্রবেশ করুন'
              //             : 'Already have an account? Sign In')
              //         : (lang == 'bn'
              //             ? 'নতুন শিক্ষক? নতুন অ্যাকাউন্ট তৈরি করুন'
              //             : 'New teacher? Create an account'),
              //     style: TextStyle(fontSize: 13, color: cs.primary),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
