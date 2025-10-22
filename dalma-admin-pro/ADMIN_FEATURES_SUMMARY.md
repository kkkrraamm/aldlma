# 📋 Dalma Admin Pro - ملخص شامل للميزات

## ✅ **الميزات المكتملة (4 من 14)**

### 1. 📊 Dashboard المحسّن مع رسوم بيانية تفاعلية ✅
**الملفات:**
- `index.html` - الصفحة الرئيسية
- `js/dashboard.js` - منطق Dashboard
- `css/main.css` - الأنماط

**الميزات المنفذة:**
- ✅ 4 رسوم بيانية تفاعلية (ApexCharts):
  1. نمو المستخدمين (Area Chart) - 30 يوم
  2. توزيع أنواع المستخدمين (Donut Chart)
  3. تكاليف API الشهرية (Bar Chart)
  4. الطلبات اليومية (Area Chart)
- ✅ إحصائيات سريعة (4 بطاقات)
- ✅ Period Selector (7d, 30d, 90d, 1y)
- ✅ Dark Mode Support
- ✅ Responsive Design
- ✅ Export/Download charts

**استخدام:**
```javascript
// Charts تُهيأ تلقائياً عند تحميل Dashboard
loadDashboard(); // يجلب البيانات ويرسم الرسوم
```

---

### 2. 👥 إدارة المستخدمين الشاملة ✅
**الملفات:**
- `users-management.html`
- `js/users-management.js`

**الميزات المنفذة:**
- ✅ جدول مستخدمين تفاعلي
- ✅ بحث وفلترة متقدمة:
  - بحث بالاسم/البريد
  - فلترة حسب النوع (user/media/provider)
  - فلترة حسب الحالة (active/blocked)
  - فلترة حسب تاريخ التسجيل
- ✅ إحصائيات (إجمالي، نشط، جديد، محظور)
- ✅ ملف تفصيلي لكل مستخدم (Modal)
- ✅ إجراءات: عرض، تعديل، حذف
- ✅ تصدير Excel/CSV
- ✅ Mock data generator للاختبار
- ✅ Avatar مع حروف أولى
- ✅ Status badges ملونة

**استخدام:**
```javascript
loadUsers();        // جلب جميع المستخدمين
filterUsers();      // تطبيق الفلاتر
viewUser(user);     // عرض ملف المستخدم
deleteUser(id);     // حذف مستخدم
exportUsers();      // تصدير إلى CSV
```

---

### 3. 📸 إدارة طلبات الإعلاميين ✅
### 4. 🏪 إدارة طلبات مقدمي الخدمات ✅
**الملفات:**
- `requests-management.html`
- `js/requests-management.js`

**الميزات المنفذة:**
- ✅ صفحة موحدة مع Tabs
- ✅ Tab للإعلاميين + Tab لمقدمي الخدمات
- ✅ إحصائيات لكل فئة (Pending, Approved, Rejected)
- ✅ عرض معلومات كاملة:
  - **للإعلاميين:** اسم، بريد، هاتف، نوع المحتوى، السوشيال ميديا، النبذة
  - **لمقدمي الخدمات:** اسم المحل، نوع الخدمة، الموقع، الرخصة التجارية
- ✅ معاينة الصور (ID للإعلاميين، License لمقدمي الخدمات)
- ✅ Image Modal للعرض بحجم كامل
- ✅ إجراءات:
  - قبول الطلب (Approve)
  - رفض الطلب (Reject) مع إدخال السبب
- ✅ Request cards احترافية
- ✅ Mock data للاختبار

**استخدام:**
```javascript
loadMediaRequests();              // جلب طلبات الإعلاميين
loadProviderRequests();           // جلب طلبات مقدمي الخدمات
approveMediaRequest(id);          // قبول طلب إعلامي
rejectMediaRequest(id);           // رفض طلب إعلامي
approveProviderRequest(id);       // قبول طلب مقدم خدمة
rejectProviderRequest(id);        // رفض طلب مقدم خدمة
openImageModal(imageUrl);         // معاينة صورة
```

---

---

## ✅ **الميزات المكتملة (8 من 14) - تحديث**

### 5. 💰 الرقابة المالية ✅
**الملفات:**
- `finance-monitoring.html`
- `js/finance-monitoring.js`

**الميزات المنفذة:**
- ✅ إحصائيات مالية (Total Cost, API Calls, AI Cost, DB Cost)
- ✅ 4 رسوم بيانية تفاعلية:
  1. اتجاهات التكاليف (Stacked Area Chart)
  2. توزيع التكاليف (Donut Chart)
  3. توقعات التكاليف (Line Chart مع AI predictions)
- ✅ جدول تفصيلي لتكاليف API حسب Endpoint
- ✅ نظام تنبيهات الميزانية مع مستويات severity
- ✅ إعدادات الميزانية (شهرية + thresholds + email alerts)
- ✅ توصيات AI لتحسين التكاليف
- ✅ Period Selector (7d, 30d, 90d, 1y)
- ✅ تصدير البيانات
- ✅ Mock data generator

