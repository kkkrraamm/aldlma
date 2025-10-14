# 🔧 إصلاح قاعدة البيانات على Render

## ✅ تم اكتشاف المشكلة!

### من Logs:
```
✅ تم حفظ Token: eyJhbGciOiJIUzI1NiIs...
🔍 Token من SharedPreferences: موجود
✅ Token موجود، جاري جلب البيانات من السيرفر...
```

**Token يعمل بشكل صحيح! ✅**

### لكن من Render Logs:
```
❌ error: "Column \"role\" does not exist"
```

**المشكلة:** قاعدة البيانات على Render **لا تحتوي على عمود `role`**!

---

## 🔧 الحل:

### الخطوة 1️⃣: افتح Render Dashboard
1. اذهب إلى: https://dashboard.render.com
2. اختر `dalma-db` (قاعدة البيانات)
3. اضغط على **"Connect"** أو **"Shell"**

### الخطوة 2️⃣: نفذ هذا الأمر SQL:

```sql
-- إضافة عمود role
ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user';

-- تحديث المستخدمين الموجودين
UPDATE users SET role = 'user' WHERE role IS NULL;

-- التحقق من النتيجة
SELECT id, name, phone, role, created_at FROM users ORDER BY id DESC LIMIT 5;
```

### الخطوة 3️⃣: تحقق من النتيجة
يجب أن ترى:
```
id | name  | phone       | role | created_at
---+-------+-------------+------+------------
23 | Kim's | 0509090090  | user | 2025-10-13
...
```

---

## 🚀 بعد تحديث قاعدة البيانات:

### 1️⃣ في التطبيق:
- اضغط `R` (Hot Restart)

### 2️⃣ افتح صفحة "حسابي"

**ستعمل بشكل مثالي! 🎊**

---

## 📝 ملاحظة مهمة:

### لماذا حدثت هذه المشكلة؟

عندما أنشأنا قاعدة البيانات على Render لأول مرة، استخدمنا `init.sql` القديم الذي **لا يحتوي على عمود `role`**.

الكود الجديد الذي رفعناه يتوقع وجود عمود `role`، لذلك نحتاج تحديث قاعدة البيانات يدوياً.

---

## 🔍 كيف تتحقق من Render Shell:

### الطريقة 1: من Dashboard
1. افتح Render Dashboard
2. اذهب إلى `dalma-db`
3. اضغط **"Connect"**
4. اختر **"External Connection"**
5. انسخ الأمر واستخدمه في Terminal

### الطريقة 2: من Terminal مباشرة
```bash
# استخدم DATABASE_URL من Environment Variables
psql "postgresql://USER:PASSWORD@HOST/DATABASE?sslmode=require"
```

---

## ✅ البديل السريع (إذا لم تستطع الوصول للـ Shell):

### يمكنني إضافة migration script في الكود:

سأضيف في `index.js`:
```javascript
// Auto-migration: إضافة عمود role إذا لم يكن موجوداً
pool.query(`
  ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user'
`).catch(err => console.log('Migration already applied or error:', err.message));
```

**هل تريد هذا الحل؟** (سيتم تطبيقه تلقائياً عند إعادة تشغيل السيرفر)

---

## 🎯 الخلاصة:

| المشكلة | الحل |
|---------|------|
| Token لا يعمل | ✅ تم الحل - Token يعمل! |
| قاعدة البيانات قديمة | ⏳ نحتاج إضافة عمود `role` |
| الحل | تنفيذ SQL في Render Shell |

---

## 💡 الحل الأسرع:

**سأضيف auto-migration في الكود الآن!**

لن تحتاج فعل أي شيء، فقط:
1. انتظر دقيقتين
2. اضغط `R` في التطبيق
3. افتح "حسابي"

**سيعمل تلقائياً! 🚀**

**هل تريد أن أضيف auto-migration الآن؟**

