import 'package:flutter/material.dart';
import 'package:jurnal_jatim_carnival/data/auth_state.dart';
import 'package:jurnal_jatim_carnival/pages/login_page.dart';
import 'package:jurnal_jatim_carnival/pages/welcome_page.dart';

// ✅ Panggil ini sebelum aksi yang butuh login
bool guardGuest(BuildContext context) {
  if (!AuthState.isGuest) return true; // ✅ sudah login, lanjut

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF2D3561),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Login Diperlukan',
        style: TextStyle(color: Color(0xFFFFF6F2), fontWeight: FontWeight.w700),
      ),
      content: const Text(
        'Silakan login terlebih dahulu untuk menggunakan fitur ini.',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white24,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.white24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Nanti', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D3561),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(
                color: Color(0xFFFFF6F2),
              ), // ✅ pindah ke sini
            ),
          ),
          child: const Text('Login Sekarang'),
        ),
      ],
    ),
  );
  return false; // ✅ guest, blokir aksi
}
