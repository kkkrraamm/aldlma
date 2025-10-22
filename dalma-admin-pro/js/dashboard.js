// Dashboard Page
let dashboardCharts = {}; // Store chart instances

async function loadDashboard() {
    try {
        // Fetch dashboard data
        const stats = await fetchDashboardStats();
        
        const result = `
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

                <!-- Charts Row -->
                <div class="charts-row">
                    <!-- Users Growth Chart -->
                    <div class="card chart-card">
                        <div class="card-header">
                            <h2 class="card-title">
                                <i class="fas fa-chart-line"></i>
                                نمو المستخدمين
                            </h2>
                            <select onchange="changeChartPeriod('usersChart', this.value)" class="period-select">
                                <option value="7d">آخر 7 أيام</option>
                                <option value="30d" selected>آخر 30 يوم</option>
                                <option value="90d">آخر 90 يوم</option>
                                <option value="1y">السنة الماضية</option>
                            </select>
                        </div>
                        <div class="card-body">
                            <div id="usersChart" style="min-height: 350px;"></div>
                        </div>
                    </div>

                    <!-- User Types Distribution Chart -->
                    <div class="card chart-card">
                        <div class="card-header">
                            <h2 class="card-title">
                                <i class="fas fa-chart-pie"></i>
                                توزيع أنواع المستخدمين
                            </h2>
                        </div>
                        <div class="card-body">
                            <div id="userTypesChart" style="min-height: 350px;"></div>
                        </div>
                    </div>
                </div>

                <!-- Second Charts Row -->
                <div class="charts-row">
                    <!-- API Costs Chart -->
                    <div class="card chart-card">
                        <div class="card-header">
                            <h2 class="card-title">
                                <i class="fas fa-dollar-sign"></i>
                                تكاليف API الشهرية
                            </h2>
                        </div>
                        <div class="card-body">
                            <div id="apiCostsChart" style="min-height: 350px;"></div>
                        </div>
                    </div>

                    <!-- Requests Timeline Chart -->
                    <div class="card chart-card">
                        <div class="card-header">
                            <h2 class="card-title">
                                <i class="fas fa-chart-area"></i>
                                الطلبات اليومية
                            </h2>
                        </div>
                        <div class="card-body">
                            <div id="requestsChart" style="min-height: 350px;"></div>
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
        
        // Initialize charts after rendering
        initializeDashboardCharts(stats);
        
        return result;
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

// Initialize Charts after DOM is ready
function initializeDashboardCharts(stats) {
    // Wait for DOM to be ready
    setTimeout(() => {
        initUsersGrowthChart(stats);
        initUserTypesChart(stats);
        initApiCostsChart(stats);
        initRequestsChart(stats);
    }, 100);
}

// Users Growth Chart
function initUsersGrowthChart(stats) {
    const element = document.getElementById('usersChart');
    if (!element) return;

    // Destroy existing chart
    if (dashboardCharts.usersChart) {
        dashboardCharts.usersChart.destroy();
    }

    // Generate mock data for 30 days
    const dates = [];
    const usersData = [];
    const mediaData = [];
    const providersData = [];
    
    for (let i = 29; i >= 0; i--) {
        const date = new Date();
        date.setDate(date.getDate() - i);
        dates.push(date.toISOString().split('T')[0]);
        
        // Mock growth data
        const baseUsers = stats.totalUsers - (stats.newUsersPercent / 100 * stats.totalUsers);
        usersData.push(Math.floor(baseUsers + (Math.random() * 20 + i * 2)));
        mediaData.push(Math.floor(stats.totalMedia * 0.7 + (Math.random() * 2 + i * 0.2)));
        providersData.push(Math.floor(stats.totalProviders * 0.6 + (Math.random() * 3 + i * 0.4)));
    }

    const options = {
        series: [{
            name: 'المستخدمين',
            data: usersData
        }, {
            name: 'الإعلاميين',
            data: mediaData
        }, {
            name: 'مقدمي الخدمات',
            data: providersData
        }],
        chart: {
            type: 'area',
            height: 350,
            fontFamily: 'Cairo, sans-serif',
            toolbar: {
                show: true,
                tools: {
                    download: true,
                    zoom: true,
                    zoomin: true,
                    zoomout: true,
                    pan: true,
                    reset: true
                }
            }
        },
        colors: ['#6366f1', '#8b5cf6', '#f59e0b'],
        dataLabels: {
            enabled: false
        },
        stroke: {
            curve: 'smooth',
            width: 2
        },
        fill: {
            type: 'gradient',
            gradient: {
                opacityFrom: 0.6,
                opacityTo: 0.1
            }
        },
        xaxis: {
            categories: dates,
            labels: {
                formatter: function(value) {
                    const date = new Date(value);
                    return date.getDate() + '/' + (date.getMonth() + 1);
                }
            }
        },
        yaxis: {
            title: {
                text: 'العدد'
            }
        },
        legend: {
            position: 'top',
            horizontalAlign: 'right'
        },
        tooltip: {
            x: {
                format: 'dd/MM/yyyy'
            }
        }
    };

    dashboardCharts.usersChart = new ApexCharts(element, options);
    dashboardCharts.usersChart.render();
}

// User Types Distribution Chart
function initUserTypesChart(stats) {
    const element = document.getElementById('userTypesChart');
    if (!element) return;

    if (dashboardCharts.userTypesChart) {
        dashboardCharts.userTypesChart.destroy();
    }

    // Ensure we have valid numbers
    const regularUsers = parseInt(stats.totalUsers) || 0;
    const mediaUsers = parseInt(stats.totalMedia) || 0;
    const providerUsers = parseInt(stats.totalProviders) || 0;
    
    // If all zeros, use fallback data to avoid NaN
    const series = (regularUsers + mediaUsers + providerUsers) === 0 
        ? [1, 0, 0] 
        : [regularUsers, mediaUsers, providerUsers];

    const options = {
        series: series,
        chart: {
            type: 'donut',
            height: 350,
            fontFamily: 'Cairo, sans-serif'
        },
        labels: ['مستخدمين عاديين', 'إعلاميين', 'مقدمي خدمات'],
        colors: ['#6366f1', '#8b5cf6', '#f59e0b'],
        legend: {
            position: 'bottom'
        },
        plotOptions: {
            pie: {
                donut: {
                    size: '65%',
                    labels: {
                        show: true,
                        total: {
                            show: true,
                            label: 'المجموع',
                            formatter: function (w) {
                                return w.globals.seriesTotals.reduce((a, b) => a + b, 0);
                            }
                        }
                    }
                }
            }
        },
        dataLabels: {
            enabled: true,
            formatter: function(val, opts) {
                return opts.w.config.series[opts.seriesIndex];
            }
        },
        noData: {
            text: 'لا توجد بيانات'
        }
    };

    dashboardCharts.userTypesChart = new ApexCharts(element, options);
    dashboardCharts.userTypesChart.render();
}

// API Costs Chart
function initApiCostsChart(stats) {
    const element = document.getElementById('apiCostsChart');
    if (!element) return;

    if (dashboardCharts.apiCostsChart) {
        dashboardCharts.apiCostsChart.destroy();
    }

    // Generate mock monthly data
    const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر'];
    const costs = [];
    
    for (let i = 0; i < 10; i++) {
        costs.push((Math.random() * 200 + 300).toFixed(2));
    }

    const options = {
        series: [{
            name: 'التكلفة ($)',
            data: costs
        }],
        chart: {
            type: 'bar',
            height: 350,
            fontFamily: 'Cairo, sans-serif'
        },
        colors: ['#10b981'],
        plotOptions: {
            bar: {
                borderRadius: 8,
                dataLabels: {
                    position: 'top'
                }
            }
        },
        dataLabels: {
            enabled: true,
            formatter: function (val) {
                return "$" + val;
            },
            offsetY: -20,
            style: {
                fontSize: '12px',
                colors: ["#304758"]
            }
        },
        xaxis: {
            categories: months,
            position: 'bottom'
        },
        yaxis: {
            title: {
                text: 'التكلفة ($)'
            }
        }
    };

    dashboardCharts.apiCostsChart = new ApexCharts(element, options);
    dashboardCharts.apiCostsChart.render();
}

// Requests Timeline Chart
function initRequestsChart(stats) {
    const element = document.getElementById('requestsChart');
    if (!element) return;

    if (dashboardCharts.requestsChart) {
        dashboardCharts.requestsChart.destroy();
    }

    // Generate data for last 14 days
    const dates = [];
    const requestsData = [];
    
    for (let i = 13; i >= 0; i--) {
        const date = new Date();
        date.setDate(date.getDate() - i);
        dates.push(date.toISOString().split('T')[0]);
        requestsData.push(Math.floor(Math.random() * 5000 + 8000));
    }

    const options = {
        series: [{
            name: 'الطلبات',
            data: requestsData
        }],
        chart: {
            type: 'area',
            height: 350,
            fontFamily: 'Cairo, sans-serif',
            sparkline: {
                enabled: false
            }
        },
        colors: ['#ef4444'],
        stroke: {
            curve: 'smooth',
            width: 3
        },
        fill: {
            type: 'gradient',
            gradient: {
                opacityFrom: 0.7,
                opacityTo: 0.2
            }
        },
        xaxis: {
            categories: dates,
            labels: {
                formatter: function(value) {
                    const date = new Date(value);
                    return date.getDate() + '/' + (date.getMonth() + 1);
                }
            }
        },
        yaxis: {
            title: {
                text: 'عدد الطلبات'
            }
        },
        tooltip: {
            x: {
                format: 'dd/MM/yyyy'
            }
        }
    };

    dashboardCharts.requestsChart = new ApexCharts(element, options);
    dashboardCharts.requestsChart.render();
}

// Change chart period
function changeChartPeriod(chartId, period) {
    console.log(`تغيير فترة ${chartId} إلى ${period}`);
    // يمكن إضافة منطق لتحديث البيانات حسب الفترة المختارة
    showToast(`جاري تحديث البيانات لفترة ${period}...`, 'info');
}

