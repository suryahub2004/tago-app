import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/family/presentation/screens/alert_settings_screen.dart';
import '../../features/family/presentation/screens/family_hub_screen.dart';
import '../../features/family/presentation/screens/family_comparison_screen.dart';
import '../../features/family/presentation/screens/invite_member_screen.dart';
import '../../features/family/presentation/screens/member_detail_screen.dart';
import '../../features/health/presentation/screens/activity_screen.dart';
import '../../features/health/presentation/screens/body_screen.dart';
import '../../features/health/presentation/screens/health_screen.dart';
import '../../features/health/presentation/screens/heart_screen.dart';
import '../../features/health/presentation/screens/history_screen.dart';
import '../../features/health/presentation/screens/sleep_screen.dart';
import '../../features/health/presentation/screens/trends_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/onboarding/presentation/screens/ai_analysis_screen.dart';
import '../../features/onboarding/presentation/screens/device_pairing_screen.dart';
import '../../features/onboarding/presentation/screens/health_permission_screen.dart';
import '../../features/onboarding/presentation/screens/product_selection_screen.dart';
import '../../features/onboarding/presentation/screens/questionnaire_screen.dart';
import '../../features/profile/presentation/screens/alert_threshold_screen.dart';
import '../../features/profile/presentation/screens/device_settings_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/notification_settings_screen.dart';
import '../../features/profile/presentation/screens/privacy_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/support_ticket_screen.dart';
import '../../features/profile/presentation/screens/ticket_history_screen.dart';
import '../../features/shop/presentation/screens/cart_screen.dart';
import '../../features/shop/presentation/screens/checkout_screen.dart';
import '../../features/shop/presentation/screens/orders_screen.dart';
import '../../features/shop/presentation/screens/product_detail_screen.dart';
import '../../features/shop/presentation/screens/shop_screen.dart';
import '../../features/shop/presentation/screens/order_form_screen.dart';
import '../../features/shop/presentation/screens/order_confirmation_screen.dart';
import '../../features/shop/presentation/screens/order_detail_screen.dart';
import '../../features/ring_sizer/presentation/screens/ring_sizer_screen.dart';
import '../../features/ring_sizer/presentation/screens/ring_size_result_screen.dart';
import '../../features/ring_sizer/presentation/screens/ring_size_chart_screen.dart';
import '../../features/ai_coach/presentation/screens/ai_coach_screen.dart';
import '../../features/workout/presentation/screens/workout_hub_screen.dart';
import '../../features/meditation/presentation/screens/meditation_hub_screen.dart';
import '../../features/my_device/presentation/screens/my_device_screen.dart';
import '../../features/family/presentation/screens/share_settings_screen.dart';
import '../../features/family/presentation/screens/family_qr_screen.dart';
import '../../features/family/presentation/screens/scan_qr_screen.dart';
import '../../features/family/presentation/screens/pending_invites_screen.dart';
import '../../features/family/presentation/screens/join_family_screen.dart';
import '../../features/reports/presentation/screens/health_report_screen.dart';
import '../../shared/widgets/sv_bottom_nav.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final path = state.uri.path;
      final isPublic =
          path == '/splash' || path == '/login' || path == '/register';

      if (auth.isRestoring) {
        return path == '/splash' ? null : '/splash';
      }
      if (!auth.isAuthenticated) {
        return isPublic ? null : '/login';
      }
      // Authenticated users with completed onboarding always go to dashboard
      // when on public/splash screens — no further checks needed.
      if (auth.isAuthenticated &&
          auth.onboardingComplete &&
          (path == '/login' || path == '/register' || path == '/splash')) {
        return '/home/dashboard';
      }
      // We do NOT redirect to onboarding if the user is already authenticated
      // and navigating normally via the bottom bar.
      // Brand new registrations will be routed explicitly by RegisterScreen.
      // Unauthenticated-to-authenticated transition for users without onboarding
      if (auth.isAuthenticated &&
          !auth.onboardingComplete &&
          (path == '/login' || path == '/register' || path == '/splash')) {
        return '/onboarding/product-select';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding/product-select',
        name: RouteNames.productSelection,
        builder: (context, state) => const ProductSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding/questionnaire',
        name: RouteNames.questionnaire,
        builder: (context, state) => const QuestionnaireScreen(),
      ),
      GoRoute(
        path: '/onboarding/analysis',
        name: RouteNames.analysis,
        builder: (context, state) => const AiAnalysisScreen(),
      ),
      GoRoute(
        path: '/onboarding/health-permission',
        name: RouteNames.healthPermission,
        builder: (context, state) => const HealthPermissionScreen(),
      ),
      GoRoute(
        path: '/onboarding/device-pairing',
        name: RouteNames.devicePairing,
        builder: (context, state) => const DevicePairingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            SvBottomNav(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/dashboard',
                name: RouteNames.dashboard,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/health',
                name: RouteNames.health,
                builder: (context, state) => const HealthScreen(),
                routes: [
                  GoRoute(
                    path: 'heart',
                    builder: (context, state) => const HeartScreen(),
                  ),
                  GoRoute(
                    path: 'sleep',
                    builder: (context, state) => const SleepScreen(),
                  ),
                  GoRoute(
                    path: 'activity',
                    builder: (context, state) => const ActivityScreen(),
                  ),
                  GoRoute(
                    path: 'body',
                    builder: (context, state) => const BodyScreen(),
                  ),
                  GoRoute(
                    path: 'trends',
                    builder: (context, state) => const TrendsScreen(),
                  ),
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => const HistoryScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/family',
                name: RouteNames.family,
                builder: (context, state) => const FamilyHubScreen(),
                routes: [
                  GoRoute(
                    path: 'member/:id',
                    builder: (context, state) => MemberDetailScreen(
                      memberId: state.pathParameters['id'] ?? 'member',
                    ),
                  ),
                  GoRoute(
                    path: 'invite',
                    builder: (context, state) => const InviteMemberScreen(),
                  ),
                  GoRoute(
                    path: 'alert-settings/:memberId',
                    builder: (context, state) => AlertSettingsScreen(
                      memberId: state.pathParameters['memberId'] ?? 'member',
                    ),
                  ),
                  GoRoute(
                    path: 'share-settings',
                    builder: (context, state) => const ShareSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'qr',
                    builder: (context, state) => const FamilyQrScreen(),
                  ),
                  GoRoute(
                    path: 'scan',
                    builder: (context, state) => const ScanQrScreen(),
                  ),
                  GoRoute(
                    path: 'pending',
                    builder: (context, state) => const PendingInvitesScreen(),
                  ),
                  GoRoute(
                    path: 'compare',
                    builder: (context, state) => const FamilyComparisonScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/shop',
                name: RouteNames.shop,
                builder: (context, state) => ShopScreen(
                  preselectedRingSize: state.uri.queryParameters['ringSize'],
                ),
                routes: [
                  GoRoute(
                    path: 'product/:slug',
                    builder: (context, state) => ProductDetailScreen(
                      slug: state.pathParameters['slug'] ?? 'product',
                    ),
                  ),
                  GoRoute(
                    path: 'cart',
                    builder: (context, state) => const CartScreen(),
                  ),
                  GoRoute(
                    path: 'checkout',
                    builder: (context, state) => const CheckoutScreen(),
                  ),
                  GoRoute(
                    path: 'orders',
                    builder: (context, state) => const OrdersScreen(),
                  ),
                  GoRoute(
                    path: 'order',
                    builder: (context, state) {
                      final productId = state.uri.queryParameters['product'] ?? '';
                      final deviceType = state.uri.queryParameters['deviceType'];
                      if (productId.isEmpty) {
                        // No valid product ID — bounce back to shop
                        return const ShopScreen();
                      }
                      return OrderFormScreen(
                        productId: productId,
                        deviceType: deviceType,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'order-success',
                    builder: (context, state) {
                      // The real order ID is passed via GoRouter extra from
                      // OrderFormScreen after a successful backend response.
                      final orderId = state.extra as String? ?? '';
                      return OrderConfirmationScreen(orderId: orderId);
                    },
                  ),
                  GoRoute(
                    path: 'order/:orderId',
                    builder: (context, state) => OrderDetailScreen(
                      orderId: state.pathParameters['orderId'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/profile',
                name: RouteNames.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'devices',
                    builder: (context, state) => const DeviceSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) =>
                        const NotificationSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'privacy',
                    builder: (context, state) => const PrivacyScreen(),
                  ),
                  GoRoute(
                    path: 'thresholds',
                    builder: (context, state) => const AlertThresholdScreen(),
                  ),
                  GoRoute(
                    path: 'ring-sizer',
                    builder: (context, state) => const RingSizerScreen(),
                    routes: [
                      GoRoute(
                        path: 'result',
                        builder: (context, state) => const RingSizeResultScreen(),
                      ),
                      GoRoute(
                        path: 'chart',
                        builder: (context, state) => const RingSizeChartScreen(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'support',
                    builder: (context, state) => const TicketHistoryScreen(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (context, state) => const SupportTicketScreen(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'reports',
                    builder: (context, state) => const HealthReportScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/ai-coach',
        name: RouteNames.aiCoach,
        builder: (context, state) => const AiCoachScreen(),
      ),
      // Deep link entry point for family invites
      // Handles: smartvital://join?token=<token>
      // Also handles HTTPS links via Cloudflare tunnel:
      // https://<tunnel>/join?token=<token>
      GoRoute(
        path: '/join',
        name: 'joinFamily',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return JoinFamilyScreen(token: token);
        },
      ),
      GoRoute(
        path: '/workout',
        name: RouteNames.workoutHub,
        builder: (context, state) => const WorkoutHubScreen(),
      ),
      GoRoute(
        path: '/meditation',
        name: RouteNames.meditationHub,
        builder: (context, state) => const MeditationHubScreen(),
      ),
      GoRoute(
        path: '/my-device',
        name: RouteNames.myDevice,
        builder: (context, state) => const MyDeviceScreen(),
      ),
    ],
  );
});
