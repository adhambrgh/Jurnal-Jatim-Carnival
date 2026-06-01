import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'verify_reset_code.dart';
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendReset() async {
  if (_emailController.text.isEmpty) {
    _showSnackbar('Email tidak boleh kosong', Icons.warning_amber_rounded);
    return;
  }

  setState(() => _isLoading = true);

  try {
    // Tetap kirim email reset seperti biasa
    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: _emailController.text.trim(),
    );
    
    if (mounted) {
      _showSnackbar(
        'Kode verifikasi telah dikirim ke email kamu!',
        Icons.check_circle_outline,
      );
      
      // PINDAH KE HALAMAN VERIFIKASI KODE
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyResetCodePage(email: _emailController.text.trim()),
        ),
      );
    }
  } catch (e) {
    _showSnackbar('Gagal mengirim: $e', Icons.error_outline);
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  void _showSnackbar(String message, IconData icon) {
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
          children: [
            Icon(icon, color: const Color(0xFF6C7FD8), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF6F2),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D3561),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF142C6E).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text(
              'Lupa Kata Sandi?',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3561),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Masukkan email kamu, kami akan kirim link untuk reset kata sandi.',
              style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 40),

            // Email field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 15, color: Color(0xFF2D3561)),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: Color(0xFF2D3561)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: const Color(0xFF2D3561).withOpacity(0.15),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(
                    color: Color(0xFF2D3561),
                    width: 1.5,
                  ),
                ),
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: Color(0xFF2D3561),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Tombol kirim
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3561),
                  foregroundColor: const Color(0xFFFFF6F2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Color(0xFF2D3561),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Kirim Link Reset',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
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