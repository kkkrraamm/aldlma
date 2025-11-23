// ============================================
// Theme Management for Dalma Admin Pro
// ============================================

document.addEventListener('DOMContentLoaded', function() {
    initializeTheme();
    setupThemeToggle();
});

function initializeTheme() {
    // Get saved theme or default to dark
    const savedTheme = localStorage.getItem('admin_theme') || 'dark';
    setTheme(savedTheme);
}

function setTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('admin_theme', theme);
    
    // Update theme toggle icon
    updateThemeIcon(theme);
}

function toggleTheme() {
    const currentTheme = document.documentElement.getAttribute('data-theme');
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
    setTheme(newTheme);
}

function updateThemeIcon(theme) {
    const themeIcons = document.querySelectorAll('.theme-toggle i, #themeToggle i');
    themeIcons.forEach(icon => {
        icon.className = theme === 'dark' ? 'fas fa-sun' : 'fas fa-moon';
    });
}

function setupThemeToggle() {
    // Setup theme toggle buttons
    const themeToggles = document.querySelectorAll('.theme-toggle, #themeToggle');
    themeToggles.forEach(toggle => {
        toggle.addEventListener('click', toggleTheme);
    });
}

// Auto-detect system theme preference
function getSystemTheme() {
    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
        return 'dark';
    }
    return 'light';
}

// Listen for system theme changes
if (window.matchMedia) {
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function(e) {
        if (!localStorage.getItem('admin_theme')) {
            setTheme(e.matches ? 'dark' : 'light');
        }
    });
}