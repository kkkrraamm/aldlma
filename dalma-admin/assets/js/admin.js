const API_URL = 'https://dalma-api.onrender.com';

// Check authentication
function checkAuth() {
    const token = localStorage.getItem('adminToken');
    if (!token) {
        window.location.href = 'login.html';
        return false;
    }
    
    // Set admin name
    const username = localStorage.getItem('adminUsername');
    const adminNameEl = document.getElementById('adminName');
    if (adminNameEl && username) {
        adminNameEl.textContent = username;
    }
    
    return true;
}

// Logout
function logout() {
    if (confirm('هل أنت متأكد من تسجيل الخروج؟')) {
        localStorage.removeItem('adminToken');
        localStorage.removeItem('adminUsername');
        window.location.href = 'login.html';
    }
}

// API Request Helper
async function apiRequest(endpoint, options = {}) {
    const token = localStorage.getItem('adminToken');
    
    const defaultOptions = {
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
        }
    };
    
    const mergedOptions = {
        ...defaultOptions,
        ...options,
        headers: {
            ...defaultOptions.headers,
            ...options.headers
        }
    };
    
    try {
        const response = await fetch(`${API_URL}${endpoint}`, mergedOptions);
        
        if (response.status === 401) {
            logout();
            return null;
        }
        
        return response;
    } catch (error) {
        console.error('API Request Error:', error);
        throw error;
    }
}

// Show Toast Notification
function showToast(message, type = 'success') {
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.textContent = message;
    toast.style.cssText = `
        position: fixed;
        top: 20px;
        left: 50%;
        transform: translateX(-50%);
        background: ${type === 'success' ? '#10B981' : '#DC2626'};
        color: white;
        padding: 15px 30px;
        border-radius: 10px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.2);
        z-index: 10000;
        animation: slideDown 0.3s ease;
        font-family: Cairo, sans-serif;
        font-weight: 600;
    `;
    
    document.body.appendChild(toast);
    
    setTimeout(() => {
        toast.style.animation = 'slideUp 0.3s ease';
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

// Format Date
function formatDate(dateString) {
    const date = new Date(dateString);
    const now = new Date();
    const diff = now - date;
    
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);
    
    if (minutes < 1) return 'الآن';
    if (minutes < 60) return `منذ ${minutes} دقيقة`;
    if (hours < 24) return `منذ ${hours} ساعة`;
    if (days < 7) return `منذ ${days} يوم`;
    
    return date.toLocaleDateString('ar-SA', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });
}

// Format Phone Number
function formatPhone(phone) {
    if (!phone) return '-';
    if (phone.startsWith('+966')) return phone;
    if (phone.startsWith('966')) return '+' + phone;
    if (phone.startsWith('05')) return '+966' + phone.substring(1);
    return phone;
}

// Confirm Dialog
function confirmDialog(message) {
    return confirm(message);
}

// Toggle Dropdown Menu
function toggleDropdown(event, dropdownId) {
    event.preventDefault();
    event.stopPropagation();
    
    const dropdown = document.getElementById(dropdownId);
    if (!dropdown) return;
    
    const parent = dropdown.parentElement;
    const isOpen = parent.classList.contains('open');
    
    // Close all other dropdowns
    document.querySelectorAll('.nav-dropdown').forEach(d => {
        d.classList.remove('open');
    });
    
    // Toggle current dropdown
    if (!isOpen) {
        parent.classList.add('open');
    }
}

// Close dropdowns when clicking outside
document.addEventListener('click', (event) => {
    if (!event.target.closest('.nav-dropdown')) {
        document.querySelectorAll('.nav-dropdown').forEach(d => {
            d.classList.remove('open');
        });
    }
});

// Initialize
if (window.location.pathname.includes('dashboard.html') ||
    window.location.pathname.includes('users.html') ||
    window.location.pathname.includes('media-requests.html') ||
    window.location.pathname.includes('posts.html') ||
    window.location.pathname.includes('orders.html')) {
    checkAuth();
}

// Add CSS animations
const style = document.createElement('style');
style.textContent = `
    @keyframes slideDown {
        from {
            opacity: 0;
            transform: translate(-50%, -20px);
        }
        to {
            opacity: 1;
            transform: translate(-50%, 0);
        }
    }
    
    @keyframes slideUp {
        from {
            opacity: 1;
            transform: translate(-50%, 0);
        }
        to {
            opacity: 0;
            transform: translate(-50%, -20px);
        }
    }
`;
document.head.appendChild(style);

