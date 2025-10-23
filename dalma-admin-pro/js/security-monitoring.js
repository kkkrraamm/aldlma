// Security Monitoring JavaScript
console.log('🔐 [SECURITY] Module loaded');

// API Configuration (API_URL is defined in main.js)

let currentFilter = 'all';
let allAttempts = [];

document.addEventListener('DOMContentLoaded', () => {
    console.log('🔐 [SECURITY] Page loaded');
    loadSecurityData();
});

async function loadSecurityData() {
    try {
        console.log('🔐 [SECURITY] Loading security data...');
        
        // Load statistics
        const statsResponse = await fetch(`${API_URL}/api/admin/security/stats`, {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
                'x-api-key': localStorage.getItem('admin_apiKey')
            }
        });

        if (!statsResponse.ok) {
            throw new Error(`HTTP ${statsResponse.status}`);
        }

        const stats = await statsResponse.json();
        console.log('✅ [SECURITY] Statistics loaded:', stats);

        // Update UI
        document.getElementById('totalAttempts').textContent = stats.total_attempts || 0;
        document.getElementById('successful').textContent = stats.successful || 0;
        document.getElementById('failed').textContent = stats.failed || 0;
        document.getElementById('blockedIPs').textContent = stats.blocked_ips || 0;

        // Load login attempts
        const attemptsResponse = await fetch(`${API_URL}/api/admin/security/login-attempts`, {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
                'x-api-key': localStorage.getItem('admin_apiKey')
            }
        });

        if (!attemptsResponse.ok) {
            throw new Error(`HTTP ${attemptsResponse.status}`);
        }

        allAttempts = await attemptsResponse.json();
        console.log(`✅ [SECURITY] Loaded ${allAttempts.length} login attempts`);

        renderAttempts(allAttempts);

    } catch (error) {
        console.error('❌ [SECURITY] Error loading data:', error);
        showToast('فشل تحميل بيانات الأمان', 'error');
        document.getElementById('attemptsTableBody').innerHTML = `
            <tr><td colspan="5" class="text-center text-danger">
                <i class="fas fa-exclamation-circle"></i> فشل التحميل
            </td></tr>
        `;
    }
}

function renderAttempts(attempts) {
    const tbody = document.getElementById('attemptsTableBody');
    
    if (attempts.length === 0) {
        tbody.innerHTML = `
            <tr><td colspan="5" class="text-center">
                <i class="fas fa-inbox"></i> لا توجد محاولات
            </td></tr>
        `;
        return;
    }

    tbody.innerHTML = attempts.map(attempt => {
        const date = new Date(attempt.attempted_at);
        const statusClass = attempt.success ? 'success' : 'danger';
        const statusIcon = attempt.success ? 'check-circle' : 'times-circle';
        const statusText = attempt.success ? 'ناجحة' : 'فاشلة';

        return `
            <tr>
                <td><code>${attempt.ip_address}</code></td>
                <td>${attempt.username || '—'}</td>
                <td>
                    <span class="badge badge-${statusClass}">
                        <i class="fas fa-${statusIcon}"></i> ${statusText}
                    </span>
                </td>
                <td dir="ltr">${date.toLocaleString('ar-SA')}</td>
                <td>
                    ${!attempt.success ? `
                        <button class="btn btn-sm btn-danger" onclick="blockIP('${attempt.ip_address}')">
                            <i class="fas fa-ban"></i> حظر
                        </button>
                    ` : '—'}
                </td>
            </tr>
        `;
    }).join('');
}

function filterAttempts(filter) {
    currentFilter = filter;
    let filtered = allAttempts;

    if (filter === 'success') {
        filtered = allAttempts.filter(a => a.success);
    } else if (filter === 'failed') {
        filtered = allAttempts.filter(a => !a.success);
    }

    renderAttempts(filtered);
}

async function blockIP(ip) {
    if (!confirm(`هل تريد حظر IP: ${ip}؟`)) {
        return;
    }

    try {
        console.log(`🔒 [SECURITY] Blocking IP: ${ip}`);
        showToast('جاري حظر IP...', 'info');

        const response = await fetch(`${API_URL}/api/admin/security/block-ip`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
                'x-api-key': localStorage.getItem('admin_apiKey')
            },
            body: JSON.stringify({
                ip,
                reason: 'محاولات تسجيل دخول فاشلة متعددة'
            })
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        console.log(`✅ [SECURITY] IP blocked: ${ip}`);
        showToast(`تم حظر IP: ${ip}`, 'success');

        // Reload data
        loadSecurityData();

    } catch (error) {
        console.error('❌ [SECURITY] Error blocking IP:', error);
        showToast('فشل حظر IP', 'error');
    }
}

function refreshData() {
    loadSecurityData();
    showToast('جاري التحديث...', 'info');
}

console.log('✅ [SECURITY] Module initialized');

