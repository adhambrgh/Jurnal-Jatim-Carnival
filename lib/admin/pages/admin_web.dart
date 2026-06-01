import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_contans.dart';
import 'postingan_page.dart';
import 'event_terbaru_page.dart';
import 'pengguna_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_login_page.dart';
import 'kota_page.dart';
// ═══════════════════════════════════════════════════════════════
// SHELL UTAMA ADMIN
// Mengelola sidebar + navigasi ke 3 halaman terpisah
// ═══════════════════════════════════════════════════════════════
class AdminWebPage extends StatefulWidget {
  const AdminWebPage({super.key});

  @override
  State<AdminWebPage> createState() => _AdminWebPageState();
}

class _AdminWebPageState extends State<AdminWebPage> {
  int _currentIndex = 0;

  // ─── Konfigurasi menu sidebar ────────────────────────────────
  static const _menuItems = [
    _MenuItem(Icons.article_rounded, 'Postingan', 'Kelola postingan pengguna'),
    _MenuItem(Icons.event_rounded, 'Event Terbaru', 'Kelola daftar event'),
    _MenuItem(Icons.people_rounded, 'Pengguna', 'Kelola akun pengguna'),
    _MenuItem(
      Icons.location_city_rounded,
      'Kategori Kota',
      'Kelola kategori kota',
    ),
  ];

  // ─── Halaman untuk setiap menu ───────────────────────────────
  final List<Widget> _pages = const [
    PostinganPage(),
    EventTerbaruPage(),
    PenggunaPage(),
    KotaPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  // IndexedStack mempertahankan state tiap halaman
                  child: IndexedStack(index: _currentIndex, children: _pages),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SIDEBAR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSidebar() {
    return Container(
      width: 230,
      decoration: const BoxDecoration(
        color: kNavy,
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),

          // ── Logo & nama app ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kAccent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.festival,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jatim Carnival',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Admin Panel',
                        style: TextStyle(
                          color: Color(0xFF8B9CC8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Colors.white.withOpacity(0.1), height: 24),
          ),

          // ── Nav items ─────────────────────────────────────
          ...List.generate(_menuItems.length, (i) {
            return _navItem(_menuItems[i], i);
          }),

          const Spacer(),

          // ── Pengumuman button ──────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: InkWell(
              onTap: _showKirimPengumuman,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: kAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kAccent.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.campaign_rounded,
                      color: Color(0xFF93A8F4),
                      size: 19,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Kirim Pengumuman',
                      style: TextStyle(
                        color: Color(0xFF93A8F4),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: InkWell(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text(
                      'Apakah kamu yakin ingin keluar dari admin?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminLoginPage()),
                    (route) => false,
                  );
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.red, size: 19),
                    SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Info admin ─────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: kAccent,
                  child: Icon(Icons.person, size: 15, color: Colors.white),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Administrator',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'v1.0.0',
                        style: TextStyle(
                          color: Color(0xFF8B9CC8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(_MenuItem item, int index) {
    final active = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? kAccent.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? kAccent.withOpacity(0.4) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              color: active ? Colors.white : const Color(0xFF8B9CC8),
              size: 19,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  color: active ? Colors.white : const Color(0xFF8B9CC8),
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
            if (active)
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: kAccent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOP BAR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTopBar() {
    final item = _menuItems[_currentIndex];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: const BoxDecoration(
        color: kCard,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Breadcrumb
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: kNavy,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                item.subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const Spacer(),

          // Tanggal hari ini
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 8),
                Text(
                  _todayStr(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _todayStr() {
    final now = DateTime.now();
    const bulan = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${now.day} ${bulan[now.month]} ${now.year}';
  }

  // ═══════════════════════════════════════════════════════════════
  // KIRIM PENGUMUMAN
  // ═══════════════════════════════════════════════════════════════
  void _showKirimPengumuman() {
    final ctrl = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kNavy.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: kNavy,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Kirim Pengumuman',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kNavy,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: TextField(
                controller: ctrl,
                maxLines: 5,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Tulis pesan pengumuman ke semua user...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFB0BAD0),
                  ),
                  filled: true,
                  fillColor: kBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: kAccent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: loading
                    ? null
                    : () async {
                        final msg = ctrl.text.trim();
                        if (msg.isEmpty) return;
                        setSt(() => loading = true);
                        try {
                          final users = await FirebaseFirestore.instance
                              .collection('users')
                              .get();
                          final batch = FirebaseFirestore.instance.batch();
                          for (final user in users.docs) {
                            final ref = FirebaseFirestore.instance
                                .collection('notifications')
                                .doc();
                            batch.set(ref, {
                              'toUid': user.id,
                              'fromUid': 'admin',
                              'fromName': 'Admin',
                              'fromPhoto': '',
                              'type': 'admin',
                              'postId': '',
                              'postImage': '',
                              'message': msg,
                              'createdAt': FieldValue.serverTimestamp(),
                              'isRead': false,
                            });
                          }
                          await batch.commit();
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            showSnack(
                              context,
                              'Pengumuman terkirim ke ${users.docs.length} user',
                            );
                          }
                        } catch (e) {
                          setSt(() => loading = false);
                          showSnack(
                            context,
                            'Gagal mengirim: $e',
                            isError: true,
                          );
                        }
                      },
                icon: loading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
                label: const Text(
                  'Kirim',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MODEL MENU
// ═══════════════════════════════════════════════════════════════
class _MenuItem {
  final IconData icon;
  final String label;
  final String subtitle;
  const _MenuItem(this.icon, this.label, this.subtitle);
}
