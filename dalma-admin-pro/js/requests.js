// Requests Management - Media & Providers

// Media Requests Page
async function loadMediaRequestsPage() {
    try {
        const requests = await fetchMediaRequests();
        
        return `
            <div class="requests-page">
                <div class="page-header">
                    <h1 class="page-title">
                        <i class="fas fa-film"></i>
                        طلبات تحويل إلى إعلامي
                    </h1>
                    <div class="page-actions">
                        <button class="btn btn-secondary" onclick="filterRequests('all')">
                            <i class="fas fa-list"></i> الكل (${requests.length})
                        </button>
                        <button class="btn btn-primary" onclick="filterRequests('pending')">
                            <i class="fas fa-clock"></i> قيد المراجعة (${requests.filter(r => r.status === 'pending').length})
                        </button>
                    </div>
                </div>

                <div class="requests-grid">
                    ${requests.map(request => renderMediaRequestCard(request)).join('')}
                </div>
            </div>
        `;
    } catch (error) {
        console.error('Error loading media requests:', error);
        return '<div class="error">فشل تحميل الطلبات</div>';
    }
}

function renderMediaRequestCard(request) {
    const statusColors = {
        pending: 'warning',
        approved: 'success',
        rejected: 'danger'
    };
    
    const statusTexts = {
        pending: 'قيد المراجعة',
        approved: 'تمت الموافقة',
        rejected: 'مرفوض'
    };
    
    const experience = typeof request.experience === 'string' 
        ? JSON.parse(request.experience || '{}') 
        : request.experience || {};
    
    return `
        <div class="card request-card" data-status="${request.status}">
            <div class="request-header">
                <div class="user-info">
                    <div class="user-avatar">
                        ${request.user_name ? request.user_name[0] : 'U'}
                    </div>
                    <div>
                        <h3>${request.user_name || 'مستخدم'}</h3>
                        <span class="text-secondary">ID: ${request.user_id}</span>
                    </div>
                </div>
                <span class="badge badge-${statusColors[request.status]}">
                    ${statusTexts[request.status]}
                </span>
            </div>

            <div class="request-details">
                <div class="detail-item">
                    <i class="fas fa-user"></i>
                    <div>
                        <span class="label">نبذة عنه</span>
                        <p>${request.reason || 'لا توجد نبذة'}</p>
                    </div>
                </div>

                <div class="detail-item">
                    <i class="fas fa-link"></i>
                    <div>
                        <span class="label">حسابات التواصل</span>
                        <p>${request.portfolio_url || 'لا يوجد'}</p>
                    </div>
                </div>

                <div class="detail-item">
                    <i class="fas fa-video"></i>
                    <div>
                        <span class="label">نوع المحتوى</span>
                        <p>${experience.content_type || 'غير محدد'}</p>
                    </div>
                </div>

                <div class="detail-item">
                    <i class="fas fa-phone"></i>
                    <div>
                        <span class="label">واتساب</span>
                        <p>${experience.whatsapp || 'غير متوفر'}</p>
                    </div>
                </div>

                <div class="detail-item">
                    <i class="fas fa-envelope"></i>
                    <div>
                        <span class="label">البريد الإلكتروني</span>
                        <p>${experience.email || 'غير متوفر'}</p>
                    </div>
                </div>

                ${experience.wants_verification ? `
                <div class="detail-item">
                    <i class="fas fa-id-card"></i>
                    <div>
                        <span class="label">صورة الهوية</span>
                        ${experience.id_image_url ? `
                            <a href="${experience.id_image_url}" target="_blank" class="view-image-btn">
                                <i class="fas fa-external-link-alt"></i>
                                عرض الصورة
                            </a>
                        ` : '<p>لم يتم رفع صورة</p>'}
                    </div>
                </div>
                ` : ''}

                <div class="detail-item">
                    <i class="fas fa-calendar"></i>
                    <div>
                        <span class="label">تاريخ التقديم</span>
                        <p>${formatDate(request.created_at)}</p>
                    </div>
                </div>

                ${request.admin_notes ? `
                <div class="detail-item">
                    <i class="fas fa-sticky-note"></i>
                    <div>
                        <span class="label">ملاحظات المدير</span>
                        <p>${request.admin_notes}</p>
                    </div>
                </div>
                ` : ''}
            </div>

            ${request.status === 'pending' ? `
            <div class="request-actions">
                <button class="btn btn-success" onclick="handleMediaRequest(${request.id}, 'approve')">
                    <i class="fas fa-check"></i>
                    قبول
                </button>
                <button class="btn btn-danger" onclick="handleMediaRequest(${request.id}, 'reject')">
                    <i class="fas fa-times"></i>
                    رفض
                </button>
            </div>
            ` : ''}
        </div>
    `;
}

