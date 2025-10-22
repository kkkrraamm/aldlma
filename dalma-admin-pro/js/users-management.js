// Users Management Page
const API_URL = 'https://dalma-api.onrender.com';
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
        <tr>
            <td>
                <div class="user-cell">
                    <div class="user-avatar">${getInitials(user.name)}</div>
                    <div class="user-info">
                        <div class="user-name">${user.name}</div>
                        <div class="user-email">${user.email}</div>
                    </div>
                </div>
            </td>
            <td>
                <span class="badge ${user.role}">
                    ${getRoleLabel(user.role)}
                </span>
            </td>
            <td>
                <span class="badge ${user.status}">
                    ${getStatusLabel(user.status)}
                </span>
            </td>
            <td>${formatDate(user.created_at)}</td>
            <td>${formatTimeAgo(user.last_login)}</td>
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
function viewUser(user) {
    currentUser = user;
    const modal = document.getElementById('userModal');
    const modalBody = document.getElementById('modalBody');
    
    modalBody.innerHTML = `
        <div class="user-profile-header">
            <div class="user-profile-avatar">${getInitials(user.name)}</div>
            <div class="user-profile-info">
                <h2>${user.name}</h2>
                <p>${user.email}</p>
                <div class="profile-badges">
                    <span class="badge ${user.role}">${getRoleLabel(user.role)}</span>
                    <span class="badge ${user.status}">${getStatusLabel(user.status)}</span>
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
                <div class="info-value">${user.devices_count || 0} جهاز</div>
            </div>
            <div class="info-item">
                <div class="info-label">عدد الطلبات</div>
                <div class="info-value">${user.orders_count || 0} طلب</div>
            </div>
            <div class="info-item">
                <div class="info-label">معرّف المستخدم</div>
                <div class="info-value">#${user.id}</div>
            </div>
        </div>
    `;
    
    modal.classList.add('active');
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
    
    showToast('جاري فتح نموذج التعديل...', 'info');
    // TODO: Open edit form
    console.log('Edit user:', currentUser);
}

// Delete user
async function deleteUser(userId) {
    if (!confirm('هل أنت متأكد من حذف هذا المستخدم؟ هذا الإجراء لا يمكن التراجع عنه.')) {
        return;
    }
    
    try {
        console.log('🗑️ [USERS] حذف مستخدم:', userId);
        
        // Remove from local array (mock)
        allUsers = allUsers.filter(u => u.id !== userId);
        filteredUsers = filteredUsers.filter(u => u.id !== userId);
        
        updateStats();
        renderUsersTable();
        showToast('تم حذف المستخدم بنجاح', 'success');
        
        // TODO: Call API to delete user
        // await apiRequest(`/api/admin/users/${userId}`, { method: 'DELETE' });
        
    } catch (error) {
        console.error('❌ [USERS] خطأ في حذف المستخدم:', error);
        showToast('فشل حذف المستخدم', 'error');
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