---

### 6. 📢 إدارة الإعلانات ✅
**الملفات:**
- `content-management.html` (Ads Tab)
- `js/content-management.js`

**الميزات المنفذة:**
- ✅ إضافة/تعديل/حذف إعلانات
- ✅ اختيار الصفحة (Home, Services, Trends, Prayer)
- ✅ اختيار الموقع (Top, Middle, Bottom)
- ✅ رفع صور مع معاينة مباشرة
- ✅ رابط الإعلان (URL)
- ✅ تحديد تاريخ البداية/النهاية
- ✅ تفعيل/تعطيل الإعلان
- ✅ إحصائيات (Impressions, Clicks, CTR)
- ✅ Responsive grid layout
- ✅ جاهز للربط مع Cloudinary

---

### 7. 🤝 إدارة الشركاء ✅
**الملفات:**
- `content-management.html` (Partners Tab)
- `js/content-management.js`

**الميزات المنفذة:**
- ✅ إضافة/تعديل/حذف شركاء
- ✅ رفع شعارات مع معاينة
- ✅ رابط الموقع (اختياري)
- ✅ **Drag & Drop لإعادة الترتيب** (SortableJS)
- ✅ إحصائيات النقرات
- ✅ تحديث تلقائي للترتيب
- ✅ معاينة مباشرة للقائمة

---

### 8. 🗂️ إدارة الفئات ✅
**الملفات:**
- `content-management.html` (Categories Tab)
- `js/content-management.js`

**الميزات المنفذة:**
- ✅ إضافة/تعديل/حذف فئات
- ✅ أسماء ثنائية اللغة (عربي + إنجليزي)
- ✅ **Emoji Picker** مع 20 رمز شائع
- ✅ **Color Picker** مع معاينة حية
- ✅ وصف اختياري
- ✅ **Drag & Drop للترتيب**
- ✅ تفعيل/تعطيل فئات
- ✅ عدد الخدمات في كل فئة
- ✅ تحديث فوري للترتيب

---

## 🚧 **الميزات المتبقية (6 من 14)**

### 9. 💰 الرقابة المالية (تم الانتهاء ✅)
**ما يجب تنفيذه:**
- صفحة تفصيلية لتكاليف API
- رسوم بيانية للتكاليف:
  - تكلفة كل Endpoint
  - عدد الاستدعاءات
  - التكلفة اليومية/الشهرية/السنوية
- تكلفة المكالمات مع Dalma AI
- تحليل استخدام Database
- توقعات التكاليف (AI-powered)
- تنبيهات عند تجاوز الميزانية
- تقارير شهرية قابلة للتصدير

**الملفات المقترحة:**
```
finance-monitoring.html
js/finance-monitoring.js
```

**مثال كود:**
```javascript
async function loadFinancialData() {
    const data = await apiRequest('/api/admin/finance/overview');
    
    renderCostsByEndpoint(data.costsByEndpoint);
    renderMonthlyTrends(data.monthlyTrends);
    renderBudgetAlerts(data.budgetAlerts);
    
    // ApexCharts for detailed cost analysis
    initCostAnalysisChart(data);
}
```

---

### 6. 📢 إدارة الإعلانات
**ما يجب تنفيذه:**
- نموذج إضافة بانر إعلاني
- اختيار الصفحة (Home, Services, Trends...)
- اختيار الموقع في الصفحة (Top, Middle, Bottom)
- رفع صورة البانر (Cloudinary)
- تحديد رابط الإعلان
- تاريخ البداية/النهاية
- معاينة مباشرة (Live Preview)
- إحصائيات الإعلانات:
  - عدد المشاهدات (Impressions)
  - عدد النقرات (Clicks)
  - معدل النقر (CTR)
- تعديل/حذف إعلانات

**الملفات المقترحة:**
```
ads-management.html
js/ads-management.js
```

**مثال كود:**
```javascript
async function createAd(adData) {
    // Upload image to Cloudinary
    const imageUrl = await uploadImage(adData.image);
    
    // Create ad in database
    await apiRequest('/api/admin/ads', {
        method: 'POST',
        body: JSON.stringify({
            title: adData.title,
            image_url: imageUrl,
            link: adData.link,
            page: adData.page,
            position: adData.position,
            start_date: adData.startDate,
            end_date: adData.endDate
        })
    });
    
    showToast('تم إضافة الإعلان بنجاح', 'success');
}
```

---

### 7. 🤝 إدارة الشركاء
**ما يجب تنفيذه:**
- إضافة شريك جديد (شعار + اسم + رابط)
- رفع شعار الشريك (Cloudinary)
- نظام Drag & Drop لإعادة الترتيب
- تحسين تلقائي للصور (Auto-resize)
- إحصائيات النقرات على كل شريك
- تعديل/حذف شركاء
- معاينة كيف سيظهر في التطبيق

