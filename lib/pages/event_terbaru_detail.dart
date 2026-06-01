import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:jurnal_jatim_carnival/data/event_terbaru.dart';
import 'package:jurnal_jatim_carnival/pages/comment_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jurnal_jatim_carnival/data/guest_guard.dart';
import 'package:jurnal_jatim_carnival/data/auth_state.dart';

class EventTerbaruDetailPage extends StatefulWidget {
  final EventTerbaru event;
  const EventTerbaruDetailPage({super.key, required this.event});

  @override
  State<EventTerbaruDetailPage> createState() => _EventTerbaruDetailPageState();
}

class _EventTerbaruDetailPageState extends State<EventTerbaruDetailPage> {
  bool isLiked = false;
  bool isSaved = false;
  int likeCount = 0;
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    debugPrint('🔍 postId: ${widget.event.postId}');
    debugPrint('🔍 uid: $uid');
    if (uid == null || widget.event.postId.isEmpty) return;
    final doc = await FirebaseFirestore.instance
        .collection('event_terbaru') // ✅ ganti ini
        .doc(widget.event.postId)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        likeCount = data['likeCount'] ?? 0;
        isLiked = List.from(data['likedBy'] ?? []).contains(uid);
        isSaved = List.from(data['savedBy'] ?? []).contains(uid);
      });
    }
  }

  Future<void> _toggleLike() async {
     if (!guardGuest(context)) return;
    if (uid == null || widget.event.postId.isEmpty) return;
    final docRef = FirebaseFirestore.instance
        .collection('event_terbaru') // ✅ ganti ini
        .doc(widget.event.postId);
    final doc = await docRef.get();
    final data = doc.data()!;
    List likedBy = List.from(data['likedBy'] ?? []);

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
    });

    await docRef.update({'likeCount': likeCount, 'likedBy': likedBy});

    if (isLiked && data['uid'] != uid) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      await FirebaseFirestore.instance.collection('notifications').add({
        'toUid': data['uid'],
        'fromUid': uid,
        'fromName': userDoc['displayName'] ?? 'Seseorang',
        'fromPhoto': userDoc['photoUrl'] ?? '',
        'type': 'like',
        'postId': widget.event.postId,
        'postImage': data['imageUrl'] ?? '',
        'message': 'Menyukai postingan anda',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
  }

  Future<void> _toggleSave() async {
     if (!guardGuest(context)) return;
    if (uid == null || widget.event.postId.isEmpty) return;
    final docRef = FirebaseFirestore.instance
        .collection('event_terbaru') // ✅ ganti ini
        .doc(widget.event.postId);
    final doc = await docRef.get();
    final data = doc.data()!;
    List savedBy = List.from(data['savedBy'] ?? []);

    setState(() {
      if (isSaved) {
        isSaved = false;
        savedBy.remove(uid);
      } else {
        isSaved = true;
        savedBy.add(uid);
      }
    });

    await docRef.update({'savedBy': savedBy});

    if (isSaved && data['uid'] != uid) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      await FirebaseFirestore.instance.collection('notifications').add({
        'toUid': data['uid'],
        'fromUid': uid,
        'fromName': userDoc['displayName'] ?? 'Seseorang',
        'fromPhoto': userDoc['photoUrl'] ?? '',
        'type': 'save',
        'postId': widget.event.postId,
        'postImage': data['imageUrl'] ?? '',
        'message': 'Menyimpan postingan anda',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
  }

  Future<void> _share() async {
    if (!guardGuest(context)) return;
    final shareText =
        "🎪 Lihat event '${widget.event.title}'\n"
        "📍 ${widget.event.location}\n"
        "📅 ${widget.event.date}\n"
        "🎫 ${widget.event.isFree ? 'Gratis' : 'Berbayar'}\n\n"
        "Buka di Jurnal Jatim Carnival:\n"
        "https://jatimcarnival.com/post/${widget.event.postId}";

    await Share.share(shareText);

    if (uid != null && widget.event.postId.isNotEmpty) {
      final doc = await FirebaseFirestore.instance
          .collection('event_terbaru') // ✅ ganti ini
          .doc(widget.event.postId)
          .get();
      final data = doc.data()!;
      if (data['uid'] != uid) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        await FirebaseFirestore.instance.collection('notifications').add({
          'toUid': data['uid'],
          'fromUid': uid,
          'fromName': userDoc['displayName'] ?? 'Seseorang',
          'fromPhoto': userDoc['photoUrl'] ?? '',
          'type': 'share',
          'postId': widget.event.postId,
          'postImage': data['imageUrl'] ?? '',
          'message': 'Membagikan postingan anda',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F2),
      body: Stack(
        children: [
          SizedBox(
            height: 300,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                  child: (() {
                    final imgUrl = widget.event.imageUrl;

                    if (imgUrl.isEmpty) {
                      return Container(color: const Color(0xFF2D3561));
                    }

                    // 1. Jika gambar berupa Base64 (dari Admin upload lokal)
                    if (imgUrl.startsWith('data:image')) {
                      return Image.memory(
                        base64Decode(imgUrl.split(',').last),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      );
                    }

                    // 2. Jika gambar berupa URL HTTP/HTTPS (dari Firebase Storage)
                    if (imgUrl.startsWith('http://') ||
                        imgUrl.startsWith('https://')) {
                      return Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: const Color(0xFF2D3561)),
                      );
                    }

                    // 3. Jika gambar berupa path Asset lokal bawaan
                    return Image.asset(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: const Color(0xFF2D3561)),
                    );
                  })(),
                ),
                Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(40),
                    ),
                    color: Colors.black26,
                  ),
                ),
                Positioned(
                  top: 50,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D3561),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFFFFF6F2),
                        size: 18,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.event.isFree
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.event.isFree
                              ? Icons.money_off_rounded
                              : Icons.attach_money_rounded,
                          color: Color(0xFFFFF6F2),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.event.isFree ? 'GRATIS' : 'BERBAYAR',
                          style: const TextStyle(
                            color: Color(0xFFFFF6F2),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.65,
            maxChildSize: 0.9,
            builder: (context, controller) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF6F2),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16, top: 12),
                        width: 200,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B6EE1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    Text(
                      widget.event.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3561),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _infoRow(Icons.location_on_outlined, widget.event.location),
                    const SizedBox(height: 12),
                    _infoRow(Icons.calendar_today_outlined, widget.event.date),
                    const SizedBox(height: 12),
                    _infoRow(
                      widget.event.isFree
                          ? Icons.money_off_rounded
                          : Icons.attach_money_rounded,
                      widget.event.isFree ? 'Gratis' : 'Berbayar',
                      color: widget.event.isFree ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 30),

                    if (widget.event.link.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () async {
                          final Uri uri = Uri.parse(widget.event.link);

                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
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
                                  color: const Color(
                                    0xFF6C7FD8,
                                  ).withOpacity(0.2),
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
                                      widget.event.link,
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
                      const SizedBox(height: 20),
                    ],

                    Row(
                      children: [
                        // Like
                        GestureDetector(
                          onTap: _toggleLike,
                          child: Row(
                            children: [
                              Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: const Color(0xFF7886C7),
                                size: 26,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$likeCount',
                                style: const TextStyle(
                                  color: Color(0xFF7886C7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Comment
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CommentPage(postId: widget.event.postId),
                            ),
                          ),
                          child: const Icon(
                            Icons.mode_comment_outlined,
                            color: Color(0xFF7886C7),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Save
                        GestureDetector(
                          onTap: _toggleSave,
                          child: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: const Color(0xFF7886C7),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Share
                        GestureDetector(
                          onTap: _share,
                          child: const Icon(
                            Icons.share_outlined,
                            color: Color(0xFF7886C7),
                            size: 26,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFE0E0E0)),
                    const SizedBox(height: 16),

                    const Text(
                      'Tentang Event',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3561),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Event ${widget.event.title} akan diselenggarakan di ${widget.event.location} pada ${widget.event.date}. '
                      'Event ini ${widget.event.isFree ? "GRATIS" : "BERBAYAR"} untuk umum.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF2D3561).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color ?? const Color(0xFF2D3561), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            softWrap: true,
            style: TextStyle(
              fontSize: 15,
              color: color ?? Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
