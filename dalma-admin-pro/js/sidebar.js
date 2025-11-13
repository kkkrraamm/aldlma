// Unified Sidebar Component for Dalma Admin Pro
// This file creates a consistent sidebar across all pages

function createUnifiedSidebar() {
    const sidebarHTML = `
    <aside class="sidebar" id="sidebar">
        <!-- Logo -->
        <div class="sidebar-header">
            <div class="logo">
                <i class="fas fa-shield-alt"></i>
                <span class="logo-text">Dalma Admin Pro</span>
            </div>
            <button class="btn-icon" id="sidebarToggle">
                <i class="fas fa-chevron-right"></i>
            </button>
        </div>

        <!-- Navigation -->
        <nav class="sidebar-nav">
            <!-- Dashboard -->
            <div class="nav-section">
                <span class="nav-section-title">الرئيسية</span>
                <a href="index.html" class="nav-item" data-page="dashboard">
                    <i class="fas fa-chart-line"></i>
                    <span>لوحة التحكم</span>
                </a>
            </div>

            <!-- Security -->
            <div class="nav-section">
                <span class="nav-section-title">الأمن السيبراني</span>
                <a href="ip-management.html" class="nav-item" data-page="ip-management">
                    <i class="fas fa-network-wired"></i>
                    <span>إدارة IPs</span>
                </a>
                <a href="security-monitoring.html" class="nav-item" data-page="security-monitoring">
                    <i class="fas fa-shield-virus"></i>
                    <span>مراقبة الأمان</span>
                </a>
                <a href="roles-management.html" class="nav-item" data-page="roles-management">
                    <i class="fas fa-user-shield"></i>
                    <span>الأدوار والصلاحيات</span>
                </a>
            </div>

            <!-- Users -->
            <div class="nav-section">
                <span class="nav-section-title">المستخدمين</span>
                <a href="users-management.html" class="nav-item" data-page="users-management">
                    <i class="fas fa-users"></i>
                    <span>جميع المستخدمين</span>
                </a>
            </div>

            <!-- Requests -->
            <div class="nav-section">
                <span class="nav-section-title">الطلبات</span>
                <a href="requests-management.html" class="nav-item" data-page="requests-management">
                    <i class="fas fa-file-alt"></i>
                    <span>إدارة الطلبات</span>
                    <span class="badge badge-warning" id="pendingRequestsBadge">0</span>
                </a>
            </div>

            <!-- Realty System -->
            <div class="nav-section">
                <span class="nav-section-title">نظام العقار</span>
                <a href="office-registrations.html" class="nav-item" data-page="office-registrations">
                    <i class="fas fa-building"></i>
                    <span>طلبات المكاتب العقارية</span>
                    <span class="badge badge-warning" id="officeRequestsBadge">0</span>
                </a>
                <a href="realty-subscriptions.html" class="nav-item" data-page="realty-subscriptions">
                    <i class="fas fa-chart-line"></i>
                    <span>إدارة الاشتراكات المالية</span>
                </a>
            </div>

            <!-- Finance -->
            <div class="nav-section">
                <span class="nav-section-title">المالية</span>
                <a href="finance-monitoring.html" class="nav-item" data-page="finance-monitoring">
                    <i class="fas fa-dollar-sign"></i>
                    <span>الرقابة المالية</span>
                </a>
            </div>

            <!-- Content & Marketing -->
            <div class="nav-section">
                <span class="nav-section-title">المحتوى والتسويق</span>
                <a href="content-management.html" class="nav-item" data-page="content-management">
                    <i class="fas fa-bullhorn"></i>
                    <span>إدارة المحتوى</span>
                </a>
                <a href="notifications.html" class="nav-item" data-page="notifications">
                    <i class="fas fa-bell"></i>
                    <span>الإشعارات</span>
                </a>
            </div>

            <!-- Analytics & Reports -->
            <div class="nav-section">
                <span class="nav-section-title">التحليلات</span>
                <a href="reports.html" class="nav-item" data-page="reports">
                    <i class="fas fa-chart-bar"></i>
                    <span>التقارير</span>
                </a>
                <a href="ai-analytics.html" class="nav-item" data-page="ai-analytics">
                    <i class="fas fa-brain"></i>
                    <span>التحليلات الذكية</span>
                </a>
            </div>

            <!-- App Settings -->
            <div class="nav-section">
                <span class="nav-section-title">الإعدادات</span>
                <a href="settings.html" class="nav-item" data-page="settings">
                    <i class="fas fa-cog"></i>
                    <span>الإعدادات العامة</span>
                </a>
            </div>
        </nav>

        <div class="sidebar-footer">
            <div class="user-info">
                <div class="user-avatar">
                    <i class="fas fa-user-shield"></i>
                </div>
                <div class="user-details">
                    <div class="user-name" id="adminName">المشرف العام</div>
                    <div class="user-role">Super Admin</div>
                </div>
            </div>
            <button class="btn-logout" onclick="logout()">
                <i class="fas fa-sign-out-alt"></i>
            </button>
        </div>
    </aside>
    `;
    
    return sidebarHTML;
}

