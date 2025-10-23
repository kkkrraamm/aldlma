# 📖 دليل شامل لصفحة البروفايل الموحدة
## UnifiedProviderProfile - الدليل الكامل

---

## 📋 **جدول المحتويات**

1. [نظرة عامة](#نظرة-عامة)
2. [الهيكل العام](#الهيكل-العام)
3. [إدارة الحالة (State Management)](#إدارة-الحالة)
4. [قاعدة البيانات (Provider Data)](#قاعدة-البيانات)
5. [المكونات الرئيسية (Main Components)](#المكونات-الرئيسية)
6. [نظام الحجز (Booking System)](#نظام-الحجز)
7. [نظام السلة (Cart System)](#نظام-السلة)
8. [الرسوم المتحركة (Animations)](#الرسوم-المتحركة)
9. [التكامل مع الثيم (Theme Integration)](#التكامل-مع-الثيم)
10. [خيارات التوصيل (Delivery Options)](#خيارات-التوصيل)

---

## 🎯 **نظرة عامة**

### **الهدف من الصفحة:**
صفحة بروفايل موحدة وفاخرة لعرض معلومات مقدمي الخدمات (مطاعم، صالونات، ورش صيانة، إلخ) مع إمكانية:
- عرض المنتجات/الخدمات
- إضافة للسلة
- الحجز المباشر
- التواصل عبر قنوات متعددة
- الطلب عبر تطبيقات التوصيل

### **الملفات المرتبطة:**
```
lib/
  ├── unified_provider_profile.dart  ← الملف الرئيسي
  ├── cart_manager.dart              ← إدارة السلة
  ├── advanced_booking_calendar.dart ← تقويم الحجز
  ├── cart_page.dart                 ← صفحة السلة
  ├── theme_config.dart              ← إعدادات الثيم
  └── notifications.dart             ← الإشعارات
```

---

## 🏗️ **الهيكل العام**

### **1. الكلاس الرئيسي:**

```dart
class UnifiedProviderProfile extends StatefulWidget {
  final int providerId;  // معرف المزود (1, 2, 3, ...)
  
  const UnifiedProviderProfile({Key? key, required this.providerId});
}
```

**المعاملات:**
- `providerId` (int): المعرف الفريد للمزود، يُستخدم لجلب البيانات من `providerData`

---

## 📊 **إدارة الحالة (State Management)**

### **المتغيرات الرئيسية:**

```dart
class _UnifiedProviderProfileState extends State<UnifiedProviderProfile> 
    with TickerProviderStateMixin {
  
  // 1. متحكمات الرسوم المتحركة
  late AnimationController _fadeController;    // تأثير الظهور التدريجي
  late AnimationController _slideController;   // تأثير الانزلاق
  late TabController _tabController;           // التبويبات (الخدمات، المقبلات، إلخ)
  
  // 2. الرسوم المتحركة
  late Animation<double> _fadeAnimation;       // من 0.0 إلى 1.0
  late Animation<Offset> _slideAnimation;      // من (0, 0.3) إلى (0, 0)
  
  // 3. حالة الحجز
  bool _showBookingForm = false;               // هل نموذج الحجز ظاهر؟
  Map<String, dynamic>? _selectedProduct;      // المنتج المختار للحجز
  String _activeTab = '';                      // التبويب النشط حالياً
  
  // 4. إدارة الإضافات
  Map<int, int> _selectedAddons = {};          // {addonId: quantity}
  
  // 5. مدير السلة
  final CartManager _cartManager = CartManager();
  
  // 6. بيانات نموذج الحجز
  final _bookingForm = {
    'customerName': '',
    'customerPhone': '',
    'scheduledDate': '',
    'notes': '',
  };
}
```

### **دورة الحياة (Lifecycle):**

```dart
@override
void initState() {
  super.initState();
  
  // 1. جلب بيانات المزود
  final provider = providerData;
  final tabs = provider['tabs'] as List<String>? ?? ['الخدمات'];
  
  // 2. إعداد التبويبات
  _tabController = TabController(length: tabs.length, vsync: this);
  _activeTab = tabs.first;
  
  // 3. إعداد الرسوم المتحركة
  _fadeController = AnimationController(duration: Duration(milliseconds: 800), vsync: this);
  _slideController = AnimationController(duration: Duration(milliseconds: 600), vsync: this);
  
  _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(...);
  _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(...);
  
  // 4. بدء الرسوم المتحركة
  _fadeController.forward();
  _slideController.forward();
}

@override
void dispose() {
  _fadeController.dispose();
  _slideController.dispose();
  _tabController.dispose();
  super.dispose();
}
```

---

## 🗄️ **قاعدة البيانات (Provider Data)**

### **الهيكل الكامل:**

```dart
Map<String, dynamic> get providerData {
  final providers = {
    1: {  // ← معرف المزود
      // معلومات أساسية
      'id': 1,
      'businessName': 'مطعم الدلما التراثي',
      'businessDescription': 'نقدم أطباق سعودية تراثية...',
      'category': 'مطاعم',  // مطاعم، صالونات، ورش صيانة، ...
      
      // الصور والشعار
      'coverImage': null,  // صورة الغلاف (اختياري)
      'logo': '🍽️',        // الشعار (emoji أو مسار صورة)
      
      // معلومات الاتصال
      'phone': '+966501234567',
      'website': 'www.dalma-restaurant.com',
      'address': 'حي النزهة، شارع الملك فهد، عرعر',
      
      // التقييمات
      'rating': 4.8,          // من 5
      'totalReviews': 127,    // عدد التقييمات
      'isVerified': true,     // موثق؟
      
      // أوقات العمل والتخصصات
      'workingHours': 'السبت - الخميس: 6:00 ص - 12:00 ص',
      'specialties': ['كبسة', 'مندي', 'مظبي', 'حنيذ'],
      
      // خيارات التوصيل
      'deliveryOptions': {
        'hasDelivery': true,     // يوفر توصيل؟
        'hasPickup': true,       // يوفر استلام؟
        
        // تطبيقات التوصيل
        'deliveryApps': [
          {
            'name': 'جاهز',
            'url': 'https://jahez.sa/restaurant/dalma-traditional',
            'icon': '🚗',
            'description': 'توصيل سريع خلال 30 دقيقة'
          },
          // ... المزيد
        ],
        
        // طرق الاتصال المباشر
        'contactMethods': [
          {
            'type': 'phone',
            'value': '+966501234567',
            'label': 'اتصال مباشر',
            'icon': '📞'
          },
          {
            'type': 'whatsapp',
            'value': '+966501234567',
            'label': 'واتساب',
            'icon': '💬'
          }
        ]
      },
      
      // التبويبات
      'tabs': ['الأطباق الرئيسية', 'المقبلات', 'الشوربات', ...],
      
      // المنتجات/الخدمات
      'products': [
        {
          'id': 1,
          'name': 'كبسة لحم الدلما الملكية',
          'description': 'كبسة لحم خروف طازج...',
          'price': 4500,  // بالهللات (45 ريال)
          
          // الأذونات
          'allowOrder': true,      // يمكن الطلب؟
          'allowBooking': false,   // يمكن الحجز؟
          
          // التصنيف والشعبية
          'category': 'الأطباق الرئيسية',
          'isPopular': true,
          
          // معلومات إضافية
          'preparationTime': '25-30 دقيقة',
          'detailedDescription': '...',
          'calories': 650,
          'spicyLevel': 'متوسط',
          
          // الإضافات (Addons)
          'addons': [
            {
              'id': 1,
              'name': 'لحم إضافي',
              'description': 'قطعة لحم خروف إضافية',
              'price': 1500,
              'category': 'إضافات اللحوم',
              'isRequired': false,
              'maxQuantity': 2,
              'minQuantity': 0
            },
            // ... المزيد
          ]
        },
        // ... المزيد من المنتجات
      ]
    },
    2: { ... },  // مزود آخر
    3: { ... },  // مزود آخر
  };
  
  return providers[widget.providerId] ?? _getDefaultProvider();
}
```

### **المزودون المتاحون:**

| ID | الاسم | الفئة | المنتجات | التوصيل |
|----|-------|------|----------|---------|
| 1 | مطعم الدلما التراثي | مطاعم | 5 أطباق | ✅ |
| 2 | ورشة الماهر للصيانة | صيانة | 0 خدمات | ❌ |
| 3 | صالون النجوم للتجميل | تجميل | 0 خدمات | ❌ |

---

## 🧩 **المكونات الرئيسية (Main Components)**

### **1. الهيكل الرئيسي (Main Build):**

```dart
Widget build(BuildContext context) {
  return AnimatedBuilder(
    animation: theme,
    builder: (context, child) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,  // ديناميكي
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                _buildLuxuryCoverHeader(provider),    // 1. الهيدر الفاخر
                _buildActionButtons(provider),        // 2. أزرار الإجراءات
                _buildExperienceBar(provider),        // 3. شريط الخبرة
                _buildTabBar(provider),               // 4. التبويبات
                _buildProductsList(products),         // 5. قائمة المنتجات
              ],
            ),
            
            // مودال الحجز (إذا كان ظاهراً)
            if (_showBookingForm && _selectedProduct != null)
              _buildLuxuryBookingModal(),
            
            // السلة الثابتة أسفل الشاشة
            _buildFloatingCart(),
          ],
        ),
      );
    },
  );
}
```

### **2. الهيدر الفاخر (_buildLuxuryCoverHeader):**

**الوظيفة:** عرض غلاف فاخر مع:
- صورة الغلاف (أو تدرج لوني)
- الشعار/Logo
- اسم المزود
- التقييم وعدد التقييمات
- شارة التوثيق
- أزرار المشاركة والحفظ والرجوع

**الكود:**
```dart
SliverAppBar(
  expandedHeight: 300,
  pinned: true,
  flexibleSpace: FlexibleSpaceBar(
    background: Stack(
      children: [
        // خلفية متدرجة
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
          ),
        ),
        
        // الشعار
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // Logo دائري
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(provider['logo'], fontSize: 40),
                ),
              ),
              
              // اسم المزود
              Text(
                provider['businessName'],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              // التقييم
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber),
                  Text('${provider['rating']}'),
                  Text('(${provider['totalReviews']} تقييم)'),
                ],
              ),
            ],
          ),
        ),
        
        // أزرار الإجراءات (مشاركة، حفظ، رجوع)
        Positioned(
          top: 50,
          child: Row(
            children: [
              _IconButton(Icons.arrow_back),  // رجوع
              Spacer(),
              _IconButton(Icons.share),       // مشاركة
              _IconButton(Icons.favorite),    // حفظ
            ],
          ),
        ),
      ],
    ),
  ),
)
```

### **3. أزرار الإجراءات (_buildActionButtons):**

**الوظيفة:** عرض أزرار للتواصل السريع:
- اتصال
- واتساب
- موقع إلكتروني

```dart
SliverToBoxAdapter(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Row(
      children: [
        _ActionButton(
          icon: Icons.phone,
          label: 'اتصال',
          onTap: () => _makePhoneCall(provider['phone']),
        ),
        _ActionButton(
          icon: Icons.chat,
          label: 'واتساب',
          onTap: () => _openWhatsApp(provider['phone']),
        ),
        _ActionButton(
          icon: Icons.language,
          label: 'الموقع',
          onTap: () => _openWebsite(provider['website']),
        ),
      ],
    ),
  ),
)
```

### **4. شريط الخبرة (_buildExperienceBar):**

**الوظيفة:** عرض معلومات سريعة:
- أوقات العمل
- التخصصات
- الموقع

```dart
Container(
  padding: EdgeInsets.all(16),
  child: Column(
    children: [
      _InfoRow(
        icon: Icons.access_time,
        title: 'أوقات العمل',
        value: provider['workingHours'],
      ),
      _InfoRow(
        icon: Icons.location_on,
        title: 'العنوان',
        value: provider['address'],
      ),
      _ChipsRow(
        title: 'التخصصات',
        items: provider['specialties'],
      ),
    ],
  ),
)
```

### **5. التبويبات (_buildTabBar):**

**الوظيفة:** عرض تبويبات لتصنيف المنتجات

```dart
SliverPersistentHeader(
  pinned: true,
  delegate: _StickyTabBarDelegate(
    TabBar(
      controller: _tabController,
      tabs: tabs.map((tab) => Tab(text: tab)).toList(),
      onTap: (index) {
        setState(() => _activeTab = tabs[index]);
      },
    ),
  ),
)
```

### **6. قائمة المنتجات (_buildProductsList):**

**الوظيفة:** عرض المنتجات في بطاقات فاخرة

**كل بطاقة تحتوي على:**
- صورة المنتج (أو أيقونة)
- الاسم والوصف
- السعر
- شارة "الأكثر طلباً" (إذا `isPopular: true`)
- زر "طلب" أو "حجز"
- أيقونة "إضافة للمفضلة"

```dart
SliverList(
  delegate: SliverChildBuilderDelegate(
    (context, index) {
      final product = products[index];
      return _ProductCard(
        product: product,
        onOrder: () => _addToCart(product),
        onBook: () => _showBooking(product),
      );
    },
    childCount: products.length,
  ),
)
```

---

## 📅 **نظام الحجز (Booking System)**

### **كيف يعمل؟**

1. المستخدم يضغط على زر "حجز" في بطاقة المنتج
2. يظهر مودال فاخر (`_buildLuxuryBookingModal`)
3. المستخدم يملأ:
   - الاسم
   - رقم الجوال
   - التاريخ (من تقويم متقدم)
   - ملاحظات إضافية
4. يضغط "تأكيد الحجز"
5. يتم إرسال إشعار نجاح

### **الكود:**

```dart
void _showBooking(Map<String, dynamic> product) {
  setState(() {
    _selectedProduct = product;
    _showBookingForm = true;
  });
}

Widget _buildLuxuryBookingModal() {
  return Positioned.fill(
    child: GestureDetector(
      onTap: () => setState(() => _showBookingForm = false),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            margin: EdgeInsets.all(24),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // معلومات المنتج
                Text(_selectedProduct!['name']),
                Text('${_selectedProduct!['price'] / 100} ريال'),
                
                // نموذج الحجز
                TextField(
                  decoration: InputDecoration(labelText: 'الاسم'),
                  onChanged: (v) => _bookingForm['customerName'] = v,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'رقم الجوال'),
                  onChanged: (v) => _bookingForm['customerPhone'] = v,
                ),
                
                // اختيار التاريخ
                ElevatedButton(
                  onPressed: _pickDate,
                  child: Text('اختر التاريخ'),
                ),
                
                // تأكيد
                ElevatedButton(
                  onPressed: _confirmBooking,
                  child: Text('تأكيد الحجز'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void _confirmBooking() {
  // إرسال الحجز للسيرفر
  NotificationsService.instance.toast(
    'تم الحجز بنجاح!',
    icon: Icons.check_circle,
    color: Colors.green,
  );
  
  setState(() {
    _showBookingForm = false;
    _selectedProduct = null;
  });
}
```

---

## 🛒 **نظام السلة (Cart System)**

### **كيف يعمل؟**

1. المستخدم يضغط على زر "طلب"
2. يظهر Bottom Sheet لاختيار الإضافات
3. المستخدم يختار الكمية والإضافات
4. يضغط "إضافة للسلة"
5. يظهر زر السلة الثابت أسفل الشاشة
6. المستخدم يضغط على السلة → ينتقل لصفحة السلة

### **الكود:**

```dart
void _addToCart(Map<String, dynamic> product) {
  _showAddonsSheet(product);
}

void _showAddonsSheet(Map<String, dynamic> product) {
  showModalBottomSheet(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              // معلومات المنتج
              Text(product['name']),
              
              // قائمة الإضافات
              ...product['addons'].map((addon) {
                return CheckboxListTile(
                  title: Text(addon['name']),
                  subtitle: Text('${addon['price'] / 100} ريال'),
                  value: _selectedAddons.containsKey(addon['id']),
                  onChanged: (checked) {
                    setModalState(() {
                      if (checked!) {
                        _selectedAddons[addon['id']] = 1;
                      } else {
                        _selectedAddons.remove(addon['id']);
                      }
                    });
                  },
                );
              }),
              
              // زر الإضافة
              ElevatedButton(
                onPressed: () {
                  _cartManager.addItem(
                    widget.providerId,
                    product,
                    _selectedAddons,
                  );
                  Navigator.pop(context);
                  NotificationsService.instance.toast('تمت الإضافة للسلة!');
                },
                child: Text('إضافة للسلة'),
              ),
            ],
          ),
        );
      },
    ),
  );
}

// السلة الثابتة أسفل الشاشة
Widget _buildFloatingCart() {
  final cartItems = _cartManager.getProviderCart(widget.providerId);
  final totalPrice = _cartManager.getProviderCartTotal(widget.providerId);
  
  if (cartItems.isEmpty) return SizedBox.shrink();
  
  return Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => CartPage(providerId: widget.providerId),
      )),
      child: Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.shopping_bag, color: Colors.white),
            Text('${cartItems.length} عناصر', style: TextStyle(color: Colors.white)),
            Spacer(),
            Text('${totalPrice / 100} ريال', style: TextStyle(color: Colors.white)),
            Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    ),
  );
}
```

---

## 🎨 **الرسوم المتحركة (Animations)**

### **الأنواع المستخدمة:**

1. **Fade Animation** (الظهور التدريجي):
   ```dart
   _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
     CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
   );
   ```
   - المدة: 800ms
   - الاستخدام: لإظهار البطاقات تدريجياً

2. **Slide Animation** (الانزلاق):
   ```dart
   _slideAnimation = Tween<Offset>(
     begin: Offset(0, 0.3),  // يبدأ 30% أسفل الموقع الأصلي
     end: Offset.zero,       // ينتهي في الموقع الأصلي
   ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));
   ```
   - المدة: 600ms
   - الاستخدام: لانزلاق العناصر من الأسفل

3. **AnimatedBuilder** (للثيم):
   ```dart
   AnimatedBuilder(
     animation: theme,
     builder: (context, child) {
       // يُعاد بناء الـ Widget تلقائياً عند تغيير الثيم
       return Scaffold(
         backgroundColor: theme.backgroundColor,
         ...
       );
     },
   )
   ```

---

## 🌓 **التكامل مع الثيم (Theme Integration)**

### **الألوان الديناميكية:**

```dart
final theme = ThemeConfig.instance;
final isDark = theme.isDarkMode;

// الخلفية
backgroundColor: theme.backgroundColor  // أبيض في النهاري، داكن في الليلي

// النصوص
color: theme.textPrimaryColor    // أسود في النهاري، أبيض في الليلي
color: theme.textSecondaryColor  // رمادي في كلا الوضعين

// البطاقات
color: theme.cardColor          // أبيض في النهاري، رمادي داكن في الليلي
border: theme.borderColor       // رمادي فاتح في النهاري، رمادي داكن في الليلي

// الأزرار
backgroundColor: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981)
```

### **الألوان المستخدمة:**

| الاسم | النهاري | الليلي |
|------|---------|--------|
| `backgroundColor` | `#FFFFFF` | `#0F172A` |
| `textPrimaryColor` | `#1F2937` | `#F9FAFB` |
| `textSecondaryColor` | `#6B7280` | `#9CA3AF` |
| `cardColor` | `#FFFFFF` | `#1E293B` |
| `borderColor` | `#E5E7EB` | `#334155` |
| `kGoldNight` | - | `#F59E0B` |

---

## 📦 **خيارات التوصيل (Delivery Options)**

### **الأنواع:**

1. **تطبيقات التوصيل** (`deliveryApps`):
   - جاهز
   - هنقرستيشن
   - طلبات
   
   **كل تطبيق يحتوي على:**
   - `name`: الاسم
   - `url`: الرابط
   - `icon`: الأيقونة (emoji)
   - `description`: الوصف

2. **طرق الاتصال المباشر** (`contactMethods`):
   - اتصال هاتفي
   - واتساب
   
   **كل طريقة تحتوي على:**
   - `type`: phone أو whatsapp
   - `value`: رقم الهاتف
   - `label`: التسمية
   - `icon`: الأيقونة (emoji)

### **كيف يتم عرضها؟**

```dart
// عرض تطبيقات التوصيل
if (provider['deliveryOptions']['hasDelivery']) {
  Column(
    children: provider['deliveryOptions']['deliveryApps'].map((app) {
      return ListTile(
        leading: Text(app['icon'], fontSize: 32),
        title: Text(app['name']),
        subtitle: Text(app['description']),
        trailing: Icon(Icons.arrow_forward),
        onTap: () => _openDeliveryApp(app['url']),
      );
    }).toList(),
  )
}

// عرض طرق الاتصال
Row(
  children: provider['deliveryOptions']['contactMethods'].map((method) {
    return ElevatedButton.icon(
      icon: Text(method['icon']),
      label: Text(method['label']),
      onTap: () {
        if (method['type'] == 'phone') {
          _makePhoneCall(method['value']);
        } else if (method['type'] == 'whatsapp') {
          _openWhatsApp(method['value']);
        }
      },
    );
  }).toList(),
)
```

---

## 🔧 **الدوال المساعدة (Helper Functions)**

### **1. الاتصال الهاتفي:**

```dart
Future<void> _makePhoneCall(String phone) async {
  final uri = Uri.parse('tel:$phone');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    NotificationsService.instance.toast('لا يمكن فتح تطبيق الهاتف');
  }
}
```

### **2. فتح واتساب:**

```dart
Future<void> _openWhatsApp(String phone) async {
  final cleanPhone = phone.replaceAll('+', '').replaceAll(' ', '');
  final uri = Uri.parse('https://wa.me/$cleanPhone');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    NotificationsService.instance.toast('لا يمكن فتح واتساب');
  }
}
```

### **3. فتح الموقع الإلكتروني:**

```dart
Future<void> _openWebsite(String website) async {
  final uri = Uri.parse('https://$website');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    NotificationsService.instance.toast('لا يمكن فتح المتصفح');
  }
}
```

### **4. فتح تطبيق توصيل:**

```dart
Future<void> _openDeliveryApp(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    NotificationsService.instance.toast('لا يمكن فتح التطبيق');
  }
}
```

---

## 📱 **أمثلة الاستخدام**

### **1. فتح بروفايل مطعم:**

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => UnifiedProviderProfile(providerId: 1),
  ),
);
```

### **2. فتح بروفايل ورشة صيانة:**

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => UnifiedProviderProfile(providerId: 2),
  ),
);
```

### **3. إضافة مزود جديد:**

```dart
// في قاعدة البيانات (providerData)
4: {
  'id': 4,
  'businessName': 'كافيه الدلما',
  'category': 'مقاهي',
  'tabs': ['القهوة الساخنة', 'القهوة الباردة', 'العصائر'],
  'products': [
    {
      'id': 1,
      'name': 'كابتشينو',
      'price': 1500,  // 15 ريال
      'allowOrder': true,
      'allowBooking': false,
      'category': 'القهوة الساخنة',
    },
  ],
}
```

---

## ⚠️ **ملاحظات مهمة**

### **1. الأسعار:**
- **جميع الأسعار بالهللات** (1 ريال = 100 هللة)
- مثال: `price: 4500` = 45 ريال
- للعرض: `${price / 100} ريال`

### **2. الإضافات (Addons):**
- يمكن أن تكون إجبارية (`isRequired: true`)
- لها حد أدنى وأقصى للكمية
- تُضاف لسعر المنتج الأساسي

### **3. الحجز vs الطلب:**
- `allowOrder: true` → يمكن إضافته للسلة
- `allowBooking: true` → يمكن حجز موعد له
- يمكن تفعيل كلاهما للمنتج الواحد

### **4. التبويبات:**
- يجب أن تكون `tabs` موجودة دائماً
- `_activeTab` يُستخدم لفلترة المنتجات
- `products` تُفلتر حسب `category`

---

## 🎯 **خطة تطبيق الثيم الديناميكي**

### **ما تم إنجازه:**
✅ `Scaffold.backgroundColor` → `theme.backgroundColor`
✅ `AnimatedBuilder` → للتفاعل مع تغييرات الثيم

### **ما يجب تطبيقه:**

1. **الهيدر (_buildLuxuryCoverHeader):**
   - [ ] الخلفية: من تدرج ثابت → `theme.headerGradient`
   - [ ] النصوص: من `Colors.white` → `theme.textPrimaryColor`

2. **أزرار الإجراءات:**
   - [ ] الخلفية: من `Colors.white` → `theme.cardColor`
   - [ ] الأيقونات: من `Colors.grey` → `theme.textSecondaryColor`

3. **بطاقات المنتجات:**
   - [ ] الخلفية: من `Colors.white` → `theme.cardColor`
   - [ ] النصوص: من `Colors.black` → `theme.textPrimaryColor`
   - [ ] الأسعار: من `Color(0xFF10B981)` → `isDark ? kGoldNight : Color(0xFF10B981)`

4. **مودال الحجز:**
   - [ ] الخلفية: من `Colors.white` → `theme.cardColor`
   - [ ] الحقول: من `Colors.grey[50]` → `isDark ? kNightAccent : Colors.grey[50]`

5. **السلة الثابتة:**
   - [ ] التدرج: من `[0xFF10B981, 0xFF059669]` → `isDark ? [kGoldNight, ...] : [0xFF10B981, ...]`

---

## 📚 **مراجع إضافية**

- `cart_manager.dart` - إدارة السلة
- `advanced_booking_calendar.dart` - تقويم الحجز المتقدم
- `theme_config.dart` - إعدادات الثيم الديناميكي
- `notifications.dart` - نظام الإشعارات

---

## ✅ **الخلاصة**

صفحة **UnifiedProviderProfile** هي صفحة شاملة وفاخرة لعرض معلومات المزودين مع:
- ✅ دعم أنواع متعددة (مطاعم، صيانة، تجميل، ...)
- ✅ نظام حجز متقدم
- ✅ نظام سلة مرن مع إضافات
- ✅ تكامل مع تطبيقات التوصيل
- ✅ رسوم متحركة فاخرة
- 🔄 **تطبيق الثيم الديناميكي (قيد التطوير)**

---

**تاريخ آخر تحديث:** 21 أكتوبر 2025
**الإصدار:** 2.0.0
**المطور:** فريق الدلما 🌿

