# دليل استخدام القائمة الجانبية الموحدة
## Dalma Admin Pro - Unified Sidebar Guide

---

## 📌 نظرة عامة

القائمة الجانبية الموحدة هي نظام ديناميكي يتم تحميله تلقائياً في جميع صفحات لوحة التحكم، مما يضمن:
- ✅ **واجهة موحدة** في جميع الصفحات
- ✅ **تحديث تلقائي** لعدد الطلبات المعلقة
- ✅ **حالة نشطة ديناميكية** بناءً على الصفحة الحالية
- ✅ **سهولة الصيانة** - تعديل واحد يطبق على كل الصفحات

---

## 🚀 كيفية استخدامها في أي صفحة

### 1️⃣ إضافة CSS Files

```html
<head>
    <!-- ... باقي الـ head tags ... -->
    <link rel="stylesheet" href="css/main.css">
    <link rel="stylesheet" href="css/unified-sidebar.css">
</head>
```

### 2️⃣ إضافة Sidebar Container

```html
<body>
    <!-- Unified Sidebar (loaded dynamically by sidebar.js) -->
    <div id="sidebarContainer"></div>
    
    <!-- باقي محتوى الصفحة -->
    <main class="main-content">
        <!-- المحتوى هنا -->
    </main>
</body>
```

### 3️⃣ تحميل JavaScript

```html
<!-- قبل إغلاق </body> -->
<script src="js/sidebar.js"></script>
<script src="js/main.js"></script>
<!-- باقي الـ scripts -->
```

---

## 📝 مثال كامل

```html
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>صفحة جديدة - Dalma Admin Pro</title>
    
    <!-- Fonts & Icons -->
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;900&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    
    <!-- CSS -->
    <link rel="stylesheet" href="css/main.css">
    <link rel="stylesheet" href="css/unified-sidebar.css">
</head>
<body>
    <!-- Unified Sidebar -->
    <div id="sidebarContainer"></div>
    
    <!-- Main Content -->
    <main class="main-content">
        <!-- Top Bar -->
        <div class="topbar">
            <div class="topbar-left">
                <button class="btn-icon" id="menuToggle">
                    <i class="fas fa-bars"></i>
                </button>
                <h1>صفحة جديدة</h1>
            </div>
            <div class="topbar-right">
                <button class="btn-icon" id="themeToggle">
                    <i class="fas fa-moon"></i>
                </button>
            </div>
        </div>
        
        <!-- Page Content -->
        <div class="page-content">
            <div class="card">
                <div class="card-header">
                    <h2>محتوى الصفحة</h2>
                </div>
                <div class="card-body">
                    <!-- محتوى الصفحة هنا -->
                </div>
            </div>
        </div>
    </main>
    
    <!-- Scripts -->
    <script src="js/sidebar.js"></script>
    <script src="js/main.js"></script>
</body>
</html>
```

---

## ⚙️ الميزات الديناميكية

### 1. تحديد الصفحة النشطة تلقائياً
القائمة تحدد تلقائياً الصفحة الحالية وتضيف class `active` للرابط المناسب.

### 2. تحديث عدد الطلبات المعلقة
يتم جلب عدد الطلبات المعلقة تلقائياً كل 30 ثانية من API.

### 3. عرض اسم المشرف
يتم عرض اسم المشرف المسجل دخول من `localStorage`.

### 4. Responsive Design
- على الشاشات الكبيرة: القائمة مرئية دائماً مع إمكانية طيها
- على الشاشات الصغيرة (موبايل): القائمة تظهر عند الضغط على زر القائمة

---

## 🎨 التخصيص

### تعديل القائمة
لإضافة أو تعديل عناصر القائمة، عدّل ملف `js/sidebar.js`:

```javascript
// في دالة createUnifiedSidebar()
<a href="new-page.html" class="nav-item" data-page="new-page">
    <i class="fas fa-new-icon"></i>
    <span>صفحة جديدة</span>
</a>
```

### تعديل الألوان
عدّل ملف `css/unified-sidebar.css`:

