import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'admin_contans.dart';
import 'admin_web.dart';

// ================================================================
// ADMIN LOGIN PAGE
// Autentikasi via koleksi Firestore: 'admin_accounts'
// Dokumen: { username, password, role }
//
// Cara pakai — di routes / main.dart:
//   home: const AdminLoginPage()
// ================================================================
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage>
    with TickerProviderStateMixin {
  final _formKey       = GlobalKey<FormState>();
  final _userCtrl      = TextEditingController();
  final _passCtrl      = TextEditingController();
  bool  _obscure       = true;
  bool  _loading       = false;
  String? _errorMsg;

  // Animasi
  late final AnimationController _bgCtrl;
  late final AnimationController _cardCtrl;
  late final Animation<double>   _cardAnim;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cardAnim = CurvedAnimation(
      parent: _cardCtrl,
      curve: Curves.easeOutBack,
    );
    _cardCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _cardCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Login Logic ──────────────────────────────────────────────
  Future<void> _login() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() { _loading = true; _errorMsg = null; });

    try {
      final username = _userCtrl.text.trim();
      final password = _passCtrl.text.trim();

      // Cari di koleksi admin_accounts
      final snap = await FirebaseFirestore.instance
          .collection('admin_accounts')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        _setError('Username tidak ditemukan');
        return;
      }

      final data = snap.docs.first.data();
      final storedPass = data['password']?.toString() ?? '';

      if (storedPass != password) {
        _setError('Password salah');
        return;
      }

      // Login berhasil
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AdminWebPage(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } catch (e) {
      _setError('Terjadi kesalahan: $e');
    }
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() { _loading = false; _errorMsg = msg; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Animated background ────────────────────────────
          _AnimatedBg(controller: _bgCtrl),

          // ── Centered card ──────────────────────────────────
          Center(
            child: ScaleTransition(
              scale: _cardAnim,
              child: FadeTransition(
                opacity: _cardAnim,
                child: _buildCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Login Card ───────────────────────────────────────────────
  Widget _buildCard() {
    return Container(
      width: 420,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kNavy.withOpacity(0.18),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header biru ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kNavy, Color(0xFF2E4090)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Logo / ikon
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.25), width: 1.5),
                  ),
                  child: const Icon(Icons.festival_rounded,
                      color: Colors.white, size: 34),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Jatim Carnival',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Admin Panel — Masuk untuk melanjutkan',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // ── Form ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // Error banner
                  if (_errorMsg != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: kDanger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: kDanger.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: kDanger, size: 17),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMsg!,
                              style: const TextStyle(
                                  color: kDanger,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Username
                  _fieldLabel('Username'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _userCtrl,
                    style: const TextStyle(fontSize: 14),
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Username wajib diisi'
                            : null,
                    decoration: _inputDeco(
                      hint: 'Masukkan username',
                      icon: Icons.person_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Password
                  _fieldLabel('Password'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    style: const TextStyle(fontSize: 14),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Password wajib diisi'
                            : null,
                    decoration: _inputDeco(
                      hint: 'Masukkan password',
                      icon: Icons.lock_outline_rounded,
                      suffix: GestureDetector(
                        onTap: () =>
                            setState(() => _obscure = !_obscure),
                        child: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Tombol Login
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kNavy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        disabledBackgroundColor:
                            kNavy.withOpacity(0.5),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login_rounded, size: 19),
                                SizedBox(width: 8),
                                Text(
                                  'Masuk',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Footer ────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24)),
            ),
            child: Text(
              'Jurnal Jatim Carnival  •  Admin v1.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper widgets ───────────────────────────────────────────
  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
      );

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
          fontSize: 13, color: Color(0xFFB0BAD0)),
      prefixIcon: Icon(icon,
          size: 20, color: const Color(0xFFB0BAD0)),
      suffixIcon: suffix,
      filled: true,
      fillColor: kBg,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: Color(0xFFE2E8F0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kDanger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kDanger, width: 1.5),
      ),
    );
  }
}

// ================================================================
// ANIMATED BACKGROUND
// Floating blobs bergerak perlahan
// ================================================================
class _AnimatedBg extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedBg({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F1A4A), Color(0xFF1E2A5E), Color(0xFF2A3A7A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Blob 1 — kiri atas
              _blob(
                color: kAccent.withOpacity(0.18),
                size: 380,
                x: -80 + 40 * math.sin(t * 2 * math.pi),
                y: -80 + 30 * math.cos(t * 2 * math.pi),
              ),
              // Blob 2 — kanan bawah
              _blob(
                color: const Color(0xFF7C3AED).withOpacity(0.14),
                size: 320,
                x: MediaQuery.of(context).size.width - 200
                    + 50 * math.cos(t * 2 * math.pi + 1),
                y: MediaQuery.of(context).size.height - 180
                    + 40 * math.sin(t * 2 * math.pi + 1),
              ),
              // Blob 3 — tengah
              _blob(
                color: Colors.white.withOpacity(0.04),
                size: 260,
                x: MediaQuery.of(context).size.width / 2 - 130
                    + 30 * math.sin(t * 2 * math.pi + 2),
                y: MediaQuery.of(context).size.height / 2 - 130
                    + 30 * math.cos(t * 2 * math.pi + 2),
              ),
              // Grid dots overlay
              CustomPaint(
                size: Size(MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height),
                painter: _DotGridPainter(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _blob({
    required Color color,
    required double size,
    required double x,
    required double y,
  }) {
    return Positioned(
      left: x, top: y,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Dot grid painter ─────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const spacing = 36.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}