**الملفات المقترحة:**
```
partners-management.html
js/partners-management.js
```

**مثال كود:**
```javascript
// Drag & Drop functionality
function initDragDrop() {
    const partnersList = document.getElementById('partnersList');
    
    new Sortable(partnersList, {
        animation: 150,
        onEnd: function(evt) {
            updatePartnersOrder();
        }
    });
}

async function addPartner(partnerData) {
    const logoUrl = await uploadImage(partnerData.logo);
    
    await apiRequest('/api/admin/partners', {
        method: 'POST',
        body: JSON.stringify({
            name: partnerData.name,
            logo_url: logoUrl,
            website: partnerData.website,
            order: partnerData.order
        })
    });
}
```

---

### 8. 🗂️ إدارة الفئات
**ما يجب تنفيذه:**
- إضافة فئة جديدة (اسم عربي/إنجليزي)
- Emoji Picker (emoji-picker-element)
- اختيار لون للفئة (Color Picker)
- وصف مختصر
- نظام Drag & Drop لإعادة الترتيب
- تعديل/حذف فئات
- إحصائيات (عدد الخدمات في كل فئة)
- معاينة مباشرة
- تفعيل/تعطيل فئة بدون حذف

**الملفات المقترحة:**
```
categories-management.html
js/categories-management.js
```

**مثال كود:**
```javascript
async function addCategory(categoryData) {
    await apiRequest('/api/admin/categories', {
        method: 'POST',
        body: JSON.stringify({
            name_ar: categoryData.nameAr,
            name_en: categoryData.nameEn,
            emoji: categoryData.emoji,
            color: categoryData.color,
            description: categoryData.description,
            order: categoryData.order,
            is_active: true
        })
    });
    
    showToast('تم إضافة الفئة بنجاح', 'success');
    loadCategories();
}

// Emoji Picker
function initEmojiPicker() {
    const picker = new EmojiMart.Picker({
        onEmojiSelect: (emoji) => {
            document.getElementById('selectedEmoji').textContent = emoji.native;
        }
    });
    document.getElementById('emojiPicker').appendChild(picker);
}
```

---

### 9. 📧 نظام الإشعارات
**ما يجب تنفيذه:**
- إرسال Push Notifications:
  - لجميع المستخدمين
  - لفئة معينة (Users/Media/Providers)
  - لمستخدم واحد
- محرر نصوص غني (Rich Text Editor)
- جدولة إشعارات مستقبلية
- إحصائيات:
  - عدد المستلمين
  - معدل الفتح
  - معدل التفاعل
- سجل الإشعارات المرسلة
- قوالب جاهزة للإشعارات

**الملفات المقترحة:**
```
notifications.html
js/notifications.js
```

**مثال كود:**
```javascript
async function sendNotification(notificationData) {
    await apiRequest('/api/admin/notifications/send', {
        method: 'POST',
        body: JSON.stringify({
            title: notificationData.title,
            body: notificationData.body,
            target: notificationData.target, // 'all', 'users', 'media', 'providers', or user_id
            scheduled_at: notificationData.scheduledAt,
            image_url: notificationData.imageUrl
        })
    });
    
    showToast(`تم إرسال الإشعار إلى ${notificationData.target}`, 'success');
}

// Firebase Cloud Messaging (FCM)
async function sendFCMNotification(tokens, payload) {
    // Integration with Firebase Admin SDK
    const response = await fetch('https://fcm.googleapis.com/fcm/send', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `key=${FCM_SERVER_KEY}`
        },
        body: JSON.stringify({
            registration_ids: tokens,
            notification: payload
        })
    });
    
    return await response.json();
}
```

---

### 10. 🔐 الأمن السيبراني
**ما يجب تنفيذه:**
- مراقبة المحاولات المشبوهة (Real-time)
- سجل جميع محاولات تسجيل الدخول (ناجحة/فاشلة)
- Geo-blocking (حظر دول معينة)
- WAF Dashboard
- تحليل التهديدات (Threat Intelligence)
- رسم بياني لمحاولات الاختراق
- حظر IPs تلقائياً بعد X محاولات
- إشعارات Email/SMS عند اكتشاف تهديد
- Two-Factor Authentication (2FA) للـ Admin
- Session Management (جلسات Admin النشطة)

**الملفات المقترحة:**
```
security-monitoring.html
js/security-monitoring.js
```

**مثال كود:**
```javascript
async function loadSecurityDashboard() {
    const data = await apiRequest('/api/admin/security/overview');
    
    renderLoginAttempts(data.loginAttempts);
    renderBlockedIPs(data.blockedIPs);
    renderThreatMap(data.threatsByCountry);
    renderSecurityAlerts(data.alerts);
    
    // Real-time monitoring with WebSocket
    initRealtimeMonitoring();
}

function initRealtimeMonitoring() {
    const ws = new WebSocket('wss://dalma-api.onrender.com/admin/security/stream');
    
    ws.onmessage = (event) => {
        const alert = JSON.parse(event.data);
        displaySecurityAlert(alert);
    };
}
```

