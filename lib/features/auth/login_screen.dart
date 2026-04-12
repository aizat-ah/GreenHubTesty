import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
 
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
 
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}
 
class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
 
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
 
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
 
    await ref.read(authNotifierProvider.notifier).signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
 
    if (!mounted) return;
 
    final state = ref.read(authNotifierProvider);
    state.whenOrNull(
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      },
    );
  }
 
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
 
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),
 
              // Header
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: AppTheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome back!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sign in to browse fresh vegetables',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textMid,
                ),
              ),
              const SizedBox(height: 40),
 
              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon:
                            const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
 
                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPassword,
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 24),
 
                    // Sign in button
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Sign In'),
                    ),
                    const SizedBox(height: 16),
 
                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: AppTheme.textMid),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/register'),
                          child: const Text(
                            'Register',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
 
  void _showForgotPassword() {
    final emailCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 28,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reset Password',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              "Enter your email and we'll send a reset link.",
              style: TextStyle(color: AppTheme.textMid),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email address'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (emailCtrl.text.trim().isNotEmpty) {
                  await ref
                      .read(authServiceProvider)
                      .sendPasswordReset(emailCtrl.text);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Password reset email sent!')),
                    );
                  }
                }
              },
              child: const Text('Send Reset Link'),
            ),
          ],
        ),
      ),
    );
  }
}