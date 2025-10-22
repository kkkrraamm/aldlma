// ==================== CONTENT MANAGEMENT ====================

let currentTab = 'ads';
let adsData = [];
let partnersData = [];
let categoriesData = [];
let editingId = null;

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    loadAllContent();
    initDragAndDrop();
});

// Load all content
async function loadAllContent() {
    await loadAds();
    await loadPartners();
    await loadCategories();
}

// Switch tabs
function switchContentTab(tab) {
    currentTab = tab;
    
    // Update tab buttons
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    document.querySelector(`[data-tab="${tab}"]`).classList.add('active');
    
    // Update tab content
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });
    document.getElementById(`${tab}Tab`).classList.add('active');
}

// ==================== ADS MANAGEMENT ====================

async function loadAds() {
    try {
        console.log('📢 جاري تحميل الإعلانات...');
        
        // In production: const ads = await apiRequest('/api/admin/ads');
        adsData = generateMockAds();
        
        renderAds();
        document.getElementById('adsCount').textContent = adsData.length;
        
        console.log('✅ تم تحميل الإعلانات بنجاح');
    } catch (error) {
        console.error('❌ خطأ في تحميل الإعلانات:', error);
        showToast('فشل تحميل الإعلانات', 'error');
    }
}

function renderAds() {
    const grid = document.getElementById('adsGrid');
    
    if (adsData.length === 0) {
        grid.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-ad"></i>
                <p>لا توجد إعلانات حالياً</p>
                <button class="btn btn-primary" onclick="openAddAdModal()">
                    <i class="fas fa-plus"></i>
                    إضافة إعلان جديد
                </button>
            </div>
        `;
        return;
    }
    
    const adsHTML = adsData.map(ad => `
        <div class="ad-card">
            <div class="ad-image">
                <img src="${ad.image_url}" alt="${ad.title}">
                <span class="ad-status ${ad.is_active ? 'active' : 'inactive'}">
                    ${ad.is_active ? 'نشط' : 'غير نشط'}
                </span>
            </div>
            <div class="ad-content">
                <h3>${ad.title}</h3>
                <div class="ad-meta">
                    <span class="ad-page">${ad.page_label}</span>
                    <span class="ad-position">${ad.position_label}</span>
                </div>
                <div class="ad-stats">
                    <div class="stat-item">
                        <i class="fas fa-eye"></i>
                        <span>${ad.impressions.toLocaleString()} مشاهدة</span>
                    </div>
                    <div class="stat-item">
                        <i class="fas fa-mouse-pointer"></i>
                        <span>${ad.clicks.toLocaleString()} نقرة</span>
                    </div>
                    <div class="stat-item">
                        <i class="fas fa-percentage"></i>
                        <span>${ad.ctr}% CTR</span>
                    </div>
                </div>
                <div class="ad-dates">
                    <small>
                        <i class="fas fa-calendar"></i>
                        ${ad.start_date} - ${ad.end_date}
                    </small>
                </div>
            </div>
            <div class="ad-actions">
                <button class="btn btn-sm btn-outline" onclick="editAd('${ad.id}')" title="تعديل">
                    <i class="fas fa-edit"></i>
                </button>
                <button class="btn btn-sm btn-outline" onclick="toggleAdStatus('${ad.id}')" title="${ad.is_active ? 'تعطيل' : 'تفعيل'}">
                    <i class="fas fa-${ad.is_active ? 'pause' : 'play'}"></i>
                </button>
                <button class="btn btn-sm btn-danger" onclick="deleteAd('${ad.id}')" title="حذف">
                    <i class="fas fa-trash"></i>
                </button>
            </div>
        </div>
    `).join('');
    
    grid.innerHTML = adsHTML;
}

function openAddAdModal() {
    editingId = null;
    document.getElementById('adModalTitle').textContent = 'إضافة إعلان جديد';
    document.getElementById('adTitle').value = '';
    document.getElementById('adPage').value = '';
    document.getElementById('adPosition').value = '';
    document.getElementById('adLink').value = '';
    document.getElementById('adImage').value = '';
    document.getElementById('adImagePreview').innerHTML = '';
    document.getElementById('adStartDate').value = '';
    document.getElementById('adEndDate').value = '';
    document.getElementById('addAdModal').style.display = 'flex';
}

function closeAddAdModal() {
    document.getElementById('addAdModal').style.display = 'none';
}

function previewAdImage(event) {
    const file = event.target.files[0];
    if (file) {
        const reader = new FileReader();
        reader.onload = (e) => {
            document.getElementById('adImagePreview').innerHTML = `
                <img src="${e.target.result}" alt="Preview">
                <button type="button" class="btn btn-sm btn-danger" onclick="clearAdImage()">
                    <i class="fas fa-times"></i>
                </button>
            `;
        };
        reader.readAsDataURL(file);
    }
}

function clearAdImage() {
    document.getElementById('adImage').value = '';
    document.getElementById('adImagePreview').innerHTML = '';
}

async function saveAd() {
    const title = document.getElementById('adTitle').value;
    const page = document.getElementById('adPage').value;
    const position = document.getElementById('adPosition').value;
    const link = document.getElementById('adLink').value;
    const imageFile = document.getElementById('adImage').files[0];
    const startDate = document.getElementById('adStartDate').value;
    const endDate = document.getElementById('adEndDate').value;
    
    // Validation
    if (!title || !page || !position || !imageFile) {
        showToast('يرجى ملء جميع الحقول المطلوبة', 'error');
        return;
    }
    
    try {
        console.log('💾 جاري حفظ الإعلان...');
        
        // In production:
        // 1. Upload image to Cloudinary
        // 2. Save ad to database
        // const imageUrl = await uploadToCloudinary(imageFile);
        // await apiRequest('/api/admin/ads', { method: 'POST', body: {...} });
        
        // Mock success
        showToast('تم حفظ الإعلان بنجاح', 'success');
        closeAddAdModal();
        loadAds();
    } catch (error) {
        console.error('❌ خطأ في حفظ الإعلان:', error);
        showToast('فشل حفظ الإعلان', 'error');
    }
}

function editAd(id) {
    const ad = adsData.find(a => a.id === id);
    if (!ad) return;
    
    editingId = id;
    document.getElementById('adModalTitle').textContent = 'تعديل إعلان';
    document.getElementById('adTitle').value = ad.title;
    document.getElementById('adPage').value = ad.page;
    document.getElementById('adPosition').value = ad.position;
    document.getElementById('adLink').value = ad.link;
    document.getElementById('adStartDate').value = ad.start_date;
    document.getElementById('adEndDate').value = ad.end_date;
    document.getElementById('adImagePreview').innerHTML = `<img src="${ad.image_url}" alt="${ad.title}">`;
    document.getElementById('addAdModal').style.display = 'flex';
}

async function toggleAdStatus(id) {
    console.log('تبديل حالة الإعلان:', id);
    // In production: await apiRequest(`/api/admin/ads/${id}/toggle`, { method: 'PATCH' });
    const ad = adsData.find(a => a.id === id);
    if (ad) {
        ad.is_active = !ad.is_active;
        renderAds();
        showToast(`تم ${ad.is_active ? 'تفعيل' : 'تعطيل'} الإعلان`, 'success');
    }
}

async function deleteAd(id) {
    if (!confirm('هل أنت متأكد من حذف هذا الإعلان؟')) return;
    
    console.log('حذف إعلان:', id);
    // In production: await apiRequest(`/api/admin/ads/${id}`, { method: 'DELETE' });
    adsData = adsData.filter(a => a.id !== id);
    renderAds();
    document.getElementById('adsCount').textContent = adsData.length;
    showToast('تم حذف الإعلان بنجاح', 'success');
}

// ==================== PARTNERS MANAGEMENT ====================

async function loadPartners() {
    try {
        console.log('🤝 جاري تحميل الشركاء...');
        
        // In production: const partners = await apiRequest('/api/admin/partners');
        partnersData = generateMockPartners();
        
        renderPartners();
        document.getElementById('partnersCount').textContent = partnersData.length;
        
        console.log('✅ تم تحميل الشركاء بنجاح');
    } catch (error) {
        console.error('❌ خطأ في تحميل الشركاء:', error);
        showToast('فشل تحميل الشركاء', 'error');
    }
}

function renderPartners() {
    const list = document.getElementById('partnersList');
    
    if (partnersData.length === 0) {
        list.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-handshake"></i>
                <p>لا يوجد شركاء حالياً</p>
                <button class="btn btn-primary" onclick="openAddPartnerModal()">
                    <i class="fas fa-plus"></i>
                    إضافة شريك جديد
                </button>
            </div>
        `;
        return;
    }
    
    const partnersHTML = partnersData.map(partner => `
        <div class="partner-item" data-id="${partner.id}">
            <div class="drag-handle">
                <i class="fas fa-grip-vertical"></i>
            </div>
            <div class="partner-logo">
                <img src="${partner.logo_url}" alt="${partner.name}">
            </div>
            <div class="partner-info">
                <h4>${partner.name}</h4>
                ${partner.website ? `<a href="${partner.website}" target="_blank" class="partner-website">
                    <i class="fas fa-external-link-alt"></i>
                    ${partner.website}
                </a>` : ''}
                <div class="partner-stats">
                    <span>
                        <i class="fas fa-mouse-pointer"></i>
                        ${partner.clicks.toLocaleString()} نقرة
                    </span>
                </div>
            </div>
            <div class="partner-actions">
                <button class="btn btn-sm btn-outline" onclick="editPartner('${partner.id}')" title="تعديل">
                    <i class="fas fa-edit"></i>
                </button>
                <button class="btn btn-sm btn-danger" onclick="deletePartner('${partner.id}')" title="حذف">
                    <i class="fas fa-trash"></i>
                </button>
            </div>
        </div>
    `).join('');
    
    list.innerHTML = partnersHTML;
}

