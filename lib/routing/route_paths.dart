import 'package:fyp_source_code/admin/presentation/view/admin_panel_screen.dart';
import 'package:fyp_source_code/alerts/presentation/view/alerts_screen.dart';
import 'package:fyp_source_code/auth/presentation/bindings/auth_bindings.dart';
import 'package:fyp_source_code/auth/presentation/view/login_screen_professional.dart';
import 'package:fyp_source_code/auth/presentation/view/register_screen_professional.dart';
import 'package:fyp_source_code/auth/presentation/view/role_selection_screen.dart';
import 'package:fyp_source_code/auth/presentation/view/waiting_screen.dart';
import 'package:fyp_source_code/chat/presentation/view/chat_screen.dart';
import 'package:fyp_source_code/communities/presentation/view/communities_screen.dart';
import 'package:fyp_source_code/routing/auth_middleware.dart';
import 'package:fyp_source_code/routing/route_names.dart';
import 'package:fyp_source_code/splash_onboardings/presentation/view/onboarding_screen_professional.dart';
import 'package:fyp_source_code/splash_onboardings/presentation/view/splash_screen_professional.dart';
import 'package:fyp_source_code/start_point/view.dart';
import 'package:fyp_source_code/volunteer_side/coordination/presentation/view/coordination_screen.dart';
import 'package:fyp_source_code/volunteer_side/home/presentation/view/home_screen.dart';
import 'package:fyp_source_code/volunteer_side/map/presentation/view/map_screen.dart';
import 'package:fyp_source_code/volunteer_side/volunteer_verification/presentation/view/admin_verification_screen.dart';
import 'package:fyp_source_code/volunteer_side/profile/presentation/view/profile_screen.dart';
import 'package:fyp_source_code/request_side/home/presentation/view/request_home_screen.dart';
import 'package:fyp_source_code/request_side/home/presentation/view/tracking_map_screen.dart';
import 'package:get/get.dart';

class RoutePaths {
  static final _authGuard = AuthMiddleware();
  static final _guestGuard = GuestOnlyMiddleware();
  static final _adminGuard = AuthMiddleware(allowedRoles: {'admin'});
  static final _volunteerGuard = AuthMiddleware(allowedRoles: {'volunteer'});
  static final _requestSideGuard = AuthMiddleware(
    allowedRoles: {'user', 'volunteer'},
  );

  static List<GetPage> routePath = [
    // SPLASH SCREEN - Initial route
    GetPage(name: RouteNames.splash, page: () => SplashScreenProfessional()),

    // ONBOARDING SCREEN
    GetPage(
      name: RouteNames.onboarding,
      page: () => OnboardingScreenProfessional(),
    ),

    // AUTH SCREENS
    GetPage(
      name: RouteNames.signup,
      page: () => RegisterScreenProfessional(),
      binding: AuthBindings(),
      middlewares: [_guestGuard],
    ),
    GetPage(
      name: RouteNames.login,
      page: () => LoginScreen(),
      binding: AuthBindings(),
      middlewares: [_guestGuard],
    ),
    GetPage(
      name: RouteNames.roleSelection,
      page: () => RoleSelectionScreen(),
      binding: AuthBindings(),
      middlewares: [_authGuard],
    ),
    GetPage(
      name: RouteNames.adminVerification,
      page: () => VolunteerVerficationScreen(),
      middlewares: [_authGuard],
    ),
    GetPage(
      name: RouteNames.waitingScreen,
      page: () => WaitingScreen(),
      middlewares: [_authGuard],
    ),

    // VOLUNTEER SCREENS
    GetPage(
      name: RouteNames.home,
      page: () => HomeScreen(),
      middlewares: [_volunteerGuard],
    ),
    GetPage(
      name: RouteNames.coordination,
      page: () => CoordinationScreen(),
      middlewares: [_authGuard],
    ),
    GetPage(
      name: RouteNames.chatDetail,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return ChatScreen(
          receiverId: args?['userId'] ?? '',
          receiverName: args?['userName'] ?? 'Chat',
        );
      },
      middlewares: [_authGuard],
    ),
    GetPage(
      name: RouteNames.map,
      page: () => MapScreen(),
      middlewares: [_volunteerGuard],
    ),
    GetPage(
      name: RouteNames.alerts,
      page: () => const AlertsScreen(),
      middlewares: [_authGuard],
    ),
    GetPage(
      name: RouteNames.communities,
      page: () => const CommunitiesScreen(),
      middlewares: [_authGuard],
    ),

    // REQUEST SCREENS
    GetPage(
      name: RouteNames.requestHome,
      page: () => const RequestHomeScreen(),
      middlewares: [_requestSideGuard],
    ),

    // TRACKING SCREENS
    GetPage(
      name: RouteNames.trackingMap,
      page: () => const TrackingMapScreen(),
      middlewares: [_authGuard],
    ),

    // ADMIN SCREENS
    GetPage(
      name: RouteNames.adminPanel,
      page: () => AdminPanelScreen(),
      middlewares: [_adminGuard],
    ),

    // MISC SCREENS
    GetPage(
      name: RouteNames.startPoint,
      page: () => StartPoint(),
      middlewares: [_volunteerGuard],
    ),
    // Profile
    GetPage(
      name: RouteNames.profile,
      page: () => const ProfileScreen(),
      middlewares: [_authGuard],
    ),
  ];
}
