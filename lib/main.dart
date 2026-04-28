import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

String resolveApiBaseUrl() {
  const String fromDefine = String.fromEnvironment('API_BASE_URL');
  final String normalized = fromDefine.trim();
  if (normalized.isNotEmpty) {
    return normalized;
  }

  if (kIsWeb) {
    return 'http://localhost:4000';
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'http://192.168.1.21:4000';
    default:
      return 'http://localhost:4000';
  }
}

Uri buildApiUri(String path, {Map<String, String>? queryParameters}) {
  final Uri base = Uri.parse(resolveApiBaseUrl());
  final String normalizedPath = path.startsWith('/') ? path : '/$path';
  final Uri resolved = base.replace(path: normalizedPath);
  if (queryParameters == null) {
    return resolved;
  }

  return resolved.replace(queryParameters: queryParameters);
}

const Color _appBackgroundColor = Color(0xFFF5F1EA);
const Color _surfaceColor = Color(0xFFFFFFFF);
const Color _surfaceTintColor = Color(0xFFF8FBFE);
const Color _primaryColor = Color(0xFF1E4F70);
const Color _primarySoftColor = Color(0xFF5F86A0);
const Color _accentColor = Color(0xFFE6784E);
const Color _accentSoftColor = Color(0xFFF6C8B6);
const Color _textColor = Color(0xFF16212B);
const Color _mutedTextColor = Color(0xFF60707E);
const Color _lineColor = Color(0xFFD8E2EA);

// Set to true to skip all backend HTTP calls and use fallback/mock data.
// Flip back to false when ready to connect the real backend.
const bool kOfflineMode = true;

const AppUser _kMockUser = AppUser(
  name: 'Dev User',
  email: 'dev@local',
  username: 'devuser',
);

void main() {
  runApp(const OrchidApp());
}

class OrchidApp extends StatefulWidget {
  const OrchidApp({super.key});

  @override
  State<OrchidApp> createState() => _OrchidAppState();
}

class _OrchidAppState extends State<OrchidApp> {
  final AppAuthController _authController = AppAuthController();

  @override
  void initState() {
    super.initState();
    _authController.initialize();
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme =
        ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.light,
        ).copyWith(
          primary: _primaryColor,
          secondary: _accentColor,
          surface: _surfaceColor,
          onSurface: _textColor,
          tertiary: _primarySoftColor,
        );
    final TextTheme baseTextTheme = ThemeData.light().textTheme;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BLOOM',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: _appBackgroundColor,
        visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        cardTheme: CardThemeData(
          color: _surfaceColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: _lineColor, width: 1),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: _textColor,
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
        ),
        dividerTheme: const DividerThemeData(
          color: _lineColor,
          space: 1,
          thickness: 1,
        ),
        textTheme: baseTextTheme.copyWith(
          headlineSmall: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
          titleLarge: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
          bodyLarge: const TextStyle(fontSize: 14, color: _textColor),
          bodyMedium: const TextStyle(fontSize: 13, color: _textColor),
          bodySmall: const TextStyle(fontSize: 12, color: _mutedTextColor),
          labelLarge: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          filled: true,
          fillColor: _surfaceColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _lineColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _primaryColor, width: 1.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 1,
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryColor,
            side: const BorderSide(color: _primaryColor, width: 1.3),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _primaryColor,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _textColor,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: const TextScaler.linear(0.92)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: AnimatedBuilder(
        animation: _authController,
        builder: (context, _) {
          if (_authController.isInitializing) {
            return const SplashScreen();
          }

          if (_authController.user != null) {
            return AuthenticatedShell(
              authController: _authController,
              initialTabIndex: 1,
            );
          }

          return WelcomeScreen(authController: _authController);
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({required this.authController, super.key});

  final AppAuthController authController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('🌺', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 16),
                const Text(
                  'BLOOM',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Orchid Conservation System',
                  style: TextStyle(fontSize: 18, color: _mutedTextColor),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mt. Busa Orchidaceae Information & Mapping',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: _mutedTextColor),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    LoginScreen(authController: authController),
                              ),
                            );
                          },
                          child: const Text('Login'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SignUpScreen(
                                  authController: authController,
                                ),
                              ),
                            );
                          },
                          child: const Text('Sign Up'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.authController, super.key});

  final AppAuthController authController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.authController.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => AuthenticatedShell(
            authController: widget.authController,
            initialTabIndex: 0,
          ),
        ),
        (route) => false,
      );
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to login right now.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(_isSubmitting ? 'Please wait...' : 'Continue'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SignUpScreen(
                            authController: widget.authController,
                          ),
                        ),
                      );
                    },
                    child: const Text('Create account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({required this.authController, super.key});

  final AppAuthController authController;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.authController.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => AuthenticatedShell(
            authController: widget.authController,
            initialTabIndex: 0,
          ),
        ),
        (route) => false,
      );
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to create account right now.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(controller: _nameController, hintText: 'Name'),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(
                      _isSubmitting ? 'Please wait...' : 'Create account',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LoginScreen(
                            authController: widget.authController,
                          ),
                        ),
                      );
                    },
                    child: const Text('Already have an account? Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(hintText: hintText),
    );
  }
}

class AuthenticatedShell extends StatefulWidget {
  const AuthenticatedShell({
    required this.authController,
    required this.initialTabIndex,
    super.key,
  });

  final AppAuthController authController;
  final int initialTabIndex;

  @override
  State<AuthenticatedShell> createState() => _AuthenticatedShellState();
}

class _AuthenticatedShellState extends State<AuthenticatedShell> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(authController: widget.authController),
      CatalogScreen(authController: widget.authController),
      UploadScreen(authController: widget.authController),
      MapScreen(authController: widget.authController),
      const NotificationsScreen(),
    ];

    final List<IconData> selectedIcons = [
      Icons.home_rounded,
      Icons.library_books_rounded,
      Icons.add_box_rounded,
      Icons.map_rounded,
      Icons.notifications_rounded,
    ];

    final List<IconData> unselectedIcons = [
      Icons.home_outlined,
      Icons.library_books_outlined,
      Icons.add_box_outlined,
      Icons.map_outlined,
      Icons.notifications_none_rounded,
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          border: Border(top: BorderSide(color: _lineColor)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List<Widget>.generate(5, (index) {
              final bool isSelected = index == _selectedIndex;
              return InkResponse(
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                radius: 24,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  scale: isSelected ? 1.08 : 1,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _primaryColor.withAlpha(20)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSelected
                          ? selectedIcons[index]
                          : unselectedIcons[index],
                      color: isSelected ? _primaryColor : _mutedTextColor,
                      size: isSelected ? 31 : 29,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.authController, super.key});

  final AppAuthController authController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboardData();
  }

  int _toInt(dynamic value, int fallback) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse((value ?? '').toString()) ?? fallback;
  }

  Future<_HomeDashboardData> _loadDashboardData() async {
    if (kOfflineMode) return const _HomeDashboardData.fallback();
    final http.Client client = http.Client();
    try {
      final http.Response response = await client
          .get(buildApiUri('/api/species/summary'))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const _HomeDashboardData.fallback();
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return const _HomeDashboardData.fallback();
      }

      final Map<String, dynamic> payload = Map<String, dynamic>.from(decoded);
      final Map<String, dynamic>? latestSpecies =
          payload['latestSpecies'] is Map
          ? Map<String, dynamic>.from(payload['latestSpecies'] as Map)
          : null;

      final AppStats liveStats = AppStats(
        totalSpecies: _toInt(
          payload['totalSpecies'],
          defaultAppStats.totalSpecies,
        ),
        pendingSubmissions: _toInt(
          payload['pendingSubmissions'],
          defaultAppStats.pendingSubmissions,
        ),
        totalSightings: _toInt(
          payload['totalSightings'],
          defaultAppStats.totalSightings,
        ),
      );

      final SpeciesHighlight liveHighlight = SpeciesHighlight(
        scientificName:
            (latestSpecies?['scientificName'] ??
                    defaultSpeciesOfTheDay.scientificName)
                .toString(),
        commonName:
            (latestSpecies?['commonName'] ?? defaultSpeciesOfTheDay.commonName)
                .toString(),
        imageUrl:
            (latestSpecies?['imageUrl'] ?? defaultSpeciesOfTheDay.imageUrl)
                .toString(),
      );

      return _HomeDashboardData(
        stats: liveStats,
        speciesOfTheDay: liveHighlight,
        isFallback: false,
      );
    } catch (_) {
      return const _HomeDashboardData.fallback();
    } finally {
      client.close();
    }
  }

  Future<void> _openProfilePanel(BuildContext context) async {
    final String profileName =
        widget.authController.user?.name.trim().isNotEmpty == true
        ? widget.authController.user!.name
        : 'Researcher 1';
    final String handleSource =
        widget.authController.user?.email.trim().isNotEmpty == true
        ? widget.authController.user!.email.split('@').first
        : profileName;
    final String normalizedHandle = handleSource.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    final String profileHandle = normalizedHandle.isNotEmpty
        ? '@$normalizedHandle'
        : '@researcher1';

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close profile menu',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, _, _) {
        return _ProfileOverlayPanel(
          authController: widget.authController,
          profileName: profileName,
          profileHandle: profileHandle,
        );
      },
      transitionBuilder: (_, animation, _, child) {
        final Animation<Offset> slide =
            Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        return SlideTransition(position: slide, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String greetingName =
        widget.authController.user?.name.trim().isNotEmpty == true
        ? widget.authController.user!.name
        : 'Researcher';

    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: SafeArea(
        child: FutureBuilder<_HomeDashboardData>(
          future: _dashboardFuture,
          builder:
              (
                BuildContext context,
                AsyncSnapshot<_HomeDashboardData> snapshot,
              ) {
                final _HomeDashboardData dashboard =
                    snapshot.data ?? const _HomeDashboardData.fallback();
                final AppStats liveStats = dashboard.stats;
                final SpeciesHighlight liveHighlight =
                    dashboard.speciesOfTheDay;

                return LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double heightScale = constraints.maxHeight / 900;
                    final double widthScale = constraints.maxWidth / 390;
                    final double adaptiveScale = heightScale < widthScale
                        ? heightScale
                        : widthScale;
                    final double scale = adaptiveScale.clamp(0.5, 1.0);
                    final double imageSize = 180 * scale;
                    final double statsWidth = (constraints.maxWidth * 0.9)
                        .clamp(260.0, 300.0);

                    return TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 520),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(begin: 0, end: 1),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          12 * scale,
                          20,
                          12 * scale,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Material(
                                color: Colors.transparent,
                                child: InkResponse(
                                  onTap: () => _openProfilePanel(context),
                                  radius: 28 * scale,
                                  child: Container(
                                    width: 40 * scale,
                                    height: 40 * scale,
                                    decoration: const BoxDecoration(
                                      color: _primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.sentiment_satisfied_alt_rounded,
                                      color: Colors.white,
                                      size: 24 * scale,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 26 * scale),
                            Text(
                              'Hello, $greetingName!',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 34 * scale,
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.italic,
                                color: _textColor,
                                letterSpacing: -0.8 * scale,
                              ),
                            ),
                            SizedBox(height: 14 * scale),
                            Text(
                              'Species of the day',
                              style: TextStyle(
                                fontSize: 17 * scale,
                                fontStyle: FontStyle.italic,
                                color: _mutedTextColor,
                              ),
                            ),
                            SizedBox(height: 10 * scale),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => CatalogSpeciesDetailsScreen(
                                      species: CatalogSpecies(
                                        scientificName:
                                            liveHighlight.scientificName,
                                        commonName: liveHighlight.commonName,
                                        imageUrl: liveHighlight.imageUrl,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22 * scale),
                                child: Image.network(
                                  liveHighlight.imageUrl,
                                  width: imageSize,
                                  height: imageSize,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (
                                        BuildContext context,
                                        Object error,
                                        StackTrace? stackTrace,
                                      ) {
                                        return Container(
                                          width: imageSize,
                                          height: imageSize,
                                          color: _surfaceTintColor,
                                          alignment: Alignment.center,
                                          child: Text(
                                            '🌸',
                                            style: TextStyle(
                                              fontSize: 74 * scale,
                                            ),
                                          ),
                                        );
                                      },
                                ),
                              ),
                            ),
                            SizedBox(height: 14 * scale),
                            Text(
                              liveHighlight.scientificName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 30 * scale,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                                color: _accentColor,
                                decoration: TextDecoration.underline,
                                decorationColor: _accentColor,
                              ),
                            ),
                            SizedBox(height: 4 * scale),
                            Text(
                              'Tap the image to learn more!',
                              style: TextStyle(
                                fontSize: 13 * scale,
                                fontStyle: FontStyle.italic,
                                color: _mutedTextColor,
                              ),
                            ),
                            SizedBox(height: 20 * scale),
                            Text(
                              'Bloom Update!',
                              style: TextStyle(
                                fontSize: 28 * scale,
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.italic,
                                color: _textColor,
                                letterSpacing: -0.4 * scale,
                              ),
                            ),
                            SizedBox(height: 2 * scale),
                            Text(
                              dashboard.isFallback
                                  ? 'snapshot fallback data'
                                  : 'live backend data',
                              style: TextStyle(
                                fontSize: 16 * scale,
                                fontStyle: FontStyle.italic,
                                color: _mutedTextColor,
                              ),
                            ),
                            if (snapshot.connectionState ==
                                ConnectionState.waiting)
                              Padding(
                                padding: EdgeInsets.only(top: 4 * scale),
                                child: const SizedBox(
                                  width: 120,
                                  child: LinearProgressIndicator(minHeight: 2),
                                ),
                              ),
                            SizedBox(height: 8 * scale),
                            Text(
                              liveStats.totalSpecies.toString(),
                              style: TextStyle(
                                fontSize: 82 * scale,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.italic,
                                color: _primaryColor,
                                letterSpacing: -2 * scale,
                              ),
                            ),
                            Text(
                              'species recorded',
                              style: TextStyle(
                                fontSize: 19 * scale,
                                fontStyle: FontStyle.italic,
                                color: _textColor,
                              ),
                            ),
                            SizedBox(height: 18 * scale),
                            Container(
                              height: 1,
                              width: statsWidth,
                              color: _lineColor,
                            ),
                            SizedBox(
                              width: statsWidth,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _SplitStat(
                                      value: liveStats.pendingSubmissions,
                                      label: 'pending\nsubmissions',
                                      scale: scale,
                                    ),
                                  ),
                                  Container(
                                    height: 104 * scale,
                                    width: 1,
                                    color: _lineColor,
                                  ),
                                  Expanded(
                                    child: _SplitStat(
                                      value: liveStats.totalSightings,
                                      label: 'total\nsightings',
                                      scale: scale,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      builder:
                          (BuildContext context, double value, Widget? child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, (1 - value) * 14),
                                child: child,
                              ),
                            );
                          },
                    );
                  },
                );
              },
        ),
      ),
    );
  }
}

class _HomeDashboardData {
  const _HomeDashboardData({
    required this.stats,
    required this.speciesOfTheDay,
    required this.isFallback,
  });

  const _HomeDashboardData.fallback()
    : stats = defaultAppStats,
      speciesOfTheDay = defaultSpeciesOfTheDay,
      isFallback = true;

  final AppStats stats;
  final SpeciesHighlight speciesOfTheDay;
  final bool isFallback;
}

class _SplitStat extends StatelessWidget {
  const _SplitStat({required this.value, required this.label, this.scale = 1});

