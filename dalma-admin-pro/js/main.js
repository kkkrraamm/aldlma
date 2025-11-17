// Main JavaScript for Dalma Admin Pro Dashboard
const API_URL = 'https://dalma-api.onrender.com';
let currentPage = 'dashboard';
let adminApiKey = '';
let adminToken = '';

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    console.log('🔧 [MAIN.JS] بدء التهيئة...');
    
    // Load credentials
    adminApiKey = localStorage.getItem('admin_apiKey') || '';
    adminToken = localStorage.getItem('admin_token') || '';
    
    console.log('🔧 [MAIN.JS] Credentials:', {
        token: adminToken ? 'موجود ✅' : 'غير موجود ❌',
        apiKey: adminApiKey ? 'موجود ✅' : 'غير موجود ❌'
    });
    
    // Don't redirect here - let index.html handle it
    // The check in index.html will run first
    
    initializeTheme();
    initializeSidebar();
    initializeNavigation();
    
    // Note: Dashboard loads its own content via dashboard.js
    // checkAuth(); // Disabled - will check on API calls instead
});

// Theme Management
function initializeTheme() {
    const theme = localStorage.getItem('theme') || 'light';
    document.documentElement.setAttribute('data-theme', theme);
    
    const themeToggle = document.getElementById('themeToggle');
    if (themeToggle) {
        updateThemeIcon(theme);
        
        themeToggle.addEventListener('click', () => {
            const currentTheme = document.documentElement.getAttribute('data-theme');
            const newTheme = currentTheme === 'light' ? 'dark' : 'light';
            document.documentElement.setAttribute('data-theme', newTheme);
            localStorage.setItem('theme', newTheme);
            updateThemeIcon(newTheme);
        });
    }
}

function updateThemeIcon(theme) {
    const icon = document.querySelector('#themeToggle i');
    if (icon) {
        icon.className = theme === 'light' ? 'fas fa-moon' : 'fas fa-sun';
    }
}

// Sidebar Management
function initializeSidebar() {
    const sidebar = document.getElementById('sidebar');
    const menuToggle = document.getElementById('menuToggle');
    const sidebarToggle = document.getElementById('sidebarToggle');
    
    menuToggle?.addEventListener('click', () => {
        sidebar.classList.toggle('active');
    });
    
    sidebarToggle?.addEventListener('click', () => {
        sidebar.classList.toggle('collapsed');
        localStorage.setItem('sidebar-collapsed', sidebar.classList.contains('collapsed'));
    });
    
    // Restore sidebar state
    if (localStorage.getItem('sidebar-collapsed') === 'true') {
        sidebar.classList.add('collapsed');
    }
}

// Navigation
function initializeNavigation() {
    const navItems = document.querySelectorAll('.nav-item');
    
    navItems.forEach(item => {
        item.addEventListener('click', (e) => {
            // Allow default navigation for links with href
            const href = item.getAttribute('href');
            if (href && href !== '#') {
                // Let the browser navigate normally
                return;
            }
            
            // Only prevent default for # links
            e.preventDefault();
            
            // Update active state
            navItems.forEach(nav => nav.classList.remove('active'));
            item.classList.add('active');
            
            // Close sidebar on mobile
            if (window.innerWidth <= 768) {
                document.getElementById('sidebar').classList.remove('active');
            }
        });
    });
}

// Notifications
function toggleNotifications() {
    const panel = document.getElementById('notificationPanel');
    panel.classList.toggle('active');
}

function closeNotifications() {
    document.getElementById('notificationPanel').classList.remove('active');
}

document.getElementById('notificationBtn')?.addEventListener('click', toggleNotifications);

// Logout
function logout() {
    if (confirm('هل أنت متأكد من تسجيل الخروج؟')) {
        localStorage.removeItem('admin_token');
        localStorage.removeItem('admin_username');
        localStorage.removeItem('admin_apiKey');
        console.log('👋 تم تسجيل الخروج');
        window.location.href = 'login.html';
    }
}

// Auth Check
async function checkAuth() {
    const token = localStorage.getItem('admin_token');
    const apiKey = localStorage.getItem('admin_apiKey');
    
    if (!token) {
        window.location.href = 'login.html';
        return;
    }
    
    try {
        console.log('🔐 [AUTH CHECK] التحقق من صلاحيات Admin...');
        
        const response = await fetch(`${API_URL}/api/admin/stats`, {
            headers: {
                'Authorization': `Bearer ${token}`,
                'X-API-Key': apiKey,
                'Content-Type': 'application/json'
            }
        });
        
        if (!response.ok) {
            console.error('❌ [AUTH CHECK] فشل التحقق:', response.status);
            throw new Error('Unauthorized');
        }
        
        console.log('✅ [AUTH CHECK] تم التحقق بنجاح');
    } catch (error) {
        console.error('❌ [AUTH CHECK] خطأ:', error);
        localStorage.removeItem('admin_token');
        localStorage.removeItem('admin_username');
        localStorage.removeItem('admin_apiKey');
        window.location.href = 'login.html';
    }
}

// Utility Functions
function formatDate(dateString) {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('ar-SA', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    }).format(date);
}

function formatCurrency(amount) {
    return new Intl.NumberFormat('ar-SA', {
        style: 'currency',
        currency: 'SAR'
    }).format(amount);
}

function showToast(message, type = 'info') {
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.textContent = message;
    document.body.appendChild(toast);
    
    setTimeout(() => {
        toast.classList.add('show');
    }, 100);
    
    setTimeout(() => {
        toast.classList.remove('show');
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

// API Helper with Security
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
    
    console.log(`📡 [API] ${options.method || 'GET'} ${endpoint}`);
    
    const response = await fetch(`${API_URL}${endpoint}`, {
        ...options,
        headers
    });
    
    if (!response.ok) {
        console.error(`❌ [API] ${response.status} ${response.statusText}`);
        if (response.status === 401 || response.status === 403) {
            console.error('❌ [API] Unauthorized - تحويل إلى صفحة تسجيل الدخول');
            localStorage.removeItem('admin_token');
            localStorage.removeItem('admin_username');
            localStorage.removeItem('admin_apiKey');
            window.location.href = 'login.html';
        }
        throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    console.log(`✅ [API] ${endpoint} نجح`);
    return await response.json();
}

