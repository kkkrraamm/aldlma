// office-registrations.js
const API_URL = 'https://dalma-api.onrender.com';
let currentTab = 'all';
let allRequests = [];

// تحميل الطلبات عند فتح الصفحة
document.addEventListener('DOMContentLoaded', () => {
    loadRequests();
    setInterval(loadRequests, 30000); // تحديث كل 30 ثانية
});

async function loadRequests() {
    try {
        showLoading();
        
        const response = await fetch(`${API_URL}/api/admin/office-registration-requests`);
        const data = await response.json();
        
        if (data.success) {
            allRequests = data.requests;
            updateCounts();
            displayRequests(currentTab);
        }
    } catch (error) {
        console.error('خطأ في تحميل الطلبات:', error);
        showError('فشل تحميل الطلبات');
    }
}

function updateCounts() {
    const pending = allRequests.filter(r => r.status === 'pending').length;
    const approved = allRequests.filter(r => r.status === 'approved').length;
    const rejected = allRequests.filter(r => r.status === 'rejected').length;
    
    document.getElementById('badge-all').textContent = allRequests.length;
    document.getElementById('badge-pending').textContent = pending;
    document.getElementById('badge-approved').textContent = approved;
    document.getElementById('badge-rejected').textContent = rejected;
    
    document.getElementById('pendingCount').textContent = pending;
    document.getElementById('totalCount').textContent = allRequests.length;
}

function switchTab(status) {
    currentTab = status;
    
    // تحديث الأزرار
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    event.target.closest('.tab-btn').classList.add('active');
    
    // تحديث المحتوى
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });
    document.getElementById(`content-${status}`).classList.add('active');
    
    displayRequests(status);
}