  final int value;
  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(6 * scale, 12 * scale, 6 * scale, 0),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 72 * scale,
              height: 0.95,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: _primaryColor,
              letterSpacing: -2 * scale,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14 * scale,
              height: 1.1,
              color: _textColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileOverlayPanel extends StatelessWidget {
  const _ProfileOverlayPanel({
    required this.authController,
    required this.profileName,
    required this.profileHandle,
  });

  final AppAuthController authController;
  final String profileName;
  final String profileHandle;

  String get _resolvedName {
    final String fromUser = authController.user?.name.trim() ?? '';
    if (fromUser.isNotEmpty) {
      return fromUser;
    }

    final String fromArgument = profileName.trim();
    return fromArgument.isNotEmpty ? fromArgument : 'Researcher 1';
  }

  String get _resolvedHandle {
    final String userUsername = authController.user?.username.trim() ?? '';
    if (userUsername.isNotEmpty) {
      return userUsername.startsWith('@') ? userUsername : '@$userUsername';
    }

    final String fromArgument = profileHandle.trim();
    if (fromArgument.isNotEmpty) {
      return fromArgument.startsWith('@') ? fromArgument : '@$fromArgument';
    }

    final String fallback = _resolvedName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    return fallback.isNotEmpty ? '@$fallback' : '@researcher1';
  }

  void _openProfile(BuildContext context) {
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    navigator.pop();
    navigator.push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => _ResearcherProfileScreen(
          authController: authController,
          fallbackName: _resolvedName,
          fallbackHandle: _resolvedHandle,
        ),
        transitionsBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) {
              final Animation<double> fade = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );
              final Animation<Offset> slide = Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(fade);

              return FadeTransition(
                opacity: fade,
                child: SlideTransition(position: slide, child: child),
              );
            },
      ),
    );
  }

  void _openMyUploads(BuildContext context) {
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    navigator.pop();
    navigator.push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => const MyUploadsScreen(),
        transitionsBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) {
              final Animation<double> fade = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );
              final Animation<Offset> slide = Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(fade);

              return FadeTransition(
                opacity: fade,
                child: SlideTransition(position: slide, child: child),
              );
            },
      ),
    );
  }

  void _openSubmissions(BuildContext context) {
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    navigator.pop();
    navigator.push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => const UploadsStatusScreen(),
        transitionsBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) {
              final Animation<double> fade = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );
              final Animation<Offset> slide = Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(fade);

              return FadeTransition(
                opacity: fade,
                child: SlideTransition(position: slide, child: child),
              );
            },
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await authController.logout();
    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => WelcomeScreen(authController: authController),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: 0.72,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Material(
              color: _surfaceColor,
              elevation: 8,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: _lineColor, width: 1.2),
                      ),
                      child: const Icon(
                        Icons.sentiment_satisfied_alt_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _resolvedName,
                      style: const TextStyle(
                        color: _textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    Text(
                      _resolvedHandle,
                      style: const TextStyle(
                        color: _mutedTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '12 Data Uploaded',
                        style: TextStyle(
                          color: _primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _ProfileMenuItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Profile',
                      onTap: () => _openProfile(context),
                    ),
                    const SizedBox(height: 10),
                    _ProfileMenuItem(
                      icon: Icons.library_books_outlined,
                      label: 'My Uploads',
                      onTap: () => _openMyUploads(context),
                    ),
                    const SizedBox(height: 10),
                    _ProfileMenuItem(
                      icon: Icons.upload_file_outlined,
                      label: 'Submissions',
                      onTap: () => _openSubmissions(context),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _logout(context),
                      style: TextButton.styleFrom(
                        foregroundColor: _accentColor,
                        padding: const EdgeInsets.all(0),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Log out',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResearcherProfileScreen extends StatelessWidget {
  const _ResearcherProfileScreen({
    required this.authController,
    required this.fallbackName,
    required this.fallbackHandle,
  });

  final AppAuthController authController;
  final String fallbackName;
  final String fallbackHandle;

  String _displayName(AppUser? user) {
    final String fromUser = user?.name.trim() ?? '';
    if (fromUser.isNotEmpty) {
      return fromUser;
    }

    final String fromFallback = fallbackName.trim();
    return fromFallback.isNotEmpty ? fromFallback : 'Researcher 1';
  }

  String _displayHandle(AppUser? user) {
    final String username = user?.username.trim() ?? '';
    if (username.isNotEmpty) {
      return username.startsWith('@') ? username : '@$username';
    }

    final String fromFallback = fallbackHandle.trim();
    if (fromFallback.isNotEmpty) {
      return fromFallback.startsWith('@') ? fromFallback : '@$fromFallback';
    }

    return '@researcher1';
  }

  String _displayLocation(AppUser? user) {
    final String fromUser = user?.location.trim() ?? '';
    return fromUser.isNotEmpty
        ? fromUser
        : 'Mt. Busa, Kiamba, Sarangani Province';
  }

  Uint8List? _decodePhoto(AppUser? user) {
    final String encoded = user?.profilePhotoBase64.trim() ?? '';
    if (encoded.isEmpty) {
      return null;
    }

    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }

  void _showActionHint(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openEditProfile(
    BuildContext context,
    AppUser? user,
    String displayName,
    String displayHandle,
    String displayLocation,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => _EditProfileScreen(
          authController: authController,
          initialName: displayName,
          initialHandle: displayHandle,
          initialLocation: displayLocation,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          final slide = Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(fade);

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: authController,
          builder: (BuildContext context, Widget? child) {
            final AppUser? user = authController.user;
            final String displayName = _displayName(user);
            final String displayHandle = _displayHandle(user);
            final String displayLocation = _displayLocation(user);
            final Uint8List? photoBytes = _decodePhoto(user);

            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double heightScale = constraints.maxHeight / 844;
                final double widthScale = constraints.maxWidth / 390;
                final double scale =
                    (heightScale < widthScale ? heightScale : widthScale).clamp(
                      0.75,
                      1.15,
                    );

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      18 * scale,
                      10 * scale,
                      18 * scale,
                      12 * scale,
                    ),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 36 * scale,
                            height: 36 * scale,
                            decoration: BoxDecoration(
                              color: _surfaceColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: _lineColor),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              splashRadius: 20 * scale,
                              icon: Icon(
                                Icons.arrow_back_rounded,
                                size: 22 * scale,
                                color: _primaryColor,
                              ),
                              onPressed: () => Navigator.of(context).maybePop(),
                            ),
                          ),
                        ),
                        SizedBox(height: 18 * scale),
                        Container(
                          width: 194 * scale,
                          height: 194 * scale,
                          decoration: const BoxDecoration(
                            color: _primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: photoBytes != null
                                ? Image.memory(
                                    photoBytes,
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.sentiment_satisfied_alt_rounded,
                                      size: 124 * scale,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: 16 * scale),
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 49 * scale,
                            height: 0.95,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            color: _textColor,
                          ),
                        ),
                        SizedBox(height: 2 * scale),
                        Text(
                          displayHandle,
                          style: TextStyle(
                            fontSize: 29 * scale,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                            color: _textColor,
                          ),
                        ),
                        SizedBox(height: 1 * scale),
                        Text(
                          'UID: ${user?.accountId != null ? 'ACC-${user!.accountId}' : 'Unavailable'}',
                          style: TextStyle(
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            color: _mutedTextColor,
                          ),
                        ),
                        SizedBox(height: 9 * scale),
                        Container(
                          height: 1,
                          width: double.infinity,
                          color: _lineColor,
                        ),
                        SizedBox(height: 4 * scale),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Born January 1, 1990',
                              style: TextStyle(
                                fontSize: 14 * scale,
                                color: _mutedTextColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            Text(
                              'Joined December 2024',
                              style: TextStyle(
                                fontSize: 14 * scale,
                                color: _mutedTextColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 26 * scale),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Location of Interest:',
                            style: TextStyle(
                              fontSize: 28 * scale,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              color: _textColor,
                            ),
                          ),
                        ),
                        SizedBox(height: 6 * scale),
                        Text(
                          displayLocation,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24 * scale,
                            fontStyle: FontStyle.italic,
                            color: _textColor,
                          ),
                        ),
                        SizedBox(height: 12 * scale),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Affiliation:',
                            style: TextStyle(
                              fontSize: 28 * scale,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              color: _textColor,
                            ),
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => _showActionHint(
                              context,
                              'Affiliation editing coming soon.',
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: _surfaceColor,
                              foregroundColor: _primaryColor,
                              padding: EdgeInsets.symmetric(
                                horizontal: 14 * scale,
                                vertical: 8 * scale,
                              ),
                              minimumSize: Size(0, 24 * scale),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14 * scale),
                                side: BorderSide(color: _lineColor),
                              ),
                            ),
                            child: Text(
                              'Add Affiliation',
                              style: TextStyle(
                                fontSize: 14 * scale,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24 * scale),
                        TextButton(
                          onPressed: () => _openEditProfile(
                            context,
                            user,
                            displayName,
                            displayHandle,
                            displayLocation,
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: _textColor,
                            minimumSize: Size(0, 44 * scale),
                            padding: EdgeInsets.symmetric(
                              horizontal: 20 * scale,
                              vertical: 12 * scale,
                            ),
                            backgroundColor: _primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18 * scale),
                            ),
                          ),
                          child: Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 17 * scale,
                              fontWeight: FontWeight.w800,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EditProfileScreen extends StatefulWidget {
  const _EditProfileScreen({
    required this.authController,
    required this.initialName,
    required this.initialHandle,
    required this.initialLocation,
  });

  final AppAuthController authController;
  final String initialName;
  final String initialHandle;
  final String initialLocation;

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _locationController;

  Uint8List? _profilePhotoBytes;
  String _storedPhotoBase64 = '';
  bool _isPickingImage = false;
  bool _isSaving = false;

  String _formatHandleForField(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '@researcher1';
    }

    return trimmed.startsWith('@') ? trimmed : '@$trimmed';
  }

  @override
  void initState() {
    super.initState();

    final AppUser? user = widget.authController.user;

    final String initialName = user?.name.trim().isNotEmpty == true
        ? user!.name
        : widget.initialName.trim();
    final String initialUsername = user?.username.trim().isNotEmpty == true
        ? user!.username
        : widget.initialHandle.trim();
    final String initialLocation = user?.location.trim().isNotEmpty == true
        ? user!.location
        : widget.initialLocation.trim();

    _nameController = TextEditingController(
      text: initialName.isNotEmpty ? initialName : 'Researcher 1',
    );
    _usernameController = TextEditingController(
      text: _formatHandleForField(initialUsername),
    );
    _locationController = TextEditingController(
      text: initialLocation.isNotEmpty ? initialLocation : 'Mt. Busa',
    );

    _storedPhotoBase64 = user?.profilePhotoBase64 ?? '';
    if (_storedPhotoBase64.trim().isNotEmpty) {
      try {
        _profilePhotoBytes = base64Decode(_storedPhotoBase64);
      } catch (_) {
        _storedPhotoBase64 = '';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    if (_isPickingImage) {
      return;
    }

    setState(() {
      _isPickingImage = true;
    });

    try {
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 86,
        maxWidth: 1024,
      );

      if (pickedImage == null) {
        return;
      }

      final Uint8List bytes = await pickedImage.readAsBytes();

      if (!mounted) {
        return;
      }

      setState(() {
        _profilePhotoBytes = bytes;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open gallery right now.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) {
      return;
    }

    final String name = _nameController.text.trim();
    final String rawHandle = _usernameController.text.trim();
    final String location = _locationController.text.trim();
    final String username = rawHandle.replaceFirst(RegExp(r'^@+'), '');

    if (name.isEmpty || username.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name, Username, and Location are required.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      final String photoBase64 = _profilePhotoBytes != null
          ? base64Encode(_profilePhotoBytes!)
          : _storedPhotoBase64;

      await widget.authController.updateProfile(
        name: name,
        username: username,
        location: location,
        profilePhotoBase64: photoBase64,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved.')));
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save profile right now.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showHint(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double heightScale = constraints.maxHeight / 844;
            final double widthScale = constraints.maxWidth / 390;
            final double scale =
                (heightScale < widthScale ? heightScale : widthScale).clamp(
                  0.78,
                  1.1,
                );

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  18 * scale,
                  10 * scale,
                  18 * scale,
                  12 * scale,
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 36 * scale,
                        height: 36 * scale,
                        decoration: BoxDecoration(
                          color: _surfaceColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: _lineColor),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          splashRadius: 20 * scale,
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            size: 22 * scale,
                            color: _primaryColor,
                          ),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                    ),
                    SizedBox(height: 16 * scale),
                    InkResponse(
                      onTap: _pickProfilePhoto,
                      radius: 106 * scale,
                      child: Container(
                        width: 194 * scale,
                        height: 194 * scale,
                        decoration: const BoxDecoration(
                          color: _primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipOval(
                              child: _profilePhotoBytes != null
                                  ? Image.memory(
                                      _profilePhotoBytes!,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                    )
                                  : Center(
                                      child: Icon(
                                        Icons.add_rounded,
                                        size: 96 * scale,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                            if (_isPickingImage)
                              const ColoredBox(
                                color: Color(0x66000000),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12 * scale),
                    Text(
                      'UID: aBc123dEf',
                      style: TextStyle(
                        fontSize: 22 * scale,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF676D65),
                      ),
                    ),
                    SizedBox(height: 26 * scale),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                      child: Column(
                        children: [
                          _EditProfileEditableRow(
                            label: 'Name',
                            controller: _nameController,
                            scale: scale,
                            enabled: !_isSaving,
                            textCapitalization: TextCapitalization.words,
                          ),
                          SizedBox(height: 10 * scale),
                          _EditProfileEditableRow(
                            label: 'Username',
                            controller: _usernameController,
                            scale: scale,
                            enabled: !_isSaving,
                          ),
                          SizedBox(height: 10 * scale),
                          _EditProfileEditableRow(
                            label: 'Location',
                            controller: _locationController,
                            scale: scale,
                            enabled: !_isSaving,
                            textCapitalization: TextCapitalization.words,
                          ),
                          SizedBox(height: 10 * scale),
                          _EditProfileValueRow(
                            label: 'Password',
                            value: 'Edit Password',
                            scale: scale,
                            onTap: () =>
                                _showHint('Password editing coming soon.'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24 * scale),
                    TextButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: TextButton.styleFrom(
                        foregroundColor: _primaryColor,
                        minimumSize: Size(0, 36 * scale),
                        padding: EdgeInsets.symmetric(horizontal: 20 * scale),
                      ),
                      child: Text(
                        _isSaving ? 'Saving...' : 'Save Profile',
                        style: TextStyle(
                          fontSize: 18 * scale,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EditProfileEditableRow extends StatelessWidget {
  const _EditProfileEditableRow({
    required this.label,
    required this.controller,
    required this.scale,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final double scale;
  final bool enabled;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: _textColor,
            ),
          ),
        ),
        SizedBox(width: 12 * scale),
        Expanded(
          flex: 6,
          child: TextField(
            controller: controller,
            enabled: enabled,
            textAlign: TextAlign.right,
            textCapitalization: textCapitalization,
            style: TextStyle(
              fontSize: 17 * scale,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: _textColor,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}

class _EditProfileValueRow extends StatelessWidget {
  const _EditProfileValueRow({
    required this.label,
    required this.value,
    required this.scale,
    required this.onTap,
  });

  final String label;
  final String value;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: _textColor,
            ),
          ),
        ),
        SizedBox(width: 12 * scale),
        Expanded(
          flex: 6,
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                foregroundColor: _textColor,
                minimumSize: const Size(0, 0),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 17 * scale,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F9FB),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: _primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: _textColor,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _mutedTextColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({required this.authController, super.key});

  final AppAuthController authController;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  bool _gridMode = false;
  late Future<List<CatalogSpecies>> _speciesFuture;

  @override
  void initState() {
    super.initState();
    _speciesFuture = _loadCatalogSpecies();
  }

  List<CatalogSpecies> _fallbackCatalogSpecies() {
    return orchidCatalogGroups
        .expand((CatalogGroup group) => group.species)
        .toList(growable: false);
  }

  List<CatalogGroup> _groupSpecies(List<CatalogSpecies> allSpecies) {
    final Map<String, List<CatalogSpecies>> grouped =
        <String, List<CatalogSpecies>>{};

    for (final CatalogSpecies species in allSpecies) {
      final String key = species.genus.trim().isNotEmpty
          ? species.genus.trim()
          : species.scientificName.trim().split(RegExp(r'\s+')).first;
      grouped.putIfAbsent(key, () => <CatalogSpecies>[]).add(species);
    }

    final List<String> sortedKeys = grouped.keys.toList(
      growable: false,
    )..sort((String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return sortedKeys
        .map(
          (String key) => CatalogGroup(
            title: key,
            species: (grouped[key]!
              ..sort(
                (CatalogSpecies a, CatalogSpecies b) => a.scientificName
                    .toLowerCase()
                    .compareTo(b.scientificName.toLowerCase()),
              )),
          ),
        )
        .toList(growable: false);
  }

  Future<List<CatalogSpecies>> _loadCatalogSpecies() async {
    if (kOfflineMode) return _fallbackCatalogSpecies();
    final http.Client client = http.Client();
    try {
      final http.Response response = await client
          .get(buildApiUri('/api/species'))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        return _fallbackCatalogSpecies();
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return _fallbackCatalogSpecies();
      }

      final List<CatalogSpecies> mapped = decoded
          .whereType<Map>()
          .map((Map item) {
            final Map<String, dynamic> json = Map<String, dynamic>.from(item);
            final String scientificName = (json['scientificName'] ?? '')
                .toString()
                .trim();
            if (scientificName.isEmpty) {
              return null;
            }

            final String commonName = (json['commonName'] ?? '')
                .toString()
                .trim();
            final String genus = (json['genus'] ?? '').toString().trim();
            final String imageUrl = (json['imageUrl'] ?? '').toString().trim();

            return CatalogSpecies(
              id: int.tryParse((json['id'] ?? '').toString()),
              scientificName: scientificName,
              commonName: commonName.isNotEmpty ? commonName : 'Common Name',
              genus: genus,
              imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
              latitude: double.tryParse((json['lat'] ?? '').toString()),
              longitude: double.tryParse((json['lng'] ?? '').toString()),
            );
          })
          .whereType<CatalogSpecies>()
          .toList(growable: false);

      if (mapped.isEmpty) {
        return _fallbackCatalogSpecies();
      }

      return mapped;
    } catch (_) {
      return _fallbackCatalogSpecies();
    } finally {
      client.close();
    }
  }

  Future<void> _openProfilePanel() async {
    final String profileName =
        widget.authController.user?.name.trim().isNotEmpty == true
        ? widget.authController.user!.name
        : 'Researcher 1';
    final String handleSource =
        widget.authController.user?.email.trim().isNotEmpty == true
        ? widget.authController.user!.email.split('@').first
        : profileName;
    final String normalizedHandle = handleSource.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    final String profileHandle = normalizedHandle.isNotEmpty
        ? '@$normalizedHandle'
        : '@researcher1';

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close profile menu',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, _, _) {
        return _ProfileOverlayPanel(
          authController: widget.authController,
          profileName: profileName,
          profileHandle: profileHandle,
        );
      },
      transitionBuilder: (_, animation, _, child) {
        final Animation<Offset> slide =
            Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        return SlideTransition(position: slide, child: child);
      },
    );
  }

  void _openSpeciesDetails(CatalogSpecies species) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CatalogSpeciesDetailsScreen(species: species),
      ),
    );
  }

  String _heroTagFor(CatalogSpecies species) {
    final String slug = species.scientificName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return 'catalog-species-${slug.isEmpty ? 'unknown' : slug}';
  }

  Widget _buildModeButton({
    required bool selected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 38,
        height: 24,
        decoration: BoxDecoration(
          color: selected ? _primaryColor : _surfaceColor,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: _lineColor),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 14,
          color: selected ? Colors.white : _primaryColor,
        ),
      ),
    );
  }

  Widget _buildCatalogList(List<CatalogGroup> groups) {
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      children: [
        for (final CatalogGroup group in groups)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _lineColor),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.title,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        color: _textColor,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final CatalogSpecies species in group.species)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () => _openSpeciesDetails(species),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 11,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: _accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      species.scientificName,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        color: _textColor,
                                        fontStyle: FontStyle.italic,
                                        height: 1.05,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: _mutedTextColor,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCatalogGrid(List<CatalogSpecies> allSpecies) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 22),
      itemCount: allSpecies.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        final CatalogSpecies item = allSpecies[index];

        Widget imageTile;
        if (item.imageUrl == null) {
          imageTile = Container(
            decoration: BoxDecoration(
              color: _surfaceTintColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _lineColor, width: 1),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_outlined,
              color: _mutedTextColor,
              size: 24,
            ),
          );
        } else {
          imageTile = ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              item.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: _surfaceTintColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _lineColor, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: _mutedTextColor,
                        size: 24,
                      ),
                    );
                  },
            ),
          );
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openSpeciesDetails(item),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _lineColor),
              ),
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 90,
                    width: double.infinity,
                    child: Hero(tag: _heroTagFor(item), child: imageTile),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.scientificName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _textColor,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                    ),
                  ),
                  Text(
                    item.commonName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _mutedTextColor,
                      fontStyle: FontStyle.italic,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: Colors.transparent,
                child: InkResponse(
                  onTap: _openProfilePanel,
                  radius: 28,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: _lineColor),
                    ),
                    child: const Icon(
                      Icons.sentiment_satisfied_alt_rounded,
                      color: _primaryColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Orchid Catalog',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: _textColor,
                  letterSpacing: -0.5,
                  height: 0.95,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _lineColor, width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeButton(
                      selected: !_gridMode,
                      icon: Icons.view_headline_rounded,
                      onTap: () => setState(() => _gridMode = false),
                    ),
                    _buildModeButton(
                      selected: _gridMode,
                      icon: Icons.grid_view_rounded,
                      onTap: () => setState(() => _gridMode = true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: FutureBuilder<List<CatalogSpecies>>(
                  future: _speciesFuture,
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<List<CatalogSpecies>> snapshot,
                      ) {
                        final List<CatalogSpecies> allSpecies =
                            snapshot.data ?? _fallbackCatalogSpecies();
                        final List<CatalogGroup> groups = _groupSpecies(
                          allSpecies,
                        );

                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                                final Animation<Offset> slide =
                                    Tween<Offset>(
                                      begin: const Offset(0.04, 0),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    );

                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: slide,
                                    child: child,
                                  ),
                                );
                              },
                          child: _gridMode
                              ? KeyedSubtree(
                                  key: const ValueKey<String>('catalog-grid'),
                                  child: _buildCatalogGrid(allSpecies),
                                )
                              : KeyedSubtree(
                                  key: const ValueKey<String>('catalog-list'),
                                  child: _buildCatalogList(groups),
                                ),
                        );
                      },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _CatalogDetailSection { speciesValue, sightings, contributors }

class CatalogSpeciesDetailsScreen extends StatefulWidget {
  const CatalogSpeciesDetailsScreen({required this.species, super.key});

  final CatalogSpecies species;

  @override
  State<CatalogSpeciesDetailsScreen> createState() =>
      _CatalogSpeciesDetailsScreenState();
}

class _CatalogSpeciesDetailsScreenState
    extends State<CatalogSpeciesDetailsScreen> {
  _CatalogDetailSection _selectedSection = _CatalogDetailSection.speciesValue;

  List<String> get _scientificParts {
    return widget.species.scientificName
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList(growable: false);
  }

  String get _genus {
    if (_scientificParts.isEmpty) {
      return 'Unknown';
    }

    return _scientificParts.first;
  }

  String get _speciesEpithet {
    if (_scientificParts.length <= 1) {
      return widget.species.scientificName;
    }

    return _scientificParts.sublist(1).join(' ');
  }

  String get _normalizedCommonName {
    final String commonName = widget.species.commonName.trim();
    if (commonName.toLowerCase() == 'common name' || commonName.isEmpty) {
      return 'No recorded common name';
    }

    return commonName;
  }

  String get _detailedCommonName {
    if (_normalizedCommonName.toLowerCase() == 'waling-waling') {
      return 'Waling-waling\nSander\'s Vanda';
    }

    return _normalizedCommonName;
  }

  String get _endemicity {
    final String normalized = widget.species.scientificName.toLowerCase();
    if (normalized == 'vanda sanderiana' ||
        normalized.contains('philippinensis')) {
      return 'Native to the Philippines';
    }

    return 'Not endemic to the Philippines';
  }

  String get _seedSlug {
    final String slug = widget.species.scientificName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    if (slug.isEmpty) {
      return 'orchid';
    }

    return slug;
  }

  String get _heroTag => 'catalog-species-$_seedSlug';

  double get _sightingLatitude => widget.species.latitude ?? 5.9352;

  double get _sightingLongitude => widget.species.longitude ?? 125.0832;

  String get _sightingsMapUrl {
    final String lat = _sightingLatitude.toStringAsFixed(4);
    final String lng = _sightingLongitude.toStringAsFixed(4);
    return 'https://staticmap.openstreetmap.de/staticmap.php?center=$lat,$lng&zoom=12&size=700x420&markers=$lat,$lng,red-pushpin';
  }

  List<String> get _sightingDates {
    if (_seedSlug == 'vanda-sanderiana') {
      return const <String>['Dec. 1, 2024', 'Dec. 9, 2024', 'Dec. 22, 2024'];
    }

    return const <String>['Nov. 28, 2024', 'Dec. 7, 2024', 'Dec. 19, 2024'];
  }

  String get _sightingLocation => 'Mt. Busa, Kiamba, Sarangani';

  String get _sightingAltitude {
    if (_seedSlug == 'vanda-sanderiana') {
      return '200 meters above sea level';
    }

    return '185 meters above sea level';
  }

  String get _sightingElevation {
    if (_seedSlug == 'vanda-sanderiana') {
      return '175 meters above sea level';
    }

    return '162 meters above sea level';
  }

  String get _sightingHabitatType {
    if (_endemicity == 'Native to the Philippines') {
      return 'Montane forest';
    }

    return 'Secondary forest edge';
  }

  String get _sightingMicroHabitat {
    return 'Epiphytic on mossy branches';
  }

  List<String> get _contributors {
    if (_seedSlug == 'vanda-sanderiana') {
      return const <String>['Researcher 1'];
    }

    return const <String>['Researcher 1'];
  }

  List<String> get _galleryImages {
    final String primaryImage =
        widget.species.imageUrl ??
        'https://picsum.photos/seed/$_seedSlug-main/360/360';

    return <String>[
      primaryImage,
      'https://picsum.photos/seed/$_seedSlug-alt-1/360/360',
      'https://picsum.photos/seed/$_seedSlug-alt-2/360/360',
    ];
  }

  void _showMoreImagesHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('More orchid images coming soon.')),
    );
  }

  Widget _sectionTabButton({
    required IconData icon,
    required _CatalogDetailSection section,
  }) {
    final bool selected = _selectedSection == section;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSection = section;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _primaryColor : _surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _lineColor),
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          scale: selected ? 1.03 : 1,
          child: Icon(
            icon,
            size: 22,
            color: selected ? Colors.white : _primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _galleryTile(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _surfaceTintColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _lineColor, width: 0.8),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_outlined,
                  color: _mutedTextColor,
                  size: 24,
                ),
              );
            },
      ),
    );
  }

  Widget _infoRow({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _lineColor, width: 0.9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 114,
            child: Text(
              label,
              style: const TextStyle(
                color: _textColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _mutedTextColor,
                fontSize: 15,
                height: 1.25,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _textColor,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
        height: 1.0,
      ),
    );
  }

  Widget _sectionSubheading(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _textColor,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
        decoration: TextDecoration.underline,
        decorationColor: _textColor,
      ),
    );
  }

  Widget _valueBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 1),
      child: Text(
        '\u2022  $text',
        style: const TextStyle(
          color: _mutedTextColor,
          fontSize: 14,
          height: 1.2,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildSpeciesValueSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading('Species Value'),
        const SizedBox(height: 12),
        _sectionSubheading('Ethnobotanical Importance'),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.only(left: 6),
          child: Text(
            'No recorded ethnobotanical importance',
            style: TextStyle(
              color: _mutedTextColor,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _sectionSubheading('Horticulture Value'),
        const SizedBox(height: 6),
        const Text(
          'Aesthetic Appeal',
          style: TextStyle(
            color: _textColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
        ),
        _valueBullet(
          _normalizedCommonName == 'Waling-waling'
              ? 'Vibrant'
              : 'Distinctive bloom clusters',
        ),
        const SizedBox(height: 6),
        const Text(
          'Cultivation',
          style: TextStyle(
            color: _textColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
        ),
        _valueBullet('Adaptable'),
        _valueBullet('Low maintenance under stable humidity'),
        const SizedBox(height: 6),
        const Text(
          'Rarity',
          style: TextStyle(
            color: _textColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
        ),
        _valueBullet(
          _endemicity == 'Native to the Philippines'
              ? 'Native to the Philippines'
              : 'Locally observed in mixed habitats',
        ),
        _valueBullet('Common in cultivated collections'),
      ],
    );
  }

  Widget _buildContributorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading('Contributors'),
        const SizedBox(height: 8),
        for (final String contributor in _contributors)
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 2),
            child: Text(
              contributor,
              style: const TextStyle(
                color: _textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                height: 1.05,
              ),
            ),
          ),
      ],
    );
  }

  Widget _sightingsInfoField({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: _mutedTextColor,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSightingsDateRail() {
    final List<String> rows = <String>[
      ..._sightingDates,
      ...List<String>.filled(14, ''),
    ];

    return Container(
      width: 96,
      decoration: BoxDecoration(
        border: Border.all(color: _lineColor, width: 1),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++)
            Container(
              height: 24,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: i == rows.length - 1
                        ? Colors.transparent
                        : _lineColor,
                    width: 0.9,
                  ),
                ),
              ),
              child: Text(
                rows[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textColor,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSightingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading('Sightings'),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSightingsDateRail(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Map',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      _sightingsMapUrl,
                      height: 172,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) {
                            return Container(
                              height: 172,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: _surfaceTintColor,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.map_outlined,
                                color: _mutedTextColor,
                                size: 40,
                              ),
                            );
                          },
                    ),
                  ),
                  _sightingsInfoField(
                    label: 'Location',
                    value: _sightingLocation,
                  ),
                  _sightingsInfoField(
                    label: 'Altitude',
                    value: _sightingAltitude,
                  ),
                  _sightingsInfoField(
                    label: 'Elevation',
                    value: _sightingElevation,
                  ),
                  _sightingsInfoField(
                    label: 'Habitat Type',
                    value: _sightingHabitatType,
                  ),
                  _sightingsInfoField(
                    label: 'Micro Habitat',
                    value: _sightingMicroHabitat,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLowerSection() {
    switch (_selectedSection) {
      case _CatalogDetailSection.speciesValue:
        return _buildSpeciesValueSection();
      case _CatalogDetailSection.sightings:
        return _buildSightingsSection();
      case _CatalogDetailSection.contributors:
        return _buildContributorsSection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: _lineColor),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      splashRadius: 20,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: _primaryColor,
                        size: 22,
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '... / Genus / $_genus / Species / ${widget.species.scientificName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _mutedTextColor,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.species.scientificName,
                        style: const TextStyle(
                          color: _textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Images',
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (int i = 0; i < _galleryImages.length; i++) ...[
                              i == 0
                                  ? Hero(
                                      tag: _heroTag,
                                      child: _galleryTile(_galleryImages[i]),
                                    )
                                  : _galleryTile(_galleryImages[i]),
                              const SizedBox(width: 8),
                            ],
                            InkWell(
                              onTap: _showMoreImagesHint,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 44,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: _surfaceTintColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _lineColor,
                                    width: 0.9,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'See\nMore',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _mutedTextColor,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    height: 1.05,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _sectionHeading('Species Information'),
                      const SizedBox(height: 6),
                      _infoRow(label: 'Family', value: 'Orchidaceae'),
                      _infoRow(label: 'Genus', value: _genus),
                      _infoRow(label: 'Species', value: _speciesEpithet),
                      _infoRow(
                        label: 'Common Name',
                        value: _detailedCommonName,
                      ),
                      _infoRow(label: 'Endemicity', value: _endemicity),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _sectionTabButton(
                            icon: Icons.diamond_outlined,
                            section: _CatalogDetailSection.speciesValue,
                          ),
                          _sectionTabButton(
                            icon: Icons.visibility_outlined,
                            section: _CatalogDetailSection.sightings,
                          ),
                          _sectionTabButton(
                            icon: Icons.groups_2_rounded,
                            section: _CatalogDetailSection.contributors,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              final Animation<Offset> slide =
                                  Tween<Offset>(
                                    begin: const Offset(0.04, 0),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  );

                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: slide,
                                  child: child,
                                ),
                              );
                            },
                        child: KeyedSubtree(
                          key: ValueKey<_CatalogDetailSection>(
                            _selectedSection,
                          ),
                          child: _buildLowerSection(),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UploadScreen extends StatefulWidget {
  const UploadScreen({required this.authController, super.key});

  final AppAuthController authController;

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  int _draftCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshDraftCount();
  }

  Future<void> _refreshDraftCount() async {
    final List<UploadSpeciesFlowData> drafts =
        await UploadSpeciesDraftStore.loadDrafts();
    if (!mounted) {
      return;
    }

    setState(() {
      _draftCount = drafts.length;
    });
  }

  Future<void> _openProfilePanel(BuildContext context) async {
    final String profileName =
        widget.authController.user?.name.trim().isNotEmpty == true
        ? widget.authController.user!.name
        : 'Researcher 1';
    final String handleSource =
        widget.authController.user?.email.trim().isNotEmpty == true
        ? widget.authController.user!.email.split('@').first
        : profileName;
    final String normalizedHandle = handleSource.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    final String profileHandle = normalizedHandle.isNotEmpty
        ? '@$normalizedHandle'
        : '@researcher1';

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close profile menu',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, _, _) {
        return _ProfileOverlayPanel(
          authController: widget.authController,
          profileName: profileName,
          profileHandle: profileHandle,
        );
      },
      transitionBuilder: (_, animation, _, child) {
        final Animation<Offset> slide =
            Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        return SlideTransition(position: slide, child: child);
      },
    );
  }

  Future<void> _openUploadNewSpecies(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const UploadSpeciesRequirementsScreen(),
      ),
    );

    await _refreshDraftCount();
  }

  Future<void> _openDraftUploads(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const UploadSpeciesDraftsScreen(),
      ),
    );

    await _refreshDraftCount();
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label coming soon.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: Colors.transparent,
                child: InkResponse(
                  onTap: () => _openProfilePanel(context),
                  radius: 28,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: _lineColor),
                    ),
                    child: const Icon(
                      Icons.sentiment_satisfied_alt_rounded,
                      color: _primaryColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Upload',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: _textColor,
                  height: 0.95,
                ),
              ),
              const SizedBox(height: 24),
              _UploadActionRow(
                icon: Icons.add_rounded,
                label: 'Upload New Species',
                onTap: () => _openUploadNewSpecies(context),
              ),
              const SizedBox(height: 18),
              _UploadActionRow(
                icon: Icons.drafts_outlined,
                label: 'Draft Uploads',
                badgeCount: _draftCount,
                onTap: () => _openDraftUploads(context),
              ),
              const SizedBox(height: 18),
              _UploadActionRow(
                icon: Icons.visibility_outlined,
                label: 'Add New Species Sightings',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const AddSpeciesSightingsRequirementsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              _UploadActionRow(
                icon: Icons.threed_rotation,
                label: 'Upload 3D Image',
                onTap: () => _showComingSoon(context, 'Upload 3D Image'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UploadSpeciesRequirementsScreen extends StatelessWidget {
  const UploadSpeciesRequirementsScreen({super.key});

  void _openSpeciesInformationForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            UploadSpeciesInformationScreen(flowData: UploadSpeciesFlowData()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _UploadFormHeader(title: 'Upload New Species'),
              const SizedBox(height: 24),
              const Text(
                'Upload New Species',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  color: _textColor,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Requirements:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: _textColor,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Before you proceed, please note of\nthe following requirements.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.25,
                          fontStyle: FontStyle.italic,
                          color: _mutedTextColor,
                        ),
                      ),
                      SizedBox(height: 22),
                      _RequirementBullet(text: 'Species Information'),
                      _RequirementBullet(text: 'Common Name', level: 1),
                      _RequirementBullet(text: 'Scientific Name', level: 1),
                      _RequirementBullet(text: 'Genus', level: 1),
                      _RequirementBullet(text: 'Endemicity', level: 1),
                      SizedBox(height: 10),
                      _RequirementBullet(text: 'Species Sightings'),
                      SizedBox(height: 10),
                      _RequirementBullet(text: 'Species Value'),
                      SizedBox(height: 10),
                      _RequirementBullet(
                        text: 'Images',
                        suffix: ' (at least 1, with photo credits)',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: OutlinedButton(
                  onPressed: () => _openSpeciesInformationForm(context),
                  style: _uploadActionButtonStyle(),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class AddSpeciesSightingsRequirementsScreen extends StatelessWidget {
  const AddSpeciesSightingsRequirementsScreen({super.key});

  void _openFindSpeciesScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AddSpeciesFindScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _UploadFormHeader(title: 'Add New Sightings'),
              const SizedBox(height: 24),
              const Text(
                'Add New Sightings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Requirements:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Before you proceed, please note of\nthe following requirements.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.25,
                  fontStyle: FontStyle.italic,
                  color: _mutedTextColor,
                ),
              ),
              const SizedBox(height: 22),
              const _RequirementBullet(text: 'Sightings Information'),
              const SizedBox(height: 10),
              const _RequirementBullet(text: 'Image', suffix: ' (at least 1)'),
              const Spacer(),
              Center(
                child: OutlinedButton(
                  onPressed: () => _openFindSpeciesScreen(context),
                  style: _uploadActionButtonStyle(),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddSpeciesFindScreen extends StatefulWidget {
  const AddSpeciesFindScreen({super.key});

  @override
  State<AddSpeciesFindScreen> createState() => _AddSpeciesFindScreenState();
}

class _AddSpeciesFindScreenState extends State<AddSpeciesFindScreen> {
  final TextEditingController _familyController = TextEditingController();
  final TextEditingController _genusController = TextEditingController();
  final TextEditingController _scientificNameController =
      TextEditingController();

  @override
  void dispose() {
    _familyController.dispose();
    _genusController.dispose();
    _scientificNameController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration() {
    return _uploadInputDecoration();
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
        color: _textColor,
      ),
    );
  }

  void _findSpecies() {
    final String family = _familyController.text.trim();
    final String genus = _genusController.text.trim();
    final String scientificName = _scientificNameController.text.trim();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddSpeciesFindResultsScreen(
          family: family.isEmpty ? 'Orchidaceae' : family,
          genus: genus.isEmpty ? 'Vanda' : genus,
          scientificName: scientificName.isEmpty
              ? 'Vanda sanderiana'
              : scientificName,
          commonName: 'Waling-waling',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _UploadFormHeader(title: 'Add New Sightings'),
              const SizedBox(height: 24),
              const Text(
                'Find Species',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 14),
              _fieldLabel('Family'),
              const SizedBox(height: 4),
              SizedBox(
                height: 34,
                child: TextField(
                  controller: _familyController,
                  decoration: _fieldDecoration(),
                ),
              ),
              const SizedBox(height: 8),
              _fieldLabel('Genus'),
              const SizedBox(height: 4),
              SizedBox(
                height: 34,
                child: TextField(
                  controller: _genusController,
                  decoration: _fieldDecoration(),
                ),
              ),
              const SizedBox(height: 8),
              _fieldLabel('Scientific Name'),
              const SizedBox(height: 4),
              SizedBox(
                height: 34,
                child: TextField(
                  controller: _scientificNameController,
                  decoration: _fieldDecoration(),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: FilledButton(
                  onPressed: _findSpecies,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 7,
                    ),
                    minimumSize: const Size(136, 42),
                  ),
                  child: const Text(
                    'FIND',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddSpeciesFindResultsScreen extends StatelessWidget {
  const AddSpeciesFindResultsScreen({
    required this.family,
    required this.genus,
    required this.scientificName,
    required this.commonName,
    super.key,
  });

  final String family;
  final String genus;
  final String scientificName;
  final String commonName;

  void _openSightingsInformationForm(BuildContext context) {
    final UploadSpeciesFlowData flowData = UploadSpeciesFlowData(
      family: family,
      genus: genus,
      scientificName: scientificName,
      commonNames: commonName.trim().isEmpty
          ? <String>[]
          : <String>[commonName],
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UploadSpeciesSightingsScreen(
          flowData: flowData,
          flowTitle: 'Add New Sightings',
          showSpeciesValueStep: false,
        ),
      ),
    );
  }

  Widget _labelText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
        color: _textColor,
      ),
    );
  }

  Widget _valueText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, top: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.italic,
          color: _mutedTextColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _UploadFormHeader(title: 'Add New Sightings'),
              const SizedBox(height: 24),
              const Text(
                'Find Species',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '1 Species Found',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  color: _mutedTextColor,
                ),
              ),
              const SizedBox(height: 14),
              _labelText('Family'),
              _valueText(family),
              const SizedBox(height: 6),
              _labelText('Genus'),
              _valueText(genus),
              const SizedBox(height: 6),
              _labelText('Scientific Name'),
              _valueText(scientificName),
              const SizedBox(height: 6),
              _labelText('Common Name'),
              _valueText(commonName),
              const SizedBox(height: 18),
              Center(
                child: FilledButton(
                  onPressed: () => _openSightingsInformationForm(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    minimumSize: const Size(150, 45),
                  ),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UploadSpeciesImageDraft {
  UploadSpeciesImageDraft({
    required this.path,
    required this.sizeBytes,
    this.photoCredit = '',
  });

  final String path;
  final int sizeBytes;
  String photoCredit;

  UploadSpeciesImageDraft copy() {
    return UploadSpeciesImageDraft(
      path: path,
      sizeBytes: sizeBytes,
      photoCredit: photoCredit,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'path': path,
    'sizeBytes': sizeBytes,
    'photoCredit': photoCredit,
  };

  factory UploadSpeciesImageDraft.fromJson(Map<String, dynamic> json) {
    return UploadSpeciesImageDraft(
      path: (json['path'] ?? '').toString(),
      sizeBytes: int.tryParse((json['sizeBytes'] ?? '0').toString()) ?? 0,
      photoCredit: (json['photoCredit'] ?? '').toString(),
    );
  }
}

class UploadContributorDraft {
  UploadContributorDraft({required this.name, required this.position});

  final String name;
  final String position;

  UploadContributorDraft copy() {
    return UploadContributorDraft(name: name, position: position);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'position': position,
  };

  factory UploadContributorDraft.fromJson(Map<String, dynamic> json) {
    return UploadContributorDraft(
      name: (json['name'] ?? '').toString(),
      position: (json['position'] ?? '').toString(),
    );
  }
}

class UploadSpeciesFlowData {
  UploadSpeciesFlowData({
    this.draftId,
    this.location = '',
    this.family = '',
    this.genus = '',
    this.scientificName = '',
    List<String>? commonNames,
    this.identificationConfidence = 'Confirmed',
    this.endemicToPhilippines = true,
    this.leafType = '',
    this.flowerColor = '',
    this.floweringFromMonth = '',
    this.floweringToMonth = '',
    this.observationDate = '',
    this.observationTime = '',
    this.collectionMethod = '',
    this.observationType = '',
    this.voucherSpecimenCollected = false,
    this.numberLocated = '',
    this.ethnobotanicalImportance = '',
    this.aestheticAppeal = '',
    this.cultivation = '',
    this.rarity = '',
    this.culturalImportance = '',
    this.latitude = '',
    this.longitude = '',
    this.province = '',
    this.municipality = '',
    this.mountain = '',
    this.altitude = '',
    this.elevation = '',
    this.habitatType = '',
    this.microHabitat = '',
    List<UploadSpeciesImageDraft>? images,
    List<UploadContributorDraft>? contributors,
    DateTime? updatedAt,
  }) : commonNames = commonNames ?? <String>[],
       images = images ?? <UploadSpeciesImageDraft>[],
       contributors = contributors ?? <UploadContributorDraft>[],
       updatedAt = updatedAt ?? DateTime.now();

  String? draftId;
  String location;
  String family;
  String genus;
  String scientificName;
  List<String> commonNames;
  String identificationConfidence;
  bool endemicToPhilippines;

  String get commonName => commonNames.isNotEmpty ? commonNames.first : '';
  String leafType;
  String flowerColor;
  String floweringFromMonth;
  String floweringToMonth;
  String observationDate;
  String observationTime;
  String collectionMethod;
  String observationType;
  bool voucherSpecimenCollected;
  String numberLocated;

  String ethnobotanicalImportance;
  String aestheticAppeal;
  String cultivation;
  String rarity;
  String culturalImportance;

  String latitude;
  String longitude;
  String province;
  String municipality;
  String mountain;
  String altitude;
  String elevation;
  String habitatType;
  String microHabitat;

  List<UploadSpeciesImageDraft> images;
  List<UploadContributorDraft> contributors;

  DateTime updatedAt;

  UploadSpeciesFlowData copy() {
    return UploadSpeciesFlowData(
      draftId: draftId,
      location: location,
      family: family,
      genus: genus,
      scientificName: scientificName,
      commonNames: List<String>.from(commonNames),
      identificationConfidence: identificationConfidence,
      endemicToPhilippines: endemicToPhilippines,
      leafType: leafType,
      flowerColor: flowerColor,
      floweringFromMonth: floweringFromMonth,
      floweringToMonth: floweringToMonth,
      observationDate: observationDate,
      observationTime: observationTime,
      collectionMethod: collectionMethod,
      observationType: observationType,
      voucherSpecimenCollected: voucherSpecimenCollected,
      numberLocated: numberLocated,
      ethnobotanicalImportance: ethnobotanicalImportance,
      aestheticAppeal: aestheticAppeal,
      cultivation: cultivation,
      rarity: rarity,
      culturalImportance: culturalImportance,
      latitude: latitude,
      longitude: longitude,
      province: province,
      municipality: municipality,
      mountain: mountain,
      altitude: altitude,
      elevation: elevation,
      habitatType: habitatType,
      microHabitat: microHabitat,
      images: images
          .map((UploadSpeciesImageDraft image) => image.copy())
          .toList(growable: false),
      contributors: contributors
          .map((UploadContributorDraft contributor) => contributor.copy())
          .toList(growable: false),
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'draftId': draftId,
      'location': location,
      'family': family,
      'genus': genus,
      'scientificName': scientificName,
      'commonName': commonName,
      'commonNames': commonNames,
      'identificationConfidence': identificationConfidence,
      'endemicToPhilippines': endemicToPhilippines,
      'leafType': leafType,
      'flowerColor': flowerColor,
      'floweringFromMonth': floweringFromMonth,
      'floweringToMonth': floweringToMonth,
      'observationDate': observationDate,
      'observationTime': observationTime,
      'collectionMethod': collectionMethod,
      'observationType': observationType,
      'voucherSpecimenCollected': voucherSpecimenCollected,
      'numberLocated': numberLocated,
      'ethnobotanicalImportance': ethnobotanicalImportance,
      'aestheticAppeal': aestheticAppeal,
      'cultivation': cultivation,
      'rarity': rarity,
      'culturalImportance': culturalImportance,
      'latitude': latitude,
      'longitude': longitude,
      'province': province,
      'municipality': municipality,
      'mountain': mountain,
      'altitude': altitude,
      'elevation': elevation,
      'habitatType': habitatType,
      'microHabitat': microHabitat,
      'images': images
          .map((UploadSpeciesImageDraft image) => image.toJson())
          .toList(growable: false),
      'contributors': contributors
          .map((UploadContributorDraft contributor) => contributor.toJson())
          .toList(growable: false),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UploadSpeciesFlowData.fromJson(Map<String, dynamic> json) {
    final dynamic rawImages = json['images'];
    final dynamic rawContributors = json['contributors'];

    final List<UploadSpeciesImageDraft> parsedImages = rawImages is List
        ? rawImages
              .whereType<Map>()
              .map(
                (Map<dynamic, dynamic> item) =>
                    UploadSpeciesImageDraft.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
              )
              .toList(growable: false)
        : <UploadSpeciesImageDraft>[];

    final List<UploadContributorDraft> parsedContributors =
        rawContributors is List
        ? rawContributors
              .whereType<Map>()
              .map(
                (Map<dynamic, dynamic> item) => UploadContributorDraft.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
        : <UploadContributorDraft>[];

    return UploadSpeciesFlowData(
      draftId: (json['draftId'] ?? '').toString().trim().isEmpty
          ? null
          : (json['draftId'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      family: (json['family'] ?? '').toString(),
      genus: (json['genus'] ?? '').toString(),
      scientificName: (json['scientificName'] ?? '').toString(),
      commonNames: () {
        final dynamic raw = json['commonNames'];
        if (raw is List) {
          return raw
              .map((dynamic e) => e.toString())
              .where((String s) => s.trim().isNotEmpty)
              .toList();
        }
        final String single = (json['commonName'] ?? '').toString().trim();
        return single.isNotEmpty ? <String>[single] : <String>[];
      }(),
      identificationConfidence:
          (json['identificationConfidence'] ?? 'Confirmed').toString(),
      endemicToPhilippines: json['endemicToPhilippines'] == true,
      leafType: (json['leafType'] ?? '').toString(),
      flowerColor: (json['flowerColor'] ?? '').toString(),
      floweringFromMonth: (json['floweringFromMonth'] ?? '').toString(),
      floweringToMonth: (json['floweringToMonth'] ?? '').toString(),
      observationDate: (json['observationDate'] ?? '').toString(),
      observationTime: (json['observationTime'] ?? '').toString(),
      collectionMethod: (json['collectionMethod'] ?? '').toString(),
      observationType: (json['observationType'] ?? '').toString(),
      voucherSpecimenCollected: json['voucherSpecimenCollected'] == true,
      numberLocated: (json['numberLocated'] ?? '').toString(),
      ethnobotanicalImportance: (json['ethnobotanicalImportance'] ?? '')
          .toString(),
      aestheticAppeal: (json['aestheticAppeal'] ?? '').toString(),
      cultivation: (json['cultivation'] ?? '').toString(),
      rarity: (json['rarity'] ?? '').toString(),
      culturalImportance: (json['culturalImportance'] ?? '').toString(),
      latitude: (json['latitude'] ?? '').toString(),
      longitude: (json['longitude'] ?? '').toString(),
      province: (json['province'] ?? '').toString(),
      municipality: (json['municipality'] ?? '').toString(),
      mountain: (json['mountain'] ?? '').toString(),
      altitude: (json['altitude'] ?? '').toString(),
      elevation: (json['elevation'] ?? '').toString(),
      habitatType: (json['habitatType'] ?? '').toString(),
      microHabitat: (json['microHabitat'] ?? '').toString(),
      images: parsedImages,
      contributors: parsedContributors,
      updatedAt:
          DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class UploadSpeciesFlowValidators {
  static String? validateSpeciesInformation(UploadSpeciesFlowData data) {
    if (data.location.trim().isEmpty) {
      return 'Location is required.';
    }

    final int? speciesCount = int.tryParse(data.numberLocated.trim());
    if (speciesCount == null || speciesCount <= 0) {
      return 'Number of species in the area must be greater than 0.';
    }

    return null;
  }

  static String? validateSightings(UploadSpeciesFlowData data) {
    final String latitudeRaw = data.latitude.trim();
    final String longitudeRaw = data.longitude.trim();

    if (latitudeRaw.isNotEmpty || longitudeRaw.isNotEmpty) {
      final double? lat = double.tryParse(latitudeRaw);
      final double? lng = double.tryParse(longitudeRaw);
      if (lat == null || lng == null) {
        return 'If coordinates are provided, both latitude and longitude must be valid numbers.';
      }
    }

    if (data.province.trim().isEmpty || data.municipality.trim().isEmpty) {
      return 'Province and Municipality are required.';
    }
    if (data.mountain.trim().isEmpty) {
      return 'Mountain is required.';
    }
    if (data.altitude.trim().isEmpty) {
      return 'Altitude is required.';
    }
    if (data.elevation.trim().isEmpty) {
      return 'Elevation is required.';
    }
    if (data.habitatType.trim().isEmpty) {
      return 'Habitat Type is required.';
    }
    if (data.microHabitat.trim().isEmpty) {
      return 'Micro Habitat is required.';
    }

    return null;
  }

  static String? validateSpeciesValues(UploadSpeciesFlowData data) {
    if (data.ethnobotanicalImportance.trim().isEmpty) {
      return 'Ethnobotanical Importance is required.';
    }
    if (data.aestheticAppeal.trim().isEmpty) {
      return 'Aesthetic Appeal is required.';
    }
    if (data.cultivation.trim().isEmpty) {
      return 'Cultivation is required.';
    }
    if (data.rarity.trim().isEmpty) {
      return 'Rarity is required.';
    }
    if (data.culturalImportance.trim().isEmpty) {
      return 'Cultural Importance is required.';
    }

    return null;
  }

  static String? validateImagesAndContributors(UploadSpeciesFlowData data) {
    if (data.images.isEmpty) {
      return 'Please upload at least one image.';
    }

    for (final UploadSpeciesImageDraft image in data.images) {
      if (image.photoCredit.trim().isEmpty) {
        return 'Photo credits are required for every image.';
      }
    }

    final List<UploadContributorDraft> usedContributors = data.contributors
        .where(
          (UploadContributorDraft contributor) =>
              contributor.name.trim().isNotEmpty ||
              contributor.position.trim().isNotEmpty,
        )
        .toList(growable: false);

    if (usedContributors.isEmpty) {
      return 'Add at least one contributor with name and position.';
    }

    for (final UploadContributorDraft contributor in usedContributors) {
      if (contributor.name.trim().isEmpty ||
          contributor.position.trim().isEmpty) {
        return 'Each contributor row must include both name and position.';
      }
    }

    return null;
  }

  static bool isReadyToUpload(UploadSpeciesFlowData data) {
    return validateSpeciesInformation(data) == null &&
        validateSightings(data) == null &&
        validateSpeciesValues(data) == null &&
        validateImagesAndContributors(data) == null;
  }
}

class UploadSpeciesDraftStore {
  static const String _draftsKey = 'upload_species_drafts_v1';

  static String _generatedDraftId(UploadSpeciesFlowData draft, int index) {
    final int updatedAtSeed = draft.updatedAt.microsecondsSinceEpoch;
    return '$updatedAtSeed-$index';
  }

  static Future<List<UploadSpeciesFlowData>> loadDrafts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encoded = prefs.getString(_draftsKey) ?? '';
    if (encoded.trim().isEmpty) {
      return <UploadSpeciesFlowData>[];
    }

    try {
      final dynamic decoded = jsonDecode(encoded);
      if (decoded is! List) {
        return <UploadSpeciesFlowData>[];
      }

      final List<UploadSpeciesFlowData> drafts = decoded
          .whereType<Map>()
          .map(
            (Map<dynamic, dynamic> item) =>
                UploadSpeciesFlowData.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: true);

      bool updatedMissingIds = false;
      for (int i = 0; i < drafts.length; i++) {
        final UploadSpeciesFlowData draft = drafts[i];
        final String existingId = (draft.draftId ?? '').trim();
        if (existingId.isEmpty) {
          draft.draftId = _generatedDraftId(draft, i);
          updatedMissingIds = true;
        }
      }

      drafts.sort(
        (UploadSpeciesFlowData a, UploadSpeciesFlowData b) =>
            b.updatedAt.compareTo(a.updatedAt),
      );

      if (updatedMissingIds) {
        await _persist(drafts);
      }

      return drafts;
    } catch (_) {
      return <UploadSpeciesFlowData>[];
    }
  }

  static Future<void> saveDraft(UploadSpeciesFlowData source) async {
    final List<UploadSpeciesFlowData> drafts = await loadDrafts();

    if (source.draftId == null || source.draftId!.trim().isEmpty) {
      source.draftId = DateTime.now().microsecondsSinceEpoch.toString();
    }

    source.updatedAt = DateTime.now();
    final UploadSpeciesFlowData toSave = source.copy();

    final int existingIndex = drafts.indexWhere(
      (UploadSpeciesFlowData draft) => draft.draftId == toSave.draftId,
    );

    if (existingIndex == -1) {
      drafts.insert(0, toSave);
    } else {
      drafts[existingIndex] = toSave;
    }

    await _persist(drafts);
  }

  static Future<void> deleteDraft(String draftId) async {
    final String normalizedId = draftId.trim();
    if (normalizedId.isEmpty) {
      return;
    }

    final List<UploadSpeciesFlowData> drafts = await loadDrafts();
    drafts.removeWhere(
      (UploadSpeciesFlowData draft) => draft.draftId == normalizedId,
    );

    await _persist(drafts);
  }

  static Future<void> deleteDraftData(UploadSpeciesFlowData source) async {
    final List<UploadSpeciesFlowData> drafts = await loadDrafts();
    if (drafts.isEmpty) {
      return;
    }

    final String normalizedId = (source.draftId ?? '').trim();
    if (normalizedId.isNotEmpty) {
      drafts.removeWhere(
        (UploadSpeciesFlowData draft) => draft.draftId == normalizedId,
      );
      await _persist(drafts);
      return;
    }

    final String sourceScientificName = source.scientificName.trim();
    final int sourceUpdatedAt = source.updatedAt.microsecondsSinceEpoch;
    final String sourceFirstImagePath = source.images.isNotEmpty
        ? source.images.first.path.trim()
        : '';

    drafts.removeWhere((UploadSpeciesFlowData draft) {
      final String draftScientificName = draft.scientificName.trim();
      final int draftUpdatedAt = draft.updatedAt.microsecondsSinceEpoch;
      final String draftFirstImagePath = draft.images.isNotEmpty
          ? draft.images.first.path.trim()
          : '';

      return draftScientificName == sourceScientificName &&
          draftUpdatedAt == sourceUpdatedAt &&
          draftFirstImagePath == sourceFirstImagePath;
    });

    await _persist(drafts);
  }

  static Future<void> clearAllDrafts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftsKey);
  }

  static Future<void> _persist(List<UploadSpeciesFlowData> drafts) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      drafts
          .map((UploadSpeciesFlowData draft) => draft.toJson())
          .toList(growable: false),
    );

    await prefs.setString(_draftsKey, encoded);
  }
}

class DraftSubmissionException implements Exception {
  DraftSubmissionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UploadSpeciesDraftSubmissionApi {
  UploadSpeciesDraftSubmissionApi({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  void dispose() {
    _client.close();
  }

  String _resolveApiBaseUrl() {
    const String fromDefine = String.fromEnvironment('API_BASE_URL');
    final String normalized = fromDefine.trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }

    if (kIsWeb) {
      return 'http://localhost:4000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://192.168.1.21:4000';
      default:
        return 'http://localhost:4000';
    }
  }

  String _extractFileName(String path) {
    final String normalized = path.replaceAll('\\', '/').trim();
    if (normalized.isEmpty) {
      return 'image.jpg';
    }

    final List<String> segments = normalized.split('/');
    final String candidate = segments.isNotEmpty ? segments.last.trim() : '';
    return candidate.isNotEmpty ? candidate : 'image.jpg';
  }

  String _inferContentType(String fileName) {
    final String lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'image/jpeg';
  }

  Future<Map<String, dynamic>> submitDraft(UploadSpeciesFlowData draft) async {
    if (kOfflineMode) {
      return const <String, dynamic>{
        'status': 'offline',
        'message': 'Offline mode — submission skipped.',
      };
    }
    final List<Map<String, dynamic>> imagePayloads = <Map<String, dynamic>>[];

    for (int index = 0; index < draft.images.length; index++) {
      final UploadSpeciesImageDraft image = draft.images[index];
      final String imagePath = image.path.trim();

      if (imagePath.isEmpty) {
        throw DraftSubmissionException(
          'Image ${index + 1} is missing a valid file path.',
        );
      }

      Uint8List imageBytes;
      try {
        imageBytes = await XFile(imagePath).readAsBytes();
      } catch (_) {
        throw DraftSubmissionException(
          'Unable to read image ${index + 1}. Open the draft and select that image again.',
        );
      }

      if (imageBytes.isEmpty) {
        throw DraftSubmissionException('Image ${index + 1} is empty.');
      }

      final String fileName = _extractFileName(imagePath);
      imagePayloads.add(<String, dynamic>{
        'fileName': fileName,
        'contentType': _inferContentType(fileName),
        'photoCredit': image.photoCredit.trim(),
        'base64Data': base64Encode(imageBytes),
      });
    }

    final Uri uri = Uri.parse('${_resolveApiBaseUrl()}/api/drafts/submit');
    final Map<String, dynamic> payload = <String, dynamic>{
      'draftId': (draft.draftId ?? '').trim(),
      'location': draft.location.trim(),
      'family': draft.family.trim(),
      'genus': draft.genus.trim(),
      'scientificName': draft.scientificName.trim(),
      'commonName': draft.commonName.trim(),
      'commonNames': draft.commonNames
          .where((String s) => s.trim().isNotEmpty)
          .toList(),
      'identificationConfidence': draft.identificationConfidence,
      'endemicToPhilippines': draft.endemicToPhilippines,
      'leafType': draft.leafType.trim(),
      'flowerColor': draft.flowerColor.trim(),
      'floweringFromMonth': draft.floweringFromMonth.trim(),
      'floweringToMonth': draft.floweringToMonth.trim(),
      'observationDate': draft.observationDate.trim(),
      'observationTime': draft.observationTime.trim(),
      'collectionMethod': draft.collectionMethod.trim(),
      'observationType': draft.observationType.trim(),
      'voucherSpecimenCollected': draft.voucherSpecimenCollected,
      'numberLocated': draft.numberLocated.trim(),
      'ethnobotanicalImportance': draft.ethnobotanicalImportance.trim(),
      'aestheticAppeal': draft.aestheticAppeal.trim(),
      'cultivation': draft.cultivation.trim(),
      'rarity': draft.rarity.trim(),
      'culturalImportance': draft.culturalImportance.trim(),
      'latitude': draft.latitude.trim(),
      'longitude': draft.longitude.trim(),
      'province': draft.province.trim(),
      'municipality': draft.municipality.trim(),
      'mountain': draft.mountain.trim(),
      'altitude': draft.altitude.trim(),
      'elevation': draft.elevation.trim(),
      'habitatType': draft.habitatType.trim(),
      'microHabitat': draft.microHabitat.trim(),
      'observedAt': draft.updatedAt.toIso8601String(),
      'images': imagePayloads,
      'contributors': draft.contributors
          .map(
            (UploadContributorDraft contributor) => <String, String>{
              'name': contributor.name.trim(),
              'position': contributor.position.trim(),
            },
          )
          .toList(growable: false),
    };

    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw DraftSubmissionException(
        'Draft submission timed out. Please check your network and try again.',
      );
    } catch (_) {
      throw DraftSubmissionException(
        'Unable to reach the API. Confirm API_BASE_URL and backend server status.',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode != 201) {
      if (decoded is Map && decoded['error'] != null) {
        throw DraftSubmissionException(decoded['error'].toString());
      }

      throw DraftSubmissionException(
        'Submission failed with status ${response.statusCode}.',
      );
    }

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    return <String, dynamic>{};
  }
}

class UploadSpeciesInformationScreen extends StatefulWidget {
  const UploadSpeciesInformationScreen({required this.flowData, super.key});

  final UploadSpeciesFlowData flowData;

  @override
  State<UploadSpeciesInformationScreen> createState() =>
      _UploadSpeciesInformationScreenState();
}

class _UploadSpeciesInformationScreenState
    extends State<UploadSpeciesInformationScreen> {
  late final UploadSpeciesFlowData _flowData;

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _familyController = TextEditingController();
  final TextEditingController _genusController = TextEditingController();
  final TextEditingController _scientificNameController =
      TextEditingController();
  final List<TextEditingController> _commonNameControllers =
      <TextEditingController>[];
  final TextEditingController _numberLocatedController =
      TextEditingController();

  static const int _maxCommonNames = 5;
  static const List<String> _confidenceOptions = <String>[
    'Confirmed',
    'Probable',
    'Unidentified',
  ];

  String _identificationConfidence = 'Confirmed';

  static const List<String> _collectionMethodOptions = <String>[
    'Transect',
    'Quadrat',
    'Opportunistic',
    'Random Survey',
  ];

  static const List<String> _observationTypeOptions = <String>[
    'Live Specimen',
    'Flowering',
    'Fruiting',
    'Dead Specimen',
    'Photographic Only',
  ];

  bool _endemicToPhilippines = true;
  bool _isResolvingLocation = false;
  DateTime? _observationDate;
  TimeOfDay? _observationTime;
  String? _selectedCollectionMethod;
  String? _selectedObservationType;
  bool _voucherSpecimenCollected = false;

  @override
  void initState() {
    super.initState();
    _flowData = widget.flowData;

    _locationController.text = _flowData.location;
    _familyController.text = _flowData.family;
    _genusController.text = _flowData.genus;
    _scientificNameController.text = _flowData.scientificName;
    final List<String> names = _flowData.commonNames.isNotEmpty
        ? _flowData.commonNames
        : <String>[''];
    for (final String name in names) {
      _commonNameControllers.add(TextEditingController(text: name));
    }
    _identificationConfidence = _flowData.identificationConfidence;
    _numberLocatedController.text = _flowData.numberLocated;

    _endemicToPhilippines = _flowData.endemicToPhilippines;
    _observationDate = _flowData.observationDate.isEmpty
        ? null
        : DateTime.tryParse(_flowData.observationDate);
    _observationTime = () {
      if (_flowData.observationTime.isEmpty) return null;
      final List<String> parts = _flowData.observationTime.split(':');
      if (parts.length >= 2) {
        final int? h = int.tryParse(parts[0]);
        final int? m = int.tryParse(parts[1]);
        if (h != null && m != null) return TimeOfDay(hour: h, minute: m);
      }
      return null;
    }();
    _selectedCollectionMethod = _flowData.collectionMethod.isEmpty
        ? null
        : _flowData.collectionMethod;
    _selectedObservationType = _flowData.observationType.isEmpty
        ? null
        : _flowData.observationType;
    _voucherSpecimenCollected = _flowData.voucherSpecimenCollected;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _familyController.dispose();
    _genusController.dispose();
    _scientificNameController.dispose();
    for (final TextEditingController c in _commonNameControllers) {
      c.dispose();
    }
    _numberLocatedController.dispose();
    super.dispose();
  }

  void _syncFlowDataFromForm() {
    _flowData.location = _locationController.text.trim();
    _flowData.family = _familyController.text.trim();
    _flowData.genus = _genusController.text.trim();
    _flowData.scientificName = _scientificNameController.text.trim();
    _flowData.commonNames = _commonNameControllers
        .map((TextEditingController c) => c.text.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
    _flowData.identificationConfidence = _identificationConfidence;
    _flowData.endemicToPhilippines = _endemicToPhilippines;
    _flowData.observationDate = _observationDate != null
        ? '${_observationDate!.year.toString().padLeft(4, '0')}-'
              '${_observationDate!.month.toString().padLeft(2, '0')}-'
              '${_observationDate!.day.toString().padLeft(2, '0')}'
        : '';
    _flowData.observationTime = _observationTime != null
        ? '${_observationTime!.hour.toString().padLeft(2, '0')}:'
              '${_observationTime!.minute.toString().padLeft(2, '0')}'
        : '';
    _flowData.collectionMethod = (_selectedCollectionMethod ?? '').trim();
    _flowData.observationType = (_selectedObservationType ?? '').trim();
    _flowData.voucherSpecimenCollected = _voucherSpecimenCollected;
    _flowData.numberLocated = _numberLocatedController.text.trim();
  }

  String _firstNonEmpty(Map<String, dynamic> address, List<String> keys) {
    for (final String key in keys) {
      final String value = (address[key] ?? '').toString().trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  Future<String> _resolveLocationLabel(Position position) async {
    try {
      final Uri uri =
          Uri.https('nominatim.openstreetmap.org', '/reverse', <String, String>{
            'format': 'jsonv2',
            'lat': position.latitude.toString(),
            'lon': position.longitude.toString(),
          });

      final http.Response response = await http.get(
        uri,
        headers: <String, String>{'User-Agent': 'bloom-mobile-upload/1.0'},
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final dynamic addressDynamic = decoded['address'];
          if (addressDynamic is Map) {
            final Map<String, dynamic> address = Map<String, dynamic>.from(
              addressDynamic,
            );
            final String municipality = _firstNonEmpty(address, <String>[
              'municipality',
              'city',
              'town',
              'village',
            ]);
            final String province = _firstNonEmpty(address, <String>[
              'province',
              'state',
              'region',
            ]);

            final String resolved = <String>[
              municipality,
              province,
            ].where((String value) => value.isNotEmpty).join(', ');

            if (resolved.isNotEmpty) {
              return resolved;
            }
          }
        }
      }
    } catch (_) {
      // Fall back to coordinates when reverse geocoding is unavailable.
    }

    return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
  }

  Future<void> _useGpsLocation() async {
    if (_isResolvingLocation) {
      return;
    }

    setState(() {
      _isResolvingLocation = true;
    });

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showValidationError('Enable location services to use GPS.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showValidationError('Location permission is required to use GPS.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showValidationError('Location permission is permanently denied.');
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final String resolvedLocation = await _resolveLocationLabel(position);

      if (!mounted) {
        return;
      }

      setState(() {
        _locationController.text = resolvedLocation;
      });
    } on Exception {
      if (mounted) {
        _showValidationError('Unable to get the current GPS location.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingLocation = false;
        });
      }
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openSpeciesSightingsForm() {
    _syncFlowDataFromForm();
    final String? validationMessage =
        UploadSpeciesFlowValidators.validateSpeciesInformation(_flowData);
    if (validationMessage != null) {
      _showValidationError(validationMessage);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UploadSpeciesSightingsScreen(flowData: _flowData),
      ),
    );
  }

  InputDecoration _fieldDecoration() {
    return _uploadInputDecoration();
  }

  Widget _dropdownField({
    required String hint,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      isDense: true,
      isExpanded: true,
      initialValue: value,
      items: options
          .map(
            (String option) =>
                DropdownMenuItem<String>(value: option, child: Text(option)),
          )
          .toList(growable: false),
      onChanged: onChanged,
      style: _uploadInputTextStyle,
      decoration: _fieldDecoration().copyWith(
        hintText: hint,
        hintStyle: _uploadHintTextStyle,
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: _uploadSectionTitleStyle);
  }

  Widget _fieldLabel(String text) {
    return Text(text, style: _uploadFieldLabelStyle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _UploadFormHeader(title: 'Upload New Species'),
              const SizedBox(height: 20),
              _sectionLabel('Species Information'),
              const SizedBox(height: 10),
              _fieldLabel('Location'),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: TextField(
                        controller: _locationController,
                        readOnly: true,
                        decoration: _fieldDecoration().copyWith(
                          hintText: 'Tap Use GPS to fill your current location',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: _isResolvingLocation ? null : _useGpsLocation,
                    style: TextButton.styleFrom(
                      foregroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 34),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: _lineColor, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _isResolvingLocation ? 'Locating...' : 'Use GPS',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _fieldLabel('Family'),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: TextField(
                        controller: _familyController,
                        decoration: _fieldDecoration(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _familyController.text = 'Unknown';
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 34),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: _lineColor, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Unknown',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _fieldLabel('Genus'),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: TextField(
                        controller: _genusController,
                        decoration: _fieldDecoration(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _genusController.text = 'Unknown';
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 34),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: _lineColor, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Unknown',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _fieldLabel('Scientific Name'),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: TextField(
                        controller: _scientificNameController,
                        decoration: _fieldDecoration(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _scientificNameController.text = 'Unknown';
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 34),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: _lineColor, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Unknown',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _fieldLabel('Common Name / Local Name / Indigenous Name'),
              const SizedBox(height: 4),
              ...List<Widget>.generate(_commonNameControllers.length, (int i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 34,
                          child: TextField(
                            controller: _commonNameControllers[i],
                            decoration: _fieldDecoration(),
                          ),
                        ),
                      ),
                      if (_commonNameControllers.length > 1) ...[
                        const SizedBox(width: 6),
                        InkResponse(
                          onTap: () {
                            setState(() {
                              _commonNameControllers[i].dispose();
                              _commonNameControllers.removeAt(i);
                            });
                          },
                          radius: 14,
                          child: const Icon(
                            Icons.remove_circle_outline,
                            size: 22,
                            color: _primaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              if (_commonNameControllers.length < _maxCommonNames)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _commonNameControllers.add(TextEditingController());
                      });
                    },
                    icon: const Icon(Icons.add, size: 18, color: _primaryColor),
                    label: const Text(
                      'Add another name',
                      style: TextStyle(fontSize: 12, color: _primaryColor),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              _fieldLabel('Identification Confidence'),
              const SizedBox(height: 4),
              RadioGroup<String>(
                groupValue: _identificationConfidence,
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _identificationConfidence = value;
                    });
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _confidenceOptions
                      .map((String option) {
                        return RadioListTile<String>(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          visualDensity: const VisualDensity(
                            horizontal: -4,
                            vertical: -4,
                          ),
                          title: Text(
                            option,
                            style: const TextStyle(
                              fontSize: 14,
                              color: _textColor,
                            ),
                          ),
                          value: option,
                          activeColor: _primaryColor,
                        );
                      })
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 8),
              _fieldLabel('Endemic to the Philippines'),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 236,
                  child: _EndemicToggle(
                    value: _endemicToPhilippines,
                    onChanged: (bool nextValue) {
                      setState(() {
                        _endemicToPhilippines = nextValue;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _sectionLabel('Observation / Collection Details'),
              const SizedBox(height: 10),
              _fieldLabel('Date of Observation'),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _observationDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _observationDate = picked;
                    });
                  }
                },
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: _lineColor),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _observationDate != null
                              ? '${_observationDate!.year.toString().padLeft(4, '0')}-'
                                    '${_observationDate!.month.toString().padLeft(2, '0')}-'
                                    '${_observationDate!.day.toString().padLeft(2, '0')}'
                              : 'Select date',
                          style: _observationDate != null
                              ? _uploadInputTextStyle
                              : _uploadHintTextStyle,
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: _primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _fieldLabel('Time'),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: _observationTime ?? TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _observationTime = picked;
                    });
                  }
                },
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: _lineColor),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _observationTime != null
                              ? _observationTime!.format(context)
                              : 'Select time',
                          style: _observationTime != null
                              ? _uploadInputTextStyle
                              : _uploadHintTextStyle,
                        ),
                      ),
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: _primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _fieldLabel('Collection Method'),
              const SizedBox(height: 4),
              _dropdownField(
                hint: 'Select collection method',
                value: _selectedCollectionMethod,
                options: _collectionMethodOptions,
                onChanged: (String? value) {
                  setState(() {
                    _selectedCollectionMethod = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              _fieldLabel('Observation Type'),
              const SizedBox(height: 4),
              _dropdownField(
                hint: 'Select observation type',
                value: _selectedObservationType,
                options: _observationTypeOptions,
                onChanged: (String? value) {
                  setState(() {
                    _selectedObservationType = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              _fieldLabel('Voucher Specimen Collected'),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 236,
                  child: _EndemicToggle(
                    value: _voucherSpecimenCollected,
                    onChanged: (bool v) {
                      setState(() {
                        _voucherSpecimenCollected = v;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _fieldLabel('Number of Species in this Area'),
              const SizedBox(height: 4),
              SizedBox(
                height: 34,
                child: TextField(
                  controller: _numberLocatedController,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration(),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: OutlinedButton(
                  onPressed: _openSpeciesSightingsForm,
                  style: _uploadActionButtonStyle(),
                  child: const Text(
                    'NEXT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UploadSpeciesValueScreen extends StatefulWidget {
  const UploadSpeciesValueScreen({required this.flowData, super.key});

  final UploadSpeciesFlowData flowData;

  @override
  State<UploadSpeciesValueScreen> createState() =>
      _UploadSpeciesValueScreenState();
}

class _UploadSpeciesValueScreenState extends State<UploadSpeciesValueScreen> {
  late final UploadSpeciesFlowData _flowData;

  static const List<String> _ethnobotanicalOptions = <String>[
    'Medicinal use',
    'Traditional remedy',
    'Food flavoring',
    'Ritual and ceremonial use',
    'No documented use',
  ];

  static const List<String> _aestheticAppealOptions = <String>[
    'Large vibrant blooms',
    'Distinctive petal pattern',
    'Fragrant flowers',
    'Elegant growth habit',
    'High ornamental value',
  ];

  static const List<String> _cultivationOptions = <String>[
    'Easy to cultivate',
    'Moderate care required',
    'Advanced care required',
    'Best in greenhouse conditions',
    'Suitable for home growers',
  ];

  static const List<String> _rarityOptions = <String>[
    'Common',
    'Uncommon',
    'Rare',
    'Very rare',
    'Critically rare',
  ];

  static const List<String> _culturalImportanceOptions = <String>[
    'Regional symbol species',
    'Used in local celebrations',
    'Important to indigenous knowledge',
    'Cultural heritage value',
    'No major cultural record',
  ];

  String? _selectedEthnobotanicalImportance;
  String? _selectedAestheticAppeal;
  String? _selectedCultivation;
  String? _selectedRarity;
  String? _selectedCulturalImportance;

  @override
  void initState() {
    super.initState();
    _flowData = widget.flowData;

    _selectedEthnobotanicalImportance =
        _flowData.ethnobotanicalImportance.trim().isEmpty
        ? null
        : _flowData.ethnobotanicalImportance.trim();
    _selectedAestheticAppeal = _flowData.aestheticAppeal.trim().isEmpty
        ? null
        : _flowData.aestheticAppeal.trim();
    _selectedCultivation = _flowData.cultivation.trim().isEmpty
        ? null
        : _flowData.cultivation.trim();
    _selectedRarity = _flowData.rarity.trim().isEmpty
        ? null
        : _flowData.rarity.trim();
    _selectedCulturalImportance = _flowData.culturalImportance.trim().isEmpty
        ? null
        : _flowData.culturalImportance.trim();
  }

  InputDecoration _fieldDecoration() {
    return _uploadInputDecoration();
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: _uploadSectionTitleStyle);
  }

  Widget _fieldLabel(String text) {
    return Text(text, style: _uploadFieldLabelStyle);
  }

  void _syncFlowDataFromForm() {
    _flowData.ethnobotanicalImportance =
        (_selectedEthnobotanicalImportance ?? '').trim();
    _flowData.aestheticAppeal = (_selectedAestheticAppeal ?? '').trim();
    _flowData.cultivation = (_selectedCultivation ?? '').trim();
    _flowData.rarity = (_selectedRarity ?? '').trim();
    _flowData.culturalImportance = (_selectedCulturalImportance ?? '').trim();
  }

  void _showNextPlaceholder() {
    _syncFlowDataFromForm();

    final String? validationMessage =
        UploadSpeciesFlowValidators.validateSpeciesValues(_flowData);
    if (validationMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationMessage)));
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UploadSpeciesImagesScreen(flowData: _flowData),
      ),
    );
  }

  List<String> _optionsWithExistingValue(
    List<String> options,
    String? selectedValue,
  ) {
    final String normalized = (selectedValue ?? '').trim();
    if (normalized.isEmpty || options.contains(normalized)) {
      return options;
    }

    return <String>[normalized, ...options];
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final List<String> resolvedOptions = _optionsWithExistingValue(
      options,
      value,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 4),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            final String? picked = await _showSearchablePicker(
              title: label,
              options: resolvedOptions,
              selectedValue: value,
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
          child: InputDecorator(
            isEmpty: (value ?? '').trim().isEmpty,
            decoration: _fieldDecoration().copyWith(
              hintText: hint,
              hintStyle: _uploadHintTextStyle,
              suffixIcon: const Icon(
                Icons.search_rounded,
                color: _mutedTextColor,
                size: 20,
              ),
            ),
            child: Text(
              (value ?? '').trim().isEmpty ? hint : value!.trim(),
              style: (value ?? '').trim().isEmpty
                  ? _uploadHintTextStyle
                  : _uploadInputTextStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Future<String?> _showSearchablePicker({
    required String title,
    required List<String> options,
    String? selectedValue,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        String query = '';
        List<String> filtered = options;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: 430,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (String value) {
                        setModalState(() {
                          query = value.trim().toLowerCase();
                          filtered = options
                              .where(
                                (String option) =>
                                    option.toLowerCase().contains(query),
                              )
                              .toList(growable: false);
                        });
                      },
                      decoration:
                          _uploadInputDecoration(
                            hintText: 'Search options...',
                          ).copyWith(
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: _mutedTextColor,
                            ),
                          ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'No matches found.',
                                style: TextStyle(
                                  color: _mutedTextColor,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder:
                                  (BuildContext context, int index) =>
                                      const Divider(
                                        height: 1,
                                        color: _lineColor,
                                      ),
                              itemBuilder: (BuildContext context, int index) {
                                final String option = filtered[index];
                                final bool isSelected =
                                    option.trim() ==
                                    (selectedValue ?? '').trim();

                                return ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  title: Text(
                                    option,
                                    style: const TextStyle(
                                      color: _textColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 18,
                                          color: _primaryColor,
                                        )
                                      : null,
                                  onTap: () =>
                                      Navigator.of(context).pop(option),
                                );
                              },
                            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _UploadFormHeader(title: 'Upload New Species'),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Species Value'),
                      const SizedBox(height: 12),
                      _buildDropdownField(
                        label: 'Ethnobotanical Importance',
                        hint: 'Select ethnobotanical importance',
                        value: _selectedEthnobotanicalImportance,
                        options: _ethnobotanicalOptions,
                        onChanged: (String? value) {
                          setState(() {
                            _selectedEthnobotanicalImportance = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _fieldLabel('Horticulture Value'),
                      const SizedBox(height: 6),
                      _buildDropdownField(
                        label: 'Aesthetic Appeal',
                        hint: 'Select aesthetic appeal',
                        value: _selectedAestheticAppeal,
                        options: _aestheticAppealOptions,
                        onChanged: (String? value) {
                          setState(() {
                            _selectedAestheticAppeal = value;
                          });
                        },
                      ),
                      const SizedBox(height: 6),
                      _buildDropdownField(
                        label: 'Cultivation',
                        hint: 'Select cultivation level',
                        value: _selectedCultivation,
                        options: _cultivationOptions,
                        onChanged: (String? value) {
                          setState(() {
                            _selectedCultivation = value;
                          });
                        },
                      ),
                      const SizedBox(height: 6),
                      _buildDropdownField(
                        label: 'Rarity',
                        hint: 'Select rarity level',
                        value: _selectedRarity,
                        options: _rarityOptions,
                        onChanged: (String? value) {
                          setState(() {
                            _selectedRarity = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildDropdownField(
                        label: 'Cultural Importance',
                        hint: 'Select cultural importance',
                        value: _selectedCulturalImportance,
                        options: _culturalImportanceOptions,
                        onChanged: (String? value) {
                          setState(() {
                            _selectedCulturalImportance = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: OutlinedButton(
                  onPressed: _showNextPlaceholder,
                  style: _uploadActionButtonStyle(),
                  child: const Text(
                    'NEXT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UploadSpeciesSightingsScreen extends StatefulWidget {
  const UploadSpeciesSightingsScreen({
    required this.flowData,
    this.flowTitle = 'Upload New Species',
    this.showSpeciesValueStep = true,
    super.key,
  });

  final UploadSpeciesFlowData flowData;
  final String flowTitle;
  final bool showSpeciesValueStep;

  @override
  State<UploadSpeciesSightingsScreen> createState() =>
      _UploadSpeciesSightingsScreenState();
}

class _UploadSpeciesSightingsScreenState
    extends State<UploadSpeciesSightingsScreen> {
  late final UploadSpeciesFlowData _flowData;

  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _municipalityController = TextEditingController();
  final TextEditingController _mountainController = TextEditingController();

  static const List<String> _altitudeOptions = <String>[
    '100 meters above sea level',
    '150 meters above sea level',
    '200 meters above sea level',
    '250 meters above sea level',
    '300 meters above sea level',
    '400 meters above sea level',
  ];

  static const List<String> _elevationOptions = <String>[
    '90 meters above sea level',
    '140 meters above sea level',
    '180 meters above sea level',
    '220 meters above sea level',
    '260 meters above sea level',
    '320 meters above sea level',
  ];

  static const List<String> _habitatTypeOptions = <String>[
    'Montane forest',
    'Lower montane forest',
    'Mossy forest',
    'Secondary forest edge',
    'Riparian forest',
    'Agroforest buffer zone',
  ];

  static const List<String> _microHabitatOptions = <String>[
    'Epiphytic on mossy branches',
    'Epiphytic on tree trunk',
    'Shaded understory branch',
    'Moist ravine slope',
    'Near stream canopy',
    'Open ridge with filtered light',
  ];

  String? _selectedAltitude;
  String? _selectedElevation;
  String? _selectedHabitatType;
  String? _selectedMicroHabitat;

  WebViewController? _sightingsMapController;
  bool _isMapReady = false;
  bool _mapLoadFailed = false;
  bool _isResolvingLocation = false;

  Timer? _reverseGeocodeDebounce;
  String _lastLookupKey = '';

  bool get _supportsLeafletWebView {
    if (kIsWeb) {
      return false;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      default:
        return false;
    }
  }

  String get _platformLabel {
    if (kIsWeb) {
      return 'Web';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }

  @override
  void initState() {
    super.initState();
    _flowData = widget.flowData;

    _latitudeController.text = _flowData.latitude;
    _longitudeController.text = _flowData.longitude;
    _provinceController.text = _flowData.province;
    _municipalityController.text = _flowData.municipality;
    _mountainController.text = _flowData.mountain;
    _selectedAltitude = _flowData.altitude.trim().isEmpty
        ? null
        : _flowData.altitude.trim();
    _selectedElevation = _flowData.elevation.trim().isEmpty
        ? null
        : _flowData.elevation.trim();
    _selectedHabitatType = _flowData.habitatType.trim().isEmpty
        ? null
        : _flowData.habitatType.trim();
    _selectedMicroHabitat = _flowData.microHabitat.trim().isEmpty
        ? null
        : _flowData.microHabitat.trim();

    _latitudeController.addListener(_scheduleReverseGeocodeLookup);
    _longitudeController.addListener(_scheduleReverseGeocodeLookup);

    if (_provinceController.text.trim().isEmpty ||
        _municipalityController.text.trim().isEmpty) {
      _scheduleReverseGeocodeLookup();
    }

    if (_supportsLeafletWebView) {
      _sightingsMapController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(_appBackgroundColor)
        ..setNavigationDelegate(
          NavigationDelegate(
            onWebResourceError: (WebResourceError _) {
              if (!mounted || _isMapReady) {
                return;
              }

              setState(() {
                _mapLoadFailed = true;
              });
            },
          ),
        )
        ..addJavaScriptChannel(
          'SightingsMapChannel',
          onMessageReceived: _onMapEventMessage,
        )
        ..loadHtmlString(
          _buildSightingsLeafletHtml(),
          baseUrl: 'https://tile.openstreetmap.org/',
        );

      Future<void>.delayed(const Duration(seconds: 8), () {
        if (!mounted || _isMapReady) {
          return;
        }

        setState(() {
          _mapLoadFailed = true;
        });
      });
    }
  }

  @override
  void dispose() {
    _reverseGeocodeDebounce?.cancel();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _provinceController.dispose();
    _municipalityController.dispose();
    _mountainController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration([String? hintText]) {
    return _uploadInputDecoration(hintText: hintText);
  }

  Widget _fieldLabel(String text) {
    return Text(text, style: _uploadFieldLabelStyle);
  }

  double? _tryParseCoordinate(String value) {
    return double.tryParse(value.trim());
  }

  String _firstNonEmpty(Map<String, dynamic> address, List<String> keys) {
    for (final String key in keys) {
      final String value = (address[key] ?? '').toString().trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  void _scheduleReverseGeocodeLookup() {
    _reverseGeocodeDebounce?.cancel();

    final double? lat = _tryParseCoordinate(_latitudeController.text);
    final double? lng = _tryParseCoordinate(_longitudeController.text);

    if (lat == null || lng == null) {
      return;
    }

    final String lookupKey =
        '${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)}';
    if (lookupKey == _lastLookupKey) {
      return;
    }

    _reverseGeocodeDebounce = Timer(const Duration(milliseconds: 700), () {
      _reverseGeocode(lat: lat, lng: lng, lookupKey: lookupKey);
    });
  }

  Future<void> _reverseGeocode({
    required double lat,
    required double lng,
    required String lookupKey,
  }) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isResolvingLocation = true;
    });

    try {
      final Uri uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': lat.toString(),
        'lon': lng.toString(),
      });

      final http.Response response = await http.get(
        uri,
        headers: <String, String>{'User-Agent': 'bloom-mobile-upload/1.0'},
      );

      if (response.statusCode != 200) {
        return;
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final dynamic addressDynamic = decoded['address'];
      if (addressDynamic is! Map) {
        return;
      }

      final Map<String, dynamic> address = Map<String, dynamic>.from(
        addressDynamic,
      );

      final String province = _firstNonEmpty(address, <String>[
        'province',
        'state',
        'region',
      ]);
      final String municipality = _firstNonEmpty(address, <String>[
        'municipality',
        'city',
        'town',
        'village',
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        if (province.isNotEmpty) {
          _provinceController.text = province;
        }
        if (municipality.isNotEmpty) {
          _municipalityController.text = municipality;
        }
      });
    } catch (_) {
      // Keep manual location input available when reverse geocoding fails.
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingLocation = false;
          _lastLookupKey = lookupKey;
        });
      }
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    String? hintText,
  }) {
    return SizedBox(
      height: 34,
      child: TextField(
        controller: controller,
        decoration: _fieldDecoration(hintText),
      ),
    );
  }

  List<String> _optionsWithExistingValue(
    List<String> options,
    String? selectedValue,
  ) {
    final String normalized = (selectedValue ?? '').trim();
    if (normalized.isEmpty || options.contains(normalized)) {
      return options;
    }

    return <String>[normalized, ...options];
  }

  Future<String?> _showSearchablePicker({
    required String title,
    required List<String> options,
    String? selectedValue,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        String query = '';
        List<String> filtered = options;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: 430,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (String value) {
                        setModalState(() {
                          query = value.trim().toLowerCase();
                          filtered = options
                              .where(
                                (String option) =>
                                    option.toLowerCase().contains(query),
                              )
                              .toList(growable: false);
                        });
                      },
                      decoration:
                          _uploadInputDecoration(
                            hintText: 'Search options...',
                          ).copyWith(
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: _mutedTextColor,
                            ),
                          ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'No matches found.',
                                style: TextStyle(
                                  color: _mutedTextColor,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder:
                                  (BuildContext context, int index) =>
                                      const Divider(
                                        height: 1,
                                        color: _lineColor,
                                      ),
                              itemBuilder: (BuildContext context, int index) {
                                final String option = filtered[index];
                                final bool isSelected =
                                    option.trim() ==
                                    (selectedValue ?? '').trim();

                                return ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  title: Text(
                                    option,
                                    style: const TextStyle(
                                      color: _textColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 18,
                                          color: _primaryColor,
                                        )
                                      : null,
                                  onTap: () =>
                                      Navigator.of(context).pop(option),
                                );
                              },
                            ),
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

  Widget _buildSearchableDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final List<String> resolvedOptions = _optionsWithExistingValue(
      options,
      value,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 4),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            final String? picked = await _showSearchablePicker(
              title: label,
              options: resolvedOptions,
              selectedValue: value,
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
          child: InputDecorator(
            isEmpty: (value ?? '').trim().isEmpty,
            decoration: _uploadInputDecoration(hintText: hint).copyWith(
              suffixIcon: const Icon(
                Icons.search_rounded,
                color: _mutedTextColor,
                size: 20,
              ),
            ),
            child: Text(
              (value ?? '').trim().isEmpty ? hint : value!.trim(),
              style: (value ?? '').trim().isEmpty
                  ? _uploadHintTextStyle
                  : _uploadInputTextStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  void _onMapEventMessage(JavaScriptMessage message) {
    bool didDrag = false;
    bool didLoad = false;
    bool didError = false;
    double? draggedLat;
    double? draggedLng;

    try {
      final dynamic payload = jsonDecode(message.message);
      if (payload is Map) {
        final Map<String, dynamic> event = Map<String, dynamic>.from(payload);

        draggedLat = double.tryParse((event['lat'] ?? '').toString());
        draggedLng = double.tryParse((event['lng'] ?? '').toString());

        didDrag = event['type'] == 'pin_dragged';
        didLoad = event['type'] == 'map_ready';
        didError = event['type'] == 'map_error';
      }
    } catch (_) {
      didDrag = message.message == 'pin_dragged';
      didLoad = message.message == 'map_ready';
      didError = message.message == 'map_error';
    }

    if (didLoad && mounted && (!_isMapReady || _mapLoadFailed)) {
      setState(() {
        _isMapReady = true;
        _mapLoadFailed = false;
      });
    }

    if (didError && mounted && !_mapLoadFailed) {
      setState(() {
        _isMapReady = false;
        _mapLoadFailed = true;
      });
    }

    if (didDrag && mounted) {
      setState(() {
        if (draggedLat != null) {
          _latitudeController.text = draggedLat.toStringAsFixed(6);
        }
        if (draggedLng != null) {
          _longitudeController.text = draggedLng.toStringAsFixed(6);
        }
      });

      _scheduleReverseGeocodeLookup();
    }
  }

  void _syncFlowDataFromForm() {
    _flowData.latitude = _latitudeController.text.trim();
    _flowData.longitude = _longitudeController.text.trim();
    _flowData.province = _provinceController.text.trim();
    _flowData.municipality = _municipalityController.text.trim();
    _flowData.mountain = _mountainController.text.trim();
    _flowData.altitude = (_selectedAltitude ?? '').trim();
    _flowData.elevation = (_selectedElevation ?? '').trim();
    _flowData.habitatType = (_selectedHabitatType ?? '').trim();
    _flowData.microHabitat = (_selectedMicroHabitat ?? '').trim();
  }

  void _showNextPlaceholder() {
    _syncFlowDataFromForm();

    final String? validationMessage =
        UploadSpeciesFlowValidators.validateSightings(_flowData);
    if (validationMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationMessage)));
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UploadSpeciesMorphologyScreen(
          flowData: _flowData,
          showSpeciesValueStep: widget.showSpeciesValueStep,
        ),
      ),
    );
  }

  void _reloadMap() {
    final WebViewController? controller = _sightingsMapController;
    if (controller == null) {
      return;
    }

    setState(() {
      _isMapReady = false;
      _mapLoadFailed = false;
    });

    controller.loadHtmlString(
      _buildSightingsLeafletHtml(),
      baseUrl: 'https://tile.openstreetmap.org/',
    );

    Future<void>.delayed(const Duration(seconds: 8), () {
      if (!mounted || _isMapReady) {
        return;
      }

      setState(() {
        _mapLoadFailed = true;
      });
    });
  }

  String get _fallbackMapPreviewUrl {
    const String lat = '5.9295';
    const String lng = '125.0800';
    return 'https://staticmap.openstreetmap.de/staticmap.php?center=$lat,$lng&zoom=12&size=900x500&markers=$lat,$lng,red-pushpin';
  }

  String _buildSightingsLeafletHtml() {
    const double defaultLat = 5.9295;
    const double defaultLng = 125.0800;

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  <style>
    html, body, #map {
      width: 100%;
      height: 100%;
      margin: 0;
      padding: 0;
      background: #111a12;
    }

    .leaflet-control-attribution {
      font-size: 9px;
    }
  </style>
</head>
<body>
  <div id="map"></div>
  <script>
    const center = [$defaultLat, $defaultLng];
    const leafletCssUrls = [
      'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css',
      'https://cdn.jsdelivr.net/npm/leaflet@1.9.4/dist/leaflet.css'
    ];
    const leafletJsUrls = [
      'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js',
      'https://cdn.jsdelivr.net/npm/leaflet@1.9.4/dist/leaflet.js'
    ];

    function notify(type, extra) {
      const payload = JSON.stringify(Object.assign({ type }, extra || {}));

      if (window.SightingsMapChannel && window.SightingsMapChannel.postMessage) {
        window.SightingsMapChannel.postMessage(payload);
      }
    }

    function loadCss(url) {
      return new Promise((resolve, reject) => {
        const link = document.createElement('link');
        link.rel = 'stylesheet';
        link.href = url;
        link.onload = () => resolve(true);
        link.onerror = () => reject(new Error('css_failed'));
        document.head.appendChild(link);
      });
    }

    function loadScript(url) {
      return new Promise((resolve, reject) => {
        const script = document.createElement('script');
        script.src = url;
        script.onload = () => resolve(true);
        script.onerror = () => reject(new Error('script_failed'));
        document.head.appendChild(script);
      });
    }

    async function ensureLeaflet() {
      let cssLoaded = false;
      for (const cssUrl of leafletCssUrls) {
        try {
          await loadCss(cssUrl);
          cssLoaded = true;
          break;
        } catch (_) {}
      }

      let jsLoaded = false;
      for (const jsUrl of leafletJsUrls) {
        try {
          await loadScript(jsUrl);
          if (window.L) {
            jsLoaded = true;
            break;
          }
        } catch (_) {}
      }

      return cssLoaded && jsLoaded && !!window.L;
    }

    function initMap() {
      const map = L.map('map', {
        preferCanvas: true,
        zoomControl: true
      }).setView(center, 13);

      const tileUrls = [
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png'
      ];

      let activeTileIndex = 0;
      let tiles;
      let readySent = false;

      function markReady() {
        if (readySent) {
          return;
        }

        readySent = true;
        notify('map_ready');
      }

      function mountTiles() {
        if (tiles) {
          map.removeLayer(tiles);
        }

        tiles = L.tileLayer(tileUrls[activeTileIndex], {
          maxZoom: 19,
          attribution: '&copy; OpenStreetMap contributors'
        }).addTo(map);

        tiles.on('load', markReady);

        tiles.on('tileerror', () => {
          if (readySent) {
            return;
          }

          if (activeTileIndex < tileUrls.length - 1) {
            activeTileIndex += 1;
            mountTiles();
            return;
          }

          notify('map_error', { reason: 'tile_load_failed' });
        });
      }

      mountTiles();

      setTimeout(() => {
        if (!readySent) {
          notify('map_error', { reason: 'map_ready_timeout' });
        }
      }, 9000);

      const marker = L.marker(center, {
        draggable: true,
        autoPan: true,
        icon: L.divIcon({
          className: '',
          html: '<div style="font-size:30px;line-height:1;transform:translate(-2px,-12px);">📍</div>',
          iconSize: [24, 24],
          iconAnchor: [12, 24]
        })
      }).addTo(map);

      marker.on('dragend', (event) => {
        const latlng = event.target.getLatLng();
        notify('pin_dragged', {
          lat: latlng.lat,
          lng: latlng.lng
        });
      });

      window.addEventListener('error', () => {
        if (!readySent) {
          notify('map_error', { reason: 'javascript_error' });
        }
      });

      L.control.scale({ imperial: false }).addTo(map);
    }

    async function init() {
      const leafletReady = await ensureLeaflet();

      if (!leafletReady) {
        notify('map_error', { reason: 'leaflet_load_failed' });
        return;
      }

      initMap();
    }

    init();
  </script>
</body>
</html>
''';
  }

  Widget _buildMapCard() {
    final bool canRenderLeaflet =
        _supportsLeafletWebView && _sightingsMapController != null;

    final bool showFallbackPreview = canRenderLeaflet && _mapLoadFailed;
    final bool showLoadingIndicator =
        canRenderLeaflet && !_isMapReady && !_mapLoadFailed;

    return Container(
      width: double.infinity,
      height: 284,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lineColor, width: 1.4),
      ),
      child: canRenderLeaflet
          ? Stack(
              children: [
                Positioned.fill(
                  child: WebViewWidget(controller: _sightingsMapController!),
                ),
                if (showFallbackPreview)
                  Positioned.fill(
                    child: Container(
                      color: _appBackgroundColor,
                      child: Column(
                        children: [
                          Expanded(
                            child: Image.network(
                              _fallbackMapPreviewUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (
                                    BuildContext context,
                                    Object error,
                                    StackTrace? stackTrace,
                                  ) {
                                    return const DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: _surfaceTintColor,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.map_outlined,
                                          color: _mutedTextColor,
                                          size: 44,
                                        ),
                                      ),
                                    );
                                  },
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            color: _surfaceTintColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Map failed to load. Check internet and tap reload.',
                                    style: TextStyle(
                                      color: _textColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _reloadMap,
                                  child: const Text(
                                    'Reload',
                                    style: TextStyle(
                                      color: _primaryColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (showLoadingIndicator)
                  const Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xAA111A12),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xCC1E4F70),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Drag the pin to set coordinates',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Container(
              color: _surfaceTintColor,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.map_outlined,
                    color: _primarySoftColor,
                    size: 30,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Leaflet map is not supported on this platform.',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current platform: $_platformLabel',
                    style: const TextStyle(
                      color: _mutedTextColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildSightingDetailsForm() {
    return <Widget>[
      const SizedBox(height: 10),
      _buildSearchableDropdownField(
        label: 'Altitude',
        hint: 'Select altitude',
        value: _selectedAltitude,
        options: _altitudeOptions,
        onChanged: (String? value) {
          setState(() {
            _selectedAltitude = value;
          });
        },
      ),
      const SizedBox(height: 8),
      _buildSearchableDropdownField(
        label: 'Elevation',
        hint: 'Select elevation',
        value: _selectedElevation,
        options: _elevationOptions,
        onChanged: (String? value) {
          setState(() {
            _selectedElevation = value;
          });
        },
      ),
      const SizedBox(height: 8),
      _buildSearchableDropdownField(
        label: 'Habitat Type',
        hint: 'Select habitat type',
        value: _selectedHabitatType,
        options: _habitatTypeOptions,
        onChanged: (String? value) {
          setState(() {
            _selectedHabitatType = value;
          });
        },
      ),
      const SizedBox(height: 8),
      _buildSearchableDropdownField(
        label: 'Micro Habitat',
        hint: 'Select micro habitat',
        value: _selectedMicroHabitat,
        options: _microHabitatOptions,
        onChanged: (String? value) {
          setState(() {
            _selectedMicroHabitat = value;
          });
        },
      ),
      const SizedBox(height: 24),
      Center(
        child: OutlinedButton(
          onPressed: _showNextPlaceholder,
          style: _uploadActionButtonStyle(),
          child: const Text(
            'NEXT',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildPostMapWidgets() {
    return _buildSightingDetailsForm();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> content = <Widget>[
      _UploadFormHeader(title: widget.flowTitle),
      const SizedBox(height: 20),
      const Text('Species Sightings', style: _uploadSectionTitleStyle),
      const SizedBox(height: 12),
      _fieldLabel('Coordinates'),
      const SizedBox(height: 2),
      const Text(
        'Optional. Enter both values to auto-fill location.',
        style: TextStyle(
          fontSize: 11,
          fontStyle: FontStyle.italic,
          color: _mutedTextColor,
        ),
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(
            child: _buildField(
              controller: _latitudeController,
              hintText: 'Latitude',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildField(
              controller: _longitudeController,
              hintText: 'Longitude',
            ),
          ),
        ],
      ),
      if (_isResolvingLocation)
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            'Resolving location from coordinates...',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: _mutedTextColor,
            ),
          ),
        ),
      const SizedBox(height: 10),
      _fieldLabel('Location'),
      const SizedBox(height: 4),
      _buildField(controller: _provinceController, hintText: 'Province'),
      const SizedBox(height: 6),
      _buildField(
        controller: _municipalityController,
        hintText: 'Municipality',
      ),
      const SizedBox(height: 6),
      _buildField(controller: _mountainController, hintText: 'Mountain'),
      const SizedBox(height: 10),
      _fieldLabel('Map'),
      const SizedBox(height: 8),
      _buildMapCard(),
    ];

    content.addAll(_buildPostMapWidgets());

    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content,
          ),
        ),
      ),
    );
  }
}

class UploadSpeciesMorphologyScreen extends StatefulWidget {
  const UploadSpeciesMorphologyScreen({
    required this.flowData,
    this.showSpeciesValueStep = true,
    super.key,
  });

  final UploadSpeciesFlowData flowData;
  final bool showSpeciesValueStep;

  @override
  State<UploadSpeciesMorphologyScreen> createState() =>
      _UploadSpeciesMorphologyScreenState();
}

class _UploadSpeciesMorphologyScreenState
    extends State<UploadSpeciesMorphologyScreen> {
  late final UploadSpeciesFlowData _flowData;

  static const List<String> _leafTypeOptions = <String>[
    'Linear',
    'Ovate',
    'Elliptical',
    'Oblong',
    'Cordate',
    'Lanceolate',
    'Acicular',
    'Reniform',
    'Orbicular',
    'Sagittate',
    'Hastate',
    'Lyrate',
    'Spatulate',
    'Rhomboid',
    'Oblique',
    'Cuneate',
  ];

  static const List<String> _flowerColorOptions = <String>[
    'White',
    'Cream',
    'Yellow',
    'Orange',
    'Pink',
    'Purple',
    'Red',
    'Green',
    'Brown',
    'Multicolor',
  ];

  static const List<String> _monthOptions = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String? _selectedLeafType;
  String? _selectedFlowerColor;
  String? _selectedFloweringFromMonth;
  String? _selectedFloweringToMonth;

  @override
  void initState() {
    super.initState();
    _flowData = widget.flowData;
    _selectedLeafType = _flowData.leafType.trim().isEmpty
        ? null
        : _flowData.leafType;
    _selectedFlowerColor = _flowData.flowerColor.trim().isEmpty
        ? null
        : _flowData.flowerColor;
    _selectedFloweringFromMonth = _flowData.floweringFromMonth.trim().isEmpty
        ? null
        : _flowData.floweringFromMonth;
    _selectedFloweringToMonth = _flowData.floweringToMonth.trim().isEmpty
        ? null
        : _flowData.floweringToMonth;
  }

  void _syncFlowDataFromForm() {
    _flowData.leafType = (_selectedLeafType ?? '').trim();
    _flowData.flowerColor = (_selectedFlowerColor ?? '').trim();
    _flowData.floweringFromMonth = (_selectedFloweringFromMonth ?? '').trim();
    _flowData.floweringToMonth = (_selectedFloweringToMonth ?? '').trim();
  }

  void _openNextStep() {
    _syncFlowDataFromForm();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => widget.showSpeciesValueStep
            ? UploadSpeciesValueScreen(flowData: _flowData)
            : UploadSpeciesImagesScreen(flowData: _flowData),
      ),
    );
  }

  InputDecoration _fieldDecoration() => _uploadInputDecoration();

  Widget _dropdownField({
    required String hint,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      isDense: true,
      isExpanded: true,
      initialValue: value,
      items: options
          .map(
            (String option) =>
                DropdownMenuItem<String>(value: option, child: Text(option)),
          )
          .toList(growable: false),
      onChanged: onChanged,
      style: _uploadInputTextStyle,
      decoration: _fieldDecoration().copyWith(
        hintText: hint,
        hintStyle: _uploadHintTextStyle,
      ),
    );
  }

  Widget _sectionLabel(String text) =>
      Text(text, style: _uploadSectionTitleStyle);

  Widget _fieldLabel(String text) => Text(text, style: _uploadFieldLabelStyle);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _UploadFormHeader(title: 'Upload New Species'),
              const SizedBox(height: 20),
              _sectionLabel('Morphological Characteristics'),
              const SizedBox(height: 10),
              _fieldLabel('Leaf Type'),
              const SizedBox(height: 4),
              _dropdownField(
                hint: 'Select one leaf type',
                value: _selectedLeafType,
                options: _leafTypeOptions,
                onChanged: (String? value) {
                  setState(() {
                    _selectedLeafType = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              _fieldLabel('Flower Color'),
              const SizedBox(height: 4),
              _dropdownField(
                hint: 'Select one flower color',
                value: _selectedFlowerColor,
                options: _flowerColorOptions,
                onChanged: (String? value) {
                  setState(() {
                    _selectedFlowerColor = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              _fieldLabel('Flowering Season'),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    'From',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _dropdownField(
                      hint: 'Month',
                      value: _selectedFloweringFromMonth,
                      options: _monthOptions,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedFloweringFromMonth = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'to',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _dropdownField(
                      hint: 'Month',
                      value: _selectedFloweringToMonth,
                      options: _monthOptions,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedFloweringToMonth = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: OutlinedButton(
                  onPressed: _openNextStep,
                  style: _uploadActionButtonStyle(),
                  child: const Text(
                    'NEXT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UploadSpeciesImagesScreen extends StatefulWidget {
  const UploadSpeciesImagesScreen({required this.flowData, super.key});

  final UploadSpeciesFlowData flowData;

  @override
  State<UploadSpeciesImagesScreen> createState() =>
      _UploadSpeciesImagesScreenState();
}

class _ContributorFormRow {
  _ContributorFormRow({String name = '', this.position = ''})
    : nameController = TextEditingController(text: name);

  final TextEditingController nameController;
  String position;

  bool get hasAnyInput =>
      nameController.text.trim().isNotEmpty || position.trim().isNotEmpty;

  bool get isComplete =>
      nameController.text.trim().isNotEmpty && position.trim().isNotEmpty;

  UploadContributorDraft toDraft() {
    return UploadContributorDraft(
      name: nameController.text.trim(),
      position: position.trim(),
    );
  }

  void dispose() {
    nameController.dispose();
  }
}

class _UploadSpeciesImagesScreenState extends State<UploadSpeciesImagesScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  static const int _maxImageBytes = 5 * 1024 * 1024;
  static const List<String> _contributorPositions = <String>[
    'Principal Investigator/Lead Researcher',
    'Field Biologist/Botanist',
    'Taxonomist/Plant Identifier',
    'Conservationist',
    'Research Assistants/Field Assistants',
    'Photographer',
  ];

  late final UploadSpeciesFlowData _flowData;

  final List<UploadSpeciesImageDraft> _images = <UploadSpeciesImageDraft>[];
  final Map<String, Uint8List> _imageBytesCache = <String, Uint8List>{};
  final List<_ContributorFormRow> _contributors = <_ContributorFormRow>[];

  bool _isPickingImage = false;
  bool _isSavingDraft = false;

  @override
  void initState() {
    super.initState();
    _flowData = widget.flowData;

    _images.addAll(
      _flowData.images
          .map(
            (UploadSpeciesImageDraft image) => UploadSpeciesImageDraft(
              path: image.path,
              sizeBytes: image.sizeBytes,
              photoCredit: image.photoCredit,
            ),
          )
          .toList(growable: false),
    );

    for (final UploadSpeciesImageDraft image in _images) {
      _loadPreviewForPath(image.path);
    }

    if (_flowData.contributors.isEmpty) {
      _contributors.add(_ContributorFormRow());
    } else {
      for (final UploadContributorDraft contributor in _flowData.contributors) {
        _contributors.add(
          _ContributorFormRow(
            name: contributor.name,
            position: contributor.position,
          ),
        );
      }
      _ensureTrailingContributorRow();
    }
  }

  @override
  void dispose() {
    for (final _ContributorFormRow row in _contributors) {
      row.dispose();
    }
    super.dispose();
  }

  String _formatFileSize(int bytes) {
    final double mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(2)} MB';
  }

  void _ensureTrailingContributorRow() {
    if (_contributors.isEmpty) {
      _contributors.add(_ContributorFormRow());
      return;
    }

    if (_contributors.last.hasAnyInput) {
      _contributors.add(_ContributorFormRow());
    }
  }

  Future<void> _loadPreviewForPath(String path) async {
    if (_imageBytesCache.containsKey(path)) {
      return;
    }

    try {
      final Uint8List bytes = await XFile(path).readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _imageBytesCache[path] = bytes;
      });
    } catch (_) {
      // Some paths may not be readable later; keep placeholder preview.
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_isPickingImage) {
      return;
    }

    setState(() {
      _isPickingImage = true;
    });

    try {
      final List<XFile> pickedImages = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 2048,
      );

      if (pickedImages.isEmpty) {
        return;
      }

      int skippedOverLimit = 0;
      int addedCount = 0;

      for (final XFile pickedImage in pickedImages) {
        final bool alreadyExists = _images.any(
          (UploadSpeciesImageDraft image) => image.path == pickedImage.path,
        );
        if (alreadyExists) {
          continue;
        }

        final Uint8List imageBytes = await pickedImage.readAsBytes();
        if (imageBytes.lengthInBytes > _maxImageBytes) {
          skippedOverLimit += 1;
          continue;
        }

        _images.add(
          UploadSpeciesImageDraft(
            path: pickedImage.path,
            sizeBytes: imageBytes.lengthInBytes,
          ),
        );
        _imageBytesCache[pickedImage.path] = imageBytes;
        addedCount += 1;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _ensureTrailingContributorRow();
      });

      if (skippedOverLimit > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$skippedOverLimit image(s) exceeded 5 MB after compression and were skipped.',
            ),
          ),
        );
      } else if (addedCount > 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$addedCount image(s) added.')));
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open gallery right now.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  void _removeImageAt(int index) {
    if (index < 0 || index >= _images.length) {
      return;
    }

    setState(() {
      _imageBytesCache.remove(_images[index].path);
      _images.removeAt(index);
    });
  }

  void _syncFlowDataFromForm({required bool includeIncompleteContributors}) {
    _flowData.images = _images
        .map(
          (UploadSpeciesImageDraft image) => UploadSpeciesImageDraft(
            path: image.path,
            sizeBytes: image.sizeBytes,
            photoCredit: image.photoCredit,
          ),
        )
        .toList(growable: false);

    final Iterable<_ContributorFormRow> selectedRows =
        includeIncompleteContributors
        ? _contributors.where((row) => row.hasAnyInput)
        : _contributors.where((row) => row.isComplete);

    _flowData.contributors = selectedRows
        .map((row) => row.toDraft())
        .toList(growable: false);
  }

  Future<void> _saveDraft() async {
    if (_isSavingDraft) {
      return;
    }

    setState(() {
      _isSavingDraft = true;
    });

    try {
      _syncFlowDataFromForm(includeIncompleteContributors: true);
      await UploadSpeciesDraftStore.saveDraft(_flowData);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved. You can upload it later.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save draft right now.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingDraft = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _UploadFormHeader(title: 'Upload New Species'),
              const SizedBox(height: 20),
              const Text('Upload Images', style: _uploadSectionTitleStyle),
              const SizedBox(height: 6),
              const Text(
                'Select multiple images. Gallery import uses compression and each file is capped at 5 MB.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: _mutedTextColor,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _isPickingImage ? null : _pickImageFromGallery,
                  style: _uploadActionButtonStyle(),
                  icon: _isPickingImage
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add Images'),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_images.isEmpty)
                        Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _lineColor, width: 1.2),
                          ),
                          child: const Center(
                            child: Text(
                              'No images selected yet.',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: _mutedTextColor,
                              ),
                            ),
                          ),
                        ),
                      for (int index = 0; index < _images.length; index++) ...[
                        if (index > 0) const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: _surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _lineColor, width: 1.1),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 84,
                                      height: 84,
                                      child:
                                          _imageBytesCache[_images[index]
                                                  .path] !=
                                              null
                                          ? Image.memory(
                                              _imageBytesCache[_images[index]
                                                  .path]!,
                                              fit: BoxFit.cover,
                                            )
                                          : const ColoredBox(
                                              color: _surfaceTintColor,
                                              child: Icon(
                                                Icons.image_outlined,
                                                color: _mutedTextColor,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Image ${index + 1}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: _textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatFileSize(
                                            _images[index].sizeBytes,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: _mutedTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Remove image',
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Color(0xFF7A2C22),
                                    ),
                                    onPressed: () => _removeImageAt(index),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Photo Credits to Photographer',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.italic,
                                  color: _textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: 36,
                                child: TextFormField(
                                  initialValue: _images[index].photoCredit,
                                  onChanged: (String value) {
                                    _images[index].photoCredit = value.trim();
                                  },
                                  style: _uploadInputTextStyle,
                                  decoration: _uploadInputDecoration(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Text(
                        'Contributors',
                        style: _uploadSectionTitleStyle,
                      ),
                      const SizedBox(height: 8),
                      for (
                        int index = 0;
                        index < _contributors.length;
                        index++
                      ) ...[
                        if (index > 0) const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: TextField(
                                  controller:
                                      _contributors[index].nameController,
                                  onChanged: (_) {
                                    setState(() {
                                      _ensureTrailingContributorRow();
                                    });
                                  },
                                  style: _uploadInputTextStyle,
                                  decoration: _uploadInputDecoration(
                                    hintText: 'Contributor name',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue:
                                    _contributors[index].position.trim().isEmpty
                                    ? null
                                    : _contributors[index].position,
                                isDense: true,
                                isExpanded: true,
                                style: _uploadInputTextStyle,
                                items: _contributorPositions
                                    .map(
                                      (String option) =>
                                          DropdownMenuItem<String>(
                                            value: option,
                                            child: Text(
                                              option,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                    )
                                    .toList(growable: false),
                                onChanged: (String? value) {
                                  setState(() {
                                    _contributors[index].position = value ?? '';
                                    _ensureTrailingContributorRow();
                                  });
                                },
                                decoration: _uploadInputDecoration(
                                  hintText: 'Position',
                                ),
                              ),
                            ),
                            if (_contributors.length > 1)
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Color(0xFF7A2C22),
                                ),
                                onPressed: () {
                                  setState(() {
                                    final _ContributorFormRow row =
                                        _contributors.removeAt(index);
                                    row.dispose();
                                    _ensureTrailingContributorRow();
                                  });
                                },
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Draft-first flow: save here, then submit from Draft Uploads after review/edit.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: _mutedTextColor,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isSavingDraft ? null : _saveDraft,
                  style: _uploadActionButtonStyle(fullWidth: true),
                  child: Text(
                    _isSavingDraft ? 'Saving Draft...' : 'SAVE TO DRAFTS',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UploadSpeciesDraftsScreen extends StatefulWidget {
  const UploadSpeciesDraftsScreen({super.key});

  @override
  State<UploadSpeciesDraftsScreen> createState() =>
      _UploadSpeciesDraftsScreenState();
}

class _UploadSpeciesDraftsScreenState extends State<UploadSpeciesDraftsScreen> {
  final UploadSpeciesDraftSubmissionApi _submissionApi =
      UploadSpeciesDraftSubmissionApi();

  late Future<List<UploadSpeciesFlowData>> _draftsFuture;
  String? _submittingDraftKey;

  @override
  void initState() {
    super.initState();
    _draftsFuture = UploadSpeciesDraftStore.loadDrafts();
  }

  @override
  void dispose() {
    _submissionApi.dispose();
    super.dispose();
  }

  void _reloadDrafts() {
    setState(() {
      _draftsFuture = UploadSpeciesDraftStore.loadDrafts();
    });
  }

  String _formatDraftTimestamp(DateTime timestamp) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[timestamp.month - 1]} ${timestamp.day}, ${timestamp.year}';
  }

  Future<Uint8List?> _loadDraftPreview(String path) async {
    final String normalized = path.trim();
    if (normalized.isEmpty) {
      return null;
    }

    try {
      return await XFile(normalized).readAsBytes();
    } catch (_) {
      return null;
    }
  }

  Widget _buildDraftPreview(UploadSpeciesFlowData draft) {
    if (draft.images.isEmpty || draft.images.first.path.trim().isEmpty) {
      return Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: _surfaceTintColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _lineColor),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, color: _mutedTextColor),
      );
    }

    return FutureBuilder<Uint8List?>(
      future: _loadDraftPreview(draft.images.first.path),
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
        final Uint8List? bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: _surfaceTintColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _lineColor),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.broken_image_outlined,
              color: _mutedTextColor,
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(bytes, width: 78, height: 78, fit: BoxFit.cover),
        );
      },
    );
  }

  Future<void> _editDraft(UploadSpeciesFlowData draft) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UploadSpeciesInformationScreen(flowData: draft.copy()),
      ),
    );

    _reloadDrafts();
  }

  String _draftKey(UploadSpeciesFlowData draft, {int fallback = 0}) {
    final String draftId = (draft.draftId ?? '').trim();
    if (draftId.isNotEmpty) {
      return draftId;
    }

    return '${draft.updatedAt.microsecondsSinceEpoch}-$fallback';
  }

  Future<void> _submitDraft(
    UploadSpeciesFlowData draft,
    String draftKey,
  ) async {
    if (_submittingDraftKey != null) {
      return;
    }

    final String? validationError =
        UploadSpeciesFlowValidators.validateSpeciesInformation(draft) ??
        UploadSpeciesFlowValidators.validateSightings(draft) ??
        UploadSpeciesFlowValidators.validateSpeciesValues(draft) ??
        UploadSpeciesFlowValidators.validateImagesAndContributors(draft);

    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Draft is incomplete: $validationError Continue editing first.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _submittingDraftKey = draftKey;
    });

    try {
      final Map<String, dynamic> result = await _submissionApi.submitDraft(
        draft,
      );

      final String draftId = (draft.draftId ?? '').trim();
      if (draftId.isNotEmpty) {
        await UploadSpeciesDraftStore.deleteDraft(draftId);
      }

      if (!mounted) {
        return;
      }

      _reloadDrafts();

      final int submissionCount =
          int.tryParse((result['submissionCount'] ?? '').toString()) ??
          draft.images.length;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Draft submitted successfully. $submissionCount image(s) uploaded.',
          ),
        ),
      );

      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const UploadsStatusScreen()),
      );
    } on DraftSubmissionException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to submit draft right now. Please try again later.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submittingDraftKey = null;
        });
      }
    }
  }

  Future<void> _deleteDraft(UploadSpeciesFlowData draft) async {
    await UploadSpeciesDraftStore.deleteDraftData(draft);
    if (!mounted) {
      return;
    }

    _reloadDrafts();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Draft deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _UploadFormHeader(title: 'Draft Uploads'),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<UploadSpeciesFlowData>>(
                  future: _draftsFuture,
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<List<UploadSpeciesFlowData>> snapshot,
                      ) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final List<UploadSpeciesFlowData> drafts =
                            snapshot.data ?? <UploadSpeciesFlowData>[];

                        if (drafts.isEmpty) {
                          return const Center(
                            child: Text(
                              'No drafts saved yet.',
                              style: TextStyle(
                                color: _mutedTextColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: drafts.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (BuildContext context, int index) {
                            final UploadSpeciesFlowData draft = drafts[index];
                            final String draftTitle =
                                draft.scientificName.trim().isNotEmpty
                                ? draft.scientificName.trim()
                                : 'Unnamed species draft';
                            final String currentDraftKey = _draftKey(
                              draft,
                              fallback: index,
                            );
                            final bool isSubmittingCurrentDraft =
                                _submittingDraftKey == currentDraftKey;

                            return Container(
                              decoration: BoxDecoration(
                                color: _surfaceColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _lineColor),
                                boxShadow: const <BoxShadow>[
                                  BoxShadow(
                                    color: Color(0x10000000),
                                    blurRadius: 18,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDraftPreview(draft),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          draftTitle,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: _textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Updated ${_formatDraftTimestamp(draft.updatedAt)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: _mutedTextColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${draft.images.length} image(s) • ${draft.contributors.where((UploadContributorDraft c) => c.name.trim().isNotEmpty).length} contributor(s)',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: _mutedTextColor,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            OutlinedButton(
                                              onPressed: () =>
                                                  _editDraft(draft),
                                              child: const Text('Edit'),
                                            ),
                                            OutlinedButton(
                                              onPressed:
                                                  isSubmittingCurrentDraft
                                                  ? null
                                                  : () => _submitDraft(
                                                      draft,
                                                      currentDraftKey,
                                                    ),
                                              child: Text(
                                                isSubmittingCurrentDraft
                                                    ? 'Submitting...'
                                                    : 'Submit',
                                              ),
                                            ),
                                            OutlinedButton(
                                              onPressed: () =>
                                                  _deleteDraft(draft),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubmissionStatusItem {
  const SubmissionStatusItem({
    required this.imageUrl,
    required this.title,
    required this.uploadedDate,
    required this.status,
    required this.statusColor,
  });

  final String imageUrl;
  final String title;
  final String uploadedDate;
  final String status;
  final Color statusColor;

  factory SubmissionStatusItem.fromJson(Map<String, dynamic> json) {
    final String title = (json['scientificName'] ?? '').toString().trim();
    final String statusRaw = (json['status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final String imageUrlRaw = (json['imageUrl'] ?? '').toString().trim();

    return SubmissionStatusItem(
      imageUrl: imageUrlRaw,
      title: title.isNotEmpty ? title : 'Unnamed species',
      uploadedDate: _formatDate((json['uploadedAt'] ?? '').toString()),
      status: _statusLabel(statusRaw),
      statusColor: _statusColor(statusRaw),
    );
  }

  static String _formatDate(String raw) {
    final String value = raw.trim();
    if (value.isEmpty) {
      return 'Unknown date';
    }

    try {
      final DateTime parsed = DateTime.parse(value);
      const List<String> months = <String>[
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
    } catch (_) {
      return value;
    }
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF2A7A2D);
      case 'rejected':
        return const Color(0xFFB33A2D);
      default:
        return const Color(0xFFF39B15);
    }
  }
}

class UploadsStatusScreen extends StatefulWidget {
  const UploadsStatusScreen({super.key});

  @override
  State<UploadsStatusScreen> createState() => _UploadsStatusScreenState();
}

class _UploadsStatusScreenState extends State<UploadsStatusScreen> {
  late final Future<List<SubmissionStatusItem>> _itemsFuture;

  List<SubmissionStatusItem> get _fallbackItems => const <SubmissionStatusItem>[
    SubmissionStatusItem(
      imageUrl: 'https://picsum.photos/seed/vanda-sanderiana-status/200/200',
      title: 'Vanda sanderiana',
      uploadedDate: 'December 1, 2024',
      status: 'Approved',
      statusColor: Color(0xFF2A7A2D),
    ),
    SubmissionStatusItem(
      imageUrl:
          'https://picsum.photos/seed/abdominea-minimiflora-status/200/200',
      title: 'Abdominea minimiflora',
      uploadedDate: 'December 6, 2024',
      status: 'Pending',
      statusColor: Color(0xFFF39B15),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _itemsFuture = _loadSubmissions();
  }

  String _resolveApiBaseUrl() {
    const String fromDefine = String.fromEnvironment('API_BASE_URL');
    final String normalized = fromDefine.trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }

    if (kIsWeb) {
      return 'http://localhost:4000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://192.168.1.21:4000';
      default:
        return 'http://localhost:4000';
    }
  }

  Future<List<SubmissionStatusItem>> _loadSubmissions() async {
    if (kOfflineMode) return _fallbackItems;
    final Uri uri = Uri.parse('${_resolveApiBaseUrl()}/api/submissions');

    try {
      final http.Response response = await http
          .get(uri)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return _fallbackItems;
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! List<dynamic>) {
        return _fallbackItems;
      }

      final List<SubmissionStatusItem> items = <SubmissionStatusItem>[];
      for (final dynamic raw in decoded) {
        if (raw is Map<String, dynamic>) {
          items.add(SubmissionStatusItem.fromJson(raw));
        } else if (raw is Map) {
          items.add(
            SubmissionStatusItem.fromJson(Map<String, dynamic>.from(raw)),
          );
        }
      }

      return items.isNotEmpty ? items : _fallbackItems;
    } catch (_) {
      return _fallbackItems;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _UploadFormHeader(title: 'Uploads'),
              const SizedBox(height: 16),
              const Text(
                'Uploads',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(height: 1, width: double.infinity, color: _lineColor),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<SubmissionStatusItem>>(
                  future: _itemsFuture,
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<List<SubmissionStatusItem>> snapshot,
                      ) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final List<SubmissionStatusItem> items =
                            snapshot.data ?? _fallbackItems;

                        if (items.isEmpty) {
                          return const Center(
                            child: Text(
                              'Nothing to show',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: _mutedTextColor,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 16),
                          itemBuilder: (BuildContext context, int index) {
                            final SubmissionStatusItem item = items[index];
                            return _UploadStatusTile(
                              imageUrl: item.imageUrl,
                              title: item.title,
                              uploadedDate: item.uploadedDate,
                              status: item.status,
                              statusColor: item.statusColor,
                            );
                          },
                        );
                      },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyUploadsScreen extends StatelessWidget {
  const MyUploadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double heightScale = constraints.maxHeight / 844;
            final double widthScale = constraints.maxWidth / 390;
            final double scale =
                (heightScale < widthScale ? heightScale : widthScale).clamp(
                  0.82,
                  1.12,
                );

            return Padding(
              padding: EdgeInsets.fromLTRB(
                18 * scale,
                12 * scale,
                18 * scale,
                14 * scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _UploadFormHeader(title: 'Uploaded Species'),
                  SizedBox(height: 16 * scale),
                  Text(
                    'Uploaded Species',
                    style: TextStyle(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: _textColor,
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: _lineColor,
                  ),
                  SizedBox(height: 8 * scale),
                  Center(
                    child: Text(
                      'Nothing to show',
                      style: TextStyle(
                        fontSize: 14 * scale,
                        fontStyle: FontStyle.italic,
                        color: _mutedTextColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 24 * scale),
                  Text(
                    'Added Sightings',
                    style: TextStyle(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: _textColor,
                    ),
                  ),
                  SizedBox(height: 14 * scale),
                  const _MyUploadsSightingTile(
                    imageUrl:
                        'https://picsum.photos/seed/vanda-sanderiana/220/220',
                    scientificName: 'Vanda sanderiana',
                    commonName: 'Waling-waling',
                    uploadedDate: 'December 1, 2024',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MyUploadsSightingTile extends StatelessWidget {
  const _MyUploadsSightingTile({
    required this.imageUrl,
    required this.scientificName,
    required this.commonName,
    required this.uploadedDate,
  });

  final String imageUrl;
  final String scientificName;
  final String commonName;
  final String uploadedDate;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            imageUrl,
            width: 78,
            height: 78,
            fit: BoxFit.cover,
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stackTrace) {
                  return Container(
                    width: 78,
                    height: 78,
                    color: _surfaceTintColor,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_outlined,
                      size: 30,
                      color: _primaryColor,
                    ),
                  );
                },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scientificName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  commonName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Uploaded: $uploadedDate',
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: _mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadStatusTile extends StatelessWidget {
  const _UploadStatusTile({
    required this.imageUrl,
    required this.title,
    required this.uploadedDate,
    required this.status,
    required this.statusColor,
  });

  final String imageUrl;
  final String title;
  final String uploadedDate;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final bool hasImageUrl = imageUrl.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lineColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: hasImageUrl
                  ? Image.network(
                      imageUrl,
                      width: 78,
                      height: 78,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) {
                            return Container(
                              width: 78,
                              height: 78,
                              color: const Color(0xFFF1F4F7),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                size: 30,
                                color: _primaryColor,
                              ),
                            );
                          },
                    )
                  : Container(
                      width: 78,
                      height: 78,
                      color: const Color(0xFFF1F4F7),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_outlined,
                        size: 30,
                        color: _primaryColor,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Uploaded: $uploadedDate',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: _mutedTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text(
                          'Status: ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            color: _textColor,
                          ),
                        ),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndemicToggle extends StatelessWidget {
  const _EndemicToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _lineColor, width: 1),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: value ? Alignment.centerLeft : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: const ColoredBox(color: _primaryColor),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => onChanged(true),
                  child: Center(
                    child: Text(
                      'YES',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        color: value ? Colors.white : _primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => onChanged(false),
                  child: Center(
                    child: Text(
                      'NO',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        color: !value ? Colors.white : _primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _closeUploadFlow(BuildContext context) {
  final NavigatorState navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.popUntil((Route<dynamic> route) => route.isFirst);
  }
}

const TextStyle _uploadSectionTitleStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w800,
  fontStyle: FontStyle.italic,
  color: _textColor,
);

const TextStyle _uploadFieldLabelStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w700,
  fontStyle: FontStyle.italic,
  color: _textColor,
);

const TextStyle _uploadInputTextStyle = TextStyle(
  fontSize: 15,
  color: _textColor,
  fontStyle: FontStyle.italic,
);

const TextStyle _uploadHintTextStyle = TextStyle(
  fontSize: 14,
  color: _mutedTextColor,
  fontStyle: FontStyle.italic,
);

InputDecoration _uploadInputDecoration({String? hintText}) {
  return InputDecoration(
    isDense: true,
    hintText: hintText,
    hintStyle: _uploadHintTextStyle,
    filled: true,
    fillColor: _surfaceTintColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _lineColor, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _primarySoftColor, width: 1.6),
    ),
  );
}

ButtonStyle _uploadActionButtonStyle({bool fullWidth = false}) {
  return OutlinedButton.styleFrom(
    foregroundColor: _primaryColor,
    side: const BorderSide(color: _primaryColor, width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    minimumSize: fullWidth
        ? const Size(double.infinity, 46)
        : const Size(140, 42),
  );
}

class _UploadFormHeader extends StatelessWidget {
  const _UploadFormHeader({required this.title});

  final String title;

  Widget _actionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 24, color: _primaryColor),
        splashRadius: 24,
        padding: EdgeInsets.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final NavigatorState navigator = Navigator.of(context);

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _actionButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onTap: () => navigator.maybePop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _textColor,
              ),
            ),
          ),
          _actionButton(
            icon: Icons.close_rounded,
            tooltip: 'Close',
            onTap: () => _closeUploadFlow(context),
          ),
        ],
      ),
    );
  }
}

class _RequirementBullet extends StatelessWidget {
  const _RequirementBullet({required this.text, this.level = 0, this.suffix});

  final String text;
  final int level;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final double indent = level == 0 ? 8 : 28;

    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '\u2022  $text',
              style: const TextStyle(
                fontSize: 14,
                height: 1.25,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                color: _textColor,
              ),
            ),
            if (suffix != null)
              TextSpan(
                text: suffix,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.25,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: _mutedTextColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UploadActionRow extends StatelessWidget {
  const _UploadActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badgeCount;

  String _badgeText(int count) {
    if (count > 99) {
      return '99+';
    }

    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surfaceColor,
      elevation: 0,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _lineColor),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(child: Icon(icon, color: Colors.white, size: 28)),
                    if (badgeCount != null && badgeCount! > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _accentColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _badgeText(badgeCount!),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: _mutedTextColor,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({required this.authController, super.key});

  final AppAuthController authController;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  WebViewController? _webViewController;
  bool _isLoadingMap = true;
  List<Map<String, double>> _mapPoints = <Map<String, double>>[];

  bool get _supportsLeafletWebView {
    if (kIsWeb) {
      return false;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      default:
        return false;
    }
  }

  @override
  void initState() {
    super.initState();

    _initializeMap();
  }

  double _weightForScientificName(String value) {
    final String normalized = value.toLowerCase();
    if (normalized.contains('philipp') || normalized.contains('sanderiana')) {
      return 1.0;
    }
    if (normalized.contains('vanda') || normalized.contains('dendrobium')) {
      return 0.85;
    }
    return 0.68;
  }

  Future<List<Map<String, double>>> _loadMapPoints() async {
    if (kOfflineMode) return const <Map<String, double>>[];
    final http.Client client = http.Client();
    try {
      final http.Response response = await client
          .get(buildApiUri('/api/sightings'))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        return const <Map<String, double>>[];
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return const <Map<String, double>>[];
      }

      return decoded
          .whereType<Map>()
          .map((Map raw) {
            final Map<String, dynamic> row = Map<String, dynamic>.from(raw);
            final double? lat = double.tryParse((row['lat'] ?? '').toString());
            final double? lng = double.tryParse((row['lng'] ?? '').toString());
            if (lat == null || lng == null) {
              return null;
            }

            final String scientificName = (row['scientificName'] ?? '')
                .toString()
                .trim();

            return <String, double>{
              'lat': lat,
              'lng': lng,
              'weight': _weightForScientificName(scientificName),
            };
          })
          .whereType<Map<String, double>>()
          .toList(growable: false);
    } catch (_) {
      return const <Map<String, double>>[];
    } finally {
      client.close();
    }
  }

  Future<void> _initializeMap() async {
    final List<Map<String, double>> loadedPoints = await _loadMapPoints();

    if (!mounted) {
      return;
    }

    final List<Map<String, double>> fallbackPoints = <Map<String, double>>[
      <String, double>{'lat': 5.9352, 'lng': 125.0832, 'weight': 0.95},
      <String, double>{'lat': 5.9380, 'lng': 125.0861, 'weight': 0.78},
    ];

    _mapPoints = loadedPoints.isNotEmpty ? loadedPoints : fallbackPoints;

    if (_supportsLeafletWebView) {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..loadHtmlString(_buildLeafletHtml(_mapPoints));
    }

    setState(() {
      _isLoadingMap = false;
    });
  }

  String get _platformLabel {
    if (kIsWeb) {
      return 'Web';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }

  Future<void> _openProfilePanel(BuildContext context) async {
    final String profileName =
        widget.authController.user?.name.trim().isNotEmpty == true
        ? widget.authController.user!.name
        : 'Researcher 1';
    final String handleSource =
        widget.authController.user?.email.trim().isNotEmpty == true
        ? widget.authController.user!.email.split('@').first
        : profileName;
    final String normalizedHandle = handleSource.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    final String profileHandle = normalizedHandle.isNotEmpty
        ? '@$normalizedHandle'
        : '@researcher1';

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close profile menu',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, _, _) {
        return _ProfileOverlayPanel(
          authController: widget.authController,
          profileName: profileName,
          profileHandle: profileHandle,
        );
      },
      transitionBuilder: (_, animation, _, child) {
        final Animation<Offset> slide =
            Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        return SlideTransition(position: slide, child: child);
      },
    );
  }

  String _buildLeafletHtml(List<Map<String, double>> points) {
    final List<Map<String, double>> effectivePoints = points.isNotEmpty
        ? points
        : <Map<String, double>>[
            <String, double>{'lat': 5.9352, 'lng': 125.0832, 'weight': 0.95},
          ];
    final double averageLat =
        effectivePoints
            .map((Map<String, double> p) => p['lat']!)
            .reduce((double a, double b) => a + b) /
        effectivePoints.length;
    final double averageLng =
        effectivePoints
            .map((Map<String, double> p) => p['lng']!)
            .reduce((double a, double b) => a + b) /
        effectivePoints.length;

    final String pointsJson = jsonEncode(effectivePoints);

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <style>
    html, body, #map {
      width: 100%;
      height: 100%;
      margin: 0;
      padding: 0;
      background: #111a12;
    }

    .leaflet-control-attribution {
      font-size: 9px;
    }
  </style>
</head>
<body>
  <div id="map"></div>
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <script src="https://unpkg.com/leaflet.heat@0.2.0/dist/leaflet-heat.js"></script>
  <script>
    const center = [$averageLat, $averageLng];
    const points = $pointsJson;

    const map = L.map('map', {
      preferCanvas: true,
      zoomControl: true
    }).setView(center, 13.2);

    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; OpenStreetMap contributors'
    }).addTo(map);

    const heatPoints = points.map((p) => [p.lat, p.lng, p.weight]);
    L.heatLayer(heatPoints, {
      radius: 36,
      blur: 25,
      maxZoom: 17,
      minOpacity: 0.4,
      gradient: {
        0.20: '#fff176',
        0.45: '#ff9800',
        0.75: '#ff5722',
        1.00: '#b71c1c'
      }
    }).addTo(map);

    points.forEach((p) => {
      L.circleMarker([p.lat, p.lng], {
        radius: 4,
        color: '#ffffff',
        weight: 1,
        fillColor: '#7a0f0f',
        fillOpacity: 0.95
      }).addTo(map);
    });

    L.control.scale({ imperial: false }).addTo(map);
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    final bool canRenderLeaflet =
        _supportsLeafletWebView && _webViewController != null;

    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: Colors.transparent,
                child: InkResponse(
                  onTap: () => _openProfilePanel(context),
                  radius: 28,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: _primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sentiment_satisfied_alt_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Orchid Map',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: _textColor,
                  height: 0.95,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _isLoadingMap
                      ? const Center(child: CircularProgressIndicator())
                      : canRenderLeaflet
                      ? Stack(
                          children: [
                            WebViewWidget(controller: _webViewController!),
                            Positioned(
                              left: 12,
                              top: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xD2151F18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Mt. Busa, Sarangani, Philippines',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          color: _primaryColor,
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.map_outlined,
                                color: Colors.white70,
                                size: 34,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Leaflet map is not supported on this platform.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Current platform: $_platformLabel',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Use Android, iOS, or macOS to view the interactive Leaflet heatmap.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.3,
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                'Mt. Busa, Sarangani, Philippines',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _loadNotifications();
  }

  Future<void> _refresh() async {
    setState(() {
      _notificationsFuture = _loadNotifications();
    });
    await _notificationsFuture;
  }

  String _bucketForDate(DateTime value) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime date = DateTime(value.year, value.month, value.day);
    final int diff = today.difference(date).inDays;
    if (diff <= 0) {
      return 'Today';
    }
    if (diff <= 7) {
      return 'Past 7 days';
    }
    return 'Earlier';
  }

  String _messageForSubmission(String status, String scientificName) {
    final String safeName = scientificName.trim().isEmpty
        ? 'Unnamed species'
        : scientificName;
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Submission approved: $safeName';
      case 'rejected':
        return 'Submission rejected: $safeName';
      default:
        return 'Submission pending review: $safeName';
    }
  }

  Future<List<AppNotification>> _loadNotifications() async {
    if (kOfflineMode) return mockNotifications;
    final http.Client client = http.Client();
    try {
      final http.Response response = await client
          .get(buildApiUri('/api/submissions'))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return mockNotifications;
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return mockNotifications;
      }

      final List<AppNotification> notifications = <AppNotification>[];
      for (int index = 0; index < decoded.length; index++) {
        final dynamic row = decoded[index];
        if (row is! Map) {
          continue;
        }

        final Map<String, dynamic> item = Map<String, dynamic>.from(row);
        final String status = (item['status'] ?? '').toString().trim();
        final String scientificName = (item['scientificName'] ?? '')
            .toString()
            .trim();
        final DateTime uploadedAt =
            DateTime.tryParse((item['uploadedAt'] ?? '').toString()) ??
            DateTime.now();

        notifications.add(
          AppNotification(
            id: (item['id'] ?? index + 1).toString(),
            type: status.isEmpty ? 'pending' : status,
            message: _messageForSubmission(status, scientificName),
            timestamp: _bucketForDate(uploadedAt),
            read: status.toLowerCase() != 'pending',
          ),
        );
      }

      if (notifications.isEmpty) {
        return mockNotifications;
      }

      return notifications;
    } catch (_) {
      return mockNotifications;
    } finally {
      client.close();
    }
  }

  Widget _buildNotificationSection({
    required String title,
    required List<AppNotification> items,
  }) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _mutedTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((AppNotification item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _lineColor),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x0E000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: item.read
                            ? const Color(0xFFF1F5F8)
                            : _accentSoftColor,
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Positioned.fill(
                            child: Icon(
                              Icons.mail_outline_rounded,
                              color: _primaryColor,
                              size: 24,
                            ),
                          ),
                          if (!item.read)
                            const Positioned(
                              right: 4,
                              top: 4,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: _accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: SizedBox(width: 8, height: 8),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.message,
                        style: TextStyle(
                          color: item.read ? _mutedTextColor : _textColor,
                          fontSize: 15,
                          height: 1.25,
                          fontStyle: FontStyle.italic,
                          fontWeight: item.read
                              ? FontWeight.w400
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<AppNotification>>(
            future: _notificationsFuture,
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<List<AppNotification>> snapshot,
                ) {
                  final List<AppNotification> notifications =
                      snapshot.data ?? mockNotifications;
                  final int unreadCount = notifications
                      .where((AppNotification item) => !item.read)
                      .length;
                  final List<AppNotification> todayNotifications = notifications
                      .where(
                        (AppNotification item) => item.timestamp == 'Today',
                      )
                      .toList(growable: false);
                  final List<AppNotification> recentNotifications =
                      notifications
                          .where(
                            (AppNotification item) =>
                                item.timestamp == 'Past 7 days',
                          )
                          .toList(growable: false);
                  final List<AppNotification> olderNotifications = notifications
                      .where(
                        (AppNotification item) => item.timestamp == 'Earlier',
                      )
                      .toList(growable: false);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: _primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sentiment_satisfied_alt_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You have $unreadCount new notifications',
                        style: const TextStyle(
                          color: _mutedTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          decoration: TextDecoration.underline,
                          decorationColor: _mutedTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Divider(height: 1, color: _lineColor),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                      const SizedBox(height: 16),
                      _buildNotificationSection(
                        title: 'Today',
                        items: todayNotifications,
                      ),
                      const SizedBox(height: 6),
                      _buildNotificationSection(
                        title: 'Past 7 days',
                        items: recentNotifications,
                      ),
                      const SizedBox(height: 6),
                      _buildNotificationSection(
                        title: 'Earlier',
                        items: olderNotifications,
                      ),
                    ],
                  );
                },
          ),
        ),
      ),
    );
  }
}

class AuthApiException implements Exception {
  AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppAuthController extends ChangeNotifier {
  AppAuthController({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  AppUser? _user;
  bool _isInitializing = true;

  AppUser? get user => _user;
  bool get isInitializing => _isInitializing;

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  String _normalizeUsername(String value) {
    return value.trim().replaceFirst(RegExp(r'^@+'), '');
  }

  String _defaultUsername({required String email, required String name}) {
    final String source = email.contains('@')
        ? email.split('@').first
        : name.trim();
    final String normalized = source.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    return normalized.isNotEmpty ? normalized : 'researcher1';
  }

  Future<void> _persistUser(AppUser user) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  AppUser _parseUserFromResponse(dynamic decoded) {
    if (decoded is! Map) {
      throw AuthApiException('Unexpected auth response format.');
    }

    final dynamic rawUser = decoded['user'];
    if (rawUser is! Map) {
      throw AuthApiException('User payload missing from auth response.');
    }

    return AppUser.fromJson(Map<String, dynamic>.from(rawUser));
  }

  Future<AppUser> _postAuth(String path, Map<String, dynamic> payload) async {
    if (kOfflineMode) return _kMockUser;
    late final http.Response response;
    try {
      response = await _client
          .post(
            buildApiUri(path),
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw AuthApiException('Request timed out. Check your connection.');
    } catch (_) {
      throw AuthApiException(
        'Unable to reach backend. Verify API_BASE_URL and server status.',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (decoded is Map && decoded['error'] != null) {
        throw AuthApiException(decoded['error'].toString());
      }

      throw AuthApiException('Authentication request failed.');
    }

    return _parseUserFromResponse(decoded);
  }

  Future<AppUser> _patchProfile(Map<String, dynamic> payload) async {
    if (kOfflineMode) return _kMockUser;
    late final http.Response response;
    try {
      response = await _client
          .patch(
            buildApiUri('/api/auth/profile'),
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw AuthApiException('Profile update timed out.');
    } catch (_) {
      throw AuthApiException(
        'Unable to reach backend. Verify API_BASE_URL and server status.',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (decoded is Map && decoded['error'] != null) {
        throw AuthApiException(decoded['error'].toString());
      }

      throw AuthApiException('Profile update failed.');
    }

    return _parseUserFromResponse(decoded);
  }

  Future<void> initialize() async {
    if (kOfflineMode) {
      _user = _kMockUser;
      _isInitializing = false;
      notifyListeners();
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? encodedUser = prefs.getString('user');

    if (encodedUser != null) {
      try {
        final Map<String, dynamic> json =
            jsonDecode(encodedUser) as Map<String, dynamic>;
        _user = AppUser.fromJson(json);
      } catch (_) {
        _user = null;
      }
    }

    _isInitializing = false;
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
    String? name,
  }) async {
    final String normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || password.trim().isEmpty) {
      throw AuthApiException('Email and password are required.');
    }

    final bool isSignup = name != null && name.trim().isNotEmpty;
    final AppUser nextUser = isSignup
        ? await _postAuth('/api/auth/signup', <String, dynamic>{
            'name': name.trim(),
            'email': normalizedEmail,
            'password': password,
            'location': 'Mt. Busa',
          })
        : await _postAuth('/api/auth/login', <String, dynamic>{
            'email': normalizedEmail,
            'password': password,
          });

    final AppUser sanitized = nextUser.copyWith(
      username: _normalizeUsername(nextUser.username).isNotEmpty
          ? _normalizeUsername(nextUser.username)
          : _defaultUsername(email: nextUser.email, name: nextUser.name),
      location: nextUser.location.trim().isNotEmpty
          ? nextUser.location
          : 'Mt. Busa',
    );

    _user = sanitized;
    notifyListeners();
    await _persistUser(sanitized);
  }

  Future<void> updateProfile({
    required String name,
    required String username,
    required String location,
    String? profilePhotoBase64,
  }) async {
    final AppUser? current = _user;
    if (current == null) {
      throw AuthApiException('No active user session.');
    }

    final String resolvedName = name.trim();
    final String resolvedUsername = _normalizeUsername(username);
    final String resolvedLocation = location.trim();

    if (resolvedName.isEmpty || resolvedUsername.isEmpty) {
      throw AuthApiException('Name and username are required.');
    }

    if (current.accountId == null) {
      final AppUser updatedLocal = current.copyWith(
        name: resolvedName,
        username: resolvedUsername,
        location: resolvedLocation,
        profilePhotoBase64: profilePhotoBase64 ?? current.profilePhotoBase64,
      );
      _user = updatedLocal;
      notifyListeners();
      await _persistUser(updatedLocal);
      return;
    }

    final AppUser updated = await _patchProfile(<String, dynamic>{
      'accountId': current.accountId,
      'name': resolvedName,
      'username': resolvedUsername,
      'location': resolvedLocation,
      'profilePhotoBase64': profilePhotoBase64 ?? current.profilePhotoBase64,
    });

    _user = updated.copyWith(
      username: _normalizeUsername(updated.username),
      location: updated.location.trim().isNotEmpty
          ? updated.location
          : resolvedLocation,
    );
    notifyListeners();
    await _persistUser(_user!);
  }

  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');

    _user = null;
    notifyListeners();
  }
}

class AppUser {
  const AppUser({
    required this.name,
    required this.email,
    this.accountId,
    this.userId,
    this.username = '',
    this.location = '',
    this.profilePhotoBase64 = '',
  });

  final int? accountId;
  final int? userId;
  final String name;
  final String email;
  final String username;
  final String location;
  final String profilePhotoBase64;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final int? parsedAccountId = int.tryParse(
      (json['accountId'] ?? '').toString(),
    );
    final int? parsedUserId = int.tryParse((json['userId'] ?? '').toString());

    return AppUser(
      accountId: parsedAccountId,
      userId: parsedUserId,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      profilePhotoBase64: (json['profilePhotoBase64'] ?? '').toString(),
    );
  }

  AppUser copyWith({
    int? accountId,
    int? userId,
    String? name,
    String? email,
    String? username,
    String? location,
    String? profilePhotoBase64,
  }) {
    return AppUser(
      accountId: accountId ?? this.accountId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      location: location ?? this.location,
      profilePhotoBase64: profilePhotoBase64 ?? this.profilePhotoBase64,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'accountId': accountId,
    'userId': userId,
    'name': name,
    'email': email,
    'username': username,
    'location': location,
    'profilePhotoBase64': profilePhotoBase64,
  };
}

class Orchid {
  const Orchid({
    required this.id,
    required this.scientificName,
    required this.commonName,
    required this.image,
    required this.latitude,
    required this.longitude,
    required this.endemicStatus,
    required this.description,
  });

  final String id;
  final String scientificName;
  final String commonName;
  final String image;
  final double latitude;
  final double longitude;
  final String endemicStatus;
  final String description;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.timestamp,
    required this.read,
  });

  final String id;
  final String type;
  final String message;
  final String timestamp;
  final bool read;
}

class AppStats {
  const AppStats({
    required this.totalSpecies,
    required this.pendingSubmissions,
    required this.totalSightings,
  });

  final int totalSpecies;
  final int pendingSubmissions;
  final int totalSightings;
}

class SpeciesHighlight {
  const SpeciesHighlight({
    required this.scientificName,
    required this.imageUrl,
    this.commonName = 'Common Name',
  });

  final String scientificName;
  final String imageUrl;
  final String commonName;
}

class CatalogSpecies {
  const CatalogSpecies({
    required this.scientificName,
    required this.commonName,
    this.id,
    this.genus = '',
    this.imageUrl,
    this.latitude,
    this.longitude,
  });

  final int? id;
  final String scientificName;
  final String commonName;
  final String genus;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
}

class CatalogGroup {
  const CatalogGroup({required this.title, required this.species});

  final String title;
  final List<CatalogSpecies> species;
}

const List<Orchid> mockOrchids = <Orchid>[
  Orchid(
    id: '1',
    scientificName: 'Vanda sanderiana',
    commonName: 'Waling-waling',
    image: '🌸',
    latitude: 5.9352,
    longitude: 125.0832,
    endemicStatus: 'Philippines',
    description: 'The Queen of Philippine Orchids',
  ),
  Orchid(
    id: '2',
    scientificName: 'Phalaenopsis amabilis',
    commonName: 'Moth Orchid',
    image: '🦋',
    latitude: 5.9362,
    longitude: 125.0842,
    endemicStatus: 'None',
    description: 'Beautiful white orchid',
  ),
  Orchid(
    id: '3',
    scientificName: 'Dendrobium anosmum',
    commonName: 'Sanggumay',
    image: '💜',
    latitude: 5.9372,
    longitude: 125.0852,
    endemicStatus: 'Philippines',
    description: 'Fragrant purple orchid',
  ),
  Orchid(
    id: '4',
    scientificName: 'Paphiopedilum rothschildianum',
    commonName: 'Gold of Kinabalu',
    image: '👑',
    latitude: 5.9382,
    longitude: 125.0862,
    endemicStatus: 'Mt Busa',
    description: 'Rare slipper orchid',
  ),
  Orchid(
    id: '5',
    scientificName: 'Bulbophyllum lobbii',
    commonName: 'Lobb\'s Bulbophyllum',
    image: '🌺',
    latitude: 5.9392,
    longitude: 125.0872,
    endemicStatus: 'None',
    description: 'Small delicate orchid',
  ),
  Orchid(
    id: '6',
    scientificName: 'Renanthera philippinensis',
    commonName: 'Philippine Fire Orchid',
    image: '🔥',
    latitude: 5.9402,
    longitude: 125.0882,
    endemicStatus: 'Philippines',
    description: 'Vibrant red orchid',
  ),
  Orchid(
    id: '7',
    scientificName: 'Cymbidium finlaysonianum',
    commonName: 'Boat Orchid',
    image: '⛵',
    latitude: 5.9412,
    longitude: 125.0892,
    endemicStatus: 'Mt Busa',
    description: 'Endemic to Mt Busa region',
  ),
  Orchid(
    id: '8',
    scientificName: 'Aerides odorata',
    commonName: 'Fragrant Aerides',
    image: '✨',
    latitude: 5.9422,
    longitude: 125.0902,
    endemicStatus: 'Philippines',
    description: 'Sweet-scented orchid',
  ),
];

const List<AppNotification> mockNotifications = <AppNotification>[
  AppNotification(
    id: '1',
    type: 'sighting',
    message: 'New sightings submitted',
    timestamp: 'Today',
    read: false,
  ),
  AppNotification(
    id: '2',
    type: 'approval',
    message: 'Species Sighting Approved',
    timestamp: 'Today',
    read: false,
  ),
  AppNotification(
    id: '3',
    type: 'welcome',
    message: 'Welcome to Bloom!',
    timestamp: 'Past 7 days',
    read: true,
  ),
];

const List<CatalogGroup> orchidCatalogGroups = <CatalogGroup>[
  CatalogGroup(
    title: 'Vanda',
    species: <CatalogSpecies>[
      CatalogSpecies(
        scientificName: 'Vanda sanderiana',
        commonName: 'Waling-waling',
        imageUrl: 'https://picsum.photos/seed/vanda-sanderiana/240/240',
      ),
    ],
  ),
  CatalogGroup(
    title: 'Abdominea',
    species: <CatalogSpecies>[
      CatalogSpecies(
        scientificName: 'Abdominea minimiflora',
        commonName: 'Mini-flower',
        imageUrl: 'https://picsum.photos/seed/abdominea-minimiflora/240/240',
      ),
      CatalogSpecies(
        scientificName: 'Abdominea intricata',
        commonName: 'Common Name',
        imageUrl: 'https://picsum.photos/seed/abdominea-intricata/240/240',
      ),
    ],
  ),
  CatalogGroup(
    title: 'Acampe',
    species: <CatalogSpecies>[
      CatalogSpecies(
        scientificName: 'Acampe rigida',
        commonName: 'Common Name',
      ),
    ],
  ),
  CatalogGroup(
    title: 'Acriopsis',
    species: <CatalogSpecies>[
      CatalogSpecies(
        scientificName: 'Acriopsis floribunda',
        commonName: 'Common Name',
        imageUrl: 'https://picsum.photos/seed/acriopsis-floribunda/240/240',
      ),
      CatalogSpecies(
        scientificName: 'Acriopsis indica',
        commonName: 'Common Name',
      ),
      CatalogSpecies(
        scientificName: 'Acriopsis liliifolia',
        commonName: 'Common Name',
        imageUrl: 'https://picsum.photos/seed/acriopsis-liliifolia/240/240',
      ),
    ],
  ),
  CatalogGroup(
    title: 'Adenoncos',
    species: <CatalogSpecies>[
      CatalogSpecies(
        scientificName: 'Adenoncos parviflora',
        commonName: 'Common Name',
        imageUrl: 'https://picsum.photos/seed/adenoncos-parviflora/240/240',
      ),
      CatalogSpecies(
        scientificName: 'Adenoncos virens',
        commonName: 'Common Name',
        imageUrl: 'https://picsum.photos/seed/adenoncos-virens/240/240',
      ),
    ],
  ),
  CatalogGroup(
    title: 'Adenoncos',
    species: <CatalogSpecies>[
      CatalogSpecies(
        scientificName: 'Aerides augustiana',
        commonName: 'Common Name',
      ),
      CatalogSpecies(
        scientificName: 'Aerides cootesii',
        commonName: 'Common Name',
        imageUrl: 'https://picsum.photos/seed/aerides-cootesii/240/240',
      ),
      CatalogSpecies(
        scientificName: 'Aerides inflexa',
        commonName: 'Common Name',
        imageUrl: 'https://picsum.photos/seed/aerides-inflexa/240/240',
      ),
      CatalogSpecies(
        scientificName: 'Aerides lawrenceae',
        commonName: 'Common Name',
        imageUrl: 'https://picsum.photos/seed/aerides-lawrenceae/240/240',
      ),
      CatalogSpecies(
        scientificName: 'Aerides leena',
        commonName: 'Common Name',
        imageUrl: 'https://picsum.photos/seed/aerides-leena/240/240',
      ),
      CatalogSpecies(
        scientificName: 'Aerides magnifica',
        commonName: 'Common Name',
        imageUrl: 'https://picsum.photos/seed/aerides-magnifica/240/240',
      ),
      CatalogSpecies(
        scientificName: 'Aerides migueldavidii',
        commonName: 'Common Name',
        imageUrl: 'https://picsum.photos/seed/aerides-migueldavidii/240/240',
      ),
      CatalogSpecies(
        scientificName: 'Aerides quinquevulnera',
        commonName: 'Common Name',
        imageUrl: 'https://picsum.photos/seed/aerides-quinquevulnera/240/240',
      ),
      CatalogSpecies(
        scientificName: 'Aerides roebelenii',
        commonName: 'Common Name',
        imageUrl: 'https://picsum.photos/seed/aerides-roebelenii/240/240',
      ),
      CatalogSpecies(
        scientificName: 'Aerides savageana',
        commonName: 'Common Name',
        imageUrl: 'https://picsum.photos/seed/aerides-savageana/240/240',
      ),
      CatalogSpecies(
        scientificName: 'Aerides shibatiana',
        commonName: 'Common Name',
        imageUrl: 'https://picsum.photos/seed/aerides-shibatiana/240/240',
      ),
      CatalogSpecies(
        scientificName: 'Aerides turma',
        commonName: 'Common Name',
        imageUrl: 'https://picsum.photos/seed/aerides-turma/240/240',
      ),
    ],
  ),
];

const SpeciesHighlight defaultSpeciesOfTheDay = SpeciesHighlight(
  scientificName: 'Vanda sanderiana',
  commonName: 'Waling-waling',
  imageUrl:
      'https://upload.wikimedia.org/wikipedia/commons/thumb/7/72/Vanda_sanderiana_Orchi_204.jpg/640px-Vanda_sanderiana_Orchi_204.jpg',
);

const AppStats defaultAppStats = AppStats(
  totalSpecies: 108,
  pendingSubmissions: 8,
  totalSightings: 15,
);
