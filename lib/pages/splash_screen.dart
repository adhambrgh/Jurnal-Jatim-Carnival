import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jurnal_jatim_carnival/pages/welcome_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          SizedBox.expand(
            child: Image.asset(
              'assets/images/bg_welcome.png', // ✅ sama seperti welcome page
              fit: BoxFit.cover,
            ),
          ),

          // Overlay putih agar logo terlihat jelas
          SizedBox.expand(
            child: Container(
              color: Colors.white.withOpacity(0.40),
            ),
          ),

          // Konten tengah
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logowebku.png', width: 180),
                const SizedBox(height: 30),
                const CircularProgressIndicator(
                  color: Color(0xFF6C7FD8), // warna biru sesuai tema
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}