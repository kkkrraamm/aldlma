// office-registrations.js
const API_URL = 'https://dalma-api.onrender.com';
let currentFilter = 'all';
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
            displayRequests(currentFilter);
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
    
    document.getElementById('count-all').textContent = allRequests.length;
    document.getElementById('count-pending').textContent = pending;
    document.getElementById('count-approved').textContent = approved;
    document.getElementById('count-rejected').textContent = rejected;
    document.getElementById('pendingCount').textContent = `${pending} طلب جديد`;
}

function filterRequests(status) {
    currentFilter = status;
    
    // تحديث الأزرار
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    event.target.closest('.filter-btn').classList.add('active');
    
    displayRequests(status);
}

function displayRequests(status) {
    const container = document.getElementById('requestsContainer');
    
    const filtered = status === 'all' 
        ? allRequests 
        : allRequests.filter(r => r.status === status);
    
    if (filtered.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-inbox"></i>
                <h3>لا توجد طلبات</h3>
                <p>لا توجد طلبات تسجيل ${getStatusLabel(status)}</p>
            </div>
        `;
        return;
    }
    
    container.innerHTML = filtered.map(request => createRequestCard(request)).join('');
}

function createRequestCard(request) {
    const statusClass = `status-${request.status}`;
    const statusLabel = getStatusLabel(request.status);
    const planClass = `plan-${request.requested_plan}`;
    const planIcon = getPlanIcon(request.requested_plan);
    const planLabel = request.plan_name || request.requested_plan;
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
                    <h3><i class="fas fa-building"></i> ${request.office_name}</h3>
                    <div class="office-meta">
                        <span><i class="fas fa-map-marker-alt"></i> ${request.city}</span>
                        <span><i class="fas fa-phone"></i> ${request.phone}</span>
                        ${request.email ? `<span><i class="fas fa-envelope"></i> ${request.email}</span>` : ''}
                        ${request.license_number ? `<span><i class="fas fa-certificate"></i> ${request.license_number}</span>` : ''}
                    </div>
                    <div class="plan-badge ${planClass}">
                        <i class="${planIcon}"></i>
                        ${planLabel} ${planPrice > 0 ? `(${planPrice} ر.س/شهر)` : '(مجاني)'}
                    </div>
                </div>
                <span class="status-badge ${statusClass}">${statusLabel}</span>
            </div>
            
            ${request.notes ? `
                <div style="margin-top: 16px; padding: 12px; background: #f8fafc; border-radius: 10px;">
                    <strong style="color: #64748b; font-size: 13px;">📝 ملاحظات:</strong>
                    <p style="margin: 8px 0 0; color: #1a1f2e;">${request.notes}</p>
                </div>
            ` : ''}
            
            <div style="margin-top: 12px; font-size: 13px; color: #94a3b8;">
                <i class="fas fa-clock"></i> تاريخ الطلب: ${createdDate}
            </div>
            
            ${request.status === 'pending' ? `
                <div class="request-actions">
                    <button class="btn btn-approve" onclick="approveRequest(${request.id}, '${request.office_name}')">
                        <i class="fas fa-check"></i> قبول وإنشاء حساب
                    </button>
                    <button class="btn btn-reject" onclick="rejectRequest(${request.id}, '${request.office_name}')">
                        <i class="fas fa-times"></i> رفض
                    </button>
                </div>
            ` : request.review_notes ? `
                <div style="margin-top: 16px; padding: 12px; background: ${request.status === 'approved' ? '#f0fdf4' : '#fef2f2'}; border-radius: 10px;">
                    <strong style="color: #64748b; font-size: 13px;">📋 ملاحظات المراجعة:</strong>
                    <p style="margin: 8px 0 0; color: #1a1f2e;">${request.review_notes}</p>
                </div>
            ` : ''}
        </div>
    `;
}

function getStatusLabel(status) {
    const labels = {
        'all': 'جميع الطلبات',
        'pending': 'قيد المراجعة',
        'approved': 'مقبول',
        'rejected': 'مرفوض'
    };
    return labels[status] || status;
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
    const notes = prompt(`قبول طلب تسجيل: ${officeName}\n\nأدخل ملاحظات (اختياري):`);
    if (notes === null) return;
    
    try {
        const response = await fetch(`${API_URL}/api/admin/office-registration/${id}/approve`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ review_notes: notes })
        });
        
        const data = await response.json();
        
        if (data.success) {
            alert(`✅ تم قبول الطلب وإنشاء المكتب بنجاح!\nرقم المكتب: ${data.office_id}`);
            loadRequests();
        } else {
            alert('❌ ' + (data.error || 'حدث خطأ'));
        }
    } catch (error) {
        console.error('خطأ:', error);
        alert('❌ حدث خطأ أثناء قبول الطلب');
    }
}

async function rejectRequest(id, officeName) {
    const notes = prompt(`رفض طلب تسجيل: ${officeName}\n\nأدخل سبب الرفض:`);
    if (!notes) {
        alert('⚠️ يجب إدخال سبب الرفض');
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
            alert('✅ تم رفض الطلب');
            loadRequests();
        } else {
            alert('❌ ' + (data.error || 'حدث خطأ'));
        }
    } catch (error) {
        console.error('خطأ:', error);
        alert('❌ حدث خطأ أثناء رفض الطلب');
    }
}

function showLoading() {
    document.getElementById('requestsContainer').innerHTML = `
        <div class="loading">
            <i class="fas fa-spinner fa-spin" style="font-size: 32px; color: #10b981;"></i>
            <p style="margin-top: 16px;">جاري التحميل...</p>
        </div>
    `;
}

function showError(message) {
    document.getElementById('requestsContainer').innerHTML = `
        <div class="empty-state">
            <i class="fas fa-exclamation-triangle"></i>
            <h3>${message}</h3>
            <button class="btn btn-approve" onclick="loadRequests()" style="max-width: 200px; margin: 16px auto;">
                إعادة المحاولة
            </button>
        </div>
    `;
}

function closeModal() {
    document.getElementById('reviewModal').classList.remove('active');
}

