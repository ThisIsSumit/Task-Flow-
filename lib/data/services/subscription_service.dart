import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:todo_app/data/models/user_models.dart';

import 'auth_service.dart';
import 'firestore_service.dart';

/// Set to [true] to skip all subscription / IAP checks during development.
/// All users will be treated as premium when this flag is on.
/// TODO: Set to false before shipping to production.
const bool kDevBypassSubscription = true;

class SubscriptionService extends GetxService {
  static const String monthlyProductId = 'taskflow_premium_monthly';
  static const String yearlyProductId = 'taskflow_premium_yearly';

  final AuthService _authService = Get.find<AuthService>();
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  final RxBool isStoreAvailable = false.obs;
  final RxBool isPurchasePending = false.obs;
  final RxBool isPremium = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<ProductDetails> products = <ProductDetails>[].obs;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool get supportsInAppPurchase {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void onInit() {
    super.onInit();

    // --- DEVELOPER BYPASS --- skip real IAP when kDevBypassSubscription is on
    if (kDevBypassSubscription) {
      isPremium.value = true;
      return;
    }
    // --- END DEVELOPER BYPASS ---

    ever<UserModel?>(_authService.userModel, _syncPremiumFromUser);
    _syncPremiumFromUser(_authService.userModel.value);

    if (supportsInAppPurchase) {
      _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _purchaseSubscription?.cancel(),
        onError: (Object error) {
          isPurchasePending.value = false;
          errorMessage.value = error.toString();
        },
      );
      unawaited(loadProducts());
    }
  }

  @override
  void onClose() {
    _purchaseSubscription?.cancel();
    super.onClose();
  }

  Future<void> loadProducts() async {
    if (!supportsInAppPurchase) {
      return;
    }

    final available = await _inAppPurchase.isAvailable();
    isStoreAvailable.value = available;
    if (!available) {
      products.clear();
      return;
    }

    final response = await _inAppPurchase.queryProductDetails({
      monthlyProductId,
      yearlyProductId,
    });

    if (response.error != null) {
      errorMessage.value = response.error!.message;
    }

    products.assignAll(response.productDetails);
  }

  Future<void> purchasePremium([ProductDetails? product]) async {
    if (!supportsInAppPurchase) {
      Get.snackbar(
        'Unsupported Platform',
        'Subscriptions are available on Android and iOS builds.',
      );
      return;
    }

    final selectedProduct = product ?? _preferredProduct();
    if (selectedProduct == null) {
      await loadProducts();
    }

    final resolvedProduct = product ?? _preferredProduct();
    if (resolvedProduct == null) {
      Get.snackbar(
        'Store Unavailable',
        'No premium plans were returned. Check your store product IDs.',
      );
      return;
    }

    isPurchasePending.value = true;
    errorMessage.value = '';

    final purchaseParam = PurchaseParam(productDetails: resolvedProduct);
    final started = await _inAppPurchase.buyNonConsumable(
      purchaseParam: purchaseParam,
    );

    if (!started) {
      isPurchasePending.value = false;
    }
  }

  Future<void> restorePurchases() async {
    if (!supportsInAppPurchase) {
      return;
    }

    await _inAppPurchase.restorePurchases();
  }

  Future<void> grantPremiumManually({int durationDays = 30}) async {
    final uid = _authService.getUserId();
    if (uid == null) {
      return;
    }

    final now = DateTime.now();
    await _firestoreService.updateUserSubscription(
      uid,
      subscriptionType: SubscriptionType.premium,
      subscriptionStartDate: now,
      subscriptionEndDate: now.add(Duration(days: durationDays)),
    );
    await _authService.refreshUserModel();
  }

  ProductDetails? _preferredProduct() {
    if (products.isEmpty) {
      return null;
    }

    for (final product in products) {
      if (product.id == monthlyProductId) {
        return product;
      }
    }

    return products.first;
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        isPurchasePending.value = true;
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        isPurchasePending.value = false;
        errorMessage.value = purchase.error?.message ?? 'Purchase failed';
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _activatePremiumFromPurchase(purchase);
      }

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  Future<void> _activatePremiumFromPurchase(PurchaseDetails purchase) async {
    final uid = _authService.getUserId();
    if (uid == null) {
      isPurchasePending.value = false;
      return;
    }

    final now = DateTime.now();
    await _firestoreService.updateUserSubscription(
      uid,
      subscriptionType: SubscriptionType.premium,
      subscriptionStartDate: now,
      subscriptionEndDate: now.add(_durationForProduct(purchase.productID)),
    );
    await _authService.refreshUserModel();
    isPurchasePending.value = false;
  }

  Duration _durationForProduct(String productId) {
    if (productId == yearlyProductId) {
      return const Duration(days: 365);
    }

    return const Duration(days: 30);
  }

  void _syncPremiumFromUser(UserModel? user) {
    isPremium.value = user?.isPremiumActive ?? false;
  }
}
