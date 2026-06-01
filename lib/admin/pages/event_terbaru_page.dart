import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'admin_contans.dart';

// ═══════════════════════════════════════════════════════════════
// DATA STATIS: KOTA & KATEGORI
// ═══════════════════════════════════════════════════════════════
const _kotaList = [
  'Malang', 'Surabaya', 'Batu', 'Blitar', 'Kediri',
  'Madiun', 'Mojokerto', 'Pasuruan', 'Probolinggo',
  'Jember', 'Banyuwangi', 'Sidoarjo', 'Gresik',
  'Lamongan', 'Bojonegoro', 'Tuban', 'Ngawi',
  'Magetan', 'Ponorogo', 'Pacitan', 'Trenggalek',
  'Tulungagung', 'Nganjuk', 'Jombang', 'Lumajang',
  'Bondowoso', 'Situbondo', 'Sampang', 'Pamekasan',
  'Sumenep', 'Bangkalan',
];

const _kategoriList = [
  'Fun Event', 'Music', 'Festival', 'Kuliner',
  'Olahraga', 'Pameran', 'Seminar', 'Workshop',
  'Bazaar', 'Seni & Budaya', 'Hiburan', 'Pendidikan',
  'Teknologi', 'Komunitas', 'Lainnya',
];

const _hariList = [
  'Senin', 'Selasa', 'Rabu', 'Kamis',
  'Jumat', 'Sabtu', 'Minggu',
];

