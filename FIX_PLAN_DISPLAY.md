# ✅ إصلاح: عرض الباقة الصحيحة في قائمة المستخدم

## ❌ **المشكلة:**

القائمة تعرض "مجاني" رغم أن الباقة "احترافي"

**السبب:**
```javascript
// localStorage يحتوي على:
{
  plan_code: 'pro',
  plan_name: 'احترافي'
}

// لكن الكود يبحث عن:
officeData.plan?.code  // undefined!
officeData.plan?.name_ar  // undefined!
```

---

## ✅ **الحل:**

### 1️⃣ **تحديث refresh-data.js:**

```javascript
// بناء كائن الباقة بشكل صحيح
const officeWithPlan = {
    ...data.office,
    plan: {
        code: data.office.plan_code || 'free',
        name_ar: data.office.plan_name || 'مجاني',
        price: data.office.price || 0,
        max_listings: data.office.max_listings || 5,
        max_images_per_listing: data.office.max_images_per_listing || 8
    }
};

localStorage.setItem('office_data', JSON.stringify(officeWithPlan));
```

**النتيجة:**
```javascript
// الآن localStorage يحتوي على:
{
  plan_code: 'pro',
  plan_name: 'احترافي',
  plan: {
    code: 'pro',
    name_ar: 'احترافي',
    price: 499,
    max_listings: 80,
    max_images_per_listing: 20
  }
}
```

### 2️⃣ **تحديث toggleUserMenu():**

```javascript
async function toggleUserMenu() {
    // تحديث البيانات من السيرفر أولاً
    if (window.refreshOfficeData) {
        await window.refreshOfficeData();
    }
    
    // الآن البيانات محدثة
    const officeData = JSON.parse(localStorage.getItem('office_data') || '{}');
    const currentUser = {
        plan: officeData.plan?.name_ar || 'مجاني',
        planCode: officeData.plan?.code || 'free'
    };
}
```

### 3️⃣ **إضافة refreshOfficeData() عالمياً:**

```javascript
window.refreshOfficeData = refreshOfficeData;
```

---

## 🧪 **الاختبار:**

### اختبار 1: فتح القائمة
```
1. أعد تحميل الصفحة (Ctrl+Shift+R)
2. اضغط على اسم المكتب
3. ✅ يجب أن تظهر "احترافي" بدلاً من "مجاني"
4. ✅ يجب أن يكون اللون بنفسجي
```

### اختبار 2: التحقق من Console
```
1. افتح Console
2. اضغط على اسم المكتب
3. يجب أن ترى:
   ✅ [REFRESH MANUAL] تم تحديث البيانات: { code: 'pro', name_ar: 'احترافي', ... }
```

### اختبار 3: التحقق من localStorage
```
1. في Console، اكتب:
   JSON.parse(localStorage.getItem('office_data')).plan
   
2. يجب أن يعيد:
   { code: 'pro', name_ar: 'احترافي', price: 499, ... }
```

---

## 📊 **المقارنة:**

| العنصر | قبل | بعد |
|--------|-----|-----|
| **plan.code** | undefined | 'pro' ✅ |
| **plan.name_ar** | undefined | 'احترافي' ✅ |
| **العرض** | "مجاني" | "احترافي" ✅ |
| **اللون** | رمادي | بنفسجي ✅ |

---

## 📂 **الملفات المُعدلة:**

### 1️⃣ **refresh-data.js:**
- بناء كائن `plan` بشكل صحيح
- حفظ في `localStorage`
- إضافة `refreshOfficeData()` عالمياً

### 2️⃣ **team.js:**
- استدعاء `await refreshOfficeData()` قبل فتح القائمة
- التأكد من تحديث البيانات

---

## ✅ **الخلاصة:**

**المشكلة:**
- `localStorage` لا يحتوي على `plan` object
- فقط `plan_code` و `plan_name` منفصلين

**الحل:**
- بناء `plan` object كامل
- تحديث قبل فتح القائمة
- حفظ بشكل صحيح

---

**الآن أعد تحميل الصفحة وجرب!** 🔄✨

**يجب أن تظهر "احترافي" بدلاً من "مجاني"!** ✅


