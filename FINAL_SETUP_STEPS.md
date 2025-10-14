# 🎯 **خطوات إتمام إعداد الحسابات**

---

## ✅ **ما تم:**

1. ✅ إنشاء 3 حسابات تجريبية على Render
2. ✅ تحديث API لدعم حقل `role`
3. ✅ تحديث API لإرجاع `role` في رد تسجيل الدخول
4. ✅ إنشاء صفحة HTML لإنشاء حسابات خاصة
5. ✅ رفع جميع التحديثات إلى Render

---

## ⚠️ **خطوة مهمة متبقية:**

الحسابات التجريبية تم إنشاؤها بنجاح، لكن `role` لم يتم تحديثه في قاعدة البيانات على Render.

### 📝 **لتحديث الأدوار يدوياً:**

#### الطريقة 1: من Render Dashboard
```sql
1. افتح Render Dashboard
2. اذهب إلى dalma-db → Connect → psql Shell
3. نفّذ الأوامر التالية:

UPDATE users SET role = 'media', is_verified = true, followers_count = 150, posts_count = 25 WHERE phone = '0502222222';
UPDATE users SET role = 'provider', is_verified = true WHERE phone = '0503333333';
UPDATE users SET role = 'user' WHERE phone = '0501111111';
```

#### الطريقة 2: باستخدام script SQL
```bash
الملف الجاهز: /Users/kimaalanzi/Desktop/aaldma/dalma-api/update_roles_manually.sql

نفّذه في Render psql Shell
```

---

## 🔍 **التحقق من النتيجة:**

بعد تحديث الأدوار، جرّب:

```bash
# تسجيل دخول الإعلامي
curl -X POST https://dalma-api.onrender.com/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"0502222222","password":"@Qq249aaq"}'

# النتيجة المتوقعة:
{
  "id": 25,
  "name": "خالد الإعلامي",
  "phone": "0502222222",
  "role": "media", ← يجب أن يظهر هنا
  "token": "..."
}
```

---

## 📱 **الاختبار من التطبيق:**

### 1️⃣ **قبل التحديث:**
- جميع الحسابات تظهر كـ "مستخدم عادي" في صفحة "حسابي"

### 2️⃣ **بعد التحديث:**
- `0501111111` → واجهة مستخدم عادي 👤
- `0502222222` → واجهة إعلامي 🎥
- `0503333333` → واجهة مقدم خدمة 🏪

---

## 🚀 **خطوات الاختبار:**

```bash
1. نفّذ SQL في Render Dashboard
2. انتظر 30 ثانية
3. افتح التطبيق واضغط R
4. سجل دخول بـ 0502222222
5. افتح تبويب "حسابي"
6. يجب أن ترى واجهة الإعلامي مع:
   - إحصاءات المتابعين
   - قائمة المنشورات
   - زر إضافة منشور جديد
```

---

## ✅ **النتيجة النهائية:**

### **الحسابات بعد التحديث:**

| الجوال | الاسم | النوع | موثق | المتابعون | المنشورات |
|--------|-------|-------|------|-----------|-----------|
| 0501111111 | أحمد المستخدم | user | ❌ | 0 | 0 |
| 0502222222 | خالد الإعلامي | media | ✅ | 150 | 25 |
| 0503333333 | محمد مقدم الخدمة | provider | ✅ | 0 | 0 |

**كلمة المرور للجميع:** `@Qq249aaq`

---

## 📂 **الملفات المفيدة:**

1. **SQL للتحديث اليدوي:**
   `/Users/kimaalanzi/Desktop/aaldma/dalma-api/update_roles_manually.sql`

2. **صفحة إنشاء حسابات خاصة:**
   `/Users/kimaalanzi/Desktop/aaldma/special_account_creator.html`

3. **سكريبت إنشاء حسابات:**
   `/Users/kimaalanzi/Desktop/aaldma/dalma-api/create_accounts_via_api.js`

---

## 🎯 **الخطوة القادمة:**

**نفّذ SQL في Render Dashboard ثم جرّب التطبيق!** 🚀

