// ignore_for_file: deprecated_member_use
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ tambah ini
import 'package:jurnal_jatim_carnival/pages/city_page.dart';
import 'package:jurnal_jatim_carnival/pages/notification_page.dart';
import 'after_search.dart';
import 'package:jurnal_jatim_carnival/data/event_post.dart';
import 'comment_page.dart';
import 'profil_page.dart';
import '../data/custom_navbar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:jurnal_jatim_carnival/data/event_terbaru.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:jurnal_jatim_carnival/pages/event_terbaru_detail.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:jurnal_jatim_carnival/data/guest_guard.dart';
import 'package:jurnal_jatim_carnival/data/auth_state.dart';

// ✅ HAPUS void main() dan MyApp — sudah ada di main.dart

/// ================== EVENT CARD ==================
class EventCardSmall extends StatefulWidget {
  final EventPost post;

  const EventCardSmall({super.key, required this.post});

  @override
  State<EventCardSmall> createState() => _EventCardSmallState();
}

class _EventCardSmallState extends State<EventCardSmall> {
  bool isLiked = false;
  bool isSaved = false;

  @override
  void initState() {
    super.initState();

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    isLiked = widget.post.likedBy.contains(uid);
    isSaved = widget.post.savedBy.contains(uid);
  }

  // ✅ tambah fungsi ini
  Future<void> _toggleSave() async {
    if (!guardGuest(context)) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final docRef = FirebaseFirestore.instance
        .collection('post')
        .doc(widget.post.id);

    setState(() {
      if (isSaved) {
        isSaved = false;
        widget.post.savedBy.remove(uid);
      } else {
        isSaved = true;
        widget.post.savedBy.add(uid);
      }
    });

    await docRef.update({'savedBy': widget.post.savedBy});

    // ✅ Kirim notifikasi ke pemilik post
    if (isSaved && widget.post.uid != uid) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final senderName = userDoc['displayName'] ?? 'Seseorang';
      final senderPhoto = userDoc['photoUrl'] ?? '';

      await FirebaseFirestore.instance.collection('notifications').add({
        'toUid': widget.post.uid,
        'fromUid': uid,
        'fromName': senderName,
        'fromPhoto': senderPhoto,
        'type': 'save',
        'postId': widget.post.id,
        'postImage': widget.post.imageUrl,
        'message': 'Menyimpan postingan anda',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
  }

  // ✅ fungsi like ke Firestore
  Future<void> _toggleLike() async {
    if (!guardGuest(context)) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final docRef = FirebaseFirestore.instance
        .collection('post')
        .doc(widget.post.id);

    setState(() {
      if (isLiked) {
        isLiked = false;
        widget.post.likeCount--;
        widget.post.likedBy.remove(uid);
      } else {
        isLiked = true;
        widget.post.likeCount++;
        widget.post.likedBy.add(uid);
      }
    });

    await docRef.update({
      'likeCount': widget.post.likeCount,
      'likedBy': widget.post.likedBy,
    });

    // ✅ Kirim notifikasi ke pemilik post
    if (isLiked && widget.post.uid != uid) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final senderName = userDoc['displayName'] ?? 'Seseorang';
      final senderPhoto = userDoc['photoUrl'] ?? '';

      await FirebaseFirestore.instance.collection('notifications').add({
        'toUid': widget.post.uid, // pemilik post
        'fromUid': uid, // yang ngelike
        'fromName': senderName,
        'fromPhoto': senderPhoto,
        'type': 'like',
        'postId': widget.post.id,
        'postImage': widget.post.imageUrl,
        'message': 'Menyukai postingan anda',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(widget.post),
        _eventImage(widget.post.imageUrl),
        _actionsRow(widget.post),
        _descriptionSection(widget.post),
      ],
    );
  }

  Widget _header(EventPost post) {
    return Padding(
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 10),
      child: Row(
        children: [
          // ✅ Fetch PP realtime dari users
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(post.uid)
                .get(),
            builder: (context, snapshot) {
              String photoUrl =
                  post.profileImage; // fallback ke profileImage lama

              if (snapshot.hasData && snapshot.data!.exists) {
                final userData = snapshot.data!.data() as Map<String, dynamic>;
                photoUrl = userData['photoUrl'] ?? post.profileImage;
              }

              return CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF6C7FD8),
                backgroundImage: photoUrl.isNotEmpty
                    ? (photoUrl.startsWith('data:image')
                          ? MemoryImage(base64Decode(photoUrl.split(',').last))
                          : photoUrl.startsWith('http')
                          ? NetworkImage(photoUrl) as ImageProvider
                          : const AssetImage('assets/images/profilkosong.jpg'))
                    : const AssetImage('assets/images/profilkosong.jpg'),
              );
            },
          ),

          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<DocumentSnapshot>(
                  // 1. Ambil data berdasarkan UID dari object 'post'
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(
                        post.uid ?? '',
                      ) // 💡 Menggunakan 'post.uid' sesuai variabel di EventCardSmall
                      .snapshots(),
                  builder: (context, snapshot) {
                    // 2. Nama cadangan diambil dari 'post.user' bawaan Anda
                    String namaTerbaru = post.user ?? '';

                    // 3. Jika data pembuat post ada di Firestore, ambil nama yang paling baru
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;
                      namaTerbaru =
                          data['user'] ??
                          data['displayName'] ??
                          post.user ??
                          '';
                    }

                    // 4. Tampilkan teks nama pemilik asli postingan tersebut
                    return Text(
                      namaTerbaru.isNotEmpty ? namaTerbaru : 'Anonim',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  post.title,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventImage(String url) {
    // 1. Kalau ada video, jalankan player video terlebih dahulu
    if (widget.post.videoUrls.isNotEmpty) {
      return _VideoCarousel(videoUrls: widget.post.videoUrls);
    }

    // 2. Normalisasi pencarian gambar (deteksi array vs string tunggal secara ketat)
    final List<String> urls = [];
    if (widget.post.imageUrls.isNotEmpty) {
      urls.addAll(widget.post.imageUrls);
    } else if (widget.post.imageUrl.isNotEmpty) {
      urls.add(widget.post.imageUrl);
    } else if (url.isNotEmpty) {
      urls.add(url);
    }

    // Jika benar-benar kosong, pasang placeholder/gagal load
    if (urls.isEmpty) {
      return AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          color: Colors.grey[300],
          child: const Icon(
            Icons.image_not_supported,
            color: Colors.grey,
            size: 50,
          ),
        ),
      );
    }

    // 3. JIKA GAMBAR HANYA ADA 1 (Single Image)
    if (urls.length == 1) {
      final targetUrl = urls.first;

      return AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          width: double.infinity,
          color: const Color(0xFF2D3561).withOpacity(0.08),
          child: Builder(
            builder: (context) {
              // IMAGE BASE64 (Sering digunakan saat upload dari admin web lokal)
              if (targetUrl.startsWith('data:image')) {
                return Image.memory(
                  base64Decode(targetUrl.split(',').last),
                  fit: BoxFit.contain,
                );
              }

              // NETWORK IMAGE (Jika upload admin masuk ke Firebase Storage)
              if (targetUrl.startsWith('http://') ||
                  targetUrl.startsWith('https://')) {
                return Image.network(
                  targetUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                );
              }

              // ASSET IMAGE (Data lokal bawaan)
              return Image.asset(
                targetUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
              );
            },
          ),
        ),
      );
    }

    // 4. JIKA GAMBAR BANYAK (Multiple Images)
    return _ImageCarousel(imageUrls: urls);
  }