function openAddPartnerModal() {
    editingId = null;
    document.getElementById('partnerModalTitle').textContent = 'إضافة شريك جديد';
    document.getElementById('partnerName').value = '';
    document.getElementById('partnerWebsite').value = '';
    document.getElementById('partnerLogo').value = '';
    document.getElementById('partnerLogoPreview').innerHTML = '';
    document.getElementById('addPartnerModal').style.display = 'flex';
}

function closeAddPartnerModal() {
    document.getElementById('addPartnerModal').style.display = 'none';
}

function previewPartnerLogo(event) {
    const file = event.target.files[0];
    if (file) {
        const reader = new FileReader();
        reader.onload = (e) => {
            document.getElementById('partnerLogoPreview').innerHTML = `
                <img src="${e.target.result}" alt="Preview">
                <button type="button" class="btn btn-sm btn-danger" onclick="clearPartnerLogo()">
                    <i class="fas fa-times"></i>
                </button>
            `;
        };
        reader.readAsDataURL(file);
    }
}

function clearPartnerLogo() {
    document.getElementById('partnerLogo').value = '';
    document.getElementById('partnerLogoPreview').innerHTML = '';
}

async function savePartner() {
    const name = document.getElementById('partnerName').value;
    const website = document.getElementById('partnerWebsite').value;
    const logoFile = document.getElementById('partnerLogo').files[0];
    
    if (!name || !logoFile) {
        showToast('يرجى ملء جميع الحقول المطلوبة', 'error');
        return;
    }
    
    try {
        console.log('💾 جاري حفظ الشريك...');
        
        // In production: Upload to Cloudinary + Save to database
        
        showToast('تم حفظ الشريك بنجاح', 'success');
        closeAddPartnerModal();
        loadPartners();
    } catch (error) {
        console.error('❌ خطأ في حفظ الشريك:', error);
        showToast('فشل حفظ الشريك', 'error');
    }
}

