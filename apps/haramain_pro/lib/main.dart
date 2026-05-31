import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/constants.dart';
import 'design/design.dart';
import 'firebase/firebase_service.dart';
import 'features/map/map.dart';
import 'features/map/screens/map_screen_new.dart';
import 'features/panic/panic_history_screen.dart';
import 'features/panic/panic_alert_screen.dart';
import 'features/panic/panic_alert_screen_new.dart';
import 'features/panic/panic_service.dart';
import 'features/ibadah/screens/prayer_time_screen.dart';
import 'features/ibadah/screens/ibadah_mode_screen.dart';
import 'features/ibadah/screens/ibadah_screen_new.dart';
import 'features/ibadah/services/ibadah_mode_service.dart';
import 'features/ibadah/services/geofence_service.dart';
import 'features/ibadah/widgets/geofence_alert_dialog.dart';
import 'features/history/screens/history_screen_new.dart';
import 'features/virtual_muthawif/screens/chat_screen_new.dart';
import 'features/profile/screens/profile_screen_new.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/group/screens/join_group_screen.dart';
import 'features/group/screens/broadcast_screen.dart';
import 'features/album/album_gallery_screen.dart';
import 'features/camera/camera_screen.dart';
import 'models/user_model.dart';
import 'services/location_service.dart';
import 'supabase/supabase_client.dart' as app;

/// Validates that required environment variables are configured.
/// Throws [UnsupportedError] with a clear message if SUPABASE_URL or
/// SUPABASE_ANON_KEY are not set. Call this early in main() so failures
/// are fast and obvious instead of silent.
void _validateEnvironment() {
  // These getters throw UnsupportedError with a clear message if not configured.
  // We call them here so the app crashes immediately at startup, not later.
  try {
    SupabaseConstants.supabaseUrl;
  } on UnsupportedError catch (e) {
    // In debug mode, print a visible warning but allow the app to continue
    // so developers can see the UI even without a backend configured.
    // ignore: avoid_print
    print('FATAL: ${e.message}');
    if (!AppConstants.isDebug) rethrow;
  }

  try {
    SupabaseConstants.supabaseKey;
  } on UnsupportedError catch (e) {
    // ignore: avoid_print
    print('FATAL: ${e.message}');
    if (!AppConstants.isDebug) rethrow;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file — must happen before any code that reads env vars
  await dotenv.load(fileName: '.env');

  _validateEnvironment();

  await FirebaseService.instance.initialize();

  await app.SupabaseClientWrapper.instance.initialize(
    supabaseUrl: SupabaseConstants.supabaseUrl,
    supabaseKey: SupabaseConstants.supabaseKey,
  );

  runApp(const HaramainProApp());
}

class HaramainProApp extends StatefulWidget {
  const HaramainProApp({super.key});

  @override
  State<HaramainProApp> createState() => _HaramainProAppState();
}

class _HaramainProAppState extends State<HaramainProApp> {
  StreamSubscription? _geofenceSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _initializeIbadahMode();
  }

  void _setupAuthListener() {
    app.SupabaseClientWrapper.instance.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn) {
        print('User signed in: ${event.session!.user.email}');
      } else if (event.event == AuthChangeEvent.signedOut) {
        print('User signed out');
      }
    });
  }

  Future<void> _initializeIbadahMode() async {
    await IbadahModeService.instance.restoreState();

    _geofenceSubscription?.cancel();
    _geofenceSubscription = GeofenceService.instance.onGeofenceEvent.listen(
      (event) {
        if (event.event == GeofenceEvent.enter) {
          _showGeofenceEnterDialog(event);
        } else if (event.event == GeofenceEvent.exit) {
          _showGeofenceExitDialog(event);
        }
      },
    );
  }

  void _showGeofenceEnterDialog(GeofenceEventData event) async {
    final shouldShow = await IbadahModeService.instance.shouldShowGeofenceAlert();
    if (!shouldShow) return;

    if (IbadahModeService.instance.isEnabled) return;

    if (!mounted) return;
    final result = await GeofenceAlertDialog.show(context, event.mosque);
    if (result == true) {
      if (mounted) {
        Navigator.of(context).pushNamed('/ibadah/mode');
      }
    }
  }

  void _showGeofenceExitDialog(GeofenceEventData event) async {
    if (!IbadahModeService.instance.isEnabled) return;

    if (!mounted) return;
    await GeofenceExitDialog.show(context, event.mosque);
  }

  @override
  void dispose() {
    _geofenceSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: AppConstants.isDebug,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/panic-history': (context) => const PanicHistoryScreen(),
        '/map': (context) => const OfflineMapScreen(),
        '/map/download': (context) => const DownloadRegionScreen(),
        '/ibadah': (context) => const PrayerTimeScreen(),
        '/ibadah/mode': (context) => const IbadahModeScreen(),
        '/map-premium': (context) => const MapScreenPremium(),
        '/ibadah-premium': (context) => const IbadahScreenPremium(),
        '/history-premium': (context) => const HistoryScreenPremium(),
        '/chat-premium': (context) => const VirtualMuthawifScreenPremium(),
        '/profile-premium': (context) => const ProfileScreenPremium(),
        '/panic-alert-premium': (context) => const PanicAlertPremiumRoute(),
        '/onboarding': (context) => OnboardingScreen(onComplete: () {}),
        '/join-group': (context) => const JoinGroupScreen(
          userId: '',
          userName: '',
        ),
        '/broadcast': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final user = app.SupabaseClientWrapper.instance.currentUser;
          return BroadcastScreen(
            groupId: args?['groupId'] ?? '',
            groupName: args?['groupName'] ?? 'Group',
            currentUserId: user?.id ?? '',
            currentUserName: user?.email ?? 'User',
          );
        },
        '/album': (context) => const AlbumGalleryScreen(),
        '/camera': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return CameraScreen(groupId: args?['groupId']);
        },
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final args = settings.arguments as Map<String, dynamic>?;
          final profile = args?['profile'] as UserProfile?;
          return MaterialPageRoute(
            builder: (context) => HomeScreen(profile: profile),
          );
        }
        if (settings.name == '/panic-alert') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (context) => PanicAlertScreen(
                alert: args['alert'] as PanicAlert,
                responderId: args['responderId'] as String,
                onResponded: args['onResponded'] as VoidCallback?,
                onDismissed: args['onDismissed'] as VoidCallback?,
              ),
            );
          }
        }
        return null;
      },
    );
  }
}

