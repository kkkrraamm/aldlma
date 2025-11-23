# 🚀 دليل التكامل - ProviderDashboardNew

## 📌 نقاط التكامل الرئيسية

### 1️⃣ استيراد الملف في main.dart
```dart
import 'provider_dashboard_new.dart';
```

### 2️⃣ إضافة الـ Route في التطبيق
يمكنك إضافة الـ route بطريقتين:

#### الطريقة الأولى: Named Route
```dart
// في main.dart - في MaterialApp
routes: {
  '/provider-dashboard': (context) => const ProviderDashboardNew(),
},
```

#### الطريقة الثانية: Direct Navigation
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ProviderDashboardNew(),
  ),
);
```

### 3️⃣ مثال على الاستخدام في صفحة الحساب
```dart
// في my_account_oasis.dart أو مكان آخر

// الزر الذي يفتح الـ Dashboard
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProviderDashboardNew(),
      ),
    );
  },
  child: const Text('لوحة التحكم'),
)
```

### 4️⃣ الربط مع حالة المتجر
يمكنك التحقق من حالة المتجر قبل فتح الـ Dashboard:

```dart
// التحقق من حالة المتجر
if (_providerRequest != null && _providerRequest!['status'] == 'approved') {
  // المتجر موافق عليه - يمكن فتح الـ Dashboard
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ProviderDashboardNew(),
    ),
  );
} else {
  // المتجر لم يتم الموافقة عليه بعد
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('يرجى الانتظار حتى يتم الموافقة على طلبك')),
  );
}
```

## 🔌 معالجة الأخطاء

### عدم وجود Token
```dart
if (_token == null) {
  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  return;
}
```

### فشل تحميل البيانات
```dart
try {
  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/provider/store'),
    headers: {
      'Authorization': 'Bearer $_token',
      'Content-Type': 'application/json',
    },
  ).timeout(const Duration(seconds: 10));

  if (response.statusCode == 404) {
    // المتجر غير موجود
    _showNoStoreDialog(context);
  } else if (response.statusCode == 403) {
    // المستخدم ليس مزودًا للخدمة
    _showNotProviderDialog(context);
  }
} on TimeoutException catch (_) {
  NotificationsService.instance.toast('انتهت المهلة الزمنية - تحقق من الإنترنت');
} catch (e) {
  print('❌ خطأ: $e');
}
```

## 🎯 سير العمل الكامل

```
┌─────────────────────────────────────┐
│     صفحة الحساب (My Account)        │
├─────────────────────────────────────┤
│  ✓ التحقق من حالة الطلب            │
│  ✓ إذا كان مقبولاً: أظهر الزر       │
│  ✓ الضغط على زر "لوحة التحكم"       │
│       ↓                              │
├─────────────────────────────────────┤
│    ProviderDashboardNew Opens        │
├─────────────────────────────────────┤
│  1. LoadStoreData()                 │
│     - جلب التوكن من SharedPreferences│
│     - استدعاء API: /provider/store  │
│     - معالجة الاستجابة              │
│  2. البيانات تحمل                   │
│     - عرض Header مع صورة المتجر     │
│     - عرض بطاقات الإحصائيات        │
│     - عرض الإجراءات السريعة         │
│  3. اختيار التبويب                  │
│     - Home (الرئيسية)               │
│     - Products (المنتجات)          │
│     - Videos (الفيديوهات)           │
│     - Analytics (الإحصائيات)        │
│     - Settings (الإعدادات)          │
└─────────────────────────────────────┘
```

## 📊 البيانات المتوقعة من API

```json
GET /provider/store
Authorization: Bearer <token>

