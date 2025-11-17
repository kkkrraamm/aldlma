// ==================== UNIFIED TOP BAR ====================
// Modern top bar with page title, sidebar toggle, and settings

function renderTopBar(pageTitle) {
    const topBarHTML = `
        <div class="top-bar">
            <div class="top-bar-left">
                <button class="sidebar-toggle-btn" onclick="toggleSidebar()">
                    <i class="fas fa-bars"></i>
                </button>
                <h1 class="page-title">${pageTitle}</h1>
            </div>
            
            <div class="top-bar-right">
                <!-- Search (optional) -->
                <button class="top-bar-icon-btn" onclick="toggleSearch()" title="بحث">
                    <i class="fas fa-search"></i>
                </button>
                
                <!-- Notifications -->
                <button class="top-bar-icon-btn" onclick="showNotifications()" title="الإشعارات">
                    <i class="fas fa-bell"></i>
                    <span class="notification-badge">3</span>
                </button>
                
                <!-- Theme Toggle -->
                <button class="top-bar-icon-btn" onclick="toggleTheme()" title="تبديل الثيم">
                    <i class="fas fa-moon theme-icon"></i>
                </button>
                
                <!-- Settings -->
                <button class="top-bar-icon-btn" onclick="showSettings()" title="الإعدادات">
                    <i class="fas fa-cog"></i>
                </button>
                
                <!-- User Menu -->
                <div class="user-menu-container">
                    <button class="user-menu-btn" onclick="toggleUserMenu()">
                        <div class="user-avatar">
                            <i class="fas fa-user"></i>
                        </div>
                        <span class="user-name">Admin</span>
                        <i class="fas fa-chevron-down"></i>
                    </button>
                    
                    <div class="user-dropdown" id="userDropdown">
                        <a href="profile.html" class="dropdown-item">
                            <i class="fas fa-user"></i>
                            <span>الملف الشخصي</span>
                        </a>
                        <a href="settings.html" class="dropdown-item">
                            <i class="fas fa-cog"></i>
                            <span>الإعدادات</span>
                        </a>
                        <div class="dropdown-divider"></div>
                        <a href="#" onclick="logout()" class="dropdown-item logout">
                            <i class="fas fa-sign-out-alt"></i>
                            <span>تسجيل الخروج</span>
                        </a>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Search Overlay (hidden by default) -->
        <div class="search-overlay" id="searchOverlay">
            <div class="search-container">
                <input type="text" class="search-input" placeholder="ابحث عن أي شيء..." autofocus>
                <button class="search-close-btn" onclick="toggleSearch()">
                    <i class="fas fa-times"></i>
                </button>
            </div>
        </div>
    `;
    
    // Insert at the beginning of body
    const topBarContainer = document.createElement('div');
    topBarContainer.innerHTML = topBarHTML;
    document.body.insertBefore(topBarContainer.firstElementChild, document.body.firstChild);
    
    // Initialize theme icon
    updateThemeIcon();
    
    // Load user info
    loadUserInfo();
}

// Toggle Sidebar
function toggleSidebar() {
    const sidebar = document.getElementById('sidebar');
    const mainContent = document.querySelector('.main-content');
    
    if (sidebar && mainContent) {
        sidebar.classList.toggle('collapsed');
        mainContent.classList.toggle('expanded');
        
        // Save state
        const isCollapsed = sidebar.classList.contains('collapsed');
        localStorage.setItem('sidebarCollapsed', isCollapsed);
        
        // Update toggle icon
        const toggleBtn = document.querySelector('.sidebar-toggle-btn i');
        if (toggleBtn) {
            toggleBtn.className = isCollapsed ? 'fas fa-bars' : 'fas fa-times';
        }
    }
}

// Toggle Search
function toggleSearch() {
    const searchOverlay = document.getElementById('searchOverlay');
    if (searchOverlay) {
        searchOverlay.classList.toggle('active');
        if (searchOverlay.classList.contains('active')) {
            searchOverlay.querySelector('.search-input')?.focus();
        }
    }
}

// Show Notifications
function showNotifications() {
    // TODO: Implement notifications panel
    console.log('📢 Show notifications');
    showToast('الإشعارات قريباً', 'info');
}

// Show Settings
function showSettings() {
    window.location.href = 'settings.html';
}

// Toggle Theme
function toggleTheme() {
    const currentTheme = document.documentElement.getAttribute('data-theme') || 'light';
    const newTheme = currentTheme === 'light' ? 'dark' : 'light';
    
    document.documentElement.setAttribute('data-theme', newTheme);
    localStorage.setItem('theme', newTheme);
    
    updateThemeIcon();
    
    console.log(`🎨 Theme changed to: ${newTheme}`);
}

// Update Theme Icon
function updateThemeIcon() {
    const theme = document.documentElement.getAttribute('data-theme') || 'light';
    const themeIcon = document.querySelector('.theme-icon');
    
    if (themeIcon) {
        themeIcon.className = theme === 'light' ? 'fas fa-moon theme-icon' : 'fas fa-sun theme-icon';
    }
}

// Toggle User Menu
function toggleUserMenu() {
    const dropdown = document.getElementById('userDropdown');
    if (dropdown) {
        dropdown.classList.toggle('active');
    }
}

// Close user menu when clicking outside
document.addEventListener('click', (e) => {
    const userMenu = document.querySelector('.user-menu-container');
    const dropdown = document.getElementById('userDropdown');
    
    if (userMenu && dropdown && !userMenu.contains(e.target)) {
        dropdown.classList.remove('active');
    }
});

// Load User Info
function loadUserInfo() {
    const userName = localStorage.getItem('admin_name') || 'Admin';
    const userNameEl = document.querySelector('.user-name');
    
    if (userNameEl) {
        userNameEl.textContent = userName;
    }
}

// Logout
function logout() {
    if (confirm('هل أنت متأكد من تسجيل الخروج؟')) {
        localStorage.removeItem('admin_token');
        localStorage.removeItem('admin_apiKey');
        localStorage.removeItem('admin_name');
        window.location.href = 'login.html';
    }
}

// Initialize sidebar state on page load
document.addEventListener('DOMContentLoaded', () => {
    const isCollapsed = localStorage.getItem('sidebarCollapsed') === 'true';
    const sidebar = document.getElementById('sidebar');
    const mainContent = document.querySelector('.main-content');
    
    if (isCollapsed && sidebar && mainContent) {
        sidebar.classList.add('collapsed');
        mainContent.classList.add('expanded');
    }
});

// Toast notification helper
function showToast(message, type = 'success') {
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.innerHTML = `
        <i class="fas fa-${type === 'success' ? 'check-circle' : type === 'error' ? 'exclamation-circle' : 'info-circle'}"></i>
        <span>${message}</span>
    `;
    
    document.body.appendChild(toast);
    
    setTimeout(() => toast.classList.add('show'), 100);
    setTimeout(() => {
        toast.classList.remove('show');
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

