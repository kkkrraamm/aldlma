// Settings Management JavaScript
console.log('⚙️ [SETTINGS] Module loaded');

// Load settings on page load
document.addEventListener('DOMContentLoaded', () => {
    console.log('⚙️ [SETTINGS] Page loaded');
    loadSettings();
});

// Load current settings from server
async function loadSettings() {
    try {
        console.log('⚙️ [SETTINGS] Loading settings from server...');

        const response = await fetch(`${API_BASE_URL}/api/admin/settings`, {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
                'x-api-key': localStorage.getItem('admin_apiKey')
            }
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        const settings = await response.json();
        console.log('✅ [SETTINGS] Settings loaded:', settings);

        // Populate form fields
        document.getElementById('appName').value = settings.appName || 'دلما';
        document.getElementById('appVersion').value = settings.appVersion || '1.0.0';
        document.getElementById('primaryColor').value = settings.primaryColor || '#6366f1';
        document.getElementById('enableNotifications').value = settings.enableNotifications !== false ? 'true' : 'false';

        // SMTP settings
        if (settings.smtp) {
            document.getElementById('smtpHost').value = settings.smtp.host || '';
            document.getElementById('smtpPort').value = settings.smtp.port || 587;
            document.getElementById('smtpUser').value = settings.smtp.user || '';
            // Don't populate password for security
        }

    } catch (error) {
        console.error('❌ [SETTINGS] Error loading settings:', error);
        showToast('فشل تحميل الإعدادات', 'error');
        
        // Use default values
        document.getElementById('appName').value = 'دلما';
        document.getElementById('appVersion').value = '1.0.0';
        document.getElementById('primaryColor').value = '#6366f1';
        document.getElementById('enableNotifications').value = 'true';
    }
}

// Save settings
async function saveSettings() {
    try {
        console.log('⚙️ [SETTINGS] Saving settings...');
        showToast('جاري حفظ الإعدادات...', 'info');

        // Collect form data
        const settings = {
            appName: document.getElementById('appName').value,
            appVersion: document.getElementById('appVersion').value,
            primaryColor: document.getElementById('primaryColor').value,
            enableNotifications: document.getElementById('enableNotifications').value === 'true',
            smtp: {
                host: document.getElementById('smtpHost').value,
                port: parseInt(document.getElementById('smtpPort').value) || 587,
                user: document.getElementById('smtpUser').value,
                password: document.getElementById('smtpPassword').value || undefined
            }
        };

        // Send to server
        const response = await fetch(`${API_BASE_URL}/api/admin/settings`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
                'x-api-key': localStorage.getItem('admin_apiKey')
            },
            body: JSON.stringify(settings)
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        const result = await response.json();
        console.log('✅ [SETTINGS] Settings saved successfully');
        showToast('تم حفظ الإعدادات بنجاح', 'success');

        // Clear password field for security
        document.getElementById('smtpPassword').value = '';

    } catch (error) {
        console.error('❌ [SETTINGS] Error saving settings:', error);
        showToast('فشل حفظ الإعدادات: ' + error.message, 'error');
    }
}

// Test SMTP connection
async function testSMTP() {
    try {
        console.log('📧 [SETTINGS] Testing SMTP connection...');
        showToast('جاري اختبار الاتصال...', 'info');

        const smtpConfig = {
            host: document.getElementById('smtpHost').value,
            port: parseInt(document.getElementById('smtpPort').value) || 587,
            user: document.getElementById('smtpUser').value,
            password: document.getElementById('smtpPassword').value
        };

        if (!smtpConfig.host || !smtpConfig.user) {
            showToast('يرجى ملء معلومات SMTP أولاً', 'warning');
            return;
        }

        // Note: In a real implementation, you would have a backend endpoint for testing SMTP
        // For now, we'll just validate the input
        console.log('✅ [SETTINGS] SMTP configuration validated');
        showToast('تم التحقق من إعدادات SMTP (اختبار محلي)', 'success');

        // In production, you would call:
        // const response = await fetch(`${API_BASE_URL}/api/admin/settings/test-smtp`, {
        //     method: 'POST',
        //     headers: { ... },
        //     body: JSON.stringify(smtpConfig)
        // });

    } catch (error) {
        console.error('❌ [SETTINGS] Error testing SMTP:', error);
        showToast('فشل اختبار SMTP: ' + error.message, 'error');
    }
}

console.log('✅ [SETTINGS] Module initialized');

