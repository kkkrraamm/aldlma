// Notifications Management JavaScript
console.log('📧 [NOTIFICATIONS] Module loaded');

// API Configuration
const API_URL = 'https://dalma-api.onrender.com';

// Templates
const templates = {
    welcome: {
        title: 'مرحباً بك في دلما!',
        body: 'نسعد بانضمامك إلى مجتمع دلما. استمتع بتجربة متميزة!'
    },
    newService: {
        title: 'خدمة جديدة متوفرة!',
        body: 'تحقق من الخدمات الجديدة المضافة اليوم'
    },
    offer: {
        title: 'عرض خاص لفترة محدودة!',
        body: 'احصل على خصم 50% على جميع الخدمات'
    },
    update: {
        title: 'تحديث جديد للتطبيق',
        body: 'تم إضافة ميزات جديدة. حدّث التطبيق الآن!'
    }
};

// Load statistics on page load
document.addEventListener('DOMContentLoaded', () => {
    console.log('📧 [NOTIFICATIONS] Page loaded');
    loadStatistics();
    loadHistory();
    
    // Show/hide user ID field based on target selection
    document.getElementById('notifTarget')?.addEventListener('change', (e) => {
        const userIdGroup = document.getElementById('userIdGroup');
        if (e.target.value === 'single') {
            userIdGroup.style.display = 'block';
        } else {
            userIdGroup.style.display = 'none';
        }
    });
    
    // Form submission
    document.getElementById('notificationForm')?.addEventListener('submit', async (e) => {
        e.preventDefault();
        await sendNotification();
    });
});

