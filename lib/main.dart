import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _kSupabaseUrl = 'https://hvyrngjfcvazxaoujduo.supabase.co';
const String _kSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh2eXJuZ2pmY3Zhenhhb3VqZHVvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc1MTc3MzgsImV4cCI6MjA5MzA5MzczOH0.5V6oda6C7Jg8SSNcU5x63ByY7Suwz6gacvsTM3z1Phc';
const String _kStorageBucket = 'bloom-uploads';

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

bool _kIsDark = false;

Color get _appBackgroundColor =>
    _kIsDark ? const Color(0xFF111820) : const Color(0xFFF5F1EA);
Color get _surfaceColor =>
    _kIsDark ? const Color(0xFF1C2733) : const Color(0xFFFFFFFF);
Color get _textColor =>
    _kIsDark ? const Color(0xFFECF2F8) : const Color(0xFF16212B);
Color get _mutedTextColor =>
    _kIsDark ? const Color(0xFF8FA4B4) : const Color(0xFF60707E);
Color get _lineColor =>
    _kIsDark ? const Color(0xFF2A3A4A) : const Color(0xFFD8E2EA);

const Color _surfaceTintColor = Color(0xFFF8FBFE);
const Color _primaryColor = Color(0xFF1E4F70);
const Color _primarySoftColor = Color(0xFF5F86A0);
const Color _accentColor = Color(0xFFE6784E);
const Color _accentSoftColor = Color(0xFFF6C8B6);

// Upload form purple/violet theme
const Color _uploadPrimary = Color(0xFF7C3AED);
const Color _uploadPrimaryDark = Color(0xFF6D28D9);
Color get _uploadBg =>
    _kIsDark ? const Color(0xFF150E24) : const Color(0xFFFAF7FF);
Color get _uploadSubCardBg =>
    _kIsDark ? const Color(0xFF231548) : const Color(0xFFF3E8FF);
Color get _uploadBorderColor =>
    _kIsDark ? const Color(0x557C3AED) : const Color(0x2E7C3AED);

const bool kOfflineMode = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Do NOT await Supabase here — it makes a network call and blocks runApp()
  // causing a native white screen for 10+ seconds. Instead, runApp immediately
  // so the branded splash renders, then initialize inside AppAuthController.
  runApp(const OrchidApp());
}

class OrchidApp extends StatefulWidget {
  const OrchidApp({super.key});

  @override
  State<OrchidApp> createState() => _OrchidAppState();
}

class _OrchidAppState extends State<OrchidApp> {
  final AppAuthController _authController = AppAuthController();

  // Cached so ThemeData is not rebuilt on every auth notification.
  ThemeData? _cachedTheme;
  bool _cachedIsDark = false;

  @override
  void initState() {
    super.initState();
    _authController.initialize();
    _authController.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() => setState(() {
    _kIsDark = _authController.isDarkMode;
  });

  @override
  void dispose() {
    _authController.removeListener(_onControllerUpdate);
    _authController.dispose();
    super.dispose();
  }

  ThemeData _buildTheme(bool isDark) {
    // Return cached theme if dark-mode hasn't changed — avoids rebuilding
    // ColorScheme.fromSeed (expensive) on every auth notification.
    if (_cachedTheme != null && _cachedIsDark == isDark) {
      return _cachedTheme!;
    }
    _cachedIsDark = isDark;
    final Brightness brightness =
        isDark ? Brightness.dark : Brightness.light;
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: brightness,
    ).copyWith(
      primary: _primaryColor,
      secondary: _accentColor,
      surface: _surfaceColor,
      onSurface: _textColor,
      tertiary: _primarySoftColor,
    );
    final TextTheme baseTextTheme = ThemeData.light().textTheme;
    _cachedTheme = ThemeData(
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
          side: BorderSide(color: _lineColor, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _textColor,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: _lineColor,
        space: 1,
        thickness: 1,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: _textColor,
        ),
        titleLarge: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: _textColor,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _textColor,
        ),
        bodyLarge: TextStyle(fontSize: 14, color: _textColor),
        bodyMedium: TextStyle(fontSize: 13, color: _textColor),
        bodySmall: TextStyle(fontSize: 12, color: _mutedTextColor),
        labelLarge: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
          borderSide: BorderSide(color: _lineColor),
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
          textStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _textColor,
        contentTextStyle: const TextStyle(color: Colors.white),
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
    );
    return _cachedTheme!;
  }

  @override
  Widget build(BuildContext context) {
    _kIsDark = _authController.isDarkMode;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BLOOM',
      theme: _buildTheme(_kIsDark),
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
              initialTabIndex: 0,
            );
          }

          return WelcomeScreen(authController: _authController);
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _fade = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _fade,
              child: Image.asset('logo.png', width: 150, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _fade,
              child: const Text(
                'BLOOM',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 6,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Orchidaceae Conservation',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 2,
                color: Colors.white.withAlpha(120),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({required this.authController, super.key});

  final AppAuthController authController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          // Hero background image
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: 'https://images.unsplash.com/photo-1775405298533-3e5909b16c43?w=800&q=80',
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0D2030), Color(0xFF0A141E)],
                  ),
                ),
              ),
            ),
          ),
          // Dark gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.4, 0.7, 1.0],
                  colors: [
                    const Color(0xFF0A141E).withAlpha(77),
                    const Color(0xFF0A141E).withAlpha(26),
                    const Color(0xFF0A141E).withAlpha(217),
                    const Color(0xFF0A141E).withAlpha(247),
                  ],
                ),
              ),
            ),
          ),
          // Content layer
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top wordmark row
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset('logo.png', height: 36, fit: BoxFit.contain),
                          const SizedBox(width: 8),
                          const Text(
                            'BLOOM',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(38),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withAlpha(64)),
                        ),
                        child: Text(
                          'Mt. Busa · Sarangani',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withAlpha(230),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Hero text block
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ORCHIDACEAE CONSERVATION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3,
                          color: const Color(0xFFE6C8A0).withAlpha(230),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Discover &\nProtect Wild\nOrchids',
                        style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Documenting & preserving the rare Orchidaceae\nof Mt. Busa, one sighting at a time.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withAlpha(166),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom frosted glass card
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withAlpha(46)),
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        child: Column(
                          children: [
                            // Sign In button
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => LoginScreen(
                                      authController: authController,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                height: 54,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF1E4F70),
                                      Color(0xFF2B7BA8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x721E4F70),
                                      blurRadius: 20,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Continue as Guest button
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => GuestCatalogScreen(
                                      authController: authController,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(89),
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      size: 18,
                                      color: Colors.white.withAlpha(200),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Continue as Guest',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white.withAlpha(230),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
        ],
      ),
    );
  }
}

// ─── Guest Catalog ────────────────────────────────────────────────────────────

class GuestCatalogScreen extends StatefulWidget {
  const GuestCatalogScreen({required this.authController, super.key});

  final AppAuthController authController;

  @override
  State<GuestCatalogScreen> createState() => _GuestCatalogScreenState();
}

