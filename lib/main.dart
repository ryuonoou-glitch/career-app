import 'dart:async';
import 'dart:io' show Platform, InternetAddress, SocketException, Socket;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const CareerGuidanceApp());
}

// ==================== APP CONFIG ====================
class AppConfig {
  /// Override per environment at build time, e.g.:
  /// flutter build apk --dart-define=BASE_URL=https://staging.riverviewhighschool.site.je/login.php
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://riverviewhighschool.site.je/login.php',
  );

  static Uri get startUrl => Uri.parse(baseUrl);

  /// Host the WebView is allowed to navigate within without bouncing
  /// out to the system browser.
  static String get allowedHost => startUrl.host;
}

class CareerGuidanceApp extends StatelessWidget {
  const CareerGuidanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Career Guidance System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==================== SPLASH SCREEN ====================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slideText;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fade = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack)),
    );
    _slideText = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );

    _initializeApp();
  }

  /// `connectivity_plus` only tells us we're attached to a network
  /// interface, not that it actually reaches the internet (captive
  /// portals, dead Wi-Fi, etc. all report "connected"). This does a
  /// real DNS lookup with a timeout to confirm actual reachability.
  Future<bool> _hasRealInternetAccess() async {
    try {
      final socket = await Socket.connect('8.8.8.8', 53, timeout: const Duration(seconds: 2));
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _initializeApp() async {
    // Kick the animation off and let it run while we check connectivity
    // in parallel, instead of waiting on a fixed extra delay.
    final animationDone = _controller.forward();

    final connectivityResult = await Connectivity().checkConnectivity();
    bool hasInternet = connectivityResult != ConnectivityResult.none;

    // Attachment looks fine — now confirm it's actually usable.
    if (hasInternet) {
      hasInternet = await _hasRealInternetAccess();
    }

    await animationDone;

    if (!mounted) return;

    if (!hasInternet) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NoInternetScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainAppScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A5A8C), Color(0xFF5C3E8C), Color(0xFF8C4E9E)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -60, right: -40, child: _glowCircle(180)),
            Positioned(bottom: -80, left: -60, child: _glowCircle(220)),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        // ClipOval ensures any corners from the image file are cropped perfectly
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/splash_logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  SlideTransition(
                    position: _slideText,
                    child: FadeTransition(
                      opacity: _fade,
                      child: Column(
                        children: [
                          const Text(
                            'Career Guidance System',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Find Your Perfect Career Path',
                            style: TextStyle(
                              fontSize: 15.5,
                              color: Colors.white.withOpacity(0.85),
                              fontStyle: FontStyle.italic,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 46),
                  FadeTransition(
                    opacity: _fade,
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.9),
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
    );
  }

  Widget _glowCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.06),
      ),
    );
  }
}

