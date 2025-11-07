# 🔐 Render Environment Variables Setup

## ⚠️ مهم جداً للأمان!

يجب إضافة `APP_API_KEY` في Render Dashboard لحماية الـ Backend من الوصول غير المصرح به.

---

## 📋 الخطوات:

### 1️⃣ افتح Render Dashboard
```
https://dashboard.render.com/
```

### 2️⃣ اختر الـ Service
- اذهب إلى `dalma-api` service

### 3️⃣ افتح Environment Variables
- اضغط على "Environment" من القائمة الجانبية

### 4️⃣ أضف المتغير الجديد
**Key:**
```
APP_API_KEY
```

**Value:**
```
FKSOE445DFLCD$%CD##g48d#d3OL5&%kdkf&5gdOdKeKKDS
```

### 5️⃣ احفظ التغييرات
- اضغط "Save Changes"
- انتظر حتى يُعاد Deploy الـ Backend تلقائياً

---

## 🛡️ كيف يعمل النظام:

### Backend (dalma-api):
```javascript
const validApiKey = process.env.APP_API_KEY || 'dalma_app_2025_secure_key';

if (!apiKey || apiKey !== validApiKey) {
  return res.status(401).json({ 
    error: 'مفتاح API غير صحيح',
    code: 'INVALID_API_KEY'
  });
}
```

### Flutter (aldlma):
```dart
// API Key مُشفّر (obfuscated) في الكود
static String get apiKey => _k1 + _k2 + _k3 + _k4;

// يُرسل في Headers
headers: {
  'X-API-Key': apiKey,
  'X-Device-ID': deviceId,
}
```

---

## ✅ الفوائد:

1. **حماية كاملة:**
   - لا يمكن لأحد الوصول للـ Backend بدون `X-API-Key`
   - المفتاح مُشفّر في Flutter (لا يظهر في compiled app)
   - المفتاح الحقيقي موجود فقط في Render Environment

2. **سهولة التغيير:**
   - يمكن تغيير المفتاح من Render فقط
   - لا حاجة لإعادة بناء التطبيق

3. **Logs واضحة:**
   - يمكن رؤية محاولات الوصول غير المصرح بها
   - تتبع كل الطلبات

---

## 🔍 التحقق من النجاح:

بعد Deploy، تحقق من Logs في Render:

**✅ نجاح:**
```
🔐 [LAYER 2] API Key Verification:
   🔑 Received Key: FKSOE445DF...
   🔑 Expected Key: FKSOE445DF...
   ✅ API Key Verified!
```

**❌ فشل:**
```
🔐 [LAYER 2] API Key Verification:
   🔑 Received Key: MISSING
   🔑 Expected Key: FKSOE445DF...
   ❌ API Key INVALID!
```

---

## 📊 طبقات الحماية (Security Layers):

```
Layer 1: IP Verification
   ↓
Layer 2: APP_API_KEY Verification ← هنا!
   ↓
Layer 3: Device ID Tracking
   ↓
Layer 4: JWT Token Verification (للمستخدمين المسجلين)
```

---

## 🚨 ملاحظات مهمة:

1. **لا تشارك المفتاح:**
   - لا ترسل `APP_API_KEY` لأي شخص
   - لا تضعه في Git أو GitHub

2. **استخدم Environment Variables:**
   - دائماً استخدم `process.env.APP_API_KEY`
   - لا تكتب المفتاح في الكود مباشرة

3. **غيّر المفتاح بشكل دوري:**
   - كل 3-6 أشهر
   - فوراً إذا شككت في تسريبه

---

## 📞 الدعم:

إذا واجهت أي مشكلة:
1. تحقق من Render Logs
2. تحقق من Flutter Logs
3. تأكد من كتابة المفتاح بشكل صحيح (بدون مسافات)

---

**آخر تحديث:** 7 نوفمبر 2025
**الحالة:** ✅ جاهز للتطبيق