class _GuestCatalogScreenState extends State<GuestCatalogScreen> {
  bool _gridMode = false;
  late final Future<List<CatalogSpecies>> _speciesFuture;
  List<CatalogSpecies> _allSpecies = <CatalogSpecies>[];
  List<CatalogSpecies> _filteredSpecies = <CatalogSpecies>[];
  List<CatalogGroup> _filteredGroups = <CatalogGroup>[];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _speciesFuture = _loadSpecies();
    _speciesFuture.then((List<CatalogSpecies> list) {
      if (mounted) {
        setState(() {
          _allSpecies = list;
          _recomputeFilter();
        });
      }
    }).ignore();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final String q = _searchController.text.toLowerCase().trim();
    if (q == _searchQuery) return;
    setState(() {
      _searchQuery = q;
      _recomputeFilter();
    });
  }

  void _recomputeFilter() {
    if (_allSpecies.isEmpty) {
      _filteredSpecies = <CatalogSpecies>[];
      _filteredGroups = <CatalogGroup>[];
      return;
    }
    _filteredSpecies = _searchQuery.isEmpty
        ? _allSpecies
        : _allSpecies
              .where(
                (CatalogSpecies s) =>
                    s.scientificName.toLowerCase().contains(_searchQuery) ||
                    s.commonName.toLowerCase().contains(_searchQuery) ||
                    s.genus.toLowerCase().contains(_searchQuery),
              )
              .toList(growable: false);
    _filteredGroups = _groupSpecies(_filteredSpecies);
  }

  List<CatalogGroup> _groupSpecies(List<CatalogSpecies> species) {
    final Map<String, List<CatalogSpecies>> map =
        <String, List<CatalogSpecies>>{};
    for (final CatalogSpecies s in species) {
      final String key = s.genus.trim().isNotEmpty
          ? s.genus.trim()
          : s.scientificName.trim().split(RegExp(r'\s+')).first;
      map.putIfAbsent(key, () => <CatalogSpecies>[]).add(s);
    }
    final List<String> keys = map.keys.toList()..sort();
    return keys
        .map((String k) => CatalogGroup(title: k, species: map[k]!))
        .toList(growable: false);
  }

  Future<List<CatalogSpecies>> _loadSpecies() async {
    try {
      final List<dynamic> data = await Supabase.instance.client
          .from('orchids')
          .select(
            'orchid_id, sci_name, common_name, local_name, genus(genus_name), picture(file_url)',
          )
          .order('sci_name');
      final List<CatalogSpecies> mapped = data
          .whereType<Map>()
          .map((Map item) {
            final Map<String, dynamic> json = Map<String, dynamic>.from(item);
            final String sci = (json['sci_name'] ?? '').toString().trim();
            if (sci.isEmpty) return null;
            final dynamic genusData = json['genus'];
            final String genus = genusData is Map
                ? (genusData['genus_name'] ?? '').toString()
                : '';
            final dynamic pic = json['picture'];
            final String imgUrl = pic is List && pic.isNotEmpty
                ? (pic.first['file_url'] ?? '').toString()
                : '';
            return CatalogSpecies(
              id: int.tryParse((json['orchid_id'] ?? '').toString()),
              scientificName: sci,
              commonName:
                  (json['common_name'] ?? 'Common Name').toString().trim(),
              genus: genus,
              imageUrl: imgUrl.isNotEmpty ? imgUrl : null,
            );
          })
          .whereType<CatalogSpecies>()
          .toList(growable: false);
      return mapped.isEmpty ? _fallback() : mapped;
    } catch (_) {
      return _fallback();
    }
  }

  List<CatalogSpecies> _fallback() => orchidCatalogGroups
      .expand((CatalogGroup g) => g.species)
      .toList(growable: false);

  void _openDetails(CatalogSpecies species) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            CatalogSpeciesDetailsScreen(species: species, isGuest: true),
      ),
    );
  }

  String _heroTagFor(CatalogSpecies s) {
    final String slug = s.scientificName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return 'guest-catalog-${slug.isEmpty ? 'unknown' : slug}';
  }

  Widget _buildModeButton({
    required bool selected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: <Color>[Color(0xFF7C3AED), Color(0xFFEC4899)],
                )
              : null,
          color: selected ? null : const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x337C3AED),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: selected ? Colors.white : const Color(0xFF7C3AED),
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // ── Top row ───────────────────────────────────────────────────
              Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: _lineColor),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: _textColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Guest View',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // ── Title + mode toggle ───────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
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
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: _lineColor, width: 1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
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
                ],
              ),
              const SizedBox(height: 12),
              // ── Search bar ────────────────────────────────────────────────
              TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1E1B4B)),
                decoration: InputDecoration(
                  hintText: 'Search orchids by name or genus...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF7C3AED),
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () => setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _recomputeFilter();
                          }),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF7C3AED),
                            size: 18,
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF5F3FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFDDD6FE)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFDDD6FE)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF7C3AED),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // ── Total orchid count ────────────────────────────────────────
              if (_allSpecies.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.eco_rounded,
                        size: 13,
                        color: Color(0xFF7C3AED),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${_allSpecies.length} orchid${_allSpecies.length == 1 ? '' : 's'} recorded',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_searchQuery.isNotEmpty) ...<Widget>[
                        const Text(
                          ' · ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        Text(
                          '${_filteredSpecies.length} matching',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              // ── List / Grid ───────────────────────────────────────────────
              Expanded(
                child: FutureBuilder<List<CatalogSpecies>>(
                  future: _speciesFuture,
                  builder: (
                    BuildContext ctx,
                    AsyncSnapshot<List<CatalogSpecies>> snap,
                  ) {
                    if (snap.connectionState != ConnectionState.done &&
                        _allSpecies.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF7C3AED),
                        ),
                      );
                    }
                    if (_filteredSpecies.isEmpty && _searchQuery.isNotEmpty) {
                      return Center(
                        child: Text(
                          'No orchids match "$_searchQuery".',
                          style: TextStyle(color: _mutedTextColor),
                        ),
                      );
                    }
                    if (_allSpecies.isEmpty) {
                      return Center(
                        child: Text(
                          'No orchids found.',
                          style: TextStyle(color: _mutedTextColor),
                        ),
                      );
                    }
                    return _gridMode
                        ? _buildGrid(_filteredSpecies)
                        : _buildList(_filteredGroups);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // List view — genus-grouped, same style as CatalogScreen
  Widget _buildList(List<CatalogGroup> groups) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      children: <Widget>[
        for (final CatalogGroup group in groups)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFDDD6FE)),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x147C3AED),
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 4,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Color(0xFF7C3AED),
                                Color(0xFFEC4899),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          group.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF1E1B4B),
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final CatalogSpecies species in group.species)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _openDetails(species),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              child: Row(
                                children: <Widget>[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: species.imageUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: species.imageUrl!,
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                            placeholder: (_, _) => _thumb(),
                                            errorWidget: (_, _, _) => _thumb(),
                                          )
                                        : _thumb(),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          species.scientificName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF1E1B4B),
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.w600,
                                            height: 1.2,
                                          ),
                                        ),
                                        if (species.commonName.isNotEmpty &&
                                            species.commonName.toLowerCase() !=
                                                'common name')
                                          Text(
                                            species.commonName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF7C3AED),
                                              height: 1.2,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF7C3AED),
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

  // Grid view — same card style as CatalogScreen, no favorites
  Widget _buildGrid(List<CatalogSpecies> species) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      itemCount: species.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (BuildContext ctx, int i) {
        final CatalogSpecies item = species[i];
        return GestureDetector(
          onTap: () => _openDetails(item),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFDDD6FE)),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x147C3AED),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: item.imageUrl != null
                      ? Hero(
                          tag: _heroTagFor(item),
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (_, _) => Container(
                              color: const Color(0xFFEDE9FE),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.eco_outlined,
                                color: Color(0xFF7C3AED),
                                size: 32,
                              ),
                            ),
                            errorWidget: (_, _, _) => Container(
                              color: const Color(0xFFEDE9FE),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.eco_outlined,
                                color: Color(0xFF7C3AED),
                                size: 32,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFEDE9FE),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.eco_outlined,
                            color: Color(0xFF7C3AED),
                            size: 32,
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.scientificName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF1E1B4B),
                          height: 1.2,
                        ),
                      ),
                      if (item.commonName.isNotEmpty &&
                          item.commonName.toLowerCase() != 'common name') ...<Widget>[
                        const SizedBox(height: 3),
                        Text(
                          item.commonName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _thumb() => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      color: const Color(0xFFEDE9FE),
      borderRadius: BorderRadius.circular(14),
    ),
    alignment: Alignment.center,
    child: const Icon(Icons.eco_outlined, color: Color(0xFF7C3AED), size: 22),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

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
  bool _showPassword = false;

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
      backgroundColor: const Color(0xFFF5F1EA),
      body: Column(
        children: [
          // Gradient header strip
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 210,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.6, 1.0],
                    colors: [
                      Color(0xFF1E4F70),
                      Color(0xFF2B7BA8),
                      Color(0xFF1a6b9a),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -48,
                right: -48,
                child: Container(
                  width: 192,
                  height: 192,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(18),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -32,
                right: 32,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(13),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(38),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'logo.png',
                                height: 30,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'BLOOM',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Welcome back',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Form area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Sign in',
                    style: TextStyle(fontSize: 14, color: Color(0xFF60707E)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'EMAIL ADDRESS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF60707E),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF16212B),
                    ),
                    decoration: InputDecoration(
                      hintText: 'your@email.com',
                      prefixIcon: const Icon(
                        Icons.mail_outline_rounded,
                        color: _primaryColor,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2DDD5),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: _primaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PASSWORD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF60707E),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF16212B),
                    ),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: _primaryColor,
                        size: 18,
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            setState(() => _showPassword = !_showPassword),
                        child: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF60707E),
                          size: 18,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2DDD5),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: _primaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: _isSubmitting ? null : _submit,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: _isSubmitting
                            ? null
                            : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF1E4F70), Color(0xFF2B7BA8)],
                              ),
                        color: _isSubmitting ? const Color(0xFF8BAFCA) : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _isSubmitting
                            ? null
                            : const [
                                BoxShadow(
                                  color: Color(0x4D1E4F70),
                                  blurRadius: 24,
                                  offset: Offset(0, 8),
                                ),
                              ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _isSubmitting ? 'Signing in…' : 'Continue',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SignUpScreen(authController: widget.authController),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF60707E),
                          ),
                          children: [
                            TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: 'Sign Up',
                              style: TextStyle(
                                color: _primaryColor,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
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
      backgroundColor: const Color(0xFFF5F1EA),
      body: Column(
        children: [
          // Gradient header strip
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 175,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.6, 1.0],
                    colors: [
                      Color(0xFF1A3A4A),
                      Color(0xFF1E4F70),
                      Color(0xFF2B7BA8),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(38),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(28, 14, 28, 0),
                      child: Text(
                        'Join BLOOM',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Form area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create your researcher account',
                    style: TextStyle(fontSize: 14, color: Color(0xFF60707E)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'FULL NAME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF60707E),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF16212B),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Dr. Maria Santos',
                      prefixIcon: const Icon(
                        Icons.person_outline_rounded,
                        color: _primaryColor,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2DDD5),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: _primaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'EMAIL ADDRESS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF60707E),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF16212B),
                    ),
                    decoration: InputDecoration(
                      hintText: 'your@email.com',
                      prefixIcon: const Icon(
                        Icons.mail_outline_rounded,
                        color: _primaryColor,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2DDD5),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: _primaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'PASSWORD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF60707E),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF16212B),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Min. 6 characters',
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: _primaryColor,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2DDD5),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: _primaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: _isSubmitting ? null : _submit,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: _isSubmitting
                            ? null
                            : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF1E4F70), Color(0xFF2B7BA8)],
                              ),
                        color: _isSubmitting ? const Color(0xFF8BAFCA) : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _isSubmitting
                            ? null
                            : const [
                                BoxShadow(
                                  color: Color(0x4D1E4F70),
                                  blurRadius: 24,
                                  offset: Offset(0, 8),
                                ),
                              ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _isSubmitting ? 'Creating account…' : 'Create Account',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            LoginScreen(authController: widget.authController),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF60707E),
                          ),
                          children: [
                            TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                color: _primaryColor,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
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
  final NotificationController _notificationController =
      NotificationController();
  final Set<int> _activatedTabs = {};
  final List<Widget?> _cachedPages = List.filled(5, null);

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
    _activatedTabs.add(widget.initialTabIndex);
    _notificationController.load();
  }

  @override
  void dispose() {
    _notificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? user = widget.authController.user;
    final String profileName = user?.name.trim().isNotEmpty == true
        ? user!.name
        : 'Researcher 1';
    final String handleSource = user?.email.trim().isNotEmpty == true
        ? user!.email.split('@').first
        : profileName;
    final String normalizedHandle = handleSource.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    final String profileHandle = normalizedHandle.isNotEmpty
        ? '@$normalizedHandle'
        : '@researcher1';

    Widget pageForIndex(int i) {
      switch (i) {
        case 0:
          return HomeScreen(authController: widget.authController);
        case 1:
          return CatalogScreen(authController: widget.authController);
        case 2:
          return UploadScreen(authController: widget.authController);
        case 3:
          return MapScreen(authController: widget.authController);
        case 4:
          return _ResearcherProfileScreen(
            authController: widget.authController,
            fallbackName: profileName,
            fallbackHandle: profileHandle,
          );
        default:
          return const SizedBox.shrink();
      }
    }

    const List<IconData> selectedIcons = [
      Icons.home_rounded,
      Icons.library_books_rounded,
      Icons.add_circle_rounded,
      Icons.map_rounded,
      Icons.person_rounded,
    ];

    const List<IconData> unselectedIcons = [
      Icons.home_outlined,
      Icons.library_books_outlined,
      Icons.add_circle_outline_rounded,
      Icons.map_outlined,
      Icons.person_outline_rounded,
    ];

    const List<String> tabLabels = [
      'Home',
      'Catalog',
      'Upload',
      'Map',
      'Profile',
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: List.generate(5, (i) {
              if (!_activatedTabs.contains(i)) return const SizedBox.shrink();
              _cachedPages[i] ??= pageForIndex(i);
              return _cachedPages[i]!;
            }),
          ),
          // Show notification bell on all tabs except Map (3) and Home (0),
          // since Home has its own notification bell in the header.
          if (_selectedIndex != 3 && _selectedIndex != 0)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 20, 0),
                  child: ListenableBuilder(
                    listenable: _notificationController,
                    builder: (BuildContext context, _) {
                      final int count = _notificationController.unreadCount;
                      return Material(
                        color: Colors.transparent,
                        child: InkResponse(
                          onTap: () => Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => NotificationsScreen(
                                controller: _notificationController,
                              ),
                            ),
                          ),
                          radius: 24,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: <Widget>[
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _surfaceColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _lineColor),
                                ),
                                child: Icon(
                                  count > 0
                                      ? Icons.notifications_rounded
                                      : Icons.notifications_none_rounded,
                                  color: _primaryColor,
                                  size: 22,
                                ),
                              ),
                              if (count > 0)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: _accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      count > 99 ? '99+' : count.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        height: 1,
                                      ),
                                      textAlign: TextAlign.center,
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
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _surfaceColor,
          border: Border(top: BorderSide(color: _lineColor, width: 1)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List<Widget>.generate(5, (index) {
                final bool isSelected = index == _selectedIndex;
                final bool isUpload = index == 2;

                if (isUpload) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _activatedTabs.add(index);
                        _selectedIndex = index;
                      });
                    },
                    child: Transform.translate(
                      offset: const Offset(0, -16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isSelected
                                    ? const [
                                        Color(0xFF1E4F70),
                                        Color(0xFF2B7BA8),
                                      ]
                                    : const [
                                        Color(0xFF1A3A4A),
                                        Color(0xFF1E4F70),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x661E4F70),
                                  blurRadius: 16,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              isSelected
                                  ? selectedIcons[index]
                                  : unselectedIcons[index],
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tabLabels[index],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? _primaryColor
                                  : _mutedTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _activatedTabs.add(index);
                      _selectedIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _primaryColor.withAlpha(20)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected
                              ? selectedIcons[index]
                              : unselectedIcons[index],
                          color: isSelected ? _primaryColor : _mutedTextColor,
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tabLabels[index],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected ? _primaryColor : _mutedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
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
  final NotificationController _notificationController =
      NotificationController();

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboardData();
    _notificationController.load();
  }

  @override
  void dispose() {
    _notificationController.dispose();
    super.dispose();
  }

  Future<_HomeDashboardData> _loadDashboardData() async {
    try {
      final SupabaseClient supabase = Supabase.instance.client;

      final List<dynamic> results = await Future.wait([
        supabase.from('orchids').select('orchid_id'),
        supabase.from('species_sightings').select('sighting_id'),
        supabase
            .from('species_sightings')
            .select('sighting_id')
            .eq('review_status', 'pending'),
        supabase
            .from('orchids')
            .select('sci_name, common_name, picture(file_url)')
            .order('orchid_id', ascending: false)
            .limit(1),
      ]);

      final List<dynamic> orchidsData = results[0] as List<dynamic>;
      final List<dynamic> sightingsData = results[1] as List<dynamic>;
      final List<dynamic> pendingData = results[2] as List<dynamic>;
      final List<dynamic> latestData = results[3] as List<dynamic>;

      SpeciesHighlight highlight = defaultSpeciesOfTheDay;
      if (latestData.isNotEmpty) {
        final Map<String, dynamic> latest = Map<String, dynamic>.from(
          latestData.first as Map,
        );
        final List<dynamic>? pictures = latest['picture'] as List?;
        final String imageUrl = pictures != null && pictures.isNotEmpty
            ? (pictures.first['file_url'] ?? '').toString()
            : '';
        highlight = SpeciesHighlight(
          scientificName:
              (latest['sci_name'] ?? defaultSpeciesOfTheDay.scientificName)
                  .toString(),
          commonName:
              (latest['common_name'] ?? defaultSpeciesOfTheDay.commonName)
                  .toString(),
          imageUrl: imageUrl.isNotEmpty
              ? imageUrl
              : defaultSpeciesOfTheDay.imageUrl,
        );
      }

      return _HomeDashboardData(
        stats: AppStats(
          totalSpecies: orchidsData.length,
          pendingSubmissions: pendingData.length,
          totalSightings: sightingsData.length,
        ),
        speciesOfTheDay: highlight,
        isFallback: false,
      );
    } catch (_) {
      return const _HomeDashboardData.fallback();
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
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, _, _) => _ProfileOverlayPanel(
        authController: widget.authController,
        fallbackName: profileName,
        fallbackHandle: profileHandle,
      ),
      transitionBuilder: (ctx, animation, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String greetingName =
        widget.authController.user?.name.trim().isNotEmpty == true
        ? widget.authController.user!.name.split(' ').first
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
                final bool isLoading =
                    snapshot.connectionState == ConnectionState.waiting;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Profile avatar button (opens slide-in panel)
                          AnimatedBuilder(
                            animation: widget.authController,
                            builder: (_, _) {
                              final Uint8List? photoBytes = () {
                                final String encoded =
                                    widget
                                        .authController
                                        .user
                                        ?.profilePhotoBase64
                                        .trim() ??
                                    '';
                                if (encoded.isEmpty) return null;
                                try {
                                  return base64Decode(encoded);
                                } catch (_) {
                                  return null;
                                }
                              }();
                              return GestureDetector(
                                onTap: () => _openProfilePanel(context),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _lineColor,
                                      width: 1.5,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x1A1E4F70),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: photoBytes != null
                                        ? Image.memory(
                                            photoBytes,
                                            fit: BoxFit.cover,
                                            gaplessPlayback: true,
                                          )
                                        : const Icon(
                                            Icons.person_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          // Greeting text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good morning 🌿',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _mutedTextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Hello, $greetingName!',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    fontStyle: FontStyle.italic,
                                    color: _textColor,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Notification bell → navigates to NotificationsScreen
                          ListenableBuilder(
                            listenable: _notificationController,
                            builder: (_, _) {
                              final int count =
                                  _notificationController.unreadCount;
                              return GestureDetector(
                                onTap: () => Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => NotificationsScreen(
                                      controller: _notificationController,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _surfaceColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _lineColor,
                                      width: 1.5,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x0A000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(
                                        count > 0
                                            ? Icons.notifications_rounded
                                            : Icons.notifications_none_rounded,
                                        color: _primaryColor,
                                        size: 22,
                                      ),
                                      if (count > 0)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            width: 9,
                                            height: 9,
                                            decoration: const BoxDecoration(
                                              color: _accentColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // Scrollable content
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        children: [
                          // Section: Species of the Day
                          Text(
                            'SPECIES OF THE DAY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: _mutedTextColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
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
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: SizedBox(
                                height: 210,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: liveHighlight.imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      placeholder: (_, _) => Container(
                                        color: _surfaceTintColor,
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.eco_outlined,
                                          color: Color(0xFF7C3AED),
                                          size: 36,
                                        ),
                                      ),
                                      errorWidget: (_, _, _) => Container(
                                        color: _surfaceTintColor,
                                        alignment: Alignment.center,
                                        child: const Text(
                                          '🌸',
                                          style: TextStyle(fontSize: 60),
                                        ),
                                      ),
                                    ),
                                    // Bottom gradient
                                    const DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          stops: [0.45, 1.0],
                                          colors: [
                                            Colors.transparent,
                                            Color(0xD90A141E),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Species info overlay
                                    Positioned(
                                      left: 16,
                                      right: 16,
                                      bottom: 14,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            liveHighlight.scientificName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              fontStyle: FontStyle.italic,
                                              color: Colors.white,
                                              height: 1.1,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Text(
                                                liveHighlight.commonName,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white.withAlpha(
                                                    179,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '  ·  Tap to explore',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white.withAlpha(
                                                    153,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Section: Bloom Update
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'BLOOM UPDATE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  color: _mutedTextColor,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4ADE80),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isLoading ? 'Loading…' : 'Live data',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Main stat card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF1E4F70), Color(0xFF2B7BA8)],
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x401E4F70),
                                  blurRadius: 20,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Species Recorded',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withAlpha(179),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      liveStats.totalSpecies.toString(),
                                      style: const TextStyle(
                                        fontSize: 64,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 0.9,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        'orchid species',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white.withAlpha(179),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Two mini stat cards
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _surfaceColor,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x0A000000),
                                        blurRadius: 12,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pending',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _mutedTextColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        liveStats.pendingSubmissions.toString(),
                                        style: const TextStyle(
                                          fontSize: 38,
                                          fontWeight: FontWeight.w700,
                                          color: _accentColor,
                                          fontStyle: FontStyle.italic,
                                          height: 1.1,
                                        ),
                                      ),
                                      Text(
                                        'submissions',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _mutedTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _surfaceColor,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x0A000000),
                                        blurRadius: 12,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _mutedTextColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        liveStats.totalSightings.toString(),
                                        style: const TextStyle(
                                          fontSize: 38,
                                          fontWeight: FontWeight.w700,
                                          color: _primaryColor,
                                          fontStyle: FontStyle.italic,
                                          height: 1.1,
                                        ),
                                      ),
                                      Text(
                                        'sightings',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _mutedTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
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

class _ResearcherProfileScreen extends StatelessWidget {
  const _ResearcherProfileScreen({
    required this.authController,
    required this.fallbackName,
    required this.fallbackHandle,
  });

  final AppAuthController authController;
  final String fallbackName;
  final String fallbackHandle;

  String _resolvedName() {
    final String fromUser = authController.user?.name.trim() ?? '';
    if (fromUser.isNotEmpty) return fromUser;
    final String fromFallback = fallbackName.trim();
    return fromFallback.isNotEmpty ? fromFallback : 'Researcher 1';
  }

  String _resolvedHandle() {
    final String username = authController.user?.username.trim() ?? '';
    if (username.isNotEmpty) {
      return username.startsWith('@') ? username : '@$username';
    }
    final String fromFallback = fallbackHandle.trim();
    if (fromFallback.isNotEmpty) {
      return fromFallback.startsWith('@') ? fromFallback : '@$fromFallback';
    }
    final String fallback = _resolvedName().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    return fallback.isNotEmpty ? '@$fallback' : '@researcher1';
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => _EditProfileScreen(
          authController: authController,
          initialName: _resolvedName(),
          initialHandle: _resolvedHandle(),
          initialLocation:
              authController.user?.location.trim().isNotEmpty == true
              ? authController.user!.location
              : 'Mt. Busa, Kiamba, Sarangani Province',
        ),
        transitionsBuilder: (_, animation, _, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(fade),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _openMyUploads(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => const MyUploadsScreen(),
        transitionsBuilder: (_, animation, _, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(fade),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _openSubmissions(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => const UploadsStatusScreen(),
        transitionsBuilder: (_, animation, _, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(fade),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await authController.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => WelcomeScreen(authController: authController),
      ),
      (route) => false,
    );
  }

  Uint8List? _decodePhoto() {
    final String encoded = authController.user?.profilePhotoBase64.trim() ?? '';
    if (encoded.isEmpty) return null;
    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: AnimatedBuilder(
        animation: authController,
        builder: (BuildContext context, _) {
          final String name = _resolvedName();
          final String handle = _resolvedHandle();
          final String email = authController.user?.email ?? '';
          final String location =
              authController.user?.location.trim().isNotEmpty == true
              ? authController.user!.location
              : 'Mt. Busa, Sarangani';
          final Uint8List? photoBytes = _decodePhoto();

          final String initials = name.trim().isNotEmpty
              ? name
                    .trim()
                    .split(' ')
                    .take(2)
                    .map((w) => w[0])
                    .join()
                    .toUpperCase()
              : 'R';

          return Column(
            children: [
              // Gradient header
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E4F70), Color(0xFF2B7BA8)],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row
                        Row(
                          children: [
                            Text(
                              'Your Profile',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withAlpha(153),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _openProfile(context),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(38),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Avatar + info row
                        Row(
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(51),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withAlpha(89),
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: photoBytes != null
                                    ? Image.memory(
                                        photoBytes,
                                        fit: BoxFit.cover,
                                        gaplessPlayback: true,
                                      )
                                    : Center(
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      fontStyle: FontStyle.italic,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    handle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withAlpha(166),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Location + email meta
                        const SizedBox(height: 14),
                        if (location.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: Colors.white.withAlpha(153),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withAlpha(179),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.mail_outline_rounded,
                                size: 13,
                                color: Colors.white.withAlpha(153),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withAlpha(179),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Scrollable content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  children: [
                    Text(
                      'ACCOUNT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: _mutedTextColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ProfileMenuItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Edit Profile',
                      onTap: () => _openProfile(context),
                    ),
                    const SizedBox(height: 8),
                    _ProfileMenuItem(
                      icon: Icons.library_books_outlined,
                      label: 'My Uploads',
                      iconColor: _uploadPrimary,
                      iconBg: const Color(0xFFEDE9FE),
                      onTap: () => _openMyUploads(context),
                    ),
                    const SizedBox(height: 8),
                    _ProfileMenuItem(
                      icon: Icons.upload_file_outlined,
                      label: 'Submissions',
                      iconColor: const Color(0xFF059669),
                      iconBg: const Color(0xFFD1FAE5),
                      onTap: () => _openSubmissions(context),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'PREFERENCES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: _mutedTextColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DarkModeToggleRow(authController: authController),
                    const SizedBox(height: 16),
                    // Sign out button
                    GestureDetector(
                      onTap: () => _logout(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFEE2E2),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: Color(0xFFDC2626),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                'Sign Out',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        '🌺  BLOOM v1.0.0 · Mt. Busa Orchidaceae Conservation',
                        style: TextStyle(
                          fontSize: 11,
                          color: _mutedTextColor.withAlpha(153),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileOverlayPanel extends StatelessWidget {
  const _ProfileOverlayPanel({
    required this.authController,
    required this.fallbackName,
    required this.fallbackHandle,
  });

  final AppAuthController authController;
  final String fallbackName;
  final String fallbackHandle;

  String _resolvedName() {
    final String fromUser = authController.user?.name.trim() ?? '';
    if (fromUser.isNotEmpty) return fromUser;
    final String fromFallback = fallbackName.trim();
    return fromFallback.isNotEmpty ? fromFallback : 'Researcher 1';
  }

  String _resolvedHandle() {
    final String username = authController.user?.username.trim() ?? '';
    if (username.isNotEmpty) {
      return username.startsWith('@') ? username : '@$username';
    }
    final String fromFallback = fallbackHandle.trim();
    if (fromFallback.isNotEmpty) {
      return fromFallback.startsWith('@') ? fromFallback : '@$fromFallback';
    }
    final String fallback = _resolvedName().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    return fallback.isNotEmpty ? '@$fallback' : '@researcher1';
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => _EditProfileScreen(
          authController: authController,
          initialName: _resolvedName(),
          initialHandle: _resolvedHandle(),
          initialLocation:
              authController.user?.location.trim().isNotEmpty == true
              ? authController.user!.location
              : 'Mt. Busa, Kiamba, Sarangani Province',
        ),
        transitionsBuilder: (_, animation, _, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(fade),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _openMyUploads(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => const MyUploadsScreen(),
        transitionsBuilder: (_, animation, _, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(fade),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _openSubmissions(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => const UploadsStatusScreen(),
        transitionsBuilder: (_, animation, _, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(fade),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await authController.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => WelcomeScreen(authController: authController),
      ),
      (route) => false,
    );
  }

  Uint8List? _decodePhoto() {
    final String encoded = authController.user?.profilePhotoBase64.trim() ?? '';
    if (encoded.isEmpty) return null;
    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Slide-in panel (80% width)
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.82,
          child: Material(
            color: _appBackgroundColor,
            child: AnimatedBuilder(
              animation: authController,
              builder: (BuildContext context, _) {
                final String name = _resolvedName();
                final String handle = _resolvedHandle();
                final String email = authController.user?.email ?? '';
                final String location =
                    authController.user?.location.trim().isNotEmpty == true
                    ? authController.user!.location
                    : 'Mt. Busa, Sarangani';
                final Uint8List? photoBytes = _decodePhoto();
                final String initials = name.trim().isNotEmpty
                    ? name
                          .trim()
                          .split(' ')
                          .take(2)
                          .map((w) => w[0])
                          .join()
                          .toUpperCase()
                    : 'R';

                return Column(
                  children: [
                    // Gradient header
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E4F70), Color(0xFF2B7BA8)],
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Edit button row
                              Row(
                                children: [
                                  Text(
                                    'Your Profile',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withAlpha(153),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => _openProfile(context),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(38),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit_outlined,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Avatar + name
                              Row(
                                children: [
                                  Container(
                                    width: 76,
                                    height: 76,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(51),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withAlpha(89),
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: photoBytes != null
                                          ? Image.memory(
                                              photoBytes,
                                              fit: BoxFit.cover,
                                              gaplessPlayback: true,
                                            )
                                          : Center(
                                              child: Text(
                                                initials,
                                                style: const TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            fontStyle: FontStyle.italic,
                                            height: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          handle,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.white.withAlpha(166),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              if (location.isNotEmpty)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 13,
                                      color: Colors.white.withAlpha(153),
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        location,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withAlpha(179),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              if (email.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.mail_outline_rounded,
                                      size: 13,
                                      color: Colors.white.withAlpha(153),
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withAlpha(179),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Scrollable menu
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        children: [
                          Text(
                            'ACCOUNT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: _mutedTextColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _ProfileMenuItem(
                            icon: Icons.person_outline_rounded,
                            label: 'Edit Profile',
                            onTap: () => _openProfile(context),
                          ),
                          const SizedBox(height: 8),
                          _ProfileMenuItem(
                            icon: Icons.library_books_outlined,
                            label: 'My Uploads',
                            iconColor: _uploadPrimary,
                            iconBg: const Color(0xFFEDE9FE),
                            onTap: () => _openMyUploads(context),
                          ),
                          const SizedBox(height: 8),
                          _ProfileMenuItem(
                            icon: Icons.upload_file_outlined,
                            label: 'Submissions',
                            iconColor: const Color(0xFF059669),
                            iconBg: const Color(0xFFD1FAE5),
                            onTap: () => _openSubmissions(context),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'PREFERENCES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: _mutedTextColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _DarkModeToggleRow(authController: authController),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => _logout(context),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFFEE2E2),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.logout_rounded,
                                      color: Color(0xFFDC2626),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Text(
                                      'Sign Out',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Text(
                              '🌺  BLOOM v1.0.0 · Mt. Busa Orchidaceae Conservation',
                              style: TextStyle(
                                fontSize: 11,
                                color: _mutedTextColor.withAlpha(153),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        // Tap-to-dismiss area (right 18%)
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
      ],
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
                        decoration: BoxDecoration(
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
    this.iconColor = _primaryColor,
    this.iconBg = const Color(0xFFE8F0F7),
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0EBE3), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _mutedTextColor,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarkModeToggleRow extends StatelessWidget {
  const _DarkModeToggleRow({required this.authController});

  final AppAuthController authController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _lineColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              authController.isDarkMode
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Dark Mode',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: _textColor,
              ),
            ),
          ),
          Switch(
            value: authController.isDarkMode,
            onChanged: (_) => authController.toggleDarkMode(),
            activeThumbColor: _primaryColor,
            activeTrackColor: _primaryColor.withAlpha(160),
          ),
        ],
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
  final Set<int> _favorites = <int>{};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Cached results — recomputed only when data or query changes, not every build.
  List<CatalogSpecies> _allSpecies = <CatalogSpecies>[];
  List<CatalogSpecies> _filteredSpecies = <CatalogSpecies>[];
  List<CatalogGroup> _filteredGroups = <CatalogGroup>[];

  @override
  void initState() {
    super.initState();
    _speciesFuture = _loadCatalogSpecies();
    _speciesFuture.then((List<CatalogSpecies> species) {
      if (mounted) {
        setState(() {
          _allSpecies = species;
          _recomputeFilter();
        });
      }
    }).ignore();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final String q = _searchController.text.toLowerCase().trim();
    if (q == _searchQuery) return;
    setState(() {
      _searchQuery = q;
      _recomputeFilter();
    });
  }

  void _recomputeFilter() {
    if (_allSpecies.isEmpty) {
      _filteredSpecies = <CatalogSpecies>[];
      _filteredGroups = <CatalogGroup>[];
      return;
    }
    _filteredSpecies = _searchQuery.isEmpty
        ? _allSpecies
        : _allSpecies
              .where(
                (CatalogSpecies s) =>
                    s.scientificName.toLowerCase().contains(_searchQuery) ||
                    s.commonName.toLowerCase().contains(_searchQuery) ||
                    s.genus.toLowerCase().contains(_searchQuery),
              )
              .toList(growable: false);
    _filteredGroups = _groupSpecies(_filteredSpecies);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
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
    try {
      final List<dynamic> data = await Supabase.instance.client
          .from('orchids')
          .select(
            'orchid_id, sci_name, common_name, local_name, genus(genus_name), picture(file_url)',
          )
          .order('sci_name');

      final List<CatalogSpecies> mapped = data
          .whereType<Map>()
          .map((Map item) {
            final Map<String, dynamic> json = Map<String, dynamic>.from(item);
            final String scientificName = (json['sci_name'] ?? '')
                .toString()
                .trim();
            if (scientificName.isEmpty) return null;

            final dynamic genusData = json['genus'];
            final String genus = genusData is Map
                ? (genusData['genus_name'] ?? '').toString()
                : '';

            final dynamic pictureData = json['picture'];
            final String imageUrl =
                pictureData is List && pictureData.isNotEmpty
                ? (pictureData.first['file_url'] ?? '').toString()
                : '';

            final String localName = (json['local_name'] ?? '').toString().trim();
            return CatalogSpecies(
              id: int.tryParse((json['orchid_id'] ?? '').toString()),
              scientificName: scientificName,
              commonName: (json['common_name'] ?? 'Common Name')
                  .toString()
                  .trim(),
              genus: genus,
              imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
              latitude: null,
              longitude: null,
              localName: localName.isNotEmpty ? localName : null,
            );
          })
          .whereType<CatalogSpecies>()
          .toList(growable: false);

      return mapped.isEmpty ? _fallbackCatalogSpecies() : mapped;
    } catch (_) {
      return _fallbackCatalogSpecies();
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

    if (!mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, _, _) => _ProfileOverlayPanel(
        authController: widget.authController,
        fallbackName: profileName,
        fallbackHandle: profileHandle,
      ),
      transitionBuilder: (ctx, animation, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                )
              : null,
          color: selected ? null : const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  const BoxShadow(
                    color: Color(0x337C3AED),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: selected ? Colors.white : const Color(0xFF7C3AED),
        ),
      ),
    );
  }

  Widget _buildCatalogList(List<CatalogGroup> groups) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      children: [
        for (final CatalogGroup group in groups)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFDDD6FE)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x147C3AED),
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          group.title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF1E1B4B),
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final CatalogSpecies species in group.species)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _openSpeciesDetails(species),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  // Thumbnail
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: species.imageUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: species.imageUrl!,
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                            placeholder: (_, _) => Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEDE9FE),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              alignment: Alignment.center,
                                              child: const Icon(Icons.eco_outlined, color: Color(0xFF7C3AED), size: 22),
                                            ),
                                            errorWidget: (_, _, _) => Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEDE9FE),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              alignment: Alignment.center,
                                              child: const Icon(Icons.eco_outlined, color: Color(0xFF7C3AED), size: 22),
                                            ),
                                          )
                                        : Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEDE9FE),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.eco_outlined,
                                              color: Color(0xFF7C3AED),
                                              size: 22,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Name info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          species.scientificName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF1E1B4B),
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.w600,
                                            height: 1.2,
                                          ),
                                        ),
                                        if (species.commonName.isNotEmpty &&
                                            species.commonName.toLowerCase() !=
                                                'common name')
                                          Text(
                                            species.commonName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF7C3AED),
                                              height: 1.2,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Heart button
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (species.id != null) {
                                          if (_favorites.contains(species.id)) {
                                            _favorites.remove(species.id);
                                          } else {
                                            _favorites.add(species.id!);
                                          }
                                        }
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Icon(
                                        species.id != null &&
                                                _favorites.contains(species.id)
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        size: 20,
                                        color:
                                            species.id != null &&
                                                _favorites.contains(species.id)
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFF7C3AED),
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF7C3AED),
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
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      itemCount: allSpecies.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (BuildContext context, int index) {
        final CatalogSpecies item = allSpecies[index];
        final bool isFav = item.id != null && _favorites.contains(item.id);

        return GestureDetector(
          onTap: () => _openSpeciesDetails(item),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFDDD6FE)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x147C3AED),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image area with overlays
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image
                      item.imageUrl != null
                          ? Hero(
                              tag: _heroTagFor(item),
                              child: CachedNetworkImage(
                                imageUrl: item.imageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (_, _) => Container(
                                  color: const Color(0xFFEDE9FE),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.eco_outlined, color: Color(0xFF7C3AED), size: 32),
                                ),
                                errorWidget: (_, _, _) => Container(
                                  color: const Color(0xFFEDE9FE),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.eco_outlined, color: Color(0xFF7C3AED), size: 32),
                                ),
                              ),
                            )
                          : Container(
                              color: const Color(0xFFEDE9FE),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.eco_outlined,
                                color: Color(0xFF7C3AED),
                                size: 32,
                              ),
                            ),
                      // Heart button top-right
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (item.id != null) {
                                if (_favorites.contains(item.id)) {
                                  _favorites.remove(item.id);
                                } else {
                                  _favorites.add(item.id!);
                                }
                              }
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              isFav
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 16,
                              color: isFav
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Name section
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.scientificName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E1B4B),
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      if (item.commonName.isNotEmpty &&
                          item.commonName.toLowerCase() != 'common name') ...[
                        const SizedBox(height: 2),
                        Text(
                          item.commonName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF7C3AED),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
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
              Text(
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
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (String v) =>
                    setState(() => _searchQuery = v.trim().toLowerCase()),
                style: TextStyle(fontSize: 14, color: Color(0xFF1E1B4B)),
                decoration: InputDecoration(
                  hintText: 'Search orchids by name or genus...',
                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF7C3AED),
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () => setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          }),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF7C3AED),
                            size: 18,
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF5F3FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFDDD6FE)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFDDD6FE)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Color(0xFF7C3AED),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<CatalogSpecies>>(
                  future: _speciesFuture,
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<List<CatalogSpecies>> snapshot,
                      ) {
                        // Use pre-cached results; fall back to computed values
                        // only while the future is still loading.
                        final List<CatalogSpecies> filtered =
                            _filteredSpecies.isNotEmpty ||
                                _allSpecies.isNotEmpty
                            ? _filteredSpecies
                            : (snapshot.data != null
                                  ? snapshot.data!
                                  : _fallbackCatalogSpecies());
                        final List<CatalogGroup> groups =
                            _filteredGroups.isNotEmpty
                            ? _filteredGroups
                            : _groupSpecies(filtered);

                        if (filtered.isEmpty && _searchQuery.isNotEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.search_off_rounded,
                                  size: 52,
                                  color: Color(0xFFDDD6FE),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'No orchids found for\n"$_searchQuery"',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF7C3AED),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

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
                                  child: _buildCatalogGrid(filtered),
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

class _SightingTeamMember {
  const _SightingTeamMember(this.name, this.role);
  final String name;
  final String role;
}

class _SightingTeam {
  const _SightingTeam(this.date, this.members);
  final String date;
  final List<_SightingTeamMember> members;
}

class CatalogSpeciesDetailsScreen extends StatefulWidget {
  const CatalogSpeciesDetailsScreen({
    required this.species,
    this.isGuest = false,
    super.key,
  });

  final CatalogSpecies species;
  final bool isGuest;

  @override
  State<CatalogSpeciesDetailsScreen> createState() =>
      _CatalogSpeciesDetailsScreenState();
}

class _CatalogSpeciesDetailsScreenState
    extends State<CatalogSpeciesDetailsScreen> {
  int _selectedTab = 0;
  int _tappedPinIndex = -1;
  double _catalogMapZoom = 13.0;
  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey _tabSectionKey = GlobalKey();

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
        normalized == 'paphiopedilum urbanianum' ||
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

  List<String> get _sightingDates {
    if (_seedSlug == 'paphiopedilum-urbanianum') {
      return const <String>[
        'Nov. 22, 2024',
        'Dec. 8, 2024',
        'Jan. 10, 2025',
        'Feb. 4, 2025',
        'Mar. 15, 2025',
      ];
    }
    if (_seedSlug == 'vanda-sanderiana') {
      return const <String>['Dec. 1, 2024', 'Dec. 9, 2024', 'Dec. 22, 2024'];
    }
    return const <String>['Nov. 28, 2024', 'Dec. 7, 2024', 'Dec. 19, 2024'];
  }

  String get _sightingLocation => 'Mt. Busa, Kiamba, Sarangani';

  String get _sightingAltitude {
    if (_seedSlug == 'paphiopedilum-urbanianum') {
      return '980 meters above sea level';
    }
    if (_seedSlug == 'vanda-sanderiana') {
      return '200 meters above sea level';
    }
    return '185 meters above sea level';
  }

  String get _sightingElevation {
    if (_seedSlug == 'paphiopedilum-urbanianum') {
      return '1,020 meters above sea level';
    }
    if (_seedSlug == 'vanda-sanderiana') {
      return '175 meters above sea level';
    }
    return '162 meters above sea level';
  }

  String get _sightingHabitatType {
    if (_seedSlug == 'paphiopedilum-urbanianum') {
      return 'Mossy montane forest';
    }
    if (_endemicity == 'Native to the Philippines') {
      return 'Montane forest';
    }
    return 'Secondary forest edge';
  }

  String get _sightingMicroHabitat {
    if (_seedSlug == 'paphiopedilum-urbanianum') {
      return 'Terrestrial on mossy limestone outcroppings';
    }
    return 'Epiphytic on mossy branches';
  }

  String get _localName {
    if (widget.species.localName != null &&
        widget.species.localName!.isNotEmpty) {
      return widget.species.localName!;
    }
    if (_seedSlug == 'vanda-sanderiana') return 'Waling-waling';
    if (_seedSlug == 'paphiopedilum-urbanianum') return 'Higpit na Tambol';
    return 'Not recorded';
  }

  // One pin per recorded sighting, scattered in the vegetation around the trail
  // (not on the trail line itself) based on field-recorded GPS offsets.
  List<LatLng> get _sightingPins {
    if (_seedSlug == 'paphiopedilum-urbanianum') {
      // 5 sightings — mossy slopes flanking Camp 1 zone (~980 m ASL)
      return const <LatLng>[
        LatLng(6.0912, 124.7216),
        LatLng(6.0894, 124.7213),
        LatLng(6.0918, 124.7194),
        LatLng(6.0890, 124.7188),
        LatLng(6.0908, 124.7182),
      ];
    }
    if (_seedSlug == 'vanda-sanderiana') {
      // 3 sightings — canopy fringe near lower trail (~200 m ASL)
      return const <LatLng>[
        LatLng(6.0740, 124.7398),
        LatLng(6.0722, 124.7393),
        LatLng(6.0736, 124.7370),
      ];
    }
    // 3 sightings — secondary forest edge near jump-off (~185 m ASL)
    return const <LatLng>[
      LatLng(6.0723, 124.7415),
      LatLng(6.0706, 124.7417),
      LatLng(6.0728, 124.7387),
    ];
  }

  static const List<_SightingTeamMember> _defaultTeam = <_SightingTeamMember>[
    _SightingTeamMember('Abedin', 'Team Lead'),
    _SightingTeamMember('Utrera', 'Researcher'),
    _SightingTeamMember('Pecajas', 'Researcher/Photographer'),
  ];

  List<_SightingTeam> get _sightingTeams {
    return _sightingDates
        .map((String date) => _SightingTeam(date, _defaultTeam))
        .toList(growable: false);
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

  // ── New detail screen helpers ──────────────────────────────────────────

  Widget _detailInfoRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Color(0xFF7C3AED),
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Color(0xFF4C1D95),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: Color(0xFF4C1D95),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _detailBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: Color(0xFF7C3AED), fontSize: 14),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Color(0xFF4C1D95),
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailSubheader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF7C3AED),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final bool selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                  )
                : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Colors.transparent : const Color(0xFFDDD6FE),
            ),
            boxShadow: selected
                ? [
                    const BoxShadow(
                      color: Color(0x337C3AED),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 19,
                color: selected ? Colors.white : const Color(0xFF7C3AED),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeciesValueContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40EC4899),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Conservation Status',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _endemicity == 'Native to the Philippines'
                    ? 'Endangered'
                    : 'Vulnerable',
                style: TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Recorded ${_sightingDates.length} time${_sightingDates.length == 1 ? '' : 's'} in the wild',
                style: TextStyle(fontSize: 12, color: Color(0xFFFFE4F0)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _detailSectionCard(
          title: 'Morphological Characteristics',
          children: _seedSlug == 'paphiopedilum-urbanianum'
              ? <Widget>[
                  _detailSubheader('Plant Structure'),
                  _detailInfoRow(label: 'Plant Height', value: '15–25 cm'),
                  _detailInfoRow(label: 'Pseudobulb', value: 'Absent'),
                  _detailInfoRow(label: 'Root Length', value: '8–15 cm'),
                  const SizedBox(height: 8),
                  _detailSubheader('Leaves'),
                  _detailInfoRow(label: 'No. of Leaves', value: '4–6'),
                  _detailInfoRow(
                    label: 'Leaf Shape',
                    value: 'Strap-shaped, tessellated',
                  ),
                  _detailInfoRow(label: 'Leaf Length', value: '8–12 cm'),
                  _detailInfoRow(label: 'Leaf Width', value: '3–4 cm'),
                  const SizedBox(height: 8),
                  _detailSubheader('Flowers'),
                  _detailInfoRow(label: 'Flowers per Stem', value: '1–2'),
                  _detailInfoRow(label: 'Bloom Duration', value: '6–8 weeks'),
                  _detailInfoRow(
                    label: 'Petal Color',
                    value: 'Cream with maroon veining',
                  ),
                  _detailInfoRow(
                    label: 'Pouch Color',
                    value: 'Yellowish-green with brown spots',
                  ),
                  const SizedBox(height: 8),
                  _detailSubheader('Fruits / Seeds'),
                  _detailInfoRow(
                    label: 'Fruit Type',
                    value: 'Ellipsoid capsule',
                  ),
                  _detailInfoRow(label: 'Fruit Length', value: '3–5 cm'),
                  _detailInfoRow(
                    label: 'Seed Dispersal',
                    value: 'Wind-dispersed (anemochory)',
                  ),
                ]
              : <Widget>[
                  const Text(
                    'No recorded morphological data',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6D28D9)),
                  ),
                ],
        ),
        const SizedBox(height: 12),
        _detailSectionCard(
          title: 'Ethnobotanical Importance',
          children: _seedSlug == 'paphiopedilum-urbanianum'
              ? <Widget>[
                  _detailBullet(
                    'Traditionally sought by B\'laan and T\'boli communities of Sarangani Province for cultural ceremonies and floral displays.',
                  ),
                  _detailBullet(
                    'Considered a symbol of highland biodiversity; featured in indigenous ceremonial arrangements.',
                  ),
                  _detailBullet(
                    'Historically traded among upland communities for its ornamental and ceremonial significance.',
                  ),
                ]
              : <Widget>[
                  const Text(
                    'No recorded ethnobotanical importance',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6D28D9)),
                  ),
                ],
        ),
        const SizedBox(height: 12),
        _detailSectionCard(
          title: 'Horticulture Value',
          children: _seedSlug == 'paphiopedilum-urbanianum'
              ? <Widget>[
                  _detailBullet(
                    'Aesthetic Appeal: Distinctive pouch-shaped flower with waxy cream petals and deep maroon veining; highly ornamental.',
                  ),
                  _detailBullet(
                    'Cultivation: Requires cool, humid montane conditions (15–22 °C); slow-growing; suited for specialist collections.',
                  ),
                  _detailBullet(
                    'Rarity: Extremely rare in cultivation; commands premium value in international orchid trade.',
                  ),
                  _detailBullet(
                    'Trade Status: Strictly protected under CITES Appendix I; commercial trade prohibited without permit.',
                  ),
                ]
              : <Widget>[
                  _detailBullet(
                    'Aesthetic Appeal: ${_normalizedCommonName == 'Waling-waling' ? 'Vibrant, showy blooms' : 'Distinctive bloom clusters'}',
                  ),
                  _detailBullet(
                    'Cultivation: Adaptable, low maintenance under stable humidity',
                  ),
                  _detailBullet(
                    'Rarity: ${_endemicity == 'Native to the Philippines' ? 'Native endemic orchid' : 'Locally observed in mixed habitats'}',
                  ),
                ],
        ),
        const SizedBox(height: 12),
        _detailSectionCard(
          title: 'Ecological & Biological Data',
          children: _seedSlug == 'paphiopedilum-urbanianum'
              ? <Widget>[
                  _detailBullet(
                    'Life Stage: Mature adult — reproductive stage confirmed at sighting location.',
                  ),
                  _detailBullet(
                    'Phenology: Flowers November to March; peak bloom December–January.',
                  ),
                  _detailBullet(
                    'Population Status: Rare — fewer than 50 individuals documented at Mt. Busa site.',
                  ),
                  _detailBullet(
                    'Threat Level: High — primary threats are illegal wild collection and habitat loss from land conversion.',
                  ),
                ]
              : <Widget>[
                  _detailBullet('Life Stage: No recorded life stage'),
                  _detailBullet('Phenology: No recorded phenology'),
                  _detailBullet(
                    'Population Status: No recorded population status',
                  ),
                  _detailBullet('Threat Level: No recorded threat level'),
                ],
        ),
      ],
    );
  }

  Widget _buildDatePill(String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 12,
            color: Color(0xFF7C3AED),
          ),
          const SizedBox(width: 6),
          Text(
            date,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4C1D95),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSightingSheet() {
    final flowData = UploadSpeciesFlowData(
      scientificName: widget.species.scientificName,
      genus: widget.species.genus,
      commonNames:
          (widget.species.commonName.isNotEmpty &&
              widget.species.commonName.toLowerCase() != 'common name')
          ? [widget.species.commonName]
          : [],
      mountain: 'Mt. Busa',
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UploadSpeciesInformationScreen(flowData: flowData),
      ),
    );
  }

  Widget _buildSightingsContent() {
    final String date = _sightingDates[_tappedPinIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailSectionCard(
          title: 'Recorded Sighting',
          children: [
            _buildDatePill(date),
          ],
        ),
        const SizedBox(height: 12),
        _detailSectionCard(
          title: 'Location & Habitat',
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: Color(0xFFEC4899),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                      Text(
                        _sightingLocation,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4C1D95),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.landscape_rounded,
                  size: 16,
                  color: Color(0xFFEC4899),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Altitude',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                      Text(
                        _sightingAltitude,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4C1D95),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.height_rounded,
                  size: 16,
                  color: Color(0xFFEC4899),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Elevation',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                      Text(
                        _sightingElevation,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4C1D95),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.forest_rounded,
                  size: 16,
                  color: Color(0xFFEC4899),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Habitat Type',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                      Text(
                        _sightingHabitatType,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4C1D95),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.grass_rounded,
                  size: 16,
                  color: Color(0xFFEC4899),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Micro Habitat',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                      Text(
                        _sightingMicroHabitat,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4C1D95),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _detailSectionCard(
          title: 'Contributors',
          children: [_buildTeamCard(_sightingTeams[_tappedPinIndex])],
        ),
      ],
    );
  }

  Widget _buildTeamCard(_SightingTeam team) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFF7C3AED),
            child: Text(
              '${team.date} Sighting Team',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                for (int j = 0; j < team.members.length; j++) ...[
                  if (j > 0) const Divider(height: 1, color: Color(0xFFD8B4FE)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                Color(0xFF7C3AED),
                                Color(0xFFEC4899),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            team.members[j].name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            team.members[j].name,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4C1D95),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          team.members[j].role,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesContent() {
    final String? imageUrl = widget.species.imageUrl;
    final String date = _sightingDates[_tappedPinIndex];
    return _detailSectionCard(
      title: 'Sighting Image',
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 13,
              color: Color(0xFF7C3AED),
            ),
            const SizedBox(width: 5),
            Text(
              date,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => _sightingImagePlaceholder(),
                  errorWidget: (_, _, _) => _sightingImagePlaceholder(),
                )
              : _sightingImagePlaceholder(),
        ),
      ],
    );
  }

  Widget _sightingImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.eco_outlined, color: Color(0xFF7C3AED), size: 36),
    );
  }

  String get _studyTitle {
    if (_seedSlug == 'paphiopedilum-urbanianum') {
      return 'Conservation Status and Distribution of Paphiopedilum urbanianum in Southern Mindanao';
    }
    if (_seedSlug == 'vanda-sanderiana') {
      return 'Ecology and Conservation of Vanda sanderiana in the Mt. Apo Region';
    }
    return 'Orchid Diversity and Habitat Assessment in Sarangani Province';
  }

  String get _studyAuthors {
    if (_seedSlug == 'paphiopedilum-urbanianum') {
      return 'Abedin, A., Utrera, C.J., & Pecajas, R. (2025)';
    }
    if (_seedSlug == 'vanda-sanderiana') {
      return 'Utrera, C.J., Abedin, A., & Pecajas, R. (2024)';
    }
    return 'Pecajas, R., Utrera, C.J., & Abedin, A. (2025)';
  }

  String get _studyInstitution => 'Mindanao State University – General Santos City';

  String get _studyAbstract {
    if (_seedSlug == 'paphiopedilum-urbanianum') {
      return 'This study documents the population size, distribution, and conservation status of Paphiopedilum urbanianum within the mossy montane forests of Mt. Busa. Field surveys were conducted across five transects at elevations between 900–1,100 m ASL, recording habitat parameters, population densities, and anthropogenic threats.';
    }
    if (_seedSlug == 'vanda-sanderiana') {
      return 'A comprehensive ecological survey of Vanda sanderiana (Waling-waling) populations in the Mt. Apo Natural Park buffer zones, focusing on canopy microhabitat associations, epiphytic substrate preferences, and flowering phenology across three seasons.';
    }
    return 'A floristic survey of orchid diversity in the secondary forests of Sarangani Province, cataloguing species richness, endemic taxa, and habitat condition across six survey sites at varying elevations.';
  }

  Widget _buildRelatedStudyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailSectionCard(
          title: 'Related Study',
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.article_outlined,
                  size: 16,
                  color: Color(0xFFEC4899),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Title',
                        style: TextStyle(fontSize: 11, color: Color(0xFF7C3AED)),
                      ),
                      Text(
                        _studyTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4C1D95),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: Color(0xFFEC4899),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Authors',
                        style: TextStyle(fontSize: 11, color: Color(0xFF7C3AED)),
                      ),
                      Text(
                        _studyAuthors,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4C1D95),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.account_balance_outlined,
                  size: 16,
                  color: Color(0xFFEC4899),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Institution',
                        style: TextStyle(fontSize: 11, color: Color(0xFF7C3AED)),
                      ),
                      Text(
                        _studyInstitution,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4C1D95),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _detailSectionCard(
          title: 'Abstract',
          children: [
            Text(
              _studyAbstract,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4C1D95),
                height: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Marker _buildPinMarker(LatLng pt, int index, {bool showCallout = false}) {
    final String label = widget.species.scientificName;
    final bool isSelected = _tappedPinIndex == index;
    return Marker(
      point: pt,
      width: showCallout ? 160.0 : 40.0,
      height: showCallout ? 76.0 : 40.0,
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onTap: () => _onPinTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showCallout) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x337C3AED),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFDDD6FE), width: 1),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF4C1D95),
                  ),
                ),
              ),
              const SizedBox(height: 2),
            ],
            Image.asset(
              'orchidpin.png',
              width: isSelected ? 28 : 22,
              height: isSelected ? 34 : 28,
              fit: BoxFit.contain,
              color: isSelected ? const Color(0xFF7C3AED) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogMapPreview() {
    final List<LatLng> pins = _sightingPins;
    final int count = pins.length;
    final bool showCallout = _catalogMapZoom >= 15.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x227C3AED),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: double.infinity,
              height: 280,
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: const LatLng(6.090, 124.713),
                      initialZoom: 13.0,
                      minZoom: 10,
                      maxZoom: 19,
                      onMapEvent: (MapEvent event) {
                        final double z = event.camera.zoom;
                        if ((z >= 15.0) != (_catalogMapZoom >= 15.0)) {
                          setState(() => _catalogMapZoom = z);
                        } else {
                          _catalogMapZoom = z;
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.example.flutter_application_1',
                        maxNativeZoom: 18,
                        keepBuffer: 2,
                      ),
                      if (!widget.isGuest) _kTrailPolylineLayer,
                      MarkerLayer(
                        markers: <Marker>[
                          for (int i = 0; i < pins.length; i++)
                            _buildPinMarker(
                              pins[i],
                              i,
                              showCallout: showCallout,
                            ),
                        ],
                      ),
                    ],
                  ),
                  // Fullscreen button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _CatalogMapFullScreen(
                            scientificName: widget.species.scientificName,
                            pins: pins,
                            isGuest: widget.isGuest,
                          ),
                        ),
                      ),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x337C3AED),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.fullscreen_rounded,
                          size: 22,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.place_rounded, size: 13, color: Color(0xFF7C3AED)),
            const SizedBox(width: 5),
            Text(
              '$count recorded sighting${count == 1 ? '' : 's'} · tap a pin to explore',
              style: const TextStyle(fontSize: 12, color: Color(0xFF7C3AED)),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onPinTapped(int index) {
    setState(() => _tappedPinIndex = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _tabSectionKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          alignment: 0.0,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String primaryImage = _galleryImages.isNotEmpty
        ? _galleryImages.first
        : '';
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      floatingActionButton: widget.isGuest
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddSightingSheet,
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_location_alt_rounded, size: 20),
              label: const Text(
                'Log Sighting',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFDDD6FE)),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFF7C3AED),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '... / Genus / $_genus / Species / ${widget.species.scientificName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7C3AED),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Scrollable body ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero image with gradient fade at bottom
                    Stack(
                      children: [
                        Hero(
                          tag: _heroTag,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(32),
                              bottomRight: Radius.circular(32),
                            ),
                            child: primaryImage.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: primaryImage,
                                    width: double.infinity,
                                    height: 240,
                                    fit: BoxFit.cover,
                                    placeholder: (_, _) => _heroFallback(),
                                    errorWidget: (_, _, _) => _heroFallback(),
                                  )
                                : _heroFallback(),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Color(0xF5F8F7FF), Colors.transparent],
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(32),
                                bottomRight: Radius.circular(32),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Name section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.species.scientificName,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF1E1B4B),
                              height: 1.1,
                            ),
                          ),
                          if (_normalizedCommonName !=
                              'No recorded common name') ...[
                            const SizedBox(height: 4),
                            Text(
                              _normalizedCommonName,
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF7C3AED),
                                height: 1.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Species info card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _detailSectionCard(
                        title: 'Species Information',
                        children: [
                          _detailInfoRow(label: 'Family', value: 'Orchidaceae'),
                          const Divider(height: 1, color: Color(0xFFDDD6FE)),
                          _detailInfoRow(label: 'Genus', value: _genus),
                          const Divider(height: 1, color: Color(0xFFDDD6FE)),
                          _detailInfoRow(
                            label: 'Species',
                            value: _speciesEpithet,
                          ),
                          const Divider(height: 1, color: Color(0xFFDDD6FE)),
                          _detailInfoRow(
                            label: 'Common Name',
                            value: _detailedCommonName,
                          ),
                          const Divider(height: 1, color: Color(0xFFDDD6FE)),
                          _detailInfoRow(
                            label: 'Local Name',
                            value: _localName,
                          ),
                          const Divider(height: 1, color: Color(0xFFDDD6FE)),
                          _detailInfoRow(
                            label: 'Endemicity',
                            value: _endemicity,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Orchid pin map preview
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildCatalogMapPreview(),
                    ),
                    if (_tappedPinIndex >= 0) ...[
                      SizedBox(key: _tabSectionKey, height: 20),
                      // Selected sighting label
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.place_rounded,
                              size: 14,
                              color: Color(0xFF7C3AED),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Sighting #${_tappedPinIndex + 1}  ·  ${_sightingDates[_tappedPinIndex]}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tab selector
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            _buildTabButton(
                              0,
                              Icons.diamond_outlined,
                              'Species Value',
                            ),
                            const SizedBox(width: 8),
                            _buildTabButton(
                              1,
                              Icons.visibility_outlined,
                              'Sightings',
                            ),
                            const SizedBox(width: 8),
                            _buildTabButton(
                              2,
                              Icons.photo_library_outlined,
                              'Images',
                            ),
                            const SizedBox(width: 8),
                            _buildTabButton(
                              3,
                              Icons.menu_book_outlined,
                              'Related Study',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tab content with fade+slide animation
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position:
                                        Tween<Offset>(
                                          begin: const Offset(0.04, 0),
                                          end: Offset.zero,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic,
                                          ),
                                        ),
                                    child: child,
                                  ),
                                );
                              },
                          child: KeyedSubtree(
                            key: ValueKey<int>(_selectedTab),
                            child: switch (_selectedTab) {
                              0 => _buildSpeciesValueContent(),
                              1 => _buildSightingsContent(),
                              2 => _buildImagesContent(),
                              _ => _buildRelatedStudyContent(),
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroFallback() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.eco_outlined, color: Colors.white54, size: 64),
    );
  }
}

