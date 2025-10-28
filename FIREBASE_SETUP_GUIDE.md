# 🔥 دليل إعداد Firebase Push Notifications لتطبيق Dalma

## 📋 الخطوات المطلوبة

### 1️⃣ إنشاء مشروع Firebase

1. اذهب إلى [Firebase Console](https://console.firebase.google.com/)
2. اضغط "Add project" أو "إضافة مشروع"
3. اسم المشروع: `Dalma` (أو أي اسم تريده)
4. اتبع الخطوات حتى يتم إنشاء المشروع

---

### 2️⃣ إضافة تطبيق iOS

#### الخطوة 1: إضافة التطبيق
1. في Firebase Console، اختر مشروعك
2. اضغط على أيقونة iOS (🍎)
3. املأ البيانات:
   - **iOS bundle ID**: `com.dalma.app` (أو bundle ID الخاص بك)
   - **App nickname**: `Dalma iOS`
   - **App Store ID**: (اتركه فارغاً الآن)

#### الخطوة 2: تحميل GoogleService-Info.plist
1. اضغط "Download GoogleService-Info.plist"
2. احفظ الملف في مكان آمن

#### الخطوة 3: إضافة الملف إلى Xcode
1. افتح مشروع iOS في Xcode:
   ```bash
   cd /Users/kimaalanzi/Desktop/aaldma/aldlma/ios
   open Runner.xcworkspace
   ```

2. اسحب ملف `GoogleService-Info.plist` إلى مجلد `Runner` في Xcode
3. تأكد من تحديد:
   - ✅ Copy items if needed
   - ✅ Runner (في Target)

---

### 3️⃣ إضافة تطبيق Android

#### الخطوة 1: إضافة التطبيق
1. في Firebase Console، اضغط على أيقونة Android (🤖)
2. املأ البيانات:
   - **Android package name**: `com.dalma.app` (أو package name الخاص بك)
   - **App nickname**: `Dalma Android`
   - **Debug signing certificate SHA-1**: (اختياري)

#### الخطوة 2: تحميل google-services.json
1. اضغط "Download google-services.json"
2. احفظ الملف

#### الخطوة 3: إضافة الملف إلى المشروع
انسخ الملف إلى:
```bash
cp google-services.json /Users/kimaalanzi/Desktop/aaldma/aldlma/android/app/
```

---

### 4️⃣ الحصول على Firebase Service Account Key

1. في Firebase Console، اذهب إلى:
   **Project Settings** ⚙️ → **Service accounts**

2. اضغط على **Generate new private key**

3. سيظهر تحذير - اضغط **Generate key**

4. سيتم تحميل ملف JSON - احفظه في مكان آمن!

5. أضفه إلى Render Environment Variables:
   - **Key**: `FIREBASE_SERVICE_ACCOUNT`
   - **Value**: انسخ **محتوى الملف JSON بالكامل** والصقه
   
   مثال:
   ```json
   {
     "type": "service_account",
     "project_id": "aldlma-c5a4f",
     "private_key_id": "xxxxx",
     "private_key": "-----BEGIN PRIVATE KEY-----\nXXXXX\n-----END PRIVATE KEY-----\n",
     "client_email": "firebase-adminsdk-xxxxx@aldlma-c5a4f.iam.gserviceaccount.com",
     ...
   }
   ```

---

### 5️⃣ التحقق من Bundle ID / Package Name

#### iOS:
1. افتح ملف:
   ```
   /Users/kimaalanzi/Desktop/aaldma/aldlma/ios/Runner.xcodeproj/project.pbxproj
   ```
2. ابحث عن `PRODUCT_BUNDLE_IDENTIFIER`
3. تأكد أنه يطابق ما أدخلته في Firebase

#### Android:
1. افتح ملف:
   ```
   /Users/kimaalanzi/Desktop/aaldma/aldlma/android/app/build.gradle
   ```
2. ابحث عن `applicationId`
3. تأكد أنه يطابق ما أدخلته في Firebase

---

### 6️⃣ اختبار Push Notifications

#### الخطوة 1: تشغيل التطبيق
```bash
cd /Users/kimaalanzi/Desktop/aaldma/aldlma
flutter run
```

#### الخطوة 2: تسجيل الدخول
- سجل دخول في التطبيق
- يجب أن ترى في Console:
  ```
  ✅ [FCM] Permission granted
  📱 [FCM] Token: XXXXX...
  📤 [FCM] Sending token to backend...
  ✅ [FCM] Token sent successfully
  ```

#### الخطوة 3: اختبار من Admin Dashboard
1. قدم طلب إعلامي من التطبيق
2. ارفضه من Admin Dashboard
3. يجب أن يصل Push Notification!

---

## 🔍 استكشاف الأخطاء

### ❌ خطأ: `[core/no-app] No Firebase App '[DEFAULT]' has been created`

**السبب:** ملفات Firebase غير موجودة

**الحل:**
1. تأكد من وجود `GoogleService-Info.plist` في `ios/Runner/`
2. تأكد من وجود `google-services.json` في `android/app/`
3. أعد تشغيل التطبيق

---

### ❌ خطأ: `⚠️ [FCM] المستخدم X ليس لديه FCM token`

**السبب:** التطبيق لم يرسل FCM token إلى السيرفر

**الحل:**
1. تأكد من تسجيل الدخول في التطبيق
2. تأكد من أن endpoint `/api/user/fcm-token` يعمل
3. تحقق من Logs التطبيق:
   ```
   ✅ [FCM] Token sent successfully
   ```

---

### ❌ خطأ: `❌ [FCM] Failed to send token: 401`

**السبب:** مشكلة في Authentication

**الحل:**
1. تأكد من أن `api_key` موجود في SharedPreferences
2. تأكد من أن `token` صالح
3. تحقق من endpoint في Backend

---

## 📱 الحالة الحالية

### ✅ ما تم إنجازه:
- ✅ إضافة `firebase_core` و `firebase_messaging` إلى `pubspec.yaml`
- ✅ إنشاء `NotificationsService` في `lib/notifications_service.dart`
- ✅ تهيئة Firebase في `main.dart`
- ✅ إضافة endpoint `/api/user/fcm-token` في Backend
- ✅ إضافة `sendPushNotification()` في Backend
- ✅ إرسال Push Notifications عند قبول/رفض/حذف الطلبات

### ⚠️ ما ينقص:
- ❌ ملف `GoogleService-Info.plist` (iOS)
- ❌ ملف `google-services.json` (Android)
- ❌ Firebase Server Key في Render

---

## 🎯 الخطوات التالية

1. **أنشئ مشروع Firebase** (إذا لم يكن موجوداً)
2. **أضف تطبيق iOS** وحمّل `GoogleService-Info.plist`
3. **أضف تطبيق Android** وحمّل `google-services.json`
4. **احصل على Firebase Server Key** وأضفه إلى Render
5. **اختبر Push Notifications**

---

## 📞 الدعم

إذا واجهت أي مشاكل:
1. تحقق من Render Logs
2. تحقق من Flutter Console Logs
3. تحقق من Firebase Console → Cloud Messaging

---

**ملاحظة:** بعد إضافة ملفات Firebase، ستحتاج إلى إعادة تشغيل التطبيق:
```bash
flutter clean
flutter pub get
flutter run
```

🎉 **بالتوفيق!**

