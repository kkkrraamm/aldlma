// upgrade-requests.js
// API_URL already defined in main.js
let allRequests = [];
let filteredRequests = [];

document.addEventListener('DOMContentLoaded', () => {
    console.log('✅ Upgrade Requests Page Loaded');
    loadRequests();
});

async function loadRequests() {
    try {
        const response = await fetch(`${API_URL}/api/admin/upgrade-requests`, {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('admin_token')}`
            }
        });

        const data = await response.json();

        if (data.success) {
            allRequests = data.requests || [];
            filteredRequests = allRequests;
            updateStats();
            displayRequests();
        } else {
            showError('فشل تحميل الطلبات');
        }
    } catch (error) {
        console.error('❌ Error:', error);
        showError('حدث خطأ في الاتصال');
    }
}

function updateStats() {
    const pending = allRequests.filter(r => r.status === 'pending').length;
    const approved = allRequests.filter(r => r.status === 'approved').length;
    const rejected = allRequests.filter(r => r.status === 'rejected').length;
    
    // حساب الإيرادات المتوقعة من الطلبات المعلقة
    const revenue = allRequests
        .filter(r => r.status === 'pending')
        .reduce((sum, r) => sum + parseFloat(r.plan_price || 0), 0);

    document.getElementById('pendingCount').textContent = pending;
    document.getElementById('approvedCount').textContent = approved;
    document.getElementById('rejectedCount').textContent = rejected;
    document.getElementById('totalRevenue').textContent = revenue.toLocaleString();
}

function filterRequests() {
    const status = document.getElementById('filterStatus').value;
    
    if (status === 'all') {
        filteredRequests = allRequests;
    } else {
        filteredRequests = allRequests.filter(r => r.status === status);
    }
    
    displayRequests();
}

function displayRequests() {
    const container = document.getElementById('requestsContainer');
    
    if (filteredRequests.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-inbox"></i>
                <h3>لا توجد طلبات</h3>
                <p>لا توجد طلبات ترقية حالياً</p>
            </div>
        `;
        return;
    }

    container.innerHTML = `
        <table>
            <thead>
                <tr>
                    <th>المكتب</th>
                    <th>الباقة الحالية</th>
                    <th>الباقة المطلوبة</th>
                    <th>السعر</th>
                    <th>تاريخ الطلب</th>
                    <th>الحالة</th>
                    <th>الإجراءات</th>
                </tr>
            </thead>
            <tbody>
                ${filteredRequests.map(request => createRequestRow(request)).join('')}
            </tbody>
        </table>
    `;
}

function createRequestRow(request) {
    const statusBadge = {
        'pending': '<span class="badge badge-pending"><i class="fas fa-clock"></i> قيد المراجعة</span>',
        'approved': '<span class="badge badge-approved"><i class="fas fa-check"></i> تم الموافقة</span>',
        'rejected': '<span class="badge badge-rejected"><i class="fas fa-times"></i> تم الرفض</span>'
    }[request.status] || '';

    const planClass = {
        'basic': 'plan-basic',
        'pro': 'plan-pro',
        'vip': 'plan-vip'
    };

    return `
        <tr>
            <td>
                <div style="font-weight: 700;">${request.office_name}</div>
                <div style="font-size: 12px; color: var(--text-secondary);">${request.office_city}</div>
            </td>
            <td>
                <span class="plan-badge ${planClass[request.current_plan] || ''}">${getPlanName(request.current_plan)}</span>
            </td>
            <td>
                <span class="plan-badge ${planClass[request.requested_plan]}">${getPlanName(request.requested_plan)}</span>
            </td>
            <td style="font-weight: 700; color: var(--primary);">
                ${parseFloat(request.plan_price).toLocaleString()} ر.س
            </td>
            <td style="font-size: 12px; color: var(--text-secondary);">
                ${formatDate(request.created_at)}
            </td>
            <td>${statusBadge}</td>
            <td>
                ${request.status === 'pending' ? `
                    <div class="action-btns">
                        <button class="btn-small btn-approve" onclick="approveRequest(${request.id}, '${request.office_name}', '${request.requested_plan}')">
                            <i class="fas fa-check"></i>
                            موافقة
                        </button>
                        <button class="btn-small btn-reject" onclick="rejectRequest(${request.id}, '${request.office_name}')">
                            <i class="fas fa-times"></i>
                            رفض
                        </button>
                    </div>
                ` : `
                    <button class="btn-small btn-view" onclick="viewRequest(${request.id})">
                        <i class="fas fa-eye"></i>
                        عرض
                    </button>
                `}
            </td>
        </tr>
    `;
}

async function approveRequest(requestId, officeName, planCode) {
    if (!confirm(`هل تريد الموافقة على ترقية "${officeName}" إلى باقة ${getPlanName(planCode)}؟`)) {
        return;
    }

    try {
        const response = await fetch(`${API_URL}/api/admin/upgrade-requests/${requestId}/approve`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('admin_token')}`
            }
        });

        const data = await response.json();

        if (data.success) {
            alert('✅ تم الموافقة على الطلب بنجاح!\n\nتم ترقية المكتب وتفعيل الباقة الجديدة.');
            loadRequests();
        } else {
            alert('❌ ' + (data.error || 'حدث خطأ'));
        }
    } catch (error) {
        console.error('❌ Error:', error);
        alert('❌ حدث خطأ في الموافقة على الطلب');
    }
}

async function rejectRequest(requestId, officeName) {
    const reason = prompt(`سبب رفض طلب "${officeName}":`);
    if (!reason) return;

    try {
        const response = await fetch(`${API_URL}/api/admin/upgrade-requests/${requestId}/reject`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('admin_token')}`
            },
            body: JSON.stringify({ reason })
        });

        const data = await response.json();

        if (data.success) {
            alert('✅ تم رفض الطلب');
            loadRequests();
        } else {
            alert('❌ ' + (data.error || 'حدث خطأ'));
        }
    } catch (error) {
        console.error('❌ Error:', error);
        alert('❌ حدث خطأ في رفض الطلب');
    }
}

function viewRequest(requestId) {
    const request = allRequests.find(r => r.id === requestId);
    if (!request) return;

    alert(`
📋 تفاصيل الطلب

المكتب: ${request.office_name}
المدينة: ${request.office_city}
الهاتف: ${request.office_phone}

الباقة الحالية: ${getPlanName(request.current_plan)}
الباقة المطلوبة: ${getPlanName(request.requested_plan)}
السعر: ${parseFloat(request.plan_price).toLocaleString()} ر.س

تاريخ الطلب: ${formatDate(request.created_at)}
الحالة: ${getStatusName(request.status)}

${request.notes ? `ملاحظات: ${request.notes}` : ''}
    `);
}

function getPlanName(code) {
    const names = {
        'free': 'مجاني',
        'basic': 'أساسي',
        'pro': 'احترافي',
        'vip': 'VIP'
    };
    return names[code] || code;
}

function getStatusName(status) {
    const names = {
        'pending': 'قيد المراجعة',
        'approved': 'تم الموافقة',
        'rejected': 'تم الرفض'
    };
    return names[status] || status;
}

function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('ar-SA', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

function showError(message) {
    alert('❌ ' + message);
}

console.log('✅ Upgrade Requests JS Loaded');

