// office-registrations.js
// API_URL is defined in main.js
let allRequests = [];
let filteredRequests = [];

// تحميل الطلبات عند فتح الصفحة
document.addEventListener('DOMContentLoaded', () => {
    console.log('✅ Office Registrations Page Loaded');
    loadRequests();
    setInterval(loadRequests, 60000); // تحديث كل دقيقة
});

async function loadRequests() {
    try {
        console.log('📥 Loading office registration requests...');
        const response = await fetch(`${API_URL}/api/admin/office-registration-requests`);
        const data = await response.json();
        
        if (data.success) {
            allRequests = data.requests;
            filteredRequests = allRequests;
            console.log(`✅ Loaded ${allRequests.length} requests`);
            updateStats();
            displayRequests();
        } else {
            showError('فشل تحميل البيانات');
        }
    } catch (error) {
        console.error('❌ Error loading requests:', error);
        showError('حدث خطأ في الاتصال بالسيرفر');
    }
}

function updateStats() {
    const pending = allRequests.filter(r => r.status === 'pending').length;
    const approved = allRequests.filter(r => r.status === 'approved').length;
    const rejected = allRequests.filter(r => r.status === 'rejected').length;
    
    document.getElementById('pendingCount').textContent = pending;
    document.getElementById('approvedCount').textContent = approved;
    document.getElementById('rejectedCount').textContent = rejected;
    document.getElementById('totalCount').textContent = allRequests.length;
}

function filterRequests() {
    const search = document.getElementById('searchInput').value.toLowerCase();
    const status = document.getElementById('statusFilter').value;
    const plan = document.getElementById('planFilter').value;
    const city = document.getElementById('cityFilter').value;
    
    filteredRequests = allRequests.filter(request => {
        const matchSearch = request.office_name.toLowerCase().includes(search) ||
                          request.phone.includes(search) ||
                          (request.email && request.email.toLowerCase().includes(search));
        const matchStatus = status === 'all' || request.status === status;
        const matchPlan = plan === 'all' || request.requested_plan === plan;
        const matchCity = city === 'all' || request.city === city;
        
        return matchSearch && matchStatus && matchPlan && matchCity;
    });
    
    displayRequests();
}

