import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:flutter/foundation.dart';

class NewEventData {
  static List myEvents = [];
}

enum Kota {
  malang,
  surabaya,
  pasuruan,
  probolinggo,
  batu,
  blitar,
  kediri,
  madiun,
}

// ✅ Model media item untuk urutan
class MediaItemData {
  final File file;
  final bool isVideo;
  VideoPlayerController? videoController;

  MediaItemData({
    required this.file,
    required this.isVideo,
    this.videoController,
  });
}

class PostEventPage extends StatefulWidget {
  final List<MediaItemData> mediaItems; // ✅ kirim sekaligus dengan urutan

  const PostEventPage({super.key, this.mediaItems = const []});

  @override
  State<PostEventPage> createState() => _PostEventPageState();
}

class _PostEventPageState extends State<PostEventPage> {
  final title = TextEditingController();
  final lokasi = TextEditingController();
  final tanggal = TextEditingController();
  final hari = TextEditingController();
  final ket = TextEditingController();
  final PageController _pageController = PageController();

  int _currentPage = 0;
  String _ticketType = 'Gratis';
  bool _isLoading = false;
  Kota kotaTerpilih = Kota.malang;
  DateTime? _selectedDate;

  List<VideoPlayerController> _videoControllers = [];

  @override
  void initState() {
    super.initState();
    _initVideoControllers();
  }

