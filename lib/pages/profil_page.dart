import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jurnal_jatim_carnival/pages/create_account.dart';
import 'package:jurnal_jatim_carnival/pages/login_page.dart';
import 'package:jurnal_jatim_carnival/services/auth_service.dart';
import '../data/custom_navbar.dart';
import 'home_page.dart';
import 'select_photo_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:jurnal_jatim_carnival/pages/comment_page.dart';
import 'package:jurnal_jatim_carnival/data/profile_cache.dart';
import 'package:jurnal_jatim_carnival/data/event_terbaru.dart';
import 'package:jurnal_jatim_carnival/pages/event_terbaru_detail.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'login_page.dart';
import 'package:jurnal_jatim_carnival/data/guest_guard.dart';
import 'package:jurnal_jatim_carnival/data/auth_state.dart';

// ==================== POST DETAIL PAGE ====================
class PostDetailPage extends StatelessWidget {
  const PostDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF0F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D336B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Postingan',
          style: TextStyle(color: Color(0xFFFFF6F2), fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildHeader(),
            const SizedBox(height: 12),
            _buildImage(),
            const SizedBox(height: 12),
            _buildActions(),
            const SizedBox(height: 12),
            _buildDescription(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundImage: AssetImage('assets/images/pp.png'),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'pakiswell',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Jazz Traffic Festival',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          const Icon(Icons.bookmark_border, color: Color(0xFF7886C7)),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Image.asset(
      'assets/images/event1.png',
      width: double.infinity,
      height: 280,
      fit: BoxFit.cover,
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: const [
          Icon(Icons.favorite_border, size: 26, color: Color(0xFF7886C7)),
          SizedBox(width: 16),
          Icon(Icons.mode_comment_outlined, size: 26, color: Color(0xFF7886C7)),
          SizedBox(width: 16),
          Icon(Icons.bookmark_border, size: 26, color: Color(0xFF7886C7)),
          Spacer(),
          Text("27–28/09/2025"),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'pakiswell',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            'Pengalaman saya di JTF Surabaya, sangat seru',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          SizedBox(height: 12),
          Text('Hari: Sabtu–Minggu', style: TextStyle(fontSize: 14)),
          SizedBox(height: 4),
          Text(
            'Tempat: Grand City Convex, Surabaya',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ==================== PROFILE PAGE ====================
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController; // ✅ tambah ini
  int _currentIndex = 2;

  List<Map<String, dynamic>> _savedPosts = [];
  List<Map<String, dynamic>> _likedPosts = [];
  List<Map<String, dynamic>> _myPosts = [];

  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();

  String name = "";
  String bio = "";
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // ✅ tambah ini
    _tabController.addListener(() {
      // ✅ tambah ini
      if (_tabController.indexIsChanging) {
        if (_tabController.index == 0) _loadMyPosts();
        if (_tabController.index == 1) _loadLikedPosts();
        if (_tabController.index == 2) _loadSavedPosts();
      }
    });
    _loadProfile();
    _loadMyPosts();
    _loadSavedPosts();
    _loadLikedPosts();
  }

  @override
  void dispose() {
    _tabController.dispose(); // ✅ tambah ini
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (ProfileCache.photoUrl != null) {
      setState(() {
        name = ProfileCache.name ?? "";
        bio = ProfileCache.bio ?? "";
        imageUrl = ProfileCache.photoUrl;
      });
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        ProfileCache.photoUrl = data['photoUrl'];
        name = data['displayName'] ?? "";
        bio = data['bio'] ?? "";
        imageUrl = data['photoUrl'];
      });
    }
  }

  // ✅ Fetch postingan sendiri
  Future<void> _loadMyPosts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('post')
        .where('uid', isEqualTo: uid)
        .get();
    setState(() {
      _myPosts = snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> _loadSavedPosts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // ✅ Fetch dari collection post
    final postSnap = await FirebaseFirestore.instance
        .collection('post')
        .where('savedBy', arrayContains: uid)
        .get();

    // ✅ Fetch dari collection event_terbaru
    final eventSnap = await FirebaseFirestore.instance
        .collection('event_terbaru')
        .where('savedBy', arrayContains: uid)
        .get();

    setState(() {
      _savedPosts = [
        ...postSnap.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }),
        ...eventSnap.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          data['isEventTerbaru'] = true; // ✅ flag
          return data;
        }),
      ];
    });
  }

  Future<void> _loadLikedPosts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final postSnap = await FirebaseFirestore.instance
        .collection('post')
        .where('likedBy', arrayContains: uid)
        .get();

    final eventSnap = await FirebaseFirestore.instance
        .collection('event_terbaru')
        .where('likedBy', arrayContains: uid)
        .get();

    setState(() {
      _likedPosts = [
        ...postSnap.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }),
        ...eventSnap.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          data['isEventTerbaru'] = true;
          return data;
        }),
      ];
    });
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  void _openEditProfile() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditProfilePage(name: name, bio: bio, photoUrl: imageUrl),
      ),
    );
    if (result != null) {
      setState(() {
        name = result['name'] ?? "";
        bio = result['bio'] ?? "";
        imageUrl = result['photoUrl'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF2F2),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProfileSection(context),
            _buildBio(),
            const SizedBox(height: 20),
            _buildTabIcons(),
            const SizedBox(height: 16),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFFFFF2F2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name.isNotEmpty
                ? name
                : _currentUser?.email?.split('@')[0] ?? 'Guest',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2D3561),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                        ? (imageUrl!.startsWith('data:image')
                              ? MemoryImage(
                                  base64Decode(imageUrl!.split(',')[1]),
                                )
                              : NetworkImage(imageUrl!) as ImageProvider)
                        : const AssetImage('assets/images/profilkosong.jpg'),
                    backgroundColor: const Color(0xFF6C7FD8),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFCF0F2),
                      width: 2.5,
                    ),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.add,
                      color: Color(0xFFFFF6F2),
                      size: 15,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SelectPhotoPage(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'postingan',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF4A5A8A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 90),
                    GestureDetector(
                      onTap: _openEditProfile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D3561),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'Edit profil',
                          style: TextStyle(
                            color: Color(0xFFFFF6F2),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _currentUser?.email ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBio() {
    return Padding(
      padding: const EdgeInsets.only(left: 90),
      child: Text(
        bio,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildTabIcons() {
    return TabBar(
      controller: _tabController,
      indicatorColor: const Color(0xFF7B8FC7),
      indicatorWeight: 2.5,
      indicatorSize: TabBarIndicatorSize.tab,
      splashFactory: NoSplash.splashFactory,
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      tabs: [
        Tab(
          icon: Image.asset(
            'assets/images/Vector-1.png',
            width: 24,
            height: 24,
            color: const Color(0xFF7B8FC7),
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.grid_on, size: 24, color: Color(0xFF7B8FC7)),
          ),
        ),
        const Tab(
          icon: Icon(Icons.favorite_border, size: 24, color: Color(0xFF7B8FC7)),
        ),
        const Tab(
          icon: Icon(Icons.bookmark_border, size: 24, color: Color(0xFF7B8FC7)),
        ),
      ],
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildPostGrid(_myPosts, 'Belum ada postingan'),
        _buildPostGrid(_likedPosts, 'Belum ada postingan yang disukai'),
        _buildPostGrid(_savedPosts, 'Belum ada postingan yang disimpan'),
      ],
    );
  }

  Widget _buildPostGrid(List<Map<String, dynamic>> posts, String emptyMsg) {
    if (posts.isEmpty) {
      return Center(
        child: Text(emptyMsg, style: const TextStyle(color: Colors.black54)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final imageUrl = post['imageUrl'] ?? '';
        final isEventTerbaru = post['isEventTerbaru'] == true; // ✅ cek flag

        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => post['isEventTerbaru'] == true
                    ? EventTerbaruDetailPage(
                        event: EventTerbaru(
                          title: post['title'] ?? '',
                          location: post['location'] ?? '',
                          date: post['date'] ?? '',
                          imageUrl: post['imageUrl'] ?? '',
                          isFree: post['isFree'] ?? false,
                          postId: post['id'] ?? '',
                        ),
                      )
                    : PostDetailFromFirestore(postData: post),
              ),
            );

            _loadMyPosts();
            _loadSavedPosts();
            _loadLikedPosts();
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Gambar
                imageUrl.startsWith('data:image')
                    ? Image.memory(
                        base64Decode(imageUrl.split(',').last),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF2D3561),
                          child: const Icon(Icons.image, color: Colors.white),
                        ),
                      )
                    : Image.asset(
                        imageUrl.isNotEmpty
                            ? imageUrl
                            : 'assets/images/logowebku.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF2D3561),
                          child: const Icon(Icons.image, color: Colors.white),
                        ),
                      ),

                // ✅ Badge Event Terbaru
                if (isEventTerbaru)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D3561).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Terbaru',
                        style: TextStyle(
                          color: Color(0xFFFFF6F2),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==================== EDIT PROFILE PAGE ====================
class EditProfilePage extends StatefulWidget {
  final String name;
  final String bio;
  final String? photoUrl;

  const EditProfilePage({
    super.key,
    required this.name,
    required this.bio,
    this.photoUrl,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  String? _selectedImageUrl;
  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();
  late TextEditingController nameController;
  late TextEditingController bioController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    bioController = TextEditingController(text: widget.bio);
    _selectedImageUrl = widget.photoUrl;
  }

  Future<String?> _uploadPhoto() async {
    if (_selectedImageFile == null) return null;
    final bytes = await _selectedImageFile!.readAsBytes();
    final base64String = base64Encode(bytes);
    return 'data:image/jpeg;base64,$base64String';
  }

  Future<void> _executeLogOut() async {
    try {
      // 1. Keluar dari Firebase Auth
      await FirebaseAuth.instance.signOut();

      // 2. Keluar dari Google Sign-In (supaya cache akun terhapus)
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      // 3. Bersihkan cache profil lokal jika ada
      ProfileCache.photoUrl = null;
      ProfileCache.name = null;
      ProfileCache.bio = null;

      // 4. Tendang user kembali ke halaman Login dan hapus semua tumpukan halaman terdahulu
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginPage(),
          ), // Pastikan nama class LoginPage kamu sudah benar
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal log out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // 1. Tentukan nilai photoUrl yang akan disimpan
      String finalPhotoUrl;

      if (_selectedImageFile != null) {
        // A. Jika ada file gambar baru (dari galeri/kamera), baru jalankan fungsi upload
        finalPhotoUrl = await _uploadPhoto() ?? _selectedImageUrl ?? '';
      } else {
        // B. Jika tidak pilih foto baru, amankan foto yang sudah ada sekarang (termasuk string kosong jika habis dihapus)
        finalPhotoUrl = _selectedImageUrl ?? '';
      }

      // 2. Simpan atau update ke Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'displayName': nameController.text.trim(),
        'user': nameController.text
            .trim(), // 💡 Tambahkan ini agar sinkron dengan StreamBuilder postingan Anda sebelumnya!
        'bio': bioController.text.trim(),
        'email': FirebaseAuth.instance.currentUser!.email,
        'uid': uid,
        'photoUrl':
            finalPhotoUrl, // 💡 Selalu kirim nilai foto terkini agar tidak hilang
      }, SetOptions(merge: true));

      // 3. Update nama di Firebase Auth
      await FirebaseAuth.instance.currentUser!.updateDisplayName(
        nameController.text.trim(),
      );

      // 4. Kembali ke halaman sebelumnya dengan membawa data terbaru
      if (mounted) {
        Navigator.pop(context, {
          'name': nameController.text.trim(),
          'bio': bioController.text.trim(),
          'photoUrl':
              finalPhotoUrl, // Kirim status foto terakhir (aman dari null)
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF6F2),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2D3561),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF142C6E).withOpacity(0.2)),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFFFFF6F2),
                size: 16,
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Edit profil',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _showPhotoOptions(context),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _selectedImageFile != null
                      ? FileImage(_selectedImageFile!) as ImageProvider
                      : (_selectedImageUrl != null &&
                                _selectedImageUrl!
                                    .isNotEmpty // 💡 1. Pastikan tidak null DAN tidak kosong
                            ? (_selectedImageUrl!.startsWith('data:image')
                                  ? MemoryImage(
                                      base64Decode(
                                        _selectedImageUrl!.split(',')[1],
                                      ),
                                    )
                                  : _selectedImageUrl!.startsWith(
                                      'http',
                                    ) // 💡 2. Cek jika ini URL internet (Firebase)
                                  ? NetworkImage(_selectedImageUrl!)
                                        as ImageProvider
                                  : AssetImage(_selectedImageUrl!)
                                        as ImageProvider) // 💡 3. Jika jalur aset lokal
                            : const AssetImage(
                                'assets/images/profilkosong.jpg',
                              )), // ✅ Fallback jika kosong/null
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _showPhotoOptions(context),
                child: const Text(
                  'Ubah foto profil',
                  style: TextStyle(color: Color(0xFF7B8FC7), fontSize: 18),
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField('Nama', controller: nameController),
              const SizedBox(height: 20),
              _buildTextField(
                'Tentang kamu',
                controller: bioController,
                maxLines: 3,
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showAccountOptions(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D3561),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Ganti akun',
                        style: TextStyle(color: Color(0xFFFFF6F2)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D3561),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Color(0xFF2D3561),
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Simpan',
                              style: TextStyle(color: Color(0xFFFFF6F2)),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    required TextEditingController controller,
    int? maxLines,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines ?? 1,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF2D3561),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF2D3561),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFF2D3561),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          filled: true,
          fillColor: const Color(0xFFFFF6F2),
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
            borderSide: const BorderSide(color: Color(0xFF2D3561), width: 1.5),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: const Color(0xFF2D3561).withOpacity(0.4),
                    size: 18,
                  ),
                  onPressed: () => controller.clear(),
                )
              : null,
        ),
      ),
    );
  }

  void _showPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2D3561),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 40,
              backgroundImage: _selectedImageFile != null
                  ? FileImage(_selectedImageFile!) as ImageProvider
                  : (_selectedImageUrl != null &&
                            _selectedImageUrl!
                                .isNotEmpty // 💡 1. Amankan dari string kosong ('')
                        ? (_selectedImageUrl!.startsWith('data:image')
                              ? MemoryImage(
                                  base64Decode(
                                    _selectedImageUrl!.split(',')[1],
                                  ),
                                )
                              : _selectedImageUrl!.startsWith(
                                  'http',
                                ) // 💡 2. Handle jika gambarnya dari URL internet
                              ? NetworkImage(_selectedImageUrl!)
                                    as ImageProvider
                              : AssetImage(_selectedImageUrl!) as ImageProvider)
                        : const AssetImage(
                            'assets/images/profilkosong.jpg',
                          )), // ✅ Fallback otomatis ke foto dasar
            ),
            const SizedBox(height: 20),
            _buildBottomSheetOption(
              icon: Icons.photo_library,
              label: 'Pilih dari galeri',
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (image != null) {
                  setState(() => _selectedImageFile = File(image.path));
                }
              },
            ),
            _buildBottomSheetOption(
              icon: Icons.camera_alt,
              label: 'Ambil foto',
              onTap: () => Navigator.pop(context),
            ),
            _buildBottomSheetOption(
              icon: Icons.delete_outline,
              label: 'Hapus Foto Profil',
              isDestructive:
                  true, // 👈 Ini akan otomatis membuat icon & teks berwarna merah
              onTap: () {
                Navigator.pop(context); // 1. Tutup bottom sheet terlebih dahulu
                _hapusFotoProfil(); // 2. Jalankan fungsi hapus foto yang sudah kita buat
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAccountOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2D3561),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tambahkan akun',
                style: TextStyle(
                  color: Color(0xFFFFF6F2),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3561),
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(color: Color(0xFF7B8FC7)),
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(color: Color(0xFFFFF6F2), fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateAccountPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFFF6F2),
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Buat Akun',
                  style: TextStyle(color: Color(0xFF2D3561), fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              // CARI KODE INI DI BAGIAN BAWAH ELEVATED BUTTON KAMU:
              ElevatedButton(
                onPressed:
                    _executeLogOut, // 👈 Ganti bagian ini untuk memanggil fungsi log out
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Keluar Akun', // 👈 Kamu bisa ganti teksnya jadi lebih jelas
                  style: TextStyle(color: Color(0xFFFFF6F2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.white),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.white,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _hapusFotoProfil() async {
    setState(() {
      // 1. Kosongkan variabel lokal agar CircleAvatar langsung berubah ke foto dasar
      _selectedImageFile = null;
      _selectedImageUrl = null;
    });

    try {
      final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      // 2. Update di Firestore dengan string kosong atau null
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'photoUrl': '', // Set jadi string kosong agar di database juga terhapus
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
                Icons.checklist_outlined,
                color: Color(0xFF6C7FD8),
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Berhasil hapus foto profil.",
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
    } catch (e) {
      print("Gagal menghapus foto di database: $e");
    }
  }
}

// ==================== PHOTO GALLERY PAGE ====================
class PhotoGalleryPage extends StatefulWidget {
  final Function(String) onPhotoSelected;
  const PhotoGalleryPage({super.key, required this.onPhotoSelected});

  @override
  State<PhotoGalleryPage> createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends State<PhotoGalleryPage> {
  String? _selectedPhoto;
  final List<String> _photos = [
    'assets/images/event1.png',
    'assets/images/event2.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF6F2),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2D3561),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF142C6E).withOpacity(0.2)),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Pilih foto',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          if (_selectedPhoto != null)
            Container(
              height: 250,
              width: 250,
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(150),
                child: Image.asset(_selectedPhoto!, fit: BoxFit.cover),
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(top: 20, left: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedPhoto = _photos[index]),
                  child: Container(
                    decoration: BoxDecoration(
                      border: _selectedPhoto == _photos[index]
                          ? Border.all(color: const Color(0xFF7B8FC7), width: 5)
                          : null,
                    ),
                    child: Image.asset(_photos[index], fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
          if (_selectedPhoto != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: ElevatedButton(
                onPressed: () {
                  widget.onPhotoSelected(_selectedPhoto!);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C7FD8),
                  minimumSize: const Size(120, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Simpan',
                  style: TextStyle(color: Color(0xFFFFF6F2), fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class UserModel {
  final String uid;
  final String email;
  final String
  user; // 👈 Pastikan di sini namanya 'user' (bukan displayName / username)
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.email,
    required this.user, // 👈 Ubah juga di constructor ini
    this.photoUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      user: map['user'] ?? map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'email': email, 'user': user, 'photoUrl': photoUrl};
  }
}

class _VideoPost extends StatefulWidget {
  final String videoBase64;
  const _VideoPost({required this.videoBase64});

  @override
  State<_VideoPost> createState() => _VideoPostState();
}

class _VideoPostState extends State<_VideoPost> {
  VideoPlayerController? controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      // ✅ Ambil hanya data base64 tanpa prefix
      final base64Str = widget.videoBase64.contains(',')
          ? widget.videoBase64.split(',').last
          : widget.videoBase64;

      final bytes = base64Decode(base64Str);
      final tempDir = await Directory.systemTemp.createTemp();
      final file = File(
        '${tempDir.path}/video_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      await file.writeAsBytes(bytes);

      controller = VideoPlayerController.file(file);
      await controller!.initialize();
      controller!.setLooping(true);

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Error load video: $e');
      if (mounted)
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AspectRatio(
        aspectRatio: 3 / 4,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF2D3561)),
        ),
      );
    }

    if (_hasError || controller == null || !controller!.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 3 / 4,
        child: Center(
          child: Icon(Icons.videocam_off, color: Colors.grey, size: 40),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          controller!.value.isPlaying
              ? controller!.pause()
              : controller!.play();
        });
      },
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller!.value.size.width,
                height: controller!.value.size.height,
                child: VideoPlayer(controller!),
              ),
            ),
            if (!controller!.value.isPlaying)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white70,
                    size: 60,
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                controller!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Color(0xFF6C7FD8),
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoCarousel extends StatefulWidget {
  final List<String> videoUrls;

  const _VideoCarousel({required this.videoUrls});

  @override
  State<_VideoCarousel> createState() => _VideoCarouselState();
}

class _VideoCarouselState extends State<_VideoCarousel> {
  int current = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: PageView.builder(
        itemCount: widget.videoUrls.length,
        onPageChanged: (i) {
          setState(() {
            current = i;
          });
        },
        itemBuilder: (context, index) {
          return _VideoPost(videoBase64: widget.videoUrls[index]);
        },
      ),
    );
  }
}

// ==================== POST DETAIL FROM FIRESTORE ====================
class PostDetailFromFirestore extends StatefulWidget {
  final Map<String, dynamic> postData;
  const PostDetailFromFirestore({super.key, required this.postData});

  @override
  State<PostDetailFromFirestore> createState() =>
      _PostDetailFromFirestoreState();
}

class _PostDetailFromFirestoreState extends State<PostDetailFromFirestore> {
  bool isLiked = false;
  bool isSaved = false;
  int likeCount = 0;
  int _currentImagePage = 0;
  final PageController _imagePageController = PageController();

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final likedBy = List<String>.from(widget.postData['likedBy'] ?? []);
    final savedBy = List<String>.from(widget.postData['savedBy'] ?? []);
    isLiked = likedBy.contains(uid);
    isSaved = savedBy.contains(uid);
    likeCount = widget.postData['likeCount'] ?? 0;
  }

  Future<void> _toggleLike() async {
    if (!guardGuest(context)) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final docRef = FirebaseFirestore.instance
        .collection('post')
        .doc(widget.postData['id']);
    final likedBy = List<String>.from(widget.postData['likedBy'] ?? []);
    setState(() {
      if (isLiked) {
        isLiked = false;
        likeCount--;
        likedBy.remove(uid);
      } else {
        isLiked = true;
        likeCount++;
        likedBy.add(uid);
      }
      widget.postData['likedBy'] = likedBy;
      widget.postData['likeCount'] = likeCount;
    });
    await docRef.update({'likeCount': likeCount, 'likedBy': likedBy});

    // ✅ Kirim notifikasi like
    if (isLiked && widget.postData['uid'] != uid) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final senderName = userDoc['displayName'] ?? 'Seseorang';
      final senderPhoto = userDoc['photoUrl'] ?? '';

      await FirebaseFirestore.instance.collection('notifications').add({
        'toUid': widget.postData['uid'] ?? '',
        'fromUid': uid,
        'fromName': senderName,
        'fromPhoto': senderPhoto,
        'type': 'like',
        'postId': widget.postData['id'],
        'postImage': widget.postData['imageUrl'] ?? '',
        'message': 'Menyukai postingan anda',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
  }

  Future<void> _toggleSave() async {
    if (!guardGuest(context)) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final docRef = FirebaseFirestore.instance
        .collection('post')
        .doc(widget.postData['id']);
    final savedBy = List<String>.from(widget.postData['savedBy'] ?? []);
    setState(() {
      if (isSaved) {
        isSaved = false;
        savedBy.remove(uid);
      } else {
        isSaved = true;
        savedBy.add(uid);
      }
      widget.postData['savedBy'] = savedBy;
    });
    await docRef.update({'savedBy': savedBy});

    // ✅ Kirim notifikasi save
    if (isSaved && widget.postData['uid'] != uid) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final senderName = userDoc['displayName'] ?? 'Seseorang';
      final senderPhoto = userDoc['photoUrl'] ?? '';

      await FirebaseFirestore.instance.collection('notifications').add({
        'toUid': widget.postData['uid'] ?? '',
        'fromUid': uid,
        'fromName': senderName,
        'fromPhoto': senderPhoto,
        'type': 'save',
        'postId': widget.postData['id'],
        'postImage': widget.postData['imageUrl'] ?? '',
        'message': 'Menyimpan postingan anda',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
  }

  Future<void> _sendShareNotification() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty || widget.postData['uid'] == uid) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    await FirebaseFirestore.instance.collection('notifications').add({
      'toUid': widget.postData['uid'] ?? '',
      'fromUid': uid,
      'fromName': userDoc['displayName'] ?? 'Seseorang',
      'fromPhoto': userDoc['photoUrl'] ?? '',
      'type': 'share',
      'postId': widget.postData['id'],
      'postImage': widget.postData['imageUrl'] ?? '',
      'message': 'Membagikan postingan anda',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.postData['imageUrl'] ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF6F2),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFF2D3561),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            // Header
            Padding(
              padding: const EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: 10,
              ),
              child: Row(
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    // 1. Pantau data user berdasarkan UID pembuat postingan secara realtime
                    // SESUDAH — aman, pakai dummy stream kalau uid kosong
                    stream: (widget.postData['uid'] ?? '').toString().isNotEmpty
                        ? FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.postData['uid'].toString())
                              .snapshots()
                        : const Stream.empty(),
                    builder: (context, snapshot) {
                      String pp = '';

                      // 2. Ambil foto terbaru dari koleksi users jika dokumennya ada
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        pp = data['photoUrl'] ?? '';
                      }

                      // 3. Jika di data user kosong, gunakan fallback ke data bawaan postingan lama
                      if (pp.isEmpty) {
                        pp =
                            widget.postData['profileImage'] ??
                            widget.postData['profilImage'] ??
                            '';
                      }

                      // 4. Kembalikan struktur CircleAvatar milik Anda
                      return CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey.shade300,
                        child: ClipOval(
                          child: (() {
                            // Jika ada data fotonya (tidak kosong)
                            if (pp.isNotEmpty) {
                              // A. Jika formatnya Base64 (data:image)
                              if (pp.startsWith('data:image')) {
                                return Image.memory(
                                  base64Decode(pp.split(',').last),
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                );
                              }
                              // B. Jika gambarnya dari URL internet/Firebase Storage
                              else if (pp.startsWith('http')) {
                                return Image.network(
                                  pp,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Image.asset(
                                    'assets/images/profilkosong.jpg',
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              }
                              // C. Jika jalurnya berupa aset lokal bawaan
                              else {
                                return Image.asset(
                                  pp,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Image.asset(
                                    'assets/images/profilkosong.jpg',
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              }
                            }

                            // 5. JIKA BENAR-BENAR KOSONG, kembalikan ke foto dasar akun
                            return Image.asset(
                              'assets/images/profilkosong.jpg', // Disamakan dengan nama aset foto dasar Anda
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            );
                          })(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StreamBuilder<DocumentSnapshot>(
                          // 1. Pantau data user berdasarkan UID pembuat postingan secara realtime
                          // SESUDAH — aman, pakai dummy stream kalau uid kosong
                          stream:
                              (widget.postData['uid'] ?? '')
                                  .toString()
                                  .isNotEmpty
                              ? FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(widget.postData['uid'].toString())
                                    .snapshots()
                              : const Stream.empty(),
                          builder: (context, snapshot) {
                            // 2. Gunakan nama dari data postingan lama sebagai cadangan (fallback)
                            String namaTerbaru = widget.postData['user'] ?? '';

                            // 3. Jika data profil terbaru ada di database, pakai nama yang paling baru
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final data =
                                  snapshot.data!.data() as Map<String, dynamic>;
                              namaTerbaru =
                                  data['user'] ??
                                  data['displayName'] ??
                                  widget.postData['user'] ??
                                  '';
                            }

                            // 4. Tampilkan teks nama yang sudah pasti selalu update
                            return Text(
                              namaTerbaru.isNotEmpty ? namaTerbaru : 'Anonim',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            );
                          },
                        ),
                        Text(
                          widget.postData['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ✅ Tombol delete hanya untuk pemilik post
                  if (FirebaseAuth.instance.currentUser?.uid ==
                      widget.postData['uid'])
                    GestureDetector(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: const Color(0xFF2D3561),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text(
                              'Hapus Postingan?',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            content: const Text(
                              'Postingan ini akan dihapus permanen.',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text(
                                  'Batal',
                                  style: TextStyle(color: Color(0xFF6C7FD8)),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Hapus',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          final postId = widget.postData['id'] ?? '';
                          if (postId.isNotEmpty) {
                            await FirebaseFirestore.instance
                                .collection('post')
                                .doc(postId)
                                .delete();
                            if (mounted) Navigator.pop(context);
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D336B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: const Color(0xFFFFF6F2),
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Gambar
            Builder(
              builder: (context) {
                final List<String> imageUrls = List<String>.from(
                  widget.postData['imageUrls'] ?? [],
                );
                if (imageUrls.isEmpty && imageUrl.isNotEmpty) {
                  imageUrls.add(imageUrl);
                }

                if (imageUrls.isEmpty) return const SizedBox();

                if (imageUrls.length == 1) {
                  final videoUrls = List<String>.from(
                    widget.postData['videoUrls'] ?? [],
                  );

                  final imageUrls = List<String>.from(
                    widget.postData['imageUrls'] ?? [],
                  );

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: ClipRRect(
                      child: AspectRatio(
                        aspectRatio: 3 / 4,
                        child: Container(
                          width: double.infinity,
                          color: const Color(0xFF2D3561).withOpacity(0.08),

                          child: Builder(
                            builder: (context) {
                              // VIDEO
                              if (videoUrls.isNotEmpty) {
                                return _VideoPost(videoBase64: videoUrls.first);
                              }

                              // IMAGE
                              if (imageUrls.isNotEmpty) {
                                final imageUrl = imageUrls.first;

                                // BASE64 IMAGE
                                if (imageUrl.startsWith('data:image')) {
                                  return Image.memory(
                                    base64Decode(imageUrl.split(',').last),
                                    fit: BoxFit.contain,
                                  );
                                }

                                // NETWORK IMAGE
                                if (imageUrl.startsWith('http')) {
                                  return Image.network(
                                    imageUrl,
                                    fit: BoxFit.contain,
                                  );
                                }

                                // ASSET IMAGE
                                return Image.asset(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                );
                              }

                              // EMPTY
                              return const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // ✅ Banyak foto — carousel portrait
                return StatefulBuilder(
                  builder: (context, setLocal) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: ClipRRect(
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              PageView.builder(
                                controller: _imagePageController,
                                itemCount: imageUrls.length,
                                onPageChanged: (i) =>
                                    setLocal(() => _currentImagePage = i),
                                itemBuilder: (context, index) {
                                  final url = imageUrls[index];
                                  return url.startsWith('data:image')
                                      ? Image.memory(
                                          base64Decode(url.split(',').last),
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                color: Colors.grey.shade300,
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  size: 10,
                                                ),
                                              ),
                                        )
                                      : Image.asset(
                                          url.isNotEmpty
                                              ? url
                                              : 'assets/images/logowebku.png',
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                color: Colors.grey.shade300,
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  size: 10,
                                                ),
                                              ),
                                        );
                                },
                              ),

                              // Counter
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_currentImagePage + 1}/${imageUrls.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              // Dot indicator
                              Positioned(
                                bottom: 12,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    imageUrls.length,
                                    (i) => AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      width: _currentImagePage == i ? 16 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _currentImagePage == i
                                            ? Colors.white
                                            : Colors.white54,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _toggleLike,
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 26,
                      color: const Color(0xFF7886C7),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$likeCount',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7886C7),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(
                      Icons.mode_comment_outlined,
                      size: 26,
                      color: Color(0xFF7886C7),
                    ),
                    onPressed: () {
                      final postId = widget.postData['id'] ?? '';
                      if (postId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Post ID tidak ditemukan'),
                          ),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CommentPage(postId: postId),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _toggleSave,
                    child: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      size: 26,
                      color: const Color(0xFF7886C7),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.share_outlined,
                      size: 26,
                      color: Color(0xFF7886C7),
                    ),
                    onPressed: () async {
                      // ✅ Kirim notifikasi share
                      await _sendShareNotification();
                      Share.share(
                        "🎪 Event: ${widget.postData['title'] ?? ''}\n"
                        "📍 ${widget.postData['place'] ?? ''}\n"
                        "📅 ${widget.postData['date'] ?? ''}\n"
                        "🎫 ${widget.postData['ticketType'] ?? 'Gratis'}\n\n"
                        "Cari di app Jurnal Jatim Carnival!",
                      );
                    },
                  ),
                  const Spacer(),
                  Text(
                    widget.postData['date'] ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

            // Deskripsi
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    // 1. Pantau data user berdasarkan UID pembuat postingan secara realtime
                    // SESUDAH — aman, pakai dummy stream kalau uid kosong
                    stream: (widget.postData['uid'] ?? '').toString().isNotEmpty
                        ? FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.postData['uid'].toString())
                              .snapshots()
                        : const Stream.empty(),
                    builder: (context, snapshot) {
                      // 2. Gunakan nama dari data postingan lama sebagai cadangan (fallback)
                      String namaTerbaru = widget.postData['user'] ?? '';

                      // 3. Jika data profil terbaru ada di database, pakai nama yang paling baru
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        namaTerbaru =
                            data['user'] ??
                            data['displayName'] ??
                            widget.postData['user'] ??
                            '';
                      }

                      // 4. Tampilkan teks nama yang sudah pasti selalu update
                      return Text(
                        namaTerbaru.isNotEmpty ? namaTerbaru : 'Anonim',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(widget.postData['description'] ?? ''),
                  const SizedBox(height: 10),
                  Text(
                    "Hari: ${widget.postData['day'] ?? ''}",
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Tempat: ${widget.postData['place'] ?? ''}",
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        widget.postData['ticketType'] == 'Berbayar'
                            ? Icons.attach_money
                            : Icons.money_off,
                        size: 16,
                        color: widget.postData['ticketType'] == 'Berbayar'
                            ? Colors.red
                            : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.postData['ticketType'] ?? 'Gratis',
                        style: TextStyle(
                          fontSize: 15,
                          color: widget.postData['ticketType'] == 'Berbayar'
                              ? Colors.red
                              : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Di dalam Padding deskripsi, setelah Row tiket:
                  if ((widget.postData['link'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse(widget.postData['link']);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D3561),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF6C7FD8),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C7FD8).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.confirmation_number_outlined,
                                color: Color(0xFFFFF6F2),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Info & Pesan Tiket',
                                    style: TextStyle(
                                      color: Color(0xFFFFF6F2),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.postData['link'],
                                    style: const TextStyle(
                                      color: Color(0xFFFFF6F2),
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Color(0xFF6C7FD8),
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
