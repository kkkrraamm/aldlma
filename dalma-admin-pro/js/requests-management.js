// Requests Management
// API_URL is defined in main.js
let mediaRequests = [];
let providerRequests = [];
let currentTab = 'media';

// Load on page load
window.addEventListener('DOMContentLoaded', () => {
    console.log('📋 [REQUESTS] تهيئة صفحة إدارة الطلبات...');
    
    // Load admin name
    const username = localStorage.getItem('admin_username');
    if (username) {
        const adminNameElement = document.getElementById('adminName');
        if (adminNameElement) {
            adminNameElement.textContent = username;
        }
    }
    
    // Load requests
    loadRequests();
});

// Load all requests
async function loadRequests() {
    await Promise.all([
        loadMediaRequests(),
        loadProviderRequests()
    ]);
}

// Load media requests
async function loadMediaRequests() {
    try {
        console.log('📸 [MEDIA REQUESTS] جلب طلبات الإعلاميين...');
        
        try {
            const data = await apiRequest('/api/admin/media-requests');
            console.log('✅ [MEDIA REQUESTS] تم جلب البيانات:', data);
            mediaRequests = data.requests || [];
        } catch (error) {
            console.warn('⚠️ [MEDIA REQUESTS] فشل جلب البيانات، استخدام بيانات تجريبية:', error);
            mediaRequests = generateMockMediaRequests();
        }
        
        updateMediaStats();
        renderMediaRequests();
        
    } catch (error) {
        console.error('❌ [MEDIA REQUESTS] خطأ:', error);
    }
}

// Load provider requests
async function loadProviderRequests() {
    try {
        console.log('🏪 [PROVIDER REQUESTS] جلب طلبات مقدمي الخدمات...');
        
        try {
            const data = await apiRequest('/api/admin/provider-requests');
            console.log('✅ [PROVIDER REQUESTS] تم جلب البيانات:', data);
            providerRequests = data.requests || [];
        } catch (error) {
            console.warn('⚠️ [PROVIDER REQUESTS] فشل جلب البيانات، استخدام بيانات تجريبية:', error);
            providerRequests = generateMockProviderRequests();
        }
        
        updateProviderStats();
        renderProviderRequests();
        
    } catch (error) {
        console.error('❌ [PROVIDER REQUESTS] خطأ:', error);
    }
}

// Generate mock media requests
function generateMockMediaRequests() {
    const names = ['أحمد العتيبي', 'سارة القحطاني', 'محمد السديري', 'فاطمة الشمري', 'عبدالله الدوسري'];
    const contentTypes = ['أخبار', 'ترفيه', 'رياضة', 'تقنية', 'طبخ'];
    const statuses = ['pending', 'pending', 'pending', 'approved', 'rejected'];
    
    return names.map((name, index) => ({
        id: index + 1,
        user_id: 100 + index,
        name: name,
        email: `media${index + 1}@example.com`,
        phone: `+9665${Math.floor(Math.random() * 90000000 + 10000000)}`,
        bio: 'إعلامي متخصص في إنتاج المحتوى الرقمي مع خبرة تزيد عن 5 سنوات في مجال الإعلام الحديث.',
        content_type: contentTypes[index],
        social_media: `@${name.split(' ')[0].toLowerCase()}`,
        id_image_url: index < 3 ? 'https://via.placeholder.com/400x300?text=ID+Image' : null,
        status: statuses[index],
        created_at: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000).toISOString()
    }));
}

// Generate mock provider requests
function generateMockProviderRequests() {
    const names = ['خالد المطيري', 'نورة العمري', 'سلطان الحربي', 'ريم العنزي'];
    const services = ['مطاعم', 'محلات تجارية', 'خدمات صيانة', 'خدمات تعليمية'];
    const statuses = ['pending', 'pending', 'approved', 'rejected'];
    
    return names.map((name, index) => ({
        id: index + 1,
        user_id: 200 + index,
        name: name,
        email: `provider${index + 1}@example.com`,
        phone: `+9665${Math.floor(Math.random() * 90000000 + 10000000)}`,
        business_name: `${services[index]} ${name.split(' ')[0]}`,
        service_type: services[index],
        location_address: 'عرعر، حي الصناعية',
        has_commercial_license: index < 2,
        license_number: index < 2 ? `CR${Math.floor(Math.random() * 9000000 + 1000000)}` : null,
        license_image_url: index < 2 ? 'https://via.placeholder.com/400x300?text=License' : null,
        status: statuses[index],
        created_at: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000).toISOString()
    }));
}