function displayRequests() {
    const tbody = document.getElementById('requestsTableBody');
    const count = document.getElementById('requestsCount');
    
    count.textContent = `${filteredRequests.length} طلب`;
    
    if (filteredRequests.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="6" style="text-align: center; padding: 60px;">
                    <i class="fas fa-inbox" style="font-size: 60px; color: var(--text-tertiary); opacity: 0.5;"></i>
                    <p style="margin-top: 20px; color: var(--text-secondary); font-weight: 600;">لا توجد طلبات</p>
                </td>
            </tr>
        `;
        return;
    }
    
    tbody.innerHTML = filteredRequests.map(request => createRequestRow(request)).join('');
}

function createRequestRow(request) {
    const statusBadge = getStatusBadge(request.status);
    const planBadge = getPlanBadge(request.requested_plan);
    const date = new Date(request.created_at).toLocaleDateString('ar-SA');
    const initial = request.office_name.charAt(0);
    
    return `
        <tr>
            <td>
                <div class="office-cell">
                    <div class="office-icon">${initial}</div>
                    <div class="office-info">
                        <div class="office-name">${escapeHtml(request.office_name)}</div>
                        <div class="office-city"><i class="fas fa-map-marker-alt"></i> ${escapeHtml(request.city)}</div>
                    </div>
                </div>
            </td>
            <td><span class="badge ${request.requested_plan}">${planBadge}</span></td>
            <td><span class="badge ${request.status}">${statusBadge}</span></td>
            <td>${escapeHtml(request.phone)}</td>
            <td>${date}</td>
            <td>
                <div class="table-actions-cell">
                    <button class="btn-icon view" onclick="viewRequest(${request.id})" title="عرض التفاصيل">
                        <i class="fas fa-eye"></i>
                    </button>
                    ${request.status === 'pending' ? `
                        <button class="btn-icon approve" onclick="approveRequest(${request.id})" title="قبول">
                            <i class="fas fa-check"></i>
                        </button>
                        <button class="btn-icon reject" onclick="rejectRequest(${request.id})" title="رفض">
                            <i class="fas fa-times"></i>
                        </button>
                    ` : ''}
                </div>
            </td>
        </tr>
    `;
}

function getStatusBadge(status) {
    const badges = {
        'pending': '⏳ قيد المراجعة',
        'approved': '✅ مقبول',
        'rejected': '❌ مرفوض'
    };
    return badges[status] || status;
}

function getPlanBadge(plan) {
    const badges = {
        'free': '🎁 مجاني',
        'basic': '⭐ أساسي',
        'pro': '🚀 احترافي',
        'vip': '👑 VIP'
    };
    return badges[plan] || plan;
}

function viewRequest(id) {
    const request = allRequests.find(r => r.id === id);
    if (!request) return;
    
    const modal = document.getElementById('officeModal');
    const modalBody = document.getElementById('modalBody');
    const modalFooter = document.getElementById('modalFooter');
    
    // حساب معلومات الاشتراك
    let subscriptionHTML = '';
    if (request.status === 'approved' && request.reviewed_at) {
        const approvedDate = new Date(request.reviewed_at);
        const expiryDate = new Date(approvedDate);
        expiryDate.setDate(expiryDate.getDate() + 30);
        
        const daysLeft = Math.ceil((expiryDate - new Date()) / (1000 * 60 * 60 * 24));
        const daysClass = daysLeft < 7 ? 'danger' : daysLeft < 15 ? 'warning' : 'success';
        
        subscriptionHTML = `
            <div class="subscription-info">
                <div class="subscription-header">
                    <h3 style="margin: 0; color: var(--text-primary);">📊 معلومات الاشتراك</h3>
                    <div class="days-left ${daysClass}">${daysLeft} يوم متبقي</div>
                </div>
                <div class="info-grid">
                    <div class="info-item">
                        <div class="info-label">تاريخ البدء</div>
                        <div class="info-value">${approvedDate.toLocaleDateString('ar-SA')}</div>
                    </div>
                    <div class="info-item">
                        <div class="info-label">تاريخ الانتهاء</div>
                        <div class="info-value">${expiryDate.toLocaleDateString('ar-SA')}</div>
                    </div>
                    <div class="info-item">
                        <div class="info-label">حالة الدفع</div>
                        <div class="info-value" style="color: var(--success);">
                            <i class="fas fa-check-circle"></i> مدفوع
                        </div>
                    </div>
                    <div class="info-item">
                        <div class="info-label">المبلغ</div>
                        <div class="info-value">${request.plan_price || 0} ر.س</div>
                    </div>
                </div>
            </div>
        `;
    }
    
    modalBody.innerHTML = `
        <div class="info-grid">
            <div class="info-item">
                <div class="info-label">اسم المكتب</div>
                <div class="info-value">${escapeHtml(request.office_name)}</div>
            </div>
            <div class="info-item">
                <div class="info-label">المدينة</div>
                <div class="info-value">${escapeHtml(request.city)}</div>
            </div>
            <div class="info-item">
                <div class="info-label">رقم الجوال</div>
                <div class="info-value">${escapeHtml(request.phone)}</div>
            </div>
            <div class="info-item">
                <div class="info-label">البريد الإلكتروني</div>
                <div class="info-value">${escapeHtml(request.email || '-')}</div>
            </div>
            <div class="info-item">
                <div class="info-label">رقم الرخصة</div>
                <div class="info-value">${escapeHtml(request.license_number || '-')}</div>
            </div>
            <div class="info-item">
                <div class="info-label">الباقة المطلوبة</div>
                <div class="info-value">${getPlanBadge(request.requested_plan)}</div>
            </div>
            <div class="info-item">
                <div class="info-label">الحالة</div>
                <div class="info-value">${getStatusBadge(request.status)}</div>
            </div>
            <div class="info-item">
                <div class="info-label">تاريخ الطلب</div>
                <div class="info-value">${new Date(request.created_at).toLocaleString('ar-SA')}</div>
            </div>
        </div>
        
        ${request.notes ? `
            <div class="info-item" style="margin-top: 20px;">
                <div class="info-label">📝 ملاحظات المكتب</div>
                <div class="info-value" style="white-space: pre-wrap;">${escapeHtml(request.notes)}</div>
            </div>
        ` : ''}
        
        ${request.review_notes ? `
            <div class="info-item" style="margin-top: 20px;">
                <div class="info-label">📋 ملاحظات المراجعة</div>
                <div class="info-value" style="white-space: pre-wrap;">${escapeHtml(request.review_notes)}</div>
            </div>
        ` : ''}
        
        ${subscriptionHTML}
    `;
    
    if (request.status === 'pending') {
        modalFooter.innerHTML = `
            <button class="btn btn-secondary" onclick="closeModal()">إغلاق</button>
            <button class="btn btn-danger" onclick="rejectRequestFromModal(${request.id})">
                <i class="fas fa-times"></i> رفض
            </button>
            <button class="btn btn-primary" onclick="approveRequestFromModal(${request.id})">
                <i class="fas fa-check"></i> قبول
            </button>
        `;
    } else {
        modalFooter.innerHTML = `
            <button class="btn btn-secondary" onclick="closeModal()">إغلاق</button>
        `;
    }
    
    modal.classList.add('active');
}

async function approveRequest(id) {
    const request = allRequests.find(r => r.id === id);
    if (!confirm(`هل أنت متأكد من قبول طلب: ${request.office_name}؟`)) return;
    
    const notes = prompt('ملاحظات (اختياري):');
    if (notes === null) return;
    
    await processApproval(id, notes);
}

async function approveRequestFromModal(id) {
    const request = allRequests.find(r => r.id === id);
    if (!confirm(`هل أنت متأكد من قبول طلب: ${request.office_name}؟`)) return;
    
    const notes = prompt('ملاحظات (اختياري):');
    if (notes === null) return;
    
    await processApproval(id, notes);
    closeModal();
}

async function processApproval(id, notes) {
    try {
        const response = await fetch(`${API_URL}/api/admin/office-registration/${id}/approve`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ review_notes: notes })
        });
        
        const data = await response.json();
        
        if (data.success) {
            // عرض بيانات الدخول بشكل منسق
            const credentials = `
╔═══════════════════════════════════════════════╗
║         🎉 تم إنشاء المكتب بنجاح!            ║
╠═══════════════════════════════════════════════╣
║                                               ║
║  📊 رقم المكتب: ${data.office_id}                           ║
║                                               ║
║  🔐 بيانات الدخول (احفظها في مكان آمن):     ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                               ║
║  👤 المعرف:                                   ║
║  ${data.username}                             ║
║                                               ║
║  🔑 كلمة المرور:                              ║
║  ${data.password}                             ║
║                                               ║
║  ⚠️ تم نسخ البيانات للحافظة تلقائياً         ║
║                                               ║
╚═══════════════════════════════════════════════╝
            `.trim();
            
            alert(credentials);
            
            // نسخ البيانات للحافظة
            const copyText = `المعرف: ${data.username}\nكلمة المرور: ${data.password}\n\nرابط البوابة: https://office.dalma.sa`;
            navigator.clipboard.writeText(copyText).then(() => {
                console.log('✅ تم نسخ البيانات للحافظة');
            }).catch(err => {
                console.log('⚠️ فشل النسخ:', err);
            });
            
            loadRequests();
        } else {
            alert('❌ خطأ: ' + (data.error || 'حدث خطأ'));
        }
    } catch (error) {
        console.error('❌ Error:', error);
        alert('❌ حدث خطأ أثناء قبول الطلب');
    }
}

