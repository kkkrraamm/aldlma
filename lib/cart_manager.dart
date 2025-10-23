import 'package:flutter/foundation.dart';

class CartManager extends ChangeNotifier {
  // Singleton pattern
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();
  
  // سلة منفصلة لكل مقدم خدمة
  Map<int, List<CartItem>> _providerCarts = {};
  
  // الحصول على سلة مقدم خدمة محدد
  List<CartItem> getProviderCart(int providerId) {
    return _providerCarts[providerId] ?? [];
  }
  
  // إضافة منتج للسلة مع الإضافات
  void addToCart({
    required int providerId,
    required int productId,
    required String productName,
    required String providerName,
    required int basePrice,
    required Map<int, CartAddon> selectedAddons,
    String notes = '',
  }) {
    if (!_providerCarts.containsKey(providerId)) {
      _providerCarts[providerId] = [];
    }
    
    // البحث عن منتج مشابه في السلة
    final existingItemIndex = _providerCarts[providerId]!.indexWhere(
      (item) => item.productId == productId && _addonsMatch(item.addons, selectedAddons),
    );
    
    if (existingItemIndex != -1) {
      // زيادة الكمية إذا وجد منتج مشابه
      _providerCarts[providerId]![existingItemIndex].quantity++;
    } else {
      // إضافة منتج جديد
      final cartItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch,
        productId: productId,
        productName: productName,
        providerName: providerName,
        basePrice: basePrice,
        quantity: 1,
        addons: selectedAddons,
        notes: notes,
      );
      
      _providerCarts[providerId]!.add(cartItem);
    }
    
    notifyListeners();
  }
  
  // إزالة منتج من السلة
  void removeFromCart(int providerId, int itemId) {
    if (_providerCarts.containsKey(providerId)) {
      _providerCarts[providerId]!.removeWhere((item) => item.id == itemId);
      if (_providerCarts[providerId]!.isEmpty) {
        _providerCarts.remove(providerId);
      }
      notifyListeners();
    }
  }
  
  // تحديث كمية منتج
  void updateQuantity(int providerId, int itemId, int newQuantity) {
    if (_providerCarts.containsKey(providerId)) {
      final itemIndex = _providerCarts[providerId]!.indexWhere((item) => item.id == itemId);
      if (itemIndex != -1) {
        if (newQuantity <= 0) {
          _providerCarts[providerId]!.removeAt(itemIndex);
          if (_providerCarts[providerId]!.isEmpty) {
            _providerCarts.remove(providerId);
          }
        } else {
          _providerCarts[providerId]![itemIndex].quantity = newQuantity;
        }
        notifyListeners();
      }
    }
  }
  
  // مسح سلة مقدم خدمة محدد
  void clearProviderCart(int providerId) {
    _providerCarts.remove(providerId);
    notifyListeners();
  }
  
  // مسح جميع السلال
  void clearAllCarts() {
    _providerCarts.clear();
    notifyListeners();
  }
  
  // حساب إجمالي سلة مقدم خدمة
  int getProviderCartTotal(int providerId) {
    final cart = getProviderCart(providerId);
    return cart.fold(0, (total, item) => total + item.totalPrice);
  }
  
  // عدد العناصر في سلة مقدم خدمة
  int getProviderCartItemCount(int providerId) {
    final cart = getProviderCart(providerId);
    return cart.fold(0, (total, item) => total + item.quantity);
  }
  
  // التحقق من تطابق الإضافات
  bool _addonsMatch(Map<int, CartAddon> addons1, Map<int, CartAddon> addons2) {
    if (addons1.length != addons2.length) return false;
    
    for (final entry in addons1.entries) {
      if (!addons2.containsKey(entry.key) || 
          addons2[entry.key]!.quantity != entry.value.quantity) {
        return false;
      }
    }
    
    return true;
  }
  
  // الحصول على جميع مقدمي الخدمات في السلة
  List<int> getActiveProviders() {
    return _providerCarts.keys.toList();
  }
}

// عنصر في السلة
class CartItem {
  final int id;
  final int productId;
  final String productName;
  final String providerName;
  final int basePrice;
  int quantity;
  final Map<int, CartAddon> addons;
  final String notes;
  
  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.providerName,
    required this.basePrice,
    required this.quantity,
    required this.addons,
    required this.notes,
  });
  
  // حساب السعر الإجمالي للعنصر
  int get totalPrice {
    final addonsPrice = addons.values.fold(0, (total, addon) => 
      total + (addon.price * addon.quantity));
    return (basePrice + addonsPrice) * quantity;
  }
  
  // قائمة الإضافات المختارة
  List<String> get selectedAddonsList {
    return addons.values.map((addon) => 
      '${addon.name}${addon.quantity > 1 ? ' (${addon.quantity}x)' : ''}').toList();
  }
}

// إضافة في السلة
class CartAddon {
  final int id;
  final String name;
  final String description;
  final int price;
  final int quantity;
  
  CartAddon({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
  });
}
