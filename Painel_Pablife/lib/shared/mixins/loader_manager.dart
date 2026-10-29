import 'package:get/get.dart';

mixin LoaderManagerMixin on GetxController {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void changeLoading(bool value) {
    _isLoading = value;
    update();
  }
}
