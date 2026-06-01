import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class CommentPage extends StatefulWidget {
  final String postId;
  const CommentPage({super.key, required this.postId});

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  final TextEditingController _controller = TextEditingController();
  List<CommentModel> comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _listenComments(); // ✅ pakai realtime listener
  }

  // ✅ Realtime listener
  void _listenComments() {
    debugPrint('🔄 Listen comments untuk postId: ${widget.postId}');

    FirebaseFirestore.instance
        .collection('post')
        .doc(widget.postId)
        .collection('comments')
        .snapshots()
        .listen(
          (snap) async {
            debugPrint('✅ Dapat ${snap.docs.length} komentar');
            try {
              final list = await Future.wait(
                snap.docs.map((doc) async {
                  final data = doc.data() as Map<String, dynamic>;
                  final commentUid = data['uid'] ?? '';
                  String photoUrl = data['avatarPath'] ?? '';
                  String name = data['name'] ?? '';

                  if (commentUid.isNotEmpty) {
                    final userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(commentUid)
                        .get();
                    if (userDoc.exists) {
                      photoUrl = userDoc['photoUrl'] ?? photoUrl;
                      name = userDoc['displayName'] ?? name;
                    }
                  }

                  return CommentModel(
                    name: name,
                    avatarPath: photoUrl,
                    avatarType: photoUrl.startsWith('data:image')
                        ? AvatarType.base64
                        : AvatarType.asset,
                    comment: data['comment'] ?? '',
                  );
                }),
              );

              setState(() {
                comments = list;
                _isLoading = false;
              });
            } catch (e) {
              debugPrint('❌ Error parsing: $e');
              setState(() => _isLoading = false);
            }
          },
          onError: (e) {
            debugPrint('❌ Error listen: $e');
            setState(() => _isLoading = false);
          },
        );
  }

  Future<void> _sendComment() async {
    if (_controller.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final comment = _controller.text.trim();

    String name = 'Pengguna';
    String photoUrl = '';

    if (uid.isNotEmpty) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (userDoc.exists) {
        name = userDoc['displayName'] ?? 'Pengguna';
        photoUrl = userDoc['photoUrl'] ?? '';
        debugPrint('📸 photoUrl kosong: ${photoUrl.isEmpty}');
        debugPrint(
          '📸 photoUrl prefix: ${photoUrl.isNotEmpty ? photoUrl.substring(0, 30) : "KOSONG"}',
        );
      }
    }

    await FirebaseFirestore.instance
        .collection('post')
        .doc(widget.postId)
        .collection('comments')
        .add({
          'name': name,
          'avatarPath': photoUrl,
          'avatarType': 'base64',
          'uid': uid,
          'comment': comment,
          'createdAt': FieldValue.serverTimestamp(),
        });

    // ✅ Kirim notifikasi ke pemilik post
    final postDoc = await FirebaseFirestore.instance
        .collection('post')
        .doc(widget.postId)
        .get();

    final postOwnerUid = postDoc['uid'] ?? '';
    final postImage = postDoc['imageUrl'] ?? '';

    if (uid.isNotEmpty && postOwnerUid != uid) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'toUid': postOwnerUid,
        'fromUid': uid,
        'fromName': name,
        'fromPhoto': photoUrl,
        'type': 'comment',
        'postId': widget.postId,
        'postImage': postImage,
        'message': 'Mengomentari postingan anda: "$comment"',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF6F2),
        elevation: 0,
        centerTitle: true,
        title: const Text("Komentar"),
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
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
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2D3561)),
                  )
                : comments.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada komentar',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      top: 40,
                      left: 10,
                      right: 10,
                    ),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundImage: c.avatarPath.isNotEmpty
                                  ? (c.avatarPath.startsWith('data:image')
                                        ? MemoryImage(
                                            base64Decode(
                                              c.avatarPath.split(',')[1],
                                            ),
                                          )
                                        : NetworkImage(c.avatarPath)
                                              as ImageProvider)
                                  : const AssetImage(
                                      'assets/images/profilkosong.jpg',
                                    ),
                              backgroundColor: const Color(0xFF6C7FD8),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF142C6E),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFFF6F2),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      c.comment,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Input komentar
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF2D3561),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Color(0xFFFFF6F2)),
                    decoration: const InputDecoration(
                      hintText: "Masukkan pendapatmu...",
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFFFF6F2)),
                  onPressed: _sendComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ handle kalau URL kosong

enum AvatarType { network, asset, file, base64 } // ✅ tambah base64

ImageProvider _buildAvatarImage(CommentModel c) {
  switch (c.avatarType) {
    case AvatarType.base64:
      if (c.avatarPath.isNotEmpty) {
        // ✅ Ambil hanya data base64 tanpa prefix
        final base64Str = c.avatarPath.contains(',')
            ? c.avatarPath.split(',').last
            : c.avatarPath;
        return MemoryImage(base64Decode(base64Str));
      }
      return const AssetImage('assets/images/pp.png');
    case AvatarType.network:
      return c.avatarPath.isNotEmpty
          ? NetworkImage(c.avatarPath)
          : const AssetImage('assets/images/pp.png');
    case AvatarType.asset:
      return AssetImage(
        c.avatarPath.isNotEmpty ? c.avatarPath : 'assets/images/pp.png',
      );
    case AvatarType.file:
      return FileImage(File(c.avatarPath));
  }
}

class CommentModel {
  final String name;
  final String avatarPath;
  final AvatarType avatarType;
  final String comment;

  CommentModel({
    required this.name,
    required this.avatarPath,
    required this.avatarType,
    required this.comment,
  });
}