// Update media stats
function updateMediaStats() {
    const pending = mediaRequests.filter(r => r.status === 'pending').length;
    const approved = mediaRequests.filter(r => r.status === 'approved').length;
    const rejected = mediaRequests.filter(r => r.status === 'rejected').length;
    
    document.getElementById('mediaPending').textContent = pending;
    document.getElementById('mediaApproved').textContent = approved;
    document.getElementById('mediaRejected').textContent = rejected;
    document.getElementById('mediaBadge').textContent = pending;
}

// Update provider stats
function updateProviderStats() {
    const pending = providerRequests.filter(r => r.status === 'pending').length;
    const approved = providerRequests.filter(r => r.status === 'approved').length;
    const rejected = providerRequests.filter(r => r.status === 'rejected').length;
    
    document.getElementById('providersPending').textContent = pending;
    document.getElementById('providersApproved').textContent = approved;
    document.getElementById('providersRejected').textContent = rejected;
    document.getElementById('providersBadge').textContent = pending;
}

// Render media requests
function renderMediaRequests() {
    const container = document.getElementById('mediaRequestsList');
    
    if (mediaRequests.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-inbox"></i>
                <h3>لا توجد طلبات</h3>
                <p>لا توجد طلبات إعلاميين حالياً</p>
            </div>
        `;
        return;
    }
    
    container.innerHTML = mediaRequests.map(request => {
        // Parse experience JSON if it's a string
        let experience = {};
        try {
            experience = typeof request.experience === 'string' ? JSON.parse(request.experience) : request.experience || {};
        } catch (e) {
            console.error('Error parsing experience:', e);
        }
        
        return `
        <div class="request-card">
            <div class="request-avatar">${getInitials(request.user_name)}</div>
            
            <div class="request-info">
                <div class="request-header">
                    <div class="request-name">${request.user_name || 'غير محدد'}</div>
                    <span class="request-status ${request.status}">
                        ${getStatusLabel(request.status)}
                    </span>
                </div>
                
                <div class="request-details">
                    <div class="detail-item">
                        <i class="fas fa-phone"></i>
                        <span>${request.user_phone || 'غير محدد'}</span>
                    </div>
                    <div class="detail-item">
                        <i class="fas fa-video"></i>
                        <span>نوع المحتوى: ${experience.content_type || 'غير محدد'}</span>
                    </div>
                    <div class="detail-item">
                        <i class="fas fa-envelope"></i>
                        <span>${experience.email || 'غير محدد'}</span>
                    </div>
                    <div class="detail-item">
                        <i class="fas fa-link"></i>
                        <span>${request.portfolio_url || 'لا يوجد'}</span>
                    </div>
                    <div class="detail-item">
                        <i class="fas fa-calendar"></i>
                        <span>${formatDate(request.created_at)}</span>
                    </div>
                </div>
                
                ${request.reason ? `
                    <div class="request-bio">
                        <strong>السبب:</strong><br>
                        ${request.reason}
                    </div>
                ` : ''}
                
                ${experience.id_image_url ? `
                    <div class="image-preview">
                        <img src="${experience.id_image_url}" alt="ID" onclick="openImageModal('${experience.id_image_url}')">
                    </div>
                ` : '<p style="color: var(--text-secondary); font-size: 13px;"><i class="fas fa-exclamation-circle"></i> لم يتم رفع صورة الهوية</p>'}
            </div>
            
            <div class="request-actions">
                ${request.status === 'pending' ? `
                    <button class="btn btn-success" onclick="approveMediaRequest(${request.id})">
                        <i class="fas fa-check"></i>
                        قبول
                    </button>
                    <button class="btn btn-danger" onclick="rejectMediaRequest(${request.id})">
                        <i class="fas fa-times"></i>
                        رفض
                    </button>
                ` : `
                    <button class="btn btn-secondary" onclick="viewRequestDetails(${request.id}, 'media')">
                        <i class="fas fa-eye"></i>
                        عرض
                    </button>
                `}
                <button class="btn btn-outline-danger" onclick="deleteMediaRequest(${request.id})" style="margin-right: 8px;">
                    <i class="fas fa-trash"></i>
                    حذف
                </button>
            </div>
        </div>
        `;
    }).join('');
}

// Render provider requests
function renderProviderRequests() {
    const container = document.getElementById('providersRequestsList');
    
    if (providerRequests.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-inbox"></i>
                <h3>لا توجد طلبات</h3>
                <p>لا توجد طلبات مقدمي خدمات حالياً</p>
            </div>
        `;
        return;
    }
    
    container.innerHTML = providerRequests.map(request => {
        // Parse location_address JSON if it's a string
        let locationData = {};
        try {
            locationData = typeof request.location_address === 'string' ? JSON.parse(request.location_address) : request.location_address || {};
        } catch (e) {
            console.error('Error parsing location_address:', e);
        }
        
        return `
        <div class="request-card">
            <div class="request-avatar">${getInitials(request.user_name)}</div>
            
            <div class="request-info">
                <div class="request-header">
                    <div class="request-name">${request.business_name || request.user_name || 'غير محدد'}</div>
                    <span class="request-status ${request.status}">
                        ${getStatusLabel(request.status)}
                    </span>
                </div>
                
                <div class="request-details">
                    <!-- معلومات المالك -->
                    <div class="detail-item">
                        <i class="fas fa-user"></i>
                        <span><strong>👤 المالك:</strong> ${request.user_name || 'غير محدد'}</span>
                    </div>
                    
                    <!-- بيانات الاتصال -->
                    <div class="detail-item">
                        <i class="fas fa-envelope"></i>
                        <span><strong>📧 البريد:</strong> ${request.email || 'غير محدد'}</span>
                    </div>
                    <div class="detail-item">
                        <i class="fas fa-phone"></i>
                        <span><strong>📱 الواتس:</strong> ${request.whatsapp_number || 'غير محدد'}</span>
                    </div>
                    
                    <!-- معلومات العمل -->
                    <div class="detail-item">
                        <i class="fas fa-briefcase"></i>
                        <span><strong>🏢 نوع الخدمة:</strong> ${request.business_category || locationData.category || 'غير محدد'}</span>
                    </div>
                    <div class="detail-item">
                        <i class="fas fa-map-marker-alt"></i>
                        <span><strong>📍 الموقع:</strong> ${request.location_address && typeof request.location_address !== 'string' ? request.location_address : locationData.location || 'غير محدد'}</span>
                    </div>
                    
                    <!-- معلومات الرخصة -->
                    <div class="detail-item">
                        <i class="fas fa-${locationData.has_commercial_license || request.has_commercial_license ? 'check-circle' : 'times-circle'}"></i>
                        <span><strong>📋 الرخصة التجارية:</strong> ${locationData.has_commercial_license || request.has_commercial_license ? '✅ موجودة' : '❌ غير موجودة'}</span>
                    </div>
                    
                    ${locationData.license_number || request.license_number ? `
                        <div class="detail-item">
                            <i class="fas fa-id-card"></i>
                            <span><strong>🔢 رقم الرخصة:</strong> <code>${locationData.license_number || request.license_number}</code></span>
                        </div>
                    ` : ''}
                    
                    <!-- التواريخ -->
                    <div class="detail-item">
                        <i class="fas fa-calendar"></i>
                        <span><strong>📅 تاريخ الطلب:</strong> ${formatDate(request.created_at)}</span>
                    </div>
                    
                    ${request.reviewed_at ? `
                        <div class="detail-item">
                            <i class="fas fa-clock"></i>
                            <span><strong>⏰ تاريخ المراجعة:</strong> ${formatDate(request.reviewed_at)}</span>
                        </div>
                    ` : ''}
                    
                    <!-- ملاحظات الادمن -->
                    ${request.admin_notes ? `
                        <div class="detail-item">
                            <i class="fas fa-sticky-note"></i>
                            <span><strong>📝 ملاحظات الإدارة:</strong> ${request.admin_notes}</span>
                        </div>
                    ` : ''}
                    
                    <!-- سبب الرفض -->
                    ${request.rejected_reason ? `
                        <div class="detail-item">
                            <i class="fas fa-ban"></i>
                            <span><strong>❌ سبب الرفض:</strong> ${request.rejected_reason}</span>
                        </div>
                    ` : ''}
                </div>
                
                ${locationData.description ? `
                    <div class="request-bio">
                        <strong>📝 وصف العمل والخدمات:</strong><br>
                        ${locationData.description}
                    </div>
                ` : ''}
                
                ${locationData.license_image_url ? `
                    <div class="image-preview">
                        <strong style="display: block; margin-bottom: 10px;">📄 صورة الرخصة:</strong>
                        <img src="${locationData.license_image_url}" alt="License" onclick="openImageModal('${locationData.license_image_url}')">
                    </div>
                ` : '<p style="color: var(--text-secondary); font-size: 13px;"><i class="fas fa-exclamation-circle"></i> لم يتم رفع صورة الرخصة</p>'}
            </div>
            
            <div class="request-actions">
                ${request.status === 'pending' ? `
                    <button class="btn btn-success" onclick="approveProviderRequest(${request.id})">
                        <i class="fas fa-check"></i>
                        قبول
                    </button>
                    <button class="btn btn-danger" onclick="rejectProviderRequest(${request.id})">
                        <i class="fas fa-times"></i>
                        رفض
                    </button>
                ` : `
                    <button class="btn btn-secondary" onclick="viewRequestDetails(${request.id}, 'provider')">
                        <i class="fas fa-eye"></i>
                        عرض
                    </button>
                `}
                <button class="btn btn-outline-danger" onclick="deleteProviderRequest(${request.id})" style="margin-right: 8px;">
                    <i class="fas fa-trash"></i>
                    حذف
                </button>
            </div>
        </div>
        `;
    }).join('');
}

