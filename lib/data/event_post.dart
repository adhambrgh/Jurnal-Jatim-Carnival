class EventPost {
  String id;
  String user;
  final String uid;
  String title;
  String imageUrl;
  String description;
  String day;
  String place;
  String date;
  String profileImage;
  int likeCount;
  bool isLiked;
  String? ticketType;
  List<String> likedBy;
  List<String> savedBy;
  List<String> imageUrls;
  List<String> videoUrls;


  EventPost({
    this.id = '',
    required this.user,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.day,
    required this.place,
    required this.date,
    required this.profileImage,
    this.likeCount = 0,
    this.isLiked = false,
    this.ticketType,
    this.likedBy = const [],
    this.savedBy = const [],
    this.imageUrls = const [],
    this.videoUrls = const [],
    required this.uid,
  });

  factory EventPost.fromFirestore(Map<String, dynamic> data, String docId) {
    return EventPost(
      id: docId,
      user: data['user'] ?? '',
      title: data['title'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      day: data['day'] ?? '',
      place: data['place'] ?? '',
      date: data['date'] ?? '',
      profileImage: data['profileImage'] ?? '',
      ticketType: data['ticketType'],
      likeCount: int.tryParse(data['likeCount'].toString()) ?? 0,
      isLiked: false,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      savedBy: List<String>.from(data['savedBy'] ?? []),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      videoUrls: List<String>.from(data['videoUrls'] ?? []),
      uid: data['uid'] ?? '',
    );
  }
}
