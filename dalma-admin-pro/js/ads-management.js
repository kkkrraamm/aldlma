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
        
        document.getElementById('modalTitle').textContent = 'إضافة إعلان جديد';
        document.getElementById('adForm').reset();
        document.getElementById('imagePreview').style.display = 'none';
        document.getElementById('uploadPlaceholder').style.display = 'block';
        document.getElementById('linkTypeExternal').checked = true;
        toggleLinkFields('external');
        
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
    document.getElementById('adPageLocation').value = ad.page_location || 'home';
    document.getElementById('adPosition').value = ad.position || 'top';
    document.getElementById('adDisplayOrder').value = ad.display_order || 0;
    
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
    if (ad.image_url) {
        document.getElementById('imagePreview').src = ad.image_url;
        document.getElementById('imagePreview').style.display = 'block';
        document.getElementById('uploadPlaceholder').style.display = 'none';
    }
    
    // Show form
    container.style.display = 'block';
    btnText.textContent = 'إلغاء';
    adsGrid.style.display = 'none';
    
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

// Handle image upload
async function handleImageUpload(event) {
    const file = event.target.files[0];
    if (!file) return;
    
    // Validate file type
    if (!file.type.startsWith('image/')) {
        showToast('يرجى اختيار صورة صحيحة', 'error');
        return;
    }
    
    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
        showToast('حجم الصورة يجب أن يكون أقل من 5 ميجابايت', 'error');
        return;
    }
    
    try {
        showToast('جاري رفع الصورة...', 'info');
        
        // Show preview immediately with local URL
        const imagePreview = document.getElementById('imagePreview');
        const uploadPlaceholder = document.getElementById('uploadPlaceholder');
        
        // Create local preview
        const reader = new FileReader();
        reader.onload = (e) => {
            imagePreview.src = e.target.result;
            imagePreview.style.display = 'block';
            uploadPlaceholder.style.display = 'none';
        };
        reader.readAsDataURL(file);
        
        console.log('☁️ [CLOUDINARY] رفع صورة إعلان:', file.name);
        
        // Upload via Backend API (more secure)
        const formData = new FormData();
        formData.append('image', file);
        
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
        
        uploadedImageUrl = data.url;
        
        // Update preview with Cloudinary URL
        imagePreview.src = uploadedImageUrl;
        
        console.log('✅ [CLOUDINARY] تم رفع الصورة:', uploadedImageUrl);
        showToast('تم رفع الصورة بنجاح', 'success');
    } catch (error) {
        console.error('❌ Error uploading image:', error);
        showToast('فشل رفع الصورة: ' + error.message, 'error');
        
        // Reset preview on error
        const imagePreview = document.getElementById('imagePreview');
        const uploadPlaceholder = document.getElementById('uploadPlaceholder');
        imagePreview.style.display = 'none';
        uploadPlaceholder.style.display = 'block';
        uploadedImageUrl = null;
    }
}

// Save ad
async function saveAd(event) {
    event.preventDefault();
    
    const title = document.getElementById('adTitle').value.trim();
    const description = document.getElementById('adDescription').value.trim();
    const pageLocation = document.getElementById('adPageLocation').value;
    const position = document.getElementById('adPosition').value;
    const displayOrder = parseInt(document.getElementById('adDisplayOrder').value) || 0;
    const linkType = document.querySelector('input[name="linkType"]:checked').value;
    const linkUrl = document.getElementById('adLinkUrl').value.trim();
    const internalRoute = document.getElementById('adInternalRoute').value.trim();
    const startDate = document.getElementById('adStartDate').value;
    const endDate = document.getElementById('adEndDate').value;
    
    // Validation
    if (!title) {
        showToast('يرجى إدخال عنوان الإعلان', 'error');
        return;
    }
    
    if (!uploadedImageUrl) {
        showToast('يرجى رفع صورة الإعلان', 'error');
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
    
    const adData = {
        title,
        description,
        image_url: uploadedImageUrl,
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
    
    try {
        showToast('جاري الحفظ...', 'info');
        
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

