// offices-management.js
// API_URL is defined in main.js
let allOffices = [];

document.addEventListener('DOMContentLoaded', () => {
    console.log('✅ Offices Management Page Loaded');
    loadOffices();
});

async function loadOffices() {
    try {
        showLoading();
        
        const response = await fetch(`${API_URL}/api/admin/offices`);
        const data = await response.json();
        
        if (data.success) {
            allOffices = data.offices;
            updateStats();
            displayOffices();
        }
    } catch (error) {
        console.error('❌ Error:', error);
        showError();
    }
}

function updateStats() {
    const active = allOffices.filter(o => o.status === 'active').length;
    const suspended = allOffices.filter(o => o.status === 'suspended').length;
    const blocked = allOffices.filter(o => o.status === 'blocked').length;
    
    document.getElementById('activeOffices').textContent = active;
    document.getElementById('suspendedOffices').textContent = suspended;
    document.getElementById('blockedOffices').textContent = blocked;
    document.getElementById('totalOffices').textContent = allOffices.length;
}

function displayOffices() {
    const tbody = document.getElementById('officesTableBody');
    const count = document.getElementById('officesCount');
    
    count.textContent = `${allOffices.length} مكتب`;
    
    if (allOffices.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="6" style="text-align: center; padding: 60px;">
                    <i class="fas fa-inbox" style="font-size: 60px; color: var(--text-tertiary); opacity: 0.5;"></i>
                    <p style="margin-top: 20px; color: var(--text-secondary);">لا توجد مكاتب</p>
                </td>
            </tr>
        `;
        return;
    }
    
    tbody.innerHTML = allOffices.map(office => createOfficeRow(office)).join('');
}

function createOfficeRow(office) {
    const initial = office.name.charAt(0);
    const statusBadge = getStatusBadge(office.status);
    const planBadge = getPlanBadge(office.plan_code);
    const daysLeft = getDaysLeft(office.subscription_end);
    const lastLogin = office.last_login ? new Date(office.last_login).toLocaleDateString('ar-SA') : '-';
    
    return `
        <tr style="border-bottom: 1px solid var(--border);">
            <td style="padding: 18px 20px;">
                <div style="display: flex; align-items: center; gap: 12px;">
                    <div style="width: 45px; height: 45px; border-radius: 10px; background: linear-gradient(135deg, #10b981, #059669); display: flex; align-items: center; justify-content: center; color: white; font-weight: 700; font-size: 18px;">
                        ${initial}
                    </div>
                    <div>
                        <div style="font-weight: 700; color: var(--text-primary);">${escapeHtml(office.name)}</div>
                        <div style="font-size: 12px; color: var(--text-secondary);">
                            <i class="fas fa-map-marker-alt"></i> ${escapeHtml(office.city)}
                        </div>
                    </div>
                </div>
            </td>
            <td style="padding: 18px 20px;">
                <span style="padding: 6px 12px; border-radius: 20px; font-size: 11px; font-weight: 700; ${getPlanStyle(office.plan_code)}">
                    ${planBadge}
                </span>
            </td>
            <td style="padding: 18px 20px;">${statusBadge}</td>
            <td style="padding: 18px 20px;">${daysLeft}</td>
            <td style="padding: 18px 20px; color: var(--text-secondary);">${lastLogin}</td>
            <td style="padding: 18px 20px;">
                <div style="display: flex; gap: 8px;">
                    <button class="btn-icon view" onclick="viewOffice(${office.id})" title="عرض" style="width: 35px; height: 35px; border: none; border-radius: 8px; background: var(--bg-tertiary); cursor: pointer;">
                        <i class="fas fa-eye"></i>
                    </button>
                    ${office.status === 'active' ? `
                        <button class="btn-icon" onclick="suspendOffice(${office.id}, '${escapeHtml(office.name)}')" title="تعليق" style="width: 35px; height: 35px; border: none; border-radius: 8px; background: var(--bg-tertiary); cursor: pointer;">
                            <i class="fas fa-pause"></i>
                        </button>
                    ` : office.status === 'suspended' ? `
                        <button class="btn-icon" onclick="activateOffice(${office.id}, '${escapeHtml(office.name)}')" title="تفعيل" style="width: 35px; height: 35px; border: none; border-radius: 8px; background: var(--bg-tertiary); cursor: pointer;">
                            <i class="fas fa-play"></i>
                        </button>
                    ` : ''}
                    <button class="btn-icon" onclick="renewSubscription(${office.id}, '${escapeHtml(office.name)}')" title="تجديد" style="width: 35px; height: 35px; border: none; border-radius: 8px; background: var(--bg-tertiary); cursor: pointer;">
                        <i class="fas fa-redo"></i>
                    </button>
                </div>
            </td>
        </tr>
    `;
}

function getStatusBadge(status) {
    const badges = {
        'active': '<span style="padding: 6px 12px; border-radius: 20px; font-size: 11px; font-weight: 700; background: #d1fae5; color: #065f46;">✅ نشط</span>',
        'suspended': '<span style="padding: 6px 12px; border-radius: 20px; font-size: 11px; font-weight: 700; background: #fef3c7; color: #92400e;">⏸️ معلق</span>',
        'blocked': '<span style="padding: 6px 12px; border-radius: 20px; font-size: 11px; font-weight: 700; background: #fee2e2; color: #991b1b;">🚫 محظور</span>',
        'pending': '<span style="padding: 6px 12px; border-radius: 20px; font-size: 11px; font-weight: 700; background: #e5e7eb; color: #374151;">⏳ معلق</span>'
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

function getPlanStyle(plan) {
    const styles = {
        'free': 'background: #e5e7eb; color: #374151;',
        'basic': 'background: #d1fae5; color: #065f46;',
        'pro': 'background: #ddd6fe; color: #5b21b6;',
        'vip': 'background: #fef3c7; color: #92400e;'
    };
    return styles[plan] || styles['free'];
}

function getDaysLeft(endDate) {
    if (!endDate) return '-';
    
    const end = new Date(endDate);
    const now = new Date();
    const days = Math.ceil((end - now) / (1000 * 60 * 60 * 24));
    
    if (days < 0) return '<span style="color: var(--danger); font-weight: 700;">منتهي</span>';
    if (days <= 7) return `<span style="color: var(--danger); font-weight: 700;">${days} يوم</span>`;
    if (days <= 15) return `<span style="color: var(--warning); font-weight: 700;">${days} يوم</span>`;
    return `<span style="color: var(--success); font-weight: 700;">${days} يوم</span>`;
}

function viewOffice(id) {
    alert(`🏢 عرض تفاصيل المكتب #${id}\n\n🚧 قيد التطوير...`);
}

async function suspendOffice(id, name) {
    if (!confirm(`هل تريد تعليق: ${name}؟\n\nسيتم إخفاء جميع إعلاناته`)) return;
    
    try {
        const response = await fetch(`${API_URL}/api/admin/offices/${id}/suspend`, {
            method: 'POST'
        });
        
        const data = await response.json();
        
        if (data.success) {
            alert('✅ تم تعليق المكتب');
            loadOffices();
        } else {
            alert('❌ ' + (data.error || 'حدث خطأ'));
        }
    } catch (error) {
        console.error('❌ Error:', error);
        alert('❌ حدث خطأ');
    }
}

async function activateOffice(id, name) {
    if (!confirm(`هل تريد تفعيل: ${name}؟`)) return;
    
    try {
        const response = await fetch(`${API_URL}/api/admin/offices/${id}/activate`, {
            method: 'POST'
        });
        
        const data = await response.json();
        
        if (data.success) {
            alert('✅ تم تفعيل المكتب');
            loadOffices();
        } else {
            alert('❌ ' + (data.error || 'حدث خطأ'));
        }
    } catch (error) {
        console.error('❌ Error:', error);
        alert('❌ حدث خطأ');
    }
}

async function renewSubscription(id, name) {
    const days = prompt(`تجديد اشتراك: ${name}\n\nعدد الأيام:`, '30');
    if (!days) return;
    
    try {
        const response = await fetch(`${API_URL}/api/admin/offices/${id}/renew`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ days: parseInt(days) })
        });
        
        const data = await response.json();
        
        if (data.success) {
            alert(`✅ تم تجديد الاشتراك لمدة ${days} يوم`);
            loadOffices();
        } else {
            alert('❌ ' + (data.error || 'حدث خطأ'));
        }
    } catch (error) {
        console.error('❌ Error:', error);
        alert('❌ حدث خطأ');
    }
}

function exportOffices() {
    alert('🚧 ميزة التصدير قيد التطوير');
}

function showLoading() {
    document.getElementById('officesTableBody').innerHTML = `
        <tr>
            <td colspan="6" style="text-align: center; padding: 60px;">
                <i class="fas fa-spinner fa-spin" style="font-size: 40px; color: var(--primary);"></i>
                <p style="margin-top: 20px; color: var(--text-secondary);">جاري التحميل...</p>
            </td>
        </tr>
    `;
}

function showError() {
    document.getElementById('officesTableBody').innerHTML = `
        <tr>
            <td colspan="6" style="text-align: center; padding: 60px;">
                <i class="fas fa-exclamation-triangle" style="font-size: 60px; color: var(--danger); opacity: 0.5;"></i>
                <p style="margin-top: 20px; color: var(--text-secondary);">فشل تحميل البيانات</p>
                <button class="btn btn-primary" onclick="loadOffices()" style="margin-top: 15px;">
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

console.log('✅ Offices Management JS Loaded');


