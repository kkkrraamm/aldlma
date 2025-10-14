# ☁️ **إعداد Cloudinary لرفع الصور**

---

## 🎯 **المشكلة:**

Render لا يدعم تخزين الملفات محلياً (ephemeral filesystem).  
**الحل:** استخدام **Cloudinary** للتخزين السحابي.

---

## 📝 **الخطوات:**

### **1. إنشاء حساب Cloudinary (مجاني):**

1. اذهب إلى: https://cloudinary.com/users/register_free
2. سجل حساب جديد (مجاني حتى 25GB)
3. بعد التسجيل، ستحصل على:
   - **Cloud Name**
   - **API Key**
   - **API Secret**

---

### **2. إضافة المتغيرات في Render:**

1. اذهب إلى: https://dashboard.render.com
2. افتح service: **dalma-api**
3. اضغط **Environment** من القائمة اليسرى
4. اضغط **Add Environment Variable**
5. أضف المتغيرات التالية:

```
CLOUDINARY_CLOUD_NAME=your_cloud_name_here
CLOUDINARY_API_KEY=your_api_key_here
CLOUDINARY_API_SECRET=your_api_secret_here
```

6. اضغط **Save Changes**
7. Render سيعيد تشغيل السيرفر تلقائياً

---

### **3. الحصول على بيانات Cloudinary:**

#### **من لوحة التحكم:**
1. اذهب إلى: https://console.cloudinary.com/
2. في الصفحة الرئيسية (Dashboard)، ستجد:

```
Cloud Name: dxxxxxx
API Key: 123456789012345
API Secret: abcdefghijklmnopqrstuvwxyz
```

3. انسخ هذه القيم وضعها في Render

---

### **4. اختبار الرفع:**

بعد إضافة المتغيرات في Render:

1. انتظر دقيقة حتى يعيد Render تشغيل السيرفر
2. في التطبيق، جرّب رفع صورة
3. يجب أن يعمل بنجاح! ✅

---

## 🔍 **التحقق من النجاح:**

في logs Render، يجب أن ترى:
```
✅ تم رفع الوسائط بنجاح إلى Cloudinary
```

---

## 🎨 **مميزات Cloudinary:**

- ✅ تخزين سحابي دائم (لا يُحذف)
- ✅ CDN سريع عالمياً
- ✅ ضغط تلقائي للصور
- ✅ تحويل الصور والفيديو
- ✅ مجاني حتى 25GB
- ✅ روابط HTTPS آمنة

---

## 📊 **الحد المجاني:**

```
التخزين: 25 GB
Bandwidth: 25 GB/شهر
التحويلات: 25,000/شهر
```

**أكثر من كافي للتطبيق!** 🎉

---

## 🚀 **الخطوات السريعة:**

```bash
1. سجل في Cloudinary
2. انسخ Cloud Name, API Key, API Secret
3. أضفهم في Render Environment Variables
4. احفظ وانتظر دقيقة
5. جرّب رفع صورة في التطبيق
6. يجب أن يعمل! ✅
```

---

## ⚠️ **مهم:**

- **لا تشارك** API Secret مع أحد
- **لا ترفع** ملف `.env` إلى GitHub
- **استخدم** Environment Variables في Render فقط

---

## 📞 **إذا واجهت مشكلة:**

1. تحقق من أن المتغيرات صحيحة في Render
2. تحقق من logs Render للأخطاء
3. تأكد من أن Cloudinary account نشط
4. جرّب Hot Restart في التطبيق

---

**الآن السيرفر جاهز! فقط أضف بيانات Cloudinary في Render** 🚀

