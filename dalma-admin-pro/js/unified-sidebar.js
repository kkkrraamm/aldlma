// ============================================
// Unified Sidebar for Dalma Admin Pro
// ============================================

document.addEventListener('DOMContentLoaded', function() {
    loadSidebar();
});

function loadSidebar() {
    const sidebarContainer = document.getElementById('sidebarContainer');
    if (!sidebarContainer) return;

    const sidebarHTML = `
        <nav class="sidebar" id="sidebar">
            <div class="sidebar-header">
                <div class="logo">
                    <i class="fas fa-shield-alt"></i>
                    <span>Dalma Admin Pro</span>
                </div>
                <button class="sidebar-toggle" onclick="toggleSidebar()">
                    <i class="fas fa-times"></i>
                </button>
            </div>

            <div class="sidebar-menu">
                <ul>
                    <!-- Dashboard -->
                    <li class="nav-section">
                        <span class="nav-section-title">الرئيسية</span>
                    </li>
                    <li>
                        <a href="dashboard.html" class="menu-item">
                            <i class="fas fa-tachometer-alt"></i>
                            <span>لوحة التحكم</span>
                        </a>
                    </li>

                    <!-- Security -->
                    <li class="nav-section">
                        <span class="nav-section-title">الأمن السيبراني</span>
                    </li>
                    <li>
                        <a href="ip-management.html" class="menu-item">
                            <i class="fas fa-network-wired"></i>
                            <span>إدارة IPs</span>
                        </a>
                    </li>
                    <li>
                        <a href="security-monitoring.html" class="menu-item">
                            <i class="fas fa-shield-virus"></i>
                            <span>مراقبة الأمان</span>
                        </a>
                    </li>
                    <li>
                        <a href="roles-management.html" class="menu-item">
                            <i class="fas fa-user-shield"></i>
                            <span>الأدوار والصلاحيات</span>
                        </a>
                    </li>

                    <!-- Users -->
                    <li class="nav-section">
                        <span class="nav-section-title">المستخدمين</span>
                    </li>
                    <li>
                        <a href="users-management.html" class="menu-item">
                            <i class="fas fa-users"></i>
                            <span>إدارة المستخدمين</span>
                        </a>
                    </li>

                    <!-- Categories -->
                    <li class="nav-section">
                        <span class="nav-section-title">التصنيفات</span>
                    </li>
                    <li>
                        <a href="categories-management.html" class="menu-item">
                            <i class="fas fa-tags"></i>
                            <span>إدارة الفئات</span>
                        </a>
                    </li>

                    <!-- Requests -->
                    <li class="nav-section">
                        <span class="nav-section-title">الطلبات</span>
                    </li>
                    <li>
                        <a href="requests-management.html" class="menu-item">
                            <i class="fas fa-file-alt"></i>
                            <span>إدارة الطلبات</span>
                            <span class="badge badge-warning">0</span>
                        </a>
                    </li>

                    <!-- Realty System -->
                    <li class="nav-section">
                        <span class="nav-section-title">نظام العقار</span>
                    </li>
                    <li>
                        <a href="office-registrations.html" class="menu-item">
                            <i class="fas fa-building"></i>
                            <span>طلبات المكاتب العقارية</span>
                            <span class="badge badge-warning">0</span>
                        </a>
                    </li>
                    <li>
                        <a href="offices-management.html" class="menu-item">
                            <i class="fas fa-building"></i>
                            <span>إدارة المكاتب النشطة</span>
                        </a>
                    </li>
                    <li>
                        <a href="upgrade-requests.html" class="menu-item">
                            <i class="fas fa-arrow-up"></i>
                            <span>طلبات الترقية</span>
                            <span class="badge badge-warning">0</span>
                        </a>
                    </li>
                    <li>
                        <a href="realty-subscriptions.html" class="menu-item">
                            <i class="fas fa-chart-line"></i>
                            <span>إدارة الاشتراكات المالية</span>
                        </a>
                    </li>

                    <!-- Finance -->
                    <li class="nav-section">
                        <span class="nav-section-title">المالية</span>
                    </li>
                    <li>
                        <a href="finance-monitoring.html" class="menu-item">
                            <i class="fas fa-dollar-sign"></i>
                            <span>الرقابة المالية</span>
                        </a>
                    </li>

                    <!-- Content & Marketing -->
                    <li class="nav-section">
                        <span class="nav-section-title">المحتوى والتسويق</span>
                    </li>
                    <li>
                        <a href="ads-management.html" class="menu-item">
                            <i class="fas fa-ad"></i>
                            <span>إدارة الإعلانات</span>
                        </a>
                    </li>
                    <li>
                        <a href="content-management.html" class="menu-item">
                            <i class="fas fa-bullhorn"></i>
                            <span>إدارة المحتوى</span>
                        </a>
                    </li>
                    <li>
                        <a href="notifications.html" class="menu-item">
                            <i class="fas fa-bell"></i>
                            <span>الإشعارات</span>
                        </a>
                    </li>

                    <!-- Analytics & Reports -->
                    <li class="nav-section">
                        <span class="nav-section-title">التحليلات</span>
                    </li>
                    <li>
                        <a href="reports.html" class="menu-item">
                            <i class="fas fa-chart-bar"></i>
                            <span>التقارير</span>
                        </a>
                    </li>
                    <li>
                        <a href="ai-analytics.html" class="menu-item">
                            <i class="fas fa-brain"></i>
                            <span>التحليلات الذكية</span>
                        </a>
                    </li>

                    <!-- App Settings -->
                    <li class="nav-section">
                        <span class="nav-section-title">الإعدادات</span>
                    </li>
                    <li>
                        <a href="settings.html" class="menu-item">
                            <i class="fas fa-cog"></i>
                            <span>الإعدادات العامة</span>
                        </a>
                    </li>
                </ul>
            </div>

            <div class="sidebar-footer">
                <div class="user-info">
                    <div class="user-avatar">
                        <i class="fas fa-user-shield"></i>
                    </div>
                    <div class="user-details">
                        <div class="user-name">kima</div>
                        <div class="user-role">Super Admin</div>
                    </div>
                </div>
                <button class="logout-btn" onclick="logout()">
                    <i class="fas fa-sign-out-alt"></i>
                    تسجيل خروج
                </button>
            </div>
        </nav>
        
        <div class="sidebar-overlay" onclick="closeSidebar()"></div>
    `;

    sidebarContainer.innerHTML = sidebarHTML;
    
    // Mark current page as active
    markCurrentPage();
}

function markCurrentPage() {
    const currentPage = window.location.pathname.split('/').pop();
    const menuItems = document.querySelectorAll('.menu-item');
    
    menuItems.forEach(item => {
        const href = item.getAttribute('href');
        if (href === currentPage) {
            item.classList.add('active');
        }
    });
}

function toggleSidebar() {
    const sidebar = document.getElementById('sidebar');
    const overlay = document.querySelector('.sidebar-overlay');
    
    sidebar.classList.toggle('active');
    overlay.classList.toggle('active');
    document.body.classList.toggle('sidebar-open');
}

function closeSidebar() {
    const sidebar = document.getElementById('sidebar');
    const overlay = document.querySelector('.sidebar-overlay');
    
    sidebar.classList.remove('active');
    overlay.classList.remove('active');
    document.body.classList.remove('sidebar-open');
}

function logout() {
    if (confirm('هل تريد تسجيل الخروج؟')) {
        localStorage.removeItem('admin_token');
        window.location.href = 'login.html';
    }
}

// Mobile sidebar toggle
document.addEventListener('click', function(e) {
    if (e.target.matches('.sidebar-toggle, .sidebar-toggle *')) {
        toggleSidebar();
    }
});