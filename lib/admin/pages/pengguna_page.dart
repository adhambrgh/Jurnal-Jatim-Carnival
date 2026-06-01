import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'admin_contans.dart';

// ═══════════════════════════════════════════════════════════════
// HALAMAN: PENGGUNA
// Koleksi Firestore: 'users'
// ═══════════════════════════════════════════════════════════════
class PenggunaPage extends StatefulWidget {
  const PenggunaPage({super.key});

  @override
  State<PenggunaPage> createState() => _PenggunaPageState();
}

class _PenggunaPageState extends State<PenggunaPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  // ── Toolbar ──────────────────────────────────────────────────
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          _statChip(
            Icons.people_rounded,
            'Total Pengguna',
            color: const Color(0xFF0891B2),
            stream: FirebaseFirestore.instance
                .collection('users')
                .snapshots()
                .map((s) => s.docs.length),
          ),
          const Spacer(),
          _searchBar('Cari nama, email, atau bio...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data!.docs;
        final docs = _query.isEmpty
            ? all
            : all.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final name =
                    d['displayName']?.toString().toLowerCase() ?? '';
                final email =
                    d['email']?.toString().toLowerCase() ?? '';
                final bio =
                    d['bio']?.toString().toLowerCase() ?? '';
                return name.contains(_query) ||
                    email.contains(_query) ||
                    bio.contains(_query);
              }).toList();

        final rows = docs.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final photo = d['photoUrl']?.toString() ?? '';
          final ImageProvider img = photo.startsWith('data:image')
              ? MemoryImage(base64Decode(photo.split(',').last))
              : const AssetImage('assets/images/profilkosong.jpg');

          return RowData(cells: [
            CircleAvatar(radius: 20, backgroundImage: img, backgroundColor: kBg),
            cellText(d['displayName'] ?? '-', bold: true),
            cellText(d['email'] ?? '-', color: kAccent),
            cellText(d['bio'] ?? '-',
                color: const Color(0xFF94A3B8), maxLines: 2),
            // Tanggal bergabung (opsional jika ada field createdAt)
            _joinedLabel(d),
            actionButtons(
              onEdit: () => _showEditDialog(doc.id, d),
              onDelete: () => _hapus(doc.id),
            ),
          ]);
        }).toList();

        return buildDataTable(
          emptyMsg: 'Belum ada pengguna',
          searchQuery: _query,
          columns: const ['Foto', 'Nama', 'Email', 'Bio', 'Bergabung', 'Aksi'],
          widths: const [60, 150, 180, 180, 110, 90],
          rows: rows,
        );
      },
    );
  }

  // ── Tanggal bergabung ────────────────────────────────────────
  Widget _joinedLabel(Map<String, dynamic> data) {
    final ts = data['createdAt'];
    if (ts == null) return cellText('-', color: const Color(0xFF94A3B8));
    try {
      final dt = (ts as Timestamp).toDate();
      final str =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      return cellText(str, color: const Color(0xFF64748B));
    } catch (_) {
      return cellText('-', color: const Color(0xFF94A3B8));
    }
  }

  // ── Edit dialog ──────────────────────────────────────────────
  void _showEditDialog(String docId, Map<String, dynamic> data) {
  final nameCtrl = TextEditingController(text: data['displayName'] ?? '');
  final bioCtrl = TextEditingController(text: data['bio'] ?? '');
  String selectedKota = data['kota'] ?? 'malang';

  final kotaList = [
    'malang', 'surabaya', 'pasuruan', 'probolinggo',
    'batu', 'blitar', 'kediri', 'madiun',
  ];

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setLocalState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Pengguna',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              formField('Nama', nameCtrl),
              const SizedBox(height: 12),
              formField('Bio', bioCtrl, maxLines: 3),
              const SizedBox(height: 12),

              // ✅ Dropdown kota
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedKota,
                    items: kotaList.map((kota) => DropdownMenuItem(
                      value: kota,
                      child: Text(kota.toUpperCase()),
                    )).toList(),
                    onChanged: (val) {
                      setLocalState(() => selectedKota = val!);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(docId)
                  .update({
                'displayName': nameCtrl.text.trim(),
                'bio': bioCtrl.text.trim(),
                'kota': selectedKota, // ✅ simpan kota
              });
              if (context.mounted) {
                Navigator.pop(context);
                showSnack(context, 'Pengguna berhasil diperbarui');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D3561),
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    ),
  );
}

  // ── Hapus ────────────────────────────────────────────────────
  Future<void> _hapus(String docId) async {
    final ok = await showDeleteDialog(context);
    if (ok == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .delete();
      showSnack(context, 'Pengguna dihapus', isError: true);
    }
  }

  // ── Reusable widgets ─────────────────────────────────────────
  Widget _searchBar(String hint) {
    return SizedBox(
      width: 280,
      height: 40,
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(fontSize: 13, color: Color(0xFFB0BAD0)),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 18, color: Color(0xFFB0BAD0)),
          suffixIcon: _query.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: Color(0xFFB0BAD0)),
                )
              : null,
          filled: true,
          fillColor: kCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kAccent, width: 1.5),
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _statChip(
    IconData icon,
    String label, {
    Color color = kAccent,
    required Stream<int> stream,
  }) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snap) {
        final val = snap.data ?? 0;
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$val',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: color)),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF94A3B8))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}