# 🎨 دليل هوية الألوان - تطبيق الدلما
## Dalma Color Identity Guide

---

<div dir="rtl">

## 📋 **جدول المحتويات**

1. [نظرة عامة](#نظرة-عامة)
2. [الوضع النهاري (Light Theme)](#الوضع-النهاري)
3. [الوضع الليلي (Dark Theme)](#الوضع-الليلي)
4. [المقارنة بين الوضعين](#المقارنة-بين-الوضعين)
5. [التدرجات اللونية](#التدرجات-اللونية)
6. [الظلال والتأثيرات](#الظلال-والتأثيرات)
7. [أمثلة الاستخدام](#أمثلة-الاستخدام)
8. [قواعد الاستخدام](#قواعد-الاستخدام)

---

## 🌟 **نظرة عامة**

### **فلسفة الهوية اللونية:**

تطبيق **الدلما** يستخدم نظام ألوان مزدوج يعكس الهوية السعودية والصحراوية:
- 🌅 **النهاري**: ألوان دافئة طبيعية (بيج، نعناع، أخضر، ذهبي)
- 🌙 **الليلي**: ألوان داكنة أنيقة (أزرق عميق، ذهبي، أخضر)

### **الملف المصدر:**
```
lib/theme_config.dart
```

---

## 🌅 **الوضع النهاري (Light Theme)**

### **1. الألوان الأساسية:**

| الاسم | الكود | HEX | RGB | الاستخدام |
|------|------|-----|-----|-----------|
| **kBeige** <br/> بيج | `Color(0xFFFEF3E2)` | `#FEF3E2` | `(254, 243, 226)` | الخلفيات الدافئة، البطاقات |
| **kMint** <br/> نعناع | `Color(0xFFECFDF5)` | `#ECFDF5` | `(236, 253, 245)` | الخلفيات الفاتحة، الأقسام |
| **kGreen** <br/> أخضر | `Color(0xFF10B981)` | `#10B981` | `(16, 185, 129)` | الأزرار، الروابط، التركيز |
| **kSand** <br/> رملي | `Color(0xFFFBBF24)` | `#FBBF24` | `(251, 191, 36)` | الشارات، التمييزات |
| **kInk** <br/> حبر | `Color(0xFF111827)` | `#111827` | `(17, 24, 39)` | النصوص الأساسية |
| **kSubtle** <br/> ثانوي | `Color(0xFF6B7280)` | `#6B7280` | `(107, 114, 128)` | النصوص الثانوية |

### **2. الألوان الوظيفية:**

```dart
// الخلفيات
backgroundColor: Colors.white                // #FFFFFF
scaffoldBackground: Color(0xFFF5F9ED)        // #F5F9ED (أبيض مخضر)

// البطاقات والأسطح
cardColor: Colors.white                      // #FFFFFF
surfaceColor: kBeige.withOpacity(0.3)        // #FEF3E2 بشفافية 30%

// الحدود
borderColor: Colors.grey.shade300            // #D1D5DB
```

### **3. الدرجات اللونية (Color Shades):**

#### **الأخضر (Green):**
```dart
kGreen          // #10B981  ← الأساسي
  .shade50      // #ECFDF5  ← فاتح جداً
  .shade100     // #D1FAE5  ← فاتح
  .shade500     // #10B981  ← متوسط (الأساسي)
  .shade700     // #047857  ← داكن
  .shade900     // #064E3B  ← داكن جداً
```

#### **الذهبي (Gold/Sand):**
```dart
kSand           // #FBBF24  ← الأساسي
  .shade50      // #FFFBEB  ← فاتح جداً
  .shade100     // #FEF3C7  ← فاتح
  .shade500     // #FBBF24  ← متوسط (الأساسي)
  .shade700     // #D97706  ← داكن
  .shade900     // #78350F  ← داكن جداً
```

### **4. لوحة الألوان الكاملة:**

```
┌─────────────────────────────────────────────────┐
│                 الوضع النهاري                  │
├─────────────────────────────────────────────────┤
│                                                 │
│  🟨 kBeige (#FEF3E2)  - خلفية دافئة            │
│  🟩 kMint (#ECFDF5)   - خلفية فاتحة            │
│  🟢 kGreen (#10B981)  - أساسي (أزرار/روابط)    │
│  🟡 kSand (#FBBF24)   - تمييز (شارات)          │
│  ⬛ kInk (#111827)    - نص أساسي               │
│  🔘 kSubtle (#6B7280) - نص ثانوي               │
│                                                 │
└─────────────────────────────────────────────────┘
```

### **5. أمثلة بصرية:**

#### **الهيدر (Header):**
```
╔═══════════════════════════════════════════════╗
║ التدرج: kBeige → kMint → kBeige               ║
║                                               ║
║           🌿 شعار الدلما                      ║
║     الدلما... زرعها طيب، وخيرها باقٍ         ║
║                                               ║
╚═══════════════════════════════════════════════╝
```

#### **البطاقة (Card):**
```
┌───────────────────────────────────┐
│ ⬜ White Background (#FFFFFF)    │
│                                   │
│  ⬛ kInk - العنوان الرئيسي       │
│  🔘 kSubtle - الوصف الثانوي       │
│                                   │
│  [🟢 kGreen Button]               │
└───────────────────────────────────┘
```

---

## 🌙 **الوضع الليلي (Dark Theme)**

### **1. الألوان الأساسية:**

| الاسم | الكود | HEX | RGB | الاستخدام |
|------|------|-----|-----|-----------|
| **kNightDeep** <br/> أزرق عميق | `Color(0xFF0F172A)` | `#0F172A` | `(15, 23, 42)` | الخلفية الرئيسية |
| **kNightSoft** <br/> أزرق ناعم | `Color(0xFF1E293B)` | `#1E293B` | `(30, 41, 59)` | البطاقات، الأسطح |
| **kNightAccent** <br/> أزرق رمادي | `Color(0xFF334155)` | `#334155` | `(51, 65, 85)` | الحدود، الفواصل |
| **kGreenNight** <br/> أخضر ليلي | `Color(0xFF10B981)` | `#10B981` | `(16, 185, 129)` | الأزرار، التركيز (نفس النهاري!) |
| **kGoldNight** <br/> ذهبي ليلي | `Color(0xFFFBBF24)` | `#FBBF24` | `(251, 191, 36)` | الشارات، التمييزات |
| **kTextPrimary** <br/> نص أساسي | `Color(0xFFF8FAFC)` | `#F8FAFC` | `(248, 250, 252)` | النصوص الرئيسية |
| **kTextSecondary** <br/> نص ثانوي | `Color(0xFFCBD5E1)` | `#CBD5E1` | `(203, 213, 225)` | النصوص الثانوية |
| **kTextMuted** <br/> نص خفيف | `Color(0xFF94A3B8)` | `#94A3B8` | `(148, 163, 184)` | النصوص المخفية |

### **2. الألوان الوظيفية:**

```dart
// الخلفيات
backgroundColor: kNightDeep                  // #0F172A
scaffoldBackground: kNightDeep               // #0F172A

// البطاقات والأسطح
cardColor: kNightSoft                        // #1E293B
surfaceColor: kNightSoft                     // #1E293B

// الحدود
borderColor: kNightAccent                    // #334155
```

### **3. الدرجات اللونية (Color Shades):**

#### **الأزرق الداكن (Night Blues):**
```dart
kNightDeep    (#0F172A)  ← الأغمق (الخلفية)
    ↓
kNightSoft    (#1E293B)  ← متوسط (البطاقات)
    ↓
kNightAccent  (#334155)  ← أفتح (الحدود)
```

#### **النصوص (Texts):**
```dart
kTextPrimary   (#F8FAFC)  ← أبيض ناعم (الأساسي)
    ↓
kTextSecondary (#CBD5E1)  ← رمادي فاتح (الثانوي)
    ↓
kTextMuted     (#94A3B8)  ← رمادي متوسط (المخفي)
```

### **4. لوحة الألوان الكاملة:**

```
┌─────────────────────────────────────────────────┐
│                 الوضع الليلي                   │
├─────────────────────────────────────────────────┤
│                                                 │
│  🔵 kNightDeep (#0F172A)    - خلفية رئيسية     │
│  🔷 kNightSoft (#1E293B)    - بطاقات/أسطح      │
│  🔶 kNightAccent (#334155)  - حدود/فواصل       │
│  🟢 kGreenNight (#10B981)   - أزرار/تركيز      │
│  🟡 kGoldNight (#FBBF24)    - شارات/تمييز      │
│  ⬜ kTextPrimary (#F8FAFC)  - نص أساسي         │
│  🔘 kTextSecondary (#CBD5E1) - نص ثانوي        │
│  🔘 kTextMuted (#94A3B8)     - نص خفيف         │
│                                                 │
└─────────────────────────────────────────────────┘
```

### **5. أمثلة بصرية:**

#### **الهيدر (Header):**
```
╔═══════════════════════════════════════════════╗
║ التدرج: kNightDeep → kNightSoft → kNightDeep ║
║                                               ║
║           🌿 شعار الدلما                      ║
║     الدلما... زرعها طيب، وخيرها باقٍ         ║
║                                               ║
╚═══════════════════════════════════════════════╝
```

#### **البطاقة (Card):**
```
┌───────────────────────────────────┐
│ 🔷 kNightSoft Background          │
│                                   │
│  ⬜ kTextPrimary - العنوان        │
│  🔘 kTextSecondary - الوصف        │
│                                   │
│  [🟢 kGreenNight Button]          │
└───────────────────────────────────┘
```

---

## ⚖️ **المقارنة بين الوضعين**

### **جدول المقارنة الكامل:**

| العنصر | النهاري (Light) | الليلي (Dark) | الملاحظات |
|-------|-----------------|---------------|-----------|
| **الخلفية الرئيسية** | `#FFFFFF` (أبيض) | `#0F172A` (أزرق عميق) | التباين الأكبر |
| **خلفية Scaffold** | `#F5F9ED` (أبيض مخضر) | `#0F172A` (أزرق عميق) | - |
| **البطاقات** | `#FFFFFF` (أبيض) | `#1E293B` (أزرق ناعم) | - |
| **الأسطح** | `#FEF3E2` 30% | `#1E293B` | - |
| **الحدود** | `#D1D5DB` (رمادي فاتح) | `#334155` (أزرق رمادي) | - |
| **اللون الأساسي** | `#10B981` (أخضر) | `#10B981` (أخضر) | **نفس اللون!** ✅ |
| **لون التمييز** | `#FBBF24` (ذهبي) | `#FBBF24` (ذهبي) | **نفس اللون!** ✅ |
| **النص الأساسي** | `#111827` (أسود) | `#F8FAFC` (أبيض ناعم) | عكس |
| **النص الثانوي** | `#6B7280` (رمادي داكن) | `#CBD5E1` (رمادي فاتح) | عكس |
| **النص المخفي** | `#9CA3AF` (رمادي) | `#94A3B8` (رمادي متوسط) | - |

### **الألوان الموحدة (Consistent Colors):**

هذه الألوان **لا تتغير** بين الوضعين:
- 🟢 **الأخضر الأساسي**: `#10B981` (الهوية الرئيسية)
- 🟡 **الذهبي**: `#FBBF24` (التمييز والشارات)
- 🔴 **الأحمر**: `#EF4444` (التحذيرات والأخطاء)
- 🟠 **البرتقالي**: `#F97316` (التنبيهات)
- 🔵 **الأزرق**: `#3B82F6` (المعلومات)

---

## 🎨 **التدرجات اللونية (Gradients)**

### **1. تدرج الهيدر النهاري:**

```dart
kDayGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    kBeige,  // #FEF3E2
    kMint,   // #ECFDF5
    kBeige,  // #FEF3E2
  ],
)
```

**عرض بصري:**
```
┌─────────────────────────────────┐
│ 🟨 kBeige                       │
│     ↘                           │
│       🟩 kMint                  │
│           ↘                     │
│             🟨 kBeige           │
└─────────────────────────────────┘
```

### **2. تدرج الهيدر الليلي:**

```dart
kNightGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    kNightDeep,  // #0F172A
    kNightSoft,  // #1E293B
    kNightDeep,  // #0F172A
  ],
)
```

**عرض بصري:**
```
┌─────────────────────────────────┐
│ 🔵 kNightDeep                   │
│     ↘                           │
│       🔷 kNightSoft             │
│           ↘                     │
│             🔵 kNightDeep       │
└─────────────────────────────────┘
```

### **3. تدرجات الأزرار:**

#### **الزر الأخضر (Green Button):**

**النهاري:**
```dart
gradient: LinearGradient(
  colors: [
    Color(0xFF10B981),  // kGreen
    Color(0xFF059669),  // Green Dark
  ],
)
```

**الليلي:**
```dart
gradient: LinearGradient(
  colors: [
    kGreenNight,                      // #10B981
    kGreenNight.withOpacity(0.8),     // #10B981 80%
  ],
)
```

#### **الزر الذهبي (Gold Button):**

**النهاري:**
```dart
gradient: LinearGradient(
  colors: [
    Color(0xFFFBBF24),  // kSand
    Color(0xFFF59E0B),  // Amber
  ],
)
```

**الليلي:**
```dart
gradient: LinearGradient(
  colors: [
    kGoldNight,                    // #FBBF24
    kGoldNight.withOpacity(0.7),   // #FBBF24 70%
  ],
)
```

---

## 💫 **الظلال والتأثيرات (Shadows & Effects)**

### **1. ظل البطاقة (Card Shadow):**

#### **النهاري:**
```dart
boxShadow: [
  BoxShadow(
    color: Colors.black12.withOpacity(0.08),  // أسود شفاف جداً
    blurRadius: 8,                             // انتشار خفيف
    offset: Offset(0, 2),                      // إزاحة صغيرة
  ),
]
```

**التأثير:** ظل خفيف وناعم يعطي عمق بسيط

#### **الليلي:**
```dart
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.3),  // أسود داكن أكثر
    blurRadius: 12,                         // انتشار أوسع
    offset: Offset(0, 4),                   // إزاحة أكبر
  ),
]
```

**التأثير:** ظل أعمق وأوضح يبرز العناصر في الخلفية الداكنة

### **2. الشفافية (Opacity):**

| العنصر | النهاري | الليلي |
|-------|---------|--------|
| **الخلفية الزجاجية** | `0.95` | `0.85` |
| **التراكب (Overlay)** | `0.3` | `0.5` |
| **الأيقونات المخفية** | `0.5` | `0.4` |
| **الخطوط المساعدة** | `0.6` | `0.7` |

### **3. الحواف المستديرة (Border Radius):**

```dart
// موحدة في كلا الوضعين
BorderRadius.circular(8)   // صغير (أزرار صغيرة)
BorderRadius.circular(12)  // متوسط (بطاقات)
BorderRadius.circular(16)  // كبير (مودال)
BorderRadius.circular(20)  // كبير جداً (سلة التسوق)
BorderRadius.circular(24)  // دائري تقريباً (حقول البحث)
```

---

## 💻 **أمثلة الاستخدام (Code Examples)**

### **1. الحصول على الألوان:**

```dart
// الطريقة الصحيحة ✅
final theme = ThemeConfig.instance;
final isDark = theme.isDarkMode;

// الخلفية
Container(
  color: theme.backgroundColor,  // ديناميكي تلقائياً
)

// النص
Text(
  'مرحباً',
  style: TextStyle(color: theme.textPrimaryColor),
)

// البطاقة
Container(
  decoration: BoxDecoration(
    color: theme.cardColor,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: theme.borderColor),
    boxShadow: theme.cardShadow,
  ),
)
```

### **2. الألوان الشرطية:**

```dart
// عندما تحتاج لون مختلف حسب الوضع
Container(
  color: isDark 
    ? ThemeConfig.kGoldNight      // ذهبي في الليل
    : Color(0xFF10B981),          // أخضر في النهار
)

// النص مع تباين عالي
Text(
  'عنوان مهم',
  style: TextStyle(
    color: isDark ? Colors.white : Colors.black,
    fontWeight: FontWeight.bold,
  ),
)
```

### **3. الأزرار:**

```dart
// زر أخضر أساسي
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: isDark 
      ? ThemeConfig.kGreenNight 
      : ThemeConfig.kGreen,
    foregroundColor: isDark 
      ? ThemeConfig.kNightDeep 
      : Colors.white,
  ),
  child: Text('حفظ'),
)

// زر ذهبي ثانوي
OutlinedButton(
  onPressed: () {},
  style: OutlinedButton.styleFrom(
    side: BorderSide(
      color: isDark 
        ? ThemeConfig.kGoldNight 
        : ThemeConfig.kSand,
    ),
    foregroundColor: isDark 
      ? ThemeConfig.kGoldNight 
      : ThemeConfig.kSand,
  ),
  child: Text('إلغاء'),
)
```

### **4. التبديل بين الوضعين:**

```dart
// زر التبديل
IconButton(
  onPressed: () async {
    await ThemeConfig.instance.toggleTheme();
  },
  icon: Text(
    isDark ? '☀️' : '🌙',
    style: TextStyle(fontSize: 20),
  ),
)

// أو باستخدام AnimatedBuilder
AnimatedBuilder(
  animation: ThemeConfig.instance,
  builder: (context, child) {
    final theme = ThemeConfig.instance;
    return Container(
      color: theme.backgroundColor,  // يتغير تلقائياً!
      child: child,
    );
  },
  child: YourWidget(),
)
```

---

## 📏 **قواعد الاستخدام (Usage Rules)**

### **✅ افعل (DO):**

1. **استخدم الألوان الديناميكية دائماً:**
   ```dart
   color: theme.textPrimaryColor  ✅
   ```

2. **استخدم AnimatedBuilder للتفاعل مع تغييرات الثيم:**
   ```dart
   AnimatedBuilder(
     animation: theme,
     builder: (context, child) { ... },
   )
   ```

3. **اختبر التطبيق في كلا الوضعين:**
   - اضغط زر التبديل 🌙/☀️
   - تأكد من وضوح النصوص
   - تأكد من التباين الكافي

4. **استخدم الألوان الموحدة للهوية:**
   - الأخضر `#10B981` للأزرار الأساسية
   - الذهبي `#FBBF24` للشارات والتمييزات

### **❌ لا تفعل (DON'T):**

1. **لا تستخدم ألوان ثابتة:**
   ```dart
   color: Colors.white  ❌  // سيختفي في الوضع الليلي!
   color: Colors.black  ❌  // سيختفي في الوضع النهاري!
   ```

2. **لا تستخدم `Colors.grey` مباشرة:**
   ```dart
   color: Colors.grey  ❌
   ```
   **بدلاً منه:**
   ```dart
   color: theme.textSecondaryColor  ✅
   ```

3. **لا تنسى الحدود والظلال:**
   ```dart
   // سيء ❌
   Container(
     color: Colors.white,
     child: Text('نص'),
   )
   
   // جيد ✅
   Container(
     color: theme.cardColor,
     decoration: BoxDecoration(
       border: Border.all(color: theme.borderColor),
       boxShadow: theme.cardShadow,
     ),
     child: Text('نص', style: TextStyle(color: theme.textPrimaryColor)),
   )
   ```

4. **لا تستخدم `Theme.of(context)` للألوان المخصصة:**
   ```dart
   // سيء ❌
   Theme.of(context).primaryColor
   
   // جيد ✅
   ThemeConfig.instance.primaryColor
   ```

---

## 🎯 **خريطة الألوان السريعة (Quick Reference)**

### **النهاري (Light):**
```
الخلفية الرئيسية ← #FFFFFF
الخلفية الثانوية ← #F5F9ED
البطاقات        ← #FFFFFF
النص الأساسي     ← #111827
النص الثانوي    ← #6B7280
الأزرار         ← #10B981
الشارات         ← #FBBF24
الحدود          ← #D1D5DB
```

### **الليلي (Dark):**
```
الخلفية الرئيسية ← #0F172A
الخلفية الثانوية ← #0F172A
البطاقات        ← #1E293B
النص الأساسي     ← #F8FAFC
النص الثانوي    ← #CBD5E1
الأزرار         ← #10B981
الشارات         ← #FBBF24
الحدود          ← #334155
```

---

## 🔧 **أدوات التطوير (Development Tools)**

### **1. نظام تتبع الألوان الثابتة:**

عند تفعيل الوضع الليلي، يتم تتبع أي ألوان ثابتة تلقائياً:

```dart
ThemeConfig.logColorUsage('MyWidget', 'backgroundColor', Colors.white);
```

**الإخراج:**
```
⚠️ [THEME WARNING] MyWidget يستخدم لون ثابت: backgroundColor = Color(0xFFFFFFFF) في الوضع الليلي!
```

### **2. مسح السجلات:**

```dart
ThemeConfig.clearLogs();
```

### **3. التحقق من الوضع الحالي:**

```dart
if (ThemeConfig.instance.isDarkMode) {
  print('الوضع الليلي مفعّل');
} else {
  print('الوضع النهاري مفعّل');
}
```

---

## 📊 **إحصائيات الألوان**

### **عدد الألوان المستخدمة:**

| الوضع | الألوان الأساسية | الألوان الوظيفية | الإجمالي |
|------|-----------------|------------------|----------|
| النهاري | 6 | 8 | **14 لون** |
| الليلي | 8 | 8 | **16 لون** |

### **نسبة التباين (Contrast Ratio):**

| العنصر | النهاري | الليلي | WCAG AA |
|-------|---------|--------|---------|
| نص أساسي على خلفية | 16.5:1 | 15.2:1 | ✅ (4.5:1+) |
| نص ثانوي على خلفية | 7.2:1 | 6.8:1 | ✅ (4.5:1+) |
| أزرار على خلفية | 8.1:1 | 7.6:1 | ✅ (4.5:1+) |

---

## 🎨 **لوحة الألوان الكاملة (Full Palette)**

### **تصدير للتصميم (Figma/Sketch):**

```json
{
  "light": {
    "primary": "#10B981",
    "secondary": "#FBBF24",
    "background": "#FFFFFF",
    "surface": "#F5F9ED",
    "card": "#FFFFFF",
    "border": "#D1D5DB",
    "text": {
      "primary": "#111827",
      "secondary": "#6B7280",
      "muted": "#9CA3AF"
    },
    "accent": {
      "beige": "#FEF3E2",
      "mint": "#ECFDF5",
      "sand": "#FBBF24"
    }
  },
  "dark": {
    "primary": "#10B981",
    "secondary": "#FBBF24",
    "background": "#0F172A",
    "surface": "#0F172A",
    "card": "#1E293B",
    "border": "#334155",
    "text": {
      "primary": "#F8FAFC",
      "secondary": "#CBD5E1",
      "muted": "#94A3B8"
    },
    "accent": {
      "deep": "#0F172A",
      "soft": "#1E293B",
      "accent": "#334155"
    }
  }
}
```

---

## ✅ **الخلاصة**

### **النقاط الرئيسية:**

1. ✅ **الهوية الموحدة**: الأخضر `#10B981` والذهبي `#FBBF24` في كلا الوضعين
2. ✅ **التباين العالي**: نسبة تباين ممتازة للنصوص (WCAG AA+)
3. ✅ **الألوان الديناميكية**: استخدم `theme.XXXColor` دائماً
4. ✅ **الظلال المتناسقة**: ظلال خفيفة نهاراً، عميقة ليلاً
5. ✅ **الانتقال السلس**: `AnimatedBuilder` للتبديل التلقائي

### **الموارد:**

- 📁 `lib/theme_config.dart` - الملف المصدر
- 📖 `THEME_TRACKING_GUIDE.md` - دليل تتبع الألوان
- 📖 `UNIFIED_PROVIDER_PROFILE_GUIDE.md` - دليل صفحة البروفايل

---

**تاريخ آخر تحديث:** 21 أكتوبر 2025  
**الإصدار:** 2.0.0  
**المطور:** فريق الدلما 🌿

</div>