// ==================== MAIN APP SCREEN (WEBVIEW) ====================
class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  InAppWebViewController? _controller;

  // These update on every progress tick / nav event (can fire many
  // times per second during a page load). Using ValueNotifiers +
  // ValueListenableBuilder instead of setState() means only the tiny
  // progress bar / back button rebuild, not the whole Scaffold and
  // WebView subtree — that full-tree rebuild churn was the source of
  // the scrolling/animation jank.
  final ValueNotifier<bool> _isLoading = ValueNotifier(true);
  final ValueNotifier<int> _progress = ValueNotifier(0);
  final ValueNotifier<bool> _canGoBack = ValueNotifier(false);

  // True only when the *main frame* itself failed to load — not a
  // sub-resource, cache warning, or blocked tracker request. Drives
  // the full-screen retry UI instead of a passing snackbar. This is
  // rare enough that a normal setState() here is fine.
  bool _mainFrameLoadFailed = false;

  @override
  void dispose() {
    _isLoading.dispose();
    _progress.dispose();
    _canGoBack.dispose();
    super.dispose();
  }

  static final Uri _startUrl = AppConfig.startUrl;

  bool _isIgnorableError(String description) {
    final lower = description.toLowerCase();
    return lower.contains('cache') || description.contains('ERR_BLOCKED_BY_ORB');
  }

  Future<void> _onError(String description, {required bool isMainFrame}) async {
    if (_isIgnorableError(description)) return;

    if (isMainFrame) {
      if (!mounted) return;
      _isLoading.value = false;
      setState(() {
        _mainFrameLoadFailed = true;
      });
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $description'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _retry() async {
    setState(() {
      _mainFrameLoadFailed = false;
    });
    _isLoading.value = true;
    await _controller?.loadUrl(urlRequest: URLRequest(url: WebUri.uri(_startUrl)));
  }

  void _exitApp() {
    if (Platform.isAndroid) {
      // Gracefully returns to the home screen instead of hard-killing
      // the process (exit(0) can leave native resources in a bad state).
      SystemNavigator.pop();
    }
    // iOS: intentionally not handled here — see _buildActions().
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _canGoBack,
      builder: (context, canGoBack, child) {
        return PopScope(
          canPop: !canGoBack,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (_controller != null && await _controller!.canGoBack()) {
              _controller!.goBack();
            }
          },
          child: child!,
        );
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Career Guidance',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
          ),
          backgroundColor: const Color(0xFF4A6FA5),
          foregroundColor: Colors.white,
          elevation: 4,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: ValueListenableBuilder<bool>(
              valueListenable: _isLoading,
              builder: (context, isLoading, _) {
                return ValueListenableBuilder<int>(
                  valueListenable: _progress,
                  builder: (context, progress, __) {
                    if (!isLoading || progress >= 100) {
                      return const SizedBox.shrink();
                    }
                    return LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    );
                  },
                );
              },
            ),
          ),
          leading: ValueListenableBuilder<bool>(
            valueListenable: _canGoBack,
            builder: (context, canGoBack, _) {
              if (!canGoBack) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  if (_controller != null && await _controller!.canGoBack()) {
                    _controller!.goBack();
                  }
                },
              );
            },
          ),
          actions: _buildActions(),
        ),
        body: _mainFrameLoadFailed ? _buildRetryView() : _buildWebView(),
      ),
    );
  }

  List<Widget> _buildActions() {
    // Programmatic app-quit isn't really a thing on iOS (Apple
    // discourages it and Navigator.pop() on the root route is a
    // silent no-op there), so there's no point showing a button that
    // does nothing. Android keeps the real exit action.
    if (!Platform.isAndroid) return const [];
    return [
      IconButton(
        icon: const Icon(Icons.exit_to_app),
        onPressed: _showExitDialog,
      ),
    ];
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri.uri(_startUrl)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        // Opaque background avoids the extra alpha-blending cost of
        // a fully transparent WebView, which helps scroll smoothness.
        transparentBackground: false,
        cacheEnabled: true,
        // Hybrid composition (default in recent Android/Flutter) is
        // required for the login form's keyboard/text-field
        // interaction to work correctly. If this app never shows a
        // keyboard over the WebView, switching this to false (Virtual
        // Display) trades that away for noticeably smoother scroll
        // performance on older Android devices — worth an on-device
        // comparison if jank persists after the rebuild-scoping fix.
        useHybridComposition: true,
      ),
      onWebViewCreated: (controller) {
        _controller = controller;
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final uri = navigationAction.request.url;
        if (uri == null) return NavigationActionPolicy.ALLOW;

        final isOnAllowedHost = uri.host == AppConfig.allowedHost ||
            uri.host.endsWith('.${AppConfig.allowedHost}');

        if (isOnAllowedHost) {
          return NavigationActionPolicy.ALLOW;
        }

        // Anything off-domain (a link on the login page, etc.) opens
        // in the device's browser instead of loading inside our
        // WebView, so the app can't be used to spoof arbitrary sites.
        if (uri.scheme == 'http' || uri.scheme == 'https') {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        return NavigationActionPolicy.CANCEL;
      },
      onLoadStart: (controller, url) {
        _isLoading.value = true;
      },
      onProgressChanged: (controller, progress) {
        _progress.value = progress;
      },
      onLoadStop: (controller, url) async {
        final canGoBack = await controller.canGoBack();
        if (!mounted) return;
        _isLoading.value = false;
        _canGoBack.value = canGoBack;
      },
      onReceivedError: (controller, request, error) {
        _onError(error.description, isMainFrame: request.isForMainFrame ?? true);
      },
      onReceivedHttpError: (controller, request, errorResponse) {
        if (!(request.isForMainFrame ?? true)) return;
        final status = errorResponse.statusCode ?? 0;
        if (status >= 400) {
          _onError('HTTP $status', isMainFrame: true);
        }
      },
    );
  }

  Widget _buildRetryView() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 72, color: Colors.grey.shade400),
              const SizedBox(height: 20),
              const Text(
                'Couldn\'t load the page',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Something went wrong reaching the server.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _retry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6FA5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Retry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exitApp();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('EXIT'),
          ),
        ],
      ),
    );
  }
}

// ==================== NO INTERNET SCREEN ====================
class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A5A8C), Color(0xFF5C3E8C), Color(0xFF8C4E9E)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wifi_off_rounded, size: 80, color: Colors.white),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'No Internet Connection',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Please check your internet connection and try again',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.75)),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SplashScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4A6FA5),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Retry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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