import 'package:get/get.dart';
import 'package:security_guard/modules/auth/ForgotPassword/forgot_password_view.dart';
import 'package:security_guard/modules/auth/controllers/auth_controller.dart';
import 'package:security_guard/modules/auth/login/login_page.dart';
import 'package:security_guard/modules/home/view/home_view.dart';
import 'package:security_guard/modules/home/controllers/home_controller.dart';
import 'package:security_guard/modules/petrol/controllers/patrol_controller.dart';
import 'package:security_guard/modules/petrol/views/patrol_check_in_view.dart';
import 'package:security_guard/routes/app_rout.dart' show Routes;

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
      name: Routes.HOME,
      page: () => HomeView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HomeController>(() => HomeController());
      }),
    ),
    GetPage(name: Routes.FORGOT_PASSWORD, page: () => ForgotPasswordView()),
  ];
}