Response:
{
  "store": {
    "id": 123,
    "store_name": "متجري الجميل",
    "store_logo": "https://...",
    "rating": 4.5,
    "followers_count": 2340,
    "total_sales": 5000,
    "products_count": 12,
    "videos_count": 8,
    "is_verified": true,
    "description": "وصف المتجر"
  },
  "products": [
    {
      "id": 1,
      "name_ar": "منتج جميل",
      "description": "وصف المنتج",
      "price": 99.99,
      "image": "https://..."
    }
  ],
  "videos": [
    {
      "id": 1,
      "title": "فيديو جميل",
      "views_count": 1500,
      "thumbnail": "https://..."
    }
  ]
}
```

## 🛠️ التخصيص والتعديل

### تغيير الألوان
```dart
// في theme_config.dart
class ThemeConfig {
  static const Color kGreen = Color(0xFF1ABF7A);
  static const Color kGoldNight = Color(0xFFD4A574);
  static const Color kNightDeep = Color(0xFF1A1A1A);
  // إضافة ألوانك هنا
}
```

### تغيير الخط
```dart
// استبدل Cairo بخطك المفضل
style: GoogleFonts.cairo(
  fontSize: 20,
  fontWeight: FontWeight.w900,
),

// أو استخدم خط محلي
style: TextStyle(
  fontFamily: 'Cairo',
  fontSize: 20,
  fontWeight: FontWeight.w900,
),
```

### تعديل الأيقونات
```dart
// في bottom navigation bar
icons: const [
  Icons.home_rounded,         // غيّر الأيقونات كما تريد
  Icons.inventory_rounded,
  Icons.videocam_rounded,
  Icons.analytics_rounded,
  Icons.settings_rounded,
],
```

## 🔄 تحديث البيانات

### إعادة تحميل البيانات
```dart
// في أي مكان داخل الـ State
_loadStoreData();  // سيعيد تحميل جميع البيانات

// أو استخدم الـ Pull to Refresh
RefreshIndicator(
  onRefresh: () async {
    await _loadStoreData();
  },
  child: // your widget
)
```

## ⚡ الأداء والتحسينات

### 1. Lazy Loading
```dart
// بدلاً من تحميل كل شيء مرة واحدة
// حمّل البيانات حسب الحاجة
if (_products == null) {
  _loadProducts();
}
```

### 2. Caching
```dart
// احفظ البيانات في SharedPreferences
final prefs = await SharedPreferences.getInstance();
await prefs.setString('cached_store_data', jsonEncode(_storeData));
```

### 3. Pagination
```dart
// للمنتجات والفيديوهات الكثيرة
// استخدم pagination للحد من الحمل
final response = await http.get(
  Uri.parse('${ApiConfig.baseUrl}/provider/store?page=1&limit=20'),
  headers: headers,
);
```

## 🐛 استكشاف المشاكل

### المشكلة: البيانات لا تظهر
**الحل:**
1. تأكد من وجود التوكن: `flutter pub global run logger`
2. تحقق من الـ API endpoint: `curl -H "Authorization: Bearer <token>" https://api.example.com/provider/store`
3. تفعيل DevTools: `flutter pub global activate devtools && devtools`

### المشكلة: الأيقونات لا تظهر بشكل صحيح
**الحل:**
1. تأكد من `flutter pub get`
2. أعد تشغيل التطبيق: `flutter run`
3. نظّف البناء: `flutter clean && flutter pub get`

### المشكلة: Timeout في جلب البيانات
**الحل:**
1. تحقق من سرعة الإنترنت
2. زد مدة الـ Timeout:
```dart
const Duration(seconds: 15)  // بدلاً من 10
```

## 📝 Next Steps

بعد الربط الناجح، يمكنك:

- [ ] تنفيذ ميزة إضافة المنتجات
- [ ] تنفيذ رفع الفيديوهات
- [ ] ربط نظام الإشعارات
- [ ] إضافة صفحة الترويجات
- [ ] تحسين الإحصائيات
- [ ] إضافة نظام التصفية والبحث

---

**تم التطوير بواسطة:** فريق الدلما 🎨
**آخر تحديث:** 23 نوفمبر 2025
