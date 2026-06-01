import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'post_event_page.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:jurnal_jatim_carnival/pages/post_event_page.dart';
import 'dart:typed_data';
import 'package:video_thumbnail/video_thumbnail.dart';

class MediaItem {
  final File file;
  final bool isVideo;
  VideoPlayerController? videoController;

  MediaItem({required this.file, required this.isVideo, this.videoController});
}

class SelectPhotoPage extends StatefulWidget {
  const SelectPhotoPage({super.key});

  @override
  State<SelectPhotoPage> createState() => _SelectPhotoPageState();
}

class _SelectPhotoPageState extends State<SelectPhotoPage> {
  List<MediaItem> _mediaItems = [];
  int _currentPage = 0;
  final PageController _pageController = PageController();
  Map<int, Uint8List?> _videoThumbnails = {};

  @override
  void dispose() {
    for (var item in _mediaItems) {
      item.videoController?.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia({bool videoOnly = false}) async {
    final picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultipleMedia();

    if (pickedFiles.isEmpty) return;

    final List<MediaItem> newItems = [];

    for (final file in pickedFiles) {
      final isVideo =
          file.path.endsWith('.mp4') ||
          file.path.endsWith('.mov') ||
          file.path.endsWith('.avi') ||
          file.path.endsWith('.mkv') ||
          file.mimeType?.startsWith('video/') == true;

      if (videoOnly && !isVideo) continue; // ✅ skip foto kalau mode video

      if (isVideo) {
        final controller = VideoPlayerController.file(File(file.path));
        await controller.initialize();
        controller.setLooping(true);
        controller.play();
        newItems.add(
          MediaItem(
            file: File(file.path),
            isVideo: true,
            videoController: controller,
          ),
        );
      } else {
        newItems.add(MediaItem(file: File(file.path), isVideo: false));
      }
    }

    setState(() => _mediaItems.addAll(newItems));
  }

  Future<void> _replaceMedia(int index) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2D3561),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _mediaItems[index].videoController?.dispose();
                setState(() {
                  _mediaItems.removeAt(index);
                  if (_currentPage >= _mediaItems.length && _currentPage > 0) {
                    _currentPage = _mediaItems.length - 1;
                  }
                });
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    // ✅ kirim MediaItemData langsung dengan urutan asli
    final mediaItems = _mediaItems
        .map(
          (m) => MediaItemData(
            file: m.file,
            isVideo: m.isVideo,
            videoController: m.videoController,
          ),
        )
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostEventPage(mediaItems: mediaItems)),
    );
  }

  Widget _buildMediaPreview(MediaItem item, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Media content
        item.isVideo
            ? (item.videoController != null &&
                      item.videoController!.value.isInitialized
                  ? GestureDetector(
                      onTap: () {
                        setState(() {
                          item.videoController!.value.isPlaying
                              ? item.videoController!.pause()
                              : item.videoController!.play();
                        });
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: item.videoController!.value.size.width,
                              height: item.videoController!.value.size.height,
                              child: VideoPlayer(item.videoController!),
                            ),
                          ),
                          if (!item.videoController!.value.isPlaying)
                            const Center(
                              child: Icon(
                                Icons.play_circle_fill,
                                color: Colors.white70,
                                size: 60,
                              ),
                            ),
                        ],
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ))
            : Image.file(
                item.file,
                fit: BoxFit.contain,
                width: double.infinity,
              ),

        // Video progress
        if (item.isVideo && item.videoController != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 12,
            child: VideoProgressIndicator(
              item.videoController!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Color(0xFF6C7FD8),
                backgroundColor: Colors.white24,
              ),
            ),
          ),

        // Dot indicator
        // Dot indicator
        if (_mediaItems.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _mediaItems.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == i ? 16 : 6,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _generateThumbnail(int index) async {
    if (_videoThumbnails.containsKey(index)) return;
    final item = _mediaItems[index];
    if (!item.isVideo) return;

    final thumbnail = await VideoThumbnail.thumbnailData(
      video: item.file.path,
      imageFormat: ImageFormat.JPEG,
      quality: 75,
    );

    if (mounted) {
      setState(() => _videoThumbnails[index] = thumbnail);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF6F2),
        elevation: 0,
        title: const Text(
          "Postingan Baru",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
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
        actions: [
          if (_mediaItems.isNotEmpty)
            TextButton(
              onPressed: _pickMedia,
              child: const Text(
                '+ Tambah',
                style: TextStyle(color: Color(0xFF6C7FD8)),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Preview area
            // Preview area
            GestureDetector(
              onTap: _mediaItems.isEmpty ? _pickMedia : null,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3561).withOpacity(0.08),
                ),
                child: _mediaItems.isEmpty
                    ? AspectRatio(
                        aspectRatio: 3 / 4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.perm_media_outlined,
                              size: 60,
                              color: const Color(0xFF6C7FD8).withOpacity(0.6),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Ketuk untuk pilih foto/video",
                              style: TextStyle(
                                color: const Color(0xFF2D3561).withOpacity(0.5),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Bisa pilih lebih dari 1",
                              style: TextStyle(
                                color: Color(0xFF2D3561),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 600, minHeight: 400,),
                        child: Stack(
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              itemCount: _mediaItems.length,
                              physics: const BouncingScrollPhysics(),
                              clipBehavior: Clip.none,
                              onPageChanged: (index) {
                                setState(() => _currentPage = index);
                              },
                              itemBuilder: (context, index) {
                                return _buildMediaPreview(
                                  _mediaItems[index],
                                  index,
                                );
                              },
                            ),

                            // Tombol hapus
                            Positioned(
                              top: 12,
                              right: 12,
                              child: GestureDetector(
                                onTap: () {
                                  _mediaItems[_currentPage].videoController
                                      ?.dispose();
                                  setState(() {
                                    _mediaItems.removeAt(_currentPage);
                                    if (_currentPage >= _mediaItems.length &&
                                        _currentPage > 0) {
                                      _currentPage = _mediaItems.length - 1;
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2D3561),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFFFF6F2),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),

                            // Dot indicator
                            if (_mediaItems.length > 1)
                              Positioned(
                                bottom: 16,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(_mediaItems.length, (
                                    i,
                                  ) {
                                    final isActive = _currentPage == i;
                                    return AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      width: isActive ? 20 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? const Color(0xFFFFF6F2)
                                            : Colors.white.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: isActive
                                            ? [
                                                BoxShadow(
                                                  color: Colors.white
                                                      .withOpacity(0.4),
                                                  blurRadius: 4,
                                                  spreadRadius: 1,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    );
                                  }),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Thumbnail list
            if (_mediaItems.isNotEmpty)
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _mediaItems.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _mediaItems.length) {
                      return GestureDetector(
                        onTap: _pickMedia,
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF6C7FD8).withOpacity(0.4),
                              width: 1.5,
                            ),
                            color: const Color(0xFF2D3561).withOpacity(0.06),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Color(0xFF6C7FD8),
                            size: 28,
                          ),
                        ),
                      );
                    }
                    final item = _mediaItems[index];
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _currentPage == index
                                ? const Color(0xFF6C7FD8)
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              item.isVideo
                                  ? FutureBuilder(
                                      future: _generateThumbnail(index),
                                      builder: (context, _) {
                                        final thumb = _videoThumbnails[index];
                                        return thumb != null
                                            ? Image.memory(
                                                thumb,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                color: Colors.black,
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.videocam,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                              );
                                      },
                                    )
                                  : Image.file(item.file, fit: BoxFit.cover),
                              if (item.isVideo)
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: const Icon(
                                    Icons.videocam,
                                    color: Color(0xFFFFF6F2),
                                    size: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const Spacer(),

            SizedBox(
              width: 400,
              height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2D3561),
                  foregroundColor: Color(0xFFFFF6F2),
                ),

                onPressed: () {
                  if (_mediaItems.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        backgroundColor: const Color(0xFF2D3561),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: const BorderSide(
                            color: Color(0xFF6C7FD8),
                            width: 1,
                          ),
                        ),
                        content: const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFF6C7FD8),
                              size: 22,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Pilih foto atau video terlebih dahulu!',
                                style: TextStyle(
                                  color: Color(0xFFFFF6F2),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                    return;
                  }
                  _nextStep();
                },

                child: const Text(
                  "Selanjutnya",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 55),
          ],
        ),
      ),
    );
  }
}
