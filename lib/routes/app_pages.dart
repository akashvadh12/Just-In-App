import 'package:get/get.dart';
import 'package:security_guard/modules/auth/controllers/auth_controller.dart';
import 'package:security_guard/modules/auth/login/login_page.dart';
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
  ];
}