// Initialize sidebar on page load
function initUnifiedSidebar() {
    console.log('🎨 [SIDEBAR] تهيئة القائمة الموحدة...');
    
    // Check if sidebar container exists
    let sidebarContainer = document.getElementById('sidebarContainer');
    
    // If no container, create one at the beginning of body
    if (!sidebarContainer) {
        sidebarContainer = document.createElement('div');
        sidebarContainer.id = 'sidebarContainer';
        document.body.insertBefore(sidebarContainer, document.body.firstChild);
    }
    
    // Insert sidebar HTML
    sidebarContainer.innerHTML = createUnifiedSidebar();
    
    // Set active page based on current URL
    setActivePage();
    
    // Update admin name from localStorage
    updateAdminInfo();
    
    // Fetch and update pending requests count
    updatePendingRequestsCount();
    
    // Initialize sidebar interactions
    initializeSidebarInteractions();
    
    console.log('✅ [SIDEBAR] تم تهيئة القائمة بنجاح');
}

// Set active page based on current URL
function setActivePage() {
    const currentPage = window.location.pathname.split('/').pop() || 'index.html';
    const navItems = document.querySelectorAll('.nav-item');
    
    navItems.forEach(item => {
        const href = item.getAttribute('href');
        if (href === currentPage) {
            item.classList.add('active');
        } else {
            item.classList.remove('active');
        }
    });
}

// Update admin info from localStorage
function updateAdminInfo() {
    const adminUsername = localStorage.getItem('admin_username');
    if (adminUsername) {
        const adminNameEl = document.getElementById('adminName');
        if (adminNameEl) {
            adminNameEl.textContent = adminUsername;
        }
    }
}

// Update pending requests count dynamically
async function updatePendingRequestsCount() {
    try {
        const API_URL = 'https://dalma-api.onrender.com';
        const adminToken = localStorage.getItem('admin_token');
        const adminApiKey = localStorage.getItem('admin_apiKey');
        
        if (!adminToken || !adminApiKey) return;
        
        const response = await fetch(`${API_URL}/api/admin/stats`, {
            headers: {
                'Authorization': `Bearer ${adminToken}`,
                'x-api-key': adminApiKey
            }
        });
        
        if (response.ok) {
            const stats = await response.json();
            const badge = document.getElementById('pendingRequestsBadge');
            if (badge && stats.pendingRequests) {
                badge.textContent = stats.pendingRequests;
                badge.style.display = stats.pendingRequests > 0 ? 'inline-block' : 'none';
            }
        }
    } catch (error) {
        console.error('❌ [SIDEBAR] خطأ في جلب عدد الطلبات:', error);
    }
}

// Initialize sidebar interactions
function initializeSidebarInteractions() {
    const sidebar = document.getElementById('sidebar');
    const sidebarToggle = document.getElementById('sidebarToggle');
    const menuToggle = document.getElementById('menuToggle');
    
    // Toggle sidebar collapse
    if (sidebarToggle) {
        sidebarToggle.addEventListener('click', () => {
            sidebar.classList.toggle('collapsed');
            localStorage.setItem('sidebar-collapsed', sidebar.classList.contains('collapsed'));
        });
    }
    
    // Mobile menu toggle
    if (menuToggle) {
        menuToggle.addEventListener('click', () => {
            sidebar.classList.toggle('active');
        });
    }
    
    // Restore sidebar state
    if (localStorage.getItem('sidebar-collapsed') === 'true') {
        sidebar.classList.add('collapsed');
    }
    
    // Close sidebar on mobile when clicking outside
    document.addEventListener('click', (e) => {
        if (window.innerWidth <= 768) {
            if (!sidebar.contains(e.target) && !menuToggle?.contains(e.target)) {
                sidebar.classList.remove('active');
            }
        }
    });
    
    // Update active state on navigation
    const navItems = document.querySelectorAll('.nav-item');
    navItems.forEach(item => {
        item.addEventListener('click', () => {
            // Close sidebar on mobile
            if (window.innerWidth <= 768) {
                sidebar.classList.remove('active');
            }
        });
    });
}

// Auto-initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initUnifiedSidebar);
} else {
    initUnifiedSidebar();
}

// Refresh pending requests count every 30 seconds
setInterval(updatePendingRequestsCount, 30000);


