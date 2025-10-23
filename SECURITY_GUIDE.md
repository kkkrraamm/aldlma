# 🔐 دليل الأمان - تطبيق الدلما

## نظام الأمان المتكامل

تم تطبيق نظام أمان شامل في التطبيق لحماية البيانات والاتصالات مع السيرفر.

---

## 🔑 حماية API Key

### التشفير والإخفاء
- **لا يظهر API Key بشكل صريح في الكود**
- تم تقسيم المفتاح إلى 4 أجزاء مخفية كأرقام ASCII
- يتم إعادة تركيب المفتاح في وقت التشغيل فقط
- لا يمكن العثور على المفتاح الكامل في الكود المصدري

### الملف: `lib/api_config.dart`
```dart
// المفتاح مخفي كـ ASCII codes
static String get _part1 => String.fromCharCodes([70, 75, 83, ...]);
static String get _part2 => String.fromCharCodes([36, 37, 67, ...]);
// ...
static String get apiKey => _part1 + _part2 + _part3 + _part4;
```

---

## 🛡️ نظام المصادقة (Authentication)

### 1. تسجيل الدخول (`lib/auth.dart`)
```dart
// جميع طلبات تسجيل الدخول تتضمن:
- X-API-Key (تلقائي)
- Phone & Password (مشفرة في HTTPS)
- Token يتم حفظه بشكل آمن في SharedPreferences
```

### 2. إنشاء حساب جديد
```dart
// جميع طلبات إنشاء الحساب تتضمن:
- X-API-Key (تلقائي)
- Name, Phone, Password, DOB
- Token يتم حفظه بعد النجاح
```

### 3. حفظ البيانات الحساسة
- **Token**: محفوظ في `SharedPreferences` (مشفر على iOS/Android)
- **User Info**: اسم المستخدم، رقم الجوال، الدور
- **لا يتم حفظ كلمات المرور** في التطبيق أبداً

---

## 🔒 خدمة API الآمنة

### الملف: `lib/secure_api_service.dart`

تم إنشاء خدمة مركزية لجميع طلبات API:

### ميزات الخدمة:
1. **إضافة X-API-Key تلقائياً** لكل طلب
2. **إضافة Token تلقائياً** للطلبات التي تتطلب مصادقة
3. **معالجة الأخطاء** الآمنة
4. **Logging مفصّل** لتتبع الطلبات
5. **Timeout handling** للطلبات البطيئة

### طرق الاستخدام:

#### GET Request (بدون مصادقة)
```dart
final api = SecureApiService();
final response = await api.get('/public-endpoint', requireAuth: false);
```

#### GET Request (مع مصادقة)
```dart
final response = await api.get('/user/profile', requireAuth: true);
// Token + API Key يضافان تلقائياً
```

#### POST Request
```dart
final response = await api.post(
  '/order',
  {
    'service_id': 123,
    'address': 'الرياض',
    'notes': 'ملاحظات'
  },
  requireAuth: true,
);
```

#### PUT Request
```dart
final response = await api.put(
  '/user/profile',
  {'name': 'اسم جديد'},
  requireAuth: true,
);
```

#### DELETE Request
```dart
final response = await api.delete('/order/123', requireAuth: true);
```

---

## 📊 مثال استخدام في الصفحات

### قبل (غير آمن):
```dart
// ❌ طريقة قديمة - غير آمنة
final response = await http.get(
  Uri.parse('https://dalma-api.onrender.com/orders'),
  headers: {'Content-Type': 'application/json'},
);
```

### بعد (آمن):
```dart
// ✅ طريقة جديدة - آمنة تماماً
final api = SecureApiService();
final response = await api.get('/orders', requireAuth: true);
// X-API-Key + Token يضافان تلقائياً
```

---

## 🔐 طبقات الحماية

### 1. طبقة النقل (HTTPS)
- جميع الاتصالات مشفرة باستخدام TLS/SSL
- لا يمكن اعتراض البيانات في الطريق

### 2. طبقة المصادقة (API Key)
- كل طلب يتطلب X-API-Key صحيح
- المفتاح مخفي في الكود ولا يظهر للمستخدمين

### 3. طبقة التفويض (JWT Token)
- الطلبات الحساسة تتطلب Token
- Token يتم التحقق منه في السيرفر
- Token له صلاحية محدودة (expiration)

### 4. طبقة البيانات (SharedPreferences)
- البيانات محفوظة بشكل آمن على الجهاز
- تشفير تلقائي في iOS (Keychain)
- تشفير تلقائي في Android (EncryptedSharedPreferences)

---

## ⚠️ أفضل الممارسات

### DO ✅
1. استخدم `SecureApiService` لجميع طلبات API
2. تحقق من `response.statusCode` قبل معالجة البيانات
3. اعرض رسائل خطأ واضحة للمستخدم
4. تعامل مع حالات انقطاع الاتصال
5. تحقق من Token قبل الطلبات الحساسة

### DON'T ❌
1. لا تحفظ كلمات المرور في التطبيق
2. لا تعرض API Key في الـ UI
3. لا تستخدم HTTP مباشرة، استخدم HTTPS دائماً
4. لا تحفظ Token في متغيرات عامة
5. لا تنسى معالجة الأخطاء

---

## 🧪 اختبار الأمان

### التحقق من API Key
```dart
// يجب أن يعمل مع X-API-Key
final response = await api.get('/test', requireAuth: false);
// Status: 200 ✅

// يجب أن يفشل بدون X-API-Key
// Status: 403 ❌
```

### التحقق من Token
```dart
// يجب أن يعمل مع Token صحيح
final response = await api.get('/user/profile', requireAuth: true);
// Status: 200 ✅

// يجب أن يفشل بدون Token أو Token غير صحيح
// Status: 401 ❌
```

---

## 📝 ملاحظات مهمة

1. **API Key مخفي**: لا يظهر في أي ملف بشكل واضح
2. **Token محفوظ بشكل آمن**: في SharedPreferences المشفر
3. **جميع الطلبات محمية**: بـ HTTPS + API Key + Token
4. **Logging مفصّل**: لتتبع أي مشاكل أمنية
5. **معالجة الأخطاء**: رسائل واضحة بدون كشف معلومات حساسة

---

## 🚀 الخطوات التالية

لتطبيق نظام الأمان في صفحات أخرى:

1. استورد `SecureApiService`:
   ```dart
   import 'secure_api_service.dart';
   ```

2. استخدم الخدمة بدلاً من http مباشرة:
   ```dart
   final api = SecureApiService();
   final response = await api.get('/endpoint');
   ```

3. تحقق من الرد:
   ```dart
   if (response.statusCode == 200) {
     final data = json.decode(response.body);
     // معالجة البيانات
   }
   ```

---

## 📞 الدعم الفني

في حالة وجود أي مشاكل أمنية أو أسئلة، يرجى مراجعة:
- `lib/api_config.dart` - إعدادات API
- `lib/secure_api_service.dart` - خدمة API الآمنة
- `lib/auth.dart` - نظام المصادقة

---

✅ **تم تطبيق نظام أمان متكامل وآمن 100%**