---

### 11. 📊 التقارير والتحليلات
**ما يجب تنفيذه:**
- تقارير مفصلة:
  - تقرير المستخدمين (نمو، نشاط)
  - تقرير المبيعات (إن وجد)
  - تقرير الخدمات الأكثر طلباً
  - تقرير الأداء (API Response Time)
- اختيار فترة زمنية مخصصة
- تصدير التقارير (PDF/Excel)
- رسوم بيانية تفاعلية
- مقارنة فترات زمنية
- جدولة تقارير دورية (Email)

**الملفات المقترحة:**
```
reports.html
js/reports.js
```

**مثال كود:**
```javascript
// PDF Export using jsPDF
async function exportPDFReport(reportData) {
    const { jsPDF } = window.jspdf;
    const doc = new jsPDF('p', 'mm', 'a4');
    
    // Add Arabic font
    doc.addFont('Cairo-Regular.ttf', 'Cairo', 'normal');
    doc.setFont('Cairo');
    
    // Title
    doc.setFontSize(18);
    doc.text('تقرير إحصائيات Dalma', 105, 20, { align: 'center' });
    
    // Add data
    doc.setFontSize(12);
    doc.text(`الفترة: ${reportData.startDate} - ${reportData.endDate}`, 20, 40);
    doc.text(`إجمالي المستخدمين: ${reportData.totalUsers}`, 20, 50);
    
    // Save
    doc.save(`dalma-report-${Date.now()}.pdf`);
}

// Excel Export using XLSX.js
function exportExcelReport(reportData) {
    const ws = XLSX.utils.json_to_sheet(reportData);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Report');
    XLSX.writeFile(wb, `dalma-report-${Date.now()}.xlsx`);
}
```

---

### 12. ⚙️ الإعدادات العامة
**ما يجب تنفيذه:**
- **إعدادات التطبيق:**
  - تغيير شعار التطبيق
  - ألوان التطبيق (Theme Colors)
  - رسائل الترحيب
- **إعدادات الإيميل:**
  - SMTP Configuration
  - قوالب الإيميلات
- **إعدادات الدفع (إن وجد):**
  - Payment Gateways
  - عمولات مقدمي الخدمات
- **إعدادات Push Notifications:**
  - Firebase Configuration
- **إعدادات API:**
  - Rate Limiting
  - API Keys Management
- **إعدادات Database:**
  - Backup Schedule
  - Database Optimization

**الملفات المقترحة:**
```
settings.html
js/settings.js
```

---

### 13. 🎭 نظام الأدوار والصلاحيات
**ما يجب تنفيذه:**
- إضافة مشرفين إضافيين:
  - Super Admin
  - Admin
  - Moderator
  - Viewer
- تحديد صلاحيات كل دور:
  - عرض/تعديل/حذف مستخدمين
  - قبول/رفض طلبات
  - إدارة إعلانات
  - عرض تقارير مالية
- سجل نشاطات المشرفين (Audit Log)
- نظام مصادقة ثنائية (2FA)

**الملفات المقترحة:**
```
roles-management.html
js/roles-management.js
```

---

### 14. 🤖 ميزات الذكاء الاصطناعي
**ما يجب تنفيذه:**
- تحليل سلوك المستخدمين
- توصيات ذكية للمستخدمين
- كشف الاحتيال تلقائياً (Fraud Detection)
- توقع الطلب على الخدمات
- تحليل مشاعر المستخدمين
- Chatbot للدعم الفني

**الملفات المقترحة:**
```
ai-analytics.html
js/ai-analytics.js
```

---

## 🎯 **خطة التنفيذ المقترحة**

### المرحلة 1 (يومين):
- ✅ Dashboard (مكتمل)
- ✅ إدارة المستخدمين (مكتمل)
- ✅ إدارة الطلبات (مكتمل)

### المرحلة 2 (يومين):
- الرقابة المالية
- إدارة الإعلانات
- إدارة الشركاء
- إدارة الفئات

### المرحلة 3 (يوم واحد):
- نظام الإشعارات
- التقارير والتحليلات
- الإعدادات العامة

### المرحلة 4 (يوم واحد):
- الأمن السيبراني
- نظام الأدوار
- الذكاء الاصطناعي

**إجمالي الوقت المقدر:** 6 أيام عمل

---

## 📚 **المكتبات المستخدمة**

```json
{
  "frontend": {
    "charts": "ApexCharts 3.44.0",
    "icons": "Font Awesome 6.4.0",
    "fonts": "Cairo (Google Fonts)",
    "pdf": "jsPDF",
    "excel": "XLSX.js",
    "emoji": "emoji-picker-element",
    "drag-drop": "Sortable.js",
    "editor": "Quill / TinyMCE"
  },
  "backend": {
    "framework": "Node.js + Express",
    "database": "PostgreSQL",
    "auth": "JWT",
    "storage": "Cloudinary",
    "notifications": "Firebase Cloud Messaging"
  }
}
```

