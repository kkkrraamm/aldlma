// 🔐 Admin Authentication System
// هذا الملف يدير المصادقة في جميع صفحات Admin Dashboard

const API_URL = 'https://dalma-api.onrender.com';

// 🔒 Security: API Key (يتم الحصول عليه من السيرفر بعد تسجيل الدخول)
let API_KEY = null;

// الحصول على API Key من localStorage
function getApiKey() {
    if (!API_KEY) {
        API_KEY = localStorage.getItem('apiKey');
    }
    return API_KEY;
}

// حفظ API Key
function setApiKey(key) {
    API_KEY = key;
    localStorage.setItem('apiKey', key);
}

// التحقق من تسجيل الدخول
function checkAuth() {
    const token = localStorage.getItem('adminToken');
    const currentPage = window.location.pathname.split('/').pop();
    
    // السماح بصفحة تسجيل الدخول
    if (currentPage === 'login.html' || currentPage === '') {
        // إذا كان مسجل دخول، انتقل إلى Dashboard
        if (token) {
            window.location.href = 'dashboard.html';
        }
        return;
    }
    
    // التحقق من وجود Token
    if (!token) {
        console.warn('⚠️ لم يتم العثور على token - إعادة توجيه إلى صفحة تسجيل الدخول');
        window.location.href = 'login.html';
        return;
    }
    
    // التحقق من صلاحية Token
    try {
        const payload = parseJwt(token);
        const now = Date.now() / 1000;
        
        if (payload.exp && payload.exp < now) {
            console.warn('⚠️ انتهت صلاحية الجلسة - يرجى تسجيل الدخول مرة أخرى');
            logout();
            return;
        }
        
        // عرض اسم المشرف
        const adminNameElement = document.getElementById('adminName');
        if (adminNameElement && payload.username) {
            adminNameElement.textContent = payload.username;
        }
        
        console.log('✅ تم التحقق من المصادقة بنجاح');
    } catch (error) {
        console.error('❌ خطأ في التحقق من Token:', error);
        logout();
    }
}

// فك تشفير JWT Token
function parseJwt(token) {
    try {
        const base64Url = token.split('.')[1];
        const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
        const jsonPayload = decodeURIComponent(atob(base64).split('').map(function(c) {
            return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
        }).join(''));
        return JSON.parse(jsonPayload);
    } catch (error) {
        throw new Error('Invalid token format');
    }
}

// تسجيل الخروج
function logout() {
    localStorage.removeItem('adminToken');
    localStorage.removeItem('adminUsername');
    localStorage.removeItem('apiKey');
    API_KEY = null;
    window.location.href = 'login.html';
}

// إضافة Token إلى جميع الطلبات
function getAuthHeaders() {
    const token = localStorage.getItem('adminToken');
    const apiKey = getApiKey();
    return {
        'Content-Type': 'application/json',
        'Authorization': token ? `Bearer ${token}` : '',
        'X-API-Key': apiKey || '',
        'X-Device-ID': 'admin-dashboard'
    };
}

// Fetch مع المصادقة
async function authenticatedFetch(url, options = {}) {
    const token = localStorage.getItem('adminToken');
    
    if (!token) {
        console.error('❌ لا يوجد token - يرجى تسجيل الدخول');
        window.location.href = 'login.html';
        return;
    }
    
    // إضافة Authorization header + Security Headers
    const apiKey = getApiKey();
    options.headers = {
        ...options.headers,
        'Authorization': `Bearer ${token}`,
        'X-API-Key': apiKey || '',
        'X-Device-ID': 'admin-dashboard'
    };
    
    // إضافة Content-Type إذا كان هناك body
    if (options.body && typeof options.body === 'object' && !(options.body instanceof FormData)) {
        options.headers['Content-Type'] = 'application/json';
        options.body = JSON.stringify(options.body);
    }
    
    try {
        const response = await fetch(url, options);
        
        // التحقق من أخطاء المصادقة
        if (response.status === 401 || response.status === 403) {
            console.error('❌ خطأ في المصادقة - إعادة توجيه إلى صفحة تسجيل الدخول');
            logout();
            return;
        }
        
        return response;
    } catch (error) {
        console.error('❌ خطأ في الاتصال:', error);
        throw error;
    }
}

// تشغيل التحقق عند تحميل الصفحة
document.addEventListener('DOMContentLoaded', () => {
    checkAuth();
});

// تصدير الدوال للاستخدام في ملفات أخرى
window.adminAuth = {
    checkAuth,
    logout,
    getAuthHeaders,
    authenticatedFetch,
    parseJwt
};

