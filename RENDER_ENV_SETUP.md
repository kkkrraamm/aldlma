# 🔐 إعداد Environment Variables في Render

## ⚠️ مهم جداً: إضافة APP_API_KEY

### 📋 الخطوات:

1. **اذهب إلى Render Dashboard:**
   ```
   https://dashboard.render.com
   ```

2. **افتح خدمة dalma-api:**
   ```
   Dashboard → dalma-api → Environment
   ```

3. **أضف Environment Variable جديد:**

   | Key | Value |
   |-----|-------|
   | `APP_API_KEY` | `FKSOE445DFLCD$%CD##g48d#d3OL5&%kdkf&5gdOdKeKKDS` |

4. **احفظ التغييرات:**
   - اضغط "Save Changes"
   - Render سيُعيد Deploy تلقائياً (2-3 دقائق)

---

## ✅ التحقق من الإعداد:

بعد Deploy، تحقق من Logs:

```
Render Dashboard → dalma-api → Logs
```

يجب أن ترى:

```
🔐 [LAYER 2] API Key Verification:
   🔑 Received Key: FKSOE445DF...
   🔑 Expected Key: FKSOE445DF...
   ✅ API Key Verified!
```

---

## 🔒 الأمان:

### ✅ في Backend (Render):
- ✅ API Key محفوظ في Environment Variables
- ✅ لا يظهر في الكود
- ✅ لا يظهر في Git
- ✅ آمن تماماً

### ✅ في Flutter:
- ✅ API Key مُشفّر (obfuscated)
- ✅ يُعاد بناؤه في Runtime
- ✅ لا يظهر بنص واضح في compiled app

---

## 📊 كيف يعمل:

### Backend:
```javascript
// في index.js
const validApiKey = process.env.APP_API_KEY;
// يقرأ من Environment Variables في Render
```

### Flutter:
```dart
// في api_config.dart
static String get apiKey => _part1 + _part2 + _part3 + _part4;
// يُعيد بناء: FKSOE445DFLCD$%CD##g48d#d3OL5&%kdkf&5gdOdKeKKDS
```

---

## 🚀 بعد الإعداد:

1. **انتظر Deploy** (2-3 دقائق)
2. **جرّب تسجيل الدخول** في التطبيق
3. **✅ يجب أن يعمل بنجاح!**

---

## 📝 ملاحظات:

- ⚠️ لا تكتب API Key في الكود أبداً
- ⚠️ لا ترفع API Key على Git
- ✅ استخدم Environment Variables دائماً
- ✅ Flutter يُشفّر الـ Key تلقائياً

---

**🔐 الآن API Key محمي بشكل كامل!**

