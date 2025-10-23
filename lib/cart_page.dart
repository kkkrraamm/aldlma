import 'package:flutter/material.dart';
import 'theme_config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cart_manager.dart';
import 'models.dart';
import 'auth.dart';
import 'orders_service.dart';
import 'notifications.dart';
import 'address_management.dart';

class CartPage extends StatefulWidget {
  final int? providerId; // إذا تم تحديد مقدم خدمة معين
  
  const CartPage({Key? key, this.providerId}) : super(key: key);
  
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartManager _cartManager = CartManager();
  DeliveryAddress? _selectedAddress;
  
  @override
  void initState() {
    super.initState();
    // الاستماع لتغييرات السلة
    _cartManager.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  String _deliveryMethod = 'delivery'; // delivery, pickup
  String _paymentMethod = 'cash'; // cash, card
  String _cardType = 'visa'; // visa, mastercard, mada, applepay

  // الحصول على السلال النشطة
  Map<int, List<CartItem>> get activeProviderCarts {
    final carts = <int, List<CartItem>>{};
    for (final providerId in _cartManager.getActiveProviders()) {
      final cart = _cartManager.getProviderCart(providerId);
      if (cart.isNotEmpty) {
        carts[providerId] = cart;
      }
    }
    return carts;
  }

  // حساب الإجمالي لمقدم خدمة محدد
  double getProviderSubtotal(int providerId) {
    return _cartManager.getProviderCartTotal(providerId) / 100;
  }

  double get deliveryFee {
    return _deliveryMethod == 'delivery' ? 10.0 : 0.0;
  }

  // حساب الإجمالي العام
  double get grandTotal {
    double total = 0;
    for (final providerId in activeProviderCarts.keys) {
      total += getProviderSubtotal(providerId);
    }
    return total; // بدون رسوم توصيل
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    final carts = activeProviderCarts;
    
    if (carts.isEmpty) {
      return _buildEmptyCart();
    }

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'السلة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: theme.textPrimaryColor),
        ),
        backgroundColor: theme.cardColor,
        elevation: 1,
        centerTitle: true,
        iconTheme: IconThemeData(color: theme.textPrimaryColor),
      ),
      body: Column(
        children: [
          // عناصر السلة مجمعة حسب المقدم
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                // عرض سلة كل مقدم منفصلة
                ...carts.entries.map((entry) {
                  final providerId = entry.key;
                  final providerCart = entry.value;
                  return _buildProviderCartSection(providerId, providerCart);
                }).toList(),
                
                SizedBox(height: 16),
                
                // خيارات التوصيل والاستلام
                _buildDeliveryPickupOptions(),
                SizedBox(height: 16),
                
                
                
                // ملخص الطلب الإجمالي
                _buildGrandOrderSummary(),
              ],
            ),
          ),
          
          // زر إتمام الطلب
          _buildCheckoutButton(),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'السلة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: theme.textPrimaryColor),
        ),
        backgroundColor: theme.cardColor,
        elevation: 1,
        centerTitle: true,
        iconTheme: IconThemeData(color: theme.textPrimaryColor),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: theme.textSecondaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'السلة فارغة',
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.textPrimaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'أضف منتجات لبدء التسوق',
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: theme.textSecondaryColor,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                foregroundColor: isDark ? ThemeConfig.kNightDeep : Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text(
                'تصفح الخدمات',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // تم استبدال هذه الدالة بـ _buildDynamicCartItem

  // تم حذف دالة طريقة الاستلام القديمة

  Widget _buildCardTypeOption(String value, String name, String icon, Color color) {
    final isSelected = _cardType == value;
    final isApplePay = value == 'applepay';
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _cardType = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isApplePay ? 20 : 12, 
          vertical: isApplePay ? 16 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(isApplePay ? 16 : 8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          gradient: isApplePay && isSelected ? LinearGradient(
            colors: [Colors.black.withOpacity(0.1), Colors.grey.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: TextStyle(fontSize: isApplePay ? 24 : 16),
            ),
            SizedBox(width: isApplePay ? 12 : 6),
            Expanded(
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: isApplePay ? 16 : 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey.shade700,
                ),
              ),
            ),
            if (isApplePay && isSelected)
              Icon(Icons.check_circle, color: Colors.black, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'طريقة الدفع',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            
            RadioListTile<String>(
              title: Row(
                children: [
                  Icon(Icons.money, color: Colors.green),
                  SizedBox(width: 8),
                  Text('نقدي', style: GoogleFonts.cairo()),
                ],
              ),
              subtitle: Text(
                'الدفع عند الاستلام من المحل',
                style: GoogleFonts.cairo(fontSize: 12),
              ),
              value: 'cash',
              groupValue: _paymentMethod,
              onChanged: (value) {
                setState(() {
                  _paymentMethod = value!;
                });
              },
            ),
            
            RadioListTile<String>(
              title: Row(
                children: [
                  Icon(Icons.credit_card, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('بطاقة', style: GoogleFonts.cairo()),
                ],
              ),
              subtitle: Text(
                'مدى، فيزا، ماستركارد، آبل باي - عند الاستلام',
                style: GoogleFonts.cairo(fontSize: 12),
              ),
              value: 'card',
              groupValue: _paymentMethod,
              onChanged: (value) {
                setState(() {
                  _paymentMethod = value!;
                });
              },
            ),
            
            // خيارات أنواع البطاقات (تظهر عند اختيار البطاقة)
            if (_paymentMethod == 'card') ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نوع البطاقة',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // آبل باي مميز بتصميم آيفون
                    _buildApplePayOption(),
                    SizedBox(height: 16),
                    
                    // بطاقات الائتمان والخصم
                    Text(
                      'بطاقات الائتمان والخصم',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Expanded(child: _buildCardTypeOption('visa', 'فيزا', '💳', Colors.blue)),
                        SizedBox(width: 8),
                        Expanded(child: _buildCardTypeOption('mastercard', 'ماستركارد', '💳', Colors.red)),
                        SizedBox(width: 8),
                        Expanded(child: _buildCardTypeOption('mada', 'مدى', '🏦', Colors.green)),
                      ],
                    ),
                    
                    // نموذج بيانات البطاقة (للبطاقات التقليدية فقط)
                    if (_cardType != 'applepay') ...[
                      SizedBox(height: 16),
                      _buildCardDetailsForm(),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // تم استبدال هذه الدالة بـ _buildGrandOrderSummary

  Widget _buildProviderCartSection(int providerId, List<CartItem> items) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    final providerName = items.first.providerName;
    final providerSubtotal = getProviderSubtotal(providerId);
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // هيدر المقدم
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark 
                        ? [ThemeConfig.kGoldNight, ThemeConfig.kGoldNight.withOpacity(.8)]
                        : [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.store, color: isDark ? ThemeConfig.kNightDeep : Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    providerName,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimaryColor,
                    ),
                  ),
                ),
                Text(
                  '${providerSubtotal.toStringAsFixed(0)} ر.س',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            // عناصر السلة للمقدم
            ...items.map((item) => _buildDynamicCartItem(providerId, item)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicCartItem(int providerId, CartItem item) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? ThemeConfig.kNightAccent.withOpacity(.3) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.productName,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimaryColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _cartManager.removeFromCart(providerId, item.id),
                icon: Icon(Icons.delete_outline, color: Colors.red, size: 20),
              ),
            ],
          ),
          
          // الإضافات المختارة
          if (item.addons.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              'الإضافات: ${item.selectedAddonsList.join(', ')}',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          
          // ملاحظات
          if (item.notes.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              'ملاحظة: ${item.notes}',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: isDark ? Colors.blue.shade300 : Colors.blue.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          
          SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // أزرار الكمية
              Row(
                children: [
                  IconButton(
                    onPressed: () => _cartManager.updateQuantity(providerId, item.id, item.quantity - 1),
                    icon: Icon(Icons.remove_circle_outline, size: 20, color: theme.textPrimaryColor),
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.borderColor),
                    ),
                    child: Text(
                      '${item.quantity}',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _cartManager.updateQuantity(providerId, item.id, item.quantity + 1),
                    icon: Icon(Icons.add_circle_outline, size: 20, color: theme.textPrimaryColor),
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              
              // السعر
              Text(
                '${(item.totalPrice / 100).toStringAsFixed(0)} ر.س',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryPickupOptions() {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.borderColor),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981)),
                SizedBox(width: 8),
                Text(
                  'طريقة الحصول على الطلب',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // خيارات التوصيل والاستلام
            Row(
              children: [
                // خيار التوصيل
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _deliveryMethod = 'delivery';
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _deliveryMethod == 'delivery' 
                          ? Color(0xFF10B981).withOpacity(0.1)
                          : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _deliveryMethod == 'delivery' 
                            ? Color(0xFF10B981) 
                            : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.delivery_dining,
                            color: _deliveryMethod == 'delivery' 
                              ? Color(0xFF10B981) 
                              : Colors.grey.shade600,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'توصيل',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _deliveryMethod == 'delivery' 
                                ? Color(0xFF10B981) 
                                : Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            'عبر التطبيقات',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: 12),
                
                // خيار الاستلام
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _deliveryMethod = 'pickup';
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _deliveryMethod == 'pickup' 
                          ? Color(0xFF10B981).withOpacity(0.1)
                          : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _deliveryMethod == 'pickup' 
                            ? Color(0xFF10B981) 
                            : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.storefront,
                            color: _deliveryMethod == 'pickup' 
                              ? Color(0xFF10B981) 
                              : Colors.grey.shade600,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'استلام',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _deliveryMethod == 'pickup' 
                                ? Color(0xFF10B981) 
                                : Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            'من المحل',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // عرض تطبيقات التوصيل عند اختيار التوصيل
            if (_deliveryMethod == 'delivery') ...[
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),
              Text(
                'تطبيقات التوصيل المتاحة',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              _buildDeliveryApps(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApplePayOption() {
    final isSelected = _cardType == 'applepay';
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _cardType = 'applepay';
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected 
            ? LinearGradient(
                colors: [
                  Colors.black,
                  Colors.grey.shade800,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  Colors.grey.shade100,
                  Colors.grey.shade200,
                ],
              ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
              offset: Offset(0, 5),
            ),
          ] : [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // شعار آبل
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.white.withOpacity(0.3) : Colors.grey.shade300,
                ),
              ),
              child: Center(
                child: Text(
                  '🍎',
                  style: TextStyle(fontSize: 28),
                ),
              ),
            ),
            SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Pay',
                        style: GoogleFonts.roboto(
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          color: isSelected ? Colors.white : Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(width: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.black,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '🍎',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'دفع سريع وآمن بضغطة واحدة',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            // أيقونة التأكيد أو السهم
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: isSelected 
                ? Container(
                    key: ValueKey('selected'),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  )
                : Icon(
                    key: ValueKey('unselected'),
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardDetailsForm() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getCardColor().withOpacity(0.05),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getCardColor().withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: _getCardColor().withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // هيدر البطاقة المميز
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_getCardColor(), _getCardColor().withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.credit_card,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بيانات ${_getCardTypeName()}',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getCardColor(),
                      ),
                    ),
                    Text(
                      'ادخل بيانات البطاقة بأمان',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // شعار نوع البطاقة
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCardColor(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getCardTypeName(),
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // محاكاة البطاقة البصرية
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getCardColor(),
                  _getCardColor().withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _getCardColor().withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 3,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // شعار البطاقة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getCardTypeName(),
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getCardIcon(),
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                  
                  Spacer(),
                  
                  // رقم البطاقة (محاكاة)
                  Text(
                    '•••• •••• •••• ••••',
                    style: GoogleFonts.robotoMono(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // تاريخ الانتهاء واسم الحامل
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'اسم الحامل',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          Text(
                            'YOUR NAME',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'صالحة حتى',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          Text(
                            'MM/YY',
                            style: GoogleFonts.robotoMono(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          
          // حقول الإدخال المحسنة
          _buildEnhancedTextField(
            label: 'رقم البطاقة',
            hint: '1234 5678 9012 3456',
            icon: Icons.credit_card,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
          
          // تاريخ الانتهاء و CVV
          Row(
            children: [
              Expanded(
                child: _buildEnhancedTextField(
                  label: 'تاريخ الانتهاء',
                  hint: 'MM/YY',
                  icon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedTextField(
                  label: 'CVV',
                  hint: '123',
                  icon: Icons.security,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // اسم حامل البطاقة
          _buildEnhancedTextField(
            label: 'اسم حامل البطاقة',
            hint: 'كما هو مكتوب على البطاقة',
            icon: Icons.person,
          ),
          
          SizedBox(height: 12),
          
          // ملاحظة أمان مبهرة
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF10B981).withOpacity(0.1),
                  Colors.green.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF10B981).withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF10B981).withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.verified_user, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔒 محمي بأعلى معايير الأمان',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'تشفير SSL 256-bit • معتمد PCI DSS',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.shield, color: Color(0xFF10B981), size: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCardColor() {
    switch (_cardType) {
      case 'visa':
        return Colors.blue;
      case 'mastercard':
        return Colors.red;
      case 'mada':
        return Colors.green;
      case 'applepay':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  String _getCardTypeName() {
    switch (_cardType) {
      case 'visa':
        return 'فيزا';
      case 'mastercard':
        return 'ماستركارد';
      case 'mada':
        return 'مدى';
      case 'applepay':
        return 'آبل باي';
      default:
        return 'البطاقة';
    }
  }

  String _getCardIcon() {
    switch (_cardType) {
      case 'visa':
        return '💳';
      case 'mastercard':
        return '💳';
      case 'mada':
        return '🏦';
      case 'applepay':
        return '🍎';
      default:
        return '💳';
    }
  }

  Widget _buildEnhancedTextField({
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _getCardColor().withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(
            fontSize: 14,
            color: _getCardColor(),
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          hintStyle: GoogleFonts.cairo(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_getCardColor(), _getCardColor().withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _getCardColor().withOpacity(0.3), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _getCardColor(), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
      ),
    );
  }

  String _getPaymentMethodText() {
    if (_paymentMethod == 'cash') {
      return 'نقدي';
    } else {
      switch (_cardType) {
        case 'visa':
          return 'بطاقة فيزا';
        case 'mastercard':
          return 'بطاقة ماستركارد';
        case 'mada':
          return 'بطاقة مدى';
        case 'applepay':
          return 'آبل باي';
        default:
          return 'بطاقة';
      }
    }
  }

  Widget _buildDeliveryApps() {
    // قائمة تطبيقات التوصيل الافتراضية
    final deliveryApps = [
      {
        'name': 'جاهز',
        'icon': '🚗',
        'description': 'توصيل سريع خلال 30 دقيقة',
        'url': 'https://jahez.sa'
      },
      {
        'name': 'هنقرستيشن',
        'icon': '🍽️',
        'description': 'توصيل موثوق مع خيارات دفع متعددة',
        'url': 'https://hungerstation.com'
      },
      {
        'name': 'طلبات',
        'icon': '📱',
        'description': 'خدمة توصيل عالمية',
        'url': 'https://talabat.com'
      },
    ];

    return Column(
      children: deliveryApps.map((app) {
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  app['icon']!,
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            title: Text(
              app['name']!,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              app['description']!,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            trailing: Icon(Icons.open_in_new, color: Color(0xFF10B981)),
            onTap: () {
              // فتح التطبيق أو الموقع
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'سيتم توجيهك لتطبيق ${app['name']}',
                    style: GoogleFonts.cairo(),
                  ),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGrandOrderSummary() {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    final carts = activeProviderCarts;
    
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.borderColor),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ملخص الطلب الإجمالي',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textPrimaryColor,
              ),
            ),
            SizedBox(height: 12),
            
            // تفاصيل كل مقدم
            ...carts.entries.map((entry) {
              final providerId = entry.key;
              final items = entry.value;
              final providerSubtotal = getProviderSubtotal(providerId);
              
              return Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      items.first.providerName,
                      style: GoogleFonts.cairo(fontSize: 14, color: theme.textPrimaryColor),
                    ),
                    Text(
                      '${providerSubtotal.toStringAsFixed(0)} ر.س',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: theme.textPrimaryColor),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            
            Divider(height: 24, color: theme.borderColor),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الإجمالي النهائي',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimaryColor,
                  ),
                ),
                Text(
                  '${grandTotal.toStringAsFixed(0)} ر.س',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutButton() {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _checkout,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
            foregroundColor: isDark ? ThemeConfig.kNightDeep : Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag),
              SizedBox(width: 8),
              Text(
                'إتمام الطلب - ${grandTotal.toStringAsFixed(0)} ر.س',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // هذه الدوال لم تعد مطلوبة - تم استبدالها بـ CartManager

  void _checkout() async {
    // التحقق من صحة البيانات والتوجه حسب نوع الطلب
    if (_deliveryMethod == 'delivery') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى اختيار تطبيق التوصيل من القائمة أعلاه',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    } else if (_deliveryMethod == 'pickup') {
      // إذا كان المستخدم مسجل دخول، احفظ الطلب مباشرة من بيانات الحساب
      final auth = AuthState.instance;
      if (auth.isLoggedIn && (auth.userName?.isNotEmpty ?? false) && (auth.phone?.isNotEmpty ?? false)) {
        await _savePickupOrderFromProfile();
        return;
      }
      // خلاف ذلك، اطلب البيانات يدويًا
      _showPickupOrderDialog();
      return;
    }

    // معالجة الطلب
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'تأكيد الطلب',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'المجموع: ${grandTotal.toStringAsFixed(0)} ر.س',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            Text(
              'طريقة الدفع: ${_getPaymentMethodText()}',
              style: GoogleFonts.cairo(),
            ),
            Text(
              'الاستلام: ${_deliveryMethod == 'delivery' ? 'توصيل' : 'من المحل'}',
              style: GoogleFonts.cairo(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _processOrder();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF10B981),
              ),
              child: Text(
                'تأكيد',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showPickupOrderDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'بيانات طلب الاستلام',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'اسم العميل',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: GoogleFonts.cairo(),
              ),
              SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'رقم الجوال',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: GoogleFonts.cairo(),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: GoogleFonts.cairo(),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty || 
                  phoneController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'يرجى ملء جميع البيانات المطلوبة',
                      style: GoogleFonts.cairo(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              _processPickupOrder(
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                notes: notesController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF10B981),
            ),
            child: Text(
              'تأكيد الطلب',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processPickupOrder({
    required String name,
    required String phone,
    required String notes,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'جاري معالجة طلب الاستلام...',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
            SizedBox(height: 16),
            Text(
              'يرجى الانتظار',
              style: GoogleFonts.cairo(),
            ),
          ],
        ),
      ),
    );

    // محاكاة معالجة الطلب
    Future.delayed(Duration(seconds: 2), () async {
      Navigator.of(context).pop(); // إغلاق مربع الحوار
      
      // مسح السلة بعد نجاح الطلب
      _cartManager.clearAllCarts();
      
      // إنشاء طلب وحفظه محلياً
      await _savePickupOrder(
        customerName: name,
        customerPhone: phone,
        notes: notes,
      );
      NotificationsService.instance.toast('تم إرسال طلب الاستلام بنجاح', icon: Icons.check_circle, color: const Color(0xFF10B981), top: false);
      
      // العودة للصفحة السابقة
      Navigator.of(context).pop();
    });
  }

  void _processOrder() {
    // محاكاة معالجة الطلب
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'جاري معالجة الطلب...',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'يرجى الانتظار',
              style: GoogleFonts.cairo(),
            ),
          ],
        ),
      ),
    );

    // محاكاة تأخير المعالجة
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pop(context); // إغلاق مودال التحميل
      
      // عرض رسالة النجاح
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 8),
              Text(
                'تم الطلب بنجاح!',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'رقم الطلب: #DLM${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'سيتم التواصل معك خلال 10 دقائق لتأكيد الطلب',
                style: GoogleFonts.cairo(),
              ),
              SizedBox(height: 8),
              Text(
                'وقت التوصيل المتوقع: 30-45 دقيقة',
                style: GoogleFonts.cairo(color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // إغلاق مودال النجاح
                Navigator.pop(context); // العودة للصفحة السابقة
                setState(() {
                  _cartManager.clearAllCarts(); // إفراغ جميع السلال
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF10B981),
              ),
              child: Text(
                'حسناً',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _savePickupOrderFromProfile() async {
    final auth = AuthState.instance;
    final name = auth.userName?.trim() ?? '';
    final phone = auth.phone?.trim() ?? '';
    if (name.isEmpty || phone.isEmpty) {
      _showPickupOrderDialog();
      return;
    }
    // عرض معالجة سريعة ثم الحفظ
    _processPickupOrder(name: name, phone: phone, notes: '');
  }

  Future<void> _savePickupOrder({
    required String customerName,
    required String customerPhone,
    String notes = '',
  }) async {
    final carts = activeProviderCarts;
    if (carts.isEmpty) return;
    final now = DateTime.now();
    for (final entry in carts.entries) {
      final providerId = entry.key;
      final items = entry.value;
      if (items.isEmpty) continue;
      final providerName = items.first.providerName;
      final subtotal = getProviderSubtotal(providerId);
      final orderId = DateTime.now().microsecondsSinceEpoch;
      final orderNumber = 'DLM-${now.year}${now.month.toString().padLeft(2,'0')}-${orderId.toString().substring(orderId.toString().length - 4)}';
      final order = <String, dynamic>{
        'id': orderId,
        'orderNumber': orderNumber,
        'service': providerName,
        'items': items.map((e) => e.productName).toList(),
        'status': 'جاري المعالجة',
        'statusType': 'preparing',
        'total': subtotal.toStringAsFixed(2),
        'totalDisplay': '${subtotal.toStringAsFixed(0)} ريال',
        'date': 'اليوم ${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}',
        'estimatedTime': 'جاهز خلال 15-25 دقيقة',
        'icon': '🛍️',
        'needsPayment': false,
        'providerPhone': '',
        'progress': 10,
        'priority': 'متوسطة',
        'deliveryMethod': 'pickup',
        'customerName': customerName,
        'customerPhone': customerPhone,
        'notes': notes,
      };
      await OrdersService.instance.addOrder(order);
    }
  }
}