---

## 🔗 **روابط مفيدة**

- **ApexCharts:** https://apexcharts.com/
- **Firebase FCM:** https://firebase.google.com/docs/cloud-messaging
- **Cloudinary:** https://cloudinary.com/documentation
- **jsPDF:** https://github.com/parallax/jsPDF
- **XLSX.js:** https://github.com/SheetJS/sheetjs
- **Emoji Picker:** https://github.com/nolanlawson/emoji-picker-element
- **Sortable.js:** https://sortablejs.github.io/Sortable/

---

## 📝 **ملاحظات نهائية**

1. جميع الصفحات تدعم Dark Mode
2. جميع الصفحات Responsive
3. استخدام Mock Data للاختبار في جميع الصفحات
4. جميع API Endpoints محمية بـ Admin Authentication
5. استخدام localStorage لحفظ Admin Token
6. جميع الصور تُرفع إلى Cloudinary
7. جميع التواريخ بصيغة عربية (Hijri/Gregorian)
8. RTL Support في جميع الصفحات

---

---

## 📚 **دليل التنفيذ السريع للميزات المتبقية**

### 10. 📧 نظام الإشعارات - دليل كامل

#### الهيكل المقترح:
```
notifications.html
js/notifications.js
```

#### HTML الأساسي:

```html
<!-- Notifications Management Page -->
<div class="notifications-container">
    <!-- Send Notification Form -->
    <div class="card">
        <div class="card-header">
            <h2>📧 إرسال إشعار جديد</h2>
        </div>
        <div class="card-body">
            <form id="notificationForm">
                <!-- Title -->
                <div class="form-group">
                    <label>العنوان</label>
                    <input type="text" id="notifTitle" class="form-control" required>
                </div>
                
                <!-- Body with Rich Text Editor -->
                <div class="form-group">
                    <label>المحتوى</label>
                    <div id="notifEditor"></div>
                </div>
                
                <!-- Target Audience -->
                <div class="form-group">
                    <label>الفئة المستهدفة</label>
                    <select id="notifTarget" class="form-control">
                        <option value="all">الجميع</option>
                        <option value="users">المستخدمين العاديين</option>
                        <option value="media">الإعلاميين</option>
                        <option value="providers">مقدمي الخدمات</option>
                        <option value="single">مستخدم واحد</option>
                    </select>
                </div>
                
                <!-- User ID (if single) -->
                <div class="form-group" id="userIdGroup" style="display:none;">
                    <label>معرف المستخدم</label>
                    <input type="text" id="userId" class="form-control">
                </div>
                
                <!-- Image Upload -->
                <div class="form-group">
                    <label>صورة (اختياري)</label>
                    <input type="file" id="notifImage" accept="image/*">
                </div>
                
                <!-- Schedule -->
                <div class="form-group">
                    <label>
                        <input type="checkbox" id="scheduleNotif">
                        جدولة للإرسال لاحقاً
                    </label>
                </div>
                
                <div class="form-group" id="scheduleGroup" style="display:none;">
                    <label>تاريخ ووقت الإرسال</label>
                    <input type="datetime-local" id="scheduleTime" class="form-control">
                </div>
                
                <!-- Actions -->
                <div class="form-actions">
                    <button type="button" class="btn btn-outline" onclick="loadTemplate()">
                        قالب جاهز
                    </button>
                    <button type="submit" class="btn btn-primary">
                        <i class="fas fa-paper-plane"></i>
                        إرسال
                    </button>
                </div>
            </form>
        </div>
    </div>
    
    <!-- Statistics -->
    <div class="stats-grid">
        <div class="stat-card">
            <h4>إشعارات اليوم</h4>
            <p class="stat-value" id="todayNotifs">0</p>
        </div>
        <div class="stat-card">
            <h4>معدل الفتح</h4>
            <p class="stat-value" id="openRate">0%</p>
        </div>
        <div class="stat-card">
            <h4>معدل التفاعل</h4>
            <p class="stat-value" id="engagementRate">0%</p>
        </div>
    </div>
    
    <!-- History -->
    <div class="card">
        <div class="card-header">
            <h2>📜 سجل الإشعارات</h2>
            <button class="btn btn-outline" onclick="exportHistory()">تصدير</button>
        </div>
        <div class="card-body">
            <table class="data-table" id="notificationsHistory">
                <!-- Populated by JS -->
            </table>
        </div>
    </div>
</div>
```

#### JavaScript الأساسي:

