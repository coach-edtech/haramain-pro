import 'package:flutter/material.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../design/tokens/app_typography.dart';
import '../../../design/tokens/app_spacing.dart';

/// Album Gallery screen for viewing photos
/// As per FRONTEND-SPEC.md Section 4.7
class AlbumGalleryScreen extends StatefulWidget {
  final String? groupId;

  const AlbumGalleryScreen({
    super.key,
    this.groupId,
  });

  @override
  State<AlbumGalleryScreen> createState() => _AlbumGalleryScreenState();
}

class _AlbumGalleryScreenState extends State<AlbumGalleryScreen> {
  // Placeholder data - would come from actual photo service
  final List<Map<String, dynamic>> _photos = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: AppColors.emerald900,
        foregroundColor: Colors.white,
        title: Text(
          'Album Foto',
          style: AppTypography.titleLarge.copyWith(color: Colors.white),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            onPressed: () {
              // Navigate to camera
              Navigator.pushNamed(context, '/camera');
            },
          ),
        ],
      ),
      body: _photos.isEmpty ? _buildEmptyState() : _buildPhotoGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.emerald100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                size: 40,
                color: AppColors.emerald700,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Belum Ada Foto',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.slate900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Foto ibadah Anda akan muncul di sini setelah Anda mulai mengambil foto dengan fitur Jejak Ibadah.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.slate600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/camera');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              icon: const Icon(Icons.camera_alt),
              label: Text(
                'Buka Kamera',
                style: AppTypography.labelLarge.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        return GestureDetector(
          onTap: () => _openPhotoViewer(index),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.slate200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.image,
              color: AppColors.slate400,
            ),
          ),
        );
      },
    );
  }

  void _openPhotoViewer(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PhotoViewerScreen(
          photos: _photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

/// Full screen photo viewer
class _PhotoViewerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> photos;
  final int initialIndex;

  const _PhotoViewerScreen({
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<_PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<_PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.photos.length}',
          style: AppTypography.titleSmall.copyWith(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final photo = widget.photos[index];
          return Stack(
            fit: StackFit.expand,
            children: [
              // Photo
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Container(
                  color: AppColors.slate800,
                  child: const Center(
                    child: Icon(
                      Icons.image,
                      size: 100,
                      color: AppColors.slate400,
                    ),
                  ),
                ),
              ),
              
              // Photo info at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (photo['title'] != null)
                        Text(
                          photo['title'],
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      if (photo['date'] != null)
                        Text(
                          photo['date'],
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.slate300,
                          ),
                        ),
                      if (photo['location'] != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppColors.amber500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              photo['location'],
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.amber500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
