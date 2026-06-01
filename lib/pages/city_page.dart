import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jurnal_jatim_carnival/data/event_post.dart';
import 'package:jurnal_jatim_carnival/pages/home_page.dart';

class CityPage extends StatefulWidget {
  final String kotaNama;
  final String heroImage;

  const CityPage({super.key, required this.kotaNama, required this.heroImage});

  @override
  State<CityPage> createState() => _CityPageState();
}

class _CityPageState extends State<CityPage> {
  List<EventPost> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint('🖼️ heroImage: ${widget.heroImage}');
    _fetchPostsByCity();
  }

  Future<void> _fetchPostsByCity() async {
    final snap = await FirebaseFirestore.instance.collection('post').get();
    setState(() {
      _posts = snap.docs
          .map((doc) => EventPost.fromFirestore(doc.data(), doc.id))
          .where(
            (post) => post.place.toLowerCase().contains(
              widget.kotaNama.toLowerCase(),
            ),
          )
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F2),
      body: Stack(
        children: [
          // ── Hero Image ──
          SizedBox(
            height: 320,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(40),
                  ),
                  child: widget.heroImage.startsWith('data:image')
                      ? Image.memory(
                          base64Decode(widget.heroImage.split(',').last),
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          widget.heroImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: const Color(0xFF2D3561)),
                        ),
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(40),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),

                // Tombol back
                Positioned(
                  top: 50,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D3561),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFFFFF6F2),
                        size: 18,
                      ),
                    ),
                  ),
                ),

                // Judul kota di bawah hero
                Positioned(
                  bottom: 30,
                  left: 24,
                  right: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFF6C7FD8),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Jawa Timur, Indonesia',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
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

          // ── Konten Bawah ──
          DraggableScrollableSheet(
            initialChildSize: 0.62,
            minChildSize: 0.62,
            maxChildSize: 0.92,
            builder: (context, controller) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF6F2),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    // ✅ Drag handle — bisa disentuh untuk geser
                    GestureDetector(
                      onVerticalDragUpdate: (details) {
                        // otomatis handled oleh DraggableScrollableSheet
                      },
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 16),
                        width: 160,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B6EE1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Header section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Event Tersedia',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2D3561),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── List konten ──
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF2D3561),
                              ),
                            )
                          : _posts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 64,
                                    color: const Color(
                                      0xFF6C7FD8,
                                    ).withOpacity(0.4),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada event\ndi ${widget.kotaNama}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.black45,
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: controller,
                              padding: const EdgeInsets.only(bottom: 100),
                              itemCount: _posts.length,
                              itemBuilder: (context, index) =>
                                  EventCardSmall(post: _posts[index]),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
