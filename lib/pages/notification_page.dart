import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF6F2),
        shadowColor: const Color(0xFF142C6E),
        title: const Text(
          "Notifikasi",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
            width: 42,
            height: 42,
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
      body: SafeArea(
        child: _uid == null
            ? const Center(child: Text('Login untuk melihat notifikasi'))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('toUid', isEqualTo: _uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2D3561),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 60,
                            color: Colors.black26,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Belum ada notifikasi',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  // ✅ Mark all as read
                  for (var doc in docs) {
                    if (doc['isRead'] == false) {
                      doc.reference.update({'isRead': true});
                    }
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return _buildNotificationCard(data);
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final fromName = data['fromName'] ?? 'Seseorang';
    final fromPhoto = data['fromPhoto'] ?? '';
    final postImage = data['postImage'] ?? '';
    final isRead = data['isRead'] ?? true;

    String message = data['message'] ?? '';
    IconData fallbackIcon = Icons.notifications;

    if (type == 'like') fallbackIcon = Icons.favorite;
    if (type == 'save') fallbackIcon = Icons.bookmark;
    if (type == 'share') fallbackIcon = Icons.share;
    if (type == 'comment') fallbackIcon = Icons.mode_comment;
    if (type == 'admin') fallbackIcon = Icons.campaign;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isRead
            ? const Color(0xFF2D3561)
            : const Color(0xFF3D4A7A), // ✅ beda warna jika belum dibaca
        borderRadius: BorderRadius.circular(22),
        border: isRead
            ? null
            : Border.all(color: const Color(0xFF7886C7), width: 1),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white24,
            child: type == 'admin'
                ? const Icon(Icons.campaign, color: Colors.white)
                : fromPhoto.isNotEmpty
                ? ClipOval(
                    child: fromPhoto.startsWith('data:image')
                        ? Image.memory(
                            base64Decode(fromPhoto.split(',').last),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            fromPhoto,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Icon(fallbackIcon, color: Colors.white),
                          ),
                  )
                : Icon(fallbackIcon, color: Colors.white),
          ),

          const SizedBox(width: 12),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type == 'admin' ? 'Admin' : fromName,
                  style: const TextStyle(
                    color: Color(0xFFFFF6F2),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(color: Color(0xFFFFF6F2))),
              ],
            ),
          ),

          // Thumbnail postingan
          if (postImage.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: postImage.startsWith('data:image')
                  ? Image.memory(
                      base64Decode(postImage.split(',').last),
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                    )
                  : postImage.startsWith('http')
                  ? Image.network(
                      postImage,
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      postImage,
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                    ),
            ),
        ],
      ),
    );
  }
}
