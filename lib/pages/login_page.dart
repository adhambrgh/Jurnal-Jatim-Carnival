// ignore_for_file: strict_top_level_inference
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'create_account.dart';
import '../services/auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jurnal_jatim_carnival/data/auth_state.dart';
import 'package:jurnal_jatim_carnival/pages/forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Login email/password ──────────────────────────────────────
  Future<void> _login() async {
    setState(() => _isLoading = true);
    final result = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null) {
      AuthState.isGuest = false;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      _showSnack(
        'Login gagal. Cek email & password.',
        icon: Icons.warning_amber_rounded,
      );
    }
  }

  // ── Google Sign In ────────────────────────────────────────────
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId:
            '181946388516-j0li50l4anpbatatt3999076avc21l2d.apps.googleusercontent.com',
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _showSnack(
          'Login dibatalkan. Coba lagi.',
          icon: Icons.warning_amber_rounded,
        );
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) {
        AuthState.isGuest = false;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Login gagal: $e', isError: true);
    }
  }

  // ── Masuk Tanpa Akun ──────────────────────────────────────────
  void _masukTanpaAkun() {
    AuthState.isGuest = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  // ── Snackbar helper ───────────────────────────────────────────
  void _showSnack(
    String msg, {
    IconData icon = Icons.info_outline,
    bool isError = false,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF2D3561),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isError ? Colors.red.shade200 : const Color(0xFF6C7FD8),
            width: 1,
          ),
        ),
        content: Row(
          children: [
            Icon(
              icon,
              color: isError ? Colors.white : const Color(0xFF6C7FD8),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  color: Color(0xFFFFF6F2),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          SizedBox.expand(
            child: Image.asset(
              'assets/images/bg_welcome.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3561),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Image.asset('assets/images/logowebku.png', width: 150),
                    const SizedBox(height: 40),

                    // Email
                    _inputField('Email', controller: _emailController),
                    const SizedBox(height: 18),

                    // Password
                    _inputField(
                      'Kata sandi',
                      isPassword: true,
                      controller: _passwordController,
                    ),
                    const SizedBox(height: 40),

                    // Tombol Login
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D3561),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 6,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  color: Color(0xFFFFF6F2),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lupa password
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage(),
                        ),
                      ),
                      child: const Text(
                        'Lupa Kata Sandi?',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Color(0xFF2D3561),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Divider atau
                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('atau'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Google
                    _socialButton(
                      iconPath: 'assets/images/google_logo.png',
                      text: 'Login dengan Google',
                      useAsset: true,
                      onPressed: _signInWithGoogle,
                    ),
                    const SizedBox(height: 10),

                    // Facebook
                    _socialButton(
                      icon: Icons.facebook,
                      text: 'Login dengan Facebook',
                      iconColor: const Color(0xFF1877F2),
                    ),
                    const SizedBox(height: 16),

                    // Buat akun baru
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateAccountPage(),
                        ),
                      ),
                      child: const Text(
                        'Buat Akun Baru',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Color(0xFF2D3561),
                        ),
                      ),
                    ),

                    // ── Masuk Tanpa Akun ─────────────────────────
                    TextButton(
                      onPressed: _masukTanpaAkun,
                      child: const Text(
                        'Masuk Tanpa Akun',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Color(0xFF2D3561),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input field ───────────────────────────────────────────────
  Widget _inputField(
    String hint, {
    bool isPassword = false,
    required TextEditingController controller,
  }) {
    bool obscureLocal = isPassword;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: StatefulBuilder(
        builder: (context, setFieldState) {
          return TextField(
            controller: controller,
            obscureText: obscureLocal,
            style: const TextStyle(fontSize: 16, color: Color(0xFF2D3561)),
            decoration: InputDecoration(
              labelText: hint,
              labelStyle: const TextStyle(
                color: Color(0xFF2D3561),
                fontWeight: FontWeight.w500,
              ),
              floatingLabelStyle: const TextStyle(
                color: Color(0xFF2D3561),
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: const Color(0xFFFFF6F2),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              suffixIcon: isPassword
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        icon: Icon(
                          obscureLocal
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF2D3561),
                        ),
                        onPressed: () =>
                            setFieldState(() => obscureLocal = !obscureLocal),
                      ),
                    )
                  : null,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(
                  color: Color(0xFF2D3561),
                  width: 1.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Social button ─────────────────────────────────────────────
  Widget _socialButton({
    IconData? icon,
    String? iconPath,
    required String text,
    Color? iconColor,
    bool useAsset = false,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFFF6F2),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (useAsset && iconPath != null)
              Image.asset(
                iconPath,
                width: 20,
                height: 20,
                color: const Color(0xFF2D3561),
                colorBlendMode: BlendMode.srcIn,
              )
            else if (icon != null)
              Icon(icon, size: 20, color: const Color(0xFF2D3561)),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(color: Color(0xFF2D3561))),
          ],
        ),
      ),
    );
  }
}