```css
.nav-item.active {
    background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
}
```

---

## 🔧 الدوال المتاحة

### `initUnifiedSidebar()`
تهيئة القائمة الجانبية (تُستدعى تلقائياً).

### `setActivePage()`
تحديد الصفحة النشطة بناءً على URL الحالي.

### `updateAdminInfo()`
تحديث معلومات المشرف من localStorage.

### `updatePendingRequestsCount()`
جلب وتحديث عدد الطلبات المعلقة من API.

---

## 📱 التوافق

- ✅ Chrome, Firefox, Safari, Edge (latest)
- ✅ Mobile & Tablet responsive
- ✅ RTL Support
- ✅ Dark Mode Support

---

## 🐛 استكشاف الأخطاء

### القائمة لا تظهر؟
1. تأكد من تحميل `js/sidebar.js`
2. تأكد من وجود `<div id="sidebarContainer"></div>`
3. افتح Console وتحقق من الأخطاء

### الصفحة النشطة غير محددة؟
تأكد من أن اسم ملف HTML يطابق `href` في `sidebar.js`.

### عدد الطلبات لا يظهر؟
1. تحقق من أن API يعمل
2. تحقق من وجود `admin_token` و `admin_apiKey` في localStorage

---

## 💡 نصائح

1. **لا تعدّل القائمة في كل صفحة**: عدّل فقط في `js/sidebar.js`
2. **استخدم data-page attribute**: لتحديد الصفحة الحالية
3. **احتفظ بـ id="menuToggle"**: للموبايل
4. **احتفظ بـ id="themeToggle"**: للثيم

---

## 📚 الملفات المطلوبة

```
dalma-admin-pro/
├── css/
│   ├── main.css
│   └── unified-sidebar.css
├── js/
│   ├── sidebar.js
│   └── main.js
└── [your-page].html
```

---

✅ **جاهز للاستخدام!**

الآن يمكنك إنشاء أي صفحة جديدة والقائمة ستظهر تلقائياً مع جميع الميزات! 🎉



## Dalma Admin Pro - Unified Sidebar Guide

---

## 📌 نظرة عامة

القائمة الجانبية الموحدة هي نظام ديناميكي يتم تحميله تلقائياً في جميع صفحات لوحة التحكم، مما يضمن:
- ✅ **واجهة موحدة** في جميع الصفحات
- ✅ **تحديث تلقائي** لعدد الطلبات المعلقة
- ✅ **حالة نشطة ديناميكية** بناءً على الصفحة الحالية
- ✅ **سهولة الصيانة** - تعديل واحد يطبق على كل الصفحات

---

## 🚀 كيفية استخدامها في أي صفحة

### 1️⃣ إضافة CSS Files

```html
<head>
    <!-- ... باقي الـ head tags ... -->
    <link rel="stylesheet" href="css/main.css">
    <link rel="stylesheet" href="css/unified-sidebar.css">
</head>
```

### 2️⃣ إضافة Sidebar Container

```html
<body>
    <!-- Unified Sidebar (loaded dynamically by sidebar.js) -->
    <div id="sidebarContainer"></div>
    
    <!-- باقي محتوى الصفحة -->
    <main class="main-content">
        <!-- المحتوى هنا -->
    </main>
</body>
```

### 3️⃣ تحميل JavaScript

```html
<!-- قبل إغلاق </body> -->
<script src="js/sidebar.js"></script>
<script src="js/main.js"></script>
<!-- باقي الـ scripts -->
```

---

## 📝 مثال كامل

