# 🎨 تصميم النماذج الحديثة - Dalma Admin Pro

## 📋 نظرة عامة

تم تحديث تصميم نموذج إضافة/تعديل الإعلانات ليكون أكثر حداثة واحترافية، مع تنظيم أفضل وتجربة مستخدم محسّنة.

---

## ✨ المميزات الجديدة

### 1. **تقسيم منطقي للأقسام**

النموذج مقسم إلى 5 أقسام رئيسية:

#### 📝 المعلومات الأساسية
```html
<div class="form-section">
    <div class="section-header">
        <i class="fas fa-info-circle"></i>
        <h3>المعلومات الأساسية</h3>
    </div>
    <!-- الحقول -->
</div>
```
- عنوان الإعلان (مطلوب)
- وصف الإعلان (اختياري)

#### 🖼️ صورة الإعلان
- منطقة رفع بتصميم drag-and-drop
- معاينة فورية للصورة
- التحقق من الحجم والنوع
- رسائل خطأ واضحة

#### 🔗 إعدادات الرابط
- اختيار نوع الرابط (خارجي/داخلي)
- بطاقات اختيار حديثة (Radio Cards)
- حقول ديناميكية حسب النوع
- قائمة منسدلة للمسارات الداخلية

#### ⚙️ إعدادات العرض
- اختيار الصفحة (مع أيقونات)
- اختيار الموضع
- ترتيب العرض
- نصائح مساعدة

#### 📅 جدولة الإعلان
- تاريخ البداية (datetime-local)
- تاريخ النهاية (datetime-local)
- صندوق معلومات توضيحي

---

## 🎨 التصميم البصري

### الهيدر (Header)
```css
.modern-header {
    background: linear-gradient(135deg, #10b981, #059669);
    color: white;
    padding: 24px 32px;
    border-radius: 16px 16px 0 0;
}
```

**المميزات:**
- ✅ تدرج أخضر (Dalma Brand)
- ✅ أيقونة كبيرة في دائرة
- ✅ عنوان واضح
- ✅ زر إغلاق متحرك (يدور 90° عند التمرير)

### الأقسام (Sections)
```css
.form-section {
    margin-bottom: 32px;
    padding: 24px;
    background: var(--bg-color);
    border-radius: 12px;
    border: 1px solid var(--border-color);
}
```

**المميزات:**
- ✅ خلفية مميزة
- ✅ حواف مستديرة
- ✅ عنوان مع أيقونة وخط فاصل
- ✅ مسافات مريحة

### الحقول (Input Fields)
```css
.form-group input,
.form-group select,
.form-group textarea {
    padding: 12px 16px;
    border: 2px solid var(--border-color);
    border-radius: 10px;
    transition: all 0.3s ease;
}

.form-group input:focus {
    border-color: #10b981;
    box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.1);
}
```

**المميزات:**
- ✅ حدود واضحة
- ✅ تأثير focus أخضر
- ✅ ظل خفيف عند التركيز
- ✅ انتقالات سلسة

---

## 🖼️ منطقة رفع الصور

### التصميم
```html
<div class="image-upload-container">
    <div class="upload-area">
        <img id="imagePreview" style="display: none;">
        <div class="upload-placeholder" id="uploadPlaceholder">
            <i class="fas fa-cloud-upload-alt"></i>
            <p>اضغط لرفع الصورة</p>
            <span>PNG, JPG, GIF (Max 5MB)</span>
        </div>
    </div>
</div>
```

### المميزات
- ✅ حدود منقطة (dashed border)
- ✅ تغيير اللون عند التمرير
- ✅ أيقونة سحابة كبيرة
- ✅ نص توضيحي
- ✅ معاينة فورية
- ✅ إخفاء النص عند رفع الصورة

### السلوك
```javascript
async function handleImageUpload(event) {
    // 1. التحقق من النوع
    if (!file.type.startsWith('image/')) {
        showToast('يرجى اختيار صورة صحيحة', 'error');
        return;
    }
    
    // 2. التحقق من الحجم (5MB max)
    if (file.size > 5 * 1024 * 1024) {
        showToast('حجم الصورة يجب أن يكون أقل من 5 ميجابايت', 'error');
        return;
    }
    
    // 3. رفع إلى Cloudinary
    // 4. عرض المعاينة
    // 5. إخفاء placeholder
}
```