// Provider Requests Page
async function loadProviderRequestsPage() {
    try {
        const requests = await fetchProviderRequests();
        
        return `
            <div class="requests-page">
                <div class="page-header">
                    <h1 class="page-title">
                        <i class="fas fa-briefcase"></i>
                        طلبات تحويل إلى مقدم خدمة
                    </h1>
                    <div class="page-actions">
                        <button class="btn btn-secondary" onclick="filterProviderRequests('all')">
                            <i class="fas fa-list"></i> الكل (${requests.length})
                        </button>
                        <button class="btn btn-primary" onclick="filterProviderRequests('pending')">
                            <i class="fas fa-clock"></i> قيد المراجعة (${requests.filter(r => r.status === 'pending').length})
                        </button>
                    </div>
                </div>

                <div class="requests-grid">
                    ${requests.map(request => renderProviderRequestCard(request)).join('')}
                </div>
            </div>
        `;
    } catch (error) {
        console.error('Error loading provider requests:', error);
        return '<div class="error">فشل تحميل الطلبات</div>';
    }
}

function renderProviderRequestCard(request) {
    const statusColors = {
        pending: 'warning',
        approved: 'success',
        rejected: 'danger'
    };
    
    const statusTexts = {
        pending: 'قيد المراجعة',
        approved: 'تمت الموافقة',
        rejected: 'مرفوض'
    };
    
    const extraData = typeof request.location_address === 'string' 
        ? JSON.parse(request.location_address || '{}') 
        : request.location_address || {};
    
    return `
        <div class="card request-card" data-status="${request.status}">
            <div class="request-header">
                <div class="user-info">
                    <div class="user-avatar">
                        ${request.user_name ? request.user_name[0] : 'U'}
                    </div>
                    <div>
                        <h3>${request.user_name || 'مستخدم'}</h3>
                        <span class="text-secondary">ID: ${request.user_id}</span>
                    </div>
                </div>
                <span class="badge badge-${statusColors[request.status]}">
                    ${statusTexts[request.status]}
                </span>
            </div>

            <div class="request-details">
                <div class="detail-item">
                    <i class="fas fa-store"></i>
                    <div>
                        <span class="label">اسم النشاط التجاري</span>
                        <p><strong>${request.business_name || 'غير محدد'}</strong></p>
                    </div>
                </div>

                <div class="detail-item">
                    <i class="fas fa-tags"></i>
                    <div>
                        <span class="label">الفئة</span>
                        <p>${request.business_category || 'غير محددة'}</p>
                    </div>
                </div>

                <div class="detail-item">
                    <i class="fas fa-align-right"></i>
                    <div>
                        <span class="label">الوصف</span>
                        <p>${extraData.description || 'لا يوجد وصف'}</p>
                    </div>
                </div>

                <div class="detail-item">
                    <i class="fas fa-map-marker-alt"></i>
                    <div>
                        <span class="label">الموقع</span>
                        <p>${extraData.location || 'غير محدد'}</p>
                    </div>
                </div>

                <div class="detail-item">
                    <i class="fas fa-phone"></i>
                    <div>
                        <span class="label">واتساب</span>
                        <p>${request.whatsapp_number || 'غير متوفر'}</p>
                    </div>
                </div>

                <div class="detail-item">
                    <i class="fas fa-envelope"></i>
                    <div>
                        <span class="label">البريد الإلكتروني</span>
                        <p>${request.email || 'غير متوفر'}</p>
                    </div>
                </div>

                <div class="detail-item">
                    <i class="fas fa-certificate"></i>
                    <div>
                        <span class="label">سجل تجاري</span>
                        <p>${extraData.has_commercial_license ? 'نعم' : 'لا'}</p>
                    </div>
                </div>

                ${extraData.has_commercial_license && extraData.license_number ? `
                <div class="detail-item">
                    <i class="fas fa-hashtag"></i>
                    <div>
                        <span class="label">رقم السجل</span>
                        <p>${extraData.license_number}</p>
                    </div>
                </div>
                ` : ''}

                ${extraData.license_image_url ? `
                <div class="detail-item">
                    <i class="fas fa-file-image"></i>
                    <div>
                        <span class="label">صورة السجل التجاري</span>
                        <a href="${extraData.license_image_url}" target="_blank" class="view-image-btn">
                            <i class="fas fa-external-link-alt"></i>
                            عرض الصورة
                        </a>
                    </div>
                </div>
                ` : ''}

                <div class="detail-item">
                    <i class="fas fa-calendar"></i>
                    <div>
                        <span class="label">تاريخ التقديم</span>
                        <p>${formatDate(request.created_at)}</p>
                    </div>
                </div>

                ${request.admin_notes ? `
                <div class="detail-item">
                    <i class="fas fa-sticky-note"></i>
                    <div>
                        <span class="label">ملاحظات المدير</span>
                        <p>${request.admin_notes}</p>
                    </div>
                </div>
                ` : ''}
            </div>

            ${request.status === 'pending' ? `
            <div class="request-actions">
                <button class="btn btn-success" onclick="handleProviderRequest(${request.id}, 'approve')">
                    <i class="fas fa-check"></i>
                    قبول
                </button>
                <button class="btn btn-danger" onclick="handleProviderRequest(${request.id}, 'reject')">
                    <i class="fas fa-times"></i>
                    رفض
                </button>
            </div>
            ` : ''}
        </div>
    `;
}