// Switch tab
function switchTab(tab) {
    currentTab = tab;
    
    // Update tab buttons
    document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
    document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));
    
    if (tab === 'media') {
        document.querySelector('.tab-btn:nth-child(1)').classList.add('active');
        document.getElementById('mediaTab').classList.add('active');
    } else {
        document.querySelector('.tab-btn:nth-child(2)').classList.add('active');
        document.getElementById('providersTab').classList.add('active');
    }
}

// Approve media request
async function approveMediaRequest(requestId) {
    if (!confirm('هل أنت متأكد من قبول هذا الطلب؟')) return;
    
    try {
        console.log('✅ [APPROVE] قبول طلب إعلامي:', requestId);
        
        // ✅ Call Backend API
        await apiRequest('/api/admin/media-requests/approve', {
            method: 'POST',
            body: JSON.stringify({ requestId })
        });
        
        showToast('تم قبول الطلب وإشعار المستخدم بنجاح!', 'success');
        
        // Reload requests from server
        loadMediaRequests();
        
    } catch (error) {
        console.error('❌ [APPROVE] خطأ:', error);
        showToast('فشل قبول الطلب', 'error');
    }
}

// Reject media request
async function rejectMediaRequest(requestId) {
    const reason = prompt('يرجى إدخال سبب الرفض:');
    if (!reason) return;
    
    try {
        console.log('❌ [REJECT] رفض طلب إعلامي:', requestId, 'السبب:', reason);
        
        await apiRequest('/api/admin/media-requests/reject', {
            method: 'POST',
            body: JSON.stringify({ requestId, reason })
        });
        
        showToast('تم رفض الطلب وإشعار المستخدم', 'success');
        loadMediaRequests();
        
    } catch (error) {
        console.error('❌ [REJECT] خطأ:', error);
        showToast('فشل رفض الطلب', 'error');
    }
}

