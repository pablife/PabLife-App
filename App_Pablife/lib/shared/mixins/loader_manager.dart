import 'package:get/get.dart';

mixin LoaderManagerMixin on GetxController {
  bool isLoading = false;
  bool isLoadingCreate = false;
  bool isLoadingDelete = false;
  bool isLoadingUpdate = false;

  void changeLoading(bool loading) {
    isLoading = loading;
    update();
  }

  void changeLoadingCreate(bool loading) {
    isLoadingCreate = loading;
    update();
  }

  void changeLoadingDelete(bool loading) {
    isLoadingDelete = loading;
    update();
  }

  void changeLoadingUpdate(bool loading) {
    isLoadingUpdate = loading;
    update();
  }
}