  Widget _actionsRow(EventPost post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleLike, // ✅ ganti ke fungsi ini
            child: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              size: 26,
              color: const Color(0xFF7886C7),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            "${post.likeCount}",
            style: const TextStyle(fontSize: 14, color: Color(0xFF7886C7)),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(
              Icons.mode_comment_outlined,
              size: 26,
              color: Color(0xFF7886C7),
            ),
            onPressed: () {
              if (!guardGuest(context)) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CommentPage(postId: widget.post.id),
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
              if (!guardGuest(context)) return;
              final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
              final postId = post.id;
              final shareText =
                  "🎪 Lihat keseruan event '${post.title}'\n"
                  "📍 ${post.place}\n"
                  "📅 ${post.date}\n"
                  "🎫 ${post.ticketType ?? 'Gratis'}\n\n"
                  "Buka di Jurnal Jatim Carnival:\n"
                  "https://jatimcarnival.com/post/$postId";

              await Share.share(shareText);

              // ✅ Kirim notifikasi ke pemilik post
              if (uid.isNotEmpty && post.uid != uid) {
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .get();
                final senderName = userDoc['displayName'] ?? 'Seseorang';
                final senderPhoto = userDoc['photoUrl'] ?? '';

                await FirebaseFirestore.instance
                    .collection('notifications')
                    .add({
                      'toUid': post.uid,
                      'fromUid': uid,
                      'fromName': senderName,
                      'fromPhoto': senderPhoto,
                      'type': 'share',
                      'postId': post.id,
                      'postImage': post.imageUrl,
                      'message': 'Membagikan postingan anda',
                      'createdAt': FieldValue.serverTimestamp(),
                      'isRead': false,
                    });
              }
            },
          ),
          const SizedBox(width: 10),
          const Spacer(),
          Text(post.date),
        ],
      ),
    );
  }

  Widget _descriptionSection(EventPost post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<DocumentSnapshot>(
            // 1. Kita ambil data user terbaru dari Firestore berdasarkan UID si pembuat postingan
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(post.uid)
                .get(),
            builder: (context, snapshot) {
              String namaTerbaru = post.user;

              if (snapshot.hasData && snapshot.data!.exists) {
                final userData = snapshot.data!.data() as Map<String, dynamic>;

                namaTerbaru =
                    userData['user'] ?? userData['displayName'] ?? post.user;
              }
              return Text(
                namaTerbaru,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15, // Ukuran bisa Anda sesuaikan
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(post.description),
          const SizedBox(height: 10),
          Text("Hari: ${post.day}", style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 10),
          Text("Tempat: ${post.place}", style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                post.ticketType == 'Berbayar'
                    ? Icons.attach_money
                    : Icons.money_off,
                size: 16,
                color: post.ticketType == 'Berbayar'
                    ? Colors.red
                    : Colors.green,
              ),
              const SizedBox(width: 4),
              Text(
                post.ticketType ?? 'Gratis',
                style: TextStyle(
                  fontSize: 15,
                  color: post.ticketType == 'Berbayar'
                      ? Colors.red
                      : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  const _ImageCarousel({required this.imageUrls});

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _current = 0;
  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 600, minHeight: 400),
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) {
              setState(() => _current = i);
            },
            itemBuilder: (context, index) {
              final imageUrl = widget.imageUrls[index];

              return Container(
                width: double.infinity,
                color: const Color(0xFF2D3561).withOpacity(0.08),
                child: Builder(
                  builder: (context) {
                    // BASE64 IMAGE
                    if (imageUrl.startsWith('data:image')) {
                      return Image.memory(
                        base64Decode(imageUrl.split(',').last),
                        fit: BoxFit.contain,
                      );
                    }

                    // NETWORK IMAGE
                    if (imageUrl.startsWith('http')) {
                      return Image.network(imageUrl, fit: BoxFit.contain);
                    }

                    // ASSET IMAGE
                    return Image.asset(imageUrl, fit: BoxFit.contain);
                  },
                ),
              );
            },
          ),

          // Counter
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_current + 1}/${widget.imageUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Dots
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.imageUrls.length, (i) {
                  final isActive = _current == i;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
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

/// ================== HOME PAGE ==================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> _katkota = [];

  List<EventTerbaru> eventTerbaru = [];
  List<EventPost> _post = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 initState dipanggil');
    _fetchData();
  }

  Future<void> _fetchData() async {
    debugPrint('🔄 _fetchData dipanggil');
    try {
      debugPrint('📡 Mencoba ambil event_terbaru...');
      final eventSnap = await FirebaseFirestore.instance
          .collection('event_terbaru')
          .get(const GetOptions(source: Source.serverAndCache));

      debugPrint('📡 Mencoba ambil post...');
      final postSnap = await FirebaseFirestore.instance
          .collection('post')
          .get(const GetOptions(source: Source.serverAndCache));

      debugPrint('✅ event_terbaru: ${eventSnap.docs.length} dokumen');
      debugPrint('✅ post: ${postSnap.docs.length} dokumen');

      final kotaSnap = await FirebaseFirestore.instance
          .collection('katkota')
          .get();

      setState(() {
        eventTerbaru = eventSnap.docs
            .map((doc) => EventTerbaru.fromFirestore(doc.data(), doc.id))
            .toList();

        _post = postSnap.docs
            .map((doc) => EventPost.fromFirestore(doc.data(), doc.id))
            .toList();

        _katkota = kotaSnap.docs.map((doc) {
          final data = doc.data();
          debugPrint(
            '📍 kota: ${data['nama']} - heroImage: ${data['heroImage']}',
          );
          return {
            'nama': data['nama']?.toString() ?? '',
            'imageUrl': data['imageUrl']?.toString() ?? '',
            'heroImage': data['heroImage']?.toString() ?? '',
          };
        }).toList();

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error fetch: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F2),
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Transform.translate(
        offset: const Offset(0, 20),
        child: CustomNavBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          onHomeTap: () {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          },
        ),
      ),
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2D3561)),
                  )
                : RefreshIndicator(
                    color: const Color(0xFF2D3561),
                    onRefresh: _fetchData,
                    child: ListView(
                      controller: _scrollController,
                      children: [
                        _searchBar(),
                        const SizedBox(height: 30),
                        const SizedBox(height: 20),
                        eventTerbaru.isNotEmpty
                            ? _eventTerbaruSection()
                            : Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                height: 250,
                                decoration: BoxDecoration(
                                  color: Color(0xFFFFF6F2),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.event_busy_rounded,
                                        size: 70,
                                        color: Color(0xFFA9B5DF),
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        "Belum Ada Event Terbaru",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2D3561),
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        "Pantau terus aplikasi ini\nuntuk mendapatkan informasi event terbaru",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "Kategori",
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D3561),
                            ),
                          ),
                        ),
                        _horizontalListView(),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _post.length,
                          itemBuilder: (context, index) =>
                              EventCardSmall(post: _post[index]),
                        ),
                        if (_post.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 60),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 60,
                                    color: Color(0xFFA9B5DF),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Belum ada event nih',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2D3561),
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Jadilah yang pertama posting event!',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 30,
                                    color: Color(0xFFA9B5DF),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Belum ada event lagi nih',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF142C6E).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundImage: AssetImage('assets/images/logowebku.png'),
            radius: 30,
            backgroundColor: Colors.transparent,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "JatimCarnival",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 2),
              Text(
                "Bringing culture alive through events",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationPage()),
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF2D3561),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_none,
                color: Color(0xFFFFF6F2),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SearchResultPage(results: _post), // ✅ kirim semua post
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF2D3561),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: Colors.white70),
              SizedBox(width: 10),
              Text(
                "Cari event",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventTerbaruSection() {
    final PageController _pageController = PageController(initialPage: 1000);
    int _currentPage = 1000;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        Future.delayed(const Duration(seconds: 3), () {
          if (_pageController.hasClients) {
            _pageController.animateToPage(
              _currentPage + 1,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Event Terbaru",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3561),
                ),
              ),
            ),
            const SizedBox(height: 10),
            eventTerbaru.isEmpty
                ? Container(
                    height: 250,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_busy_rounded,
                            size: 60,
                            color: Color(0xFFA9B5DF),
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Belum ada event terbaru",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3561),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Silakan cek kembali nanti",
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : SizedBox(
                    height: 250,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: 99999,
                      onPageChanged: (i) =>
                          setLocalState(() => _currentPage = i),
                      itemBuilder: (context, index) {
                        final event = eventTerbaru[index % eventTerbaru.length];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EventTerbaruDetailPage(event: event),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      15,
                                    ), // Jika ingin sudutnya melengkung rapi
                                    child: (() {
                                      final imgUrl = event.imageUrl;

                                      if (imgUrl.isEmpty) {
                                        return Container(
                                          color: const Color(0xFF2D3561),
                                        );
                                      }

                                      // 1. Jika data dari admin berupa Base64
                                      if (imgUrl.startsWith('data:image')) {
                                        return Image.memory(
                                          base64Decode(imgUrl.split(',').last),
                                          fit: BoxFit.cover,
                                          gaplessPlayback: true,
                                        );
                                      }

                                      // 2. Jika data dari admin berupa URL Internet / Firebase Storage
                                      if (imgUrl.startsWith('http://') ||
                                          imgUrl.startsWith('https://')) {
                                        return Image.network(
                                          imgUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                color: const Color(0xFF2D3561),
                                              ),
                                        );
                                      }

                                      // 3. Jika data bawaan lokal asli (Asset)
                                      return Image.asset(
                                        imgUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: const Color(0xFF2D3561),
                                        ),
                                      );
                                    })(),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.7),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: event.isFree
                                            ? const Color(0xFF4CAF50)
                                            : const Color(0xFFE53935),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            event.isFree
                                                ? Icons.money_off_rounded
                                                : Icons.attach_money_rounded,
                                            color: const Color(0xFFFFF6F2),
                                            size: 13,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            event.isFree
                                                ? 'GRATIS'
                                                : 'BERBAYAR',
                                            style: const TextStyle(
                                              color: Color(0xFFFFF6F2),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 16,
                                    left: 16,
                                    right: 16,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.title,
                                          style: const TextStyle(
                                            color: Color(0xFFFFF6F2),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on_outlined,
                                              color: Colors.white70,
                                              size: 13,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                "${event.date} · ${event.location}",
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                                softWrap: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  Widget _horizontalListView() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _katkota.length,
        itemBuilder: (context, index) {
          final kota = _katkota[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                debugPrint('🏙️ kota data: ${kota}');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CityPage(
                      kotaNama: kota['nama'] ?? '',
                      heroImage:
                          kota['heroImage'] ??
                          'assets/images/default_city_hero.png',
                    ),
                  ),
                );
              },
              child: Card(
                color: const Color(0xFF2D3561),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SizedBox(
                  width: 90,
                  child: Center(
                    child: Image.asset(
                      kota['imageUrl'] ?? '',
                      height: 90,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.location_city, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _navIcon(IconData icon, int index) {
    final active = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Icon(
        icon,
        size: 26,
        color: active ? const Color(0xFFFFF6F2) : const Color(0xFFA9B5DF),
      ),
    );
  }

  Widget _profileIcon(int index) {
    final active = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          );
        }
        setState(() => _currentIndex = index);
      },
      child: CircleAvatar(
        radius: 14,
        backgroundColor: active
            ? const Color(0xFFFFF6F2)
            : const Color(0xFFA9B5DF),
        child: const CircleAvatar(
          radius: 12,
          backgroundImage: AssetImage("assets/images/pp.png"),
        ),
      ),
    );
  }
}