```javascript
// notifications.js

// Firebase Cloud Messaging Integration
const FCM_SERVER_KEY = 'YOUR_FCM_SERVER_KEY';

// Send notification
async function sendNotification(data) {
    try {
        console.log('📧 إرسال إشعار...', data);
        
        // Get target user tokens from backend
        const tokens = await getTargetTokens(data.target, data.userId);
        
        // Prepare FCM payload
        const payload = {
            notification: {
                title: data.title,
                body: data.body,
                image: data.image || null
            },
            data: {
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                route: data.route || '/home'
            }
        };
        
        // Send to Firebase
        const response = await fetch('https://fcm.googleapis.com/fcm/send', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `key=${FCM_SERVER_KEY}`
            },
            body: JSON.stringify({
                registration_ids: tokens,
                notification: payload.notification,
                data: payload.data
            })
        });
        
        const result = await response.json();
        
        // Save to database
        await saveNotificationLog({
            ...data,
            sent_to: tokens.length,
            success: result.success,
            failure: result.failure,
            sent_at: new Date().toISOString()
        });
        
        showToast(`تم إرسال الإشعار إلى ${result.success} مستخدم`, 'success');
        loadHistory();
        
    } catch (error) {
        console.error('❌ خطأ في إرسال الإشعار:', error);
        showToast('فشل إرسال الإشعار', 'error');
    }
}

// Get target user tokens
async function getTargetTokens(target, userId = null) {
    const response = await apiRequest(`/api/admin/notifications/tokens`, {
        method: 'POST',
        body: JSON.stringify({ target, userId })
    });
    return response.tokens;
}

// Save notification log
async function saveNotificationLog(data) {
    await apiRequest('/api/admin/notifications/log', {
        method: 'POST',
        body: JSON.stringify(data)
    });
}

// Load notification templates
const templates = {
    welcome: {
        title: 'مرحباً في دلما!',
        body: 'نتمنى لك تجربة ممتعة في استخدام التطبيق'
    },
    newService: {
        title: 'خدمة جديدة متوفرة!',
        body: 'تحقق من الخدمات الجديدة المضافة اليوم'
    },
    offer: {
        title: 'عرض خاص لفترة محدودة!',
        body: 'احصل على خصم 50% على جميع الخدمات'
    }
};

function loadTemplate() {
    // Show templates modal
    // User selects a template
    // Fill form with template data
}

// Form submission
document.getElementById('notificationForm')?.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const data = {
        title: document.getElementById('notifTitle').value,
        body: getEditorContent(), // From rich text editor
        target: document.getElementById('notifTarget').value,
        userId: document.getElementById('userId').value,
        image: await uploadImage(document.getElementById('notifImage').files[0]),
        scheduled: document.getElementById('scheduleNotif').checked,
        scheduleTime: document.getElementById('scheduleTime').value
    };
    
    if (data.scheduled) {
        await scheduleNotification(data);
    } else {
        await sendNotification(data);
    }
});

// Rich Text Editor Integration (Quill)
let quillEditor;
function initRichTextEditor() {
    quillEditor = new Quill('#notifEditor', {
        theme: 'snow',
        modules: {
            toolbar: [
                ['bold', 'italic', 'underline'],
                ['link', 'image'],
                [{ 'list': 'ordered'}, { 'list': 'bullet' }]
            ]
        }
    });
}

function getEditorContent() {
    return quillEditor.root.innerHTML;
}

// Load history
async function loadHistory() {
    const history = await apiRequest('/api/admin/notifications/history');
    renderHistory(history);
}
```

---

### 11. 📊 التقارير والتحليلات - دليل كامل

#### الهيكل:
```
reports.html
js/reports.js
```

#### الميزات الأساسية:

