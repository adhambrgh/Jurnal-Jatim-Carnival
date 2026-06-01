import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_contans.dart';

class KotaPage extends StatefulWidget {
  const KotaPage({super.key});

  @override
  State<KotaPage> createState() => _KotaPageState();
}

class _KotaPageState extends State<KotaPage> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Text(
            'Kategori Kota',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),

          SizedBox(
            width: 250,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari kota...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) {
                setState(() {
                  search = v.toLowerCase();
                });
              },
            ),
          ),

          const SizedBox(width: 12),

          ElevatedButton.icon(
            onPressed: () => _showTambahDialog(),
            icon: const Icon(Icons.add),
            label: const Text("Tambah Kota"),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('katkota')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final docs = snapshot.data!.docs.where((doc) {
          final nama =
              (doc['nama'] ?? '')
                  .toString()
                  .toLowerCase();

          return nama.contains(search);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: SizedBox(
                  width: 60,
                  child: Image.asset(
                    doc['imageUrl'] ?? '',
                    errorBuilder:
                        (_, __, ___) =>
                            const Icon(Icons.location_city),
                  ),
                ),

                title: Text(
                  doc['nama'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: Text(
                  doc['heroImage'] ?? '',
                ),

                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _showEditDialog(doc);
                      },
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('katkota')
                            .doc(doc.id)
                            .delete();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTambahDialog() {
    final nama = TextEditingController();
    final image = TextEditingController();
    final hero = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tambah Kota"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nama,
              decoration: const InputDecoration(
                labelText: "Nama Kota",
              ),
            ),

            TextField(
              controller: image,
              decoration: const InputDecoration(
                labelText: "Image Asset",
              ),
            ),

            TextField(
              controller: hero,
              decoration: const InputDecoration(
                labelText: "Hero Image",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),

          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('katkota')
                  .add({
                'nama': nama.text,
                'imageUrl': image.text,
                'heroImage': hero.text,
              });

              Navigator.pop(context);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final nama =
        TextEditingController(text: data['nama']);

    final image =
        TextEditingController(text: data['imageUrl']);

    final hero =
        TextEditingController(text: data['heroImage']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Kota"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nama,
              decoration: const InputDecoration(
                labelText: "Nama Kota",
              ),
            ),

            TextField(
              controller: image,
              decoration: const InputDecoration(
                labelText: "Image Asset",
              ),
            ),

            TextField(
              controller: hero,
              decoration: const InputDecoration(
                labelText: "Hero Image",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),

          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('katkota')
                  .doc(doc.id)
                  .update({
                'nama': nama.text,
                'imageUrl': image.text,
                'heroImage': hero.text,
              });

              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }
}