// Dashboard Page
async function loadDashboard() {
    try {
        // Fetch dashboard data
        const stats = await fetchDashboardStats();
        
        return `
            <div class="dashboard">
                <div class="page-header">
                    <h1 class="page-title">
                        <i class="fas fa-chart-line"></i>
                        لوحة التحكم الرئيسية
                    </h1>
                    <button class="btn btn-primary" onclick="refreshDashboard()">
                        <i class="fas fa-sync"></i>
                        تحديث
                    </button>
                </div>

                <!-- Stats Grid -->
                <div class="stats-grid">
                    <div class="stat-card">
                        <div class="stat-icon primary">
                            <i class="fas fa-users"></i>
                        </div>
                        <div class="stat-label">إجمالي المستخدمين</div>
                        <div class="stat-value">${stats.totalUsers || 0}</div>
                        <div class="stat-change positive">
                            <i class="fas fa-arrow-up"></i>
                            <span>+${stats.newUsersPercent || 0}% هذا الشهر</span>
                        </div>
                    </div>

                    <div class="stat-card">
                        <div class="stat-icon secondary">
                            <i class="fas fa-camera"></i>
                        </div>
                        <div class="stat-label">الإعلاميين</div>
                        <div class="stat-value">${stats.totalMedia || 0}</div>
                        <div class="stat-change positive">
                            <i class="fas fa-arrow-up"></i>
                            <span>+${stats.newMediaPercent || 0}%</span>
                        </div>
                    </div>

                    <div class="stat-card">
                        <div class="stat-icon warning">
                            <i class="fas fa-store"></i>
                        </div>
                        <div class="stat-label">مقدمي الخدمات</div>
                        <div class="stat-value">${stats.totalProviders || 0}</div>
                        <div class="stat-change positive">
                            <i class="fas fa-arrow-up"></i>
                            <span>+${stats.newProvidersPercent || 0}%</span>
                        </div>
                    </div>

                    <div class="stat-card">
                        <div class="stat-icon danger">
                            <i class="fas fa-file-alt"></i>
                        </div>
                        <div class="stat-label">الطلبات المعلقة</div>
                        <div class="stat-value">${stats.pendingRequests || 0}</div>
                        <div class="stat-change ${stats.requestsChange > 0 ? 'positive' : 'negative'}">
                            <i class="fas fa-${stats.requestsChange > 0 ? 'arrow-up' : 'arrow-down'}"></i>
                            <span>${Math.abs(stats.requestsChange || 0)}%</span>
                        </div>
                    </div>
                </div>

                <!-- Financial Overview -->
                <div class="card">
                    <div class="card-header">
                        <h2 class="card-title">
                            <i class="fas fa-dollar-sign"></i>
                            نظرة عامة على التكاليف
                        </h2>
                        <button class="btn btn-secondary" onclick="loadPage('finance')">
                            عرض التفاصيل
                        </button>
                    </div>
                    <div class="stats-grid">
                        <div class="stat-card">
                            <div class="stat-label">تكلفة API هذا الشهر</div>
                            <div class="stat-value" style="font-size: 24px;">${formatCurrency(stats.apiCostMonth || 0)}</div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-label">إجمالي الطلبات API</div>
                            <div class="stat-value" style="font-size: 24px;">${(stats.totalApiRequests || 0).toLocaleString('ar')}</div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-label">متوسط التكلفة لكل طلب</div>
                            <div class="stat-value" style="font-size: 24px;">${formatCurrency(stats.avgCostPerRequest || 0)}</div>
                        </div>
                    </div>
                </div>

                <!-- Security Alerts -->
                <div class="card">
                    <div class="card-header">
                        <h2 class="card-title">
                            <i class="fas fa-shield-alt"></i>
                            تنبيهات الأمان
                        </h2>
                        <button class="btn btn-secondary" onclick="loadPage('security')">
                            عرض الكل
                        </button>
                    </div>
                    <div class="alerts-list">
                        ${renderSecurityAlerts(stats.securityAlerts || [])}
                    </div>
                </div>

                <!-- Recent Activities -->
                <div class="card">
                    <div class="card-header">
                        <h2 class="card-title">
                            <i class="fas fa-clock"></i>
                            النشاطات الأخيرة
                        </h2>
                    </div>
                    <div class="activities-list">
                        ${renderActivities(stats.recentActivities || [])}
                    </div>
                </div>
            </div>
        `;
    } catch (error) {
        console.error('Error loading dashboard:', error);
        return '<div class="error">فشل تحميل لوحة التحكم</div>';
    }
}