const _bulanList = [
  '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

// ═══════════════════════════════════════════════════════════════
// HALAMAN: EVENT TERBARU
// ═══════════════════════════════════════════════════════════════
class EventTerbaruPage extends StatefulWidget {
  const EventTerbaruPage({super.key});
  @override
  State<EventTerbaruPage> createState() => _EventTerbaruPageState();
}

class _EventTerbaruPageState extends State<EventTerbaruPage> {
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
          _statChip(Icons.event_rounded, 'Total Event',
              color: const Color(0xFF7C3AED),
              stream: FirebaseFirestore.instance
                  .collection('event_terbaru')
                  .snapshots()
                  .map((s) => s.docs.length)),
          const SizedBox(width: 12),
          _statChip(Icons.money_off_rounded, 'Gratis',
              color: kSuccess,
              stream: FirebaseFirestore.instance
                  .collection('event_terbaru')
                  .where('isFree', isEqualTo: true)
                  .snapshots()
                  .map((s) => s.docs.length)),
          const SizedBox(width: 12),
          _statChip(Icons.attach_money_rounded, 'Berbayar',
              color: kDanger,
              stream: FirebaseFirestore.instance
                  .collection('event_terbaru')
                  .where('isFree', isEqualTo: false)
                  .snapshots()
                  .map((s) => s.docs.length)),
          const Spacer(),
          _searchBar(),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showEventDialog(isEdit: false),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tambah Event',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tabel Konten ─────────────────────────────────────────────
  Widget _buildContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('event_terbaru')
          .orderBy('updatedAt', descending: true)
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
                return [
                  d['title'], d['location'], d['kota'],
                  d['kategori'], d['penyelenggara'], d['description'],
                ].any((f) => f?.toString().toLowerCase().contains(_query) ?? false);
              }).toList();

        final rows = docs.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final isFree = d['isFree'] == true;
          final imgUrl = d['imageUrl']?.toString() ?? '';
          return RowData(cells: [
            // Foto
            _thumbWidget(imgUrl),
            // Judul
            cellText(d['title'] ?? '-', bold: true, maxLines: 2),
            // Lokasi + Kota
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                cellText(d['location'] ?? '-', maxLines: 1),
                if ((d['kota'] ?? '').toString().isNotEmpty)
                  cellText(d['kota'].toString(), color: const Color(0xFF94A3B8)),
              ],
            ),
            // Tanggal
            cellText(d['date'] ?? '-', color: const Color(0xFF64748B)),
            // Kategori
            cellText(d['kategori'] ?? '-', color: const Color(0xFF7C3AED)),
            // Penyelenggara
            cellText(d['penyelenggara'] ?? '-'),
            // Tiket
            _tiketBadge(isFree),
            // Aksi
            actionButtons(
              onEdit: () => _showEventDialog(isEdit: true, docId: doc.id, initial: d),
              onDelete: () => _hapus(doc.id),
            ),
          ]);
        }).toList();

        return buildDataTable(
          emptyMsg: 'Belum ada event terbaru',
          searchQuery: _query,
          columns: const ['Foto', 'Judul', 'Lokasi', 'Tanggal', 'Kategori', 'Penyelenggara', 'Tiket', 'Aksi'],
          widths: const [60, 160, 140, 120, 100, 120, 90, 90],
          rows: rows,
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  // DIALOG TAMBAH / EDIT
  // ══════════════════════════════════════════════════════════════
  void _showEventDialog({
    required bool isEdit,
    String? docId,
    Map<String, dynamic>? initial,
  }) {
    final d = initial ?? {};

    final titleCtrl  = TextEditingController(text: d['title'] ?? '');
    final locCtrl    = TextEditingController(text: d['location'] ?? '');
    final penyelCtrl = TextEditingController(text: d['penyelenggara'] ?? '');
    final linkCtrl   = TextEditingController(text: d['link'] ?? '');
    final descCtrl   = TextEditingController(text: d['description'] ?? '');

    String? selectedKota     = _kotaList.contains(d['kota']) ? d['kota'] : null;
    String? selectedKategori = _kategoriList.contains(d['kategori']) ? d['kategori'] : null;
    bool    isFree           = d['isFree'] != false;
    DateTime? pickedDate;

    // Parse tanggal tersimpan jika edit
    if (isEdit && (d['date'] ?? '').toString().isNotEmpty) {
      pickedDate = _parseStoredDate(d['date'].toString());
    }

    // Foto
    Uint8List? imageBytes;
    String existingImageUrl = d['imageUrl']?.toString() ?? '';

    bool loading = false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(builder: (ctx, setSt) {

        // Pilih tanggal
        Future<void> pickDate() async {
          // Pakai outer context (context) bukan ctx dialog
          // supaya tidak crash & tidak perlu flutter_localizations
          final picked = await showDatePicker(
            context: context,
            initialDate: pickedDate ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
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

        // ── Pilih foto ───────────────────────────────────────
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

        // Format tanggal untuk display di button
        String dateDisplay() {
          if (pickedDate == null) return 'Pilih Tanggal';
          final hari = _hariList[pickedDate!.weekday - 1];
          final bln  = _bulanList[pickedDate!.month];
          return '$hari, ${pickedDate!.day} $bln ${pickedDate!.year}';
        }

        // Format tanggal untuk disimpan ke Firestore
        String dateForSave() {
          if (pickedDate == null) return '';
          final hari = _hariList[pickedDate!.weekday - 1];
          final bln  = _bulanList[pickedDate!.month];
          return '$hari, ${pickedDate!.day} $bln ${pickedDate!.year}';
        }

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Container(
            width: 640,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.90,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ── Header ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
                  decoration: const BoxDecoration(
                    color: kNavy,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          isEdit ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
                          color: Colors.white, size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEdit ? 'Edit Event' : 'Tambah Event Baru',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => Navigator.pop(ctx),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Body Scrollable ──────────────────────────────
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ── UPLOAD FOTO ──────────────────────
                          _sectionLabel('Foto Event'),
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
                                    style: BorderStyle.solid),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildImagePreview(imageBytes, existingImageUrl),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: pickImage,
                                icon: const Icon(Icons.upload_rounded, size: 16),
                                label: const Text('Upload Foto',
                                    style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: kAccent,
                                  side: const BorderSide(color: kAccent),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (imageBytes != null || existingImageUrl.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () => setSt(() {
                                    imageBytes = null;
                                    existingImageUrl = '';
                                  }),
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      size: 16, color: kDanger),
                                  label: const Text('Hapus Foto',
                                      style: TextStyle(
                                          fontSize: 12, color: kDanger)),
                                ),
                              const Spacer(),
                              Text(
                                'JPG/PNG, maks 800×800px',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // ── JUDUL ────────────────────────────
                          _sectionLabel('Judul Event *'),
                          _fField('Masukkan judul event', titleCtrl, required: true),

                          // ── LOKASI & KOTA ────────────────────
                          Row(children: [
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionLabel('Lokasi / Venue *'),
                                _fField('Contoh: GOR Kanjuruhan', locCtrl, required: true),
                              ],
                            )),
                            const SizedBox(width: 16),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionLabel('Kota *'),
                                // ── SELECT KOTA ──────────────
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: DropdownButtonFormField<String>(
                                    value: selectedKota,
                                    hint: const Text('Pilih kota',
                                        style: TextStyle(fontSize: 13,
                                            color: Color(0xFFB0BAD0))),
                                    isExpanded: true,
                                    validator: (v) =>
                                        v == null ? 'Kota wajib dipilih' : null,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: kBg,
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                            color: kAccent, width: 1.5),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                            color: kDanger, width: 1.5),
                                      ),
                                    ),
                                    style: const TextStyle(
                                        fontSize: 13, color: Color(0xFF334155)),
                                    items: _kotaList
                                        .map((k) => DropdownMenuItem(
                                            value: k,
                                            child: Text(k,
                                                style: const TextStyle(fontSize: 13))))
                                        .toList(),
                                    onChanged: (v) => setSt(() => selectedKota = v),
                                  ),
                                ),
                              ],
                            )),
                          ]),

                          // ── TANGGAL (DATE PICKER) ────────────
                          _sectionLabel('Tanggal *'),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: FormField<DateTime>(
                              validator: (_) => pickedDate == null
                                  ? 'Tanggal wajib dipilih' : null,
                              builder: (state) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: pickDate,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 13),
                                      decoration: BoxDecoration(
                                        color: kBg,
                                        borderRadius: BorderRadius.circular(10),
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
                                          // Chip hari otomatis
                                          if (pickedDate != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: kNavy.withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                _hariList[pickedDate!.weekday - 1],
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: kNavy),
                                              ),
                                            ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.arrow_drop_down_rounded,
                                              color: Color(0xFFB0BAD0)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (state.hasError)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6, left: 4),
                                      child: Text(state.errorText!,
                                          style: const TextStyle(
                                              fontSize: 12, color: kDanger)),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // ── KATEGORI & PENYELENGGARA ─────────
                          Row(children: [
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionLabel('Kategori'),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: DropdownButtonFormField<String>(
                                    value: selectedKategori,
                                    hint: const Text('Pilih kategori',
                                        style: TextStyle(fontSize: 13,
                                            color: Color(0xFFB0BAD0))),
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: kBg,
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                            color: kAccent, width: 1.5),
                                      ),
                                    ),
                                    style: const TextStyle(
                                        fontSize: 13, color: Color(0xFF334155)),
                                    items: _kategoriList
                                        .map((k) => DropdownMenuItem(
                                            value: k,
                                            child: Text(k,
                                                style: const TextStyle(fontSize: 13))))
                                        .toList(),
                                    onChanged: (v) =>
                                        setSt(() => selectedKategori = v),
                                  ),
                                ),
                              ],
                            )),
                            const SizedBox(width: 16),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionLabel('Penyelenggara'),
                                _fField('Nama penyelenggara', penyelCtrl),
                              ],
                            )),
                          ]),

                          // ── TIKET ────────────────────────────
                          _sectionLabel('Tipe Tiket'),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              children: [
                                _tiketOption(
                                  label: 'Gratis',
                                  icon: Icons.money_off_rounded,
                                  selected: isFree,
                                  color: kSuccess,
                                  onTap: () => setSt(() => isFree = true),
                                ),
                                const SizedBox(width: 10),
                                _tiketOption(
                                  label: 'Berbayar',
                                  icon: Icons.attach_money_rounded,
                                  selected: !isFree,
                                  color: kDanger,
                                  onTap: () => setSt(() => isFree = false),
                                ),
                              ],
                            ),
                          ),

                          // ── LINK ─────────────────────────────
                          _sectionLabel('Link Event / Pendaftaran'),
                          _fField('https://...', linkCtrl),

                          // ── DESKRIPSI ─────────────────────────
                          _sectionLabel('Deskripsi'),
                          _fField(
                            'Tulis deskripsi singkat event...',
                            descCtrl,
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Footer ──────────────────────────────────────
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
                        child: const Text('Batal',
                            style: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: loading
                            ? null
                            : () async {
                                if (formKey.currentState?.validate() != true) return;
                                if (pickedDate == null) {
                                  showSnack(ctx, 'Tanggal wajib dipilih', isError: true);
                                  return;
                                }
                                setSt(() => loading = true);
                                try {
                                  // Encode gambar ke base64 jika ada yang baru
                                  String finalImageUrl = existingImageUrl;
                                  if (imageBytes != null) {
                                    final base64Str = base64Encode(imageBytes!);
                                    finalImageUrl = 'data:image/jpeg;base64,$base64Str';
                                  }

                                  final payload = <String, dynamic>{
                                    'title':         titleCtrl.text.trim(),
                                    'location':      locCtrl.text.trim(),
                                    'kota':          selectedKota ?? '',
                                    'date':          dateForSave(),
                                    'kategori':      selectedKategori ?? '',
                                    'penyelenggara': penyelCtrl.text.trim(),
                                    'link':          linkCtrl.text.trim(),
                                    'description':   descCtrl.text.trim(),
                                    'isFree':        isFree,
                                    'imageUrl':      finalImageUrl,
                                    'updatedAt':     FieldValue.serverTimestamp(),
                                  };

                                  if (isEdit && docId != null) {
                                    await FirebaseFirestore.instance
                                        .collection('event_terbaru')
                                        .doc(docId)
                                        .update(payload);
                                    showSnack(context, 'Event berhasil diperbarui');
                                  } else {
                                    payload['createdAt'] = FieldValue.serverTimestamp();
                                    await FirebaseFirestore.instance
                                        .collection('event_terbaru')
                                        .add(payload);
                                    showSnack(context, 'Event berhasil ditambahkan');
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } catch (e) {
                                  setSt(() => loading = false);
                                  showSnack(context, 'Gagal: $e', isError: true);
                                }
                              },
                        icon: loading
                            ? const SizedBox(
                                width: 14, height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Icon(isEdit ? Icons.save_rounded : Icons.add_rounded,
                                size: 17),
                        label: Text(
                          isEdit ? 'Simpan Perubahan' : 'Tambah Event',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEdit ? kAccent : kNavy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PARSE TANGGAL TERSIMPAN ("Minggu, 20 Mei 2025/14" → DateTime)
  // ═══════════════════════════════════════════════════════════════
  DateTime? _parseStoredDate(String raw) {
    try {
      // Hapus nama hari + "/"
      final clean = raw.replaceAll(RegExp(r'^[A-Za-z]+,?\s*'), '').split('/').first.trim();
      final parts = clean.split(' ');
      if (parts.length < 3) return null;
      final day   = int.parse(parts[0]);
      final month = _bulanList.indexOf(parts[1]);
      final year  = int.parse(parts[2]);
      if (month <= 0) return null;
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HAPUS
  // ═══════════════════════════════════════════════════════════════
  Future<void> _hapus(String docId) async {
    final ok = await showDeleteDialog(context);
    if (ok == true) {
      await FirebaseFirestore.instance
          .collection('event_terbaru')
          .doc(docId)
          .delete();
      showSnack(context, 'Event dihapus', isError: true);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // WIDGET HELPERS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildImagePreview(Uint8List? bytes, String url) {
    if (bytes != null) {
      return Stack(fit: StackFit.expand, children: [
        Image.memory(bytes, fit: BoxFit.cover),
        Positioned(
          bottom: 6, right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Foto baru',
                style: TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ),
      ]);
    }
    if (url.startsWith('data:image')) {
      return Image.memory(
        base64Decode(url.split(',').last),
        fit: BoxFit.cover,
      );
    }
    if (url.startsWith('http')) {
      return Image.network(url, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _uploadPlaceholder());
    }
    return _uploadPlaceholder();
  }

  Widget _uploadPlaceholder() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_rounded,
              size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text('Klik untuk upload foto',
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          Text('JPG / PNG',
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade400)),
        ],
      );

  Widget _thumbWidget(String url) {
    if (url.startsWith('data:image')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          base64Decode(url.split(',').last),
          width: 44, height: 44, fit: BoxFit.cover,
        ),
      );
    }
    if (url.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(url, width: 44, height: 44, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _thumbPlaceholder()),
      );
    }
    return _thumbPlaceholder();
  }

  Widget _thumbPlaceholder() => Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: kNavy.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image_rounded, color: kNavy, size: 20),
      );

  Widget _tiketBadge(bool isFree) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isFree ? kSuccess.withOpacity(0.1) : kDanger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          isFree ? 'Gratis' : 'Berbayar',
          style: TextStyle(
              color: isFree ? kSuccess : kDanger,
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
      );

  Widget _tiketOption({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.1) : kBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : const Color(0xFFE2E8F0),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: selected ? color : const Color(0xFFB0BAD0)),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected ? color : const Color(0xFF94A3B8))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569))),
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
            ? (v) => (v == null || v.trim().isEmpty) ? 'Field ini wajib diisi' : null
            : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFB0BAD0)),
          filled: true,
          fillColor: kBg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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

  Widget _statChip(IconData icon, String label,
      {Color color = kAccent, required Stream<int> stream}) {
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
          child: Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$val',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: color)),
              Text(label,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ]),
          ]),
        );
      },
    );
  }

  Widget _searchBar() {
    return SizedBox(
      width: 260, height: 40,
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Cari event...',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFB0BAD0)),
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
}