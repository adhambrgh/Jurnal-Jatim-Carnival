// ignore_for_file: strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:jurnal_jatim_carnival/pages/login_page.dart';
import 'package:jurnal_jatim_carnival/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          backgroundColor: const Color(0xFF2D3561),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF6C7FD8), width: 1),
          ),
          content: Row(
            children: const [
              Icon(Icons.lock_outline, color: Color(0xFF6C7FD8), size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Kata sandi tidak cocok!",
                  style: TextStyle(
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
      return;
    }

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          backgroundColor: const Color(0xFF2D3561),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF6C7FD8), width: 1),
          ),
          content: Row(
            children: const [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFF6C7FD8),
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Email dan kata sandi tidak boleh kosong!",
                  style: TextStyle(
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
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.register(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result != null) {
      // ✅ Simpan user ke Firestore
      // ✅ Simpan user ke Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(result.user!.uid)
          .set({
            'uid': result.user!.uid,
            'displayName': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'bio': '',
            'photoUrl': '',
            'createdAt': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          backgroundColor: const Color(0xFF2D3561),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF6C7FD8), width: 1),
          ),
          content: Row(
            children: const [
              Icon(
                Icons.check_circle_outline,
                color: Color(0xFF6C7FD8),
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Akun berhasil dibuat! Silakan login.",
                  style: TextStyle(
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal membuat akun. Email mungkin sudah dipakai."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
                      "Buat Akun",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3561),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Image.asset('assets/images/logowebku.png', width: 150),

                    const SizedBox(height: 40),

                    _inputField("Nama", controller: _nameController),
                    const SizedBox(height: 18),
                    _inputField("Email", controller: _emailController),
                    const SizedBox(height: 18),
                    _inputField(
                      "Kata sandi",
                      isPassword: true,
                      controller: _passwordController,
                    ),
                    const SizedBox(height: 18),
                    _inputField(
                      "Pastikan kata sandi",
                      isPassword: true,
                      controller: _confirmPasswordController,
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2D3561),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 6,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Color(0xFF2D3561),
                              )
                            : const Text(
                                "Buat Akun",
                                style: TextStyle(color: Color(0xFFFFF6F2)),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: const Text(
                        "Sudah punya akun? Login",
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Color(0xFF2D3561),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text("atau"),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _socialButton(
                      iconPath: 'assets/images/google_logo.png',
                      text: "Daftar dengan Google",
                      useAsset: true,
                    ),

                    const SizedBox(height: 10),

                    _socialButton(
                      icon: Icons.facebook,
                      text: "Daftar dengan Facebook",
                      iconColor: const Color(0xFF1877F2),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(
    String hint, {
    bool isPassword = false,
    required TextEditingController controller,
  }) {
    bool obscureLocal = isPassword;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: StatefulBuilder(
        builder: (context, setState) {
          return TextField(
            controller: controller,
            obscureText: obscureLocal,
            style: const TextStyle(fontSize: 16, color: Color(0xFF2D3561)),
            decoration: InputDecoration(
              labelText:
                  hint, // Menggunakan labelText agar otomatis melayang ke atas saat aktif
              labelStyle: const TextStyle(
                color: Color(0xFF2D3561),
                fontWeight: FontWeight.w500,
              ),
              // Warna label saat teks melayang ke atas ketika field aktif
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
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        icon: Icon(
                          obscureLocal
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Color(0xFF2D3561),
                        ),
                        onPressed: () {
                          setState(() {
                            obscureLocal = !obscureLocal;
                          });
                        },
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
                ), // Border aktif menyala
              ),
            ),
          );
        },
      ),
    );
  }

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
        onPressed: onPressed, // ✅ pakai parameter
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