function displayRequests(status) {
    const container = document.getElementById(`requests-${status}`);
    
    const filtered = status === 'all' 
        ? allRequests 
        : allRequests.filter(r => r.status === status);
    
    if (filtered.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-inbox"></i>
                <h3>لا توجد طلبات</h3>
                <p>${getEmptyMessage(status)}</p>
            </div>
        `;
        return;
    }
    
    container.innerHTML = filtered.map(request => createRequestCard(request)).join('');
}

function getEmptyMessage(status) {
    const messages = {
        'all': 'لا توجد طلبات تسجيل حتى الآن',
        'pending': 'لا توجد طلبات قيد المراجعة',
        'approved': 'لا توجد طلبات مقبولة',
        'rejected': 'لا توجد طلبات مرفوضة'
    };
    return messages[status] || '';
}

function createRequestCard(request) {
    const statusClass = `status-${request.status}`;
    const statusLabel = getStatusLabel(request.status);
    const planClass = `plan-${request.requested_plan}`;
    const planIcon = getPlanIcon(request.requested_plan);
    const planLabel = request.plan_name || request.requested_plan.toUpperCase();
    const planPrice = request.plan_price || 0;
    
    const createdDate = new Date(request.created_at).toLocaleString('ar-SA', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
    
    return `
        <div class="request-card">
            <div class="request-header">
                <div class="office-info">
                    <h3>
                        <i class="fas fa-building"></i>
                        ${request.office_name}
                    </h3>
                    <div class="office-meta">
                        <div class="meta-item">
                            <i class="fas fa-map-marker-alt"></i>
                            <span>${request.city}</span>
                        </div>
                        <div class="meta-item">
                            <i class="fas fa-phone"></i>
                            <span>${request.phone}</span>
                        </div>
                        ${request.email ? `
                            <div class="meta-item">
                                <i class="fas fa-envelope"></i>
                                <span>${request.email}</span>
                            </div>
                        ` : ''}
                        ${request.license_number ? `
                            <div class="meta-item">
                                <i class="fas fa-certificate"></i>
                                <span>رخصة: ${request.license_number}</span>
                            </div>
                        ` : ''}
                    </div>
                </div>
                <span class="status-badge ${statusClass}">
                    ${getStatusIcon(request.status)} ${statusLabel}
                </span>
            </div>
            
            <div class="plan-section">
                <div class="plan-header">
                    <div class="plan-badge ${planClass}">
                        <i class="${planIcon}"></i>
                        باقة ${planLabel}
                    </div>
                    <div class="plan-price">
                        ${planPrice > 0 ? `${planPrice} ر.س/شهر` : 'مجاناً'}
                    </div>
                </div>
                ${getPlanFeatures(request.requested_plan)}
            </div>
            
            ${request.notes ? `
                <div class="info-box">
                    <div class="info-box-title">📝 ملاحظات المكتب</div>
                    <div class="info-box-content">${request.notes}</div>
                </div>
            ` : ''}
            
            ${request.review_notes ? `
                <div class="info-box" style="border-right-color: ${request.status === 'approved' ? 'var(--success)' : 'var(--danger)'}">
                    <div class="info-box-title">📋 ملاحظات المراجعة</div>
                    <div class="info-box-content">${request.review_notes}</div>
                </div>
            ` : ''}
            
            <div class="request-footer">
                <div class="request-date">
                    <i class="fas fa-clock"></i>
                    ${createdDate}
                </div>
                <div class="request-actions">
                    ${request.status === 'pending' ? `
                        <button class="btn btn-approve" onclick="approveRequest(${request.id}, '${escapeHtml(request.office_name)}')">
                            <i class="fas fa-check"></i>
                            قبول وإنشاء حساب
                        </button>
                        <button class="btn btn-reject" onclick="rejectRequest(${request.id}, '${escapeHtml(request.office_name)}')">
                            <i class="fas fa-times"></i>
                            رفض
                        </button>
                    ` : ''}
                </div>
            </div>
        </div>
    `;
}

function getPlanFeatures(plan) {
    const features = {
        'free': [
            '5 إعلانات مجانية',
            '8 صور لكل إعلان',
            'معاينة طلبات العملاء'
        ],
        'basic': [
            '20 إعلان شهرياً',
            '12 صورة لكل إعلان',
            'طلبات من نفس المدينة',
            'تحليلات أساسية'
        ],
        'pro': [
            '80 إعلان شهرياً',
            '20 صورة لكل إعلان',
            'طلبات من المنطقة كاملة',
            'تحليلات متقدمة'
        ],
        'vip': [
            'إعلانات غير محدودة',
            '30 صورة لكل إعلان',
            'أولوية في الطلبات',
            'خرائط حرارية + تقارير PDF'
        ]
    };
    
    const planFeatures = features[plan] || [];
    return `
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 8px; margin-top: 12px;">
            ${planFeatures.map(f => `
                <div style="display: flex; align-items: center; gap: 6px; font-size: 13px; color: var(--text-secondary);">
                    <i class="fas fa-check" style="color: var(--primary); font-size: 11px;"></i>
                    <span>${f}</span>
                </div>
            `).join('')}
        </div>
    `;
}

function getStatusLabel(status) {
    const labels = {
        'pending': 'قيد المراجعة',
        'approved': 'مقبول',
        'rejected': 'مرفوض'
    };
    return labels[status] || status;
}

function getStatusIcon(status) {
    const icons = {
        'pending': '⏳',
        'approved': '✅',
        'rejected': '❌'
    };
    return icons[status] || '';
}

function getPlanIcon(plan) {
    const icons = {
        'free': 'fas fa-gift',
        'basic': 'fas fa-star',
        'pro': 'fas fa-rocket',
        'vip': 'fas fa-crown'
    };
    return icons[plan] || 'fas fa-building';
}

async function approveRequest(id, officeName) {
    const notes = prompt(`✅ قبول طلب تسجيل: ${officeName}\n\nأدخل ملاحظات للمكتب (اختياري):`);
    if (notes === null) return;
    
    try {
        const response = await fetch(`${API_URL}/api/admin/office-registration/${id}/approve`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ review_notes: notes })
        });
        
        const data = await response.json();
        
        if (data.success) {
            alert(`🎉 تم قبول الطلب وإنشاء المكتب بنجاح!\n\n📊 رقم المكتب: ${data.office_id}\n✉️ سيتم إرسال بيانات الدخول للمكتب قريباً`);
            loadRequests();
        } else {
            alert('❌ خطأ: ' + (data.error || 'حدث خطأ'));
        }
    } catch (error) {
        console.error('خطأ:', error);
        alert('❌ حدث خطأ أثناء قبول الطلب');
    }
}

async function rejectRequest(id, officeName) {
    const notes = prompt(`❌ رفض طلب تسجيل: ${officeName}\n\n⚠️ يرجى إدخال سبب الرفض (مطلوب):`);
    if (!notes || notes.trim() === '') {
        alert('⚠️ يجب إدخال سبب الرفض');
        return;
    }
    
    if (!confirm(`هل أنت متأكد من رفض طلب: ${officeName}؟`)) {
        return;
    }
    
    try {
        const response = await fetch(`${API_URL}/api/admin/office-registration/${id}/reject`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ review_notes: notes })
        });
        
        const data = await response.json();
        
        if (data.success) {
            alert('✅ تم رفض الطلب بنجاح');
            loadRequests();
        } else {
            alert('❌ خطأ: ' + (data.error || 'حدث خطأ'));
        }
    } catch (error) {
        console.error('خطأ:', error);
        alert('❌ حدث خطأ أثناء رفض الطلب');
    }
}

function showLoading() {
    ['all', 'pending', 'approved', 'rejected'].forEach(status => {
        const container = document.getElementById(`requests-${status}`);
        if (container) {
            container.innerHTML = `
                <div class="loading">
                    <i class="fas fa-spinner fa-spin"></i>
                    <p>جاري تحميل الطلبات...</p>
                </div>
            `;
        }
    });
}

function showError(message) {
    ['all', 'pending', 'approved', 'rejected'].forEach(status => {
        const container = document.getElementById(`requests-${status}`);
        if (container) {
            container.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-exclamation-triangle"></i>
                    <h3>${message}</h3>
                    <button class="btn btn-approve" onclick="loadRequests()" style="margin-top: 20px;">
                        <i class="fas fa-redo"></i>
                        إعادة المحاولة
                    </button>
                </div>
            `;
        }
    });
}

function closeModal() {
    document.getElementById('reviewModal').classList.remove('active');
}

function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, m => map[m]);
}
