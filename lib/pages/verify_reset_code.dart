import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerifyResetCodePage extends StatefulWidget {
  final String email;
  const VerifyResetCodePage({super.key, required this.email});

  @override
  State<VerifyResetCodePage> createState() => _VerifyResetCodePageState();
}

class _VerifyResetCodePageState extends State<VerifyResetCodePage> {
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleResetPassword() async {
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (code.isEmpty || newPassword.isEmpty) {
      _showSnackbar('Semua kolom harus diisi', Icons.warning_amber_rounded);
      return;
    }

    if (newPassword.length < 6) {
      _showSnackbar(
        'Password baru minimal 6 karakter',
        Icons.warning_amber_rounded,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Verifikasi apakah kode dari email tersebut valid/cocok
      await FirebaseAuth.instance.verifyPasswordResetCode(code);

      // 2. Jika valid, langsung eksekusi ganti password baru di sini
      await FirebaseAuth.instance.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );

      if (mounted) {
        _showSnackbar(
          'Password berhasil diperbarui! Silakan login.',
          Icons.check_circle_outline,
        );
        // Kembali ke halaman Login (pop 2 kali untuk menutup halaman verifikasi dan lupa password)
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Gagal mereset password.';
      if (e.code == 'expired-action-code') {
        msg = 'Kode verifikasi telah kedaluwarsa.';
      } else if (e.code == 'invalid-action-code') {
        msg = 'Kode verifikasi tidak valid/salah.';
      } else if (e.code == 'user-not-found') {
        msg = 'Pengguna tidak ditemukan.';
      }
      _showSnackbar(msg, Icons.error_outline);
    } catch (e) {
      _showSnackbar('Terjadi kesalahan: $e', Icons.error_outline);
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
                style: const TextStyle(color: Color(0xFFFFF6F2)),
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20), // Jarak atas agar tidak terlalu mepet

              // Teks Judul
              const Text(
                'Verifikasi & Reset',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3561),
                ),
              ),

              const SizedBox(height: 8),

              // Deskripsi Petunjuk
              const Text(
                'Buka email kamu, salin kode "oobCode" yang ada di ujung link email reset Firebase, lalu masukkan di sini.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 30),

              // Input Kode dari Email
              TextField(
                controller: _codeController,
                style: const TextStyle(fontSize: 15, color: Color(0xFF2D3561)),
                decoration: InputDecoration(
                  labelText: 'Masukkan Kode (oobCode)',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(
                    Icons.vpn_key_outlined,
                    color: Color(0xFF2D3561),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: const Color(0xFF2D3561).withOpacity(0.15),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF2D3561)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Input Password Baru
              TextField(
                controller: _newPasswordController,
                obscureText: _obscurePassword,
                style: const TextStyle(fontSize: 15, color: Color(0xFF2D3561)),
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF2D3561),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFF2D3561),
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: const Color(0xFF2D3561).withOpacity(0.15),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF2D3561)),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Tombol Konfirmasi
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D3561),
                    foregroundColor: const Color(0xFFFFF6F2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
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
                          'Simpan Password Baru',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