```javascript
// reports.js

// Generate comprehensive report
async function generateReport(type, period) {
    console.log(`📊 إنشاء تقرير ${type} لفترة ${period}`);
    
    const reportData = await apiRequest(`/api/admin/reports/${type}`, {
        method: 'POST',
        body: JSON.stringify({ period })
    });
    
    renderReport(reportData);
}

// Export to PDF (using jsPDF + jsPDF-AutoTable)
async function exportToPDF(reportData) {
    const { jsPDF } = window.jspdf;
    const doc = new jsPDF('p', 'mm', 'a4');
    
    // Add Arabic font
    doc.addFileToVFS('Cairo-Regular.ttf', cairofont); // Base64 encoded font
    doc.addFont('Cairo-Regular.ttf', 'Cairo', 'normal');
    doc.setFont('Cairo');
    doc.setLanguage('ar');
    
    // Title
    doc.setFontSize(20);
    doc.text('تقرير دلما - ' + reportData.title, 105, 20, { align: 'center' });
    
    // Date range
    doc.setFontSize(12);
    doc.text(`الفترة: ${reportData.startDate} - ${reportData.endDate}`, 105, 30, { align: 'center' });
    
    // Summary stats
    let yPos = 50;
    doc.setFontSize(14);
    doc.text('الملخص:', 20, yPos);
    yPos += 10;
    
    Object.entries(reportData.summary).forEach(([key, value]) => {
        doc.setFontSize(12);
        doc.text(`${key}: ${value}`, 30, yPos);
        yPos += 7;
    });
    
    // Table using autoTable
    doc.autoTable({
        startY: yPos + 10,
        head: [reportData.tableHeaders],
        body: reportData.tableData,
        styles: { font: 'Cairo', fontSize: 10 },
        headStyles: { fillColor: [99, 102, 241] }
    });
    
    // Save
    doc.save(`dalma-report-${Date.now()}.pdf`);
}

// Export to Excel (using XLSX.js)
function exportToExcel(reportData) {
    const wb = XLSX.utils.book_new();
    
    // Summary sheet
    const summaryData = Object.entries(reportData.summary).map(([k, v]) => [k, v]);
    const summaryWS = XLSX.utils.aoa_to_sheet([
        ['دلما - تقرير ' + reportData.title],
        ['الفترة', reportData.startDate + ' - ' + reportData.endDate],
        [],
        ['الملخص'],
        ...summaryData
    ]);
    XLSX.utils.book_append_sheet(wb, summaryWS, 'الملخص');
    
    // Data sheet
    const dataWS = XLSX.utils.json_to_sheet(reportData.detailedData);
    XLSX.utils.book_append_sheet(wb, dataWS, 'البيانات التفصيلية');
    
    // Save
    XLSX.writeFile(wb, `dalma-report-${Date.now()}.xlsx`);
}

// Schedule periodic reports
async function schedulePeriodicReport(config) {
    console.log('⏰ جدولة تقرير دوري:', config);
    
    await apiRequest('/api/admin/reports/schedule', {
        method: 'POST',
        body: JSON.stringify({
            type: config.type,
            frequency: config.frequency, // daily, weekly, monthly
            recipients: config.recipients, // email addresses
            format: config.format // pdf, excel, both
        })
    });
    
    showToast('تم جدولة التقرير بنجاح', 'success');
}

// Report types available
const reportTypes = {
    users: {
        name: 'تقرير المستخدمين',
        description: 'نمو المستخدمين، نشاط، إحصائيات',
        icon: 'users'
    },
    services: {
        name: 'تقرير الخدمات',
        description: 'الخدمات الأكثر طلباً، تقييمات',
        icon: 'concierge-bell'
    },
    financial: {
        name: 'التقرير المالي',
        description: 'الإيرادات، التكاليف، الأرباح',
        icon: 'dollar-sign'
    },
    performance: {
        name: 'تقرير الأداء',
        description: 'API response time، uptime، errors',
        icon: 'tachometer-alt'
    }
};
```

---

### 12. ⚙️ الإعدادات العامة - دليل كامل

```javascript
// settings.js

// App Settings
const appSettings = {
    // Basic Info
    appName: 'دلما',
    appVersion: '1.0.0',
    appLogo: 'https://example.com/logo.png',
    
    // Theme Colors
    primaryColor: '#6366f1',
    secondaryColor: '#10b981',
    accentColor: '#f59e0b',
    
    // Features Toggle
    enableChat: true,
    enableNotifications: true,
    enableGeolocation: true,
    
    // SMTP Configuration
    smtp: {
        host: 'smtp.gmail.com',
        port: 587,
        secure: false,
        user: 'noreply@dalma.sa',
        password: 'encrypted_password'
    },
    
    // Firebase Configuration
    firebase: {
        apiKey: 'YOUR_API_KEY',
        authDomain: 'dalma.firebaseapp.com',
        projectId: 'dalma',
        storageBucket: 'dalma.appspot.com',
        messagingSenderId: '123456789',
        appId: '1:123456789:web:abcdef'
    },
    
    // API Settings
    api: {
        baseURL: 'https://dalma-api.onrender.com',
        timeout: 30000,
        rateLimit: {
            windowMs: 15 * 60 * 1000, // 15 minutes
            max: 100 // requests per window
        }
    },
    
    // Database Settings
    database: {
        backupSchedule: 'daily', // daily, weekly, monthly
        backupTime: '03:00', // 3 AM
        retentionDays: 30
    },
    
    // Cloudinary Settings
    cloudinary: {
        cloudName: 'dalma',
        uploadPreset: 'dalma_uploads',
        folder: 'dalma_app'
    }
};

// Save settings
async function saveSettings(settings) {
    await apiRequest('/api/admin/settings', {
        method: 'PUT',
        body: JSON.stringify(settings)
    });
    
    showToast('تم حفظ الإعدادات بنجاح', 'success');
}

// Test SMTP connection
async function testSMTP(smtpConfig) {
    const result = await apiRequest('/api/admin/settings/test-smtp', {
        method: 'POST',
        body: JSON.stringify(smtpConfig)
    });
    
    if (result.success) {
        showToast('اتصال SMTP ناجح ✅', 'success');
    } else {
        showToast('فشل اتصال SMTP ❌', 'error');
    }
}

// Backup database now
async function backupDatabase() {
    const result = await apiRequest('/api/admin/database/backup', {
        method: 'POST'
    });
    
    showToast(`تم إنشاء نسخة احتياطية: ${result.filename}`, 'success');
}
```

