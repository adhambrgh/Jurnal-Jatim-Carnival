import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      home: ProfilePhotoPicker(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class ProfilePhotoPicker extends StatelessWidget {
  const ProfilePhotoPicker({super.key});

  @override
  Widget build(BuildContext context) {
    // Warna yang digunakan berdasarkan gambar
    const Color primaryPurple = Color(0xFF4A56AF); // Warna header & tombol
    const Color backgroundPink = Color(0xFFFFF1F1); // Warna background atas

    return Scaffold(
      backgroundColor: Color(0xFFFFF6F2),
      appBar: AppBar(
        backgroundColor: primaryPurple,
        elevation: 0,
        leading: const Icon(Icons.close, color: Colors.white),
        title: const Text(
          'Pilih foto',
          style: TextStyle(color: Color(0xFFFFF6F2), fontSize: 18),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(
              Icons.signal_cellular_alt,
              color: Color(0xFFFFF6F2),
              size: 20,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.battery_full, color: Color(0xFFFFF6F2), size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          // Bagian Atas: Preview Lingkaran & Tombol Simpan
          Container(
            width: double.infinity,
            color: backgroundPink,
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              children: [
                // Bulatan Foto Profil
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFFFFF6F2), width: 2),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://placeholder.com/120',
                      ), // Ganti dengan asset/link gambar
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Tombol Simpan dengan Shadow/Lekukan Halus
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF7A86D3,
                    ), // Warna tombol lebih muda
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(
                      color: Color(0xFFFFF6F2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bagian Bawah: Grid Galeri Foto
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 kolom sesuai gambar
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
                childAspectRatio: 1.0,
              ),
              itemCount: 6, // Jumlah foto di contoh
              itemBuilder: (context, index) {
                return Container(
                  color: Colors.grey[300],
                  child: Image.network(
                    'https://via.placeholder.com/300', // Ganti dengan foto-foto budaya/event Anda
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