---

## 🎯 بطاقات الاختيار (Radio Cards)

### التصميم
```html
<div class="radio-group modern-radio">
    <label class="radio-card">
        <input type="radio" name="linkType" value="external">
        <div class="radio-content">
            <i class="fas fa-globe"></i>
            <span>رابط خارجي</span>
        </div>
    </label>
    <label class="radio-card">
        <input type="radio" name="linkType" value="internal">
        <div class="radio-content">
            <i class="fas fa-home"></i>
            <span>مسار داخلي</span>
        </div>
    </label>
</div>
```

### المميزات
- ✅ عرض شبكي (2 أعمدة)
- ✅ بطاقات قابلة للنقر
- ✅ أيقونات كبيرة
- ✅ تغيير اللون عند الاختيار
- ✅ حدود خضراء للمحدد
- ✅ خلفية شفافة خضراء

---

## 📦 صندوق المعلومات (Info Box)

### التصميم
```html
<div class="info-box">
    <i class="fas fa-info-circle"></i>
    <p>إذا لم تحدد تواريخ، سيظهر الإعلان بشكل دائم...</p>
</div>
```

### الاستخدام
```css
.info-box {
    background: rgba(59, 130, 246, 0.1);
    border: 1px solid rgba(59, 130, 246, 0.3);
    border-radius: 10px;
    padding: 16px;
}
```

**المميزات:**
- ✅ خلفية زرقاء شفافة
- ✅ أيقونة معلومات
- ✅ نص واضح
- ✅ حواف مستديرة

---

## 📱 التخطيط المتجاوب (Responsive Layout)

### شبكة الأعمدة
```css
.form-row {
    display: grid;
    gap: 20px;
}

.form-row.two-columns {
    grid-template-columns: repeat(2, 1fr);
}

.form-group.full-width {
    grid-column: 1 / -1;
}
```

### Mobile (≤ 768px)
```css
@media (max-width: 768px) {
    .form-row.two-columns {
        grid-template-columns: 1fr; /* عمود واحد */
    }
    
    .modern-radio {
        grid-template-columns: 1fr; /* بطاقة واحدة */
    }
}
```

---

## 🎬 التأثيرات والانتقالات

### زر الإغلاق
```css
.close-btn:hover {
    background: rgba(255, 255, 255, 0.3);
    transform: rotate(90deg); /* دوران 90 درجة */
}
```

### الحقول
```css
.form-group input:focus {
    border-color: #10b981;
    box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.1);
    transition: all 0.3s ease;
}
```

### الأزرار
```css
.btn-primary:hover {
    transform: translateY(-2px); /* رفع خفيف */
    box-shadow: 0 6px 16px rgba(16, 185, 129, 0.4);
}
```

---

## 🔧 الحقول الديناميكية

### إظهار/إخفاء حسب نوع الرابط

```javascript
function toggleLinkFields(type) {
    const externalField = document.getElementById('externalLinkField');
    const internalField = document.getElementById('internalLinkField');
    
    if (type === 'external') {
        externalField.style.display = 'block';
        internalField.style.display = 'none';
    } else {
        externalField.style.display = 'none';
        internalField.style.display = 'block';
    }
}
```

**الاستدعاء:**
```html
<input type="radio" onchange="toggleLinkFields('external')">
```

---

## 📊 القوائم المنسدلة مع الأيقونات

### الصفحات
```html
<select id="adPageLocation">
    <option value="home">🏠 الصفحة الرئيسية</option>
    <option value="services">🛠️ الخدمات</option>
    <option value="realty">🏘️ العقارات</option>
    <option value="trends">📈 الترندات</option>
    <option value="orders">📦 الطلبات</option>
    <option value="add_property">➕ إضافة عقار</option>
</select>
```

### المسارات الداخلية
```html
<select id="adInternalRoute">
    <option value="">اختر المسار</option>
    <option value="/prayer">🕌 أوقات الصلاة</option>
    <option value="/dalma-ai">🤖 ذكاء الدلما</option>
    <option value="/services">🛠️ الخدمات</option>
    <option value="/realty">🏠 العقارات</option>
    <option value="/trends">📈 الترندات</option>
</select>
```