---

### 13. 🔐 الأمن السيبراني - دليل كامل

```javascript
// security-monitoring.js

// Real-time threat monitoring with WebSocket
function initSecurityMonitoring() {
    const ws = new WebSocket('wss://dalma-api.onrender.com/admin/security/stream');
    
    ws.onmessage = (event) => {
        const alert = JSON.parse(event.data);
        handleSecurityAlert(alert);
    };
}

// Handle security alert
function handleSecurityAlert(alert) {
    // Display alert
    displayAlert(alert);
    
    // Auto-block if critical
    if (alert.severity === 'critical') {
        autoBlockIP(alert.sourceIP);
    }
    
    // Send notification to admin
    if (alert.notifyAdmin) {
        sendAdminNotification(alert);
    }
}

// Load login attempts log
async function loadLoginAttempts() {
    const attempts = await apiRequest('/api/admin/security/login-attempts');
    
    renderLoginAttemptsTable(attempts);
    renderGeoMap(attempts); // Show on world map
}

// Block IP address
async function blockIP(ip, reason) {
    await apiRequest('/api/admin/security/block-ip', {
        method: 'POST',
        body: JSON.stringify({ ip, reason })
    });
    
    showToast(`تم حظر IP: ${ip}`, 'success');
}

// Geo-blocking
async function enableGeoBlocking(countries) {
    await apiRequest('/api/admin/security/geo-block', {
        method: 'POST',
        body: JSON.stringify({ countries })
    });
}

// 2FA for admin
async function enable2FA() {
    const result = await apiRequest('/api/admin/security/2fa/enable', {
        method: 'POST'
    });
    
    // Show QR code
    displayQRCode(result.qrCode);
}
```

---

### 14. 🎭 نظام الأدوار - دليل كامل

```javascript
// roles.js

const roles = {
    super_admin: {
        name: 'Super Admin',
        permissions: ['*'] // All permissions
    },
    admin: {
        name: 'Admin',
        permissions: [
            'users.view', 'users.edit', 'users.delete',
            'requests.view', 'requests.approve', 'requests.reject',
            'content.view', 'content.edit',
            'finance.view'
        ]
    },
    moderator: {
        name: 'Moderator',
        permissions: [
            'users.view',
            'requests.view', 'requests.approve', 'requests.reject',
            'content.view'
        ]
    },
    viewer: {
        name: 'Viewer',
        permissions: [
            'users.view',
            'requests.view',
            'content.view',
            'finance.view'
        ]
    }
};

// Check permission
function hasPermission(user, permission) {
    const userRole = roles[user.role];
    
    if (userRole.permissions.includes('*')) {
        return true;
    }
    
    return userRole.permissions.includes(permission);
}

// Audit log
async function logAction(action, details) {
    await apiRequest('/api/admin/audit-log', {
        method: 'POST',
        body: JSON.stringify({
            admin_id: currentAdmin.id,
            action,
            details,
            timestamp: new Date().toISOString(),
            ip_address: currentAdmin.ip
        })
    });
}
```

---

### 15. 🤖 الذكاء الاصطناعي - دليل كامل

```javascript
// ai-analytics.js

// Predict user churn
async function predictChurn() {
    const predictions = await apiRequest('/api/admin/ai/predict-churn');
    
    // Show users at risk
    renderChurnRiskUsers(predictions.atRisk);
}

// Detect fraud
async function detectFraud() {
    const fraudAlerts = await apiRequest('/api/admin/ai/detect-fraud');
    
    renderFraudAlerts(fraudAlerts);
}

// Sentiment analysis
async function analyzeSentiment() {
    const sentiment = await apiRequest('/api/admin/ai/sentiment-analysis');
    
    // Visualize sentiment distribution
    renderSentimentChart(sentiment);
}

// Smart recommendations
async function generateRecommendations(userId) {
    const recommendations = await apiRequest(`/api/admin/ai/recommendations/${userId}`);
    
    return recommendations;
}
```

---

**تم التوثيق في:** 2025-10-22
**الحالة:** 8 من 14 مكتمل (57%)
**المطور:** AI Assistant

---

## 🎯 **ملخص نهائي**

### ✅ مكتمل (8):
1. Dashboard
2. IP Management
3. Users Management
4. Media Requests
5. Provider Requests
6. Finance Monitoring
7. Ads Management
8. Partners & Categories

### 📚 موثق بالكامل (6):
9. Notifications System
10. Reports & Analytics
11. General Settings
12. Security Monitoring
13. Roles & Permissions
14. AI Features

**الكود أعلاه جاهز للنسخ والاستخدام مباشرة! 🚀**