async function rejectRequest(id) {
    const request = allRequests.find(r => r.id === id);
    if (!confirm(`هل أنت متأكد من رفض طلب: ${request.office_name}؟`)) return;
    
    const notes = prompt('سبب الرفض (مطلوب):');
    if (!notes || notes.trim() === '') {
        alert('⚠️ يجب إدخال سبب الرفض');
        return;
    }
    
    await processRejection(id, notes);
}

async function rejectRequestFromModal(id) {
    const request = allRequests.find(r => r.id === id);
    if (!confirm(`هل أنت متأكد من رفض طلب: ${request.office_name}؟`)) return;
    
    const notes = prompt('سبب الرفض (مطلوب):');
    if (!notes || notes.trim() === '') {
        alert('⚠️ يجب إدخال سبب الرفض');
        return;
    }
    
    await processRejection(id, notes);
    closeModal();
}

async function processRejection(id, notes) {
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
            alert('❌ خطأ: ' + (data.error || 'حدث خطأ'));
        }
    } catch (error) {
        console.error('❌ Error:', error);
        alert('❌ حدث خطأ أثناء رفض الطلب');
    }
}

function closeModal() {
    document.getElementById('officeModal').classList.remove('active');
}

function exportData() {
    alert('🚧 ميزة التصدير قيد التطوير...');
}

function showError(message) {
    const tbody = document.getElementById('requestsTableBody');
    tbody.innerHTML = `
        <tr>
            <td colspan="6" style="text-align: center; padding: 60px;">
                <i class="fas fa-exclamation-triangle" style="font-size: 60px; color: var(--danger); opacity: 0.5;"></i>
                <p style="margin-top: 20px; color: var(--text-secondary); font-weight: 600;">${message}</p>
                <button class="btn btn-primary" onclick="loadRequests()" style="margin-top: 15px;">
                    <i class="fas fa-redo"></i> إعادة المحاولة
                </button>
            </td>
        </tr>
    `;
}

function escapeHtml(text) {
    if (!text) return '';
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.toString().replace(/[&<>"']/g, m => map[m]);
}

console.log('✅ Office Registrations JS Loaded');
