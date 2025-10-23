# 📱 دليل صفحة "حسابي" - تطبيق الدلما

## 📋 جدول المحتويات
1. [نظرة عامة](#نظرة-عامة)
2. [الحالات المختلفة للصفحة](#الحالات-المختلفة-للصفحة)
3. [المكونات الرئيسية](#المكونات-الرئيسية)
4. [الميزات والوظائف](#الميزات-والوظائف)
5. [التكامل مع الثيم](#التكامل-مع-الثيم)
6. [التكامل مع الـ API](#التكامل-مع-الـ-api)
7. [إدارة الحالة](#إدارة-الحالة)
8. [أمثلة الاستخدام](#أمثلة-الاستخدام)

---

## 🎯 نظرة عامة

صفحة **"حسابي"** (`MyAccountPage`) هي المركز الرئيسي لإدارة حساب المستخدم في تطبيق الدلما. توفر واجهة أنيقة وشاملة لعرض وتعديل معلومات المستخدم، إدارة الأجهزة المتصلة، تغيير الثيم، وإدارة الإعدادات الأخرى.

### 📍 الموقع
```
lib/my_account_page.dart
```

### 🎨 التصميم
- **نمط**: Material Design مع لمسات عربية
- **الخط**: Google Fonts (Cairo)
- **الثيم**: ديناميكي (نهاري/ليلي)
- **الألوان**: متناسقة مع `ThemeConfig`

---

## 🔄 الحالات المختلفة للصفحة

### 1️⃣ حالة "غير مسجل دخول"
**متى تظهر:** عندما لا يوجد token في `SharedPreferences`

#### المكونات:
```dart
- أيقونة دائرية كبيرة مع تدرج لوني
- عنوان: "سجّل دخول لإدارة حسابك"
- قائمة بالميزات المتاحة:
  ✨ معلومات حسابك الشخصية
  📱 الأجهزة المتصلة
  🎨 إعدادات الثيم والمظهر
  📍 العناوين المحفوظة
- زر "تسجيل الدخول" (تدرج لوني + ظل)
- رابط "أنشئ حساباً جديداً"
```

#### التصميم:
- **الخلفية**: `ThemeConfig.instance.backgroundColor`
- **الأيقونة**: `Icons.account_circle_outlined` (80px)
- **التدرج**: أخضر (نهاري) / ذهبي (ليلي)
- **الظل**: `blurRadius: 12`, `offset: (0, 4)`

---

### 2️⃣ حالة "التحميل"
**متى تظهر:** أثناء جلب بيانات المستخدم من الـ API

#### المكونات:
```dart
- CircularProgressIndicator
- نص: "جاري التحميل..."
```

---

### 3️⃣ حالة "خطأ في التحميل"
**متى تظهر:** عند فشل الاتصال بالـ API أو خطأ في الاستجابة

#### المكونات:
```dart
- أيقونة خطأ: Icons.error_outline (80px, أحمر)
- نص: "حدث خطأ في تحميل البيانات"
- زر "إعادة المحاولة" (يستدعي _loadUserProfile)
```

---

### 4️⃣ حالة "مسجل دخول" (الحالة الرئيسية)
**متى تظهر:** عند نجاح تسجيل الدخول ووجود بيانات المستخدم

---

## 🧩 المكونات الرئيسية

### 1. **الهيدر (Header)**
```
┌─────────────────────────────────────┐
│   [← رجوع]         [🌙 ثيم]       │
│                                     │
│         ┌───────────────┐           │
│         │   [صورة/حرف]  │  [+]     │
│         └───────────────┘           │
│                                     │
│         اسم المستخدم               │
│         رقم الجوال                 │
│                                     │
│    ┌──────────────────────┐        │
│    │   👤 user   ✨      │        │
│    └──────────────────────┘        │
└─────────────────────────────────────┘
```

#### العناصر:
- **زر الرجوع**: أعلى اليسار
- **زر الثيم**: أعلى اليمين (`ThemeToggleWidget`)
- **الصورة الشخصية**: 
  - دائرية (100px)
  - إما صورة من الـ API أو حرف أول من الاسم
  - زر (+) للتحميل/التغيير
- **الاسم**: خط عريض (24px)
- **رقم الجوال**: خط رفيع (14px)
- **شارة الدور**: بتدرج لوني (user, media, provider, admin)

---

### 2. **معلومات الحساب (Account Info)**

#### القسم الأول: تاريخ الميلاد والأجهزة
```
┌─────────────────────────────────────┐
│  📅 تاريخ الميلاد: 01/01/1990      │
│  📱 الأجهزة المتصلة: 3 أجهزة  →   │
└─────────────────────────────────────┘
```

**الضغط على "الأجهزة المتصلة"** يفتح `BottomSheet` بالتفاصيل:
```
┌─────────────────────────────────────┐
│         الأجهزة المتصلة            │
│  ───────────────────────────────    │
│                                     │
│  📱 iPhone 16 Pro                  │
│     🌍 الرياض، السعودية            │
│     🕐 آخر دخول: 21/10/2025        │
│                                     │
│  💻 MacBook Pro                    │
│     🌍 الدمام، السعودية            │
│     🕐 آخر دخول: 20/10/2025        │
└─────────────────────────────────────┘
```

---

### 3. **الإجراءات السريعة (Quick Actions)**

```
┌──────────────────────────────────────┐
│       🚀 الإجراءات السريعة         │
│                                      │
│  📺 طلب أن تكون إعلامياً            │
│  🏪 طلب أن تكون مقدم خدمة           │
└──────────────────────────────────────┘
```

**الوظائف:**
- **طلب إعلامي**: ينقل إلى `RequestMediaPage`
- **طلب مقدم خدمة**: ينقل إلى `RequestProviderPage`

---

### 4. **الأمان والخصوصية (Security & Privacy)**

```
┌──────────────────────────────────────┐
│      🔒 الأمان والخصوصية            │
│                                      │
│  🔑 تغيير كلمة المرور                │
│  📍 إدارة العناوين                   │
│  🔔 إعدادات الإشعارات                │
└──────────────────────────────────────┘
```

**الوظائف:**
- **تغيير كلمة المرور**: يفتح `Dialog` بنموذج (كلمة المرور القديمة/الجديدة)
- **إدارة العناوين**: ينقل إلى صفحة العناوين (قريباً)
- **إعدادات الإشعارات**: ينقل إلى صفحة الإشعارات (قريباً)

---

### 5. **زر تسجيل الخروج (Logout)**

```
┌──────────────────────────────────────┐
│          🚪 تسجيل الخروج            │
└──────────────────────────────────────┘
```

**السلوك:**
- يظهر `Dialog` تأكيد
- عند التأكيد:
  1. يمسح الـ token من `SharedPreferences`
  2. يمسح بيانات المستخدم المحلية
  3. يُعلم `AuthState` بتسجيل الخروج
  4. يرجع إلى الصفحة الرئيسية
  5. يظهر toast "تم تسجيل الخروج بنجاح"

---

## ✨ الميزات والوظائف

### 1. **رفع الصورة الشخصية**

#### التدفق:
```
1. الضغط على زر (+) في الصورة الشخصية
2. اختيار مصدر الصورة:
   - الكاميرا
   - المعرض
3. رفع الصورة إلى Cloudinary
4. حفظ URL في قاعدة البيانات
5. تحديث الواجهة
```

#### السجلات (Logs):
```
📸━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📸 [التاريخ والوقت] بدء رفع الصورة الشخصية
📸 الخطوة 1: تحديد الصورة...
📸 الخطوة 2: قراءة الصورة...
📸 الخطوة 3: رفع إلى Cloudinary...
📸 الخطوة 4: تحديث قاعدة البيانات...
📸 ✅ تم رفع الصورة بنجاح: https://...
📸━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### الكود:
```dart
Future<void> _uploadProfilePicture(ImageSource source) async {
  // 1. اختيار الصورة
  final picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: source);
  
  // 2. تحويل إلى bytes
  final bytes = await image.readAsBytes();
  
  // 3. رفع إلى Cloudinary (multipart/form-data)
  // 4. استقبال URL
  // 5. إرسال PATCH إلى /api/me/avatar
  // 6. تحديث _userProfile
}
```

---

### 2. **عرض الأجهزة المتصلة**

#### التدفق:
```
1. الضغط على "الأجهزة المتصلة: X أجهزة"
2. جلب البيانات من /api/connected-devices
3. عرض BottomSheet بالتفاصيل:
   - نوع الجهاز (📱 موبايل / 💻 كمبيوتر)
   - اسم الجهاز (مثل: iPhone 16 Pro)
   - الموقع (GPS → City, Country)
   - آخر دخول (تاريخ ووقت)
```

#### البيانات المعروضة:
```dart
{
  "device_id": "abc123",
  "device_type": "mobile", // mobile, desktop, tablet
  "device_name": "iPhone 16 Pro",
  "location": {
    "city": "الرياض",
    "country": "السعودية",
    "ip": "192.168.1.1"
  },
  "last_login": "2025-10-21T14:30:00Z"
}
```

---

### 3. **تغيير كلمة المرور**

#### التدفق:
```
1. الضغط على "تغيير كلمة المرور"
2. يظهر Dialog بنموذج:
   - كلمة المرور الحالية
   - كلمة المرور الجديدة
   - تأكيد كلمة المرور
3. التحقق من صحة البيانات
4. إرسال POST إلى /api/change-password
5. عرض رسالة نجاح/فشل
```

#### الكود:
```dart
Future<void> _changePassword() async {
  final response = await http.post(
    Uri.parse('$_baseUrl/api/change-password'),
    headers: {
      'Authorization': 'Bearer $_token',
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'old_password': _oldPasswordController.text,
      'new_password': _newPasswordController.text,
    }),
  );
  
  if (response.statusCode == 200) {
    NotificationsService.instance.toast('تم تغيير كلمة المرور بنجاح');
  }
}
```

---

## 🎨 التكامل مع الثيم

### الألوان الديناميكية

```dart
// الخلفية
backgroundColor: ThemeConfig.instance.backgroundColor

// النص الأساسي
color: ThemeConfig.instance.textPrimaryColor

// النص الثانوي
color: ThemeConfig.instance.textSecondaryColor

// اللون الأساسي (أخضر/ذهبي)
color: ThemeConfig.instance.primaryColor

// التدرجات
gradient: LinearGradient(
  colors: ThemeConfig.instance.isDarkMode
    ? [ThemeConfig.kGoldNight, ThemeConfig.kGoldNight.withOpacity(0.8)]
    : [ThemeConfig.kGreen, const Color(0xFF059669)],
)
```

### زر الثيم

```dart
ThemeToggleWidget(
  position: ThemeTogglePosition.topRight,
)
```

**الوظيفة:**
- عرض زر ليلي/نهاري في أعلى اليمين
- حفظ اختيار المستخدم في `SharedPreferences`
- تحديث الواجهة فوراً

---

## 🌐 التكامل مع الـ API

### 1. **جلب معلومات المستخدم**

**Endpoint:** `GET /api/me`

**Headers:**
```json
{
  "Authorization": "Bearer <token>",
  "Content-Type": "application/json"
}
```

**Response (200):**
```json
{
  "id": 123,
  "name": "أحمد محمد",
  "phone": "+966501234567",
  "role": "user",
  "birth_date": "1990-01-01",
  "avatar_url": "https://res.cloudinary.com/...",
  "is_active": true,
  "created_at": "2025-01-01T00:00:00Z"
}
```

---

### 2. **رفع الصورة الشخصية**

**Endpoint:** `PATCH /api/me/avatar`

**Method:** Multipart Form Data

**Body:**
```
file: <image_bytes>
upload_preset: dalma_avatars
```

**Process:**
```
1. Upload to Cloudinary
2. Get URL
3. Save to database
```

---

### 3. **جلب الأجهزة المتصلة**

**Endpoint:** `GET /api/connected-devices`

**Headers:**
```json
{
  "Authorization": "Bearer <token>"
}
```

**Response (200):**
```json
{
  "devices": [
    {
      "device_id": "abc123",
      "device_type": "mobile",
      "device_name": "iPhone 16 Pro",
      "location": {
        "city": "الرياض",
        "country": "السعودية",
        "ip": "192.168.1.1"
      },
      "last_login": "2025-10-21T14:30:00Z"
    }
  ]
}
```

---

### 4. **تغيير كلمة المرور**

**Endpoint:** `POST /api/change-password`

**Headers:**
```json
{
  "Authorization": "Bearer <token>",
  "Content-Type": "application/json"
}
```

**Body:**
```json
{
  "old_password": "old123",
  "new_password": "new123"
}
```

**Response (200):**
```json
{
  "message": "تم تغيير كلمة المرور بنجاح"
}
```

---

### 5. **تسجيل الخروج**

**Endpoint:** `POST /api/logout`

**Headers:**
```json
{
  "Authorization": "Bearer <token>"
}
```

**Response (200):**
```json
{
  "message": "تم تسجيل الخروج بنجاح"
}
```

**الإجراءات المحلية:**
```dart
1. prefs.remove('token')
2. prefs.remove('user_name')
3. prefs.remove('user_phone')
4. prefs.remove('user_role')
5. AuthState.logout()
6. Navigator.pop()
```

---

## 📊 إدارة الحالة

### المتغيرات الرئيسية

```dart
class _MyAccountPageState extends State<MyAccountPage> {
  bool _isLoading = true;         // حالة التحميل
  bool _hasError = false;          // حالة الخطأ
  Map<String, dynamic>? _userProfile; // بيانات المستخدم
  String? _token;                  // رمز الجلسة
  final String _baseUrl = 'https://dalma-api.onrender.com';
}
```

### دورة الحياة

```
initState()
  ↓
_loadUserProfile()
  ↓
if (token == null)
  → Show Login Screen
else
  ↓
  GET /api/me
  ↓
  if (success)
    → Show Account Page
  else
    → Show Error Screen
```

---

## 🎯 أمثلة الاستخدام

### 1. **التنقل إلى صفحة حسابي**

```dart
Navigator.pushNamed(context, '/account');
```

أو:

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => MyAccountPage()),
);
```

---

### 2. **التحقق من حالة تسجيل الدخول**

```dart
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('token');

if (token != null) {
  // المستخدم مسجل دخول
} else {
  // المستخدم غير مسجل
}
```

---

### 3. **الاستماع لتغييرات الثيم**

```dart
AnimatedBuilder(
  animation: ThemeConfig.instance,
  builder: (context, child) {
    return Container(
      color: ThemeConfig.instance.backgroundColor,
      child: child,
    );
  },
  child: YourWidget(),
)
```

---

## 🔧 الصيانة والتطوير

### إضافة ميزة جديدة

1. **إضافة زر في القسم المناسب:**
```dart
_buildActionButton(
  icon: Icons.new_feature,
  label: 'ميزة جديدة',
  onTap: () => _handleNewFeature(),
)
```

2. **إنشاء دالة المعالجة:**
```dart
Future<void> _handleNewFeature() async {
  // الكود هنا
}
```

3. **تحديث الواجهة:**
```dart
setState(() {
  // تحديث البيانات
});
```

---

### تخصيص التصميم

#### تغيير الألوان:
```dart
// في ThemeConfig
static const kCustomColor = Color(0xFF123456);
```

#### تغيير الخطوط:
```dart
style: GoogleFonts.cairo(
  fontSize: 18,
  fontWeight: FontWeight.w700,
  color: ThemeConfig.instance.textPrimaryColor,
)
```

---

## 📝 ملاحظات مهمة

### 1. **الأمان**
- ✅ جميع الطلبات محمية بـ Bearer Token
- ✅ التحقق من صحة الـ token في كل طلب
- ✅ تشفير كلمات المرور (bcrypt في الـ Backend)
- ✅ تسجيل خروج تلقائي عند انتهاء صلاحية الـ Token

### 2. **الأداء**
- ✅ تحميل البيانات مرة واحدة فقط
- ✅ استخدام `setState` للتحديثات المحلية
- ✅ `CircularProgressIndicator` أثناء العمليات الطويلة

### 3. **تجربة المستخدم**
- ✅ رسائل واضحة ومفهومة
- ✅ تأكيد قبل الإجراءات الحساسة (حذف، تسجيل خروج)
- ✅ Toasts للنجاح/الفشل
- ✅ تصميم متجاوب مع جميع الأحجام

---

## 🐛 استكشاف الأخطاء

### المشكلة: "غير قادر على تحميل البيانات"
**الحل:**
1. تحقق من الاتصال بالإنترنت
2. تحقق من صحة الـ Token
3. تحقق من حالة الـ API Server

### المشكلة: "الصورة لا تُرفع"
**الحل:**
1. تحقق من أذونات الكاميرا/المعرض
2. تحقق من حجم الصورة (max 10MB)
3. تحقق من تكوين Cloudinary

### المشكلة: "تسجيل الخروج لا يعمل"
**الحل:**
1. تحقق من حذف الـ Token من `SharedPreferences`
2. تحقق من تحديث `AuthState`
3. أعد تشغيل التطبيق

---

## 📚 الموارد الإضافية

### الملفات ذات الصلة:
- `lib/auth.dart` - إدارة المصادقة
- `lib/theme_config.dart` - تكوين الثيم
- `lib/notifications.dart` - خدمة الإشعارات
- `lib/api_config.dart` - تكوين الـ API
- `lib/request_media_page.dart` - طلب إعلامي
- `lib/request_provider_page.dart` - طلب مقدم خدمة

### المكتبات المستخدمة:
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  shared_preferences: ^2.2.2
  provider: ^6.1.1
  google_fonts: ^6.1.0
  image_picker: ^1.0.7
  intl: ^0.18.1
```

---

## ✅ قائمة التحقق للمطورين

- [ ] التحقق من تسجيل الدخول عند فتح الصفحة
- [ ] عرض رسالة واضحة عند عدم تسجيل الدخول
- [ ] تحميل بيانات المستخدم من الـ API
- [ ] عرض الصورة الشخصية (صورة أو حرف)
- [ ] السماح برفع/تغيير الصورة الشخصية
- [ ] عرض الأجهزة المتصلة
- [ ] السماح بتغيير كلمة المرور
- [ ] تسجيل الخروج بشكل صحيح
- [ ] دعم الثيم الديناميكي (نهاري/ليلي)
- [ ] رسائل خطأ واضحة
- [ ] سجلات مفصلة في الـ Console

---

**📅 آخر تحديث:** 21 أكتوبر 2025  
**✍️ المطور:** فريق تطبيق الدلما  
**📧 للدعم:** support@dalma-app.com  


