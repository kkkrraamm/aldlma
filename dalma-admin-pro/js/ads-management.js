// ==================== ADS MANAGEMENT - Complete & Professional ====================

const API_BASE = 'https://dalma-api.onrender.com';
let adsData = [];
let editingAdId = null;
let uploadedImageUrl = null;

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    if (checkAuth()) {
        loadAds();
    }
});

// Check authentication
function checkAuth() {
    const token = localStorage.getItem('admin_token');
    const apiKey = localStorage.getItem('admin_apiKey');
    
    if (!token || !apiKey) {
        console.log('❌ [AUTH] No credentials found, redirecting to login...');
        window.location.href = 'login.html';
        return false;
    }
    
    console.log('✅ [AUTH] Credentials found');
    return true;
}

// Get auth headers
function getAuthHeaders() {
    return {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
        'x-api-key': localStorage.getItem('admin_apiKey')
    };
}

// ==================== LOAD ADS ====================

async function loadAds() {
    try {
        console.log('📢 Loading ads...');
        showLoading();
        
        const response = await fetch(`${API_BASE}/api/admin/ads`, {
            headers: getAuthHeaders()
        });
        
        if (response.status === 401 || response.status === 403) {
            console.error('❌ [AUTH] Unauthorized - redirecting to login...');
            localStorage.removeItem('admin_token');
            localStorage.removeItem('admin_apiKey');
            window.location.href = 'login.html';
            return;
        }
        
        if (!response.ok) {
            throw new Error('Failed to load ads');
        }
        
        const data = await response.json();
        adsData = data.ads || [];
        
        renderAds();
        renderStats(data.stats);
        
        const adsCountEl = document.getElementById('adsCount');
        if (adsCountEl) {
            adsCountEl.textContent = adsData.length;
        }
        
        console.log('✅ Ads loaded successfully');
        hideLoading();
    } catch (error) {
        console.error('❌ Error loading ads:', error);
        showToast('فشل تحميل الإعلانات', 'error');
        hideLoading();
    }
}

// ==================== RENDER ADS ====================

