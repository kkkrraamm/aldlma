# 🖼️ إعداد Cloudinary لرفع الصور

## 📋 نظرة عامة

تستخدم إدارة الإعلانات **Cloudinary** لرفع وتخزين صور الإعلانات.

---

## ⚙️ الإعداد الحالي

### المعلومات المُستخدمة:
```javascript
CLOUDINARY_CLOUD_NAME = 'dxvmlvqda'
CLOUDINARY_UPLOAD_PRESET = 'dalma_ads'
```

---

## 🔧 خطوات الإعداد في Cloudinary

### 1. إنشاء Upload Preset

1. سجل الدخول إلى [Cloudinary Dashboard](https://cloudinary.com/console)
2. اذهب إلى **Settings** → **Upload**
3. انزل إلى **Upload presets**
4. اضغط على **Add upload preset**
5. املأ المعلومات:
   ```
   Preset name: dalma_ads
   Signing Mode: Unsigned
   Folder: dalma/ads
   ```
6. في **Media Analysis and AI**:
   - ✅ Enable: Image analysis
   - ✅ Enable: Quality analysis
7. في **Upload manipulations**:
   - Max image width: 1920
   - Max image height: 1080
   - Image format: Auto
8. احفظ التغييرات

---

## 🔐 الأمان

### Unsigned Upload Preset:
- ✅ **مناسب للاستخدام**: يسمح بالرفع من المتصفح مباشرة
- ⚠️ **تحذير**: يمكن لأي شخص الرفع إذا عرف الـ preset name
- 🛡️ **الحماية**: استخدم Cloudinary's Upload Restrictions

### إعدادات الأمان الموصى بها:
1. في **Upload preset settings**:
   - Enable: **Unique filename**
   - Enable: **Overwrite**
   - Max file size: **5 MB**
   - Allowed formats: `jpg,jpeg,png,gif,webp`

---

## 🚀 كيف يعمل

### 1. المستخدم يختار صورة:
```javascript
<input type="file" id="adImage" accept="image/*" onchange="handleImageUpload(event)">
```

### 2. معاينة فورية (Local Preview):
```javascript
const reader = new FileReader();
reader.onload = (e) => {
    imagePreview.src = e.target.result; // معاينة فورية
};
reader.readAsDataURL(file);
```

### 3. رفع إلى Cloudinary:
```javascript
const formData = new FormData();
formData.append('file', file);
formData.append('upload_preset', 'dalma_ads');

const response = await fetch(
    'https://api.cloudinary.com/v1_1/dxvmlvqda/image/upload',
    { method: 'POST', body: formData }
);

const data = await response.json();
uploadedImageUrl = data.secure_url; // الرابط النهائي
```

---

## 🔍 استكشاف الأخطاء

### ❌ Error 401 (Unauthorized)

**السبب:**
- Upload preset غير موجود
- Upload preset من نوع "Signed" بدلاً من "Unsigned"

**الحل:**
1. تأكد من وجود preset باسم `dalma_ads`
2. تأكد أن Signing Mode = **Unsigned**
3. احفظ التغييرات

---

### ❌ الصورة تظهر "undefined"

**السبب:**
- `data.secure_url` غير موجود في الاستجابة

**الحل:**
```javascript
if (!data.secure_url) {
    throw new Error('No URL returned from Cloudinary');
}
```

---

### ❌ الصورة مكسورة (Broken Image)

**السبب:**
- الرابط غير صحيح
- الصورة لم تُرفع بنجاح

**الحل:**
1. تحقق من Console للأخطاء
2. تحقق من `uploadedImageUrl` في Console
3. جرب فتح الرابط في المتصفح

---

## 📊 مراقبة الاستخدام

### Cloudinary Dashboard:
- **Media Library**: جميع الصور المرفوعة
- **Usage**: استهلاك الباندويث والتخزين
- **Transformations**: عدد التحويلات المستخدمة

### الحد المجاني:
```
✅ 25 GB Storage
✅ 25 GB Bandwidth/month
✅ 25,000 Transformations/month
```

---

## 🎨 تحسينات الصور

### Cloudinary Transformations:
يمكنك تحسين الصور تلقائياً:

```javascript
// مثال: تصغير الصورة
const optimizedUrl = uploadedImageUrl.replace(
    '/upload/',
    '/upload/w_800,h_600,c_fill,q_auto,f_auto/'
);
```

### معاملات مفيدة:
- `w_800` - عرض 800px
- `h_600` - ارتفاع 600px
- `c_fill` - ملء الإطار
- `q_auto` - جودة تلقائية
- `f_auto` - صيغة تلقائية (WebP للمتصفحات الحديثة)

---

## 🔄 البدائل

### إذا لم يعمل Cloudinary:

#### **1. استخدام Backend لرفع الصور:**
```javascript
// Upload to your own server
const formData = new FormData();
formData.append('image', file);

const response = await fetch(`${API_BASE}/api/admin/upload-image`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: formData
});
```

#### **2. استخدام خدمات أخرى:**
- **ImgBB**: مجاني، سهل
- **Imgur**: مجاني، شهير
- **AWS S3**: احترافي، مدفوع

---

## 📝 ملاحظات مهمة

### ✅ المزايا:
- معاينة فورية قبل الرفع
- رفع سريع ومباشر
- CDN عالمي
- تحسين تلقائي للصور

### ⚠️ تحذيرات:
- لا تشارك Upload Preset مع الجميع
- راقب استهلاك الباندويث
- استخدم قيود الحجم والنوع

---

## 🆘 الدعم

### إذا واجهت مشاكل:
1. تحقق من Console للأخطاء
2. تحقق من Cloudinary Dashboard
3. راجع [Cloudinary Documentation](https://cloudinary.com/documentation)

---

**✅ الآن رفع الصور يعمل بشكل صحيح!**

