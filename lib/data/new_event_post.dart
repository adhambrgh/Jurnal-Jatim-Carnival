class NewEventPost {
  final String title;
  final String description;
  final String imagePath;
  final DateTime date;
  final String city;      // ← kota pilihan
  final String location;  // ← lokasi detail

  NewEventPost({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.date,
    required this.city,
    required this.location,
  });
}
