import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/network/app_socket_client.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'core/storage/secure_storage.dart';
import 'core/services/biometric_service.dart';
import 'shared/widgets/biometric_lock_gate.dart';
import 'shared/widgets/announcement_bottom_sheet.dart';
import 'shared/widgets/vitals_anomaly_card.dart';
import 'core/bluetooth/ble_manager.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class SmartVitalApp extends ConsumerStatefulWidget {
  const SmartVitalApp({super.key});

  @override
  ConsumerState<SmartVitalApp> createState() => _SmartVitalAppState();
}

class _SmartVitalAppState extends ConsumerState<SmartVitalApp> with WidgetsBindingObserver {
  StreamSubscription? _broadcastSub;
  StreamSubscription? _anomalySub;
  StreamSubscription<Uri>? _deepLinkSub;
  bool _requiresAuth = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
  }

  /// Sets up deep link handling for both cold-start and foreground links.
  /// Supports:
  ///   `smartvital://join?token=<token>`
  ///   `https://<cloudflare-url>/join?token=<token>`
  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();

    // Cold-start — app was launched from a deep link
    try {
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null) _handleDeepLink(initialUri);
    } catch (_) {}

    // Foreground — app was already open, link tapped
    _deepLinkSub = appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (_) {},
    );
  }

  void _handleDeepLink(Uri uri) {
    // Both  smartvital://join?token=xxx  AND
    //       https://<host>/join?token=xxx  are handled here.
    final isJoinPath = uri.path == '/join' || uri.host == 'join';
    if (!isJoinPath) return;

    final token = uri.queryParameters['token'] ?? '';
    if (token.isEmpty) return;

    // Wait until the router is mounted, then navigate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(appRouterProvider);
      router.go('/join?token=$token');
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final auth = ref.read(authProvider);
      if (auth.isAuthenticated) {
        ref.read(biometricServiceProvider).isEnabled.then((enabled) {
          if (enabled && mounted) {
            setState(() {
              _requiresAuth = true;
            });
          }
        });
      }
    }
  }

  void _setupBroadcastListener() {
    _broadcastSub ??= ref.read(appSocketClientProvider).adminBroadcastStream.listen((data) {
      final title = data['title'] as String? ?? 'Notice';
      final body = data['body'] as String? ?? '';
      
      final context = ref.read(appRouterProvider).routerDelegate.navigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      AnnouncementBottomSheet.show(context, title: title, bodyMarkdown: body);
    });

    _anomalySub ??= ref.read(appSocketClientProvider).anomalyStream.listen((data) {
      final context = ref.read(appRouterProvider).routerDelegate.navigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      ref.read(bleManagerProvider).sendHapticCommand();
      VitalsAnomalyCard.show(context, data);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _broadcastSub?.cancel();
    _anomalySub?.cancel();
    _deepLinkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    // Ensure socket connects/disconnects based on auth state
    ref.listen(authProvider, (prev, next) async {
      final justFinishedRestoring = prev?.isRestoring == true && next.isRestoring == false && next.isAuthenticated;
      final justLoggedIn = prev?.isAuthenticated != next.isAuthenticated && next.isAuthenticated;
      
      if (justFinishedRestoring || justLoggedIn) {
        _setupBroadcastListener();
        final storage = ref.read(secureStorageProvider);
        final token = await storage.read(SecureStorage.accessTokenKey);
        if (token != null) ref.read(appSocketClientProvider).connect(token);
      } else if (prev?.isAuthenticated != next.isAuthenticated && !next.isAuthenticated) {
        ref.read(appSocketClientProvider).disconnect();
      }
    });

    final app = MaterialApp.router(
      title: 'SmartVital',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.light, // Forced Light Mode
      themeMode: ThemeMode.light,
      routerConfig: router,
      scaffoldMessengerKey: scaffoldMessengerKey,
    );

    if (_requiresAuth) {
      return BiometricLockGate(
        key: UniqueKey(), // Ensure it resets state on new wrap
        onUnlocked: () {
          setState(() {
            _requiresAuth = false;
          });
        },
        child: app,
      );
    }

    return app;
  }
}
