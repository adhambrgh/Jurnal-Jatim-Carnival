import 'package:flutter/material.dart';
import 'dart:convert';

// ═══════════════════════════════════════════════════════════════
// WARNA & KONSTANTA GLOBAL
// ═══════════════════════════════════════════════════════════════
const kNavy   = Color(0xFF1E2A5E);
const kAccent = Color(0xFF4F6AF5);
const kBg     = Color(0xFFF4F6FB);
const kCard   = Colors.white;
const kDanger = Color(0xFFE53935);
const kSuccess = Color(0xFF2E7D32);

// ═══════════════════════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════════════════════
class RowData {
  final List<Widget> cells;
  const RowData({required this.cells});
}

// ═══════════════════════════════════════════════════════════════
// WIDGET HELPERS (dipakai di semua halaman)
// ═══════════════════════════════════════════════════════════════

/// Teks standar tabel
Widget cellText(
  String text, {
  bool bold = false,
  Color? color,
  int maxLines = 1,
}) {
  return Text(
    text,
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontSize: 13,
      fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
      color: color ?? const Color(0xFF334155),
    ),
  );
}

/// Thumbnail gambar
Widget thumbWidget(String imgUrl) {
  if (imgUrl.startsWith('data:image')) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        base64Decode(imgUrl.split(',').last),
        width: 44, height: 44, fit: BoxFit.cover,
      ),
    );
  }
  if (imgUrl.startsWith('http')) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imgUrl, width: 44, height: 44, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderThumb(),
      ),
    );
  }
  return _placeholderThumb();
}

Widget _placeholderThumb() => Container(
  width: 44, height: 44,
  decoration: BoxDecoration(
    color: kNavy.withOpacity(0.08),
    borderRadius: BorderRadius.circular(8),
  ),
  child: const Icon(Icons.image_rounded, color: kNavy, size: 20),
);

/// Badge tiket
Widget ticketBadge(String? type) {
  final free =
      type == null || type.isEmpty || type.toLowerCase() == 'gratis';
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: free ? kSuccess.withOpacity(0.1) : kDanger.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      free ? 'Gratis' : type ?? '',
      style: TextStyle(
        color: free ? kSuccess : kDanger,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// Tombol edit + hapus
Widget actionButtons({
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  return Row(
    children: [
      iconBtn(icon: Icons.edit_rounded, color: kAccent, tooltip: 'Edit', onTap: onEdit),
      const SizedBox(width: 4),
      iconBtn(icon: Icons.delete_rounded, color: kDanger, tooltip: 'Hapus', onTap: onDelete),
    ],
  );
}

Widget iconBtn({
  required IconData icon,
  required Color color,
  required String tooltip,
  required VoidCallback onTap,
}) {
  return Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// TABEL BUILDER GENERIC
// ═══════════════════════════════════════════════════════════════
Widget buildDataTable({
  required List<String> columns,
  required List<double> widths,
  required List<RowData> rows,
  required String emptyMsg,
  String searchQuery = '',
}) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: kNavy,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: List.generate(columns.length, (i) => SizedBox(
                width: widths[i],
                child: Text(columns[i],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.4,
                  ),
                ),
              )),
            ),
          ),

          // Jumlah hasil pencarian
          if (searchQuery.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: kAccent.withOpacity(0.06),
              child: Text(
                '${rows.length} hasil untuk "$searchQuery"',
                style: const TextStyle(
                  fontSize: 12, color: kAccent, fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Empty state
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  Icon(Icons.inbox_rounded, size: 40,
                      color: Colors.grey.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  Text(emptyMsg,
                      style: const TextStyle(
                          color: Color(0xFFB0BAD0), fontSize: 14)),
                ],
              ),
            )
          else
            ...rows.asMap().entries.map((entry) {
              final even = entry.key % 2 == 0;
              return Container(
                decoration: BoxDecoration(
                  color: even ? kCard : const Color(0xFFF9FAFF),
                  border: const Border(
                    bottom: BorderSide(color: Color(0xFFEDF0F7), width: 1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(
                        entry.value.cells.length,
                        (i) => SizedBox(
                              width: widths[i],
                              child: entry.value.cells[i],
                            )),
                  ),
                ),
              );
            }),
        ],
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// DIALOG HELPERS
// ═══════════════════════════════════════════════════════════════

/// Dialog form edit generik
void showFormDialog({
  required BuildContext context,
  required String title,
  required List<Widget> fields,
  Widget? extra,
  required Future<void> Function() onSave,
}) {
  final formKey = GlobalKey<FormState>();
  bool loading = false;

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(builder: (ctx, setSt) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        title: Row(
          children: [
            const Icon(Icons.edit_rounded, color: kAccent, size: 20),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kNavy)),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [...fields, if (extra != null) extra],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: loading
                ? null
                : () async {
                    if (formKey.currentState?.validate() != true) return;
                    setSt(() => loading = true);
                    await onSave();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
            ),
            child: loading
                ? const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Simpan',
                    style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      );
    }),
  );
}

/// Dialog konfirmasi hapus
Future<bool?> showDeleteDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      title: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: kDanger.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.delete_rounded,
                color: kDanger, size: 18),
          ),
          const SizedBox(width: 12),
          const Text('Hapus Data?',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kNavy)),
        ],
      ),
      content: const Text(
        'Data ini akan dihapus secara permanen dan tidak bisa dikembalikan.',
        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal',
              style: TextStyle(color: Color(0xFF94A3B8))),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: kDanger,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
          ),
          child: const Text('Ya, Hapus',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

/// Form field standar
Widget formField(
  String label,
  TextEditingController ctrl, {
  int maxLines = 1,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            fontSize: 12, color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: kBg,
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
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
      ),
    ),
  );
}

/// Snackbar helper
void showSnack(
  BuildContext context,
  String msg, {
  bool isError = false,
}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(
      children: [
        Icon(
          isError ? Icons.delete_rounded : Icons.check_circle_rounded,
          color: Colors.white, size: 18,
        ),
        const SizedBox(width: 10),
        Text(msg, style: const TextStyle(fontSize: 13)),
      ],
    ),
    backgroundColor: isError ? kDanger : kAccent,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.all(16),
  ));
}