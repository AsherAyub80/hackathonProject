// ignore_for_file: use_build_context_synchronously

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:hackathon_project/model/product_model.dart' as pm;
import 'package:hackathon_project/provider/product_provider.dart';
import 'package:hackathon_project/screen/reciept_screen.dart';
import 'package:hackathon_project/services/auth/firestore_service.dart';

class CartProvider extends ChangeNotifier {
  final List<pm.Product> _cart = [];
  List<pm.Product> get cart => _cart;

  void addToCart(pm.Product product, context) {
    final existingProductIndex = _cart.indexWhere(
      (element) => element.id == product.id,
    );

    if (existingProductIndex != -1) {
      _cart[existingProductIndex].quantity++;
    } else {
      product.quantity = 1;
      _cart.add(product);
    }
    notifyListeners();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Product Added to cart'),
        duration: Duration(seconds: 1)));
  }

  void incrementQty(int index) {
    _cart[index].quantity++;
    notifyListeners();
  }

  void decrementQty(int index) {
    if (_cart[index].quantity > 1) {
      _cart[index].quantity--;
    } else {
      _cart.removeAt(index);
    }
    notifyListeners();
  }

  void deleteAt(int index) {
    _cart.removeAt(index);
    notifyListeners();
  }

  double totalPrice() {
    double total = 0.0;
    for (pm.Product element in _cart) {
      total += element.price * element.quantity;
    }
    return total;
  }

  Future<void> checkout(
  BuildContext ctx,
  String user,
  String email,
  String storeId,
  String address,
  String paymentMethod,
 
) async {
  BotToast.showLoading();
  final firestoreService = FirestoreService();
  final total = totalPrice();
  final List<pm.Product> myCart = List.from(cart); // Create a copy of the cart

  try {
    // Fetch store details
    final productProvider = ProductProvider();
    final storeDetails = await productProvider.fetchStoreDetails(storeId);

    // Prepare store location
    final storeLocation = {
      'lat': storeDetails['lat'],
      'lng': storeDetails['lng'],
      
    };

    // Store the order in Firestore with the payment method and store location
    await firestoreService.addOrder(
      cart,
      total,
      user,
      email,
      storeId,
      address,
      paymentMethod, // Pass the payment method
      storeLocation, // Pass the store location
    );

    _cart.clear();
    BotToast.showText(
      text: "Order Placed!",
      contentColor: Colors.green,
    );
    notifyListeners();

    Navigator.pushReplacement(
      ctx,
      MaterialPageRoute(
        builder: (context) => RecieptScreen(listCart: myCart),
      ),
    );
  } catch (e) {
    BotToast.showText(
      text: "Failed to place order: $e",
      contentColor: Colors.red,
    );
  } finally {
    BotToast.closeAllLoading();
  }
}

  int getQuantity(String productId) {
    final product = _cart.firstWhere((product) => product.id == productId,
        orElse: () => pm.Product(
            storeId: '',
            id: '',
            title: '',
            description: '',
            price: 0.0,
            store: '',
            category: '',
            imageUrl: '',
            colors: [],
            rating: 0.0,
            quantity: 0,
            reviews: []));
    return product.quantity;
  }

  bool isProductInCart(String productId) {
    return _cart.any((product) => product.id == productId);
  }
}
