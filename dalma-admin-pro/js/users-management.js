// Users Management Page
// API_URL is defined in main.js
let allUsers = [];
let filteredUsers = [];
let currentUser = null;

// Load users on page load
window.addEventListener('DOMContentLoaded', () => {
    console.log('📋 [USERS] تهيئة صفحة إدارة المستخدمين...');
    
    // Load admin name
    const username = localStorage.getItem('admin_username');
    if (username) {
        const adminNameElement = document.getElementById('adminName');
        if (adminNameElement) {
            adminNameElement.textContent = username;
        }
    }
    
    // Load users
    loadUsers();
});

// Load all users
async function loadUsers() {
    try {
        console.log('📋 [USERS] جلب قائمة المستخدمين...');
        
        // Try to fetch from API
        try {
            const data = await apiRequest('/api/admin/users');
            console.log('✅ [USERS] تم جلب البيانات من API:', data);
            allUsers = data.users || [];
        } catch (error) {
            console.warn('⚠️ [USERS] فشل جلب البيانات، استخدام بيانات تجريبية:', error);
            // Fallback to mock data
            allUsers = generateMockUsers();
        }
        
        filteredUsers = [...allUsers];
        updateStats();
        renderUsersTable();
        
    } catch (error) {
        console.error('❌ [USERS] خطأ في تحميل المستخدمين:', error);
        showError('فشل تحميل المستخدمين');
    }
}

// Generate mock users for testing
function generateMockUsers() {
    const names = [
        'أحمد العتيبي', 'سارة القحطاني', 'محمد السديري', 'فاطمة الشمري',
        'عبدالله الدوسري', 'نورة العمري', 'خالد المطيري', 'مريم الزهراني',
        'سلطان الحربي', 'ريم العنزي', 'فهد القرني', 'هند البقمي',
        'ناصر الشهري', 'لمى الثبيتي', 'عمر المالكي', 'دانة الخالدي'
    ];
    
    const roles = ['user', 'user', 'user', 'media', 'provider'];
    const statuses = ['active', 'active', 'active', 'blocked'];
    
    return names.map((name, index) => ({
        id: index + 1,
        name: name,
        email: `user${index + 1}@example.com`,
        phone: `+9665${Math.floor(Math.random() * 90000000 + 10000000)}`,
        role: roles[Math.floor(Math.random() * roles.length)],
        status: statuses[Math.floor(Math.random() * statuses.length)],
        created_at: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000).toISOString(),
        last_login: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000).toISOString(),
        devices_count: Math.floor(Math.random() * 5 + 1),
        orders_count: Math.floor(Math.random() * 20),
        avatar_url: null
    }));
}

// Update stats
function updateStats() {
    const total = allUsers.length;
    const active = allUsers.filter(u => u.status === 'active').length;
    const blocked = allUsers.filter(u => u.status === 'blocked').length;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const newToday = allUsers.filter(u => new Date(u.created_at) >= today).length;
    
    document.getElementById('totalUsersCount').textContent = total;
    document.getElementById('activeUsersCount').textContent = active;
    document.getElementById('blockedUsersCount').textContent = blocked;
    document.getElementById('newUsersCount').textContent = newToday;
}

