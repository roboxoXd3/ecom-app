import 'package:get/get.dart';

class ProductDetailsController extends GetxController {
  final RxInt currentImageIndex = 0.obs;
  final RxString selectedSize = ''.obs;
  final RxString selectedColor = ''.obs;
  final RxInt quantity = 1.obs;

  void updateImageIndex(int index) {
    currentImageIndex.value = index;
  }

  void updateSize(String size) {
    selectedSize.value = size;
  }

  void updateColor(String color) {
    selectedColor.value = color;
  }

  void incrementQuantity() {
    quantity.value++;
  }

  void decrementQuantity() {
    if (quantity.value > 1) {
      quantity.value--;
    }
  }

  void reset() {
    currentImageIndex.value = 0;
    selectedSize.value = '';
    selectedColor.value = '';
    quantity.value = 1;
  }
}
