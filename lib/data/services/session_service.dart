import 'package:get/get.dart';

class SessionService extends GetxService {
  String? companyId;
  String? siteId;

  void setSession({required String company, required String site}) {
    companyId = company;
    siteId = site;
  }
}