function editPartner(id) {
    const partner = partnersData.find(p => p.id === id);
    if (!partner) return;
    
    editingId = id;
    document.getElementById('partnerModalTitle').textContent = 'تعديل شريك';
    document.getElementById('partnerName').value = partner.name;
    document.getElementById('partnerWebsite').value = partner.website || '';
    document.getElementById('partnerLogoPreview').innerHTML = `<img src="${partner.logo_url}" alt="${partner.name}">`;
    document.getElementById('addPartnerModal').style.display = 'flex';
}

async function deletePartner(id) {
    if (!confirm('هل أنت متأكد من حذف هذا الشريك؟')) return;
    
    console.log('حذف شريك:', id);
    partnersData = partnersData.filter(p => p.id !== id);
    renderPartners();
    document.getElementById('partnersCount').textContent = partnersData.length;
    showToast('تم حذف الشريك بنجاح', 'success');
}

// ==================== CATEGORIES MANAGEMENT ====================

async function loadCategories() {
    try {
        console.log('🗂️ جاري تحميل الفئات...');
        
        // In production: const categories = await apiRequest('/api/admin/categories');
        categoriesData = generateMockCategories();
        
        renderCategories();
        document.getElementById('categoriesCount').textContent = categoriesData.length;
        
        console.log('✅ تم تحميل الفئات بنجاح');
    } catch (error) {
        console.error('❌ خطأ في تحميل الفئات:', error);
        showToast('فشل تحميل الفئات', 'error');
    }
}

