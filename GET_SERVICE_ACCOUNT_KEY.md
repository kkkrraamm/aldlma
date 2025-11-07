# 🔑 كيفية الحصول على Firebase Service Account Key

## 📋 الخطوات المطلوبة

### 1️⃣ افتح Firebase Console
```
https://console.firebase.google.com/
```

### 2️⃣ اختر مشروعك (aldlma)

### 3️⃣ اذهب إلى Project Settings
- اضغط على أيقونة ⚙️ (Settings) في الشريط الجانبي
- اختر **Project settings**

### 4️⃣ اذهب إلى Service accounts
- في الأعلى، اختر تبويب **Service accounts**

### 5️⃣ احصل على Service Account Key
1. ستجد قسم **Firebase Admin SDK**
2. اختر **Node.js** (إذا لم يكن محدداً)
3. اضغط على زر **Generate new private key**
4. سيظهر تحذير - اضغط **Generate key**
5. سيتم تحميل ملف JSON

### 6️⃣ احفظ الملف
- اسم الملف سيكون شبيهاً بـ: `aldlma-c5a4f-firebase-adminsdk-xxxxx.json`
- احفظه في مكان آمن!
- **لا تشاركه مع أحد!**

### 7️⃣ أضف الملف إلى Render
1. افتح Render Dashboard
2. اختر dalma-api service
3. اذهب إلى **Environment**
4. أضف متغير جديد:
   - **Key**: `FIREBASE_SERVICE_ACCOUNT`
   - **Value**: انسخ **محتوى الملف JSON بالكامل** والصقه هنا
   
   مثال:
   ```json
   {
     "type": "service_account",
     "project_id": "aldlma-c5a4f",
     "private_key_id": "xxxxx",
     "private_key": "-----BEGIN PRIVATE KEY-----\nXXXXX\n-----END PRIVATE KEY-----\n",
     "client_email": "firebase-adminsdk-xxxxx@aldlma-c5a4f.iam.gserviceaccount.com",
     "client_id": "xxxxx",
     "auth_uri": "https://accounts.google.com/o/oauth2/auth",
     "token_uri": "https://oauth2.googleapis.com/token",
     "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
     "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xxxxx%40aldlma-c5a4f.iam.gserviceaccount.com"
   }
   ```

5. اضغط **Save Changes**

---

## ⚠️ ملاحظات مهمة

### 🔒 الأمان
- **لا تضع هذا الملف في Git!**
- **لا تشاركه مع أحد!**
- هذا المفتاح يعطي صلاحيات كاملة لمشروع Firebase

### 📝 نسخ احتياطي
- احتفظ بنسخة احتياطية من الملف
- إذا فقدته، يمكنك إنشاء مفتاح جديد

### 🔄 إذا فقدت المفتاح
1. اذهب إلى Service accounts
2. احذف المفتاح القديم (اختياري)
3. أنشئ مفتاح جديد
4. حدّث Render Environment Variables

---

## 🧪 اختبار بعد الإضافة

### 1️⃣ انتظر إعادة تشغيل Render
- بعد حفظ Environment Variable
- Render سيعيد تشغيل السيرفر تلقائياً
- انتظر 1-2 دقيقة

### 2️⃣ افتح Render Logs
- يجب أن ترى:
  ```
  ✅ [FCM] Firebase Admin SDK initialized successfully
  ```

### 3️⃣ اختبر من التطبيق
1. سجل دخول في التطبيق
2. قدم طلب إعلامي
3. ارفضه من Admin Dashboard
4. يجب أن يصل Push Notification! 🎉

---

## ❓ استكشاف الأخطاء

### ❌ خطأ: `FIREBASE_SERVICE_ACCOUNT is not defined`
**الحل:** تأكد من إضافة المتغير في Render وإعادة تشغيل السيرفر

### ❌ خطأ: `Failed to parse service account key`
**الحل:** تأكد من نسخ **محتوى الملف JSON بالكامل** بدون أخطاء

### ❌ خطأ: `Permission denied`
**الحل:** تأكد من أن Service Account لديه صلاحيات Firebase Cloud Messaging

---

## 📞 الدعم

إذا واجهت أي مشاكل:
1. تحقق من Render Logs
2. تحقق من Flutter Console Logs
3. تحقق من Firebase Console → Cloud Messaging

---

