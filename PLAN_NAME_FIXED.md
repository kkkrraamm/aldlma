# ✅ إصلاح نهائي: عرض اسم الباقة بالعربي

## 🔍 **المشكلة:**

```javascript
❌ API كان يرجع:
   p.name as plan_name  // 'Professional' (إنجليزي)

✅ يجب أن يرجع:
   p.name_ar as plan_name  // 'احترافي' (عربي)
```

---

## ✅ **التعديلات:**

### 1️⃣ **في API (`dalma-api/index.js`):**
```sql
-- قبل:
p.name as plan_name

-- بعد:
p.name_ar as plan_name
```

### 2️⃣ **في `refresh-data.js`:**
```javascript
// قراءة من data.office.plan بدلاً من data.office.plan_code
plan: {
    code: data.office.plan?.code || 'free',
    name_ar: data.office.plan?.name || 'مجاني'
}
```

### 3️⃣ **في `user-menu.js`:**
```javascript
// دعم كلا الحقلين
const planName = officeData.plan?.name_ar || officeData.plan?.name || 'مجاني';
```

---

## 📤 **تم الرفع:**

```bash
✅ git commit: "Fix: عرض الباقة الصحيحة في قائمة المستخدم"
✅ git push: dalma-api
✅ git push: aaldma
```

---

## ⏳ **الخطوات التالية:**

```
1. انتظر 2-3 دقائق (Render Deploy)
2. أعد تحميل الصفحة (Ctrl+Shift+R)
3. اضغط على "إداري"
4. ✅ يظهر "احترافي" بدلاً من "مجاني"
```

---

## 🧪 **التحقق بعد Deploy:**

```javascript
// في Console:
JSON.parse(localStorage.getItem('office_data')).plan
// النتيجة المتوقعة:
// {code: 'pro', name_ar: 'احترافي', ...}
```

---

**انتظر Deploy ثم أعد تحميل الصفحة!** ⏳✨

