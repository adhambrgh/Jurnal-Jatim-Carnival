import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/profil_page.dart';
import '../pages/select_photo_page.dart';
import 'package:jurnal_jatim_carnival/data/profile_cache.dart';
import 'package:jurnal_jatim_carnival/data/guest_guard.dart';
import 'package:jurnal_jatim_carnival/data/auth_state.dart';

class CustomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onHomeTap;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onHomeTap,
  });

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get(const GetOptions(source: Source.server)); // ✅ paksa dari server

    if (doc.exists && mounted) {
      setState(() {
        _photoUrl = doc.data()?['photoUrl'];
        ProfileCache.photoUrl = _photoUrl; // ✅ update cache
      });
    }
  }

  ImageProvider _getImage() {
    if (_photoUrl == null) return const AssetImage("assets/images/pp.png");
    if (_photoUrl!.startsWith('data:image')) {
      return MemoryImage(base64Decode(_photoUrl!.split(',')[1]));
    }
    return NetworkImage(_photoUrl!);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 5),
        child: Container(
          height: 55,
          decoration: BoxDecoration(
            color: const Color(0xFF2D3561),
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navIcon(context, Icons.home_outlined, 0),
              _navIcon(context, Icons.add_circle_outline, 1),
              _profileIcon(context, 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navIcon(BuildContext context, IconData icon, int index) {
    final active = widget.currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (!guardGuest(context)) return;
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SelectPhotoPage()),
          );
          return;
        }
        if (index == 0) {
          widget.onHomeTap?.call();
        }
        widget.onTap(index);
      },
      child: Icon(
        icon,
        size: 26,
        color: active ? const Color(0xFFFFF6F2) : const Color(0xFFA9B5DF),
      ),
    );
  }

  Widget _profileIcon(BuildContext context, int index) {
    final active = widget.currentIndex == index;
    return GestureDetector(
      onTap: () async {
        if (!guardGuest(context)) return; 
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );

        await _loadPhoto();
        if (mounted) setState(() {});
        widget.onTap(index);
      },
      child: StreamBuilder<DocumentSnapshot>(
        // 👈 Tambahkan properti 'child:' di sini
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          String? photoUrlTerkini;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            photoUrlTerkini = data['photoUrl'];
          }

          return CircleAvatar(
            radius: 14,
            backgroundColor: active
                ? const Color(0xFFFFF6F2)
                : const Color(0xFFA9B5DF),
            child: CircleAvatar(
              radius: 12,
              backgroundImage:
                  photoUrlTerkini != null && photoUrlTerkini.isNotEmpty
                  ? (photoUrlTerkini.startsWith('data:image')
                        ? MemoryImage(
                            base64Decode(photoUrlTerkini.split(',').last),
                          )
                        : NetworkImage(photoUrlTerkini) as ImageProvider)
                  : const AssetImage('assets/images/profilkosong.jpg'),
              backgroundColor: const Color(0xFF6C7FD8),
            ),
          );
        },
      ),
    );
  }
}
