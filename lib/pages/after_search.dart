import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jurnal_jatim_carnival/data/event_post.dart';
import 'package:jurnal_jatim_carnival/data/event_terbaru.dart';
import 'package:jurnal_jatim_carnival/pages/profil_page.dart';
import 'package:jurnal_jatim_carnival/pages/event_terbaru_detail.dart';

// ════════════════════════════════════════════════════════════════
// MODEL HASIL GABUNGAN
// ════════════════════════════════════════════════════════════════
enum _ResultType { post, eventTerbaru }

class _SearchResult {
  final _ResultType type;
  final EventPost? post;
  final Map<String, dynamic>? eventData;

  const _SearchResult.fromPost(this.post)
    : type = _ResultType.post,
      eventData = null;

  const _SearchResult.fromEvent(this.eventData)
    : type = _ResultType.eventTerbaru,
      post = null;
}

// ════════════════════════════════════════════════════════════════
// SEARCH RESULT PAGE
// ════════════════════════════════════════════════════════════════
class SearchResultPage extends StatefulWidget {
  /// Postingan user yang sudah diload sebelumnya (dari home)
  final List<EventPost> results;

  const SearchResultPage({super.key, required this.results});

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String _query = '';
  bool _hasSearched = false;
  bool _isSearching = false;

  // Hasil gabungan
  List<_SearchResult> _results = [];

