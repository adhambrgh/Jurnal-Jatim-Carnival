class EventTerbaru {
  final String title;
  final String location;
  final String date;
  final String imageUrl;
  final bool isFree;
  final String postId;
  final String link;

  EventTerbaru({
    required this.title,
    required this.location,
    required this.date,
    required this.imageUrl,
    required this.isFree,
    required this.postId,
    this.link = '',
  });

  factory EventTerbaru.fromFirestore(Map<String, dynamic> data, String docId) {
    return EventTerbaru(
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      date: data['date'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isFree: data['isFree'] ?? false,
      postId: data['postId'] ?? docId,
      link: data['link'] ?? '',
    );
  }
}