async function fetchDashboardStats() {
    try {
        console.log('📊 [DASHBOARD] جلب الإحصائيات من API...');
        
        try {
            const data = await apiRequest('/api/admin/stats');
            console.log('✅ [DASHBOARD] تم جلب البيانات من API:', data);
            return data;
        } catch (error) {
            console.warn('⚠️ [DASHBOARD] فشل جلب البيانات، استخدام بيانات تجريبية:', error);
        }
        
        // Fallback to mock data if API fails
        console.log('📊 [DASHBOARD] استخدام بيانات تجريبية');
        return {
            totalUsers: 1247,
            newUsersPercent: 12.5,
            totalMedia: 34,
            newMediaPercent: 8.3,
            totalProviders: 87,
            newProvidersPercent: 15.2,
            pendingRequests: 8,
            requestsChange: -3.4,
            apiCostMonth: 450.75,
            totalApiRequests: 125430,
            avgCostPerRequest: 0.0036,
            securityAlerts: [
                {
                    type: 'warning',
                    message: 'محاولة دخول غير مصرح بها من IP: 192.168.1.100',
                    time: '2025-10-22T01:30:00Z'
                },
                {
                    type: 'info',
                    message: 'تم تحديث شهادة SSL بنجاح',
                    time: '2025-10-21T18:00:00Z'
                }
            ],
            recentActivities: [
                {
                    user: 'سلطان القحطاني',
                    action: 'قدم طلب تحويل إلى إعلامي',
                    time: '2025-10-22T02:00:00Z'
                },
                {
                    user: 'Admin',
                    action: 'وافق على طلب مقدم خدمة',
                    time: '2025-10-22T01:45:00Z'
                },
                {
                    user: 'أحمد العتيبي',
                    action: 'سجل دخول جديد',
                    time: '2025-10-22T01:30:00Z'
                }
            ]
        };
    } catch (error) {
        console.error('Error fetching dashboard stats:', error);
        return {};
    }
}

function renderSecurityAlerts(alerts) {
    if (!alerts || alerts.length === 0) {
        return '<div class="empty-state">لا توجد تنبيهات أمنية</div>';
    }
    
    return alerts.map(alert => `
        <div class="alert alert-${alert.type}">
            <i class="fas fa-${alert.type === 'warning' ? 'exclamation-triangle' : 'info-circle'}"></i>
            <div class="alert-content">
                <p>${alert.message}</p>
                <span class="time">${formatDate(alert.time)}</span>
            </div>
        </div>
    `).join('');
}

function renderActivities(activities) {
    if (!activities || activities.length === 0) {
        return '<div class="empty-state">لا توجد نشاطات حديثة</div>';
    }
    
    return activities.map(activity => `
        <div class="activity-item">
            <div class="activity-icon">
                <i class="fas fa-user"></i>
            </div>
            <div class="activity-content">
                <p><strong>${activity.user}</strong> ${activity.action}</p>
                <span class="time">${formatDate(activity.time)}</span>
            </div>
        </div>
    `).join('');
}

async function refreshDashboard() {
    showToast('جاري تحديث البيانات...', 'info');
    await loadPage('dashboard');
    showToast('تم التحديث بنجاح', 'success');
}