class PanicAlertPremiumRoute extends StatelessWidget {
  const PanicAlertPremiumRoute({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final jamaaahId = args?['jamaaahId'] as String? ?? '';
    final grupId = args?['grupId'] as String? ?? '';
    return PanicAlertScreenPremium(
      jamaaahId: jamaaahId,
      grupId: grupId,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final session = app.SupabaseClientWrapper.instance.currentSession;

    if (session != null) {
      try {
        final profile = await _fetchUserProfile();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/home',
            arguments: {'profile': profile},
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  Future<UserProfile?> _fetchUserProfile() async {
    final user = app.SupabaseClientWrapper.instance.currentUser;
    if (user == null) return null;

    final response = await app.SupabaseClientWrapper.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response as Map<String, dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.backgroundDark, const Color(0xFF1A1A1A)]
                : [AppColors.surfaceLight, AppColors.backgroundLight],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.mosque,
                  size: 60,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                AppConstants.appName,
                style: AppTypography.headlineLarge.copyWith(
                  color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your Sacred Journey Companion',
                style: AppTypography.bodyMedium.copyWith(
                  color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                      .withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'v${AppConstants.appVersion}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await app.SupabaseClientWrapper.instance.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        final profile = await _fetchUserProfile();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/home',
            arguments: {'profile': profile},
          );
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = 'Login failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<UserProfile?> _fetchUserProfile() async {
    final user = app.SupabaseClientWrapper.instance.currentUser;
    if (user == null) return null;

    final response = await app.SupabaseClientWrapper.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response as Map<String, dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: const Icon(
                    Icons.mosque,
                    size: 40,
                    color: AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Welcome Back',
                style: AppTypography.headlineMedium.copyWith(
                  color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sign in to continue your sacred journey',
                style: AppTypography.bodyMedium.copyWith(
                  color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                      .withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _error!,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _signIn(),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryLight,
                          ),
                        )
                      : const Text('Sign In'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: AppTypography.bodyMedium.copyWith(
                      color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/register'),
                    child: const Text('Create Account'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter your name';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await app.SupabaseClientWrapper.instance.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        await app.SupabaseClientWrapper.instance.client.from('profiles').insert({
          'id': response.user!.id,
          'email': _emailController.text.trim(),
          'name': _nameController.text.trim(),
          'role': 'pilgrim',
        });

        if (mounted) {
          final profile = await _fetchUserProfile();
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(
              '/home',
              arguments: {'profile': profile},
            );
          }
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = 'Registration failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<UserProfile?> _fetchUserProfile() async {
    final user = app.SupabaseClientWrapper.instance.currentUser;
    if (user == null) return null;

    final response = await app.SupabaseClientWrapper.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response as Map<String, dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: const Icon(
                    Icons.person_add,
                    size: 40,
                    color: AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Create Account',
                style: AppTypography.headlineMedium.copyWith(
                  color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Start your sacred journey with us',
                style: AppTypography.bodyMedium.copyWith(
                  color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                      .withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _error!,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _signUp(),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryLight,
                          ),
                        )
                      : const Text('Create Account'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: AppTypography.bodyMedium.copyWith(
                      color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final UserProfile? profile;

  const HomeScreen({super.key, this.profile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LocationData? _currentLocation;
  bool _isLoadingLocation = true;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _getInitialLocation();
    _setupPanicAlertHandler();
  }

  Future<void> _getInitialLocation() async {
    final location = await LocationService.instance.getCurrentLocation();
    if (mounted) {
      setState(() {
        _currentLocation = location;
        _isLoadingLocation = false;
      });
    }
  }

  void _setupPanicAlertHandler() {
    FirebaseService.instance.registerPanicAlertHandler(_handleIncomingPanicAlert);
  }

  void _handleIncomingPanicAlert(dynamic message) {
    final data = message.data;
    if (data['type'] == 'panic_alert') {
      final alert = PanicAlert(
        id: data['alert_id'] ?? '',
        jamaaahId: data['jamaah_id'] ?? '',
        grupId: data['grup_id'] ?? '',
        latitude: double.tryParse(data['lat']?.toString() ?? '0') ?? 0,
        longitude: double.tryParse(data['lng']?.toString() ?? '0') ?? 0,
        timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
      );

      Navigator.of(context).pushNamed(
        '/panic-alert',
        arguments: {
          'alert': alert,
          'responderId': widget.profile?.id ?? '',
        },
      );
    }
  }

  @override
  void dispose() {
    FirebaseService.instance.unregisterPanicAlertHandler(_handleIncomingPanicAlert);
    super.dispose();
  }

  String get _userName => widget.profile?.name ?? 'User';
  String get _userRole => widget.profile?.role.toString().split('.').last ?? 'pilgrim';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final role = widget.profile?.role ?? UserRole.pilgrim;

    return Scaffold(
      body: _buildHomeContent(role, isDark),
      bottomNavigationBar: _buildPremiumBottomNav(isDark),
    );
  }

  Widget _buildHomeContent(UserRole role, bool isDark) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(isDark),
          ),
          SliverToBoxAdapter(
            child: _buildLocationCard(isDark),
          ),
          SliverToBoxAdapter(
            child: _buildPanicSection(isDark),
          ),
          SliverToBoxAdapter(
            child: _buildQuickActions(role, isDark),
          ),
          SliverToBoxAdapter(
            child: _buildRoleContent(role, isDark),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 2),
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            ),
            child: Center(
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assalamu\'alaikum',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _userName,
                  style: AppTypography.titleLarge.copyWith(
                    color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _userRole.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                        .withValues(alpha: 0.6),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showProfileMenu(),
            icon: Icon(
              Icons.more_vert,
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1A1A), const Color(0xFF0D0D0D)]
              : [AppColors.surfaceLight, AppColors.backgroundLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              Icons.location_on,
              color: AppColors.gold,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lokasi Saat Ini',
                  style: AppTypography.labelSmall.copyWith(
                    color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                        .withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                if (_isLoadingLocation)
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mendapatkan lokasi...',
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                        ),
                      ),
                    ],
                  )
                else if (_currentLocation != null)
                  Text(
                    _getLocationName(),
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Text(
                    'Lokasi tidak tersedia',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: _currentLocation != null
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _currentLocation != null ? Icons.check_circle : Icons.error,
                  size: 14,
                  color: _currentLocation != null ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  _currentLocation != null ? 'Aktif' : 'Offline',
                  style: AppTypography.labelSmall.copyWith(
                    color: _currentLocation != null ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLocationName() {
    if (_currentLocation == null) return 'Unknown';
    final lat = _currentLocation!.latitude;
    final lng = _currentLocation!.longitude;

    if (lat >= 21.4 && lat <= 24.5 && lng >= 39.5 && lng <= 39.8) {
      return 'Masjidil Haram, Makkah';
    } else if (lat >= 24.4 && lat <= 24.6 && lng >= 39.6 && lng <= 39.7) {
      return 'Masjid Nabawi, Madinah';
    }
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  Widget _buildPanicSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keselamatan Anda',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: () => _triggerPanic(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.lg,
                horizontal: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.error.withValues(alpha: 0.9),
                    AppColors.error,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PANIC BUTTON',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tekan jika dalam keadaan darurat',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 24,
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

  Widget _buildQuickActions(UserRole role, bool isDark) {
    final actions = _getQuickActionsForRole(role);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aksi Cepat',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            children: actions,
          ),
        ],
      ),
    );
  }

  List<Widget> _getQuickActionsForRole(UserRole role) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final commonActions = [
      _buildQuickActionItem(
        icon: Icons.map_outlined,
        label: 'Peta',
        color: AppColors.gold,
        isDark: isDark,
        onTap: () => _handleNavTap(1),
      ),
      _buildQuickActionItem(
        icon: Icons.schedule,
        label: 'Ibadah',
        color: AppColors.gold,
        isDark: isDark,
        onTap: () => _handleNavTap(2),
      ),
      _buildQuickActionItem(
        icon: Icons.chat_outlined,
        label: 'Muthawif',
        color: AppColors.gold,
        isDark: isDark,
        onTap: () => _openVirtualMuthawif(),
      ),
      _buildQuickActionItem(
        icon: Icons.person_outline,
        label: 'Profile',
        color: AppColors.gold,
        isDark: isDark,
        onTap: () => _openProfile(),
      ),
    ];

    if (role == UserRole.pilgrim) {
      return commonActions;
    }

    return [
      ...commonActions,
      _buildQuickActionItem(
        icon: Icons.people_outlined,
        label: 'Jamaah',
        color: AppColors.gold,
        isDark: isDark,
        onTap: () {},
      ),
      _buildQuickActionItem(
        icon: Icons.analytics_outlined,
        label: 'Statistik',
        color: AppColors.gold,
        isDark: isDark,
        onTap: () {},
      ),
      _buildQuickActionItem(
        icon: Icons.settings_outlined,
        label: 'Pengaturan',
        color: AppColors.gold,
        isDark: isDark,
        onTap: () {},
      ),
      _buildQuickActionItem(
        icon: Icons.help_outline,
        label: 'Bantuan',
        color: AppColors.gold,
        isDark: isDark,
        onTap: () {},
      ),
    ];
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleContent(UserRole role, bool isDark) {
    switch (role) {
      case UserRole.pilgrim:
        return _buildPilgrimContent(isDark);
      case UserRole.muthawif:
        return _buildMuthawifContent(isDark);
      case UserRole.agency:
        return _buildAgencyContent(isDark);
      case UserRole.admin:
        return _buildAdminContent(isDark);
    }
  }

  Widget _buildPilgrimContent(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tips_and_updates_outlined,
                color: AppColors.gold,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Tips Ibadah',
                style: AppTypography.titleSmall.copyWith(
                  color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tetap hydratasi saat berada di Masjidil Haram. Bawa botol air sendiri dan hindari berdiri terlalu lama di bawah terik matahari.',
            style: AppTypography.bodySmall.copyWith(
              color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                  .withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuthawifContent(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rombongan Aktif',
                style: AppTypography.titleSmall.copyWith(
                  color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  '3 Jamaah',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildJamaahItem('Ahmad bin Ibrahim', 'Makkah', true, isDark),
          const Divider(height: AppSpacing.md),
          _buildJamaahItem('Sarah binti Yusuf', 'Madinah', true, isDark),
          const Divider(height: AppSpacing.md),
          _buildJamaahItem('Muhammad Ali', 'Makkah', false, isDark),
        ],
      ),
    );
  }

  Widget _buildJamaahItem(String name, String location, bool isActive, bool isDark) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.gold.withValues(alpha: 0.1),
          ),
          child: Center(
            child: Text(
              name[0],
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                location,
                style: AppTypography.bodySmall.copyWith(
                  color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.success : AppColors.dividerLight,
          ),
        ),
      ],
    );
  }

  Widget _buildAgencyContent(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik Agen',
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Total Jamaah', '48', AppColors.gold, isDark),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildStatCard('Aktif', '32', AppColors.success, isDark),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildStatCard('Alerts', '2', AppColors.error, isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.headlineSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                  .withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminContent(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Overview',
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildAdminStatRow('Total Users', '1,248', isDark),
          _buildAdminStatRow('Active Sessions', '456', isDark),
          _buildAdminStatRow('Panic Alerts Today', '3', isDark),
          _buildAdminStatRow('System Health', 'Operational', isDark),
        ],
      ),
    );
  }

  Widget _buildAdminStatRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                  .withValues(alpha: 0.8),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home', isDark),
              _buildNavItem(1, Icons.map_rounded, 'Map', isDark),
              _buildNavItem(2, Icons.schedule_rounded, 'Ibadah', isDark),
              _buildNavItem(3, Icons.history_rounded, 'History', isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _selectedNavIndex == index;
    final color = isSelected ? AppColors.gold : (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight);

    return GestureDetector(
      onTap: () => _handleNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleNavTap(int index) async {
    if (_selectedNavIndex == index && index == 0) return;

    setState(() => _selectedNavIndex = index);

    if (index == 0) return;

    final route = switch (index) {
      1 => '/map-premium',
      2 => '/ibadah-premium',
      3 => '/history-premium',
      _ => null,
    };

    if (route == null) {
      setState(() => _selectedNavIndex = 0);
      return;
    }

    await Navigator.of(context).pushNamed(route);
    if (mounted) {
      setState(() => _selectedNavIndex = 0);
    }
  }

  void _triggerPanic() {
    if (widget.profile != null) {
      Navigator.of(context).pushNamed(
        '/panic-alert-premium',
        arguments: {
          'jamaaahId': widget.profile!.id,
          'grupId': '',
        },
      );
    }
  }

  void _showProfileMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppColors.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: AppColors.gold),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: AppColors.gold),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Logout', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                await app.SupabaseClientWrapper.instance.auth.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _openVirtualMuthawif() {
    Navigator.of(context).pushNamed('/chat-premium');
  }

  void _openProfile() {
    Navigator.of(context).pushNamed('/profile-premium');
  }
}