---

## 🎯 Footer الحديث

### التصميم
```css
.modern-footer {
    padding: 20px 32px;
    background: var(--bg-color);
    border-top: 1px solid var(--border-color);
    display: flex;
    justify-content: flex-end;
    gap: 12px;
}
```

### الأزرار
```html
<div class="modal-footer modern-footer">
    <button type="button" class="btn btn-secondary">
        <i class="fas fa-times"></i>
        إلغاء
    </button>
    <button type="submit" class="btn btn-primary">
        <i class="fas fa-save"></i>
        حفظ الإعلان
    </button>
</div>
```

**المميزات:**
- ✅ محاذاة لليمين
- ✅ مسافة بين الأزرار
- ✅ أيقونات واضحة
- ✅ تأثيرات hover مميزة

---

## 🎨 الألوان المستخدمة

### الأخضر (Primary)
```css
--primary-color: #10b981;
--primary-dark: #059669;
--primary-light: rgba(16, 185, 129, 0.1);
```

### الأزرق (Info)
```css
--info-color: #3b82f6;
--info-light: rgba(59, 130, 246, 0.1);
```

### الرمادي (Neutral)
```css
--text-color: #111827 (light) / #f9fafb (dark);
--border-color: #e5e7eb (light) / #2d2d2d (dark);
--bg-color: #f9fafb (light) / #1a1a1a (dark);
```

---

## 📝 مثال كامل للاستخدام

```html
<!-- Modal -->
<div class="modal" id="adModal">
    <div class="modal-content modern-modal">
        <!-- Header -->
        <div class="modal-header modern-header">
            <div class="header-content">
                <div class="header-icon">
                    <i class="fas fa-ad"></i>
                </div>
                <h2>إضافة إعلان جديد</h2>
            </div>
            <button class="btn btn-icon close-btn" onclick="closeModal()">
                <i class="fas fa-times"></i>
            </button>
        </div>
        
        <!-- Body -->
        <form onsubmit="saveAd(event)">
            <div class="modal-body modern-body">
                <!-- Sections here -->
            </div>
            
            <!-- Footer -->
            <div class="modal-footer modern-footer">
                <button type="button" class="btn btn-secondary">إلغاء</button>
                <button type="submit" class="btn btn-primary">حفظ</button>
            </div>
        </form>
    </div>
</div>
```

---

## 🔄 التحديثات المستقبلية

### قريباً:
- [ ] Drag & Drop فعلي للصور
- [ ] معاينة متعددة للصور (Gallery)
- [ ] محرر نصوص غني (Rich Text Editor)
- [ ] اختيار التاريخ بتقويم عربي
- [ ] حفظ تلقائي (Auto-save)
- [ ] التحقق الفوري (Live validation)

---

## 📚 الملفات ذات الصلة

```
dalma-admin-pro/
├── ads-management.html     # النموذج الحديث
├── js/
│   └── ads-management.js   # منطق النموذج
└── css/
    └── (inline styles)     # تنسيقات النموذج
```

---

## 🎯 أفضل الممارسات

### 1. التنظيم
- ✅ قسّم النموذج لأقسام منطقية
- ✅ استخدم عناوين واضحة
- ✅ أضف أيقونات مساعدة

### 2. التحقق
- ✅ تحقق من البيانات قبل الإرسال
- ✅ أظهر رسائل خطأ واضحة
- ✅ استخدم HTML5 validation

### 3. التجربة
- ✅ معاينة فورية للتغييرات
- ✅ رسائل نجاح/فشل واضحة
- ✅ حالة تحميل (loading state)

### 4. الوصولية
- ✅ استخدم labels مناسبة
- ✅ أضف placeholders توضيحية
- ✅ دعم لوحة المفاتيح

---

## 👨‍💻 المطور

تم التطوير بواسطة: **Dalma Development Team**  
التاريخ: نوفمبر 2025  
الإصدار: 1.0.0

---

**🎉 نماذج حديثة وسهلة الاستخدام!**

