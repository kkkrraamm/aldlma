// AI Analytics JavaScript
console.log('🤖 [AI] Module loaded');

// API Configuration
const API_URL = 'https://dalma-api.onrender.com';

async function predictChurn() {
    try {
        console.log('🤖 [AI] Starting churn prediction analysis...');
        showToast('جاري تحليل نشاط المستخدمين...', 'info');
        
        const response = await fetch(`${API_URL}/api/admin/ai/predict-churn`, {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
                'x-api-key': localStorage.getItem('admin_apiKey')
            }
        });
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        
        const data = await response.json();
        console.log(`✅ [AI] Churn analysis complete: ${data.atRisk.length} users at risk`);
        
        const tbody = document.getElementById('churnTableBody');
        
        if (data.atRisk.length === 0) {
            tbody.innerHTML = `
                <tr><td colspan="6" class="text-center">
                    <i class="fas fa-check-circle text-success"></i> 
                    رائع! لا يوجد مستخدمين معرضين لخطر المغادرة
                </td></tr>
            `;
            showToast('تحليل مكتمل: لا يوجد مستخدمين معرضين للخطر', 'success');
            return;
        }
        
        tbody.innerHTML = data.atRisk.map(user => {
            const riskClass = user.churn_risk === 'high' ? 'danger' : 
                             user.churn_risk === 'medium' ? 'warning' : 'info';
            const riskText = user.churn_risk === 'high' ? 'عالي' :
                            user.churn_risk === 'medium' ? 'متوسط' : 'منخفض';
            const lastLogin = user.last_login ? 
                new Date(user.last_login).toLocaleDateString('ar-SA') : 'لم يسجل دخول أبداً';
            const daysInactive = Math.round(user.days_inactive);
            
            return `
                <tr>
                    <td><strong>#${user.id}</strong></td>
                    <td>${user.username}</td>
                    <td>${user.email}</td>
                    <td dir="ltr">${lastLogin}</td>
                    <td><span class="badge badge-warning">${daysInactive} يوم</span></td>
                    <td>
                        <span class="badge badge-${riskClass}">
                            <i class="fas fa-exclamation-triangle"></i> ${riskText}
                        </span>
                    </td>
                </tr>
            `;
        }).join('');
        
        showToast(`تم تحليل ${data.atRisk.length} مستخدم معرض للمغادرة`, 'warning');
        
    } catch (error) {
        console.error('❌ [AI] Error in churn prediction:', error);
        showToast('فشل تحليل Churn: ' + error.message, 'error');
        document.getElementById('churnTableBody').innerHTML = `
            <tr><td colspan="6" class="text-center text-danger">
                <i class="fas fa-exclamation-circle"></i> فشل التحليل
            </td></tr>
        `;
    }
}

async function detectFraud() {
    try {
        console.log('🚨 [AI] Starting fraud detection...');
        showToast('جاري فحص النشاطات المشبوهة...', 'info');
        
        const response = await fetch(`${API_URL}/api/admin/ai/detect-fraud`, {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
                'x-api-key': localStorage.getItem('admin_apiKey')
            }
        });
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        
        const data = await response.json();
        console.log(`✅ [AI] Fraud detection complete`);
        console.log(`   - Suspicious IPs: ${data.suspicious_ips.length}`);
        console.log(`   - Failed login attempts: ${data.failed_login_attempts.length}`);
        
        // Render suspicious IPs (multiple accounts from same IP)
        const fraudTbody = document.getElementById('fraudTableBody');
        
        if (data.suspicious_ips.length === 0) {
            fraudTbody.innerHTML = `
                <tr><td colspan="5" class="text-center">
                    <i class="fas fa-check-circle text-success"></i> 
                    لا توجد حسابات مشبوهة
                </td></tr>
            `;
        } else {
            fraudTbody.innerHTML = data.suspicious_ips.map(item => {
                const usernames = item.usernames.slice(0, 3).join(', ') + 
                                 (item.usernames.length > 3 ? ` +${item.usernames.length - 3}` : '');
                const emails = item.emails.slice(0, 3).join(', ') + 
                              (item.emails.length > 3 ? ` +${item.emails.length - 3}` : '');
                
                return `
                    <tr>
                        <td><code>${item.ip_address}</code></td>
                        <td><span class="badge badge-danger">${item.account_count}</span></td>
                        <td>${usernames}</td>
                        <td class="text-truncate" style="max-width: 200px;" title="${item.emails.join(', ')}">
                            ${emails}
                        </td>
                        <td>
                            <button class="btn btn-sm btn-danger" onclick="blockSuspiciousIP('${item.ip_address}')">
                                <i class="fas fa-ban"></i> حظر
                            </button>
                        </td>
                    </tr>
                `;
            }).join('');
        }
        
        // Render failed login attempts
        const failedTbody = document.getElementById('failedLoginsBody');
        
        if (data.failed_login_attempts.length === 0) {
            failedTbody.innerHTML = `
                <tr><td colspan="4" class="text-center">
                    <i class="fas fa-check-circle text-success"></i> 
                    لا توجد محاولات فاشلة متكررة
                </td></tr>
            `;
        } else {
            failedTbody.innerHTML = data.failed_login_attempts.map(item => {
                const lastAttempt = new Date(item.last_attempt).toLocaleString('ar-SA');
                
                return `
                    <tr>
                        <td><code>${item.ip_address}</code></td>
                        <td><span class="badge badge-danger">${item.failed_attempts}</span></td>
                        <td dir="ltr">${lastAttempt}</td>
                        <td>
                            <button class="btn btn-sm btn-danger" onclick="blockSuspiciousIP('${item.ip_address}')">
                                <i class="fas fa-ban"></i> حظر
                            </button>
                        </td>
                    </tr>
                `;
            }).join('');
        }
        
        const totalIssues = data.suspicious_ips.length + data.failed_login_attempts.length;
        if (totalIssues > 0) {
            showToast(`تم كشف ${totalIssues} حالة مشبوهة`, 'warning');
        } else {
            showToast('الفحص مكتمل: لا توجد نشاطات مشبوهة', 'success');
        }
        
    } catch (error) {
        console.error('❌ [AI] Error in fraud detection:', error);
        showToast('فشل كشف الاحتيال: ' + error.message, 'error');
        document.getElementById('fraudTableBody').innerHTML = `
            <tr><td colspan="5" class="text-center text-danger">
                <i class="fas fa-exclamation-circle"></i> فشل الفحص
            </td></tr>
        `;
        document.getElementById('failedLoginsBody').innerHTML = `
            <tr><td colspan="4" class="text-center text-danger">
                <i class="fas fa-exclamation-circle"></i> فشل الفحص
            </td></tr>
        `;
    }
}

async function blockSuspiciousIP(ip) {
    if (!confirm(`هل تريد حظر IP المشبوه: ${ip}؟`)) {
        return;
    }
    
    try {
        console.log(`🔒 [AI] Blocking suspicious IP: ${ip}`);
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
                reason: 'نشاط مشبوه - تم اكتشافه بواسطة AI'
            })
        });
        
        if (!response.ok) {
            throw new Error('Failed to block IP');
        }
        
        console.log(`✅ [AI] IP blocked successfully: ${ip}`);
        showToast(`تم حظر IP: ${ip}`, 'success');
        
        // Reload fraud detection
        detectFraud();
        
    } catch (error) {
        console.error('❌ [AI] Error blocking IP:', error);
        showToast('فشل حظر IP', 'error');
    }
}

console.log('✅ [AI] Module initialized');

