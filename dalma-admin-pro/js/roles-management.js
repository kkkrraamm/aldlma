// Roles Management JavaScript
console.log('🎭 [ROLES] Module loaded');

// API Configuration (API_URL is defined in main.js)

document.addEventListener('DOMContentLoaded', () => {
    console.log('🎭 [ROLES] Page loaded');
    loadAdmins();
    loadAuditLog();
    
    document.getElementById('addAdminForm')?.addEventListener('submit', addAdmin);
});

async function loadAdmins() {
    try {
        console.log('🎭 [ROLES] Loading admins...');
        
        const response = await fetch(`${API_URL}/api/admin/admins`, {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
                'x-api-key': localStorage.getItem('admin_apiKey')
            }
        });
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        
        const admins = await response.json();
        console.log(`✅ [ROLES] Loaded ${admins.length} admins`);
        
        renderAdmins(admins);
    } catch (error) {
        console.error('❌ [ROLES] Error loading admins:', error);
        showToast('فشل تحميل المشرفين', 'error');
        document.getElementById('adminsTableBody').innerHTML = `
            <tr><td colspan="5" class="text-center text-danger">
                <i class="fas fa-exclamation-circle"></i> فشل التحميل
            </td></tr>
        `;
    }
}

function renderAdmins(admins) {
    const tbody = document.getElementById('adminsTableBody');
    
    if (admins.length === 0) {
        tbody.innerHTML = `
            <tr><td colspan="5" class="text-center">
                <i class="fas fa-inbox"></i> لا يوجد مشرفين
            </td></tr>
        `;
        return;
    }
    
    tbody.innerHTML = admins.map(admin => {
        const date = new Date(admin.created_at);
        const roleBadge = getRoleBadge(admin.role);
        
        return `
            <tr>
                <td><strong>#${admin.id}</strong></td>
                <td>${admin.username}</td>
                <td>${roleBadge}</td>
                <td dir="ltr">${date.toLocaleString('ar-SA')}</td>
                <td>
                    <button class="btn btn-sm btn-danger" onclick="deleteAdmin(${admin.id}, '${admin.username}')">
                        <i class="fas fa-trash"></i> حذف
                    </button>
                </td>
            </tr>
        `;
    }).join('');
}

function getRoleBadge(role) {
    const badges = {
        'super_admin': '<span class="badge badge-danger">Super Admin</span>',
        'admin': '<span class="badge badge-primary">Admin</span>',
        'moderator': '<span class="badge badge-warning">Moderator</span>',
        'viewer': '<span class="badge badge-info">Viewer</span>'
    };
    return badges[role] || `<span class="badge badge-secondary">${role}</span>`;
}

async function addAdmin(e) {
    e.preventDefault();
    
    try {
        const username = document.getElementById('adminUsername').value.trim();
        const password = document.getElementById('adminPassword').value;
        const role = document.getElementById('adminRole').value;
        
        if (!username || !password || !role) {
            showToast('يرجى ملء جميع الحقول', 'error');
            return;
        }
        
        console.log(`🎭 [ROLES] Adding admin: ${username}`);
        showToast('جاري إضافة المشرف...', 'info');
        
        const response = await fetch(`${API_URL}/api/admin/admins`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
                'x-api-key': localStorage.getItem('admin_apiKey')
            },
            body: JSON.stringify({ username, password, role })
        });
        
        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.error || 'Failed to add admin');
        }
        
        console.log(`✅ [ROLES] Admin added: ${username}`);
        showToast('تم إضافة المشرف بنجاح', 'success');
        
        // Reset form
        document.getElementById('addAdminForm').reset();
        
        // Reload data
        loadAdmins();
        loadAuditLog();
        
    } catch (error) {
        console.error('❌ [ROLES] Error adding admin:', error);
        showToast('فشل إضافة المشرف: ' + error.message, 'error');
    }
}

async function deleteAdmin(id, username) {
    if (!confirm(`هل تريد حذف المشرف: ${username}؟\n\nهذا الإجراء لا يمكن التراجع عنه.`)) {
        return;
    }
    
    try {
        console.log(`🗑️ [ROLES] Deleting admin ID: ${id}`);
        showToast('جاري الحذف...', 'info');
        
        const response = await fetch(`${API_URL}/api/admin/admins/${id}`, {
            method: 'DELETE',
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
                'x-api-key': localStorage.getItem('admin_apiKey')
            }
        });
        
        if (!response.ok) {
            throw new Error('Failed to delete');
        }
        
        console.log(`✅ [ROLES] Admin deleted: ${username}`);
        showToast(`تم حذف المشرف: ${username}`, 'success');
        
        // Reload data
        loadAdmins();
        loadAuditLog();
        
    } catch (error) {
        console.error('❌ [ROLES] Error deleting admin:', error);
        showToast('فشل حذف المشرف', 'error');
    }
}

async function loadAuditLog() {
    try {
        console.log('📜 [ROLES] Loading audit log...');
        
        const response = await fetch(`${API_URL}/api/admin/audit-log`, {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
                'x-api-key': localStorage.getItem('admin_apiKey')
            }
        });
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        
        const log = await response.json();
        console.log(`✅ [ROLES] Loaded ${log.length} audit entries`);
        
        const tbody = document.getElementById('auditLogBody');
        
        if (log.length === 0) {
            tbody.innerHTML = `
                <tr><td colspan="4" class="text-center">
                    <i class="fas fa-inbox"></i> لا توجد نشاطات
                </td></tr>
            `;
            return;
        }
        
        tbody.innerHTML = log.slice(0, 100).map(entry => {
            const date = new Date(entry.timestamp);
            const details = entry.details ? JSON.stringify(entry.details) : '—';
            
            return `
                <tr>
                    <td><strong>${entry.admin_username || 'System'}</strong></td>
                    <td>${entry.action}</td>
                    <td class="text-truncate" style="max-width: 300px;" title="${details}">
                        ${details}
                    </td>
                    <td dir="ltr">${date.toLocaleString('ar-SA')}</td>
                </tr>
            `;
        }).join('');
        
    } catch (error) {
        console.error('❌ [ROLES] Error loading audit log:', error);
        document.getElementById('auditLogBody').innerHTML = `
            <tr><td colspan="4" class="text-center text-danger">
                <i class="fas fa-exclamation-circle"></i> فشل تحميل السجل
            </td></tr>
        `;
    }
}

console.log('✅ [ROLES] Module initialized');