function renderAds() {
    const grid = document.getElementById('adsGrid');
    
    if (adsData.length === 0) {
        grid.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-ad fa-4x"></i>
                <h3>لا توجد إعلانات حالياً</h3>
                <p>ابدأ بإضافة إعلان جديد لعرضه في التطبيق</p>
                <button class="btn btn-primary" onclick="openAddAdModal()">
                    <i class="fas fa-plus"></i>
                    إضافة إعلان جديد
                </button>
            </div>
        `;
        return;
    }
    
    const adsHTML = adsData.map(ad => {
        const ctr = ad.impressions > 0 ? ((ad.clicks / ad.impressions) * 100).toFixed(2) : 0;
        const statusClass = ad.is_active ? 'success' : 'danger';
        const statusText = ad.is_active ? 'نشط' : 'معطل';
        const statusIcon = ad.is_active ? 'check-circle' : 'times-circle';
        
        return `
            <div class="ad-card" data-ad-id="${ad.id}">
                <div class="ad-image">
                    <img src="${ad.image_url}" alt="${ad.title}" onerror="this.src='assets/images/placeholder.jpg'">
                    <span class="badge badge-${statusClass} ad-status">
                        <i class="fas fa-${statusIcon}"></i>
                        ${statusText}
                    </span>
                    ${ad.link_type === 'internal' ? '<span class="badge badge-info ad-type">داخلي</span>' : '<span class="badge badge-warning ad-type">خارجي</span>'}
                </div>
                
                <div class="ad-content">
                    <h3>${ad.title}</h3>
                    ${ad.description ? `<p class="ad-description">${ad.description}</p>` : ''}
                    
                    <div class="ad-meta">
                        <span class="meta-item">
                            <i class="fas fa-file"></i>
                            ${getPageLabel(ad.page_location)}
                        </span>
                        <span class="meta-item">
                            <i class="fas fa-map-marker-alt"></i>
                            ${getPositionLabel(ad.position)}
                        </span>
                        <span class="meta-item">
                            <i class="fas fa-sort"></i>
                            ترتيب ${ad.display_order}
                        </span>
                    </div>
                    
                    <div class="ad-link">
                        ${ad.link_type === 'internal' 
                            ? `<span class="link-text"><i class="fas fa-link"></i> ${ad.internal_route}</span>`
                            : `<span class="link-text"><i class="fas fa-external-link-alt"></i> ${ad.link_url || 'لا يوجد'}</span>`
                        }
                    </div>
                    
                    <div class="ad-stats">
                        <div class="stat-item">
                            <div class="stat-icon">
                                <i class="fas fa-eye"></i>
                            </div>
                            <div class="stat-info">
                                <span class="stat-value">${ad.impressions.toLocaleString()}</span>
                                <span class="stat-label">مشاهدة</span>
                            </div>
                        </div>
                        <div class="stat-item">
                            <div class="stat-icon">
                                <i class="fas fa-mouse-pointer"></i>
                            </div>
                            <div class="stat-info">
                                <span class="stat-value">${ad.clicks.toLocaleString()}</span>
                                <span class="stat-label">نقرة</span>
                            </div>
                        </div>
                        <div class="stat-item">
                            <div class="stat-icon">
                                <i class="fas fa-percentage"></i>
                            </div>
                            <div class="stat-info">
                                <span class="stat-value">${ctr}%</span>
                                <span class="stat-label">CTR</span>
                            </div>
                        </div>
                    </div>
                    
                    ${ad.start_date || ad.end_date ? `
                        <div class="ad-dates">
                            <i class="fas fa-calendar-alt"></i>
                            ${ad.start_date ? formatDate(ad.start_date) : 'غير محدد'} - 
                            ${ad.end_date ? formatDate(ad.end_date) : 'غير محدد'}
                        </div>
                    ` : ''}
                </div>
                
                <div class="ad-actions">
                    <button class="btn btn-sm btn-primary" onclick="editAd(${ad.id})" title="تعديل">
                        <i class="fas fa-edit"></i>
                        تعديل
                    </button>
                    <button class="btn btn-sm btn-${ad.is_active ? 'warning' : 'success'}" onclick="toggleAdStatus(${ad.id})" title="${ad.is_active ? 'تعطيل' : 'تفعيل'}">
                        <i class="fas fa-${ad.is_active ? 'pause' : 'play'}"></i>
                        ${ad.is_active ? 'تعطيل' : 'تفعيل'}
                    </button>
                    <button class="btn btn-sm btn-danger" onclick="deleteAd(${ad.id})" title="حذف">
                        <i class="fas fa-trash"></i>
                        حذف
                    </button>
                </div>
            </div>
        `;
    }).join('');
    
    grid.innerHTML = adsHTML;
}

// ==================== RENDER STATS ====================

function renderStats(stats) {
    if (!stats) return;
    
    document.getElementById('totalAds').textContent = stats.total || 0;
    document.getElementById('activeAds').textContent = stats.active || 0;
    document.getElementById('totalImpressions').textContent = (stats.totalImpressions || 0).toLocaleString();
    document.getElementById('totalClicks').textContent = (stats.totalClicks || 0).toLocaleString();
    
    const overallCTR = stats.totalImpressions > 0 
        ? ((stats.totalClicks / stats.totalImpressions) * 100).toFixed(2)
        : 0;
    document.getElementById('overallCTR').textContent = overallCTR + '%';
}

// ==================== ADD/EDIT AD ====================

// Toggle Add Ad Form (Inline)
function toggleAddAdForm() {
    const container = document.getElementById('addAdContainer');
    const btnText = document.getElementById('addAdBtnText');
    const adsGrid = document.getElementById('adsGrid');
    
    if (container.style.display === 'none') {
        // Show form
        editingAdId = null;
        uploadedImageUrl = null;
        selectedImageFile = null;
        
        document.getElementById('modalTitle').textContent = 'إضافة إعلان جديد';
        document.getElementById('adForm').reset();
        document.getElementById('imagePreview').style.display = 'none';
        document.getElementById('uploadPlaceholder').style.display = 'block';
        document.getElementById('linkTypeExternal').checked = true;
        toggleLinkFields('external');
        
        // Reset service category
        document.getElementById('serviceCategoryRow').style.display = 'none';
        document.getElementById('adServiceCategory').value = '';
        
        // Update location description
        setTimeout(() => {
            updateLocationDescription();
            checkDuplicateAd();
        }, 100);
        
        container.style.display = 'block';
        btnText.textContent = 'إلغاء';
        adsGrid.style.display = 'none';
        
        // Scroll to form
        container.scrollIntoView({ behavior: 'smooth', block: 'start' });
    } else {
        // Hide form
        container.style.display = 'none';
        btnText.textContent = 'إضافة إعلان جديد';
        adsGrid.style.display = 'grid';
        editingAdId = null;
        uploadedImageUrl = null;
    }
}

// Keep old function for compatibility
function openAddAdModal() {
    toggleAddAdForm();
}

async function editAd(id) {
    editingAdId = id;
    const ad = adsData.find(a => a.id === id);
    
    if (!ad) {
        showToast('الإعلان غير موجود', 'error');
        return;
    }
    
    const container = document.getElementById('addAdContainer');
    const btnText = document.getElementById('addAdBtnText');
    const adsGrid = document.getElementById('adsGrid');
    
    document.getElementById('modalTitle').textContent = 'تعديل الإعلان';
    document.getElementById('adTitle').value = ad.title || '';
    document.getElementById('adDescription').value = ad.description || '';
    
    // Parse page_location for services (extract category if exists)
    let pageLocation = ad.page_location || 'home';
    let serviceCategory = '';
    if (pageLocation.startsWith('services_')) {
        serviceCategory = pageLocation.replace('services_', '');
        pageLocation = 'services';
    }
    
    document.getElementById('adPageLocation').value = pageLocation;
    document.getElementById('adPosition').value = ad.position || 'top';
    document.getElementById('adDisplayOrder').value = ad.display_order || 0;
    
    // Set service category if services page
    if (pageLocation === 'services') {
        document.getElementById('serviceCategoryRow').style.display = 'block';
        document.getElementById('adServiceCategory').value = serviceCategory;
    } else {
        document.getElementById('serviceCategoryRow').style.display = 'none';
        document.getElementById('adServiceCategory').value = '';
    }
    
    // Link type
    if (ad.link_type === 'internal') {
        document.getElementById('linkTypeInternal').checked = true;
        document.getElementById('adInternalRoute').value = ad.internal_route || '';
        toggleLinkFields('internal');
    } else {
        document.getElementById('linkTypeExternal').checked = true;
        document.getElementById('adLinkUrl').value = ad.link_url || '';
        toggleLinkFields('external');
    }
    
    // Dates
    if (ad.start_date) {
        document.getElementById('adStartDate').value = ad.start_date.split('T')[0];
    }
    if (ad.end_date) {
        document.getElementById('adEndDate').value = ad.end_date.split('T')[0];
    }
    
    // Image
    uploadedImageUrl = ad.image_url;
    selectedImageFile = null; // Reset file selection
    if (ad.image_url) {
        document.getElementById('imagePreview').src = ad.image_url;
        document.getElementById('imagePreview').style.display = 'block';
        document.getElementById('uploadPlaceholder').style.display = 'none';
    }
    
    // Show form
    container.style.display = 'block';
    btnText.textContent = 'إلغاء';
    adsGrid.style.display = 'none';
    
    // Update location description and check duplicates
    setTimeout(() => {
        updateLocationDescription();
        checkDuplicateAd();
    }, 100);
    
    // Scroll to form
    container.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

function closeAdModal() {
    // Hide inline form
    toggleAddAdForm();
}

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

// Handle image selection (preview only, no upload yet)
let selectedImageFile = null;

function handleImageUpload(event) {
    const file = event.target.files[0];
    if (!file) return;
    
    // Validate file type
    if (!file.type.startsWith('image/')) {
        showToast('يرجى اختيار صورة صحيحة', 'error');
        event.target.value = '';
        return;
    }
    
    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
        showToast('حجم الصورة يجب أن يكون أقل من 5 ميجابايت', 'error');
        event.target.value = '';
        return;
    }
    
    // Store file for later upload
    selectedImageFile = file;
    
    // Show local preview only
    const imagePreview = document.getElementById('imagePreview');
    const uploadPlaceholder = document.getElementById('uploadPlaceholder');
    
    const reader = new FileReader();
    reader.onload = (e) => {
        imagePreview.src = e.target.result;
        imagePreview.style.display = 'block';
        uploadPlaceholder.style.display = 'none';
    };
    reader.readAsDataURL(file);
    
    console.log('📸 [IMAGE] تم اختيار الصورة:', file.name, '- سيتم الرفع عند الحفظ');
}

// Upload image to Cloudinary (called when saving ad)
async function uploadImageToCloudinary() {
    if (!selectedImageFile) {
        return null;
    }
    
    try {
        console.log('☁️ [CLOUDINARY] رفع صورة إعلان:', selectedImageFile.name);
        
        const formData = new FormData();
        formData.append('image', selectedImageFile);
        
        const response = await fetch(
            `${API_BASE}/api/admin/upload-ad-image`,
            {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
                    'x-api-key': localStorage.getItem('admin_apiKey')
                },
                body: formData
            }
        );
        
        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.error || `Server error: ${response.status}`);
        }
        
        const data = await response.json();
        
        if (!data.success || !data.url) {
            throw new Error('No URL returned from server');
        }
        
        console.log('✅ [CLOUDINARY] تم رفع الصورة:', data.url);
        return data.url;
    } catch (error) {
        console.error('❌ Error uploading image:', error);
        throw error;
    }
}

// Save ad
async function saveAd(event) {
    event.preventDefault();
    
    const title = document.getElementById('adTitle').value.trim();
    const description = document.getElementById('adDescription').value.trim();
    let pageLocation = document.getElementById('adPageLocation').value;
    const position = document.getElementById('adPosition').value;
    const displayOrder = parseInt(document.getElementById('adDisplayOrder').value) || 0;
    const serviceCategory = document.getElementById('adServiceCategory').value;
    const linkType = document.querySelector('input[name="linkType"]:checked').value;
    const linkUrl = document.getElementById('adLinkUrl').value.trim();
    const internalRoute = document.getElementById('adInternalRoute').value.trim();
    const startDate = document.getElementById('adStartDate').value;
    const endDate = document.getElementById('adEndDate').value;
    
    // Build actual page_location for services (include category if selected)
    if (pageLocation === 'services' && serviceCategory) {
        pageLocation = `services_${serviceCategory}`;
    }
    
    // Check for duplicates before saving
    if (checkDuplicateAd()) {
        showToast('يوجد إعلان آخر في نفس الموقع والترتيب. يرجى تغيير الترتيب أو الموضع', 'error');
        return;
    }
    
    // Validation
    if (!title) {
        showToast('يرجى إدخال عنوان الإعلان', 'error');
        return;
    }
    
    // Validate position for offers (only for home page)
    if (position === 'offers' && pageLocation !== 'home') {
        showToast('موضع "قسم العروض" متاح فقط للصفحة الرئيسية', 'error');
        return;
    }
    
    // Check if image is selected (either new file or existing URL)
    if (!selectedImageFile && !uploadedImageUrl) {
        showToast('يرجى اختيار صورة الإعلان', 'error');
        return;
    }
    
    if (linkType === 'external' && !linkUrl) {
        showToast('يرجى إدخال الرابط الخارجي', 'error');
        return;
    }
    
    if (linkType === 'internal' && !internalRoute) {
        showToast('يرجى إدخال المسار الداخلي', 'error');
        return;
    }
    
    try {
        showToast('جاري الحفظ...', 'info');
        
        // Upload image if a new one is selected
        let finalImageUrl = uploadedImageUrl;
        if (selectedImageFile) {
            showToast('جاري رفع الصورة...', 'info');
            finalImageUrl = await uploadImageToCloudinary();
            if (!finalImageUrl) {
                throw new Error('فشل رفع الصورة');
            }
        }
        
        const adData = {
            title,
            description,
            image_url: finalImageUrl,
            link_type: linkType,
            link_url: linkType === 'external' ? linkUrl : null,
            internal_route: linkType === 'internal' ? internalRoute : null,
            page_location: pageLocation,
            position,
            display_order: displayOrder,
            start_date: startDate || null,
            end_date: endDate || null,
            is_active: true
        };
        
        const url = editingAdId 
            ? `${API_BASE}/api/admin/ads/${editingAdId}`
            : `${API_BASE}/api/admin/ads`;
        
        const method = editingAdId ? 'PUT' : 'POST';
        
        const response = await fetch(url, {
            method,
            headers: getAuthHeaders(),
            body: JSON.stringify(adData)
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            throw new Error(data.error || 'فشل حفظ الإعلان');
        }
        
        showToast(data.message || 'تم حفظ الإعلان بنجاح', 'success');
        
        // Reset
        selectedImageFile = null;
        uploadedImageUrl = null;
        
        closeAdModal();
        loadAds();
    } catch (error) {
        console.error('❌ Error saving ad:', error);
        showToast(error.message || 'فشل حفظ الإعلان', 'error');
    }
}

// ==================== TOGGLE AD STATUS ====================

async function toggleAdStatus(id) {
    if (!confirm('هل أنت متأكد من تغيير حالة الإعلان؟')) {
        return;
    }
    
    try {
        const response = await fetch(`${API_BASE}/api/admin/ads/${id}/toggle`, {
            method: 'POST',
            headers: getAuthHeaders()
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            throw new Error(data.error || 'فشل تغيير حالة الإعلان');
        }
        
        showToast(data.message, 'success');
        loadAds();
    } catch (error) {
        console.error('❌ Error toggling ad status:', error);
        showToast(error.message || 'فشل تغيير حالة الإعلان', 'error');
    }
}

// ==================== DELETE AD ====================

async function deleteAd(id) {
    if (!confirm('هل أنت متأكد من حذف هذا الإعلان؟ لا يمكن التراجع عن هذا الإجراء.')) {
        return;
    }
    
    try {
        const response = await fetch(`${API_BASE}/api/admin/ads/${id}`, {
            method: 'DELETE',
            headers: getAuthHeaders()
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            throw new Error(data.error || 'فشل حذف الإعلان');
        }
        
        showToast(data.message, 'success');
        loadAds();
    } catch (error) {
        console.error('❌ Error deleting ad:', error);
        showToast(error.message || 'فشل حذف الإعلان', 'error');
    }
}

// ==================== HELPER FUNCTIONS ====================

function getPageLabel(page) {
    const labels = {
        'home': 'الصفحة الرئيسية',
        'services': 'الخدمات',
        'realty': 'العقارات',
        'trends': 'الترندات',
        'orders': 'الطلبات'
    };
    return labels[page] || page;
}

function getPositionLabel(position) {
    const labels = {
        'top': 'أعلى',
        'bottom': 'أسفل',
        'middle': 'وسط'
    };
    return labels[position] || position;
}

function formatDate(dateString) {
    if (!dateString) return '';
    const date = new Date(dateString);
    return date.toLocaleDateString('ar-SA', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });
}

function showLoading() {
    document.getElementById('loadingOverlay')?.classList.add('active');
}

function hideLoading() {
    document.getElementById('loadingOverlay')?.classList.remove('active');
}

function showToast(message, type = 'info') {
    // Implement toast notification
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.textContent = message;
    document.body.appendChild(toast);
    
    setTimeout(() => {
        toast.classList.add('show');
    }, 100);
    
    setTimeout(() => {
        toast.classList.remove('show');
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

// Image upload is now handled via Backend API
// No need for Cloudinary credentials in frontend (more secure)

// ==================== KEYBOARD SHORTCUT: Tab + R ====================
// Show Ad Locations Guide
document.addEventListener('keydown', (e) => {
    // Check if Tab + R is pressed
    if (e.key === 'r' && e.shiftKey && !e.ctrlKey && !e.altKey && !e.metaKey) {
        e.preventDefault();
        const overlay = document.getElementById('adLocationsOverlay');
        if (overlay) {
            overlay.style.display = overlay.style.display === 'none' ? 'block' : 'none';
            console.log('🗺️ [SHORTCUT] Ad Locations Guide toggled (Tab + R)');
        }
    }
});

console.log('⌨️ [SHORTCUT] Tab + R: Show/Hide Ad Locations Guide');

// ==================== DYNAMIC LOCATION DESCRIPTION ====================

// Location descriptions based on page and position
const locationDescriptions = {
    home: {
        top: '📍 يظهر في <strong>الصفحة الرئيسية</strong> في <strong>أعلى الصفحة</strong>، بعد حقل البحث مباشرة وقبل زر أوقات الصلاة. هذا هو أول ما يراه المستخدم عند فتح التطبيق.',
        middle: '📍 يظهر في <strong>الصفحة الرئيسية</strong> في <strong>وسط المحتوى</strong>، بين الأقسام المختلفة.',
        bottom: '📍 يظهر في <strong>الصفحة الرئيسية</strong> في <strong>أسفل الصفحة</strong>، قبل التذييل.',
        offers: '📍 يظهر في <strong>الصفحة الرئيسية</strong> داخل قسم <strong>"العروض والإعلانات"</strong>، بعد عنوان القسم مباشرة وقبل العروض الحالية. هذا الموقع مخصص للصفحة الرئيسية فقط.'
    },
    services: {
        top: '📍 يظهر في <strong>صفحة الخدمات</strong> في <strong>أعلى الصفحة</strong>، بعد زر "الكل" مباشرة وقبل قائمة الخدمات. يمكن أن يكون إعلان عام (لجميع الفئات) أو خاص بفئة محددة.',
        middle: '📍 يظهر في <strong>صفحة الخدمات</strong> في <strong>وسط المحتوى</strong>، بين قائمة الخدمات.',
        bottom: '📍 يظهر في <strong>صفحة الخدمات</strong> في <strong>أسفل الصفحة</strong>، بعد قائمة الخدمات.'
    },
    realty: {
        top: '📍 يظهر في <strong>صفحة العقارات</strong> في <strong>أعلى الصفحة</strong>، قبل قائمة العقارات.',
        middle: '📍 يظهر في <strong>صفحة العقارات</strong> في <strong>وسط القائمة</strong>، بعد أول 3 عقارات مباشرة. هذا الموقع مخصص لعرض الإعلانات بين العقارات.',
        bottom: '📍 يظهر في <strong>صفحة العقارات</strong> في <strong>أسفل القائمة</strong>، بعد جميع العقارات.'
    },
    trends: {
        top: '📍 يظهر في <strong>صفحة الترندات</strong> في <strong>أعلى الصفحة</strong>، بعد قائمة الصحفيين وقبل قسم "كيف أسجل كإعلامي؟".',
        middle: '📍 يظهر في <strong>صفحة الترندات</strong> في <strong>وسط المحتوى</strong>، بين المنشورات.',
        bottom: '📍 يظهر في <strong>صفحة الترندات</strong> في <strong>أسفل الصفحة</strong>، بعد جميع المنشورات.'
    },
    add_property: {
        top: '📍 يظهر في <strong>صفحة إضافة عقار</strong> في <strong>أعلى الصفحة</strong>، بعد العنوان الرئيسي مباشرة وقبل حقول النموذج.',
        middle: '📍 يظهر في <strong>صفحة إضافة عقار</strong> في <strong>وسط النموذج</strong>، بين حقول الإدخال.',
        bottom: '📍 يظهر في <strong>صفحة إضافة عقار</strong> في <strong>أسفل النموذج</strong>، قبل زر "نشر العقار".'
    },
    orders: {
        top: '📍 يظهر في <strong>صفحة الطلبات</strong> في <strong>أعلى الصفحة</strong>، قبل قائمة الطلبات.',
        middle: '📍 يظهر في <strong>صفحة الطلبات</strong> في <strong>وسط القائمة</strong>، بين الطلبات.',
        bottom: '📍 يظهر في <strong>صفحة الطلبات</strong> في <strong>أسفل القائمة</strong>، بعد جميع الطلبات.'
    }
};

// Update location description
function updateLocationDescription() {
    const pageLocation = document.getElementById('adPageLocation').value;
    const position = document.getElementById('adPosition').value;
    const serviceCategory = document.getElementById('adServiceCategory').value;
    const descriptionText = document.getElementById('locationDescriptionText');
    
    let description = '';
    
    if (pageLocation && position) {
        // Check if position is valid for this page
        if (position === 'offers' && pageLocation !== 'home') {
            description = '⚠️ <strong>تحذير:</strong> موضع "قسم العروض" متاح فقط للصفحة الرئيسية. يرجى اختيار موضع آخر.';
            descriptionText.style.color = '#ef4444';
        } else {
            let baseDescription = locationDescriptions[pageLocation]?.[position] || '📍 موقع الإعلان في التطبيق';
            
            // Add service category info if services page
            if (pageLocation === 'services') {
                if (serviceCategory) {
                    const categories = getCategories();
                    const category = categories.find(c => c.code === serviceCategory);
                    const categoryName = category ? category.name : serviceCategory;
                    baseDescription += ` <br><br>🎯 <strong>الفئة المحددة:</strong> ${categoryName}. سيظهر هذا الإعلان فقط عند اختيار هذه الفئة في صفحة الخدمات.`;
                } else {
                    baseDescription += ` <br><br>🎯 <strong>الفئة:</strong> الكل (إعلان عام). سيظهر هذا الإعلان لجميع الفئات في صفحة الخدمات.`;
                }
            }
            
            description = baseDescription;
            descriptionText.style.color = '#374151';
        }
    } else {
        description = 'اختر الصفحة والموضع لعرض تفاصيل الموقع';
        descriptionText.style.color = '#374151';
    }
    
    descriptionText.innerHTML = description;
}

// Show/hide service category field
function toggleServiceCategory() {
    const pageLocation = document.getElementById('adPageLocation').value;
    const serviceCategoryRow = document.getElementById('serviceCategoryRow');
    
    if (pageLocation === 'services') {
        serviceCategoryRow.style.display = 'block';
    } else {
        serviceCategoryRow.style.display = 'none';
        document.getElementById('adServiceCategory').value = '';
    }
    
    updateLocationDescription();
}

// Check for duplicate ads (same page, position, and display_order)
function checkDuplicateAd() {
    const pageLocation = document.getElementById('adPageLocation').value;
    const position = document.getElementById('adPosition').value;
    const displayOrder = parseInt(document.getElementById('adDisplayOrder').value) || 0;
    const serviceCategory = document.getElementById('adServiceCategory').value;
    const duplicateWarningRow = document.getElementById('duplicateWarningRow');
    const duplicateWarningText = document.getElementById('duplicateWarningText');
    
    // Build the actual page_location (for services, include category)
    let actualPageLocation = pageLocation;
    if (pageLocation === 'services' && serviceCategory) {
        actualPageLocation = `services_${serviceCategory}`;
    }
    
    // Find duplicate ads (exclude current editing ad)
    const duplicates = adsData.filter(ad => {
        // Skip if editing this ad
        if (editingAdId && ad.id === editingAdId) return false;
        
        // Check if ad is active
        if (!ad.is_active) return false;
        
        // Check page_location match
        let adPageLocation = ad.page_location;
        if (adPageLocation === actualPageLocation && 
            ad.position === position && 
            ad.display_order === displayOrder) {
            return true;
        }
        
        return false;
    });
    
    if (duplicates.length > 0) {
        const duplicate = duplicates[0];
        duplicateWarningText.innerHTML = `⚠️ يوجد إعلان آخر نشط في نفس الموقع والترتيب:<br>
            <strong>الإعلان:</strong> "${duplicate.title}"<br>
            <strong>الصفحة:</strong> ${getPageLabel(duplicate.page_location)}<br>
            <strong>الموضع:</strong> ${getPositionLabel(duplicate.position)}<br>
            <strong>الترتيب:</strong> ${duplicate.display_order}<br><br>
            يرجى تغيير الترتيب أو الموضع لتجنب التكرار.`;
        duplicateWarningRow.style.display = 'block';
        return true;
    } else {
        duplicateWarningRow.style.display = 'none';
        return false;
    }
}

// Get page label
function getPageLabel(pageLocation) {
    const labels = {
        'home': '🏠 الصفحة الرئيسية',
        'services': '🛠️ الخدمات (الكل)',
        'realty': '🏘️ العقارات',
        'trends': '📈 الترندات',
        'orders': '📦 الطلبات',
        'add_property': '➕ إضافة عقار'
    };
    
    // Check if it's a service category
    if (pageLocation.startsWith('services_')) {
        const categoryCode = pageLocation.replace('services_', '');
        const categories = getCategories();
        const category = categories.find(c => c.code === categoryCode);
        if (category) {
            return `🛠️ الخدمات - ${category.name}`;
        }
        return `🛠️ الخدمات - ${categoryCode}`;
    }
    
    return labels[pageLocation] || pageLocation;
}

// Initialize event listeners for location description
document.addEventListener('DOMContentLoaded', () => {
    // Wait for form elements to be available
    setTimeout(() => {
        const pageLocationSelect = document.getElementById('adPageLocation');
        const positionSelect = document.getElementById('adPosition');
        const serviceCategorySelect = document.getElementById('adServiceCategory');
        const displayOrderInput = document.getElementById('adDisplayOrder');
        
        if (pageLocationSelect) {
            pageLocationSelect.addEventListener('change', () => {
                toggleServiceCategory();
                checkDuplicateAd();
            });
        }
        
        if (positionSelect) {
            positionSelect.addEventListener('change', () => {
                updateLocationDescription();
                checkDuplicateAd();
            });
        }
        
        if (serviceCategorySelect) {
            serviceCategorySelect.addEventListener('change', () => {
                updateLocationDescription();
                checkDuplicateAd();
            });
        }
        
        if (displayOrderInput) {
            displayOrderInput.addEventListener('input', () => {
                checkDuplicateAd();
            });
        }
        
        // Initial update
        updateLocationDescription();
    }, 500);
    
    // Load categories on page load
    loadCategories();
});

// ==================== SERVICE CATEGORIES MANAGEMENT ====================

// الفئات الثابتة (نفسها في التطبيق)
const staticCategories = [
    { code: 'electricity', name: 'الكهرباء', icon: '⚡' },
    { code: 'plumbing', name: 'السباكة', icon: '🔧' },
    { code: 'cleaning', name: 'التنظيف', icon: '🧹' },
    { code: 'painting', name: 'الدهان', icon: '🎨' },
    { code: 'carpentry', name: 'النجارة', icon: '🪚' },
    { code: 'air_conditioning', name: 'التكييف', icon: '❄️' },
    { code: 'gardening', name: 'البستنة', icon: '🌳' },
    { code: 'security', name: 'الأمن', icon: '🔒' },
    { code: 'other', name: 'أخرى', icon: '📦' }
];

let categoriesData = [];

// Load categories from API (with fallback to static)
async function loadCategories() {
    try {
        console.log('📋 Loading service categories...');
        const response = await fetch(`${API_BASE}/api/admin/service-categories`, {
            headers: getAuthHeaders()
        });
        
        if (response.status === 401 || response.status === 403) {
            console.error('❌ [AUTH] Unauthorized - redirecting to login...');
            localStorage.removeItem('admin_token');
            localStorage.removeItem('admin_apiKey');
            window.location.href = 'login.html';
            return;
        }
        
        if (response.ok) {
            categoriesData = await response.json();
            console.log('✅ Categories loaded from API');
        } else {
            // Fallback to static categories
            console.warn('⚠️ Failed to load from API, using static categories');
            categoriesData = staticCategories;
        }
        
        renderCategories(categoriesData);
        updateCategoriesDropdown(categoriesData);
        updateCategoriesCount(categoriesData.length);
        console.log('✅ Categories ready: ${categoriesData.length}');
    } catch (error) {
        console.error('❌ Error loading categories, using static:', error);
        // Use static categories as fallback
        categoriesData = staticCategories;
        renderCategories(categoriesData);
        updateCategoriesDropdown(categoriesData);
        updateCategoriesCount(categoriesData.length);
    }
}

// Get categories (for use in other functions)
function getCategories() {
    // Always return static categories for dropdown (to match app)
    // But show database categories in management section
    return staticCategories;
}

// Render categories list
function renderCategories(categories) {
    const container = document.getElementById('categoriesList');
    if (!container) return;
    
    if (categories.length === 0) {
        container.innerHTML = `
            <div style="text-align: center; padding: 40px; color: var(--text-secondary);">
                <i class="fas fa-tags" style="font-size: 48px; margin-bottom: 15px; opacity: 0.3;"></i>
                <p>لا توجد فئات حالياً</p>
                <p style="font-size: 13px; margin-top: 5px;">ابدأ بإضافة فئة جديدة</p>
            </div>
        `;
        return;
    }
    
    container.innerHTML = categories.map((cat, index) => `
        <div class="category-item" style="display: flex; align-items: center; justify-content: space-between; padding: 15px; background: var(--bg-color); border-radius: 8px; border: 1px solid var(--border-color); transition: all 0.2s;">
            <div style="display: flex; align-items: center; gap: 12px; flex: 1;">
                <div style="font-size: 24px;">${cat.icon || '🏷️'}</div>
                <div style="flex: 1;">
                    <div style="font-weight: 600; color: var(--text-color); margin-bottom: 4px;">
                        ${cat.name}
                    </div>
                    <div style="font-size: 12px; color: var(--text-secondary); font-family: monospace;">
                        <i class="fas fa-code"></i> ${cat.code} → services_${cat.code}
                    </div>
                </div>
            </div>
            <button class="btn btn-icon" onclick="deleteCategory('${cat.code}')" style="color: #ef4444; padding: 8px 12px;" title="حذف الفئة">
                <i class="fas fa-trash"></i>
            </button>
        </div>
    `).join('');
}

// Update categories dropdown in ad form
function updateCategoriesDropdown(categories) {
    const select = document.getElementById('adServiceCategory');
    if (!select) return;
    
    // Always use static categories for dropdown (to match app)
    const categoriesToUse = staticCategories;
    const currentValue = select.value;
    
    // Clear existing category options (keep "الكل")
    Array.from(select.options).forEach(opt => {
        if (opt.value !== '') opt.remove();
    });
    
    // Add category options from static categories
    categoriesToUse.forEach(cat => {
        const option = document.createElement('option');
        option.value = cat.code;
        option.textContent = `${cat.icon || '🏷️'} ${cat.name}`;
        select.appendChild(option);
    });
    
    // Restore selected value if still exists
    if (currentValue && select.querySelector(`option[value="${currentValue}"]`)) {
        select.value = currentValue;
    }
}

// Update categories count
function updateCategoriesCount(count) {
    const countEl = document.getElementById('categoriesCount');
    if (countEl) {
        countEl.textContent = count;
    }
}

// Toggle add category form
function toggleAddCategoryForm() {
    const form = document.getElementById('addCategoryForm');
    const batchForm = document.getElementById('batchAddCategoriesForm');
    
    if (form) {
        form.style.display = form.style.display === 'none' ? 'block' : 'none';
        // Close batch form if open
        if (batchForm) batchForm.style.display = 'none';
        
        // Clear inputs when opening
        if (form.style.display === 'block') {
            document.getElementById('newCategoryCode').value = '';
            document.getElementById('newCategoryName').value = '';
        }
    }
}

// Toggle batch add categories form
function toggleBatchAddCategories() {
    const form = document.getElementById('batchAddCategoriesForm');
    const singleForm = document.getElementById('addCategoryForm');
    
    if (form) {
        form.style.display = form.style.display === 'none' ? 'block' : 'none';
        // Close single form if open
        if (singleForm) singleForm.style.display = 'none';
        
        // Clear input when opening
        if (form.style.display === 'block') {
            document.getElementById('batchCategoriesInput').value = '';
        }
    }
}

// Add single category
async function addSingleCategory() {
    const code = document.getElementById('newCategoryCode').value.trim();
    const name = document.getElementById('newCategoryName').value.trim();
    
    if (!code || !name) {
        showToast('يرجى إدخال رمز الفئة واسمها', 'error');
        return;
    }
    
    // Validate code (English only, lowercase, no spaces)
    if (!/^[a-z0-9_]+$/.test(code)) {
        showToast('رمز الفئة يجب أن يكون إنجليزي فقط (أحرف صغيرة، أرقام، _)', 'error');
        return;
    }
    
    try {
        showToast('جاري إضافة الفئة...', 'info');
        
        const response = await fetch(`${API_BASE}/api/admin/service-categories`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify({
                code: code,
                name: name,
                icon: '🏷️'
            })
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            throw new Error(data.error || 'فشل إضافة الفئة');
        }
        
        showToast(data.message || `تم إضافة فئة "${name}" بنجاح`, 'success');
        
        // Clear inputs and close form
        document.getElementById('newCategoryCode').value = '';
        document.getElementById('newCategoryName').value = '';
        toggleAddCategoryForm();
        
        // Reload categories
        loadCategories();
    } catch (error) {
        console.error('❌ Error adding category:', error);
        showToast(error.message || 'فشل إضافة الفئة', 'error');
    }
}

// Add batch categories
async function addBatchCategories() {
    const input = document.getElementById('batchCategoriesInput').value.trim();
    
    if (!input) {
        showToast('يرجى إدخال الفئات', 'error');
        return;
    }
    
    const lines = input.split('\n').filter(line => line.trim());
    const newCategories = [];
    const errors = [];
    
    lines.forEach((line, index) => {
        const trimmed = line.trim();
        if (!trimmed) return;
        
        const parts = trimmed.split(',').map(p => p.trim());
        if (parts.length !== 2) {
            errors.push(`السطر ${index + 1}: صيغة غير صحيحة (يجب أن يكون: رمز,اسم)`);
            return;
        }
        
        const [code, name] = parts;
        
        if (!code || !name) {
            errors.push(`السطر ${index + 1}: رمز الفئة أو الاسم فارغ`);
            return;
        }
        
        // Validate code
        if (!/^[a-z0-9_]+$/.test(code)) {
            errors.push(`السطر ${index + 1}: رمز الفئة "${code}" غير صحيح (يجب أن يكون إنجليزي فقط)`);
            return;
        }
        
        // Check if code already exists in new categories
        if (newCategories.find(c => c.code === code)) {
            errors.push(`السطر ${index + 1}: رمز الفئة "${code}" مكرر في الدفعة`);
            return;
        }
        
        newCategories.push({
            code: code,
            name: name,
            icon: '🏷️'
        });
    });
    
    if (errors.length > 0) {
        showToast(`أخطاء:\n${errors.join('\n')}`, 'error');
        return;
    }
    
    if (newCategories.length === 0) {
        showToast('لم يتم إضافة أي فئات', 'error');
        return;
    }
    
    try {
        showToast(`جاري إضافة ${newCategories.length} فئة...`, 'info');
        
        const response = await fetch(`${API_BASE}/api/admin/service-categories/batch`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify({
                categories: newCategories
            })
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            throw new Error(data.error || 'فشل إضافة الفئات');
        }
        
        let message = data.message || `تم إضافة ${data.added?.length || newCategories.length} فئة بنجاح`;
        if (data.errors && data.errors.length > 0) {
            message += `\n${data.errors.length} فئة فشلت`;
        }
        
        showToast(message, data.errors && data.errors.length > 0 ? 'warning' : 'success');
        
        // Clear input and close form
        document.getElementById('batchCategoriesInput').value = '';
        toggleBatchAddCategories();
        
        // Reload categories
        loadCategories();
    } catch (error) {
        console.error('❌ Error adding batch categories:', error);
        showToast(error.message || 'فشل إضافة الفئات', 'error');
    }
}

// Delete category
async function deleteCategory(code) {
    const category = getCategories().find(c => c.code === code);
    if (!category) {
        showToast('الفئة غير موجودة', 'error');
        return;
    }
    
    if (!confirm('هل أنت متأكد من حذف هذه الفئة؟\n\nملاحظة: الإعلانات المرتبطة بهذه الفئة لن تتأثر، لكن لن تظهر في القائمة.')) {
        return;
    }
    
    try {
        showToast('جاري حذف الفئة...', 'info');
        
        const response = await fetch(`${API_BASE}/api/admin/service-categories/${category.id}`, {
            method: 'DELETE',
            headers: getAuthHeaders()
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            throw new Error(data.error || 'فشل حذف الفئة');
        }
        
        showToast(data.message || 'تم حذف الفئة بنجاح', 'success');
        
        // Reload categories
        loadCategories();
    } catch (error) {
        console.error('❌ Error deleting category:', error);
        showToast(error.message || 'فشل حذف الفئة', 'error');
    }
}