```html
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>صفحة جديدة - Dalma Admin Pro</title>
    
    <!-- Fonts & Icons -->
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;900&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    
    <!-- CSS -->
    <link rel="stylesheet" href="css/main.css">
    <link rel="stylesheet" href="css/unified-sidebar.css">
</head>
<body>
    <!-- Unified Sidebar -->
    <div id="sidebarContainer"></div>
    
    <!-- Main Content -->
    <main class="main-content">
        <!-- Top Bar -->
        <div class="topbar">
            <div class="topbar-left">
                <button class="btn-icon" id="menuToggle">
                    <i class="fas fa-bars"></i>
                </button>
                <h1>صفحة جديدة</h1>
            </div>
            <div class="topbar-right">
                <button class="btn-icon" id="themeToggle">
                    <i class="fas fa-moon"></i>
                </button>
            </div>
        </div>
        
        <!-- Page Content -->
        <div class="page-content">
            <div class="card">
                <div class="card-header">
                    <h2>محتوى الصفحة</h2>
                </div>
                <div class="card-body">
                    <!-- محتوى الصفحة هنا -->
                </div>
            </div>
        </div>
    </main>
    
    <!-- Scripts -->
    <script src="js/sidebar.js"></script>
    <script src="js/main.js"></script>
</body>
</html>
```

---

## ⚙️ الميزات الديناميكية

### 1. تحديد الصفحة النشطة تلقائياً
القائمة تحدد تلقائياً الصفحة الحالية وتضيف class `active` للرابط المناسب.

### 2. تحديث عدد الطلبات المعلقة
يتم جلب عدد الطلبات المعلقة تلقائياً كل 30 ثانية من API.

### 3. عرض اسم المشرف
يتم عرض اسم المشرف المسجل دخول من `localStorage`.

### 4. Responsive Design
- على الشاشات الكبيرة: القائمة مرئية دائماً مع إمكانية طيها
- على الشاشات الصغيرة (موبايل): القائمة تظهر عند الضغط على زر القائمة

---

## 🎨 التخصيص

### تعديل القائمة
لإضافة أو تعديل عناصر القائمة، عدّل ملف `js/sidebar.js`:

```javascript
// في دالة createUnifiedSidebar()
<a href="new-page.html" class="nav-item" data-page="new-page">
    <i class="fas fa-new-icon"></i>
    <span>صفحة جديدة</span>
</a>
```

### تعديل الألوان
عدّل ملف `css/unified-sidebar.css`:

```css
.nav-item.active {
    background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
}
```

---

## 🔧 الدوال المتاحة

### `initUnifiedSidebar()`
تهيئة القائمة الجانبية (تُستدعى تلقائياً).

### `setActivePage()`
تحديد الصفحة النشطة بناءً على URL الحالي.

### `updateAdminInfo()`
تحديث معلومات المشرف من localStorage.

### `updatePendingRequestsCount()`
جلب وتحديث عدد الطلبات المعلقة من API.

---

## 📱 التوافق

- ✅ Chrome, Firefox, Safari, Edge (latest)
- ✅ Mobile & Tablet responsive
- ✅ RTL Support
- ✅ Dark Mode Support

---

## 🐛 استكشاف الأخطاء

### القائمة لا تظهر؟
1. تأكد من تحميل `js/sidebar.js`
2. تأكد من وجود `<div id="sidebarContainer"></div>`
3. افتح Console وتحقق من الأخطاء

### الصفحة النشطة غير محددة؟
تأكد من أن اسم ملف HTML يطابق `href` في `sidebar.js`.

### عدد الطلبات لا يظهر؟
1. تحقق من أن API يعمل
2. تحقق من وجود `admin_token` و `admin_apiKey` في localStorage

---

## 💡 نصائح

1. **لا تعدّل القائمة في كل صفحة**: عدّل فقط في `js/sidebar.js`
2. **استخدم data-page attribute**: لتحديد الصفحة الحالية
3. **احتفظ بـ id="menuToggle"**: للموبايل
4. **احتفظ بـ id="themeToggle"**: للثيم

---

## 📚 الملفات المطلوبة

```
dalma-admin-pro/
├── css/
│   ├── main.css
│   └── unified-sidebar.css
├── js/
│   ├── sidebar.js
│   └── main.js
└── [your-page].html
```

---

✅ **جاهز للاستخدام!**

الآن يمكنك إنشاء أي صفحة جديدة والقائمة ستظهر تلقائياً مع جميع الميزات! 🎉