// Fetch Functions
async function fetchMediaRequests() {
    try {
        const response = await apiRequest('/api/admin/media-requests');
        return response.requests || [];
    } catch (error) {
        console.error('Error fetching media requests:', error);
        // Return mock data for development
        return [
            {
                id: 17,
                user_id: 44,
                user_name: 'سلطان القحطاني',
                reason: 'أنا جميل جدا لدرجة الجنون',
                portfolio_url: 'Kim\'s',
                experience: JSON.stringify({
                    content_type: 'سفر وسياحة',
                    whatsapp: '0550775255',
                    email: 'sjfdggf@gmail.com',
                    wants_verification: true,
                    id_image_url: null
                }),
                status: 'pending',
                created_at: '2025-10-21T20:31:10.091Z'
            }
        ];
    }
}

async function fetchProviderRequests() {
    try {
        const response = await apiRequest('/api/admin/provider-requests');
        return response.requests || [];
    } catch (error) {
        console.error('Error fetching provider requests:', error);
        return [];
    }
}

// Handle Request Actions
async function handleMediaRequest(requestId, action) {
    const notes = action === 'reject' ? prompt('سبب الرفض (اختياري):') : null;
    if (action === 'reject' && notes === null) return;
    
    try {
        await apiRequest(`/api/admin/media-request/${requestId}/${action}`, {
            method: 'PUT',
            body: JSON.stringify({ admin_notes: notes })
        });
        
        showToast(`تم ${action === 'approve' ? 'قبول' : 'رفض'} الطلب بنجاح`, 'success');
        await loadPage('requests-media');
    } catch (error) {
        console.error('Error handling request:', error);
        showToast('حدث خطأ في معالجة الطلب', 'error');
    }
}

async function handleProviderRequest(requestId, action) {
    const notes = action === 'reject' ? prompt('سبب الرفض (اختياري):') : null;
    if (action === 'reject' && notes === null) return;
    
    try {
        await apiRequest(`/api/admin/provider-request/${requestId}/${action}`, {
            method: 'PUT',
            body: JSON.stringify({ admin_notes: notes })
        });
        
        showToast(`تم ${action === 'approve' ? 'قبول' : 'رفض'} الطلب بنجاح`, 'success');
        await loadPage('requests-providers');
    } catch (error) {
        console.error('Error handling request:', error);
        showToast('حدث خطأ في معالجة الطلب', 'error');
    }
}

// Filter Functions
function filterRequests(status) {
    const cards = document.querySelectorAll('.request-card');
    cards.forEach(card => {
        if (status === 'all' || card.dataset.status === status) {
            card.style.display = 'block';
        } else {
            card.style.display = 'none';
        }
    });
}

function filterProviderRequests(status) {
    filterRequests(status);
}