// Render users table
function renderUsersTable() {
    const tbody = document.getElementById('usersTableBody');
    const usersCount = document.getElementById('usersCount');
    
    usersCount.textContent = `${filteredUsers.length} مستخدم`;
    
    if (filteredUsers.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="6" style="text-align: center; padding: 60px;">
                    <i class="fas fa-inbox" style="font-size: 50px; color: var(--text-tertiary); margin-bottom: 15px;"></i>
                    <p style="color: var(--text-secondary); font-size: 16px;">لا توجد نتائج</p>
                </td>
            </tr>
        `;
        return;
    }
    
    tbody.innerHTML = filteredUsers.map(user => `
        <tr data-user-id="${user.id}">
            <td>
                <div class="user-cell">
                    ${user.profile_picture 
                        ? `<img src="${user.profile_picture}" class="user-avatar-img" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';" />
                           <div class="user-avatar" style="display:none;">${getInitials(user.name)}</div>`
                        : `<div class="user-avatar">${getInitials(user.name)}</div>`
                    }
                    <div class="user-info">
                        <div class="user-name">${user.name}</div>
                        <div class="user-email">${user.phone || 'لا يوجد'}</div>
                    </div>
                </div>
            </td>
            <td>
                <span class="badge ${user.role}">
                    ${getRoleLabel(user.role)}
                </span>
            </td>
            <td>
                <span class="badge ${user.status || 'inactive'}">
                    ${user.status === 'active' ? '<i class="fas fa-circle"></i> نشط' : '<i class="fas fa-circle"></i> غير نشط'}
                </span>
            </td>
            <td>
                <div class="devices-count" onclick="toggleDevices(${user.id})" style="cursor: pointer;">
                    <i class="fas fa-mobile-alt"></i>
                    <span>${user.device_count || 0} جهاز</span>
                    <i class="fas fa-chevron-down" style="margin-right: 5px; font-size: 12px;"></i>
                </div>
            </td>
            <td>${formatDate(user.created_at)}</td>
            <td>
                <div class="table-actions-cell">
                    <button class="btn-icon view" onclick='viewUser(${JSON.stringify(user).replace(/'/g, "&apos;")})' title="عرض التفاصيل">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button class="btn-icon edit" onclick='editUser(${JSON.stringify(user).replace(/'/g, "&apos;")})' title="تعديل">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="btn-icon delete" onclick='deleteUser(${user.id})' title="حذف">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </td>
        </tr>
        <tr id="devices-row-${user.id}" class="devices-details-row" style="display: none;">
            <td colspan="6">
                <div class="devices-loading" style="text-align: center; padding: 20px;">
                    <i class="fas fa-spinner fa-spin"></i> جارٍ تحميل الأجهزة...
                </div>
            </td>
        </tr>
    `).join('');
}

// Filter users
function filterUsers() {
    const search = document.getElementById('searchInput').value.toLowerCase();
    const role = document.getElementById('roleFilter').value;
    const status = document.getElementById('statusFilter').value;
    const dateFilter = document.getElementById('dateFilter').value;
    
    filteredUsers = allUsers.filter(user => {
        // Search filter
        const matchesSearch = !search || 
            user.name.toLowerCase().includes(search) || 
            user.email.toLowerCase().includes(search);
        
        // Role filter
        const matchesRole = role === 'all' || user.role === role;
        
        // Status filter
        const matchesStatus = status === 'all' || user.status === status;
        
        // Date filter
        let matchesDate = true;
        if (dateFilter !== 'all') {
            const createdDate = new Date(user.created_at);
            const now = new Date();
            
            if (dateFilter === 'today') {
                const today = new Date();
                today.setHours(0, 0, 0, 0);
                matchesDate = createdDate >= today;
            } else if (dateFilter === 'week') {
                const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
                matchesDate = createdDate >= weekAgo;
            } else if (dateFilter === 'month') {
                const monthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
                matchesDate = createdDate >= monthAgo;
            }
        }
        
        return matchesSearch && matchesRole && matchesStatus && matchesDate;
    });
    
    renderUsersTable();
}

// View user details
async function viewUser(user) {
    currentUser = user;
    const modal = document.getElementById('userModal');
    const modalBody = document.getElementById('modalBody');
    
    // Show initial content with loading for devices
    modalBody.innerHTML = `
        <div class="user-profile-header">
            <div class="user-profile-avatar">
                ${user.profile_picture 
                    ? `<img src="${user.profile_picture}" style="width: 100%; height: 100%; border-radius: 50%; object-fit: cover;" onerror="this.style.display='none'; this.parentElement.innerHTML='${getInitials(user.name)}';" />`
                    : getInitials(user.name)
                }
            </div>
            <div class="user-profile-info">
                <h2>${user.name}</h2>
                <p>${user.phone || 'غير متوفر'}</p>
                <div class="profile-badges">
                    <span class="badge ${user.role}">${getRoleLabel(user.role)}</span>
                    <span class="badge ${user.status || 'inactive'}">${user.status === 'active' ? 'نشط' : 'غير نشط'}</span>
                </div>
            </div>
        </div>
        
        <div class="info-grid">
            <div class="info-item">
                <div class="info-label">رقم الهاتف</div>
                <div class="info-value">${user.phone || 'غير متوفر'}</div>
            </div>
            <div class="info-item">
                <div class="info-label">تاريخ التسجيل</div>
                <div class="info-value">${formatDate(user.created_at)}</div>
            </div>
            <div class="info-item">
                <div class="info-label">آخر نشاط</div>
                <div class="info-value">${formatTimeAgo(user.last_login)}</div>
            </div>
            <div class="info-item">
                <div class="info-label">عدد الأجهزة المتصلة</div>
                <div class="info-value">${user.device_count || 0} جهاز</div>
            </div>
            <div class="info-item">
                <div class="info-label">تاريخ الميلاد</div>
                <div class="info-value">${user.birth_date ? formatDate(user.birth_date) : 'غير متوفر'}</div>
            </div>
            <div class="info-item">
                <div class="info-label">معرّف المستخدم</div>
                <div class="info-value">#${user.id}</div>
            </div>
        </div>
        
        <div class="modal-section">
            <h3 class="modal-section-title">
                <i class="fas fa-mobile-alt"></i>
                الأجهزة المتصلة (${user.device_count || 0})
            </h3>
            <div id="modalDevicesContainer" class="modal-devices-loading">
                <i class="fas fa-spinner fa-spin"></i> جارٍ تحميل الأجهزة...
            </div>
        </div>
    `;
    
    modal.classList.add('active');
    
    // Load devices asynchronously
    if (user.device_count > 0) {
        try {
            const data = await apiRequest(`/api/admin/users/${user.id}/devices`);
            const devices = data.devices || [];
            renderModalDevices(devices);
        } catch (error) {
            console.error('❌ [MODAL DEVICES] خطأ في تحميل الأجهزة:', error);
            document.getElementById('modalDevicesContainer').innerHTML = `
                <div style="text-align: center; padding: 20px; color: #e74c3c;">
                    <i class="fas fa-exclamation-triangle"></i> فشل تحميل الأجهزة
                </div>
            `;
        }
    } else {
        document.getElementById('modalDevicesContainer').innerHTML = `
            <div style="text-align: center; padding: 20px; color: var(--text-secondary);">
                <i class="fas fa-mobile-alt"></i> لا توجد أجهزة مسجلة
            </div>
        `;
    }
}

function renderModalDevices(devices) {
    const container = document.getElementById('modalDevicesContainer');
    if (!container) return;
    
    if (devices.length === 0) {
        container.innerHTML = `
            <div style="text-align: center; padding: 20px; color: var(--text-secondary);">
                <i class="fas fa-mobile-alt"></i> لا توجد أجهزة مسجلة
            </div>
        `;
        return;
    }
    
    const devicesHTML = devices.map(device => {
        const info = device.device_info || {};
        const deviceName = info.name || info.model || 'جهاز غير معروف';
        const platform = info.platform || 'غير محدد';
        const platformIcon = getPlatformIcon(platform);
        const isPhysical = info.isPhysicalDevice !== undefined ? info.isPhysicalDevice : true;
        const deviceType = isPhysical ? 'جهاز حقيقي' : 'محاكي';
        const systemVersion = info.systemVersion || info.os_version || 'غير محدد';
        const lastLogin = formatTimeAgo(device.last_login);
        
        return `
            <div class="device-card">
                <div class="device-header">
                    <div class="device-icon ${platform.toLowerCase()}">
                        ${platformIcon}
                    </div>
                    <div class="device-main-info">
                        <div class="device-name">${deviceName}</div>
                        <div class="device-platform">${platform} ${systemVersion}</div>
                    </div>
                    <div class="device-type-badge ${isPhysical ? 'physical' : 'simulator'}">
                        ${deviceType}
                    </div>
                </div>
                <div class="device-details">
                    <div class="device-detail-item">
                        <i class="fas fa-clock"></i>
                        <span>آخر استخدام: ${lastLogin}</span>
                    </div>
                    <div class="device-detail-item">
                        <i class="fas fa-calendar"></i>
                        <span>تم التسجيل: ${formatDate(device.created_at)}</span>
                    </div>
                    ${info.location ? `
                        <div class="device-detail-item">
                            <i class="fas fa-map-marker-alt"></i>
                            <span>الموقع: ${info.location.latitude.toFixed(4)}, ${info.location.longitude.toFixed(4)}</span>
                        </div>
                    ` : ''}
                </div>
            </div>
        `;
    }).join('');
    
    container.innerHTML = `
        <div class="modal-devices-grid">
            ${devicesHTML}
        </div>
    `;
}

// Close user modal
function closeUserModal() {
    const modal = document.getElementById('userModal');
    modal.classList.remove('active');
    currentUser = null;
}

// Edit user
function editUser(user) {
    if (user) {
        currentUser = user;
    }
    
    if (!currentUser) {
        showToast('لم يتم تحديد مستخدم للتعديل', 'error');
        return;
    }
    
    console.log('✏️ [USERS] فتح نموذج التعديل:', currentUser);
    
    // Create modal HTML
    const modalHTML = `
        <div class="modal-overlay" id="editUserModal">
            <div class="modal-content">
                <div class="modal-header">
                    <h3>✏️ تعديل بيانات المستخدم</h3>
                    <button class="modal-close" onclick="closeEditModal()">&times;</button>
                </div>
                <div class="modal-body">
                    <form id="editUserForm" onsubmit="saveUserEdit(event)">
                        <div class="form-group">
                            <label>الاسم الكامل</label>
                            <input type="text" id="editName" value="${currentUser.name}" required>
                        </div>
                        <div class="form-group">
                            <label>رقم الجوال</label>
                            <input type="tel" id="editPhone" value="${currentUser.phone}" required>
                        </div>
                        <div class="form-group">
                            <label>الدور (Role)</label>
                            <select id="editRole" required>
                                <option value="user" ${currentUser.role === 'user' ? 'selected' : ''}>👤 مستخدم عادي</option>
                                <option value="media" ${currentUser.role === 'media' ? 'selected' : ''}>📺 إعلامي</option>
                                <option value="provider" ${currentUser.role === 'provider' ? 'selected' : ''}>🏪 مزود خدمة</option>
                                <option value="admin" ${currentUser.role === 'admin' ? 'selected' : ''}>👑 Admin</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>تاريخ الميلاد (اختياري)</label>
                            <input type="date" id="editBirthDate" value="${currentUser.birth_date ? currentUser.birth_date.split('T')[0] : ''}">
                        </div>
                        <div class="form-actions">
                            <button type="submit" class="btn btn-primary">
                                <i class="fas fa-save"></i> حفظ التعديلات
                            </button>
                            <button type="button" class="btn btn-secondary" onclick="closeEditModal()">
                                <i class="fas fa-times"></i> إلغاء
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    `;
    
    // Add modal to page
    document.body.insertAdjacentHTML('beforeend', modalHTML);
}

// Close edit modal
function closeEditModal() {
    const modal = document.getElementById('editUserModal');
    if (modal) {
        modal.remove();
    }
    currentUser = null;
}

// Save user edit
async function saveUserEdit(event) {
    event.preventDefault();
    
    try {
        const name = document.getElementById('editName').value.trim();
        const phone = document.getElementById('editPhone').value.trim();
        const role = document.getElementById('editRole').value;
        const birth_date = document.getElementById('editBirthDate').value;
        
        console.log('💾 [USERS] حفظ تعديلات المستخدم:', currentUser.id);
        
        // Call API
        const data = await apiRequest(`/api/admin/users/${currentUser.id}`, {
            method: 'PUT',
            body: JSON.stringify({ name, phone, role, birth_date })
        });
        
        console.log('✅ [USERS] تم حفظ التعديلات:', data);
        
        // Update local data
        const userIndex = allUsers.findIndex(u => u.id === currentUser.id);
        if (userIndex !== -1) {
            allUsers[userIndex] = { ...allUsers[userIndex], name, phone, role, birth_date };
        }
        
        const filteredIndex = filteredUsers.findIndex(u => u.id === currentUser.id);
        if (filteredIndex !== -1) {
            filteredUsers[filteredIndex] = { ...filteredUsers[filteredIndex], name, phone, role, birth_date };
        }
        
        // Refresh table
        renderUsersTable();
        closeEditModal();
        showToast('تم حفظ التعديلات بنجاح', 'success');
        
    } catch (error) {
        console.error('❌ [USERS] خطأ في حفظ التعديلات:', error);
        showToast('فشل حفظ التعديلات: ' + (error.message || 'خطأ غير معروف'), 'error');
    }
}

// Delete user
async function deleteUser(userId) {
    if (!confirm('هل أنت متأكد من حذف هذا المستخدم؟\n\n⚠️ هذا الإجراء لا يمكن التراجع عنه.\n⚠️ سيتم حذف جميع بيانات المستخدم بشكل نهائي.')) {
        return;
    }
    
    try {
        console.log('🗑️ [USERS] حذف مستخدم:', userId);
        
        // Call API to delete user
        await apiRequest(`/api/admin/users/${userId}`, { method: 'DELETE' });
        
        console.log('✅ [USERS] تم حذف المستخدم من السيرفر');
        
        // Remove from local arrays
        allUsers = allUsers.filter(u => u.id !== userId);
        filteredUsers = filteredUsers.filter(u => u.id !== userId);
        
        updateStats();
        renderUsersTable();
        showToast('تم حذف المستخدم بنجاح', 'success');
        
    } catch (error) {
        console.error('❌ [USERS] خطأ في حذف المستخدم:', error);
        showToast('فشل حذف المستخدم: ' + (error.message || 'خطأ غير معروف'), 'error');
    }
}

// Refresh users
async function refreshUsers() {
    showToast('جاري تحديث البيانات...', 'info');
    await loadUsers();
    showToast('تم التحديث بنجاح', 'success');
}

// Export users to Excel
function exportUsers() {
    showToast('جاري تصدير البيانات...', 'info');
    
    // Create CSV content
    const headers = ['الاسم', 'البريد الإلكتروني', 'الهاتف', 'النوع', 'الحالة', 'تاريخ التسجيل'];
    const rows = filteredUsers.map(user => [
        user.name,
        user.email,
        user.phone || '',
        getRoleLabel(user.role),
        getStatusLabel(user.status),
        formatDate(user.created_at)
    ]);
    
    let csvContent = headers.join(',') + '\n';
    rows.forEach(row => {
        csvContent += row.map(cell => `"${cell}"`).join(',') + '\n';
    });
    
    // Download file
    const blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', `users_${new Date().toISOString().split('T')[0]}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    
    showToast('تم تصدير البيانات بنجاح', 'success');
}

// Helper functions
function getInitials(name) {
    return name
        .split(' ')
        .map(n => n[0])
        .join('')
        .toUpperCase()
        .substring(0, 2);
}

function getRoleLabel(role) {
    const labels = {
        user: 'مستخدم',
        media: 'إعلامي',
        provider: 'مقدم خدمة'
    };
    return labels[role] || role;
}

function getStatusLabel(status) {
    const labels = {
        active: 'نشط',
        blocked: 'محظور'
    };
    return labels[status] || status;
}

function formatDate(dateString) {
    if (!dateString) return 'غير متوفر';
    const date = new Date(dateString);
    return date.toLocaleDateString('ar-SA', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });
}

function formatTimeAgo(dateString) {
    if (!dateString) return 'غير متوفر';
    const date = new Date(dateString);
    const now = new Date();
    const diff = now - date;
    
    const seconds = Math.floor(diff / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);
    
    if (days > 0) return `منذ ${days} يوم`;
    if (hours > 0) return `منذ ${hours} ساعة`;
    if (minutes > 0) return `منذ ${minutes} دقيقة`;
    return 'الآن';
}

// Toggle devices details for a user
let loadedDevices = {}; // Cache for loaded devices

async function toggleDevices(userId) {
    const devicesRow = document.getElementById(`devices-row-${userId}`);
    
    if (!devicesRow) return;
    
    // If already visible, hide it
    if (devicesRow.style.display !== 'none') {
        devicesRow.style.display = 'none';
        return;
    }
    
    // Show the row
    devicesRow.style.display = 'table-row';
    
    // If already loaded, just display cached data
    if (loadedDevices[userId]) {
        renderDevices(userId, loadedDevices[userId]);
        return;
    }
    
    // Load devices from API
    try {
        const data = await apiRequest(`/api/admin/users/${userId}/devices`);
        loadedDevices[userId] = data.devices || [];
        renderDevices(userId, loadedDevices[userId]);
    } catch (error) {
        console.error('❌ [DEVICES] خطأ في تحميل الأجهزة:', error);
        devicesRow.querySelector('td').innerHTML = `
            <div style="text-align: center; padding: 20px; color: #e74c3c;">
                <i class="fas fa-exclamation-triangle"></i> فشل تحميل الأجهزة
            </div>
        `;
    }
}

function renderDevices(userId, devices) {
    const devicesRow = document.getElementById(`devices-row-${userId}`);
    if (!devicesRow) return;
    
    if (devices.length === 0) {
        devicesRow.querySelector('td').innerHTML = `
            <div style="text-align: center; padding: 20px; color: var(--text-secondary);">
                <i class="fas fa-mobile-alt"></i> لا توجد أجهزة مسجلة
            </div>
        `;
        return;
    }
    
    const devicesHTML = devices.map((device, index) => {
        const info = device.device_info || {};
        const deviceName = info.name || info.model || 'جهاز غير معروف';
        const platform = info.platform || 'غير محدد';
        const platformIcon = getPlatformIcon(platform);
        const isPhysical = info.isPhysicalDevice !== undefined ? info.isPhysicalDevice : true;
        const deviceType = isPhysical ? 'جهاز حقيقي' : 'محاكي';
        const systemVersion = info.systemVersion || info.os_version || 'غير محدد';
        const lastLogin = formatTimeAgo(device.last_login);
        
        return `
            <div class="device-card">
                <div class="device-header">
                    <div class="device-icon ${platform.toLowerCase()}">
                        ${platformIcon}
                    </div>
                    <div class="device-main-info">
                        <div class="device-name">${deviceName}</div>
                        <div class="device-platform">${platform} ${systemVersion}</div>
                    </div>
                    <div class="device-type-badge ${isPhysical ? 'physical' : 'simulator'}">
                        ${deviceType}
                    </div>
                </div>
                <div class="device-details">
                    <div class="device-detail-item">
                        <i class="fas fa-clock"></i>
                        <span>آخر استخدام: ${lastLogin}</span>
                    </div>
                    <div class="device-detail-item">
                        <i class="fas fa-calendar"></i>
                        <span>تم التسجيل: ${formatDate(device.created_at)}</span>
                    </div>
                    ${info.location ? `
                        <div class="device-detail-item">
                            <i class="fas fa-map-marker-alt"></i>
                            <span>الموقع: ${info.location.latitude.toFixed(4)}, ${info.location.longitude.toFixed(4)}</span>
                        </div>
                    ` : ''}
                </div>
            </div>
        `;
    }).join('');
    
    devicesRow.querySelector('td').innerHTML = `
        <div class="devices-container">
            ${devicesHTML}
        </div>
    `;
}

function getPlatformIcon(platform) {
    const icons = {
        'ios': '<i class="fab fa-apple"></i>',
        'android': '<i class="fab fa-android"></i>',
        'web': '<i class="fas fa-globe"></i>',
        'windows': '<i class="fab fa-windows"></i>',
        'macos': '<i class="fab fa-apple"></i>',
        'linux': '<i class="fab fa-linux"></i>'
    };
    return icons[platform.toLowerCase()] || '<i class="fas fa-mobile-alt"></i>';
}

function showToast(message, type = 'info') {
    console.log(`[${type.toUpperCase()}] ${message}`);
    // TODO: Implement toast notification UI
}

function showError(message) {
    console.error('❌', message);
    showToast(message, 'error');
}

// API Helper (use existing from main.js if available)
async function apiRequest(endpoint, options = {}) {
    const token = localStorage.getItem('admin_token');
    const apiKey = localStorage.getItem('admin_apiKey');
    
    const headers = {
        'Content-Type': 'application/json',
        'X-API-Key': apiKey,
        ...options.headers
    };
    
    if (token) {
        headers['Authorization'] = `Bearer ${token}`;
    }
    
    const response = await fetch(`${API_URL}${endpoint}`, {
        ...options,
        headers
    });
    
    if (!response.ok) {
        if (response.status === 401 || response.status === 403) {
            localStorage.removeItem('admin_token');
            localStorage.removeItem('admin_username');
            localStorage.removeItem('admin_apiKey');
            window.location.href = 'login.html';
        }
        throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    return await response.json();
}

