import 'package:flutter/material.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../design/tokens/app_typography.dart';
import '../../../design/tokens/app_spacing.dart';

/// Onboarding flow as per FRONTEND-SPEC.md Section 4.1
/// Screen 1: Welcome + value prop
/// Screen 2: How Panic Button works
/// Screen 3: Offline map preview
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextButton(
                  onPressed: widget.onComplete,
                  child: Text(
                    'Lewati',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.slate600,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: const [
                  _WelcomePage(),
                  _PanicButtonPage(),
                  _OfflineMapPage(),
                ],
              ),
            ),

            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.emerald700
                        : AppColors.slate300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Next button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage == 2 ? 'Mulai' : 'Lanjut',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.mosque,
              size: 60,
              color: AppColors.gold,
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          Text(
            'Haramain Pro',
            style: AppTypography.displayMedium.copyWith(
              color: AppColors.emerald900,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'Companion Perjalanan Suci Anda',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.slate600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Features list
          _FeatureItem(
            icon: Icons.location_on,
            title: 'Navigasi Luring',
            description: 'Peta offline tanpa perlu internet',
          ),
          const SizedBox(height: AppSpacing.md),
          _FeatureItem(
            icon: Icons.emergency,
            title: 'Panic Button',
            description: 'Bantuan satu sentuhan',
          ),
          const SizedBox(height: AppSpacing.md),
          _FeatureItem(
            icon: Icons.group,
            title: 'Grup & Jamaah',
            description: 'Terhubung dengan muthawif Anda',
          ),
        ],
      ),
    );
  }
}

class _PanicButtonPage extends StatelessWidget {
  const _PanicButtonPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Panic button illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.red600,
              boxShadow: [
                BoxShadow(
                  color: AppColors.red600.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.emergency,
              size: 60,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          Text(
            'Panic Button',
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.emerald900,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'Kirim alert darurat ke muthawif Anda\ndalam satu sentuhan',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.slate600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Steps
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.emerald100,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              children: [
                _StepItem(number: '1', text: 'Tekan tombol panic'),
                const SizedBox(height: AppSpacing.sm),
                _StepItem(number: '2', text: 'Konfirmasi dalam 5 detik'),
                const SizedBox(height: AppSpacing.sm),
                _StepItem(number: '3', text: 'Muthawif akan dimintai bantuan'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineMapPage extends StatelessWidget {
  const _OfflineMapPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Map illustration
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.darkNavy,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Map grid pattern
                CustomPaint(
                  size: const Size(double.infinity, 200),
                  painter: _MapGridPainter(),
                ),
                // POI markers
                const Positioned(
                  left: 40,
                  top: 60,
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.amber500,
                    size: 32,
                  ),
                ),
                const Positioned(
                  right: 60,
                  top: 40,
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.amber500,
                    size: 28,
                  ),
                ),
                const Positioned(
                  left: 100,
                  bottom: 50,
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.amber500,
                    size: 24,
                  ),
                ),
                // Current location
                const Positioned(
                  right: 40,
                  bottom: 60,
                  child: Icon(
                    Icons.my_location,
                    color: AppColors.emerald500,
                    size: 36,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          Text(
            'Peta Luring',
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.emerald900,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'Navigasi tanpa internet\nTersedia untuk area Masjidil Haram & Masjid Nabawi',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.slate600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xl),

          // POI legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: AppColors.amber500, label: 'Lokasi Suci'),
              const SizedBox(width: AppSpacing.lg),
              _LegendItem(color: AppColors.emerald500, label: 'Posisi Anda'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.emerald100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.emerald700, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.slate900,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.slate600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String text;

  const _StepItem({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.emerald700,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          text,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.emerald900,
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.slate600,
          ),
        ),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.slate700.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    // Draw grid lines
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
