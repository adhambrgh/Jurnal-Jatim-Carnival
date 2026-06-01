import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'admin_contans.dart';

// ═══════════════════════════════════════════════════════════════
// DATA STATIS
// ═══════════════════════════════════════════════════════════════
const _hariList = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

const _bulanList = [
  '',
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const _tiketList = ['Gratis', 'Berbayar'];

// ═══════════════════════════════════════════════════════════════
// HALAMAN: POSTINGAN USER
// Koleksi Firestore: 'post'
// ═══════════════════════════════════════════════════════════════
class PostinganPage extends StatefulWidget {
  const PostinganPage({super.key});

  @override
  State<PostinganPage> createState() => _PostinganPageState();
}

class _PostinganPageState extends State<PostinganPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  // Kota dari koleksi katkota
  List<Map<String, String>> _katkota = [];

  @override
  void initState() {
    super.initState();
    _loadKatkota();
  }

  Future<void> _loadKatkota() async {
    final snap = await FirebaseFirestore.instance.collection('katkota').get();
    setState(() {
      _katkota = snap.docs
          .map(
            (doc) => {
              'id': doc.id,
              'name': doc.data()['nama']?.toString() ?? '',
            },
          )
          .toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────
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
            Icons.article_rounded,
            'Total Postingan',
            stream: FirebaseFirestore.instance
                .collection('post')
                .snapshots()
                .map((s) => s.docs.length),
          ),
          const SizedBox(width: 12),
          _statChip(
            Icons.favorite_rounded,
            'Total Like',
            color: kDanger,
            stream: FirebaseFirestore.instance
                .collection('post')
                .snapshots()
                .map(
                  (s) => s.docs.fold<int>(
                    0,
                    (sum, d) => sum + ((d['likeCount'] as int?) ?? 0),
                  ),
                ),
          ),
          const Spacer(),
          _searchBar(),
        ],
      ),
    );
  }

  // ── Tabel Konten ─────────────────────────────────────────────
  Widget _buildContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('post')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data!.docs;
        final docs = _query.isEmpty
            ? all
            : all.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return (d['title']?.toString().toLowerCase() ?? '').contains(
                      _query,
                    ) ||
                    (d['user']?.toString().toLowerCase() ?? '').contains(
                      _query,
                    ) ||
                    (d['place']?.toString().toLowerCase() ?? '').contains(
                      _query,
                    );
              }).toList();

        final rows = docs.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return RowData(
            cells: [
              thumbWidget(d['imageUrl']?.toString() ?? ''),
              cellText(d['title'] ?? '-', bold: true, maxLines: 2),
              cellText(d['user'] ?? '-'),
              cellText(d['place'] ?? '-'),
              cellText(d['date'] ?? '-', color: const Color(0xFF64748B)),
              ticketBadge(d['ticketType']?.toString()),
              cellText('${d['likeCount'] ?? 0}', color: kDanger),
              actionButtons(
                onEdit: () => _showEditDialog(doc.id, d),
                onDelete: () => _hapus(doc.id),
              ),
            ],
          );
        }).toList();

        return buildDataTable(
          emptyMsg: 'Belum ada postingan',
          searchQuery: _query,
          columns: const [
            'Foto',
            'Judul',
            'Pengguna',
            'Tempat',
            'Tanggal',
            'Tiket',
            '❤️',
            'Aksi',
          ],
          widths: const [64, 180, 130, 130, 110, 80, 50, 90],
          rows: rows,
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  // DIALOG EDIT — style sama dengan EventTerbaruPage
  // ══════════════════════════════════════════════════════════════
  void _showEditDialog(String docId, Map<String, dynamic> data) {
    final titleCtrl = TextEditingController(text: data['title'] ?? '');
    final placeCtrl = TextEditingController(text: data['place'] ?? '');

    // Kota
    String savedCityId = data['city']?.toString() ?? '';
    String? selectedCityId = _resolveKotaId(savedCityId);

    // Tiket
    String selectedTiket = _tiketList.contains(data['ticketType'])
        ? data['ticketType']
        : _tiketList.first;

    // Tanggal
    DateTime? pickedDate = _parseStoredDate(data['date']?.toString() ?? '');

    // Foto
    Uint8List? imageBytes;
    String existingImageUrl = data['imageUrl']?.toString() ?? '';

    bool loading = false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) {
          // ── Pilih tanggal ──────────────────────────────────
          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: pickedDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (_, child) => Theme(
                data: ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: kNavy,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: kNavy,
                  ),
                  dialogBackgroundColor: Colors.white,
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(foregroundColor: kNavy),
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) setSt(() => pickedDate = picked);
          }

          // ── Pilih foto ─────────────────────────────────────
          Future<void> pickImage() async {
            try {
              final picker = ImagePicker();
              final file = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 800,
                maxHeight: 800,
                imageQuality: 75,
              );
              if (file == null) return;
              final bytes = await file.readAsBytes();
              setSt(() {
                imageBytes = bytes;
                existingImageUrl = '';
              });
            } catch (e) {
              showSnack(ctx, 'Gagal memilih foto: $e', isError: true);
            }
          }

          String dateDisplay() {
            if (pickedDate == null) return 'Pilih Tanggal';
            final hari = _hariList[pickedDate!.weekday - 1];
            final bln = _bulanList[pickedDate!.month];
            return '$hari, ${pickedDate!.day} $bln ${pickedDate!.year}';
          }

          String dateForSave() {
            if (pickedDate == null) return '';
            final hari = _hariList[pickedDate!.weekday - 1];
            final bln = _bulanList[pickedDate!.month];
            return '$hari, ${pickedDate!.day} $bln ${pickedDate!.year}';
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 24,
            ),
            child: Container(
              width: 640,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.90,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header navy ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
                    decoration: const BoxDecoration(
                      color: kNavy,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Edit Postingan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Body Scrollable ──────────────────────────
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── FOTO ──────────────────────────
                            _sectionLabel('Foto Postingan'),
                            GestureDetector(
                              onTap: pickImage,
                              child: Container(
                                width: double.infinity,
                                height: 160,
                                decoration: BoxDecoration(
                                  color: kBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _buildImagePreview(
                                    imageBytes,
                                    existingImageUrl,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: pickImage,
                                  icon: const Icon(
                                    Icons.upload_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Upload Foto',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: kAccent,
                                    side: const BorderSide(color: kAccent),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                if (imageBytes != null ||
                                    existingImageUrl.isNotEmpty)
                                  TextButton.icon(
                                    onPressed: () => setSt(() {
                                      imageBytes = null;
                                      existingImageUrl = '';
                                    }),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 16,
                                      color: kDanger,
                                    ),
                                    label: const Text(
                                      'Hapus Foto',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: kDanger,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                Text(
                                  'JPG/PNG, maks 800×800px',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // ── JUDUL ────────────────────────
                            _sectionLabel('Judul Postingan *'),
                            _fField(
                              'Masukkan judul',
                              titleCtrl,
                              required: true,
                            ),

                            // ── TEMPAT & KOTA ─────────────────
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _sectionLabel('Nama Tempat *'),
                                      _fField(
                                        'Contoh: Alun-alun Malang',
                                        placeCtrl,
                                        required: true,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _sectionLabel('Kota'),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 14,
                                        ),
                                        child: _katkota.isEmpty
                                            ? _loadingDropdown()
                                            : DropdownButtonFormField<String>(
                                                value: selectedCityId,
                                                hint: const Text(
                                                  'Pilih kota',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFFB0BAD0),
                                                  ),
                                                ),
                                                isExpanded: true,
                                                decoration: _dropdownDeco(),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF334155),
                                                ),
                                                items: _katkota
                                                    .map(
                                                      (k) => DropdownMenuItem(
                                                        value: k['id'],
                                                        child: Text(
                                                          k['name'] ?? '-',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                              ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                                onChanged: (v) => setSt(
                                                  () => selectedCityId = v,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // ── TANGGAL ───────────────────────
                            _sectionLabel('Tanggal *'),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: FormField<DateTime>(
                                validator: (_) => pickedDate == null
                                    ? 'Tanggal wajib dipilih'
                                    : null,
                                builder: (state) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: pickDate,
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 13,
                                        ),
                                        decoration: BoxDecoration(
                                          color: kBg,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: state.hasError
                                                ? kDanger
                                                : pickedDate != null
                                                ? kAccent.withOpacity(0.5)
                                                : Colors.transparent,
                                            width: state.hasError ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_month_rounded,
                                              size: 18,
                                              color: pickedDate != null
                                                  ? kAccent
                                                  : const Color(0xFFB0BAD0),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                dateDisplay(),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: pickedDate != null
                                                      ? const Color(0xFF334155)
                                                      : const Color(0xFFB0BAD0),
                                                ),
                                              ),
                                            ),
                                            // Chip nama hari otomatis
                                            if (pickedDate != null)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: kNavy.withOpacity(
                                                    0.08,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  _hariList[pickedDate!
                                                          .weekday -
                                                      1],
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: kNavy,
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.arrow_drop_down_rounded,
                                              color: Color(0xFFB0BAD0),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (state.hasError)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 6,
                                          left: 4,
                                        ),
                                        child: Text(
                                          state.errorText!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: kDanger,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            // ── TIPE TIKET ────────────────────
                            _sectionLabel('Tipe Tiket'),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: DropdownButtonFormField<String>(
                                value: selectedTiket,
                                isExpanded: true,
                                decoration: _dropdownDeco(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF334155),
                                ),
                                items: _tiketList
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Row(
                                          children: [
                                            Icon(
                                              t == 'Gratis'
                                                  ? Icons.money_off_rounded
                                                  : Icons.attach_money_rounded,
                                              size: 16,
                                              color: t == 'Gratis'
                                                  ? kSuccess
                                                  : kDanger,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              t,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: t == 'Gratis'
                                                    ? kSuccess
                                                    : kDanger,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setSt(() => selectedTiket = v ?? 'Gratis'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Footer / Actions ─────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFEDF0F7))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Batal',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: loading
                              ? null
                              : () async {
                                  if (formKey.currentState?.validate() != true)
                                    return;
                                  if (pickedDate == null) {
                                    showSnack(
                                      ctx,
                                      'Tanggal wajib dipilih',
                                      isError: true,
                                    );
                                    return;
                                  }
                                  setSt(() => loading = true);
                                  try {
                                    // Encode foto baru jika ada
                                    String finalImageUrl = existingImageUrl;
                                    if (imageBytes != null) {
                                      finalImageUrl =
                                          'data:image/jpeg;base64,${base64Encode(imageBytes!)}';
                                    }

                                    // Ambil nama kota dari ID
                                    String cityName = '';
                                    if (selectedCityId != null &&
                                        _katkota.isNotEmpty) {
                                      cityName =
                                          _katkota.firstWhere(
                                            (k) => k['id'] == selectedCityId,
                                            orElse: () => {'name': ''},
                                          )['name'] ??
                                          '';
                                    }

                                    await FirebaseFirestore.instance
                                        .collection('post')
                                        .doc(docId)
                                        .update({
                                          'title': titleCtrl.text.trim(),
                                          'place': placeCtrl.text.trim(),
                                          'city': selectedCityId ?? '',
                                          'cityName': cityName,
                                          'date': dateForSave(),
                                          'ticketType': selectedTiket,
                                          'imageUrl': finalImageUrl,
                                        });

                                    showSnack(
                                      context,
                                      'Postingan berhasil diperbarui',
                                    );
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  } catch (e) {
                                    setSt(() => loading = false);
                                    showSnack(
                                      context,
                                      'Gagal: $e',
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
                              : const Icon(Icons.save_rounded, size: 17),
                          label: const Text(
                            'Simpan Perubahan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// Resolve ID kota — support kasus tersimpan sbg nama atau ID
  String? _resolveKotaId(String saved) {
    if (saved.isEmpty || _katkota.isEmpty) return null;
    if (_katkota.any((k) => k['id'] == saved)) return saved;
    final byName = _katkota.where((k) => k['name'] == saved);
    if (byName.isNotEmpty) return byName.first['id'];
    return null;
  }

  /// Parse tanggal tersimpan → DateTime
  DateTime? _parseStoredDate(String raw) {
    try {
      final clean = raw
          .replaceAll(RegExp(r'^[A-Za-z]+,?\s*'), '')
          .split('/')
          .first
          .trim();
      final parts = clean.split(' ');
      if (parts.length < 3) return null;
      final day = int.parse(parts[0]);
      final month = _bulanList.indexOf(parts[1]);
      final year = int.parse(parts[2]);
      if (month <= 0) return null;
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  Widget _buildImagePreview(Uint8List? bytes, String url) {
    if (bytes != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(bytes, fit: BoxFit.cover),
          Positioned(
            bottom: 6,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Foto baru',
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        ],
      );
    }
    if (url.startsWith('data:image')) {
      return Image.memory(base64Decode(url.split(',').last), fit: BoxFit.cover);
    }
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _uploadPlaceholder(),
      );
    }
    return _uploadPlaceholder();
  }

  Widget _uploadPlaceholder() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.add_photo_alternate_rounded,
        size: 40,
        color: Colors.grey.shade400,
      ),
      const SizedBox(height: 8),
      Text(
        'Klik untuk upload foto',
        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
      ),
      const SizedBox(height: 4),
      Text(
        'JPG / PNG',
        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
      ),
    ],
  );

  Widget _loadingDropdown() => Container(
    height: 48,
    decoration: BoxDecoration(
      color: kBg,
      borderRadius: BorderRadius.circular(10),
    ),
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: const Text(
      'Memuat data kota...',
      style: TextStyle(fontSize: 13, color: Color(0xFFB0BAD0)),
    ),
  );

  InputDecoration _dropdownDeco() => InputDecoration(
    filled: true,
    fillColor: kBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kAccent, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kDanger, width: 1.5),
    ),
  );

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF475569),
      ),
    ),
  );

  Widget _fField(
    String hint,
    TextEditingController ctrl, {
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 13),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty)
                  ? 'Field ini wajib diisi'
                  : null
            : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFB0BAD0)),
          filled: true,
          fillColor: kBg,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kAccent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kDanger, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kDanger, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return SizedBox(
      width: 280,
      height: 40,
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Cari judul, pengguna, tempat...',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFB0BAD0)),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: Color(0xFFB0BAD0),
          ),
          suffixIcon: _query.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Color(0xFFB0BAD0),
                  ),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                  Text(
                    '$val',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _hapus(String docId) async {
    final ok = await showDeleteDialog(context);
    if (ok == true) {
      await FirebaseFirestore.instance.collection('post').doc(docId).delete();
      showSnack(context, 'Postingan dihapus', isError: true);
    }
  }
}
