import 'package:get/get.dart';
import 'package:security_guard/modules/auth/ForgotPassword/forgot_password_controller.dart';
import 'package:security_guard/modules/auth/ForgotPassword/forgot_password_view.dart';
import 'package:security_guard/modules/auth/controllers/auth_controller.dart';
import 'package:security_guard/modules/auth/login/login_page.dart';
import 'package:security_guard/modules/home/view/home_view.dart';
import 'package:security_guard/modules/home/controllers/home_controller.dart';
import 'package:security_guard/modules/petrol/controllers/patrol_controller.dart';
import 'package:security_guard/modules/petrol/views/patrol_check_in_view.dart';
import 'package:security_guard/routes/app_rout.dart' show Routes;
import 'package:security_guard/shared/widgets/bottomnavigation/bottomnavigation.dart';
import 'package:security_guard/shared/widgets/bottomnavigation/navigation_controller.dart';


class AppPages {
  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(
      name: Routes.LOGIN,
      page: () => LoginPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthController>(() => AuthController());
      }),
    ),
    GetPage(
      name: Routes.FORGOT_PASSWORD,
      page: () => ForgotPasswordView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ForgotPasswordController>(() => ForgotPasswordController());
      }),
    ),
    GetPage(
      name: Routes.HOME,
      page: () => HomeView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HomeController>(() => HomeController());
      }),
    ),
    GetPage(
      name: Routes.PATROL_CHECK_IN,
      page: () => PatrolCheckInScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<PatrolCheckInController>(() => PatrolCheckInController());
      }),
    ),
    GetPage(
      name: Routes.BOTTOM_NAV,
      page: () => BottomNavBarWidget(),
      binding: BindingsBuilder(() {
        Get.lazyPut<BottomNavController>(() => BottomNavController());
      }),
    ),
  ];
}
