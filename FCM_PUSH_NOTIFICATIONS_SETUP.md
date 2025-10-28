# 🔔 دليل إعداد Push Notifications (FCM)

## ✅ ما تم إضافته

تم إضافة نظام **Push Notifications** كامل يرسل إشعارات للمستخدمين **حتى لو كانوا خارج التطبيق**!

---

## 📋 الميزات

| # | الميزة |
|---|--------|
| 1 | إشعار Push عند قبول طلب إعلامي |
| 2 | إشعار Push عند رفض طلب إعلامي |
| 3 | إشعار Push عند قبول طلب مقدم خدمة |
| 4 | إشعار Push عند رفض طلب مقدم خدمة |
| 5 | الإشعار يصل حتى لو كان التطبيق مغلقاً |

---

## 🔧 خطوات التفعيل

### 1️⃣ الحصول على Firebase Server Key

1. افتح [Firebase Console](https://console.firebase.google.com/)
2. اختر مشروع **Dalma**
3. اذهب إلى **Project Settings** (⚙️)
4. اختر تبويب **Cloud Messaging**
5. انسخ **Server key**

### 2️⃣ إضافة Server Key إلى Render

1. افتح [Render Dashboard](https://dashboard.render.com/)
2. اختر **dalma-api**
3. اذهب إلى **Environment**
4. أضف متغير بيئة جديد:
   - **Key:** `FIREBASE_SERVER_KEY`
   - **Value:** (الصق Server Key من Firebase)
5. احفظ التغييرات

### 3️⃣ إعادة تشغيل Server

سيعيد Render تشغيل Server تلقائياً بعد إضافة المتغير.

---

## 📱 كيف يعمل

```
Admin Dashboard
     ↓
يرفض/يقبل طلب
     ↓
Backend API
     ↓
1. حفظ الإشعار في notification_logs
2. إرسال Push Notification عبر FCM
     ↓
Firebase Cloud Messaging
     ↓
هاتف المستخدم (حتى لو كان التطبيق مغلقاً!)
```

---

## 🧪 اختبار Push Notifications

### الطريقة 1: من Admin Dashboard

1. افتح Admin Dashboard
2. اذهب إلى **إدارة الطلبات**
3. ارفض/اقبل طلب جديد
4. **أغلق التطبيق تماماً** على الهاتف
5. يجب أن يصل إشعار Push!

### الطريقة 2: من Render Logs

1. افتح Render Dashboard
2. اختر **dalma-api**
3. اذهب إلى **Logs**
4. ابحث عن:
   ```
   📲 [FCM] إرسال Push Notification للمستخدم...
   ✅ [FCM] تم إرسال Push Notification للمستخدم
   ```

---

## 🐛 حل المشاكل

### المشكلة: لا يصل Push Notification

**الحلول:**

1. **تأكد من إضافة `FIREBASE_SERVER_KEY`:**
   ```bash
   # في Render Environment Variables
   FIREBASE_SERVER_KEY=AAAA...your-key-here
   ```

2. **تأكد من أن المستخدم لديه FCM Token:**
   - افتح التطبيق مرة واحدة على الأقل
   - يجب أن يظهر في Logs:
     ```
     ✅ [FCM] Token sent successfully
     ```

3. **تأكد من أن Firebase Project صحيح:**
   - Server Key يجب أن يكون من نفس المشروع المستخدم في التطبيق

4. **تحقق من Render Logs:**
   ```
   ⚠️ [FCM] المستخدم X ليس لديه FCM token
   ❌ [FCM] FIREBASE_SERVER_KEY غير موجود في .env
   ❌ [FCM] فشل إرسال Push Notification
   ```

---

## 📊 Logs مفيدة

### عند نجاح الإرسال:
```
📲 [FCM] إرسال Push Notification للمستخدم 123...
✅ [FCM] تم إرسال Push Notification للمستخدم 123
📧 [NOTIFICATION] تم إرسال إشعار الرفض للمستخدم 123
```

### عند فشل الإرسال:
```
⚠️ [FCM] المستخدم 123 ليس لديه FCM token
```
أو
```
❌ [FCM] FIREBASE_SERVER_KEY غير موجود في .env
```

---

## 🎯 الخلاصة

✅ **تم تفعيل Push Notifications بالكامل!**

**ما تحتاجه فقط:**
1. إضافة `FIREBASE_SERVER_KEY` إلى Render Environment Variables
2. اختبار من Admin Dashboard

**النتيجة:**
- المستخدم يستلم إشعار حتى لو كان التطبيق مغلقاً! 🎉

---

**آخر تحديث:** 23 أكتوبر 2025