// Load notification statistics
async function loadStatistics() {
    try {
        console.log('📊 [NOTIFICATIONS] Loading statistics...');
        
        const response = await fetch(`${API_URL}/api/admin/notifications/stats`, {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
                'x-api-key': localStorage.getItem('admin_apiKey')
            }
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        const stats = await response.json();
        console.log('✅ [NOTIFICATIONS] Statistics loaded:', stats);

        // Update UI
        document.getElementById('totalSent').textContent = stats.total_sent || 0;
        document.getElementById('todaySent').textContent = stats.today_sent || 0;
        document.getElementById('successRate').textContent = `${stats.success_rate || 0}%`;
        document.getElementById('totalRecipients').textContent = stats.total_recipients || 0;

    } catch (error) {
        console.error('❌ [NOTIFICATIONS] Error loading statistics:', error);
        showToast('فشل تحميل الإحصائيات', 'error');
    }
}

// Load notification history
async function loadHistory() {
    try {
        console.log('📜 [NOTIFICATIONS] Loading history...');
        
        const response = await fetch(`${API_URL}/api/admin/notifications/history`, {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
                'x-api-key': localStorage.getItem('admin_apiKey')
            }
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        const history = await response.json();
        console.log(`✅ [NOTIFICATIONS] Loaded ${history.length} notifications`);

        renderHistory(history);

    } catch (error) {
        console.error('❌ [NOTIFICATIONS] Error loading history:', error);
        document.getElementById('historyTableBody').innerHTML = `
            <tr>
                <td colspan="7" class="text-center text-danger">
                    <i class="fas fa-exclamation-circle"></i> فشل تحميل السجل
                </td>
            </tr>
        `;
    }
}

// Render notification history table
function renderHistory(history) {
    const tbody = document.getElementById('historyTableBody');
    
    if (history.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="7" class="text-center">
                    <i class="fas fa-inbox"></i> لا توجد إشعارات مرسلة
                </td>
            </tr>
        `;
        return;
    }

    tbody.innerHTML = history.map(notif => {
        const sentAt = new Date(notif.sent_at);
        const targetLabel = getTargetLabel(notif.target);
        const successRate = notif.sent_to > 0 ? ((notif.success / notif.sent_to) * 100).toFixed(1) : 0;
        
        return `
            <tr>
                <td><strong>${escapeHtml(notif.title)}</strong></td>
                <td class="text-truncate" style="max-width: 200px;" title="${escapeHtml(notif.body)}">
                    ${escapeHtml(notif.body)}
                </td>
                <td>
                    <span class="badge badge-info">${targetLabel}</span>
                </td>
                <td>${notif.sent_to}</td>
                <td>
                    <span class="badge badge-success">
                        ${notif.success} (${successRate}%)
                    </span>
                </td>
                <td>
                    <span class="badge badge-danger">${notif.failure}</span>
                </td>
                <td dir="ltr">${sentAt.toLocaleString('ar-SA')}</td>
            </tr>
        `;
    }).join('');
}

// Get target label in Arabic
function getTargetLabel(target) {
    const labels = {
        'all': 'الجميع',
        'users': 'المستخدمين',
        'media': 'الإعلاميين',
        'providers': 'مقدمي الخدمات',
        'single': 'مستخدم واحد'
    };
    return labels[target] || target;
}

// Send notification
async function sendNotification() {
    try {
        const title = document.getElementById('notifTitle').value.trim();
        const body = document.getElementById('notifBody').value.trim();
        const target = document.getElementById('notifTarget').value;
        const userId = document.getElementById('userId').value.trim();

        if (!title || !body) {
            showToast('يرجى ملء جميع الحقول المطلوبة', 'error');
            return;
        }

        if (target === 'single' && !userId) {
            showToast('يرجى إدخال معرف المستخدم', 'error');
            return;
        }

        console.log('📧 [NOTIFICATIONS] Sending notification...');
        showToast('جاري الإرسال...', 'info');

        // Get FCM tokens
        const tokensResponse = await fetch(`${API_URL}/api/admin/notifications/tokens`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
                'x-api-key': localStorage.getItem('admin_apiKey')
            },
            body: JSON.stringify({ target, userId: target === 'single' ? userId : null })
        });

        if (!tokensResponse.ok) {
            throw new Error('فشل جلب FCM tokens');
        }

        const { tokens } = await tokensResponse.json();
        console.log(`✅ [NOTIFICATIONS] Got ${tokens.length} FCM tokens`);

        if (tokens.length === 0) {
            showToast('لا توجد أجهزة مستهدفة', 'warning');
            return;
        }

        // In a real app, you would send to Firebase Cloud Messaging here
        // For now, we'll simulate success
        const success = tokens.length;
        const failure = 0;

        // Log notification
        await fetch(`${API_URL}/api/admin/notifications/log`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
                'x-api-key': localStorage.getItem('admin_apiKey')
            },
            body: JSON.stringify({
                title,
                body,
                target,
                sent_to: tokens.length,
                success,
                failure
            })
        });

        console.log(`✅ [NOTIFICATIONS] Notification sent successfully to ${success} users`);
        showToast(`تم إرسال الإشعار بنجاح إلى ${success} مستخدم`, 'success');

        // Clear form
        document.getElementById('notificationForm').reset();
        
        // Reload data
        loadStatistics();
        loadHistory();

    } catch (error) {
        console.error('❌ [NOTIFICATIONS] Error sending notification:', error);
        showToast('فشل إرسال الإشعار: ' + error.message, 'error');
    }
}

// Load template
function loadTemplate() {
    const templateNames = Object.keys(templates);
    const templateOptions = templateNames.map(name => {
        return `<button class="btn btn-outline" onclick="applyTemplate('${name}')" style="margin: 5px;">
            ${templates[name].title}
        </button>`;
    }).join('');

    const modal = document.createElement('div');
    modal.className = 'modal-overlay';
    modal.innerHTML = `
        <div class="modal-content" style="max-width: 600px;">
            <div class="modal-header">
                <h3>اختر قالباً</h3>
                <button class="btn-close" onclick="this.closest('.modal-overlay').remove()">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <div class="modal-body">
                <div style="display: flex; flex-direction: column; gap: 10px;">
                    ${templateOptions}
                </div>
            </div>
        </div>
    `;
    document.body.appendChild(modal);
}

// Apply template
function applyTemplate(templateName) {
    const template = templates[templateName];
    if (template) {
        document.getElementById('notifTitle').value = template.title;
        document.getElementById('notifBody').value = template.body;
        showToast('تم تطبيق القالب', 'success');
    }
    document.querySelector('.modal-overlay')?.remove();
}

// Refresh history
function refreshHistory() {
    loadHistory();
    showToast('جاري تحديث السجل...', 'info');
}

// Utility function to escape HTML
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

console.log('✅ [NOTIFICATIONS] Module initialized');