// Delete media request
async function deleteMediaRequest(requestId) {
    if (!confirm('هل أنت متأكد من حذف هذا الطلب؟\n\nسيتمكن المستخدم من تقديم طلب جديد.')) {
        return;
    }
    
    try {
        console.log('🗑️ [DELETE] حذف طلب إعلامي:', requestId);
        
        await apiRequest('/api/admin/media-requests/delete', {
            method: 'POST',
            body: JSON.stringify({ requestId })
        });
        
        showToast('تم حذف الطلب بنجاح', 'success');
        loadMediaRequests();
        
    } catch (error) {
        console.error('❌ [DELETE] خطأ:', error);
        showToast('فشل حذف الطلب', 'error');
    }
}

// Approve provider request
async function approveProviderRequest(requestId) {
    if (!confirm('هل أنت متأكد من قبول هذا الطلب؟')) return;
    
    try {
        console.log('✅ [APPROVE] قبول طلب مقدم خدمة:', requestId);
        
        // ✅ Call Backend API
        await apiRequest('/api/admin/provider-requests/approve', {
            method: 'POST',
            body: JSON.stringify({ requestId })
        });
        
        showToast('تم قبول الطلب وإشعار المستخدم بنجاح!', 'success');
        
        // Reload requests from server
        loadProviderRequests();
        
    } catch (error) {
        console.error('❌ [APPROVE] خطأ:', error);
        showToast('فشل قبول الطلب', 'error');
    }
}

