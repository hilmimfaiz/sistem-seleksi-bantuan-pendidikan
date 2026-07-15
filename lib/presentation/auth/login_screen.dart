import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/app_widgets.dart';

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
  bool _rememberLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        final authState = ref.read(authProvider);
        if (authState.isAdmin) {
          Navigator.of(context).pushReplacementNamed('/admin/dashboard');
        } else {
          Navigator.of(context).pushReplacementNamed('/mahasiswa/dashboard');
        }
      } else {
        final error = ref.read(authProvider).error ?? 'Login gagal';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.primary, // Orange background
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Section (Hello Welcome Back!)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                children: [
                  const Text(
                    'Halo',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ).animate().slideY(begin: -0.2, end: 0, duration: 500.ms, curve: Curves.easeOut).fadeIn(),
                  const SizedBox(height: 8),
                  const Text(
                    'Selamat Datang Kembali!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ).animate(delay: 100.ms).slideY(begin: -0.2, end: 0, duration: 500.ms, curve: Curves.easeOut).fadeIn(),
                ],
              ),
            ),

            // Bottom Section (White Card)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    )
                  ]
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Login Account Title
                        Text(
                          'Masuk Akun',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ).animate(delay: 200.ms).fadeIn(),
                        
                        const SizedBox(height: 12),
                        
                        // Subtitle
                        Text(
                          'Silakan masuk ke akun Anda untuk melanjutkan akses ke sistem finansial pendidikan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ).animate(delay: 300.ms).fadeIn(),

                        const SizedBox(height: 40),

                        // Email Field
                        Text(
                          'Alamat Email',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ).animate(delay: 400.ms).fadeIn(),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Masukkan Alamat Email',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                            suffixIcon: Icon(Icons.person, color: Colors.grey.shade600, size: 20),
                            filled: true,
                            fillColor: isDark ? AppColors.darkSurface : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.red, width: 1.5),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email tidak boleh kosong';
                            if (!v.contains('@')) return 'Format email tidak valid';
                            return null;
                          },
                        ).animate(delay: 450.ms).slideX(begin: 0.1, end: 0).fadeIn(),

                        const SizedBox(height: 24),

                        // Password Field
                        Text(
                          'Kata Sandi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ).animate(delay: 500.ms).fadeIn(),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            hintText: '••••••••••••',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400, letterSpacing: 2),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey.shade600,
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: isDark ? AppColors.darkSurface : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.red, width: 1.5),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password tidak boleh kosong';
                            if (v.length < 6) return 'Password minimal 6 karakter';
                            return null;
                          },
                        ).animate(delay: 550.ms).slideX(begin: 0.1, end: 0).fadeIn(),

                        const SizedBox(height: 16),

                        // Remember Me & Forgot Password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _rememberLogin,
                                    onChanged: (v) => setState(() => _rememberLogin = v ?? true),
                                    activeColor: AppColors.primary,
                                    checkColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tetap login',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Informasi'),
                                    content: const Text('Jika terjadi kesalahan login atau lupa sandi hubungi admin.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Lupa Kata Sandi?',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ).animate(delay: 600.ms).fadeIn(),

                        const SizedBox(height: 40),

                        // Login Button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                                    ),
                                  )
                                : const Text(
                                    'Masuk',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ).animate(delay: 700.ms).slideY(begin: 0.2, end: 0).fadeIn(),

                        const SizedBox(height: 16),

                        // Demo Accounts Info removed
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