// ── Catalog Map Full Screen ───────────────────────────────────────────────────

class _CatalogMapFullScreen extends StatefulWidget {
  const _CatalogMapFullScreen({
    required this.scientificName,
    required this.pins,
    this.isGuest = false,
  });

  final String scientificName;
  final List<LatLng> pins;
  final bool isGuest;

  @override
  State<_CatalogMapFullScreen> createState() => _CatalogMapFullScreenState();
}

class _CatalogMapFullScreenState extends State<_CatalogMapFullScreen> {
  double _zoom = 13.0;

  Marker _buildPin(LatLng pt) {
    final bool showCallout = _zoom >= 15.0;
    return Marker(
      point: pt,
      width: showCallout ? 160.0 : 40.0,
      height: showCallout ? 68.0 : 40.0,
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCallout) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x337C3AED),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: Text(
                widget.scientificName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4C1D95),
                ),
              ),
            ),
            const SizedBox(height: 2),
          ],
          Image.asset(
            'orchidpin.png',
            width: 22,
            height: 28,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(6.090, 124.713),
              initialZoom: 13.0,
              minZoom: 10,
              maxZoom: 19,
              onMapEvent: (MapEvent event) {
                final double z = event.camera.zoom;
                if ((z >= 15.0) != (_zoom >= 15.0)) {
                  setState(() => _zoom = z);
                } else {
                  _zoom = z;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_application_1',
                maxNativeZoom: 18,
                keepBuffer: 2,
              ),
              if (!widget.isGuest) _kTrailPolylineLayer,
              MarkerLayer(
                markers: <Marker>[
                  for (final LatLng pt in widget.pins) _buildPin(pt),
                ],
              ),
            ],
          ),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 14,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x337C3AED),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF7C3AED),
                  size: 22,
                ),
              ),
            ),
          ),
          // Species name chip at top
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 66,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x337C3AED),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.scientificName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4C1D95),
                ),
              ),
            ),
          ),
        ],
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
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, _, _) => _ProfileOverlayPanel(
        authController: widget.authController,
        fallbackName: profileName,
        fallbackHandle: profileHandle,
      ),
      transitionBuilder: (ctx, animation, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
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
              Text(
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
                label: 'Upload Orchid',
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
                icon: Icons.threed_rotation,
                label: 'Upload 3D Image',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Upload3DRequirementsScreen(),
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
              const _UploadFormHeader(title: ' Upload Orchid'),
              const SizedBox(height: 24),
              Text(
                'Upload Orchid',
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
                    children: [
                      Text(
                        'Requirements:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: _textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
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
              Text(
                'Add New Sightings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Requirements:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
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
  String _lastAutoFilledScientificName = '';

  // ── Species search autocomplete ───────────────────────────────────────────
  List<CatalogSpecies> _allSpecies = <CatalogSpecies>[];
  bool _isLoadingSpecies = false;
  String _selectedCommonName = '';

  void _autoFillScientificName() {
    final String family = _familyController.text.trim();
    final String genus = _genusController.text.trim();
    final String current = _scientificNameController.text;
    if (current.isEmpty || current == _lastAutoFilledScientificName) {
      final String autoFilled = <String>[
        family,
        genus,
      ].where((String s) => s.isNotEmpty).join(' ');
      _scientificNameController.text = autoFilled;
      _lastAutoFilledScientificName = autoFilled;
    }
  }

  Future<void> _loadAllSpecies() async {
    if (!mounted) return;
    setState(() => _isLoadingSpecies = true);
    try {
      final List<dynamic> data = await Supabase.instance.client
          .from('orchids')
          .select('orchid_id, sci_name, common_name, genus(genus_name)')
          .order('sci_name');
      final List<CatalogSpecies> species = data
          .whereType<Map>()
          .map((Map item) {
            final Map<String, dynamic> json = Map<String, dynamic>.from(item);
            final String sci = (json['sci_name'] ?? '').toString().trim();
            if (sci.isEmpty) return null;
            final dynamic g = json['genus'];
            final String genus = g is Map
                ? (g['genus_name'] ?? '').toString()
                : '';
            return CatalogSpecies(
              id: int.tryParse((json['orchid_id'] ?? '').toString()),
              scientificName: sci,
              commonName: (json['common_name'] ?? '').toString().trim(),
              genus: genus,
            );
          })
          .whereType<CatalogSpecies>()
          .toList(growable: false);
      if (mounted) {
        setState(() {
          _allSpecies = species;
          _isLoadingSpecies = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSpecies = false);
    }
  }

  void _onSpeciesSelected(CatalogSpecies species) {
    setState(() {
      _selectedCommonName = species.commonName;
      _familyController.text = 'Orchidaceae';
      _genusController.text = species.genus;
      _scientificNameController.text = species.scientificName;
      _lastAutoFilledScientificName = species.scientificName;
    });
  }

  @override
  void initState() {
    super.initState();
    _familyController.addListener(_autoFillScientificName);
    _genusController.addListener(_autoFillScientificName);
    _loadAllSpecies();
  }

  @override
  void dispose() {
    _familyController.removeListener(_autoFillScientificName);
    _genusController.removeListener(_autoFillScientificName);
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
      style: TextStyle(
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
          genus: genus.isEmpty ? 'Unknown' : genus,
          scientificName: scientificName.isEmpty ? 'Unknown' : scientificName,
          commonName: _selectedCommonName,
        ),
      ),
    );
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
              const _UploadFormHeader(title: 'Add New Sightings'),
              const SizedBox(height: 24),
              Text(
                'Find Species',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Search by common or scientific name to autofill fields.',
                style: TextStyle(fontSize: 12, color: _mutedTextColor),
              ),
              const SizedBox(height: 12),

              // ── Autocomplete search ───────────────────────────────────
              LayoutBuilder(
                builder: (BuildContext ctx, BoxConstraints constraints) {
                  return Autocomplete<CatalogSpecies>(
                    optionsBuilder: (TextEditingValue value) {
                      if (value.text.trim().isEmpty || _allSpecies.isEmpty) {
                        return const Iterable<CatalogSpecies>.empty();
                      }
                      final String q = value.text.trim().toLowerCase();
                      return _allSpecies
                          .where(
                            (CatalogSpecies s) =>
                                s.scientificName.toLowerCase().contains(q) ||
                                s.commonName.toLowerCase().contains(q),
                          )
                          .take(8);
                    },
                    displayStringForOption: (CatalogSpecies s) =>
                        s.scientificName,
                    onSelected: _onSpeciesSelected,
                    fieldViewBuilder:
                        (
                          BuildContext ctx,
                          TextEditingController fieldCtrl,
                          FocusNode focusNode,
                          VoidCallback onSubmitted,
                        ) {
                          return TextField(
                            controller: fieldCtrl,
                            focusNode: focusNode,
                            style: TextStyle(fontSize: 14, color: _textColor),
                            decoration: InputDecoration(
                              hintText: _isLoadingSpecies
                                  ? 'Loading species…'
                                  : 'Search species…',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: _mutedTextColor,
                              ),
                              prefixIcon: _isLoadingSpecies
                                  ? const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _uploadPrimary,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.search_rounded,
                                      color: _uploadPrimary,
                                      size: 20,
                                    ),
                              suffixIcon: fieldCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        size: 18,
                                        color: _uploadPrimary,
                                      ),
                                      onPressed: () {
                                        fieldCtrl.clear();
                                        setState(
                                          () => _selectedCommonName = '',
                                        );
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: _uploadSubCardBg,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: _uploadBorderColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: _uploadBorderColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: _uploadPrimary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          );
                        },
                    optionsViewBuilder:
                        (
                          BuildContext ctx,
                          AutocompleteOnSelected<CatalogSpecies> onSelected,
                          Iterable<CatalogSpecies> options,
                        ) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 8,
                              borderRadius: BorderRadius.circular(16),
                              color: _surfaceColor,
                              child: SizedBox(
                                width: constraints.maxWidth,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 280,
                                  ),
                                  child: ListView.separated(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    separatorBuilder: (_, _) => Divider(
                                      height: 1,
                                      color: _lineColor,
                                      indent: 56,
                                    ),
                                    itemBuilder: (_, int i) {
                                      final CatalogSpecies s = options
                                          .elementAt(i);
                                      return InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () => onSelected(s),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: _uploadSubCardBg,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Icon(
                                                  Icons.eco_rounded,
                                                  size: 18,
                                                  color: _uploadPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      s.scientificName,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        color: _textColor,
                                                      ),
                                                    ),
                                                    if (s.commonName.isNotEmpty)
                                                      Text(
                                                        s.commonName,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              _mutedTextColor,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                size: 12,
                                                color: _uploadPrimary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                  );
                },
              ),

              // ── Divider between search and manual fields ──────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: _lineColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'or fill in manually',
                        style: TextStyle(fontSize: 11, color: _mutedTextColor),
                      ),
                    ),
                    Expanded(child: Divider(color: _lineColor)),
                  ],
                ),
              ),

              // ── Manual fields (autofilled when species selected) ──────
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

              // ── Selected species confirmation chip ────────────────────
              if (_selectedCommonName.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _uploadSubCardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _uploadBorderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: _uploadPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Common name: $_selectedCommonName',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _uploadPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),
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
      style: TextStyle(
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
        style: TextStyle(
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
              Text(
                'Find Species',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
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
    this.category = 'specimen_photo',
  });

  final String path;
  final int sizeBytes;
  String photoCredit;
  String category;

  UploadSpeciesImageDraft copy() {
    return UploadSpeciesImageDraft(
      path: path,
      sizeBytes: sizeBytes,
      photoCredit: photoCredit,
      category: category,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'path': path,
    'sizeBytes': sizeBytes,
    'photoCredit': photoCredit,
    'category': category,
  };

  factory UploadSpeciesImageDraft.fromJson(Map<String, dynamic> json) {
    return UploadSpeciesImageDraft(
      path: (json['path'] ?? '').toString(),
      sizeBytes: int.tryParse((json['sizeBytes'] ?? '0').toString()) ?? 0,
      photoCredit: (json['photoCredit'] ?? '').toString(),
      category: (json['category'] ?? 'specimen_photo').toString(),
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
    String? entryId,
    this.location = '',
    this.family = '',
    this.genus = '',
    this.scientificName = '',
    List<String>? commonNames,
    List<String>? localNames,
    this.identificationConfidence = 'Confirmed',
    this.endemicToPhilippines = true,
    this.leafType = '',
    this.flowerColor = '',
    this.floweringFromMonth = '',
    this.floweringToMonth = '',
    this.plantHeight = '',
    this.pseudobulbPresent = '',
    this.stemLength = '',
    this.rootLength = '',
    this.numberOfLeaves = '',
    this.leafShape = '',
    this.leafLength = '',
    this.leafWidth = '',
    this.leafTexture = '',
    this.leafArrangement = '',
    this.numberOfFlowers = '',
    this.flowerDiameter = '',
    this.inflorescenceType = '',
    this.petalCharacteristics = '',
    this.sepalCharacteristics = '',
    this.labellumDescription = '',
    this.fragrance = '',
    this.bloomingStage = '',
    this.fruitPresent = '',
    this.fruitType = '',
    this.seedCapsuleCondition = '',
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
    this.lifeStage = '',
    this.phenology = '',
    this.populationStatus = '',
    this.threatLevel = '',
    this.threatType = '',
    this.latitude = '',
    this.longitude = '',
    this.province = '',
    this.municipality = '',
    this.mountain = '',
    this.altitude = '',
    this.elevation = '',
    this.habitatType = '',
    this.microHabitat = '',
    this.specificSite = '',
    this.growthSubstrate = '',
    this.hostTreeSpecies = '',
    this.hostTreeDiameter = '',
    this.canopyCover = '',
    this.lightExposure = '',
    this.soilType = '',
    this.nearbyWaterSource = '',
    this.videoPath = '',
    this.studyTitle = '',
    this.studyLink = '',
    this.studyFilePath = '',
    this.headResearcher = '',
    this.teamMembers = '',
    this.institution = '',
    this.researcherNotes = '',
    this.unusualObservations = '',
    List<UploadSpeciesImageDraft>? images,
    List<UploadContributorDraft>? contributors,
    DateTime? updatedAt,
  }) : entryId = (entryId != null && entryId.trim().isNotEmpty)
           ? entryId
           : _generateEntryId(),
       commonNames = commonNames ?? <String>[],
       localNames = localNames ?? <String>[],
       images = images ?? <UploadSpeciesImageDraft>[],
       contributors = contributors ?? <UploadContributorDraft>[],
       updatedAt = updatedAt ?? DateTime.now();

  String? draftId;
  String entryId;
  String location;
  String family;
  String genus;
  String scientificName;
  List<String> commonNames;
  List<String> localNames;
  String identificationConfidence;
  bool endemicToPhilippines;

  String get commonName => commonNames.isNotEmpty ? commonNames.first : '';
  String leafType;
  String flowerColor;
  String floweringFromMonth;
  String floweringToMonth;
  String plantHeight;
  String pseudobulbPresent;
  String stemLength;
  String rootLength;
  String numberOfLeaves;
  String leafShape;
  String leafLength;
  String leafWidth;
  String leafTexture;
  String leafArrangement;
  String numberOfFlowers;
  String flowerDiameter;
  String inflorescenceType;
  String petalCharacteristics;
  String sepalCharacteristics;
  String labellumDescription;
  String fragrance;
  String bloomingStage;
  String fruitPresent;
  String fruitType;
  String seedCapsuleCondition;
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
  String lifeStage;
  String phenology;
  String populationStatus;
  String threatLevel;
  String threatType;

  String latitude;
  String longitude;
  String province;
  String municipality;
  String mountain;
  String altitude;
  String elevation;
  String habitatType;
  String microHabitat;
  String specificSite;
  String growthSubstrate;
  String hostTreeSpecies;
  String hostTreeDiameter;
  String canopyCover;
  String lightExposure;
  String soilType;
  String nearbyWaterSource;

  String videoPath;
  String studyTitle;
  String studyLink;
  String studyFilePath;
  String headResearcher;
  String teamMembers;
  String institution;
  String researcherNotes;
  String unusualObservations;

  List<UploadSpeciesImageDraft> images;
  List<UploadContributorDraft> contributors;

  DateTime updatedAt;

  UploadSpeciesFlowData copy() {
    return UploadSpeciesFlowData(
      draftId: draftId,
      entryId: entryId,
      location: location,
      family: family,
      genus: genus,
      scientificName: scientificName,
      commonNames: List<String>.from(commonNames),
      localNames: List<String>.from(localNames),
      identificationConfidence: identificationConfidence,
      endemicToPhilippines: endemicToPhilippines,
      leafType: leafType,
      flowerColor: flowerColor,
      floweringFromMonth: floweringFromMonth,
      floweringToMonth: floweringToMonth,
      plantHeight: plantHeight,
      pseudobulbPresent: pseudobulbPresent,
      stemLength: stemLength,
      rootLength: rootLength,
      numberOfLeaves: numberOfLeaves,
      leafShape: leafShape,
      leafLength: leafLength,
      leafWidth: leafWidth,
      leafTexture: leafTexture,
      leafArrangement: leafArrangement,
      numberOfFlowers: numberOfFlowers,
      flowerDiameter: flowerDiameter,
      inflorescenceType: inflorescenceType,
      petalCharacteristics: petalCharacteristics,
      sepalCharacteristics: sepalCharacteristics,
      labellumDescription: labellumDescription,
      fragrance: fragrance,
      bloomingStage: bloomingStage,
      fruitPresent: fruitPresent,
      fruitType: fruitType,
      seedCapsuleCondition: seedCapsuleCondition,
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
      lifeStage: lifeStage,
      phenology: phenology,
      populationStatus: populationStatus,
      threatLevel: threatLevel,
      threatType: threatType,
      latitude: latitude,
      longitude: longitude,
      province: province,
      municipality: municipality,
      mountain: mountain,
      altitude: altitude,
      elevation: elevation,
      habitatType: habitatType,
      microHabitat: microHabitat,
      specificSite: specificSite,
      growthSubstrate: growthSubstrate,
      hostTreeSpecies: hostTreeSpecies,
      hostTreeDiameter: hostTreeDiameter,
      canopyCover: canopyCover,
      lightExposure: lightExposure,
      soilType: soilType,
      nearbyWaterSource: nearbyWaterSource,
      videoPath: videoPath,
      studyTitle: studyTitle,
      studyLink: studyLink,
      studyFilePath: studyFilePath,
      headResearcher: headResearcher,
      teamMembers: teamMembers,
      institution: institution,
      researcherNotes: researcherNotes,
      unusualObservations: unusualObservations,
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
      'entryId': entryId,
      'location': location,
      'family': family,
      'genus': genus,
      'scientificName': scientificName,
      'commonName': commonName,
      'commonNames': commonNames,
      'localNames': localNames,
      'identificationConfidence': identificationConfidence,
      'endemicToPhilippines': endemicToPhilippines,
      'leafType': leafType,
      'flowerColor': flowerColor,
      'floweringFromMonth': floweringFromMonth,
      'floweringToMonth': floweringToMonth,
      'plantHeight': plantHeight,
      'pseudobulbPresent': pseudobulbPresent,
      'stemLength': stemLength,
      'rootLength': rootLength,
      'numberOfLeaves': numberOfLeaves,
      'leafShape': leafShape,
      'leafLength': leafLength,
      'leafWidth': leafWidth,
      'leafTexture': leafTexture,
      'leafArrangement': leafArrangement,
      'numberOfFlowers': numberOfFlowers,
      'flowerDiameter': flowerDiameter,
      'inflorescenceType': inflorescenceType,
      'petalCharacteristics': petalCharacteristics,
      'sepalCharacteristics': sepalCharacteristics,
      'labellumDescription': labellumDescription,
      'fragrance': fragrance,
      'bloomingStage': bloomingStage,
      'fruitPresent': fruitPresent,
      'fruitType': fruitType,
      'seedCapsuleCondition': seedCapsuleCondition,
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
      'lifeStage': lifeStage,
      'phenology': phenology,
      'populationStatus': populationStatus,
      'threatLevel': threatLevel,
      'threatType': threatType,
      'latitude': latitude,
      'longitude': longitude,
      'province': province,
      'municipality': municipality,
      'mountain': mountain,
      'altitude': altitude,
      'elevation': elevation,
      'habitatType': habitatType,
      'microHabitat': microHabitat,
      'specificSite': specificSite,
      'growthSubstrate': growthSubstrate,
      'hostTreeSpecies': hostTreeSpecies,
      'hostTreeDiameter': hostTreeDiameter,
      'canopyCover': canopyCover,
      'lightExposure': lightExposure,
      'soilType': soilType,
      'nearbyWaterSource': nearbyWaterSource,
      'videoPath': videoPath,
      'studyTitle': studyTitle,
      'studyLink': studyLink,
      'studyFilePath': studyFilePath,
      'headResearcher': headResearcher,
      'teamMembers': teamMembers,
      'institution': institution,
      'researcherNotes': researcherNotes,
      'unusualObservations': unusualObservations,
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
      entryId: (json['entryId'] ?? '').toString(),
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
      localNames: () {
        final dynamic raw = json['localNames'];
        if (raw is List) {
          return raw
              .map((dynamic e) => e.toString())
              .where((String s) => s.trim().isNotEmpty)
              .toList();
        }
        return <String>[];
      }(),
      identificationConfidence:
          (json['identificationConfidence'] ?? 'Confirmed').toString(),
      endemicToPhilippines: json['endemicToPhilippines'] == true,
      leafType: (json['leafType'] ?? '').toString(),
      flowerColor: (json['flowerColor'] ?? '').toString(),
      floweringFromMonth: (json['floweringFromMonth'] ?? '').toString(),
      floweringToMonth: (json['floweringToMonth'] ?? '').toString(),
      plantHeight: (json['plantHeight'] ?? '').toString(),
      pseudobulbPresent: (json['pseudobulbPresent'] ?? '').toString(),
      stemLength: (json['stemLength'] ?? '').toString(),
      rootLength: (json['rootLength'] ?? '').toString(),
      numberOfLeaves: (json['numberOfLeaves'] ?? '').toString(),
      leafShape: (json['leafShape'] ?? '').toString(),
      leafLength: (json['leafLength'] ?? '').toString(),
      leafWidth: (json['leafWidth'] ?? '').toString(),
      leafTexture: (json['leafTexture'] ?? '').toString(),
      leafArrangement: (json['leafArrangement'] ?? '').toString(),
      numberOfFlowers: (json['numberOfFlowers'] ?? '').toString(),
      flowerDiameter: (json['flowerDiameter'] ?? '').toString(),
      inflorescenceType: (json['inflorescenceType'] ?? '').toString(),
      petalCharacteristics: (json['petalCharacteristics'] ?? '').toString(),
      sepalCharacteristics: (json['sepalCharacteristics'] ?? '').toString(),
      labellumDescription: (json['labellumDescription'] ?? '').toString(),
      fragrance: (json['fragrance'] ?? '').toString(),
      bloomingStage: (json['bloomingStage'] ?? '').toString(),
      fruitPresent: (json['fruitPresent'] ?? '').toString(),
      fruitType: (json['fruitType'] ?? '').toString(),
      seedCapsuleCondition: (json['seedCapsuleCondition'] ?? '').toString(),
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
      lifeStage: (json['lifeStage'] ?? '').toString(),
      phenology: (json['phenology'] ?? '').toString(),
      populationStatus: (json['populationStatus'] ?? '').toString(),
      threatLevel: (json['threatLevel'] ?? '').toString(),
      threatType: (json['threatType'] ?? '').toString(),
      latitude: (json['latitude'] ?? '').toString(),
      longitude: (json['longitude'] ?? '').toString(),
      province: (json['province'] ?? '').toString(),
      municipality: (json['municipality'] ?? '').toString(),
      mountain: (json['mountain'] ?? '').toString(),
      altitude: (json['altitude'] ?? '').toString(),
      elevation: (json['elevation'] ?? '').toString(),
      habitatType: (json['habitatType'] ?? '').toString(),
      microHabitat: (json['microHabitat'] ?? '').toString(),
      specificSite: (json['specificSite'] ?? '').toString(),
      growthSubstrate: (json['growthSubstrate'] ?? '').toString(),
      hostTreeSpecies: (json['hostTreeSpecies'] ?? '').toString(),
      hostTreeDiameter: (json['hostTreeDiameter'] ?? '').toString(),
      canopyCover: (json['canopyCover'] ?? '').toString(),
      lightExposure: (json['lightExposure'] ?? '').toString(),
      soilType: (json['soilType'] ?? '').toString(),
      nearbyWaterSource: (json['nearbyWaterSource'] ?? '').toString(),
      videoPath: (json['videoPath'] ?? '').toString(),
      studyTitle: (json['studyTitle'] ?? '').toString(),
      studyLink: (json['studyLink'] ?? '').toString(),
      studyFilePath: (json['studyFilePath'] ?? '').toString(),
      headResearcher: (json['headResearcher'] ?? '').toString(),
      teamMembers: (json['teamMembers'] ?? '').toString(),
      institution: (json['institution'] ?? '').toString(),
      researcherNotes: (json['researcherNotes'] ?? '').toString(),
      unusualObservations: (json['unusualObservations'] ?? '').toString(),
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
    if (data.scientificName.trim().isEmpty) {
      return 'Scientific Name is required.';
    }
    if (data.observationDate.trim().isEmpty) {
      return 'Date of Observation is required.';
    }
    return null;
  }

  static String? validateSightings(UploadSpeciesFlowData data) {
    if (data.location.trim().isEmpty) {
      return 'Location is required. Use GPS to fill the location.';
    }
    if (data.latitude.trim().isEmpty || data.longitude.trim().isEmpty) {
      return 'Coordinates (Latitude & Longitude) are required.';
    }
    return null;
  }

  static String? validateSpeciesValues(UploadSpeciesFlowData data) {
    return null;
  }

  static String? validateImagesAndContributors(UploadSpeciesFlowData data) {
    if (data.headResearcher.trim().isEmpty) {
      return 'Head Observer / Researcher Name is required.';
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
  UploadSpeciesDraftSubmissionApi();

  void dispose() {}

  String _extractFileName(String path) {
    final String normalized = path.replaceAll('\\', '/').trim();
    if (normalized.isEmpty) return 'image.jpg';
    final List<String> segments = normalized.split('/');
    final String candidate = segments.isNotEmpty ? segments.last.trim() : '';
    return candidate.isNotEmpty ? candidate : 'image.jpg';
  }

  String _inferContentType(String fileName) {
    final String lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<String?> _uploadImage(
    SupabaseClient supabase,
    String imagePath,
    int index,
  ) async {
    Uint8List bytes;
    try {
      bytes = await XFile(imagePath).readAsBytes();
    } catch (_) {
      return null;
    }
    if (bytes.isEmpty) return null;

    final String fileName = _extractFileName(imagePath);
    final String storagePath =
        'sightings/${DateTime.now().millisecondsSinceEpoch}_${index}_$fileName';
    try {
      await supabase.storage
          .from(_kStorageBucket)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(contentType: _inferContentType(fileName)),
          );
      return supabase.storage.from(_kStorageBucket).getPublicUrl(storagePath);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> submitDraft(UploadSpeciesFlowData draft) async {
    final SupabaseClient supabase = Supabase.instance.client;
    final String userEmail = supabase.auth.currentUser?.email ?? '';
    final Map<String, dynamic> userMeta = Map<String, dynamic>.from(
      supabase.auth.currentUser?.userMetadata ?? <String, dynamic>{},
    );
    final String userName = (userMeta['name'] ?? '').toString();

    // Upload images concurrently
    final List<Future<String?>> uploadFutures = <Future<String?>>[];
    for (int i = 0; i < draft.images.length; i++) {
      final String path = draft.images[i].path.trim();
      uploadFutures.add(
        path.isEmpty
            ? Future<String?>.value(null)
            : _uploadImage(supabase, path, i),
      );
    }
    final List<String?> uploadedUrls = await Future.wait(uploadFutures);

    final String wholePlantUrl = uploadedUrls.isNotEmpty
        ? (uploadedUrls[0] ?? '')
        : '';
    final String closeupFlowerUrl = uploadedUrls.length > 1
        ? (uploadedUrls[1] ?? '')
        : '';
    final String habitatUrl = uploadedUrls.length > 2
        ? (uploadedUrls[2] ?? '')
        : '';

    final String entryId = 'BLOOM-${DateTime.now().microsecondsSinceEpoch}';

    final String threatType = draft.threatType.trim();
    final List<String> threatTypes = threatType.isNotEmpty
        ? <String>[threatType]
        : <String>[];

    final Map<String, dynamic> row = <String, dynamic>{
      'entry_id': entryId,
      'researcher_email': userEmail,
      'researcher_name': userName,
      'scientific_name': draft.scientificName.trim().isEmpty
          ? 'Unknown'
          : draft.scientificName.trim(),
      'observation_date': draft.observationDate.trim().isEmpty
          ? null
          : draft.observationDate.trim(),
      'observation_time': draft.observationTime.trim().isEmpty
          ? null
          : draft.observationTime.trim(),
      'collection_method': draft.collectionMethod.trim(),
      'observation_type': draft.observationType.trim(),
      'voucher_collected': draft.voucherSpecimenCollected,
      'mountain_name': draft.mountain.trim().isEmpty
          ? 'Mt. Busa'
          : draft.mountain.trim(),
      'specific_site_zone': draft.altitude.trim(),
      'latitude': double.tryParse(draft.latitude.trim()) ?? 0.0,
      'longitude': double.tryParse(draft.longitude.trim()) ?? 0.0,
      'elevation_meters': double.tryParse(draft.elevation.trim()),
      'habitat_type': draft.habitatType.trim(),
      'microhabitat': draft.microHabitat.trim(),
      'leaf_shape': draft.leafType.trim(),
      'flower_color': draft.flowerColor.trim(),
      'life_stage': draft.lifeStage.trim(),
      'phenology': draft.phenology.trim(),
      'population_count': int.tryParse(draft.numberLocated.trim()),
      'population_status': draft.populationStatus.trim(),
      'threat_level': draft.threatLevel.trim(),
      'threat_types': threatTypes,
      'institution': draft.institution.trim(),
      'team_members': draft.teamMembers.trim(),
      'researcher_notes': draft.researcherNotes.trim(),
      'unusual_observations': draft.unusualObservations.trim(),
      'whole_plant_photo_path': wholePlantUrl.isNotEmpty ? wholePlantUrl : null,
      'closeup_flower_photo_path': closeupFlowerUrl.isNotEmpty
          ? closeupFlowerUrl
          : null,
      'habitat_photo_path': habitatUrl.isNotEmpty ? habitatUrl : null,
      'review_status': 'pending',
    };

    try {
      final List<dynamic> result = await supabase
          .from('species_sightings')
          .insert(row)
          .select();
      if (result.isNotEmpty) {
        return Map<String, dynamic>.from(result.first as Map);
      }
      return <String, dynamic>{'status': 'submitted'};
    } catch (e) {
      throw DraftSubmissionException('Submission failed: ${e.toString()}');
    }
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

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _familyFieldKey = GlobalKey();
  final GlobalKey _genusFieldKey = GlobalKey();
  final GlobalKey _scientificNameFieldKey = GlobalKey();
  final GlobalKey _confidenceFieldKey = GlobalKey();
  final GlobalKey _dateFieldKey = GlobalKey();
  final GlobalKey _numberLocatedFieldKey = GlobalKey();

  String? _familyError;
  String? _genusError;
  String? _scientificNameError;
  String? _confidenceError;
  String? _dateError;
  String? _numberLocatedError;

  final TextEditingController _familyController = TextEditingController();
  final TextEditingController _genusController = TextEditingController();
  final TextEditingController _scientificNameController =
      TextEditingController();
  String _lastAutoFilledScientificName = '';
  final List<TextEditingController> _commonNameControllers =
      <TextEditingController>[];
  final List<TextEditingController> _localNameControllers =
      <TextEditingController>[];
  final TextEditingController _numberLocatedController =
      TextEditingController();

  static const int _maxCommonNames = 5;
  static const int _maxLocalNames = 5;
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
  DateTime? _observationDate;
  TimeOfDay? _observationTime;
  String? _selectedCollectionMethod;
  String? _selectedObservationType;
  bool _voucherSpecimenCollected = false;
  bool _isSavingDraft = false;

  void _autoFillScientificName() {
    final String family = _familyController.text.trim();
    final String genus = _genusController.text.trim();
    final String current = _scientificNameController.text;
    if (current.isEmpty || current == _lastAutoFilledScientificName) {
      final String autoFilled = <String>[
        family,
        genus,
      ].where((String s) => s.isNotEmpty).join(' ');
      _scientificNameController.text = autoFilled;
      _lastAutoFilledScientificName = autoFilled;
    }
  }

  @override
  void initState() {
    super.initState();
    _flowData = widget.flowData;

    _familyController.text = _flowData.family;
    _genusController.text = _flowData.genus;
    _scientificNameController.text = _flowData.scientificName;
    _lastAutoFilledScientificName = _flowData.scientificName;
    _familyController.addListener(_autoFillScientificName);
    _genusController.addListener(_autoFillScientificName);
    final List<String> names = _flowData.commonNames.isNotEmpty
        ? _flowData.commonNames
        : <String>[''];
    for (final String name in names) {
      _commonNameControllers.add(TextEditingController(text: name));
    }
    final List<String> localNames = _flowData.localNames.isNotEmpty
        ? _flowData.localNames
        : <String>[''];
    for (final String name in localNames) {
      _localNameControllers.add(TextEditingController(text: name));
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
    _scrollController.dispose();
    _familyController.removeListener(_autoFillScientificName);
    _genusController.removeListener(_autoFillScientificName);
    _familyController.dispose();
    _genusController.dispose();
    _scientificNameController.dispose();
    for (final TextEditingController c in _commonNameControllers) {
      c.dispose();
    }
    for (final TextEditingController c in _localNameControllers) {
      c.dispose();
    }
    _numberLocatedController.dispose();
    super.dispose();
  }

  void _syncFlowDataFromForm() {
    _flowData.family = _familyController.text.trim();
    _flowData.genus = _genusController.text.trim();
    _flowData.scientificName = _scientificNameController.text.trim();
    _flowData.commonNames = _commonNameControllers
        .map((TextEditingController c) => c.text.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
    _flowData.localNames = _localNameControllers
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

  Future<void> _openSpeciesSightingsForm() async {
    _syncFlowDataFromForm();

    setState(() {
      _familyError = null;
      _genusError = null;
      _scientificNameError = _flowData.scientificName.trim().isEmpty
          ? 'Scientific Name is required'
          : null;
      _confidenceError = null;
      _dateError = _flowData.observationDate.trim().isEmpty
          ? 'Date of observation is required'
          : null;
      _numberLocatedError = null;
    });

    GlobalKey? firstErrorKey;
    if (_scientificNameError != null) {
      firstErrorKey = _scientificNameFieldKey;
    } else if (_dateError != null) {
      firstErrorKey = _dateFieldKey;
    }

    if (firstErrorKey != null) {
      final BuildContext? ctx = firstErrorKey.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          alignment: 0.1,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UploadSpeciesSightingsScreen(flowData: _flowData),
      ),
    );
  }

  Future<void> _saveDraft() async {
    if (_isSavingDraft) return;
    setState(() => _isSavingDraft = true);
    try {
      _syncFlowDataFromForm();
      await UploadSpeciesDraftStore.saveDraft(_flowData);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Draft saved.')));
      Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save draft right now.')),
      );
    } finally {
      if (mounted) setState(() => _isSavingDraft = false);
    }
  }

  InputDecoration _fieldDecoration() {
    return _uploadInputDecoration();
  }

  Widget _dropdownField({
    required String hint,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    String? errorText,
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
        errorText: errorText,
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(text, style: _uploadFieldLabelStyle);
  }

  Widget _unknownButton(VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: _uploadPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        minimumSize: const Size(0, 46),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: _uploadBorderColor, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: _uploadSubCardBg,
      ),
      child: const Text('Unknown', style: TextStyle(fontSize: 13)),
    );
  }

  Widget _pickerField({
    required String value,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    String? errorText,
  }) {
    final bool hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: _surfaceColor,
              border: Border.all(
                color: hasError ? const Color(0xFFB00020) : _uploadBorderColor,
                width: hasError ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    value.isEmpty ? hint : value,
                    style: value.isEmpty
                        ? _uploadHintTextStyle
                        : _uploadInputTextStyle,
                  ),
                ),
                Icon(icon, size: 18, color: _uploadPrimary),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              errorText,
              style: TextStyle(fontSize: 12, color: Color(0xFFB00020)),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _uploadBg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _UploadFormHeader(
                title: 'Upload Orchid',
                sectionTitle: 'Basic Taxonomic Information',
                step: 1,
                totalSteps: 5,
                stepIcon: Icons.eco_outlined,
                entryId: _flowData.entryId,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // ── Species Information Card ──────────────────────────
                    _uploadFormCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Row(
                            children: <Widget>[
                              Icon(
                                Icons.eco_outlined,
                                size: 16,
                                color: _uploadPrimary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Species Information',
                                style: _uploadSectionTitleStyle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _fieldLabel('Family'),
                          const SizedBox(height: 6),
                          Row(
                            key: _familyFieldKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: TextField(
                                  controller: _familyController,
                                  style: _uploadInputTextStyle,
                                  onChanged: (_) {
                                    if (_familyError != null) {
                                      setState(() => _familyError = null);
                                    }
                                  },
                                  decoration: _fieldDecoration().copyWith(
                                    errorText: _familyError,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _unknownButton(
                                () => setState(
                                  () => _familyController.text = 'Unknown',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _fieldLabel('Genus'),
                          const SizedBox(height: 6),
                          Row(
                            key: _genusFieldKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: TextField(
                                  controller: _genusController,
                                  style: _uploadInputTextStyle,
                                  onChanged: (_) {
                                    if (_genusError != null) {
                                      setState(() => _genusError = null);
                                    }
                                  },
                                  decoration: _fieldDecoration().copyWith(
                                    errorText: _genusError,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _unknownButton(
                                () => setState(
                                  () => _genusController.text = 'Unknown',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _fieldLabel(
                            'Scientific Name (Binomial Nomenclature) *',
                          ),
                          const SizedBox(height: 6),
                          Row(
                            key: _scientificNameFieldKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: TextField(
                                  controller: _scientificNameController,
                                  style: _uploadInputTextStyle.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                  onChanged: (_) {
                                    if (_scientificNameError != null) {
                                      setState(
                                        () => _scientificNameError = null,
                                      );
                                    }
                                  },
                                  decoration: _fieldDecoration().copyWith(
                                    hintText: 'e.g. Phalaenopsis amabilis',
                                    hintStyle: _uploadHintTextStyle.copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                                    errorText: _scientificNameError,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _unknownButton(
                                () => setState(
                                  () => _scientificNameController.text =
                                      'Unknown',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _uploadFieldLabelWithTooltip(
                            'Vernacular / Common Names',
                            'Non-scientific names the orchid is known by, including local dialect and regional names.',
                          ),
                          const SizedBox(height: 6),
                          ...List<Widget>.generate(
                            _commonNameControllers.length,
                            (int i) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: TextField(
                                      controller: _commonNameControllers[i],
                                      style: _uploadInputTextStyle,
                                      decoration: _fieldDecoration().copyWith(
                                        hintText: 'Enter name ${i + 1}',
                                      ),
                                    ),
                                  ),
                                  if (_commonNameControllers.length >
                                      1) ...<Widget>[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _commonNameControllers[i].dispose();
                                          _commonNameControllers.removeAt(i);
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        size: 22,
                                        color: _uploadPrimary,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (_commonNameControllers.length < _maxCommonNames)
                            TextButton.icon(
                              onPressed: () => setState(
                                () => _commonNameControllers.add(
                                  TextEditingController(),
                                ),
                              ),
                              icon: const Icon(
                                Icons.add,
                                size: 16,
                                color: _uploadPrimary,
                              ),
                              label: const Text(
                                'Add another name',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _uploadPrimary,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          const SizedBox(height: 14),
                          _uploadFieldLabelWithTooltip(
                            'Local Names',
                            'Names used in local dialects or indigenous languages specific to the area where the orchid was found.',
                          ),
                          const SizedBox(height: 6),
                          ...List<Widget>.generate(
                            _localNameControllers.length,
                            (int i) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: TextField(
                                      controller: _localNameControllers[i],
                                      style: _uploadInputTextStyle,
                                      decoration: _fieldDecoration().copyWith(
                                        hintText: 'Enter local name ${i + 1}',
                                      ),
                                    ),
                                  ),
                                  if (_localNameControllers.length >
                                      1) ...<Widget>[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _localNameControllers[i].dispose();
                                          _localNameControllers.removeAt(i);
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        size: 22,
                                        color: _uploadPrimary,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (_localNameControllers.length < _maxLocalNames)
                            TextButton.icon(
                              onPressed: () => setState(
                                () => _localNameControllers.add(
                                  TextEditingController(),
                                ),
                              ),
                              icon: const Icon(
                                Icons.add,
                                size: 16,
                                color: _uploadPrimary,
                              ),
                              label: const Text(
                                'Add another local name',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _uploadPrimary,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          const SizedBox(height: 12),
                          _uploadFieldLabelWithTooltip(
                            'Taxonomic Identification Confidence',
                            'How certain you are of the species identification. Confirmed: verified by an expert. Probable: likely but not confirmed. Unidentified: species unknown.',
                          ),
                          const SizedBox(height: 6),
                          Column(
                            key: _confidenceFieldKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _dropdownField(
                                hint: 'Select confidence level',
                                value: _identificationConfidence.isEmpty
                                    ? null
                                    : _identificationConfidence,
                                options: _confidenceOptions,
                                onChanged: (String? value) {
                                  if (value != null) {
                                    if (_confidenceError != null) {
                                    setState(() => _confidenceError = null);
                                  }
                                    setState(
                                      () => _identificationConfidence = value,
                                    );
                                  }
                                },
                                errorText: _confidenceError,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _uploadFieldLabelWithTooltip(
                            'Endemic to the Philippines',
                            'Species found naturally only in the Philippines and nowhere else in the world.',
                          ),
                          const SizedBox(height: 6),
                          _dropdownField(
                            hint: 'Select yes or no',
                            value: _endemicToPhilippines ? 'Yes' : 'No',
                            options: const <String>['Yes', 'No'],
                            onChanged: (String? value) {
                              if (value != null) {
                                setState(
                                  () => _endemicToPhilippines = value == 'Yes',
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ── Observation / Collection Details Card ─────────────
                    _uploadFormCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Row(
                            children: <Widget>[
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: _uploadPrimary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Observation & Collection Details',
                                style: _uploadSectionTitleStyle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  key: _dateFieldKey,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _fieldLabel('Date of Observation *'),
                                    const SizedBox(height: 6),
                                    _pickerField(
                                      value: _observationDate != null
                                          ? '${_observationDate!.year.toString().padLeft(4, '0')}-'
                                                '${_observationDate!.month.toString().padLeft(2, '0')}-'
                                                '${_observationDate!.day.toString().padLeft(2, '0')}'
                                          : '',
                                      hint: 'Select date',
                                      icon: Icons.calendar_today_outlined,
                                      onTap: () async {
                                        final DateTime? picked =
                                            await showDatePicker(
                                              context: context,
                                              initialDate:
                                                  _observationDate ??
                                                  DateTime.now(),
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime.now(),
                                            );
                                        if (picked != null) {
                                          if (_dateError != null) {
                                            setState(() => _dateError = null);
                                          }
                                          setState(
                                            () => _observationDate = picked,
                                          );
                                        }
                                      },
                                      errorText: _dateError,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _fieldLabel('Time'),
                                    const SizedBox(height: 6),
                                    _pickerField(
                                      value: _observationTime != null
                                          ? _observationTime!.format(context)
                                          : '',
                                      hint: 'Select time',
                                      icon: Icons.access_time_outlined,
                                      onTap: () async {
                                        final TimeOfDay? picked =
                                            await showTimePicker(
                                              context: context,
                                              initialTime:
                                                  _observationTime ??
                                                  TimeOfDay.now(),
                                            );
                                        if (picked != null) {
                                          setState(
                                            () => _observationTime = picked,
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _uploadFieldLabelWithTooltip(
                            'Sampling Methodology',
                            'Method used to survey and locate the orchid. Transect: along a fixed line; Quadrat: within a bounded area; Opportunistic: casual sighting; Random Survey: no fixed pattern.',
                          ),
                          const SizedBox(height: 6),
                          _dropdownField(
                            hint: 'Select collection method',
                            value: _selectedCollectionMethod,
                            options: _collectionMethodOptions,
                            onChanged: (String? value) => setState(
                              () => _selectedCollectionMethod = value,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _uploadFieldLabelWithTooltip(
                            'Specimen Observation Type',
                            'Physical state of the orchid at the time of observation (e.g., alive and flowering, dead, or recorded only by photo).',
                          ),
                          const SizedBox(height: 6),
                          _dropdownField(
                            hint: 'Select observation type',
                            value: _selectedObservationType,
                            options: _observationTypeOptions,
                            onChanged: (String? value) => setState(
                              () => _selectedObservationType = value,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _uploadFieldLabelWithTooltip(
                            'Voucher Specimen Collected',
                            'Whether a physical specimen was taken and deposited in a herbarium for future scientific verification.',
                          ),
                          const SizedBox(height: 6),
                          _dropdownField(
                            hint: 'Select yes or no',
                            value: _voucherSpecimenCollected ? 'Yes' : 'No',
                            options: const <String>['Yes', 'No'],
                            onChanged: (String? value) {
                              if (value != null) {
                                setState(
                                  () => _voucherSpecimenCollected =
                                      value == 'Yes',
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          _fieldLabel('Number of Orchids in this Area'),
                          const SizedBox(height: 6),
                          Column(
                            key: _numberLocatedFieldKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              TextField(
                                controller: _numberLocatedController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: false,
                                      signed: false,
                                    ),
                                style: _uploadInputTextStyle,
                                onChanged: (_) {
                                  if (_numberLocatedError != null) {
                                    setState(() => _numberLocatedError = null);
                                  }
                                },
                                decoration: _fieldDecoration().copyWith(
                                  hintText: 'e.g. 25',
                                  errorText: _numberLocatedError,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _uploadNextButton(
                      onPressed: _openSpeciesSightingsForm,
                      label: 'Next — Location & Habitat',
                    ),
                    const SizedBox(height: 8),
                    _uploadSaveDraftButton(
                      onPressed: _isSavingDraft ? null : _saveDraft,
                      label: _isSavingDraft
                          ? 'Saving Draft...'
                          : 'Save as Draft',
                    ),
                    const SizedBox(height: 8),
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

  static const List<String> _lifeStageOptions = <String>[
    'Seedling',
    'Juvenile',
    'Mature',
  ];

  static const List<String> _phenologyOptions = <String>[
    'Vegetative',
    'Budding',
    'Flowering',
    'Fruiting',
  ];

  static const List<String> _populationStatusOptions = <String>[
    'Abundant',
    'Common',
    'Rare',
  ];

  static const List<String> _threatLevelOptions = <String>[
    'Critically Endangered',
    'Endangered',
    'Vulnerable',
    'Least Concern',
  ];

  static const List<String> _threatTypeOptions = <String>[
    'Logging',
    'Collection',
    'Fire',
    'Land Conversion',
  ];

  String? _selectedEthnobotanicalImportance;
  String? _selectedAestheticAppeal;
  String? _selectedCultivation;
  String? _selectedRarity;
  String? _selectedCulturalImportance;
  String? _selectedLifeStage;
  String? _selectedPhenology;
  String? _selectedPopulationStatus;
  String? _selectedThreatLevel;
  String? _selectedThreatType;
  bool _isSavingDraft = false;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _lifeStageKey = GlobalKey();
  final GlobalKey _phenologyKey = GlobalKey();
  final GlobalKey _populationStatusKey = GlobalKey();
  final GlobalKey _threatLevelKey = GlobalKey();
  final GlobalKey _rarityKey = GlobalKey();

  String? _lifeStageError;
  String? _phenologyError;
  String? _populationStatusError;
  String? _threatLevelError;
  String? _rarityError;

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
    _selectedLifeStage = _flowData.lifeStage.trim().isEmpty
        ? null
        : _flowData.lifeStage.trim();
    _selectedPhenology = _flowData.phenology.trim().isEmpty
        ? null
        : _flowData.phenology.trim();
    _selectedPopulationStatus = _flowData.populationStatus.trim().isEmpty
        ? null
        : _flowData.populationStatus.trim();
    _selectedThreatLevel = _flowData.threatLevel.trim().isEmpty
        ? null
        : _flowData.threatLevel.trim();
    _selectedThreatType = _flowData.threatType.trim().isEmpty
        ? null
        : _flowData.threatType.trim();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration() {
    return _uploadInputDecoration();
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
    _flowData.lifeStage = (_selectedLifeStage ?? '').trim();
    _flowData.phenology = (_selectedPhenology ?? '').trim();
    _flowData.populationStatus = (_selectedPopulationStatus ?? '').trim();
    _flowData.threatLevel = (_selectedThreatLevel ?? '').trim();
    _flowData.threatType = (_selectedThreatType ?? '').trim();
  }

  Future<void> _openImagesScreen() async {
    _syncFlowDataFromForm();

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UploadSpeciesImagesScreen(flowData: _flowData),
      ),
    );
  }

  Future<void> _saveDraft() async {
    if (_isSavingDraft) return;
    setState(() => _isSavingDraft = true);
    try {
      _syncFlowDataFromForm();
      await UploadSpeciesDraftStore.saveDraft(_flowData);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Draft saved.')));
      Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save draft right now.')),
      );
    } finally {
      if (mounted) setState(() => _isSavingDraft = false);
    }
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
    String? errorText,
  }) {
    final List<String> resolvedOptions = _optionsWithExistingValue(
      options,
      value,
    );
    final bool hasError = errorText != null;

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
              suffixIcon: Icon(
                Icons.search_rounded,
                color: _mutedTextColor,
                size: 20,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: hasError
                      ? const Color(0xFFB84040)
                      : _uploadBorderColor,
                  width: hasError ? 1.5 : 1,
                ),
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
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              errorText,
              style: TextStyle(fontSize: 12, color: Color(0xFFB00020)),
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
                      style: TextStyle(
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
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: _mutedTextColor,
                            ),
                          ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
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
                                      Divider(height: 1, color: _lineColor),
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
                                    style: TextStyle(
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
      backgroundColor: _uploadBg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _UploadFormHeader(
                title: 'Upload Orchid',
                step: 4,
                totalSteps: 5,
                stepIcon: Icons.analytics_outlined,
                sectionTitle: 'Ecological & Value Data',
                entryId: _flowData.entryId,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // ── Ecological / Biological Data ──────────────────────
                    _uploadFormCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.science_outlined,
                                size: 16,
                                color: _uploadPrimary,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Ecological / Biological Data',
                                style: _uploadSectionTitleStyle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Column(
                            key: _lifeStageKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDropdownField(
                                label: 'Life Stage',
                                hint: 'Select life stage',
                                value: _selectedLifeStage,
                                options: _lifeStageOptions,
                                errorText: _lifeStageError,
                                onChanged: (String? value) {
                                  setState(() {
                                    _lifeStageError = null;
                                    _selectedLifeStage = value;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Column(
                            key: _phenologyKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDropdownField(
                                label: 'Phenology',
                                hint: 'Select phenology',
                                value: _selectedPhenology,
                                options: _phenologyOptions,
                                errorText: _phenologyError,
                                onChanged: (String? value) {
                                  setState(() {
                                    _phenologyError = null;
                                    _selectedPhenology = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ── Conservation & Threat Data ────────────────────────
                    _uploadFormCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.shield_outlined,
                                size: 16,
                                color: _uploadPrimary,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Conservation & Threat Data',
                                style: _uploadSectionTitleStyle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Column(
                            key: _populationStatusKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDropdownField(
                                label: 'Population Status',
                                hint: 'Select population status',
                                value: _selectedPopulationStatus,
                                options: _populationStatusOptions,
                                errorText: _populationStatusError,
                                onChanged: (String? value) {
                                  setState(() {
                                    _populationStatusError = null;
                                    _selectedPopulationStatus = value;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Column(
                            key: _threatLevelKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDropdownField(
                                label: 'Threat Level',
                                hint: 'Select threat level',
                                value: _selectedThreatLevel,
                                options: _threatLevelOptions,
                                errorText: _threatLevelError,
                                onChanged: (String? value) {
                                  setState(() {
                                    _threatLevelError = null;
                                    _selectedThreatLevel = value;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildDropdownField(
                            label: 'Threat Type',
                            hint: 'Select threat type',
                            value: _selectedThreatType,
                            options: _threatTypeOptions,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedThreatType = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ── Species Value ─────────────────────────────────────
                    _uploadFormCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.star_outline_rounded,
                                size: 16,
                                color: _uploadPrimary,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Species Value',
                                style: _uploadSectionTitleStyle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
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
                          const SizedBox(height: 10),
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
                          const SizedBox(height: 10),
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
                          const SizedBox(height: 10),
                          Column(
                            key: _rarityKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDropdownField(
                                label: 'Rarity',
                                hint: 'Select rarity level',
                                value: _selectedRarity,
                                options: _rarityOptions,
                                errorText: _rarityError,
                                onChanged: (String? value) {
                                  setState(() {
                                    _rarityError = null;
                                    _selectedRarity = value;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
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
                    const SizedBox(height: 20),
                    _uploadNextButton(
                      onPressed: _openImagesScreen,
                      label: 'Next — Media & Researchers',
                    ),
                    const SizedBox(height: 8),
                    _uploadSaveDraftButton(
                      onPressed: _isSavingDraft ? null : _saveDraft,
                      label: _isSavingDraft
                          ? 'Saving Draft...'
                          : 'Save as Draft',
                    ),
                    const SizedBox(height: 8),
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

class UploadSpeciesSightingsScreen extends StatefulWidget {
  const UploadSpeciesSightingsScreen({
    required this.flowData,
    this.flowTitle = 'Upload Orchid',
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

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _mountainController = TextEditingController();
  final TextEditingController _altitudeController = TextEditingController();
  final TextEditingController _elevationController = TextEditingController();

  static const List<String> _habitatTypeOptions = <String>[
    'lowland forest',
    'montane forest',
    'mossy forest',
    'Others',
  ];

  static const List<String> _microHabitatOptions = <String>[
    'Canopy',
    'understory',
    'forest floor',
    'rock surface',
  ];

  static const List<String> _specificSiteOptions = <String>[
    'trail',
    'ridge',
    'streamside',
    'Other',
  ];

  static const List<String> _growthSubstrateOptions = <String>[
    'tree bark',
    'soil',
    'rock',
    'decaying wood',
  ];

  static const List<String> _lightExposureOptions = <String>[
    'full shade',
    'partial',
    'direct',
  ];

  static const List<String> _soilTypeOptions = <String>[
    'Sandy soil',
    'Clay soil',
    'Loamy soil',
    'Rocky soil',
    'Volcanic soil',
    'Laterite soil',
  ];

  static const List<String> _nearbyWaterSourceOptions = <String>[
    'River',
    'Stream',
    'Spring',
    'Waterfall',
    'Seepage area',
    'None',
    'Unidentified',
  ];

  String? _selectedHabitatType;
  String? _selectedMicroHabitat;
  String? _selectedSpecificSite;
  String? _selectedGrowthSubstrate;
  String? _selectedLightExposure;
  String? _selectedSoilType;
  String? _selectedNearbyWaterSource;

  late TextEditingController _otherSpecificSiteController;
  late TextEditingController _otherHabitatTypeController;
  late TextEditingController _hostTreeSpeciesController;
  late TextEditingController _hostTreeDiameterController;
  late TextEditingController _canopyCoverController;

  bool _isResolvingLocation = false;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _locationFieldKey = GlobalKey();
  final GlobalKey _mountainFieldKey = GlobalKey();
  final GlobalKey _altitudeFieldKey = GlobalKey();
  final GlobalKey _elevationFieldKey = GlobalKey();
  final GlobalKey _habitatTypeFieldKey = GlobalKey();
  final GlobalKey _microHabitatFieldKey = GlobalKey();

  String? _locationError;
  String? _coordinateError;
  String? _mountainError;
  String? _altitudeError;
  String? _elevationError;
  String? _habitatTypeError;
  String? _microHabitatError;
  bool _isSavingDraft = false;

  @override
  void initState() {
    super.initState();
    _flowData = widget.flowData;

    _locationController.text = _flowData.location;
    _latitudeController.text = _flowData.latitude;
    _longitudeController.text = _flowData.longitude;
    _mountainController.text = 'Mt. Busa';
    _altitudeController.text = _flowData.altitude;
    _elevationController.text = _flowData.elevation;

    _latitudeController.addListener(_reverseGeocodeFromCoordinates);
    _longitudeController.addListener(_reverseGeocodeFromCoordinates);

    _selectedHabitatType = _flowData.habitatType.trim().isEmpty
        ? null
        : _flowData.habitatType.trim();
    _selectedMicroHabitat = _flowData.microHabitat.trim().isEmpty
        ? null
        : _flowData.microHabitat.trim();
    _selectedSpecificSite = _flowData.specificSite.trim().isEmpty
        ? null
        : _flowData.specificSite.trim();
    _selectedGrowthSubstrate = _flowData.growthSubstrate.trim().isEmpty
        ? null
        : _flowData.growthSubstrate.trim();
    _selectedLightExposure = _flowData.lightExposure.trim().isEmpty
        ? null
        : _flowData.lightExposure.trim();
    _selectedSoilType = _flowData.soilType.trim().isEmpty
        ? null
        : _flowData.soilType.trim();
    _selectedNearbyWaterSource = _flowData.nearbyWaterSource.trim().isEmpty
        ? null
        : _flowData.nearbyWaterSource.trim();

    _otherSpecificSiteController = TextEditingController();
    _otherHabitatTypeController = TextEditingController();
    _hostTreeSpeciesController = TextEditingController(
      text: _flowData.hostTreeSpecies,
    );
    _hostTreeDiameterController = TextEditingController(
      text: _flowData.hostTreeDiameter,
    );
    _canopyCoverController = TextEditingController(text: _flowData.canopyCover);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _mountainController.dispose();
    _altitudeController.dispose();
    _elevationController.dispose();
    _otherSpecificSiteController.dispose();
    _otherHabitatTypeController.dispose();
    _hostTreeSpeciesController.dispose();
    _hostTreeDiameterController.dispose();
    _canopyCoverController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration([String? hintText]) {
    return _uploadInputDecoration(hintText: hintText);
  }

  Widget _fieldLabel(String text) {
    return Text(text, style: _uploadFieldLabelStyle);
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

  Future<void> _useGpsLocation() async {
    if (_isResolvingLocation) return;
    setState(() => _isResolvingLocation = true);
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enable location services to use GPS.'),
            ),
          );
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required.')),
          );
        }
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is permanently denied.'),
            ),
          );
        }
        return;
      }
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (!mounted) return;

      String locationLabel =
          '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      String province = '';
      String municipality = '';

      try {
        final Uri uri = Uri.https(
          'nominatim.openstreetmap.org',
          '/reverse',
          <String, String>{
            'format': 'jsonv2',
            'lat': position.latitude.toString(),
            'lon': position.longitude.toString(),
          },
        );
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
              municipality = _firstNonEmpty(address, <String>[
                'municipality',
                'city',
                'town',
                'village',
              ]);
              province = _firstNonEmpty(address, <String>[
                'province',
                'state',
                'region',
              ]);
              final String resolved = <String>[
                municipality,
                province,
              ].where((String s) => s.isNotEmpty).join(', ');
              if (resolved.isNotEmpty) locationLabel = resolved;
            }
          }
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _locationController.text = locationLabel;
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
        _altitudeController.text = position.altitude.toStringAsFixed(1);
        _elevationController.text = position.altitude.toStringAsFixed(1);
      });
      _flowData.province = province;
      _flowData.municipality = municipality;
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get the current GPS location.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResolvingLocation = false);
    }
  }

  Future<void> _reverseGeocodeFromCoordinates() async {
    final double? lat = double.tryParse(_latitudeController.text.trim());
    final double? lng = double.tryParse(_longitudeController.text.trim());

    if (lat == null || lng == null) return;

    if (!mounted) return;
    setState(() => _isResolvingLocation = true);

    try {
      final Uri uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/reverse',
        <String, String>{
          'format': 'jsonv2',
          'lat': lat.toString(),
          'lon': lng.toString(),
        },
      );
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
            ].where((String s) => s.isNotEmpty).join(', ');

            if (!mounted) return;
            setState(() {
              if (resolved.isNotEmpty) {
                _locationController.text = resolved;
              } else {
                _locationController.text =
                    '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
              }
            });
            _flowData.province = province;
            _flowData.municipality = municipality;
          }
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _isResolvingLocation = false);
  }

  Widget _buildField({
    required TextEditingController controller,
    String? hintText,
    TextInputType? keyboardType,
  }) {
    return SizedBox(
      height: 34,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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
                      style: TextStyle(
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
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: _mutedTextColor,
                            ),
                          ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
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
                                      Divider(height: 1, color: _lineColor),
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
                                    style: TextStyle(
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
    String? tooltip,
  }) {
    final List<String> resolvedOptions = _optionsWithExistingValue(
      options,
      value,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tooltip != null
            ? _uploadFieldLabelWithTooltip(label, tooltip)
            : _fieldLabel(label),
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
            decoration: _uploadInputDecoration().copyWith(
              suffixIcon: Icon(
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

  void _syncFlowDataFromForm() {
    _flowData.location = _locationController.text.trim();
    _flowData.latitude = _latitudeController.text.trim();
    _flowData.longitude = _longitudeController.text.trim();
    _flowData.mountain = 'Mt. Busa';
    _flowData.altitude = _altitudeController.text.trim();
    _flowData.elevation = _elevationController.text.trim();
    _flowData.habitatType = (_selectedHabitatType ?? '').trim();
    if (_selectedHabitatType == 'Others') {
      _flowData.habitatType = _otherHabitatTypeController.text.trim();
    }
    _flowData.microHabitat = (_selectedMicroHabitat ?? '').trim();
    _flowData.specificSite = (_selectedSpecificSite ?? '').trim();
    if (_selectedSpecificSite == 'Other') {
      _flowData.specificSite = _otherSpecificSiteController.text.trim();
    }
    _flowData.growthSubstrate = (_selectedGrowthSubstrate ?? '').trim();
    _flowData.hostTreeSpecies = _selectedGrowthSubstrate == 'tree bark'
        ? _hostTreeSpeciesController.text.trim()
        : '';
    _flowData.hostTreeDiameter = _selectedGrowthSubstrate == 'tree bark'
        ? _hostTreeDiameterController.text.trim()
        : '';
    _flowData.canopyCover = _canopyCoverController.text.trim();
    _flowData.lightExposure = (_selectedLightExposure ?? '').trim();
    _flowData.soilType = (_selectedSoilType ?? '').trim();
    _flowData.nearbyWaterSource = (_selectedNearbyWaterSource ?? '').trim();
  }

  Future<void> _showNextPlaceholder() async {
    _syncFlowDataFromForm();

    setState(() {
      _locationError = _flowData.location.trim().isEmpty
          ? 'Location is required. Use GPS to fill the location.'
          : null;
      _coordinateError =
          (_flowData.latitude.trim().isEmpty ||
              _flowData.longitude.trim().isEmpty)
          ? 'Latitude and Longitude are required'
          : null;
      _mountainError = null;
      _altitudeError = null;
      _elevationError = null;
      _habitatTypeError = null;
      _microHabitatError = null;
    });

    GlobalKey? firstErrorKey;
    if (_locationError != null) {
      firstErrorKey = _locationFieldKey;
    } else if (_coordinateError != null) {
      firstErrorKey = _locationFieldKey;
    }

    if (firstErrorKey != null) {
      final BuildContext? ctx = firstErrorKey.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          alignment: 0.1,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UploadSpeciesMorphologyScreen(
          flowData: _flowData,
          showSpeciesValueStep: widget.showSpeciesValueStep,
        ),
      ),
    );
  }

  Future<void> _saveDraft() async {
    if (_isSavingDraft) return;
    setState(() => _isSavingDraft = true);
    try {
      _syncFlowDataFromForm();
      await UploadSpeciesDraftStore.saveDraft(_flowData);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Draft saved.')));
      Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save draft right now.')),
      );
    } finally {
      if (mounted) setState(() => _isSavingDraft = false);
    }
  }

  List<Widget> _buildSightingDetailsForm() {
    return <Widget>[
      const SizedBox(height: 10),
      _buildSearchableDropdownField(
        label: 'Growth Substrate',
        hint: 'Select growth substrate',
        value: _selectedGrowthSubstrate,
        options: _growthSubstrateOptions,
        tooltip:
            'The surface or material the orchid grows on (e.g., tree bark, rock, soil, or another plant).',
        onChanged: (String? value) {
          setState(() {
            _selectedGrowthSubstrate = value;
          });
        },
      ),

      if (_selectedGrowthSubstrate == 'tree bark') ...<Widget>[
        const SizedBox(height: 10),
        _fieldLabel('Tree Species'),
        const SizedBox(height: 4),
        _buildField(
          controller: _hostTreeSpeciesController,
          hintText: 'Enter host tree species',
        ),
        const SizedBox(height: 6),
        _uploadFieldLabelWithTooltip(
          'Diameter / DBH (cm)',
          'Diameter at Breast Height — trunk diameter measured at 1.3 m above ground on the host tree.',
        ),
        const SizedBox(height: 4),
        _buildField(
          controller: _hostTreeDiameterController,
          hintText: 'Enter DBH in cm',
          keyboardType: TextInputType.number,
        ),
      ],
      const SizedBox(height: 10),
      _fieldLabel('Environmental Data'),
      const SizedBox(height: 8),
      _uploadFieldLabelWithTooltip(
        'Canopy Cover (%)',
        'Estimated percentage of the sky blocked by tree canopy directly above the orchid (0 = open sky, 100 = fully covered).',
      ),
      const SizedBox(height: 4),
      _buildField(
        controller: _canopyCoverController,
        hintText: 'Enter percentage (0-100)',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      const SizedBox(height: 8),
      _buildSearchableDropdownField(
        label: 'Light Exposure',
        hint: 'Select light exposure',
        value: _selectedLightExposure,
        options: _lightExposureOptions,
        tooltip:
            'Amount of sunlight the orchid receives at its location (e.g., full sun, partial shade, or deep shade).',
        onChanged: (String? value) {
          setState(() {
            _selectedLightExposure = value;
          });
        },
      ),
      const SizedBox(height: 8),
      Column(
        key: _habitatTypeFieldKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSearchableDropdownField(
            label: 'Habitat Type',
            hint: 'Select habitat type',
            value: _selectedHabitatType,
            options: _habitatTypeOptions,
            tooltip:
                'General type of forest or environment where the orchid was observed (e.g., lowland forest, mossy forest).',
            onChanged: (String? value) {
              if (_habitatTypeError != null) {
                setState(() => _habitatTypeError = null);
              }
              setState(() {
                _selectedHabitatType = value;
              });
            },
          ),
          if (_selectedHabitatType == 'Others') ...<Widget>[
            const SizedBox(height: 8),
            _fieldLabel('Specify Habitat Type'),
            const SizedBox(height: 4),
            _buildField(
              controller: _otherHabitatTypeController,
              hintText: 'Enter habitat type',
            ),
          ],
          if (_habitatTypeError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Text(
                _habitatTypeError!,
                style: TextStyle(fontSize: 12, color: Color(0xFFB00020)),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Column(
        key: _microHabitatFieldKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSearchableDropdownField(
            label: 'Microhabitat',
            hint: 'Select microhabitat',
            value: _selectedMicroHabitat,
            options: _microHabitatOptions,
            tooltip:
                'Specific micro-location within the broader habitat where the orchid was found (e.g., canopy, understory, forest floor).',
            onChanged: (String? value) {
              if (_microHabitatError != null) {
                setState(() => _microHabitatError = null);
              }
              setState(() {
                _selectedMicroHabitat = value;
              });
            },
          ),
          if (_microHabitatError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Text(
                _microHabitatError!,
                style: TextStyle(fontSize: 12, color: Color(0xFFB00020)),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      _buildSearchableDropdownField(
        label: 'Soil Type',
        hint: 'Select soil type',
        value: _selectedSoilType,
        options: _soilTypeOptions,
        onChanged: (String? value) {
          setState(() {
            _selectedSoilType = value;
          });
        },
      ),
      const SizedBox(height: 8),
      _buildSearchableDropdownField(
        label: 'Nearby Water Source',
        hint: 'Select water source',
        value: _selectedNearbyWaterSource,
        options: _nearbyWaterSourceOptions,
        onChanged: (String? value) {
          setState(() {
            _selectedNearbyWaterSource = value;
          });
        },
      ),
      const SizedBox(height: 24),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _uploadBg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _UploadFormHeader(
                title: widget.flowTitle,
                sectionTitle: 'Location & Habitat',
                step: 2,
                totalSteps: 5,
                stepIcon: Icons.location_on_outlined,
                entryId: _flowData.entryId,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // ── Geographical Location Card ───────────────────────
                    _uploadFormCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Row(
                            children: <Widget>[
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: _uploadPrimary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Geographical / Location Data',
                                style: _uploadSectionTitleStyle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _fieldLabel('GPS Location *'),
                          const SizedBox(height: 6),
                          Column(
                            key: _locationFieldKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _uploadSubCard(
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: TextField(
                                        controller: _locationController,
                                        readOnly: true,
                                        style: _uploadInputTextStyle,
                                        decoration: _fieldDecoration(
                                          'Tap Acquire GPS to fill location',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      onPressed: _isResolvingLocation
                                          ? null
                                          : _useGpsLocation,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _uploadPrimary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        elevation: 0,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      icon: Icon(
                                        _isResolvingLocation
                                            ? Icons.sync_rounded
                                            : Icons.my_location_rounded,
                                        size: 16,
                                      ),
                                      label: Text(
                                        _isResolvingLocation
                                            ? 'Locating...'
                                            : 'Use GPS',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_locationError != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 6,
                                    left: 12,
                                  ),
                                  child: Text(
                                    _locationError!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFB00020),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _uploadFieldLabelWithTooltip(
                            'GPS Coordinates',
                            'Precise geographic coordinates (latitude and longitude) of where the orchid was observed.',
                          ),
                          const SizedBox(height: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        _fieldLabel('Latitude *'),
                                        const SizedBox(height: 4),
                                        TextField(
                                          controller: _latitudeController,
                                          style: _uploadInputTextStyle,
                                          keyboardType: TextInputType.number,
                                          onChanged: (_) {
                                            if (_coordinateError != null) {
                                              setState(
                                                () => _coordinateError = null,
                                              );
                                            }
                                          },
                                          decoration: _fieldDecoration(
                                            'e.g. 7.123456',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        _fieldLabel('Longitude *'),
                                        const SizedBox(height: 4),
                                        TextField(
                                          controller: _longitudeController,
                                          style: _uploadInputTextStyle,
                                          keyboardType: TextInputType.number,
                                          onChanged: (_) {
                                            if (_coordinateError != null) {
                                              setState(
                                                () => _coordinateError = null,
                                              );
                                            }
                                          },
                                          decoration: _fieldDecoration(
                                            'e.g. 125.123456',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (_coordinateError != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 6,
                                    left: 12,
                                  ),
                                  child: Text(
                                    _coordinateError!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFB00020),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _fieldLabel('Mountain / General Location'),
                          const SizedBox(height: 6),
                          Column(
                            key: _mountainFieldKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _buildField(
                                controller: _mountainController,
                                hintText: 'Mt. Busa',
                              ),
                              if (_mountainError != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 6,
                                    left: 12,
                                  ),
                                  child: Text(
                                    _mountainError!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFB00020),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildSearchableDropdownField(
                            label: 'Specific Site / Ecological Zone',
                            hint: 'Trail, Ridge, Streamside, Others…',
                            value: _selectedSpecificSite,
                            options: _specificSiteOptions,
                            onChanged: (String? value) =>
                                setState(() => _selectedSpecificSite = value),
                          ),
                          if (_selectedSpecificSite == 'Other') ...<Widget>[
                            const SizedBox(height: 10),
                            _fieldLabel('Specify Alternative Site'),
                            const SizedBox(height: 6),
                            _buildField(
                              controller: _otherSpecificSiteController,
                              hintText: 'Enter site description',
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  key: _altitudeFieldKey,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _uploadFieldLabelWithTooltip(
                                      'Altitude (m)',
                                      'Height of the observation site above sea level, in meters.',
                                    ),
                                    const SizedBox(height: 6),
                                    _buildField(
                                      controller: _altitudeController,
                                      hintText: 'e.g. 800',
                                      keyboardType: TextInputType.number,
                                    ),
                                    if (_altitudeError != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 6,
                                          left: 12,
                                        ),
                                        child: Text(
                                          _altitudeError!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFFB00020),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  key: _elevationFieldKey,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _uploadFieldLabelWithTooltip(
                                      'Elevation (m)',
                                      'Vertical height of the terrain surface at the observation point above sea level.',
                                    ),
                                    const SizedBox(height: 6),
                                    _buildField(
                                      controller: _elevationController,
                                      hintText: 'e.g. 1500',
                                      keyboardType: TextInputType.number,
                                    ),
                                    if (_elevationError != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 6,
                                          left: 12,
                                        ),
                                        child: Text(
                                          _elevationError!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFFB00020),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ── Habitat Information Card ────────────────────────
                    _uploadFormCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Row(
                            children: <Widget>[
                              Icon(
                                Icons.forest_outlined,
                                size: 16,
                                color: _uploadPrimary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Habitat Information',
                                style: _uploadSectionTitleStyle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ..._buildSightingDetailsForm(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _uploadNextButton(
                      onPressed: _showNextPlaceholder,
                      label: 'Next — Morphology',
                    ),
                    const SizedBox(height: 8),
                    _uploadSaveDraftButton(
                      onPressed: _isSavingDraft ? null : _saveDraft,
                      label: _isSavingDraft
                          ? 'Saving Draft...'
                          : 'Save as Draft',
                    ),
                    const SizedBox(height: 8),
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

  static const List<String> _pseudobulbOptions = <String>['Yes', 'No'];

  static const List<String> _leafShapeOptions = <String>[
    'Linear & Narrow',
    'Rounded & Oval',
    'Pointy or Tapered',
    'Reversed',
    'Specialized Shapes',
  ];

  static const List<String> _leafTextureOptions = <String>[
    'Smooth',
    'Leathery',
    'Hairy or Fuzzy',
    'Thin or Fragile',
  ];

  static const List<String> _leafArrangementOptions = <String>[
    'Alternate',
    'Opposite',
    'Whorled',
  ];

  static const List<String> _inflorescenceTypeOptions = <String>[
    'Raceme',
    'Spike',
    'Panicle',
    'Solitary',
  ];

  static const List<String> _petalCharacteristicsOptions = <String>[
    'Obovate',
    'Elliptic',
    'Spatulate',
  ];

  static const List<String> _labellumOptions = <String>[
    'Trilobed (Three-lobed)',
    'Saccate (Bag-like)',
    'Spurred',
  ];

  static const List<String> _fragranceOptions = <String>[
    'None',
    'Faint',
    'Strong',
    'Sweet',
    'Musky',
    'Spicy',
  ];

  static const List<String> _bloomingStageOptions = <String>[
    'Budding',
    'Anthesis (Early)',
    'Full Bloom',
    'Senescent',
  ];

  static const List<String> _fruitTypeOptions = <String>[
    'Capsule',
    'Pod',
    'Berry',
  ];

  static const List<String> _seedCapsuleConditionOptions = <String>[
    'Immature (Green)',
    'Mature (Yellow/Brown)',
    'Dehisced (Split)',
    'Aborted',
  ];

  String? _selectedLeafType;
  String? _selectedFlowerColor;
  String? _selectedFloweringFromMonth;
  String? _selectedFloweringToMonth;
  bool _floweringSeasonUnknown = false;
  bool _isSavingDraft = false;

  // Plant Structure
  late TextEditingController _plantHeightController;
  String? _selectedPseudobulbPresent;
  late TextEditingController _stemLengthController;
  late TextEditingController _rootLengthController;

  // Leaves
  late TextEditingController _numberOfLeavesController;
  String? _selectedLeafShape;
  late TextEditingController _leafLengthController;
  late TextEditingController _leafWidthController;
  List<String> _selectedLeafTexture = <String>[];
  String? _selectedLeafArrangement;

  // Flowers
  late TextEditingController _numberOfFlowersController;
  late TextEditingController _flowerDiameterController;
  String? _selectedInflorescenceType;
  String? _selectedPetalCharacteristics;
  late TextEditingController _sepalCharacteristicsController;
  String? _selectedLabellumDescription;
  String? _selectedFragrance;
  String? _selectedBloomingStage;

  // Fruits/Seeds
  String? _selectedFruitPresent;
  String? _selectedFruitType;
  String? _selectedSeedCapsuleCondition;

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
    _floweringSeasonUnknown = _flowData.floweringFromMonth == 'Unknown';
    _selectedFloweringFromMonth =
        _flowData.floweringFromMonth.trim().isEmpty ||
            _flowData.floweringFromMonth == 'Unknown'
        ? null
        : _flowData.floweringFromMonth;
    _selectedFloweringToMonth =
        _flowData.floweringToMonth.trim().isEmpty ||
            _flowData.floweringToMonth == 'Unknown'
        ? null
        : _flowData.floweringToMonth;

    // Plant Structure
    _plantHeightController = TextEditingController(text: _flowData.plantHeight);
    _selectedPseudobulbPresent = _flowData.pseudobulbPresent.trim().isEmpty
        ? null
        : _flowData.pseudobulbPresent;
    _stemLengthController = TextEditingController(text: _flowData.stemLength);
    _rootLengthController = TextEditingController(text: _flowData.rootLength);

    // Leaves
    _numberOfLeavesController = TextEditingController(
      text: _flowData.numberOfLeaves,
    );
    _selectedLeafShape = _flowData.leafShape.trim().isEmpty
        ? null
        : _flowData.leafShape;
    _leafLengthController = TextEditingController(text: _flowData.leafLength);
    _leafWidthController = TextEditingController(text: _flowData.leafWidth);
    _selectedLeafTexture = _flowData.leafTexture.trim().isEmpty
        ? <String>[]
        : _flowData.leafTexture.split(',').map((String s) => s.trim()).toList();
    _selectedLeafArrangement = _flowData.leafArrangement.trim().isEmpty
        ? null
        : _flowData.leafArrangement;

    // Flowers
    _numberOfFlowersController = TextEditingController(
      text: _flowData.numberOfFlowers,
    );
    _flowerDiameterController = TextEditingController(
      text: _flowData.flowerDiameter,
    );
    _selectedInflorescenceType = _flowData.inflorescenceType.trim().isEmpty
        ? null
        : _flowData.inflorescenceType;
    _selectedPetalCharacteristics =
        _flowData.petalCharacteristics.trim().isEmpty
        ? null
        : _flowData.petalCharacteristics;
    _sepalCharacteristicsController = TextEditingController(
      text: _flowData.sepalCharacteristics,
    );
    _selectedLabellumDescription = _flowData.labellumDescription.trim().isEmpty
        ? null
        : _flowData.labellumDescription;
    _selectedFragrance = _flowData.fragrance.trim().isEmpty
        ? null
        : _flowData.fragrance;
    _selectedBloomingStage = _flowData.bloomingStage.trim().isEmpty
        ? null
        : _flowData.bloomingStage;

    // Fruits/Seeds
    _selectedFruitPresent = _flowData.fruitPresent.trim().isEmpty
        ? null
        : _flowData.fruitPresent;
    _selectedFruitType = _flowData.fruitType.trim().isEmpty
        ? null
        : _flowData.fruitType;
    _selectedSeedCapsuleCondition =
        _flowData.seedCapsuleCondition.trim().isEmpty
        ? null
        : _flowData.seedCapsuleCondition;
  }

  @override
  void dispose() {
    _plantHeightController.dispose();
    _stemLengthController.dispose();
    _rootLengthController.dispose();
    _numberOfLeavesController.dispose();
    _leafLengthController.dispose();
    _leafWidthController.dispose();
    _numberOfFlowersController.dispose();
    _flowerDiameterController.dispose();
    _sepalCharacteristicsController.dispose();
    super.dispose();
  }

  void _syncFlowDataFromForm() {
    _flowData.leafType = (_selectedLeafType ?? '').trim();
    _flowData.flowerColor = (_selectedFlowerColor ?? '').trim();
    if (_floweringSeasonUnknown) {
      _flowData.floweringFromMonth = 'Unknown';
      _flowData.floweringToMonth = 'Unknown';
    } else {
      _flowData.floweringFromMonth = (_selectedFloweringFromMonth ?? '').trim();
      _flowData.floweringToMonth = (_selectedFloweringToMonth ?? '').trim();
    }

    // Plant Structure
    _flowData.plantHeight = _plantHeightController.text.trim();
    _flowData.pseudobulbPresent = (_selectedPseudobulbPresent ?? '').trim();
    _flowData.stemLength = _stemLengthController.text.trim();
    _flowData.rootLength = _rootLengthController.text.trim();

    // Leaves
    _flowData.numberOfLeaves = _numberOfLeavesController.text.trim();
    _flowData.leafShape = (_selectedLeafShape ?? '').trim();
    _flowData.leafLength = _leafLengthController.text.trim();
    _flowData.leafWidth = _leafWidthController.text.trim();
    _flowData.leafTexture = _selectedLeafTexture.join(', ');
    _flowData.leafArrangement = (_selectedLeafArrangement ?? '').trim();

    // Flowers
    _flowData.numberOfFlowers = _numberOfFlowersController.text.trim();
    _flowData.flowerDiameter = _flowerDiameterController.text.trim();
    _flowData.inflorescenceType = (_selectedInflorescenceType ?? '').trim();
    _flowData.petalCharacteristics = (_selectedPetalCharacteristics ?? '')
        .trim();
    _flowData.sepalCharacteristics = _sepalCharacteristicsController.text
        .trim();
    _flowData.labellumDescription = (_selectedLabellumDescription ?? '').trim();
    _flowData.fragrance = (_selectedFragrance ?? '').trim();
    _flowData.bloomingStage = (_selectedBloomingStage ?? '').trim();

    // Fruits/Seeds
    _flowData.fruitPresent = (_selectedFruitPresent ?? '').trim();
    _flowData.fruitType = (_selectedFruitType ?? '').trim();
    _flowData.seedCapsuleCondition = (_selectedSeedCapsuleCondition ?? '')
        .trim();
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

  Future<void> _saveDraft() async {
    if (_isSavingDraft) return;
    setState(() => _isSavingDraft = true);
    try {
      _syncFlowDataFromForm();
      await UploadSpeciesDraftStore.saveDraft(_flowData);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Draft saved.')));
      Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save draft right now.')),
      );
    } finally {
      if (mounted) setState(() => _isSavingDraft = false);
    }
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

  Widget _fieldLabel(String text) => Text(text, style: _uploadFieldLabelStyle);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _uploadBg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _UploadFormHeader(
                title: 'Upload Orchid',
                step: 3,
                totalSteps: 5,
                stepIcon: Icons.local_florist_outlined,
                sectionTitle: 'Morphological Characteristics',
                entryId: _flowData.entryId,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // ── Plant Structure ───────────────────────────────────
                    _uploadFormCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.grass_outlined,
                                size: 16,
                                color: _uploadPrimary,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Plant Structure',
                                style: _uploadSectionTitleStyle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _fieldLabel('Plant Height (cm)'),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _plantHeightController,
                            keyboardType: TextInputType.number,
                            style: _uploadInputTextStyle,
                            decoration: _fieldDecoration().copyWith(
                              hintText: 'Enter plant height in cm',
                            ),
                          ),
                          const SizedBox(height: 10),
                          _uploadFieldLabelWithTooltip(
                            'Pseudobulb Present',
                            'A swollen, bulb-like stem segment found in many orchids, used to store water and nutrients.',
                          ),
                          const SizedBox(height: 4),
                          _dropdownField(
                            hint: 'Select yes or no',
                            value: _selectedPseudobulbPresent,
                            options: _pseudobulbOptions,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedPseudobulbPresent = value;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _fieldLabel('Stem Length (cm)'),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: _stemLengthController,
                                      keyboardType: TextInputType.number,
                                      style: _uploadInputTextStyle,
                                      decoration: _fieldDecoration().copyWith(
                                        hintText: 'cm',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _fieldLabel('Root Length (cm)'),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: _rootLengthController,
                                      keyboardType: TextInputType.number,
                                      style: _uploadInputTextStyle,
                                      decoration: _fieldDecoration().copyWith(
                                        hintText: 'cm',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ── Leaves ────────────────────────────────────────────
                    _uploadFormCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.eco_outlined,
                                size: 16,
                                color: _uploadPrimary,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Leaves',
                                style: _uploadSectionTitleStyle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _fieldLabel('Number of Leaves'),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _numberOfLeavesController,
                            keyboardType: TextInputType.number,
                            style: _uploadInputTextStyle,
                            decoration: _fieldDecoration().copyWith(
                              hintText: 'Enter number of leaves',
                            ),
                          ),
                          const SizedBox(height: 10),
                          _fieldLabel('Leaf Shape'),
                          const SizedBox(height: 4),
                          _dropdownField(
                            hint: 'Select leaf shape',
                            value: _selectedLeafShape,
                            options: _leafShapeOptions,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedLeafShape = value;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _fieldLabel('Leaf Length (cm)'),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: _leafLengthController,
                                      keyboardType: TextInputType.number,
                                      style: _uploadInputTextStyle,
                                      decoration: _fieldDecoration().copyWith(
                                        hintText: 'Length',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _fieldLabel('Leaf Width (cm)'),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: _leafWidthController,
                                      keyboardType: TextInputType.number,
                                      style: _uploadInputTextStyle,
                                      decoration: _fieldDecoration().copyWith(
                                        hintText: 'Width',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _uploadFieldLabelWithTooltip(
                            'Leaf Surface Texture',
                            'Physical texture of the leaf surface (e.g., smooth, waxy, hairy, or rough).',
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Multiple selections allowed',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _leafTextureOptions
                                .map((String option) {
                                  final bool selected = _selectedLeafTexture
                                      .contains(option);
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (selected) {
                                          _selectedLeafTexture.remove(option);
                                        } else {
                                          _selectedLeafTexture.add(option);
                                        }
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? _uploadPrimary
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: selected
                                              ? _uploadPrimary
                                              : _uploadBorderColor,
                                          width: 1.5,
                                        ),
                                        boxShadow: selected
                                            ? <BoxShadow>[
                                                BoxShadow(
                                                  color: _uploadPrimary
                                                      .withValues(alpha: 0.18),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: selected
                                              ? Colors.white
                                              : const Color(0xFF374151),
                                        ),
                                      ),
                                    ),
                                  );
                                })
                                .toList(growable: false),
                          ),
                          const SizedBox(height: 10),
                          _uploadFieldLabelWithTooltip(
                            'Leaf Arrangement',
                            'How leaves are organized along the stem (e.g., alternate, opposite, or in a basal rosette).',
                          ),
                          const SizedBox(height: 4),
                          _dropdownField(
                            hint: 'Select leaf arrangement',
                            value: _selectedLeafArrangement,
                            options: _leafArrangementOptions,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedLeafArrangement = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ── Flowers ───────────────────────────────────────────
                    _uploadFormCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.local_florist_outlined,
                                size: 16,
                                color: _uploadPrimary,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Flowers',
                                style: _uploadSectionTitleStyle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _fieldLabel('Flower Color'),
                          const SizedBox(height: 4),
                          _dropdownField(
                            hint: 'Select flower color',
                            value: _selectedFlowerColor,
                            options: _flowerColorOptions,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedFlowerColor = value;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _fieldLabel('No. of Flowers'),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: _numberOfFlowersController,
                                      keyboardType: TextInputType.number,
                                      style: _uploadInputTextStyle,
                                      decoration: _fieldDecoration().copyWith(
                                        hintText: 'Count',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _fieldLabel('Diameter (cm)'),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: _flowerDiameterController,
                                      keyboardType: TextInputType.number,
                                      style: _uploadInputTextStyle,
                                      decoration: _fieldDecoration().copyWith(
                                        hintText: 'cm',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _uploadFieldLabelWithTooltip(
                            'Inflorescence Type',
                            'The arrangement pattern of multiple flowers on the flower stalk (e.g., raceme, panicle, or solitary).',
                          ),
                          const SizedBox(height: 4),
                          _dropdownField(
                            hint: 'Select inflorescence type',
                            value: _selectedInflorescenceType,
                            options: _inflorescenceTypeOptions,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedInflorescenceType = value;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          _uploadFieldLabelWithTooltip(
                            'Petal Characteristics',
                            'Descriptors for the shape, texture, or markings of the inner flower parts.',
                          ),
                          const SizedBox(height: 4),
                          _dropdownField(
                            hint: 'Select petal characteristics',
                            value: _selectedPetalCharacteristics,
                            options: _petalCharacteristicsOptions,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedPetalCharacteristics = value;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          _uploadFieldLabelWithTooltip(
                            'Sepal Characteristics',
                            'Description of the outer protective parts surrounding the flower, usually leaf-like and located below the petals.',
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _sepalCharacteristicsController,
                            style: _uploadInputTextStyle,
                            decoration: _fieldDecoration().copyWith(
                              hintText: 'Describe sepal characteristics',
                            ),
                          ),
                          const SizedBox(height: 10),
                          _uploadFieldLabelWithTooltip(
                            'Labellum / Lip Description',
                            'The distinctive modified petal unique to orchids. It is often elaborately patterned or shaped to attract specific pollinators.',
                          ),
                          const SizedBox(height: 4),
                          _dropdownField(
                            hint: 'Select labellum type',
                            value: _selectedLabellumDescription,
                            options: _labellumOptions,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedLabellumDescription = value;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _uploadFieldLabelWithTooltip(
                                      'Fragrance',
                                      'Scent intensity of the flower at time of observation.',
                                    ),
                                    const SizedBox(height: 4),
                                    _dropdownField(
                                      hint: 'Level',
                                      value: _selectedFragrance,
                                      options: _fragranceOptions,
                                      onChanged: (String? value) {
                                        setState(() {
                                          _selectedFragrance = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _uploadFieldLabelWithTooltip(
                                      'Blooming Stage',
                                      'Current developmental stage of the flower at time of observation (e.g., bud, fully open, wilting).',
                                    ),
                                    const SizedBox(height: 4),
                                    _dropdownField(
                                      hint: 'Stage',
                                      value: _selectedBloomingStage,
                                      options: _bloomingStageOptions,
                                      onChanged: (String? value) {
                                        setState(() {
                                          _selectedBloomingStage = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _uploadFieldLabelWithTooltip(
                            'Flowering Season',
                            'The months during which this orchid typically produces flowers.',
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: <Widget>[
                              Checkbox(
                                value: _floweringSeasonUnknown,
                                onChanged: (bool? v) {
                                  setState(() {
                                    _floweringSeasonUnknown = v ?? false;
                                    if (_floweringSeasonUnknown) {
                                      _selectedFloweringFromMonth = null;
                                      _selectedFloweringToMonth = null;
                                    }
                                  });
                                },
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Text(
                                'Unknown',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                          if (!_floweringSeasonUnknown) ...<Widget>[
                            const SizedBox(height: 4),
                            Row(
                              children: <Widget>[
                                const Text(
                                  'From',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ── Fruits / Seeds ────────────────────────────────────
                    _uploadFormCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.spa_outlined,
                                size: 16,
                                color: _uploadPrimary,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Fruits / Seeds',
                                style: _uploadSectionTitleStyle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _fieldLabel('Fruit Present'),
                          const SizedBox(height: 4),
                          _dropdownField(
                            hint: 'Select yes or no',
                            value: _selectedFruitPresent,
                            options: _pseudobulbOptions,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedFruitPresent = value;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          _fieldLabel('Fruit Type'),
                          const SizedBox(height: 4),
                          _dropdownField(
                            hint: 'Select fruit type',
                            value: _selectedFruitType,
                            options: _fruitTypeOptions,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedFruitType = value;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          _uploadFieldLabelWithTooltip(
                            'Seed Capsule Condition',
                            'Maturity and physical state of the seed pod if present (e.g., immature, mature, dehisced/open).',
                          ),
                          const SizedBox(height: 4),
                          _dropdownField(
                            hint: 'Select seed capsule condition',
                            value: _selectedSeedCapsuleCondition,
                            options: _seedCapsuleConditionOptions,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedSeedCapsuleCondition = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _uploadNextButton(
                      onPressed: _openNextStep,
                      label: 'Next — Ecological Data',
                    ),
                    const SizedBox(height: 8),
                    _uploadSaveDraftButton(
                      onPressed: _isSavingDraft ? null : _saveDraft,
                      label: _isSavingDraft
                          ? 'Saving Draft...'
                          : 'Save as Draft',
                    ),
                    const SizedBox(height: 8),
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

class _ContributorEntry {
  _ContributorEntry({String name = '', this.selectedPosition})
    : nameController = TextEditingController(text: name);

  final TextEditingController nameController;
  String? selectedPosition;

  void dispose() => nameController.dispose();

  static const List<String> positionOptions = <String>[
    'Field Biologist/Botanist',
    'Taxonomist/Plant Identifier',
    'Conservationist',
    'Research Assistant/Field Assistant',
    'Photographer',
  ];
}

class UploadSpeciesImagesScreen extends StatefulWidget {
  const UploadSpeciesImagesScreen({required this.flowData, super.key});

  final UploadSpeciesFlowData flowData;

  @override
  State<UploadSpeciesImagesScreen> createState() =>
      _UploadSpeciesImagesScreenState();
}

class _UploadSpeciesImagesScreenState extends State<UploadSpeciesImagesScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  static const int _maxImageBytes = 5 * 1024 * 1024;
  static const String _catSpecimen = 'specimen_photo';
  static const String _catWholePlant = 'whole_plant';
  static const String _catCloseupFlower = 'closeup_flower';
  static const String _catHabitat = 'habitat_photo';
  static const String _catThreeD = 'three_d_photo';

  late final UploadSpeciesFlowData _flowData;
  final List<UploadSpeciesImageDraft> _specimenPhotos =
      <UploadSpeciesImageDraft>[];
  final List<UploadSpeciesImageDraft> _wholePlantPhotos =
      <UploadSpeciesImageDraft>[];
  final List<UploadSpeciesImageDraft> _closeupFlowerPhotos =
      <UploadSpeciesImageDraft>[];
  final List<UploadSpeciesImageDraft> _habitatPhotos =
      <UploadSpeciesImageDraft>[];
  final List<UploadSpeciesImageDraft> _threeDPhotos =
      <UploadSpeciesImageDraft>[];
  final Map<String, Uint8List> _imageBytesCache = <String, Uint8List>{};

  String? _videoPath;
  bool _isPickingImage = false;
  bool _isPickingVideo = false;
  bool _isSavingDraft = false;
  String? _headResearcherError;

  late final TextEditingController _headResearcherController;
  late final TextEditingController _institutionController;
  late final TextEditingController _researcherNotesController;
  late final TextEditingController _unusualObservationsController;
  late final TextEditingController _studyTitleController;
  late final TextEditingController _studyLinkController;
  String? _studyFilePath;
  String? _studyFileName;
  final List<_ContributorEntry> _contributorEntries = <_ContributorEntry>[];

  @override
  void initState() {
    super.initState();
    _flowData = widget.flowData;

    for (final UploadSpeciesImageDraft image in _flowData.images) {
      _listForCategory(image.category).add(
        UploadSpeciesImageDraft(
          path: image.path,
          sizeBytes: image.sizeBytes,
          photoCredit: image.photoCredit,
          category: image.category,
        ),
      );
      _loadPreviewForPath(image.path);
    }

    _videoPath = _flowData.videoPath.trim().isEmpty
        ? null
        : _flowData.videoPath.trim();
    _headResearcherController = TextEditingController(
      text: _flowData.headResearcher.trim(),
    );
    _institutionController = TextEditingController(text: _flowData.institution);
    _researcherNotesController = TextEditingController(
      text: _flowData.researcherNotes,
    );
    _unusualObservationsController = TextEditingController(
      text: _flowData.unusualObservations,
    );
    _studyTitleController = TextEditingController(text: _flowData.studyTitle);
    _studyLinkController = TextEditingController(text: _flowData.studyLink);
    if (_flowData.studyFilePath.trim().isNotEmpty) {
      _studyFilePath = _flowData.studyFilePath;
      _studyFileName = _flowData.studyFilePath.split('/').last.split('\\').last;
    }

    if (_flowData.contributors.isNotEmpty) {
      for (final UploadContributorDraft c in _flowData.contributors) {
        _contributorEntries.add(
          _ContributorEntry(
            name: c.name,
            selectedPosition: c.position.trim().isEmpty ? null : c.position,
          ),
        );
      }
    }
    if (_contributorEntries.isEmpty) {
      _contributorEntries.add(_ContributorEntry());
    }
  }

  @override
  void dispose() {
    _headResearcherController.dispose();
    _institutionController.dispose();
    _researcherNotesController.dispose();
    _unusualObservationsController.dispose();
    _studyTitleController.dispose();
    _studyLinkController.dispose();
    for (final _ContributorEntry e in _contributorEntries) {
      e.dispose();
    }
    super.dispose();
  }

  List<UploadSpeciesImageDraft> _listForCategory(String category) {
    switch (category) {
      case _catWholePlant:
        return _wholePlantPhotos;
      case _catCloseupFlower:
        return _closeupFlowerPhotos;
      case _catHabitat:
        return _habitatPhotos;
      case _catThreeD:
        return _threeDPhotos;
      default:
        return _specimenPhotos;
    }
  }

  String _formatFileSize(int bytes) {
    final double mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(2)} MB';
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
    } catch (_) {}
  }

  Future<void> _pickImagesForCategory(String category) async {
    if (_isPickingImage) {
      return;
    }
    setState(() {
      _isPickingImage = true;
    });
    try {
      final List<XFile> picked = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 2048,
      );
      if (picked.isEmpty) {
        return;
      }
      final List<UploadSpeciesImageDraft> targetList = _listForCategory(
        category,
      );
      int skipped = 0;
      int added = 0;
      for (final XFile file in picked) {
        if (targetList.any(
          (UploadSpeciesImageDraft img) => img.path == file.path,
        )) {
          continue;
        }
        final Uint8List bytes = await file.readAsBytes();
        if (bytes.lengthInBytes > _maxImageBytes) {
          skipped++;
          continue;
        }
        targetList.add(
          UploadSpeciesImageDraft(
            path: file.path,
            sizeBytes: bytes.lengthInBytes,
            category: category,
          ),
        );
        _imageBytesCache[file.path] = bytes;
        added++;
      }
      if (!mounted) {
        return;
      }
      setState(() {});
      if (skipped > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$skipped image(s) exceeded 5 MB and were skipped.'),
          ),
        );
      } else if (added > 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$added image(s) added.')));
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

  Future<void> _pickVideo() async {
    if (_isPickingVideo) {
      return;
    }
    setState(() {
      _isPickingVideo = true;
    });
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );
      if (!mounted) {
        return;
      }
      if (video != null) {
        setState(() {
          _videoPath = video.path;
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to pick video right now.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingVideo = false;
        });
      }
    }
  }

  void _removeImageFromCategory(String category, int index) {
    final List<UploadSpeciesImageDraft> list = _listForCategory(category);
    if (index < 0 || index >= list.length) {
      return;
    }
    setState(() {
      _imageBytesCache.remove(list[index].path);
      list.removeAt(index);
    });
  }

  void _syncFlowDataFromForm() {
    _flowData.images = <UploadSpeciesImageDraft>[
      ..._specimenPhotos,
      ..._wholePlantPhotos,
      ..._closeupFlowerPhotos,
      ..._habitatPhotos,
      ..._threeDPhotos,
    ].map((UploadSpeciesImageDraft img) => img.copy()).toList(growable: false);
    _flowData.videoPath = _videoPath ?? '';
    _flowData.headResearcher = _headResearcherController.text.trim();
    _flowData.institution = _institutionController.text.trim();
    _flowData.researcherNotes = _researcherNotesController.text.trim();
    _flowData.unusualObservations = _unusualObservationsController.text.trim();
    _flowData.studyTitle = _studyTitleController.text.trim();
    _flowData.studyLink = _studyLinkController.text.trim();
    _flowData.studyFilePath = _studyFilePath ?? '';
    _flowData.contributors = _contributorEntries
        .where((e) => e.nameController.text.trim().isNotEmpty)
        .map(
          (e) => UploadContributorDraft(
            name: e.nameController.text.trim(),
            position: e.selectedPosition ?? '',
          ),
        )
        .toList(growable: false);
  }

  Future<void> _pickStudyFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx'],
      withData: false,
      withReadStream: false,
    );
    if (result != null && result.files.isNotEmpty) {
      final PlatformFile file = result.files.first;
      setState(() {
        _studyFilePath = file.path;
        _studyFileName = file.name;
      });
    }
  }

  Future<void> _saveDraft() async {
    if (_isSavingDraft) return;

    // Validate required field
    if (_headResearcherController.text.trim().isEmpty) {
      setState(
        () => _headResearcherError = 'Head Researcher name is required.',
      );
      return;
    }

    setState(() {
      _isSavingDraft = true;
    });
    try {
      _syncFlowDataFromForm();
      await UploadSpeciesDraftStore.saveDraft(_flowData);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved. You can upload it later.')),
      );
      Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
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

  Widget _buildAddButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: _uploadActionButtonStyle(),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildPhotoSlot(
    UploadSpeciesImageDraft image,
    String category,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _lineColor, width: 1.1),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: _imageBytesCache[image.path] != null
                      ? Image.memory(
                          _imageBytesCache[image.path]!,
                          fit: BoxFit.cover,
                        )
                      : ColoredBox(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Photo ${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatFileSize(image.sizeBytes),
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: _mutedTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFF7A2C22),
                ),
                onPressed: () => _removeImageFromCategory(category, index),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Photo Credit',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 36,
            child: TextFormField(
              initialValue: image.photoCredit,
              onChanged: (String v) {
                image.photoCredit = v.trim();
              },
              style: _uploadInputTextStyle,
              decoration: _uploadInputDecoration(hintText: 'Photographer name'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection({
    required String label,
    required String category,
    required List<UploadSpeciesImageDraft> images,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: _uploadFieldLabelStyle),
        const SizedBox(height: 6),
        _buildAddButton(
          label: 'Add Images',
          icon: Icons.add_photo_alternate_outlined,
          onPressed: _isPickingImage
              ? null
              : () => _pickImagesForCategory(category),
        ),
        for (int i = 0; i < images.length; i++)
          _buildPhotoSlot(images[i], category, i),
      ],
    );
  }

  Widget _build3DCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '3D Photo — multiple angles / series',
          style: _uploadFieldLabelStyle,
        ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: _isPickingImage ? null : _show3DPhotoFlow,
          style: _uploadActionButtonStyle(),
          icon: const Icon(Icons.view_in_ar_outlined, size: 18),
          label: const Text(
            'Upload 3D Images',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        for (int i = 0; i < _threeDPhotos.length; i++)
          _buildPhotoSlot(_threeDPhotos[i], _catThreeD, i),
      ],
    );
  }

  Future<void> _show3DPhotoFlow() async {
    final List<UploadSpeciesImageDraft>? result =
        await showDialog<List<UploadSpeciesImageDraft>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => _ThreeDPhotoUploadDialog(
        imagePicker: _imagePicker,
        existing: List<UploadSpeciesImageDraft>.from(_threeDPhotos),
        maxBytes: _maxImageBytes,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _threeDPhotos.clear();
      _threeDPhotos.addAll(result);
      for (final UploadSpeciesImageDraft img in result) {
        if (!_imageBytesCache.containsKey(img.path)) {
          _loadPreviewForPath(img.path);
        }
      }
    });
  }

  Widget _buildNotesField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: _uploadFieldLabelStyle),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: _uploadInputTextStyle,
          decoration: _uploadInputDecoration(hintText: hint).copyWith(
            errorText: errorText,
            errorStyle: const TextStyle(fontSize: 11),
          ),
          onChanged: errorText != null
              ? (_) => setState(() => _headResearcherError = null)
              : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _uploadBg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _UploadFormHeader(
                title: 'Upload Orchid',
                step: 5,
                totalSteps: 5,
                stepIcon: Icons.camera_alt_outlined,
                sectionTitle: 'Media & Researcher Notes',
                entryId: _flowData.entryId,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // ── Multimedia Documentation ──────────────────────
                    _uploadFormCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Multimedia Documentation',
                            style: _uploadSectionTitleStyle,
                          ),
                          const SizedBox(height: 14),
                          _buildCategorySection(
                            label: 'Specimen Photos',
                            category: _catSpecimen,
                            images: _specimenPhotos,
                          ),
                          const SizedBox(height: 14),
                          _buildCategorySection(
                            label: 'Whole Plant',
                            category: _catWholePlant,
                            images: _wholePlantPhotos,
                          ),
                          const SizedBox(height: 14),
                          _buildCategorySection(
                            label: 'Close-up Flower',
                            category: _catCloseupFlower,
                            images: _closeupFlowerPhotos,
                          ),
                          const SizedBox(height: 14),
                          _buildCategorySection(
                            label: 'Habitat Photo',
                            category: _catHabitat,
                            images: _habitatPhotos,
                          ),
                          const SizedBox(height: 14),
                          _build3DCategorySection(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // ── Video Documentation ───────────────────────────
                    _uploadFormCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Video Documentation',
                            style: _uploadSectionTitleStyle,
                          ),
                          const SizedBox(height: 12),
                          _buildAddButton(
                            label: _isPickingVideo
                                ? 'Selecting...'
                                : 'Add Video',
                            icon: Icons.videocam_outlined,
                            onPressed: _isPickingVideo ? null : _pickVideo,
                          ),
                          if (_videoPath != null) ...<Widget>[
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: _appBackgroundColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _lineColor, width: 1),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.videocam_outlined,
                                    color: _primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _videoPath!
                                          .split('/')
                                          .last
                                          .split('\\')
                                          .last,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Remove video',
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Color(0xFF7A2C22),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() {
                                      _videoPath = null;
                                    }),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // ── Contributors ───────────────────────────────────
                    _uploadFormCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Contributors',
                            style: _uploadSectionTitleStyle,
                          ),
                          const SizedBox(height: 14),
                          // Head Researcher (first)
                          _buildNotesField(
                            label: 'Head Observer / Researcher Name *',
                            controller: _headResearcherController,
                            hint: 'Full name of lead researcher',
                            errorText: _headResearcherError,
                          ),
                          const SizedBox(height: 14),
                          Divider(color: _lineColor, height: 1),
                          const SizedBox(height: 14),
                          // Team Members (name + position dropdown)
                          Text('Team Members', style: _uploadFieldLabelStyle),
                          const SizedBox(height: 10),
                          ...List<Widget>.generate(_contributorEntries.length, (
                            int i,
                          ) {
                            final _ContributorEntry entry =
                                _contributorEntries[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Text(
                                        'Member ${i + 1}',
                                        style: _uploadFieldLabelStyle,
                                      ),
                                      const Spacer(),
                                      if (_contributorEntries.length > 1)
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _contributorEntries[i].dispose();
                                              _contributorEntries.removeAt(i);
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            size: 20,
                                            color: Color(0xFF7A2C22),
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: entry.nameController,
                                    style: _uploadInputTextStyle,
                                    decoration: _uploadInputDecoration(
                                      hintText: 'Enter member name',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    isDense: true,
                                    isExpanded: true,
                                    initialValue: entry.selectedPosition,
                                    items: _ContributorEntry.positionOptions
                                        .map(
                                          (String opt) =>
                                              DropdownMenuItem<String>(
                                                value: opt,
                                                child: Text(
                                                  opt,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                        )
                                        .toList(growable: false),
                                    onChanged: (String? val) {
                                      setState(
                                        () => entry.selectedPosition = val,
                                      );
                                    },
                                    style: _uploadInputTextStyle,
                                    decoration: _uploadInputDecoration(
                                      hintText: 'Select position',
                                    ),
                                  ),
                                  if (i < _contributorEntries.length - 1)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Divider(
                                        color: _lineColor,
                                        height: 1,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                          TextButton.icon(
                            onPressed: () {
                              setState(
                                () => _contributorEntries.add(
                                  _ContributorEntry(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.add,
                              size: 16,
                              color: _uploadPrimary,
                            ),
                            label: const Text(
                              'Add Member',
                              style: TextStyle(
                                fontSize: 13,
                                color: _uploadPrimary,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Divider(color: _lineColor, height: 1),
                          const SizedBox(height: 14),
                          // Institution (last)
                          _buildNotesField(
                            label: 'Institution / Organization',
                            controller: _institutionController,
                            hint: 'Enter institution or organization',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // ── Notes & Remarks ─────────────────────────────────
                    _uploadFormCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Notes & Remarks',
                            style: _uploadSectionTitleStyle,
                          ),
                          const SizedBox(height: 14),
                          _buildNotesField(
                            label: 'Researcher Notes',
                            controller: _researcherNotesController,
                            hint: 'Enter field notes or remarks',
                            maxLines: 4,
                          ),
                          const SizedBox(height: 10),
                          _buildNotesField(
                            label: 'Unusual Observations',
                            controller: _unusualObservationsController,
                            hint: 'Describe any unusual findings',
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // ── Related Study ────────────────────────────────────
                    _uploadFormCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Text(
                                'Related Study',
                                style: _uploadSectionTitleStyle,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDE9FE),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Optional',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _uploadPrimary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Title of Study
                          Text('Title of Study', style: _uploadFieldLabelStyle),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _studyTitleController,
                            style: _uploadInputTextStyle,
                            decoration: _uploadInputDecoration(
                              hintText: 'Enter the title of the related study',
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Source Link
                          Text('Source Link', style: _uploadFieldLabelStyle),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _studyLinkController,
                            style: _uploadInputTextStyle,
                            keyboardType: TextInputType.url,
                            decoration:
                                _uploadInputDecoration(
                                  hintText: 'https://doi.org/...',
                                ).copyWith(
                                  prefixIcon: const Icon(
                                    Icons.link_rounded,
                                    size: 18,
                                    color: _uploadPrimary,
                                  ),
                                ),
                          ),
                          const SizedBox(height: 12),
                          // File Upload
                          Text(
                            'Upload Study File',
                            style: _uploadFieldLabelStyle,
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _pickStudyFile,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F3FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFDDD6FE),
                                  width: 1.5,
                                ),
                              ),
                              child: _studyFileName != null
                                  ? Row(
                                      children: <Widget>[
                                        const Icon(
                                          Icons.description_outlined,
                                          size: 20,
                                          color: _uploadPrimary,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _studyFileName!,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF4C1D95),
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => setState(() {
                                            _studyFilePath = null;
                                            _studyFileName = null;
                                          }),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                            color: _uploadPrimary,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const <Widget>[
                                        Icon(
                                          Icons.upload_file_rounded,
                                          size: 20,
                                          color: _uploadPrimary,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Tap to attach a file',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: _uploadPrimary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Accepted: PDF, DOC, DOCX, PPT, PPTX, TXT',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Draft-first flow: save here, then submit from Draft Uploads after review/edit.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: _mutedTextColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _uploadSaveDraftButton(
                onPressed: _isSavingDraft ? null : _saveDraft,
                label: _isSavingDraft ? 'Saving Draft...' : 'Save as Draft',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Standalone 3D Upload Flow ────────────────────────────────────────────────

class Upload3DRequirementsScreen extends StatelessWidget {
  const Upload3DRequirementsScreen({super.key});

  static const List<String> _angles = <String>[
    'Front View',
    'Left Side',
    'Right Side',
    'Top View',
    'Back / Bottom',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _UploadFormHeader(title: 'Upload 3D Image'),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Upload 3D Image',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                          color: _textColor,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add a 3D photo series to an existing orchid in the catalog.',
                        style: TextStyle(fontSize: 13, color: _mutedTextColor),
                      ),
                      const SizedBox(height: 20),
                      _uploadFormCard(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Requirements',
                              style: _uploadSectionTitleStyle,
                            ),
                            const SizedBox(height: 14),
                            _Upload3DReqItem(
                              icon: Icons.view_in_ar_outlined,
                              title: '5 Photos Required',
                              description:
                                  'Capture the orchid from 5 different angles: Front, Left Side, Right Side, Top, and Back/Bottom.',
                            ),
                            const SizedBox(height: 12),
                            _Upload3DReqItem(
                              icon: Icons.wb_sunny_outlined,
                              title: 'Consistent Lighting',
                              description:
                                  'Use the same lighting conditions across all 5 shots to ensure accurate 3D reconstruction.',
                            ),
                            const SizedBox(height: 12),
                            _Upload3DReqItem(
                              icon: Icons.center_focus_strong_outlined,
                              title: 'Centered & Stable',
                              description:
                                  'Keep the specimen centered in the frame and avoid camera shake or blur.',
                            ),
                            const SizedBox(height: 12),
                            _Upload3DReqItem(
                              icon: Icons.crop_free_outlined,
                              title: 'Plain Background',
                              description:
                                  'Use a neutral background to help isolate the subject for 3D modeling.',
                            ),
                            const SizedBox(height: 12),
                            _Upload3DReqItem(
                              icon: Icons.photo_size_select_large_outlined,
                              title: 'File Constraints',
                              description:
                                  'Max 5 MB per photo. Accepted formats: JPG or PNG.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _uploadFormCard(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Required Angles',
                              style: _uploadSectionTitleStyle,
                            ),
                            const SizedBox(height: 12),
                            ..._angles.asMap().entries.map(
                              (MapEntry<int, String> e) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: <Widget>[
                                    Container(
                                      width: 26,
                                      height: 26,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        color: _uploadPrimary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${e.key + 1}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      e.value,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _textColor,
                                      ),
                                    ),
                                  ],
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
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Upload3DOrchidPickerScreen(),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _uploadPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Proceed',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

class _Upload3DReqItem extends StatelessWidget {
  const _Upload3DReqItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _uploadPrimary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Step 2: Orchid Catalog Picker ─────────────────────────────────────────────

class Upload3DOrchidPickerScreen extends StatefulWidget {
  const Upload3DOrchidPickerScreen({super.key});

  @override
  State<Upload3DOrchidPickerScreen> createState() =>
      _Upload3DOrchidPickerScreenState();
}

class _Upload3DOrchidPickerScreenState
    extends State<Upload3DOrchidPickerScreen> {
  late final Future<List<CatalogSpecies>> _speciesFuture;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speciesFuture = _loadSpecies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<CatalogSpecies>> _loadSpecies() async {
    try {
      final List<dynamic> data = await Supabase.instance.client
          .from('orchids')
          .select(
            'orchid_id, sci_name, common_name, local_name, genus(genus_name), picture(file_url)',
          )
          .order('sci_name');
      return data
          .whereType<Map>()
          .map((Map item) {
            final Map<String, dynamic> json = Map<String, dynamic>.from(item);
            final String sci = (json['sci_name'] ?? '').toString().trim();
            if (sci.isEmpty) return null;
            final dynamic genusData = json['genus'];
            final String genus = genusData is Map
                ? (genusData['genus_name'] ?? '').toString()
                : '';
            final dynamic pic = json['picture'];
            final String imgUrl =
                pic is List && pic.isNotEmpty
                    ? (pic.first['file_url'] ?? '').toString()
                    : '';
            return CatalogSpecies(
              id: int.tryParse((json['orchid_id'] ?? '').toString()),
              scientificName: sci,
              commonName:
                  (json['common_name'] ?? 'Common Name').toString().trim(),
              genus: genus,
              imageUrl: imgUrl.isNotEmpty ? imgUrl : null,
            );
          })
          .whereType<CatalogSpecies>()
          .toList(growable: false);
    } catch (_) {
      return <CatalogSpecies>[];
    }
  }

  List<CatalogSpecies> _filtered(List<CatalogSpecies> all) {
    if (_searchQuery.isEmpty) return all;
    final String q = _searchQuery.toLowerCase();
    return all
        .where(
          (CatalogSpecies s) =>
              s.scientificName.toLowerCase().contains(q) ||
              s.commonName.toLowerCase().contains(q) ||
              s.genus.toLowerCase().contains(q),
        )
        .toList();
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
            children: <Widget>[
              const _UploadFormHeader(title: 'Upload 3D Image'),
              const SizedBox(height: 18),
              Text(
                'Select Orchid',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose the orchid you want to add 3D photos to.',
                style: TextStyle(fontSize: 13, color: _mutedTextColor),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                onChanged: (String v) =>
                    setState(() => _searchQuery = v.trim()),
                style: _uploadInputTextStyle,
                decoration: _uploadInputDecoration(
                  hintText: 'Search by name or genus…',
                ).copyWith(
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: FutureBuilder<List<CatalogSpecies>>(
                  future: _speciesFuture,
                  builder: (
                    BuildContext ctx,
                    AsyncSnapshot<List<CatalogSpecies>> snap,
                  ) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: _uploadPrimary,
                        ),
                      );
                    }
                    final List<CatalogSpecies> items =
                        _filtered(snap.data ?? <CatalogSpecies>[]);
                    if (items.isEmpty) {
                      return Center(
                        child: Text(
                          snap.data == null
                              ? 'Failed to load catalog.'
                              : 'No orchids found.',
                          style: TextStyle(color: _mutedTextColor),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 8),
                      itemBuilder: (BuildContext ctx2, int i) =>
                          _buildTile(items[i]),
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

  Widget _buildTile(CatalogSpecies species) {
    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => Upload3DImagesScreen(orchid: species),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: species.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: species.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => _orchidPlaceholder(60),
                        errorWidget: (_, _, _) => _orchidPlaceholder(60),
                      )
                    : _orchidPlaceholder(60),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      species.scientificName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF1E1B4B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (species.commonName.isNotEmpty &&
                        species.commonName.toLowerCase() != 'common name') ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        species.commonName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _uploadPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (species.genus.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        species.genus,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _uploadPrimary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orchidPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.eco_outlined, color: _uploadPrimary, size: size * 0.43),
    );
  }
}

// ── Step 3: 3D Image Upload ───────────────────────────────────────────────────

class Upload3DImagesScreen extends StatefulWidget {
  const Upload3DImagesScreen({required this.orchid, super.key});

  final CatalogSpecies orchid;

  @override
  State<Upload3DImagesScreen> createState() => _Upload3DImagesScreenState();
}

class _Upload3DImagesScreenState extends State<Upload3DImagesScreen> {
  static const List<String> _angleLabels = <String>[
    'Front View',
    'Left Side',
    'Right Side',
    'Top View',
    'Back / Bottom',
  ];
  static const int _maxBytes = 5 * 1024 * 1024;

  final ImagePicker _imagePicker = ImagePicker();
  final List<ThreeDSlot?> _slots =
      List<ThreeDSlot?>.filled(5, null, growable: false);
  final Map<String, Uint8List> _previewCache = <String, Uint8List>{};
  bool _isPicking = false;
  bool _isSubmitting = false;

  Future<void> _pickSlot(int index) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 2048,
      );
      if (picked == null || !mounted) return;
      final Uint8List bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > _maxBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image exceeds 5 MB limit.')),
          );
        }
        return;
      }
      setState(() {
        _slots[index] = ThreeDSlot(
          path: picked.path,
          sizeBytes: bytes.lengthInBytes,
        );
        _previewCache[picked.path] = bytes;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open gallery.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _removeSlot(int index) {
    setState(() {
      if (_slots[index] != null) {
        _previewCache.remove(_slots[index]!.path);
        _slots[index] = null;
      }
    });
  }

  Future<void> _submit() async {
    final int count = _slots.where((ThreeDSlot? s) => s != null).length;
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least one photo before submitting.'),
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      for (int i = 0; i < _slots.length; i++) {
        final ThreeDSlot? slot = _slots[i];
        if (slot == null) continue;
        final String ts = DateTime.now().millisecondsSinceEpoch.toString();
        final String fileName =
            'orchid_3d_${widget.orchid.id ?? 0}_${i + 1}_$ts.jpg';
        final String storagePath = '3d_images/$fileName';
        final Uint8List bytes = _previewCache[slot.path]!;
        await Supabase.instance.client.storage
            .from('bloom-uploads')
            .uploadBinary(
              storagePath,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: <Widget>[
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                'Submitted!',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: Text(
            '$count 3D photo(s) submitted for "${widget.orchid.scientificName}". Thank you for your contribution!',
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _closeUploadFlow(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _uploadPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
            children: <Widget>[
              const _UploadFormHeader(title: 'Upload 3D Image'),
              const SizedBox(height: 18),
              // Selected orchid banner
              _uploadFormCard(
                Row(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: widget.orchid.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.orchid.imageUrl!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => _smallPlaceholder(),
                              errorWidget: (_, _, _) => _smallPlaceholder(),
                            )
                          : _smallPlaceholder(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.orchid.scientificName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF1E1B4B),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.orchid.commonName.isNotEmpty &&
                              widget.orchid.commonName.toLowerCase() !=
                                  'common name')
                            Text(
                              widget.orchid.commonName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _uploadPrimary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.view_in_ar_outlined,
                      color: _uploadPrimary,
                      size: 24,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Upload 5 Photos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap each slot to pick a photo from the required angle.',
                style: TextStyle(fontSize: 12, color: _mutedTextColor),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: 5,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, int i) => _buildSlot(i),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _uploadPrimary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFDDD6FE),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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

  Widget _buildSlot(int index) {
    final ThreeDSlot? slot = _slots[index];
    final bool hasImage = slot != null;
    final Uint8List? preview = hasImage ? _previewCache[slot.path] : null;

    return GestureDetector(
      onTap: _isPicking ? null : () => _pickSlot(index),
      child: Container(
        decoration: BoxDecoration(
          color: hasImage ? _surfaceColor : const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasImage ? _uploadPrimary : const Color(0xFFDDD6FE),
            width: hasImage ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hasImage ? _uploadPrimary : const Color(0xFFDDD6FE),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: hasImage ? Colors.white : _uploadPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: preview != null
                    ? Image.memory(preview, fit: BoxFit.cover)
                    : Container(
                        color: const Color(0xFFEDE9FE),
                        child: const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: _uploadPrimary,
                          size: 28,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Image ${index + 1}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                  ),
                  Text(
                    _angleLabels[index],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _uploadPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasImage
                        ? '${(slot.sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB'
                        : 'Tap to upload',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle:
                          hasImage ? FontStyle.normal : FontStyle.italic,
                      color: hasImage
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            if (hasImage)
              GestureDetector(
                onTap: () => _removeSlot(index),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFF7A2C22),
                    size: 22,
                  ),
                ),
              )
            else
              const Icon(
                Icons.cloud_upload_outlined,
                color: _uploadPrimary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _smallPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.eco_outlined, color: _uploadPrimary, size: 24),
    );
  }
}

class ThreeDSlot {
  ThreeDSlot({required this.path, required this.sizeBytes});
  final String path;
  final int sizeBytes;
}

class _ThreeDPhotoUploadDialog extends StatefulWidget {
  const _ThreeDPhotoUploadDialog({
    required this.imagePicker,
    required this.existing,
    required this.maxBytes,
  });

  final ImagePicker imagePicker;
  final List<UploadSpeciesImageDraft> existing;
  final int maxBytes;

  @override
  State<_ThreeDPhotoUploadDialog> createState() =>
      _ThreeDPhotoUploadDialogState();
}

class _ThreeDPhotoUploadDialogState extends State<_ThreeDPhotoUploadDialog> {
  static const List<String> _angleLabels = <String>[
    'Front View',
    'Left Side',
    'Right Side',
    'Top View',
    'Back / Bottom',
  ];

  bool _showUploadStep = false;
  final List<UploadSpeciesImageDraft?> _slots =
      List<UploadSpeciesImageDraft?>.filled(5, null, growable: false);
  final Map<String, Uint8List> _previewCache = <String, Uint8List>{};
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.existing.length && i < 5; i++) {
      _slots[i] = widget.existing[i];
    }
    for (final UploadSpeciesImageDraft img in widget.existing) {
      _loadPreview(img.path);
    }
  }

  Future<void> _loadPreview(String path) async {
    if (_previewCache.containsKey(path)) return;
    try {
      final Uint8List bytes = await XFile(path).readAsBytes();
      if (mounted) setState(() => _previewCache[path] = bytes);
    } catch (_) {}
  }

  Future<void> _pickSlot(int index) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final XFile? picked = await widget.imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 2048,
      );
      if (picked == null || !mounted) return;
      final Uint8List bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > widget.maxBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image exceeds 5 MB limit.')),
          );
        }
        return;
      }
      setState(() {
        _slots[index] = UploadSpeciesImageDraft(
          path: picked.path,
          sizeBytes: bytes.lengthInBytes,
          category: 'three_d_photo',
        );
        _previewCache[picked.path] = bytes;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open gallery.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _removeSlot(int index) {
    setState(() {
      if (_slots[index] != null) {
        _previewCache.remove(_slots[index]!.path);
        _slots[index] = null;
      }
    });
  }

  void _confirmAndClose() {
    final List<UploadSpeciesImageDraft> result =
        _slots.whereType<UploadSpeciesImageDraft>().toList(growable: false);
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: _appBackgroundColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _showUploadStep
              ? _buildUploadStep()
              : _buildRequirementsStep(),
        ),
      ),
    );
  }

  Widget _buildRequirementsStep() {
    return SingleChildScrollView(
      key: const ValueKey<String>('requirements'),
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.view_in_ar_outlined,
                  color: _uploadPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '3D Image Requirements',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _uploadPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 20,
                  color: Color(0xFF6B7280),
                ),
                onPressed: () => Navigator.of(context).pop(null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDD6FE), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'For 3D reconstruction, you need 5 photos taken from different angles of the same specimen.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4C1D95),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Required angles:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5B21B6),
                  ),
                ),
                const SizedBox(height: 6),
                ..._angleLabels.asMap().entries.map(
                  (MapEntry<int, String> e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: _uploadPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${e.key + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          e.value,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildTipRow(
            Icons.wb_sunny_outlined,
            'Use consistent lighting across all shots',
          ),
          const SizedBox(height: 6),
          _buildTipRow(
            Icons.center_focus_strong_outlined,
            'Keep the specimen centered in each frame',
          ),
          const SizedBox(height: 6),
          _buildTipRow(
            Icons.crop_free_outlined,
            'Use a plain / neutral background if possible',
          ),
          const SizedBox(height: 6),
          _buildTipRow(
            Icons.photo_size_select_large_outlined,
            'Max 5 MB per photo · JPG or PNG recommended',
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _showUploadStep = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _uploadPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Proceed',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 15, color: _uploadPrimary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadStep() {
    return Column(
      key: const ValueKey<String>('upload'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
          child: Row(
            children: <Widget>[
              GestureDetector(
                onTap: () => setState(() => _showUploadStep = false),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: _uploadPrimary,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Upload 3D Photo Series',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _uploadPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 20,
                  color: Color(0xFF6B7280),
                ),
                onPressed: () => Navigator.of(context).pop(null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 6, 22, 0),
          child: Text(
            'Upload 5 photos from the required angles below.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.50,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < 5; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildImageSlot(i),
                  ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmAndClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: _uploadPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Okay',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSlot(int index) {
    final UploadSpeciesImageDraft? img = _slots[index];
    final bool hasImage = img != null;
    final Uint8List? preview = hasImage ? _previewCache[img.path] : null;

    return GestureDetector(
      onTap: _isPicking ? null : () => _pickSlot(index),
      child: Container(
        decoration: BoxDecoration(
          color: hasImage ? _surfaceColor : const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage ? _uploadPrimary : const Color(0xFFDDD6FE),
            width: hasImage ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: <Widget>[
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hasImage ? _uploadPrimary : const Color(0xFFDDD6FE),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: hasImage ? Colors.white : _uploadPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: preview != null
                    ? Image.memory(preview, fit: BoxFit.cover)
                    : Container(
                        color: const Color(0xFFEDE9FE),
                        child: const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: _uploadPrimary,
                          size: 24,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Image ${index + 1} — ${_angleLabels[index]}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasImage
                        ? '${(img.sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB'
                        : 'Tap to upload',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle:
                          hasImage ? FontStyle.normal : FontStyle.italic,
                      color: hasImage
                          ? const Color(0xFF6B7280)
                          : _uploadPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (hasImage)
              GestureDetector(
                onTap: () => _removeSlot(index),
                child: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFF7A2C22),
                  size: 20,
                ),
              )
            else
              const Icon(
                Icons.cloud_upload_outlined,
                color: _uploadPrimary,
                size: 20,
              ),
          ],
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
        child: Icon(Icons.image_outlined, color: _mutedTextColor),
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
            child: Icon(Icons.broken_image_outlined, color: _mutedTextColor),
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

  Future<void> _confirmDeleteDraft(UploadSpeciesFlowData draft) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Draft',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to delete this draft? This action cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await UploadSpeciesDraftStore.deleteDraftData(draft);
    if (!mounted) return;
    _reloadDrafts();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Draft deleted.')));
  }

  void _showSubmitPreview(
    BuildContext context,
    UploadSpeciesFlowData draft,
    String draftKey,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DraftSubmitPreviewSheet(
        draft: draft,
        onConfirmSubmit: () => _submitDraft(draft, draftKey),
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
                          return Center(
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

                            final bool isComplete =
                                draft.scientificName.trim().isNotEmpty &&
                                draft.observationDate.trim().isNotEmpty &&
                                draft.location.trim().isNotEmpty &&
                                draft.latitude.trim().isNotEmpty &&
                                draft.longitude.trim().isNotEmpty &&
                                draft.headResearcher.trim().isNotEmpty;

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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  // ── Top info row ────────────────────────
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      14,
                                      14,
                                      10,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        _buildDraftPreview(draft),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                draftTitle,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: _textColor,
                                                  fontStyle:
                                                      draft.scientificName
                                                          .trim()
                                                          .isEmpty
                                                      ? FontStyle.italic
                                                      : FontStyle.normal,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                'Updated ${_formatDraftTimestamp(draft.updatedAt)}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: _mutedTextColor,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${draft.images.length} image(s) · ${draft.contributors.where((UploadContributorDraft c) => c.name.trim().isNotEmpty).length} contributor(s)',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: _mutedTextColor,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isComplete
                                                      ? const Color(0xFFE6F4EA)
                                                      : const Color(0xFFFFF3E0),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  isComplete
                                                      ? '✓ Ready to submit'
                                                      : '⚠ Missing required fields',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: isComplete
                                                        ? const Color(
                                                            0xFF2E7D32,
                                                          )
                                                        : const Color(
                                                            0xFFE65100,
                                                          ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // ── Divider ─────────────────────────────
                                  Divider(height: 1, color: _lineColor),
                                  // ── Action buttons ───────────────────────
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      8,
                                      12,
                                      12,
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _editDraft(draft),
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 16,
                                            ),
                                            label: const Text('Edit'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: _primaryColor,
                                              side: BorderSide(
                                                color: _primaryColor,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: isSubmittingCurrentDraft
                                                ? null
                                                : () => _showSubmitPreview(
                                                    context,
                                                    draft,
                                                    currentDraftKey,
                                                  ),
                                            icon: isSubmittingCurrentDraft
                                                ? const SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.send_rounded,
                                                    size: 16,
                                                  ),
                                            label: Text(
                                              isSubmittingCurrentDraft
                                                  ? 'Submitting...'
                                                  : 'Submit',
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _primaryColor,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () =>
                                              _confirmDeleteDraft(draft),
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                          ),
                                          color: Colors.red,
                                          style: IconButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFFFFEBEE,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
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

class _DraftSubmitPreviewSheet extends StatelessWidget {
  const _DraftSubmitPreviewSheet({
    required this.draft,
    required this.onConfirmSubmit,
  });
  final UploadSpeciesFlowData draft;
  final VoidCallback onConfirmSubmit;

  Widget _section(String title, List<Widget> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF5F6368),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }

  Widget _row(
    String label,
    String value, {
    bool required = false,
    bool missing = false,
  }) {
    final bool empty = value.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF80868B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: missing
                ? Row(
                    children: <Widget>[
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: Color(0xFFE65100),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Required — not filled',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE65100),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : empty
                ? const Text(
                    '—',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFBDBDBD),
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Text(
                    value.trim(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF202124),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasName = draft.scientificName.trim().isNotEmpty;
    final bool hasDate = draft.observationDate.trim().isNotEmpty;
    final bool hasLocation = draft.location.trim().isNotEmpty;
    final bool hasCoords =
        draft.latitude.trim().isNotEmpty && draft.longitude.trim().isNotEmpty;
    final bool hasHeadResearcher = draft.headResearcher.trim().isNotEmpty;
    final bool isReady =
        hasName && hasDate && hasLocation && hasCoords && hasHeadResearcher;

    final int contribCount = draft.contributors
        .where((UploadContributorDraft c) => c.name.trim().isNotEmpty)
        .length;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ScrollController sc) => Column(
        children: <Widget>[
          // Handle
          const SizedBox(height: 10),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDADCE0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Review Before Submitting',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF202124),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  color: const Color(0xFF5F6368),
                ),
              ],
            ),
          ),
          if (!isReady)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: const Row(
                children: <Widget>[
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFE65100),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Some required fields are missing. Fill them before submitting.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              controller: sc,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: <Widget>[
                _section('SPECIES INFORMATION', <Widget>[
                  _row(
                    'Scientific Name',
                    draft.scientificName,
                    required: true,
                    missing: !hasName,
                  ),
                  _row('Common Name', draft.commonName),
                  _row('Family', draft.family),
                  _row('Genus', draft.genus),
                  _row('ID Confidence', draft.identificationConfidence),
                  _row(
                    'Endemic to PH',
                    draft.endemicToPhilippines ? 'Yes' : 'No',
                  ),
                ]),
                _section('SIGHTING & LOCATION', <Widget>[
                  _row(
                    'Date of Observation',
                    draft.observationDate,
                    required: true,
                    missing: !hasDate,
                  ),
                  _row('Time', draft.observationTime),
                  _row(
                    'Location',
                    draft.location,
                    required: true,
                    missing: !hasLocation,
                  ),
                  _row(
                    'Coordinates',
                    hasCoords ? '${draft.latitude}, ${draft.longitude}' : '',
                    required: true,
                    missing: !hasCoords,
                  ),
                  _row('Province', draft.province),
                  _row('Municipality', draft.municipality),
                  _row('Mountain', draft.mountain),
                  _row('Altitude', draft.altitude),
                  _row('Elevation', draft.elevation),
                  _row('Specific Site', draft.specificSite),
                  _row('Habitat Type', draft.habitatType),
                  _row('Micro-habitat', draft.microHabitat),
                  _row('Growth Substrate', draft.growthSubstrate),
                  _row('Host Tree Species', draft.hostTreeSpecies),
                  _row('Host Tree Diameter', draft.hostTreeDiameter),
                  _row('Canopy Cover', draft.canopyCover),
                  _row('Light Exposure', draft.lightExposure),
                  _row('Soil Type', draft.soilType),
                  _row('Nearby Water Source', draft.nearbyWaterSource),
                  _row('Observation Type', draft.observationType),
                  _row('Collection Method', draft.collectionMethod),
                  _row(
                    'Voucher Specimen',
                    draft.voucherSpecimenCollected ? 'Yes' : 'No',
                  ),
                  _row('Number Located', draft.numberLocated),
                ]),
                _section('PLANT STRUCTURE', <Widget>[
                  _row('Plant Height', draft.plantHeight),
                  _row('Pseudobulb Present', draft.pseudobulbPresent),
                  _row('Stem Length', draft.stemLength),
                  _row('Root Length', draft.rootLength),
                ]),
                _section('LEAVES', <Widget>[
                  _row('Leaf Type', draft.leafType),
                  _row('Leaf Shape', draft.leafShape),
                  _row('Number of Leaves', draft.numberOfLeaves),
                  _row('Leaf Length', draft.leafLength),
                  _row('Leaf Width', draft.leafWidth),
                  _row('Leaf Texture', draft.leafTexture),
                  _row('Leaf Arrangement', draft.leafArrangement),
                ]),
                _section('FLOWERS', <Widget>[
                  _row('Flower Color', draft.flowerColor),
                  _row('Number of Flowers', draft.numberOfFlowers),
                  _row('Flower Diameter', draft.flowerDiameter),
                  _row('Inflorescence Type', draft.inflorescenceType),
                  _row('Petal Characteristics', draft.petalCharacteristics),
                  _row('Sepal Characteristics', draft.sepalCharacteristics),
                  _row('Labellum / Lip', draft.labellumDescription),
                  _row('Fragrance', draft.fragrance),
                  _row('Blooming Stage', draft.bloomingStage),
                  _row('Flowering From', draft.floweringFromMonth),
                  _row('Flowering To', draft.floweringToMonth),
                ]),
                _section('FRUITS & SEEDS', <Widget>[
                  _row('Fruit Present', draft.fruitPresent),
                  _row('Fruit Type', draft.fruitType),
                  _row('Seed Capsule Condition', draft.seedCapsuleCondition),
                ]),
                _section('ECOLOGICAL DATA', <Widget>[
                  _row('Life Stage', draft.lifeStage),
                  _row('Phenology', draft.phenology),
                  _row('Population Status', draft.populationStatus),
                  _row('Threat Level', draft.threatLevel),
                  _row('Threat Type', draft.threatType),
                  _row('Rarity', draft.rarity),
                  _row(
                    'Ethnobotanical Importance',
                    draft.ethnobotanicalImportance,
                  ),
                  _row('Cultural Importance', draft.culturalImportance),
                  _row('Aesthetic Appeal', draft.aestheticAppeal),
                  _row('Cultivation', draft.cultivation),
                ]),
                _section('IMAGES & CONTRIBUTORS', <Widget>[
                  _row('Images', '${draft.images.length} image(s)'),
                  _row(
                    'Head Researcher',
                    draft.headResearcher,
                    required: true,
                    missing: !hasHeadResearcher,
                  ),
                  _row('Team Members', draft.teamMembers),
                  _row('Institution', draft.institution),
                  _row('Contributors', '$contribCount contributor(s)'),
                ]),
                _section('NOTES & REMARKS', <Widget>[
                  _row('Researcher Notes', draft.researcherNotes),
                  _row('Unusual Observations', draft.unusualObservations),
                ]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isReady
                    ? () {
                        Navigator.pop(context);
                        onConfirmSubmit();
                      }
                    : null,
                icon: const Icon(Icons.send_rounded),
                label: Text(
                  isReady ? 'Submit Now' : 'Fill Required Fields First',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
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

  Future<List<SubmissionStatusItem>> _loadSubmissions() async {
    try {
      final SupabaseClient supabase = Supabase.instance.client;
      final String userEmail = supabase.auth.currentUser?.email ?? '';
      final List<dynamic> data = await supabase
          .from('species_sightings')
          .select(
            'sighting_id, scientific_name, review_status, created_at, whole_plant_photo_path',
          )
          .eq('researcher_email', userEmail)
          .order('created_at', ascending: false);

      final List<SubmissionStatusItem> items = data
          .whereType<Map>()
          .map(
            (Map row) => SubmissionStatusItem.fromJson(<String, dynamic>{
              'scientificName': row['scientific_name'],
              'status': row['review_status'],
              'uploadedAt': row['created_at'],
              'imageUrl': row['whole_plant_photo_path'] ?? '',
            }),
          )
          .toList();

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
              const _UploadFormHeader(title: 'Submissions'),
              const SizedBox(height: 16),
              Text(
                'Submissions',
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
                          return Center(
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
                  const _UploadFormHeader(title: 'Uploaded Orchids'),
                  SizedBox(height: 16 * scale),
                  Text(
                    'Uploaded Orchids',
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
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: 78,
            height: 78,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(
              width: 78,
              height: 78,
              color: _surfaceTintColor,
              alignment: Alignment.center,
              child: const Icon(Icons.image_outlined, size: 30, color: _primaryColor),
            ),
            errorWidget: (_, _, _) => Container(
              width: 78,
              height: 78,
              color: _surfaceTintColor,
              alignment: Alignment.center,
              child: const Icon(Icons.image_outlined, size: 30, color: _primaryColor),
            ),
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  commonName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Uploaded: $uploadedDate',
                  style: TextStyle(
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
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 78,
                      height: 78,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        width: 78,
                        height: 78,
                        color: const Color(0xFFF1F4F7),
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_outlined, size: 30, color: _primaryColor),
                      ),
                      errorWidget: (_, _, _) => Container(
                        width: 78,
                        height: 78,
                        color: const Color(0xFFF1F4F7),
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined, size: 30, color: _primaryColor),
                      ),
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
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Uploaded: $uploadedDate',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: _mutedTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
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

void _closeUploadFlow(BuildContext context) {
  final NavigatorState navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.popUntil((Route<dynamic> route) => route.isFirst);
  }
}

const TextStyle _uploadSectionTitleStyle = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w700,
  color: _uploadPrimary,
  letterSpacing: 0.3,
);

TextStyle get _uploadFieldLabelStyle => TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w500,
  color: _kIsDark ? const Color(0xFFBCC4CF) : const Color(0xFF374151),
);

TextStyle get _uploadInputTextStyle =>
    TextStyle(fontSize: 14, color: _textColor);

const TextStyle _uploadHintTextStyle = TextStyle(
  fontSize: 14,
  color: Color(0xFF9CA3AF),
);

Widget _uploadFieldLabelWithTooltip(String label, String tooltip) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: <Widget>[
      Text(label, style: _uploadFieldLabelStyle),
      const SizedBox(width: 4),
      Tooltip(
        message: tooltip,
        triggerMode: TooltipTriggerMode.tap,
        preferBelow: true,
        showDuration: const Duration(seconds: 4),
        child: const Icon(
          Icons.info_outline,
          size: 14,
          color: Color(0xFF9CA3AF),
        ),
      ),
    ],
  );
}

InputDecoration _uploadInputDecoration({String? hintText}) {
  return InputDecoration(
    isDense: true,
    hintText: hintText,
    hintStyle: _uploadHintTextStyle,
    filled: true,
    fillColor: _surfaceColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: _uploadBorderColor, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: _uploadPrimary, width: 1.8),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Color(0xFFB84040), width: 1),
    ),
  );
}

ButtonStyle _uploadActionButtonStyle({bool fullWidth = false}) {
  return OutlinedButton.styleFrom(
    foregroundColor: _uploadPrimary,
    side: BorderSide(color: _uploadPrimary, width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    minimumSize: fullWidth
        ? const Size(double.infinity, 50)
        : const Size(130, 46),
  );
}

String _generateEntryId() {
  final DateTime now = DateTime.now();
  final String date =
      '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  final int rand = (now.microsecondsSinceEpoch % 10000).abs();
  return 'ORD-$date-${rand.toString().padLeft(4, '0')}';
}

/// Card-like container wrapping a single form section.
Widget _uploadFormCard(Widget child) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    decoration: BoxDecoration(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _uploadBorderColor, width: 1),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: _kIsDark ? const Color(0x1A7C3AED) : const Color(0x0A7C3AED),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

/// Light-purple sub-section card used inside form cards.
Widget _uploadSubCard({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
    decoration: BoxDecoration(
      color: _uploadSubCardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _uploadBorderColor, width: 1),
    ),
    child: child,
  );
}

/// Full-width gradient Next button.
Widget _uploadNextButton({
  required VoidCallback? onPressed,
  String label = 'Continue',
  IconData trailingIcon = Icons.arrow_forward_rounded,
}) {
  final bool enabled = onPressed != null;
  return Material(
    borderRadius: BorderRadius.circular(12),
    color: Colors.transparent,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: enabled
                ? const <Color>[_uploadPrimary, _uploadPrimaryDark]
                : const <Color>[Color(0xFF9CA3AF), Color(0xFF9CA3AF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              Icon(trailingIcon, size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Outlined Save Draft button.
Widget _uploadSaveDraftButton({
  required VoidCallback? onPressed,
  String label = 'Save as Draft',
}) {
  return OutlinedButton.icon(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: _uploadPrimary,
      side: BorderSide(color: _uploadPrimary, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      minimumSize: const Size(double.infinity, 50),
      padding: const EdgeInsets.symmetric(vertical: 12),
    ),
    icon: const Icon(Icons.save_outlined, size: 18),
    label: Text(
      label,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
  );
}

class _UploadFormHeader extends StatelessWidget {
  const _UploadFormHeader({
    required this.title,
    this.sectionTitle = '',
    this.step = 0,
    this.totalSteps = 5,
    this.stepIcon = Icons.eco_outlined,
    this.entryId = '',
  });

  final String title;
  final String sectionTitle;
  final int step;
  final int totalSteps;
  final IconData stepIcon;
  final String entryId;

  @override
  Widget build(BuildContext context) {
    final NavigatorState navigator = Navigator.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[_uploadPrimary, _uploadPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x347C3AED),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          // Back / close row
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => navigator.maybePop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  tooltip: 'Back',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _closeUploadFlow(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 22,
                  ),
                  tooltip: 'Close',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Content area
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Orchid Database',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    if (entryId.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              'Entry ID',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.7),
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(
                              entryId.trim(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'monospace',
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Icon(stepIcon, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sectionTitle.isNotEmpty ? sectionTitle : title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (step > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$step / $totalSteps',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                if (step > 0) ...<Widget>[
                  const SizedBox(height: 12),
                  Row(
                    children: List<Widget>.generate(totalSteps, (int i) {
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(
                            right: i < totalSteps - 1 ? 4 : 0,
                          ),
                          decoration: BoxDecoration(
                            color: i < step
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
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
              style: TextStyle(
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
                style: TextStyle(
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
                            style: TextStyle(
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
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

// ── Trail constants ───────────────────────────────────────────────────────
const List<LatLng> _kBusaTrail = <LatLng>[
  LatLng(6.0705, 124.7412),
  LatLng(6.0758, 124.7350),
  LatLng(6.0821, 124.7284),
  LatLng(6.0903, 124.7201),
  LatLng(6.0987, 124.7128),
  LatLng(6.1055, 124.7049),
  LatLng(6.1092, 124.6858),
];

// Shared, never-rebuilt trail polyline layer used in catalog maps (purple, 7/4).
final PolylineLayer _kTrailPolylineLayer = PolylineLayer(
  polylines: <Polyline>[
    Polyline(points: _kBusaTrail, color: Colors.black26, strokeWidth: 7),
    Polyline(
      points: _kBusaTrail,
      color: const Color(0xFF7C3AED),
      strokeWidth: 4,
    ),
  ],
);

// Trail layer for the main map (blue trail style).
final PolylineLayer _kMainMapTrailPolylineLayer = PolylineLayer(
  polylines: <Polyline>[
    Polyline(points: _kBusaTrail, color: Colors.black26, strokeWidth: 9),
    Polyline(
      points: _kBusaTrail,
      color: const Color(0xFF1A73E8),
      strokeWidth: 5,
    ),
  ],
);

enum _MapLayer { street, topo, satellite }

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _cardExpanded = true;
  Position? _currentPosition;
  final ValueNotifier<_MapLayer> _activeLayerNotifier = ValueNotifier(
    _MapLayer.street,
  );
  final ValueNotifier<double> _mapRotationNotifier = ValueNotifier(0.0);

  static const LatLng _kCenter = LatLng(6.090, 124.713);
  static const double _kInitialZoom = 13;

  String _tileUrlFor(_MapLayer layer) {
    switch (layer) {
      case _MapLayer.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/'
            'World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case _MapLayer.topo:
        return 'https://a.tile.opentopomap.org/{z}/{x}/{y}.png';
      case _MapLayer.street:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _activeLayerNotifier.dispose();
    _mapRotationNotifier.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (!mounted) return;
      setState(() => _currentPosition = pos);
      _mapController.move(LatLng(pos.latitude, pos.longitude), 15);
    } catch (_) {}
  }

  void _zoomIn() => _mapController.move(
    _mapController.camera.center,
    _mapController.camera.zoom + 1,
  );

  void _zoomOut() => _mapController.move(
    _mapController.camera.center,
    _mapController.camera.zoom - 1,
  );

  void _flyToCurrentLocation() {
    if (_currentPosition == null) return;
    _mapController.move(
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      15,
    );
  }

  void _resetNorth() {
    _mapController.rotate(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // ── Full-screen flutter_map ──────────────────────────────
          Positioned.fill(
            child: RepaintBoundary(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _kCenter,
                  initialZoom: _kInitialZoom,
                  minZoom: 8,
                  maxZoom: 19,
                  onMapEvent: (MapEvent event) {
                    final double r = event.camera.rotation;
                    if ((r - _mapRotationNotifier.value).abs() >= 1.0) {
                      _mapRotationNotifier.value = r;
                    }
                  },
                ),
                children: <Widget>[
                  ValueListenableBuilder<_MapLayer>(
                    valueListenable: _activeLayerNotifier,
                    builder: (_, layer, _) => TileLayer(
                      key: ValueKey(layer),
                      urlTemplate: _tileUrlFor(layer),
                      userAgentPackageName: 'com.example.flutter_application_1',
                      maxNativeZoom: 18,
                      keepBuffer: 4,
                      evictErrorTileStrategy: EvictErrorTileStrategy.notVisible,
                    ),
                  ),
                  _kMainMapTrailPolylineLayer,
                  if (_currentPosition != null)
                    MarkerLayer(
                      markers: <Marker>[
                        Marker(
                          point: LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          width: 24,
                          height: 24,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF1A73E8),
                              shape: BoxShape.circle,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Color(0x661A73E8),
                                  blurRadius: 8,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.circle,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // ── Zoom + locate + compass buttons (right side) ─────────
          Positioned(
            right: 12,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 52),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Compass — rotates with the map, tap to reset north
                    GestureDetector(
                      onTap: _resetNorth,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Color(0x26000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: ValueListenableBuilder<double>(
                          valueListenable: _mapRotationNotifier,
                          builder: (_, rotation, child) => Transform.rotate(
                            angle: -rotation * (3.141592653589793 / 180),
                            child: child,
                          ),
                          child: CustomPaint(
                            size: const Size(22, 28),
                            painter: _CompassNeedlePainter(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _mapIconButton(Icons.add, _zoomIn),
                    const SizedBox(height: 4),
                    _mapIconButton(Icons.remove, _zoomOut),
                    const SizedBox(height: 12),
                    _mapIconButton(
                      Icons.my_location_rounded,
                      _flyToCurrentLocation,
                      color: const Color(0xFF1A73E8),
                    ),
                    const SizedBox(height: 12),
                    _mapIconButton(Icons.layers_rounded, () {
                      final int idx = _MapLayer.values.indexOf(
                        _activeLayerNotifier.value,
                      );
                      _activeLayerNotifier.value =
                          _MapLayer.values[(idx + 1) % _MapLayer.values.length];
                    }),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom info card (draggable) ─────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onVerticalDragEnd: (DragEndDetails details) {
                final double v = details.primaryVelocity ?? 0;
                if (v > 150) setState(() => _cardExpanded = false);
                if (v < -150) setState(() => _cardExpanded = true);
              },
              onTap: () {
                if (!_cardExpanded) setState(() => _cardExpanded = true);
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Drag handle — always visible
                    const SizedBox(height: 10),
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDADCE0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Title row — always visible
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: <Widget>[
                          const Expanded(
                            child: Text(
                              'Mt. Busa Trail',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF202124),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F0FE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Trail',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A73E8),
                              ),
                            ),
                          ),
                          if (!_cardExpanded) ...<Widget>[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.keyboard_arrow_up_rounded,
                              color: Color(0xFF80868B),
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Expandable content
                    AnimatedSize(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeInOut,
                      child: _cardExpanded
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const SizedBox(height: 2),
                                  const Text(
                                    'South Cotabato / Sarangani Province',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF80868B),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            )
                          : const SizedBox(height: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapIconButton(IconData icon, VoidCallback onTap, {Color? color}) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 20, color: color ?? const Color(0xFF5F6368)),
        ),
      ),
    );
  }
}

class _CompassNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // North half — red, points up
    final ui.Path north = ui.Path()
      ..moveTo(cx, 0)
      ..lineTo(cx + cx * 0.55, cy)
      ..lineTo(cx, cy - cy * 0.15)
      ..lineTo(cx - cx * 0.55, cy)
      ..close();
    canvas.drawPath(north, Paint()..color = const Color(0xFFE53935));

    // South half — grey, points down
    final ui.Path south = ui.Path()
      ..moveTo(cx, size.height)
      ..lineTo(cx + cx * 0.55, cy)
      ..lineTo(cx, cy + cy * 0.15)
      ..lineTo(cx - cx * 0.55, cy)
      ..close();
    canvas.drawPath(south, Paint()..color = const Color(0xFF9E9E9E));

    // Centre dot
    canvas.drawCircle(
      Offset(cx, cy),
      2.5,
      Paint()..color = const Color(0xFF212121),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NotificationController extends ChangeNotifier {
  static const String _prefsKey = 'notif_read_ids_v1';

  List<AppNotification> _raw = <AppNotification>[];
  Set<String> _readIds = <String>{};
  bool _isLoading = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  List<AppNotification> get notifications => _raw;
  int get unreadCount => _raw.where((AppNotification n) => !n.read).length;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    _notify();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _readIds = (prefs.getStringList(_prefsKey) ?? <String>[]).toSet();

    try {
      final SupabaseClient supabase = Supabase.instance.client;
      final String userEmail = supabase.auth.currentUser?.email ?? '';
      final List<dynamic> data = await supabase
          .from('species_sightings')
          .select('sighting_id, scientific_name, review_status, created_at')
          .eq('researcher_email', userEmail)
          .order('created_at', ascending: false);

      final List<AppNotification> notifs = <AppNotification>[];
      for (int i = 0; i < data.length; i++) {
        final Map<String, dynamic> item = Map<String, dynamic>.from(
          data[i] as Map,
        );
        final String status = (item['review_status'] ?? '').toString().trim();
        final String scientificName = (item['scientific_name'] ?? '')
            .toString()
            .trim();
        final DateTime uploadedAt =
            DateTime.tryParse((item['created_at'] ?? '').toString()) ??
            DateTime.now();
        final String id = (item['sighting_id'] ?? i + 1).toString();
        notifs.add(
          AppNotification(
            id: id,
            type: status.isEmpty ? 'pending' : status,
            message: _messageForSubmission(status, scientificName),
            timestamp: _bucketForDate(uploadedAt),
            read: _readIds.contains(id),
          ),
        );
      }
      _raw = notifs.isNotEmpty ? notifs : _applyReadIds(mockNotifications);
    } catch (_) {
      _raw = _applyReadIds(mockNotifications);
    }

    _isLoading = false;
    _notify();
  }

  List<AppNotification> _applyReadIds(List<AppNotification> source) {
    return source
        .map(
          (AppNotification n) => _readIds.contains(n.id)
              ? AppNotification(
                  id: n.id,
                  type: n.type,
                  message: n.message,
                  timestamp: n.timestamp,
                  read: true,
                )
              : n,
        )
        .toList(growable: false);
  }

  Future<void> markAsRead(String id) async {
    if (_readIds.contains(id)) return;
    _readIds.add(id);
    _raw = _raw
        .map(
          (AppNotification n) => n.id == id
              ? AppNotification(
                  id: n.id,
                  type: n.type,
                  message: n.message,
                  timestamp: n.timestamp,
                  read: true,
                )
              : n,
        )
        .toList(growable: false);
    _notify();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _readIds.toList());
  }

  Future<void> markAllAsRead() async {
    for (final AppNotification n in _raw) {
      _readIds.add(n.id);
    }
    _raw = _raw
        .map(
          (AppNotification n) => AppNotification(
            id: n.id,
            type: n.type,
            message: n.message,
            timestamp: n.timestamp,
            read: true,
          ),
        )
        .toList(growable: false);
    _notify();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _readIds.toList());
  }

  String _bucketForDate(DateTime value) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime date = DateTime(value.year, value.month, value.day);
    final int diff = today.difference(date).inDays;
    if (diff <= 0) return 'Today';
    if (diff <= 7) return 'Past 7 days';
    return 'Earlier';
  }

  String _messageForSubmission(String status, String scientificName) {
    final String safeName = scientificName.isEmpty
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
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({required this.controller, super.key});

  final NotificationController controller;

  Widget _buildSection(
    BuildContext context,
    String title,
    List<AppNotification> items,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            color: _mutedTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (AppNotification item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => controller.markAsRead(item.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: item.read
                      ? _surfaceColor
                      : _kIsDark
                      ? const Color(0xFF1E2D3D)
                      : const Color(0xFFF0F6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: item.read ? _lineColor : _primarySoftColor,
                  ),
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
                    children: <Widget>[
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
                          children: <Widget>[
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
                      if (!item.read)
                        const Padding(
                          padding: EdgeInsets.only(left: 8, top: 2),
                          child: Text(
                            'Tap to read',
                            style: TextStyle(
                              fontSize: 10,
                              color: _primarySoftColor,
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _appBackgroundColor,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (BuildContext context, _) {
            final List<AppNotification> notifications =
                controller.notifications;
            final int unreadCount = controller.unreadCount;

            final List<AppNotification> today = notifications
                .where((AppNotification n) => n.timestamp == 'Today')
                .toList(growable: false);
            final List<AppNotification> recent = notifications
                .where((AppNotification n) => n.timestamp == 'Past 7 days')
                .toList(growable: false);
            final List<AppNotification> older = notifications
                .where((AppNotification n) => n.timestamp == 'Earlier')
                .toList(growable: false);

            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Spacer(),
                      Material(
                        color: Colors.transparent,
                        child: InkResponse(
                          onTap: () => Navigator.of(context).pop(),
                          radius: 24,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _surfaceColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: _lineColor),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: _primaryColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
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
                              unreadCount == 0
                                  ? 'All caught up!'
                                  : '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
                              style: TextStyle(
                                color: _mutedTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (unreadCount > 0)
                        TextButton(
                          onPressed: controller.markAllAsRead,
                          child: const Text(
                            'Mark all read',
                            style: TextStyle(
                              fontSize: 13,
                              color: _primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(height: 1, color: _lineColor),
                  if (controller.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  const SizedBox(height: 16),
                  _buildSection(context, 'Today', today),
                  if (today.isNotEmpty) const SizedBox(height: 6),
                  _buildSection(context, 'Past 7 days', recent),
                  if (recent.isNotEmpty) const SizedBox(height: 6),
                  _buildSection(context, 'Earlier', older),
                  if (notifications.isEmpty && !controller.isLoading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text(
                          'No notifications yet.',
                          style: TextStyle(
                            color: _mutedTextColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
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

class AuthApiException implements Exception {
  AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppAuthController extends ChangeNotifier {
  AppAuthController();

  AppUser? _user;
  bool _isInitializing = true;
  bool _isDarkMode = false;

  AppUser? get user => _user;
  bool get isInitializing => _isInitializing;
  bool get isDarkMode => _isDarkMode;

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> initialize() async {
    // Initialize Supabase here (not in main) so runApp() isn't blocked by the
    // network handshake, which caused the 10-13 s native white screen.
    // SharedPreferences can start in parallel while Supabase connects.
    final results = await Future.wait(<Future<Object?>>[
      Supabase.initialize(url: _kSupabaseUrl, anonKey: _kSupabaseAnonKey)
          .then<Object?>((v) => v)
          .timeout(const Duration(seconds: 12), onTimeout: () => null),
      SharedPreferences.getInstance()
          .then<Object?>((v) => v)
          .timeout(const Duration(seconds: 5), onTimeout: () => null),
    ]);

    final SharedPreferences prefs = results[1] as SharedPreferences;
    _isDarkMode = prefs.getBool('darkMode') ?? false;

    final User? currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      _user = AppUser.fromSupabaseUser(currentUser);
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

    final SupabaseClient supabase = Supabase.instance.client;
    final bool isSignup = name != null && name.trim().isNotEmpty;

    try {
      if (isSignup) {
        final String trimmedName = name.trim();
        final AuthResponse response = await supabase.auth.signUp(
          email: normalizedEmail,
          password: password,
          data: <String, dynamic>{
            'name': trimmedName,
            'username': _defaultUsername(
              email: normalizedEmail,
              name: trimmedName,
            ),
            'location': 'Mt. Busa',
          },
        );
        if (response.user == null) {
          throw AuthApiException('Sign up failed. Please try again.');
        }
        _user = AppUser.fromSupabaseUser(response.user!);
      } else {
        final AuthResponse response = await supabase.auth.signInWithPassword(
          email: normalizedEmail,
          password: password,
        );
        if (response.user == null) {
          throw AuthApiException('Invalid email or password.');
        }
        _user = AppUser.fromSupabaseUser(response.user!);
      }
    } on AuthApiException {
      rethrow;
    } catch (e) {
      final String msg = e.toString().toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid_credentials')) {
        throw AuthApiException('Invalid email or password.');
      }
      if (msg.contains('user already registered')) {
        throw AuthApiException(
          'An account with this email already exists. Please sign in.',
        );
      }
      throw AuthApiException(
        'Authentication failed. Check your connection and try again.',
      );
    }

    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String username,
    required String location,
    String? profilePhotoBase64,
  }) async {
    final AppUser? current = _user;
    if (current == null) throw AuthApiException('No active user session.');

    final String resolvedName = name.trim();
    final String resolvedUsername = username.trim().replaceFirst(
      RegExp(r'^@+'),
      '',
    );
    final String resolvedLocation = location.trim();

    if (resolvedName.isEmpty || resolvedUsername.isEmpty) {
      throw AuthApiException('Name and username are required.');
    }

    try {
      final UserResponse response = await Supabase.instance.client.auth
          .updateUser(
            UserAttributes(
              data: <String, dynamic>{
                'name': resolvedName,
                'username': resolvedUsername,
                'location': resolvedLocation,
                'profilePhotoBase64': profilePhotoBase64 ?? current.profilePhotoBase64,
              },
            ),
          );
      final User? updatedUser = response.user;
      _user = updatedUser != null
          ? AppUser.fromSupabaseUser(updatedUser)
          : current.copyWith(
              name: resolvedName,
              username: resolvedUsername,
              location: resolvedLocation,
              profilePhotoBase64:
                  profilePhotoBase64 ?? current.profilePhotoBase64,
            );
    } catch (_) {
      _user = current.copyWith(
        name: resolvedName,
        username: resolvedUsername,
        location: resolvedLocation,
        profilePhotoBase64: profilePhotoBase64 ?? current.profilePhotoBase64,
      );
    }

    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // signOut can fail when the server returns a non-JSON response (e.g.
      // HTML error page on network issues). Clear the local session anyway.
    }
    _user = null;
    notifyListeners();
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

  factory AppUser.fromSupabaseUser(User user) {
    final Map<String, dynamic> meta = Map<String, dynamic>.from(
      user.userMetadata ?? <String, dynamic>{},
    );
    final String name = (meta['name'] ?? user.email?.split('@').first ?? '')
        .toString();
    return AppUser(
      name: name,
      email: user.email ?? '',
      username: (meta['username'] ?? '').toString(),
      location: (meta['location'] ?? 'Mt. Busa').toString(),
      profilePhotoBase64: (meta['profilePhotoBase64'] ?? '').toString(),
    );
  }

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
    this.localName,
  });

  final int? id;
  final String scientificName;
  final String commonName;
  final String genus;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String? localName;
}

class CatalogGroup {
  const CatalogGroup({required this.title, required this.species});

  final String title;
  final List<CatalogSpecies> species;
}

const List<Orchid> mockOrchids = <Orchid>[
  Orchid(
    id: '1',
    scientificName: 'Paphiopedilum urbanianum',
    commonName: "Urban's Slipper Orchid",
    image: '🌿',
    latitude: 6.0903,
    longitude: 124.7201,
    endemicStatus: 'Philippines',
    description:
        'Endangered Philippine endemic slipper orchid found in Mindanao mossy montane forests.',
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
    title: 'Paphiopedilum',
    species: <CatalogSpecies>[
      CatalogSpecies(
        id: 1,
        scientificName: 'Paphiopedilum urbanianum',
        commonName: "Urban's Slipper Orchid",
        genus: 'Paphiopedilum',
        imageUrl: 'https://picsum.photos/seed/paphiopedilum-urbanianum/400/400',
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