// Reject provider request
async function rejectProviderRequest(requestId) {
    const reason = prompt('يرجى إدخال سبب الرفض:');
    if (!reason) return;
    
    try {
        console.log('❌ [REJECT] رفض طلب مقدم خدمة:', requestId, 'السبب:', reason);
        
        await apiRequest('/api/admin/provider-requests/reject', {
            method: 'POST',
            body: JSON.stringify({ requestId, reason })
        });
        
        showToast('تم رفض الطلب وإشعار المستخدم', 'success');
        loadProviderRequests();
        
    } catch (error) {
        console.error('❌ [REJECT] خطأ:', error);
        showToast('فشل رفض الطلب', 'error');
    }
}

// Delete provider request
async function deleteProviderRequest(requestId) {
    if (!confirm('هل أنت متأكد من حذف هذا الطلب؟\n\nسيتمكن المستخدم من تقديم طلب جديد.')) {
        return;
    }
    
    try {
        console.log('🗑️ [DELETE] حذف طلب مقدم خدمة:', requestId);
        
        await apiRequest('/api/admin/provider-requests/delete', {
            method: 'POST',
            body: JSON.stringify({ requestId })
        });
        
        showToast('تم حذف الطلب بنجاح', 'success');
        loadProviderRequests();
        
    } catch (error) {
        console.error('❌ [DELETE] خطأ:', error);
        showToast('فشل حذف الطلب', 'error');
    }
}

// View request details
function viewRequestDetails(requestId, type) {
    showToast('عرض تفاصيل الطلب...', 'info');
    console.log('View request:', requestId, type);
}

// Refresh requests
async function refreshRequests() {
    showToast('جاري تحديث البيانات...', 'info');
    await loadRequests();
    showToast('تم التحديث بنجاح', 'success');
}

// Image modal functions
function openImageModal(imageUrl) {
    const modal = document.getElementById('imageModal');
    const img = document.getElementById('modalImage');
    img.src = imageUrl;
    modal.classList.add('active');
}

function closeImageModal() {
    const modal = document.getElementById('imageModal');
    modal.classList.remove('active');
}

// Helper functions
function getInitials(name) {
    if (!name) return '؟؟';
    return name.split(' ').map(n => n[0]).join('').toUpperCase().substring(0, 2);
}

function getStatusLabel(status) {
    const labels = {
        pending: 'قيد المراجعة',
        approved: 'مقبول',
        rejected: 'مرفوض'
    };
    return labels[status] || status;
}

function formatDate(dateString) {
    if (!dateString) return 'غير متوفر';
    const date = new Date(dateString);
    return date.toLocaleDateString('ar-SA', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });
}

function showToast(message, type = 'info') {
    console.log(`[${type.toUpperCase()}] ${message}`);
}

// API Helper
async function apiRequest(endpoint, options = {}) {
    const token = localStorage.getItem('admin_token');
    const apiKey = localStorage.getItem('admin_apiKey');
    
    const headers = {
        'Content-Type': 'application/json',
        'X-API-Key': apiKey,
        ...options.headers
    };
    
    if (token) {
        headers['Authorization'] = `Bearer ${token}`;
    }
    
    const response = await fetch(`${API_URL}${endpoint}`, {
        ...options,
        headers
    });
    
    if (!response.ok) {
        if (response.status === 401 || response.status === 403) {
            localStorage.removeItem('admin_token');
            localStorage.removeItem('admin_username');
            localStorage.removeItem('admin_apiKey');
            window.location.href = 'login.html';
        }
        throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    return await response.json();
}