**بعد إضافة Service Account Key، سيعمل Push Notifications بنجاح!** 🎉




## 📋 الخطوات المطلوبة

### 1️⃣ افتح Firebase Console
```
https://console.firebase.google.com/
```

### 2️⃣ اختر مشروعك (aldlma)

### 3️⃣ اذهب إلى Project Settings
- اضغط على أيقونة ⚙️ (Settings) في الشريط الجانبي
- اختر **Project settings**

### 4️⃣ اذهب إلى Service accounts
- في الأعلى، اختر تبويب **Service accounts**

### 5️⃣ احصل على Service Account Key
1. ستجد قسم **Firebase Admin SDK**
2. اختر **Node.js** (إذا لم يكن محدداً)
3. اضغط على زر **Generate new private key**
4. سيظهر تحذير - اضغط **Generate key**
5. سيتم تحميل ملف JSON

### 6️⃣ احفظ الملف
- اسم الملف سيكون شبيهاً بـ: `aldlma-c5a4f-firebase-adminsdk-xxxxx.json`
- احفظه في مكان آمن!
- **لا تشاركه مع أحد!**

### 7️⃣ أضف الملف إلى Render
1. افتح Render Dashboard
2. اختر dalma-api service
3. اذهب إلى **Environment**
4. أضف متغير جديد:
   - **Key**: `FIREBASE_SERVICE_ACCOUNT`
   - **Value**: انسخ **محتوى الملف JSON بالكامل** والصقه هنا
   
   مثال:
   ```json
   {
     "type": "service_account",
     "project_id": "aldlma-c5a4f",
     "private_key_id": "xxxxx",
     "private_key": "-----BEGIN PRIVATE KEY-----\nXXXXX\n-----END PRIVATE KEY-----\n",
     "client_email": "firebase-adminsdk-xxxxx@aldlma-c5a4f.iam.gserviceaccount.com",
     "client_id": "xxxxx",
     "auth_uri": "https://accounts.google.com/o/oauth2/auth",
     "token_uri": "https://oauth2.googleapis.com/token",
     "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
     "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xxxxx%40aldlma-c5a4f.iam.gserviceaccount.com"
   }
   ```

5. اضغط **Save Changes**

---

## ⚠️ ملاحظات مهمة

### 🔒 الأمان
- **لا تضع هذا الملف في Git!**
- **لا تشاركه مع أحد!**
- هذا المفتاح يعطي صلاحيات كاملة لمشروع Firebase

### 📝 نسخ احتياطي
- احتفظ بنسخة احتياطية من الملف
- إذا فقدته، يمكنك إنشاء مفتاح جديد

### 🔄 إذا فقدت المفتاح
1. اذهب إلى Service accounts
2. احذف المفتاح القديم (اختياري)
3. أنشئ مفتاح جديد
4. حدّث Render Environment Variables

---

## 🧪 اختبار بعد الإضافة

### 1️⃣ انتظر إعادة تشغيل Render
- بعد حفظ Environment Variable
- Render سيعيد تشغيل السيرفر تلقائياً
- انتظر 1-2 دقيقة

### 2️⃣ افتح Render Logs
- يجب أن ترى:
  ```
  ✅ [FCM] Firebase Admin SDK initialized successfully
  ```

### 3️⃣ اختبر من التطبيق
1. سجل دخول في التطبيق
2. قدم طلب إعلامي
3. ارفضه من Admin Dashboard
4. يجب أن يصل Push Notification! 🎉

---

## ❓ استكشاف الأخطاء

### ❌ خطأ: `FIREBASE_SERVICE_ACCOUNT is not defined`
**الحل:** تأكد من إضافة المتغير في Render وإعادة تشغيل السيرفر

### ❌ خطأ: `Failed to parse service account key`
**الحل:** تأكد من نسخ **محتوى الملف JSON بالكامل** بدون أخطاء

### ❌ خطأ: `Permission denied`
**الحل:** تأكد من أن Service Account لديه صلاحيات Firebase Cloud Messaging

---

## 📞 الدعم

إذا واجهت أي مشاكل:
1. تحقق من Render Logs
2. تحقق من Flutter Console Logs
3. تحقق من Firebase Console → Cloud Messaging

---

**بعد إضافة Service Account Key، سيعمل Push Notifications بنجاح!** 🎉