function renderCategories() {
    const list = document.getElementById('categoriesList');
    
    if (categoriesData.length === 0) {
        list.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-tags"></i>
                <p>لا توجد فئات حالياً</p>
                <button class="btn btn-primary" onclick="openAddCategoryModal()">
                    <i class="fas fa-plus"></i>
                    إضافة فئة جديدة
                </button>
            </div>
        `;
        return;
    }
    
    const categoriesHTML = categoriesData.map(category => `
        <div class="category-item ${category.is_active ? '' : 'inactive'}" data-id="${category.id}">
            <div class="drag-handle">
                <i class="fas fa-grip-vertical"></i>
            </div>
            <div class="category-emoji" style="background: ${category.color}20; color: ${category.color};">
                ${category.emoji}
            </div>
            <div class="category-info">
                <h4>${category.name_ar}</h4>
                <p>${category.name_en}</p>
                ${category.description ? `<small>${category.description}</small>` : ''}
                <div class="category-stats">
                    <span>
                        <i class="fas fa-box"></i>
                        ${category.services_count} خدمة
                    </span>
                </div>
            </div>
            <div class="category-actions">
                <button class="btn btn-sm btn-outline" onclick="toggleCategoryStatus('${category.id}')" title="${category.is_active ? 'تعطيل' : 'تفعيل'}">
                    <i class="fas fa-${category.is_active ? 'pause' : 'play'}"></i>
                </button>
                <button class="btn btn-sm btn-outline" onclick="editCategory('${category.id}')" title="تعديل">
                    <i class="fas fa-edit"></i>
                </button>
                <button class="btn btn-sm btn-danger" onclick="deleteCategory('${category.id}')" title="حذف">
                    <i class="fas fa-trash"></i>
                </button>
            </div>
        </div>
    `).join('');
    
    list.innerHTML = categoriesHTML;
}

function openAddCategoryModal() {
    editingId = null;
    document.getElementById('categoryModalTitle').textContent = 'إضافة فئة جديدة';
    document.getElementById('categoryNameAr').value = '';
    document.getElementById('categoryNameEn').value = '';
    document.getElementById('categoryEmoji').value = '';
    document.getElementById('categoryColor').value = '#6366f1';
    document.getElementById('categoryColorPreview').style.background = '#6366f1';
    document.getElementById('categoryDescription').value = '';
    document.getElementById('addCategoryModal').style.display = 'flex';
}

function closeAddCategoryModal() {
    document.getElementById('addCategoryModal').style.display = 'none';
    document.getElementById('emojiPicker').style.display = 'none';
}

function openEmojiPicker() {
    const picker = document.getElementById('emojiPicker');
    picker.style.display = picker.style.display === 'none' ? 'block' : 'none';
}

function selectEmoji(emoji) {
    document.getElementById('categoryEmoji').value = emoji;
    document.getElementById('emojiPicker').style.display = 'none';
}

async function saveCategory() {
    const nameAr = document.getElementById('categoryNameAr').value;
    const nameEn = document.getElementById('categoryNameEn').value;
    const emoji = document.getElementById('categoryEmoji').value;
    const color = document.getElementById('categoryColor').value;
    const description = document.getElementById('categoryDescription').value;
    
    if (!nameAr || !nameEn || !emoji) {
        showToast('يرجى ملء جميع الحقول المطلوبة', 'error');
        return;
    }
    
    try {
        console.log('💾 جاري حفظ الفئة...');
        
        // In production: await apiRequest('/api/admin/categories', { method: 'POST', body: {...} });
        
        showToast('تم حفظ الفئة بنجاح', 'success');
        closeAddCategoryModal();
        loadCategories();
    } catch (error) {
        console.error('❌ خطأ في حفظ الفئة:', error);
        showToast('فشل حفظ الفئة', 'error');
    }
}

function editCategory(id) {
    const category = categoriesData.find(c => c.id === id);
    if (!category) return;
    
    editingId = id;
    document.getElementById('categoryModalTitle').textContent = 'تعديل فئة';
    document.getElementById('categoryNameAr').value = category.name_ar;
    document.getElementById('categoryNameEn').value = category.name_en;
    document.getElementById('categoryEmoji').value = category.emoji;
    document.getElementById('categoryColor').value = category.color;
    document.getElementById('categoryColorPreview').style.background = category.color;
    document.getElementById('categoryDescription').value = category.description || '';
    document.getElementById('addCategoryModal').style.display = 'flex';
}

async function toggleCategoryStatus(id) {
    console.log('تبديل حالة الفئة:', id);
    const category = categoriesData.find(c => c.id === id);
    if (category) {
        category.is_active = !category.is_active;
        renderCategories();
        showToast(`تم ${category.is_active ? 'تفعيل' : 'تعطيل'} الفئة`, 'success');
    }
}

async function deleteCategory(id) {
    if (!confirm('هل أنت متأكد من حذف هذه الفئة؟')) return;
    
    console.log('حذف فئة:', id);
    categoriesData = categoriesData.filter(c => c.id !== id);
    renderCategories();
    document.getElementById('categoriesCount').textContent = categoriesData.length;
    showToast('تم حذف الفئة بنجاح', 'success');
}

// ==================== DRAG AND DROP ====================

function initDragAndDrop() {
    // Partners drag and drop
    const partnersList = document.getElementById('partnersList');
    if (partnersList) {
        new Sortable(partnersList, {
            animation: 150,
            handle: '.drag-handle',
            onEnd: function(evt) {
                console.log('تم تغيير ترتيب الشركاء');
                updatePartnersOrder();
            }
        });
    }
    
    // Categories drag and drop
    const categoriesList = document.getElementById('categoriesList');
    if (categoriesList) {
        new Sortable(categoriesList, {
            animation: 150,
            handle: '.drag-handle',
            onEnd: function(evt) {
                console.log('تم تغيير ترتيب الفئات');
                updateCategoriesOrder();
            }
        });
    }
}

async function updatePartnersOrder() {
    const items = document.querySelectorAll('#partnersList .partner-item');
    const newOrder = Array.from(items).map((item, index) => ({
        id: item.getAttribute('data-id'),
        order: index
    }));
    
    console.log('ترتيب الشركاء الجديد:', newOrder);
    // In production: await apiRequest('/api/admin/partners/reorder', { method: 'POST', body: newOrder });
    showToast('تم تحديث ترتيب الشركاء', 'success');
}

async function updateCategoriesOrder() {
    const items = document.querySelectorAll('#categoriesList .category-item');
    const newOrder = Array.from(items).map((item, index) => ({
        id: item.getAttribute('data-id'),
        order: index
    }));
    
    console.log('ترتيب الفئات الجديد:', newOrder);
    // In production: await apiRequest('/api/admin/categories/reorder', { method: 'POST', body: newOrder });
    showToast('تم تحديث ترتيب الفئات', 'success');
}

// ==================== MOCK DATA GENERATORS ====================

function generateMockAds() {
    return [
        {
            id: 'ad-1',
            title: 'عرض خاص - خصم 50%',
            page: 'home',
            page_label: 'الرئيسية',
            position: 'top',
            position_label: 'أعلى الصفحة',
            image_url: 'https://via.placeholder.com/800x300/6366f1/ffffff?text=عرض+خاص',
            link: 'https://example.com/offer',
            start_date: '2025-01-01',
            end_date: '2025-12-31',
            is_active: true,
            impressions: 125432,
            clicks: 8765,
            ctr: 7.0
        },
        {
            id: 'ad-2',
            title: 'افتتاح فرع جديد',
            page: 'services',
            page_label: 'الخدمات',
            position: 'middle',
            position_label: 'منتصف الصفحة',
            image_url: 'https://via.placeholder.com/800x300/10b981/ffffff?text=افتتاح+فرع+جديد',
            link: 'https://example.com/new-branch',
            start_date: '2025-01-15',
            end_date: '2025-02-15',
            is_active: true,
            impressions: 98765,
            clicks: 5432,
            ctr: 5.5
        }
    ];
}

function generateMockPartners() {
    return [
        { id: 'p-1', name: 'شركة كرمار', logo_url: 'https://via.placeholder.com/200/6366f1/ffffff?text=كرمار', website: 'https://karmar.sa', clicks: 2345, order: 0 },
        { id: 'p-2', name: 'مؤسسة النجاح', logo_url: 'https://via.placeholder.com/200/10b981/ffffff?text=النجاح', website: 'https://alnajah.sa', clicks: 1876, order: 1 },
        { id: 'p-3', name: 'شركة الأمانة', logo_url: 'https://via.placeholder.com/200/f59e0b/ffffff?text=الأمانة', website: null, clicks: 1543, order: 2 },
        { id: 'p-4', name: 'مجموعة الراجحي', logo_url: 'https://via.placeholder.com/200/8b5cf6/ffffff?text=الراجحي', website: 'https://alrajhi.com', clicks: 3456, order: 3 }
    ];
}

function generateMockCategories() {
    return [
        { id: 'c-1', name_ar: 'المطاعم والمقاهي', name_en: 'Restaurants & Cafes', emoji: '🍔', color: '#6366f1', description: 'جميع المطاعم والمقاهي في عرعر', is_active: true, services_count: 45, order: 0 },
        { id: 'c-2', name_ar: 'العقارات', name_en: 'Real Estate', emoji: '🏠', color: '#10b981', description: 'بيع وشراء وتأجير العقارات', is_active: true, services_count: 32, order: 1 },
        { id: 'c-3', name_ar: 'السيارات', name_en: 'Vehicles', emoji: '🚗', color: '#f59e0b', description: 'خدمات السيارات والنقل', is_active: true, services_count: 28, order: 2 },
        { id: 'c-4', name_ar: 'الخدمات المنزلية', name_en: 'Home Services', emoji: '🔧', color: '#8b5cf6', description: 'صيانة وخدمات منزلية', is_active: true, services_count: 56, order: 3 },
        { id: 'c-5', name_ar: 'التعليم', name_en: 'Education', emoji: '🎓', color: '#ef4444', description: 'المراكز التعليمية والدورات', is_active: false, services_count: 12, order: 4 }
    ];
}

