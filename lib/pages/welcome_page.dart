import 'package:flutter/material.dart';
import 'package:jurnal_jatim_carnival/data/auth_state.dart';
import 'login_page.dart';
import 'create_account.dart';
import 'home_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background ───────────────────────────────────────
          SizedBox.expand(
            child: Image.asset(
              'assets/images/bg_welcome.png',
              fit: BoxFit.cover,
            ),
          ),
          // Overlay gelap tipis supaya teks lebih terbaca
          SizedBox.expand(
            child: Container(color: Colors.white.withOpacity(0.35)),
          ),

          // ── Konten ───────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const Spacer(),

                  // Logo
                  Image.asset(
                    'assets/images/logowebku.png',
                    width: 180,
                    height: 180,
                  ),
                  const SizedBox(height: 20),

                  // Judul
                  const Text(
                    'SELAMAT DATANG!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3561),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle
                  const Text(
                    'Lestarikan Tradisi, Rayakan Kreasi',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                  ),

                  const Spacer(),

                  // ── Tombol Login ─────────────────────────────
                  ElevatedButton(
                    onPressed: () {
                      AuthState.isGuest = false;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D3561),
                      foregroundColor: const Color(0xFFFFF6F2),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Tombol Sign Up ───────────────────────────
                  OutlinedButton(
                    onPressed: () {
                      AuthState.isGuest = false;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateAccountPage(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2D3561),
                      backgroundColor: const Color(0xFFFFF6F2),
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(
                        color: Color(0xFF2D3561),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Divider dengan teks ──────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: Colors.black26, thickness: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'atau',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Colors.black26, thickness: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Tombol Masuk Tanpa Akun ──────────────────
                  GestureDetector(
                    onTap: () {
                      AuthState.isGuest = true;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage()),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFF2D3561).withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 19,
                            color: Color(0xFF2D3561),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Masuk Tanpa Akun',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3561),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