  // Cache event_terbaru dari Firestore (load sekali)
  List<Map<String, dynamic>> _allEvents = [];
  bool _eventsLoaded = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadEvents();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── Load event_terbaru dari Firestore ─────────────────────────
  Future<void> _loadEvents() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('event_terbaru')
          .get();
      setState(() {
        _allEvents = snap.docs.map((doc) {
          final d = Map<String, dynamic>.from(doc.data());
          d['id'] = doc.id;
          return d;
        }).toList();
        _eventsLoaded = true;
      });
    } catch (_) {
      setState(() => _eventsLoaded = true);
    }
  }

  // ── Search gabungan ───────────────────────────────────────────
  void _onSearch(String value) {
    final q = value.toLowerCase().trim();
    setState(() {
      _query = q;
      _hasSearched = value.isNotEmpty;
      _isSearching = true;
    });

    if (q.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    // Filter postingan user
    final postResults = widget.results
        .where(
          (p) =>
              p.title.toLowerCase().contains(q) ||
              p.place.toLowerCase().contains(q) ||
              p.user.toLowerCase().contains(q),
        )
        .map((p) => _SearchResult.fromPost(p))
        .toList();

    // Filter event terbaru
    final eventResults = _allEvents
        .where(
          (e) =>
              (e['title']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['location']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['kota']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['kategori']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['penyelenggara']?.toString().toLowerCase() ?? '').contains(q),
        )
        .map((e) => _SearchResult.fromEvent(e))
        .toList();

    setState(() {
      _results = [...postResults, ...eventResults];
      _isSearching = false;
    });
  }

  // ── Filter per tab ────────────────────────────────────────────
  List<_SearchResult> get _postResults =>
      _results.where((r) => r.type == _ResultType.post).toList();

  List<_SearchResult> get _eventResults =>
      _results.where((r) => r.type == _ResultType.eventTerbaru).toList();

  List<_SearchResult> get _currentTabResults =>
      _tabController.index == 0 ? _postResults : _eventResults;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F2),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            _buildSearchBar(),
            const SizedBox(height: 4),

            // Tab bar — muncul hanya kalau sudah search
            if (_hasSearched) _buildTabBar(),

            // Konten
            Expanded(
              child: _isSearching
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2D3561),
                      ),
                    )
                  : !_hasSearched
                  ? _buildIdleState()
                  : _currentTabResults.isEmpty
                  ? _buildEmptyState()
                  : _buildResultList(_currentTabResults),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D336B).withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF2D3561),
          borderRadius: BorderRadius.circular(30),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF2D3561),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.article_rounded, size: 16),
                const SizedBox(width: 6),
                Text('Postingan (${_postResults.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_rounded, size: 16),
                const SizedBox(width: 6),
                Text('Event (${_eventResults.length})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF2D3561),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF142C6E).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFFFFF6F2),
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2D336B),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white54, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      autofocus: true,
                      style: const TextStyle(color: Color(0xFFFFF6F2)),
                      decoration: const InputDecoration(
                        hintText: 'Cari postingan & event...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: _onSearch,
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _onSearch('');
                      },
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white54,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── List hasil ────────────────────────────────────────────────
  Widget _buildResultList(List<_SearchResult> items) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return item.type == _ResultType.post
            ? _buildPostCard(context, item.post!)
            : _buildEventCard(context, item.eventData!);
      },
    );
  }

  // ── Card Postingan User ───────────────────────────────────────
  Widget _buildPostCard(BuildContext context, EventPost post) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostDetailFromFirestore(
            postData: {
              'id': post.id,
              'uid': post.uid,
              'user': post.user,
              'title': post.title,
              'imageUrl': post.imageUrl,
              'imageUrls': post.imageUrls,
              'videoUrls': post.videoUrls,
              'description': post.description,
              'day': post.day,
              'place': post.place,
              'date': post.date,
              'profileImage': post.profileImage,
              'ticketType': post.ticketType,
              'likeCount': post.likeCount,
              'likedBy': post.likedBy,
              'savedBy': post.savedBy,
            },
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2D336B),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D336B).withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildImage(post.imageUrl),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge tipe
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.article_rounded,
                          size: 11,
                          color: Colors.white70,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Postingan',
                          style: TextStyle(fontSize: 10, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.title,
                    style: const TextStyle(
                      color: Color(0xFFFFF6F2),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.calendar_today_rounded,
                    '${post.day}, ${post.date}',
                  ),
                  const SizedBox(height: 4),
                  _infoRow(Icons.location_on_rounded, post.place),
                  const SizedBox(height: 10),
                  Divider(color: Colors.white.withOpacity(0.1), height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _avatar(post.profileImage),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          post.user,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _tiketBadge(post.ticketType),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card Event Terbaru ────────────────────────────────────────
  Widget _buildEventCard(BuildContext context, Map<String, dynamic> e) {
    final isFree = e['isFree'] == true;
    final imgUrl = e['imageUrl']?.toString() ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventTerbaruDetailPage(
            event: EventTerbaru(
              title: e['title'] ?? '',
              location: e['location'] ?? '',
              date: e['date'] ?? '',
              imageUrl: imgUrl,
              isFree: isFree,
              postId: e['id'] ?? '',
            ),
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2D336B),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D336B).withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildImage(imgUrl),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge tipe
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_rounded,
                          size: 11,
                          color: Color(0xFFD8B4FE),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Event Terbaru',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFD8B4FE),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e['title'] ?? '-',
                    style: const TextStyle(
                      color: Color(0xFFFFF6F2),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _infoRow(Icons.calendar_today_rounded, e['date'] ?? '-'),
                  const SizedBox(height: 4),
                  _infoRow(
                    Icons.location_on_rounded,
                    [e['location'], e['kota']]
                        .where((s) => s != null && s.toString().isNotEmpty)
                        .join(', '),
                  ),
                  if ((e['penyelenggara'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _infoRow(
                      Icons.people_rounded,
                      e['penyelenggara'].toString(),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Divider(color: Colors.white.withOpacity(0.1), height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Kategori chip
                      if ((e['kategori'] ?? '').toString().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            e['kategori'].toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white60,
                            ),
                          ),
                        ),
                      const Spacer(),
                      _tiketBadge(isFree ? 'Gratis' : 'Berbayar'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Idle state (belum ketik) ──────────────────────────────────
  Widget _buildIdleState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF2D336B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 38,
              color: Color(0xFF2D3561),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ketik untuk mencari event...',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF2D3561),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cari postingan atau event terbaru ',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),

          // Hint chips
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF2D336B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 38,
              color: Color(0xFF2D3561),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada hasil ditemukan',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF2D3561),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba kata kunci yang berbeda',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ── Widget helpers ────────────────────────────────────────────
  Widget _infoRow(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: Colors.white54),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _avatar(String profileImage) {
    ImageProvider img;
    if (profileImage.startsWith('data:image')) {
      img = MemoryImage(base64Decode(profileImage.split(',').last));
    } else if (profileImage.startsWith('http')) {
      img = NetworkImage(profileImage);
    } else {
      img = const AssetImage('assets/images/profilkosong.jpg');
    }
    return CircleAvatar(
      radius: 12,
      backgroundImage: img,
      backgroundColor: const Color(0xFF2D3561),
    );
  }

  Widget _tiketBadge(String? ticketType) {
    final isBerbayar = ticketType == 'Berbayar';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isBerbayar
            ? Colors.redAccent.withOpacity(0.15)
            : Colors.greenAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBerbayar
              ? Colors.redAccent.withOpacity(0.4)
              : Colors.greenAccent.withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBerbayar ? Icons.attach_money_rounded : Icons.money_off_rounded,
            size: 12,
            color: isBerbayar ? Colors.redAccent : Colors.greenAccent,
          ),
          const SizedBox(width: 2),
          Text(
            ticketType ?? 'Gratis',
            style: TextStyle(
              color: isBerbayar ? Colors.redAccent : Colors.greenAccent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.startsWith('data:image')) {
      return Image.memory(
        base64Decode(url.split(',').last),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imgFallback(),
      );
    }
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imgFallback(),
      );
    }
    if (url.isNotEmpty) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imgFallback(),
      );
    }
    return _imgFallback();
  }

  Widget _imgFallback() => Container(
    color: const Color(0xFF2D3561),
    child: const Center(
      child: Icon(Icons.image_rounded, color: Colors.white30, size: 36),
    ),
  );
}