  Future<void> _initVideoControllers() async {
    for (final item in widget.mediaItems) {
      if (item.isVideo) {
        final controller = VideoPlayerController.file(item.file);
        await controller.initialize();
        controller.setLooping(true);
        controller.setVolume(1.0); // ✅ ada suara
        _videoControllers.add(controller);
        item.videoController = controller;
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    title.dispose();
    lokasi.dispose();
    tanggal.dispose();
    hari.dispose();
    ket.dispose();
    _pageController.dispose();
    for (final c in _videoControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _postEvent() async {
    final hasImage = widget.mediaItems.any((m) => !m.isVideo);

    final hasVideo = widget.mediaItems.any((m) => m.isVideo);

    if (!hasImage && !hasVideo) {
      _showSnackbar(
        "Silakan pilih foto atau video",

        Icons.image_not_supported_outlined,
      );

      return;
    }

    if (title.text.isEmpty || ket.text.isEmpty) {
      _showSnackbar(
        "Judul dan keterangan wajib diisi",

        Icons.warning_amber_rounded,
      );

      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      final uid = user?.uid ?? '';

      String displayName = 'Pengguna';

      String profileImage = '';

      if (uid.isNotEmpty) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (userDoc.exists) {
          displayName = userDoc['displayName'] ?? 'Pengguna';

          profileImage = userDoc['photoUrl'] ?? '';
        }
      }

      // ✅ Convert semua media ke base64 sesuai urutan

      // ✅ Convert semua media ke base64 sesuai urutan

      final List<Map<String, String>> mediaList = [];

      for (final item in widget.mediaItems) {
        if (item.isVideo) {
          final bytes = await item.file.readAsBytes();

          final base64Str = base64Encode(bytes);

          mediaList.add({
            'type': 'video',

            'data': 'data:video/mp4;base64,$base64Str',
          });
        } else {
          // ✅ Compress foto
          final compressed = await FlutterImageCompress.compressWithFile(
            item.file.path,
            quality: 50, // ✅ kurangi kualitas
            minWidth: 800, // ✅ batas lebar
            minHeight: 800,
          );
          final bytes = compressed ?? await item.file.readAsBytes();

          // ✅ Cek ukuran
          debugPrint('📸 size: ${bytes.length ~/ 1024}KB');

          if (bytes.length > 900000) {
            // ✅ lebih dari 900KB → tolak
            _showSnackbar(
              'Foto terlalu besar, pilih foto lain',
              Icons.warning_amber_rounded,
            );
            setState(() => _isLoading = false);
            return;
          }

          final base64Str = base64Encode(bytes);
          mediaList.add({
            'type': 'image',
            'data': 'data:image/jpeg;base64,$base64Str',
          });
        }
      }

      // ✅ Pisahkan untuk backward compatibility

      final imageUrls = mediaList
          .where((m) => m['type'] == 'image')
          .map((m) => m['data']!)
          .toList();

      final videoUrls = mediaList
          .where((m) => m['type'] == 'video')
          .map((m) => m['data']!)
          .toList();

      await FirebaseFirestore.instance.collection('post').add({
        'user': displayName,

        'title': title.text.trim(),

        'description': ket.text.trim(),

        'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : '',

        'imageUrls': imageUrls,

        'videoUrls': videoUrls,

        'mediaList': mediaList
            .map((m) => Map<String, dynamic>.from(m))
            .toList(),

        'profileImage': profileImage,

        'place': '${lokasi.text.trim()}, ${kotaTerpilih.name}',

        'day': hari.text.trim(),

        'date': tanggal.text.trim(),

        'ticketType': _ticketType,

        'likeCount': 0,

        'likedBy': [],

        'savedBy': [],

        'uid': uid,

        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSnackbar(
          "Postingan berhasil diunggah!",

          Icons.check_circle_outline,
        );

        Navigator.pop(context);

        Navigator.pop(context);
      }
    } catch (e, stack) {
      debugPrint("ERROR: $e");

      debugPrint("STACK: $stack");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
    final pages = widget.mediaItems;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF6F2),
        elevation: 0,
        title: const Text(
          "Postingan Baru",
          style: TextStyle(
            color: Color(0xFF2D3561),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
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
              color: Color(0xFFFFF6F2),
              size: 16,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // ── Media Preview ──
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 600),
              child: Container(
                color: const Color(0xFF2D3561).withOpacity(0.08),
                child: pages.isEmpty
                    ? AspectRatio(
                        aspectRatio: 3 / 4,
                        child: Container(
                          color: const Color(0xFF2D3561),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 54,
                                color: const Color(0xFF6C7FD8).withOpacity(0.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Tidak ada media",
                                style: TextStyle(
                                  color: const Color(
                                    0xFF2D3561,
                                  ).withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: pages.length,
                            physics: const BouncingScrollPhysics(),
                            onPageChanged: (i) {
                              setState(() => _currentPage = i);
                              for (final item in pages) {
                                if (item.isVideo) item.videoController?.pause();
                              }
                              if (pages[i].isVideo)
                                pages[i].videoController?.play();
                            },
                            itemBuilder: (context, index) {
                              final item = pages[index];
                              if (item.isVideo) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      final c = item.videoController;
                                      if (c != null) {
                                        c.value.isPlaying
                                            ? c.pause()
                                            : c.play();
                                      }
                                    });
                                  },
                                  child: Stack(
                                    children: [
                                      item.videoController != null &&
                                              item
                                                  .videoController!
                                                  .value
                                                  .isInitialized
                                          ? Center(
                                              child: FittedBox(
                                                fit: BoxFit.contain,
                                                child: SizedBox(
                                                  width: item
                                                      .videoController!
                                                      .value
                                                      .size
                                                      .width,
                                                  height: item
                                                      .videoController!
                                                      .value
                                                      .size
                                                      .height,
                                                  child: VideoPlayer(
                                                    item.videoController!,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : const SizedBox(
                                              height: 300,
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                    ),
                                              ),
                                            ),

                                      if (item.videoController != null &&
                                          !item
                                              .videoController!
                                              .value
                                              .isPlaying)
                                        const Positioned.fill(
                                          child: Center(
                                            child: Icon(
                                              Icons.play_circle_fill,
                                              color: Colors.white70,
                                              size: 60,
                                            ),
                                          ),
                                        ),

                                      if (item.videoController != null)
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          height: 12,
                                          child: VideoProgressIndicator(
                                            item.videoController!,
                                            allowScrubbing: true,
                                            colors: const VideoProgressColors(
                                              playedColor: Color(0xFF6C7FD8),
                                              backgroundColor: Colors.white24,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }
                              return Image.file(
                                item.file,
                                fit: BoxFit.contain,
                                width: double.infinity,
                              );
                            },
                          ),

                          // Counter
                          if (pages.length > 1)
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
                                  '${_currentPage + 1}/${pages.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                          // Dot indicator
                          if (pages.length > 1)
                            Positioned(
                              bottom: 16,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(pages.length, (i) {
                                  final isActive = _currentPage == i;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    width: isActive ? 20 : 6,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: isActive
                                          ? [
                                              BoxShadow(
                                                color: Colors.white.withOpacity(
                                                  0.4,
                                                ),
                                                blurRadius: 4,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  );
                                }),
                              ),
                            ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),
            _sectionLabel("Info Event", Icons.event_note_outlined),
            const SizedBox(height: 10),
            _field("Judul Event", title),
            _buildKotaDropdown(),
            _buildTicketDropdown(),
            _sectionLabel("Waktu & Tempat", Icons.location_on_outlined),
            const SizedBox(height: 10),
            _field("Lokasi", lokasi),
            _buildDatePicker(),
            _field("Hari", hari),
            _sectionLabel("Deskripsi", Icons.description_outlined),
            const SizedBox(height: 10),
            _field("Keterangan", ket, max: 4),
            const SizedBox(height: 20),

            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _postEvent,
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.upload_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Posting Sekarang",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6C7FD8)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D3561),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C7FD8).withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getDayName(DateTime date) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return days[date.weekday - 1];
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2030),
            builder: (context, child) {
              return Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF6C7FD8),
                    onPrimary: Colors.white,
                    surface: Color(0xFF2D3561),
                    onSurface: Colors.white,
                  ),
                  dialogBackgroundColor: const Color(0xFF2D3561),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            setState(() {
              _selectedDate = picked;
              tanggal.text =
                  '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
              hari.text = _getDayName(picked);
            });
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6F2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFF2D3561).withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFF2D3561),
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                tanggal.text.isNotEmpty ? tanggal.text : 'Pilih Tanggal',
                style: TextStyle(
                  color: tanggal.text.isNotEmpty
                      ? Color(0xFF2D3561)
                      : Color(0xFF2D3561),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {int max = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        maxLines: max,
        style: const TextStyle(fontSize: 14, color: Color(0xFF2D3561)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF2D3561),
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: const Color(0xFFFFF6F2),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: Color(0xFF2D3561).withOpacity(0.15),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFF2D3561), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildKotaDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6F2),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: const Color(0xFF2D3561).withOpacity(0.15),
            width: 1.5,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Kota>(
            isExpanded: true,
            value: kotaTerpilih,
            dropdownColor: const Color(0xFFFFF6F2),
            style: const TextStyle(
              color: Color(0xFF2D3561),
              fontWeight: FontWeight.w500,
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF2D3561),
            ),
            onChanged: (Kota? value) => setState(() => kotaTerpilih = value!),
            items: Kota.values.map((Kota kota) {
              return DropdownMenuItem(
                value: kota,
                child: Text(kota.name.toUpperCase()),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6F2),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: const Color(0xFF2D3561).withOpacity(0.15),
            width: 1.5,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: _ticketType,
            dropdownColor: const Color(0xFFFFF6F2),
            style: const TextStyle(
              color: Color(0xFF2D3561),
              fontWeight: FontWeight.w500,
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF2D3561),
            ),
            onChanged: (String? value) => setState(() => _ticketType = value!),
            items: ['Gratis', 'Berbayar'].map((String type) {
              return DropdownMenuItem(
                value: type,
                child: Row(
                  children: [
                    Icon(
                      type == 'Gratis' ? Icons.money_off : Icons.attach_money,
                      color: type == 'Gratis'
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(type),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
