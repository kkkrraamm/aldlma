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
                    <i class="fas fa-building"></i>
                    <span>Dalma Admin</span>
                </div>
                <button class="sidebar-toggle" onclick="toggleSidebar()">
                    <i class="fas fa-times"></i>
                </button>
            </div>

            <div class="sidebar-menu">
                <ul>
                    <li>
                        <a href="dashboard.html" class="menu-item">
                            <i class="fas fa-tachometer-alt"></i>
                            <span>لوحة التحكم</span>
                        </a>
                    </li>
                    <li>
                        <a href="users-management.html" class="menu-item">
                            <i class="fas fa-users"></i>
                            <span>إدارة المستخدمين</span>
                        </a>
                    </li>
                    <li>
                        <a href="categories-management.html" class="menu-item">
                            <i class="fas fa-tags"></i>
                            <span>إدارة الفئات</span>
                        </a>
                    </li>
                    <li>
                        <a href="offices-management.html" class="menu-item">
                            <i class="fas fa-building"></i>
                            <span>إدارة المكاتب</span>
                        </a>
                    </li>
                    <li>
                        <a href="ads-management.html" class="menu-item">
                            <i class="fas fa-ad"></i>
                            <span>إدارة الإعلانات</span>
                        </a>
                    </li>
                    <li>
                        <a href="finance-monitoring.html" class="menu-item">
                            <i class="fas fa-chart-line"></i>
                            <span>المراقبة المالية</span>
                        </a>
                    </li>
                    <li>
                        <a href="reports.html" class="menu-item">
                            <i class="fas fa-file-alt"></i>
                            <span>التقارير</span>
                        </a>
                    </li>
                    <li>
                        <a href="settings.html" class="menu-item">
                            <i class="fas fa-cog"></i>
                            <span>الإعدادات</span>
                        </a>
                    </li>
                </ul>
            </div>

            <div class="sidebar-footer">
                <div class="user-info">
                    <i class="fas fa-user-circle"></i>
                    <span>مدير النظام</span>
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