# 🚀 كيفية الاستخدام - Dalma

## 📋 الإعداد الأولي

### 1️⃣ **تفعيل الحماية في Render:**

1. افتح: https://dashboard.render.com
2. اختر `dalma-api`
3. اذهب إلى `Environment`
4. أضف/عدّل المتغيرات التالية:

```env
SECURITY_ENABLED=true
ADMIN_ALLOWED_IPS=YOUR_IP_HERE
```

5. احفظ التغييرات (سيعيد بناء السيرفر تلقائياً)

---

### 2️⃣ **معرفة IP جهازك:**

```bash
# في Terminal:
curl https://api.ipify.org

# النتيجة مثلاً:
211.25.233.178
```

ضع هذا الرقم في `ADMIN_ALLOWED_IPS`

---

## 🌐 استخدام الموقع الخارجي (Admin Dashboard)

### **الخطوات:**

1. **افتح الموقع:**
   ```
   file:///Users/kimaalanzi/Desktop/aaldma/dalma-admin/login.html
   ```

2. **سجل دخول:**
   - Username: `admin`
   - Password: (كلمة المرور المحفوظة في `ADMIN_PASSWORD`)

3. **ماذا يحدث:**
   - السيرفر يتحقق من IP جهازك
   - إذا كان مصرح: يرسل Token + API Key
   - يُحفظ API Key في localStorage
   - جميع الطلبات التالية تستخدم API Key تلقائياً

4. **إذا حصل خطأ:**
   - تحقق من أن IP جهازك في `ADMIN_ALLOWED_IPS`
   - تحقق من أن `SECURITY_ENABLED=true`

---

## 📱 استخدام التطبيق (Flutter)

### **الخطوات:**

1. **شغّل التطبيق:**
   ```bash
   cd /Users/kimaalanzi/Desktop/aaldma/aldlma
   flutter run
   ```

2. **سجل دخول أو أنشئ حساب:**
   - التطبيق سيرسل API Key + Device ID تلقائياً
   - لا حاجة لأي إعداد إضافي

3. **تحقق من Logs:**
   ```
   🔒 [SECURITY] إضافة API Key و Device ID
   ```

---

## 🔧 إيقاف الحماية مؤقتاً (للتطوير)

إذا أردت إيقاف الحماية مؤقتاً:

```env
SECURITY_ENABLED=false
```

⚠️ **تحذير:** لا تفعل هذا في الإنتاج!

---

## 🧪 الاختبار

### **اختبار الموقع الخارجي:**

```bash
# من جهازك:
curl -X POST https://dalma-api.onrender.com/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "YOUR_PASSWORD"}'

# يجب أن ترى:
{
  "success": true,
  "token": "...",
  "apiKey": "..."
}
```

### **اختبار التطبيق:**

```bash
# مع API Key + Device ID:
curl -X POST https://dalma-api.onrender.com/login \
  -H "X-API-Key: YOUR_API_KEY" \
  -H "X-Device-ID: test-device" \
  -d '{"phone": "0597414141", "password": "test123"}'
```

---

## 📊 مراقبة النظام

### **عرض Logs في Render:**

1. افتح: https://dashboard.render.com
2. اختر `dalma-api`
3. اذهب إلى `Logs`
4. ابحث عن:
   - `🔍 [ADMIN IP CHECK]` - محاولات الوصول للـ Admin
   - `🚫 محاولة وصول` - محاولات مشبوهة
   - `✅ [ADMIN IP CHECK] IP مصرح به` - وصول ناجح

---

## 🛠️ حل المشاكل

### **المشكلة: "IP غير مسموح"**

**الحل:**
1. تحقق من IP جهازك: `curl https://api.ipify.org`
2. تحقق من `ADMIN_ALLOWED_IPS` في Render
3. تأكد أنهما متطابقان

---

### **المشكلة: "معرف الجهاز مطلوب"**

**الحل:**
- تأكد أن التطبيق يرسل `X-Device-ID` في Headers
- تحقق من Logs في Flutter

---

### **المشكلة: "مفتاح API غير صحيح"**

**الحل:**
- تأكد أن `APP_API_KEY` محفوظ في Render
- تأكد أن التطبيق/الموقع يرسل نفس المفتاح

---

## 📝 ملاحظات مهمة

1. ✅ **API Key لا يظهر في الكود**
   - يُخزن في Environment Variables
   - يُرسل فقط بعد المصادقة

2. ✅ **الموقع الخارجي محمي**
   - فقط IP جهازك يمكنه الوصول
   - أي IP آخر يُرفض

3. ✅ **التطبيق محمي**
   - Device ID مطلوب
   - Rate Limiting نشط
   - تتبع كامل للأجهزة

---

✅ **جاهز للاستخدام!** 🚀
