// ==================== FINANCE MONITORING ====================

let financeCharts = {};

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    loadFinanceData();
});

// Load all finance data
async function loadFinanceData() {
    try {
        console.log('📊 جاري تحميل البيانات المالية...');
        
        // In production, fetch from API
        // const data = await apiRequest('/api/admin/finance/overview');
        
        // For now, use mock data
        const data = generateMockFinanceData();
        
        // Update stats
        updateFinanceStats(data.stats);
        
        // Initialize charts
        initCostTrendsChart(data.costTrends);
        initCostBreakdownChart(data.costBreakdown);
        initCostPredictionsChart(data.predictions);
        
        // Load API costs table
        loadApiCostsTable(data.apiCosts);
        
        // Load budget alerts
        loadBudgetAlerts(data.budgetAlerts);
        
        console.log('✅ تم تحميل البيانات المالية بنجاح');
    } catch (error) {
        console.error('❌ خطأ في تحميل البيانات المالية:', error);
        showToast('فشل تحميل البيانات المالية', 'error');
    }
}

// Update finance stats
function updateFinanceStats(stats) {
    document.getElementById('totalCost').textContent = `$${stats.totalCost.toFixed(2)}`;
    document.getElementById('apiCalls').textContent = stats.apiCalls.toLocaleString();
    document.getElementById('aiCost').textContent = `$${stats.aiCost.toFixed(2)}`;
    document.getElementById('dbCost').textContent = `$${stats.dbCost.toFixed(2)}`;
    
    document.getElementById('costChange').textContent = `${stats.costChange}%`;
    document.getElementById('callsChange').textContent = `+${stats.callsChange}%`;
    document.getElementById('aiChange').textContent = `+${stats.aiChange}%`;
    document.getElementById('dbChange').textContent = `${stats.dbChange}%`;
}

// Cost Trends Chart
function initCostTrendsChart(data) {
    const element = document.getElementById('costTrendsChart');
    if (!element) return;

    if (financeCharts.costTrends) {
        financeCharts.costTrends.destroy();
    }

    const options = {
        series: [
            {
                name: 'API Costs',
                data: data.apiCosts
            },
            {
                name: 'Dalma AI',
                data: data.aiCosts
            },
            {
                name: 'Database',
                data: data.dbCosts
            },
            {
                name: 'Storage',
                data: data.storageCosts
            }
        ],
        chart: {
            type: 'area',
            height: 350,
            fontFamily: 'Cairo, sans-serif',
            stacked: true,
            toolbar: {
                show: true
            }
        },
        colors: ['#6366f1', '#f59e0b', '#10b981', '#8b5cf6'],
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
            categories: data.dates,
            labels: {
                formatter: function(value) {
                    const date = new Date(value);
                    return date.getDate() + '/' + (date.getMonth() + 1);
                }
            }
        },
        yaxis: {
            title: {
                text: 'التكلفة ($)'
            },
            labels: {
                formatter: function(val) {
                    return '$' + val.toFixed(2);
                }
            }
        },
        legend: {
            position: 'top',
            horizontalAlign: 'right'
        },
        tooltip: {
            x: {
                format: 'dd/MM/yyyy'
            },
            y: {
                formatter: function(val) {
                    return '$' + val.toFixed(2);
                }
            }
        }
    };

    financeCharts.costTrends = new ApexCharts(element, options);
    financeCharts.costTrends.render();
}

// Cost Breakdown Chart
function initCostBreakdownChart(data) {
    const element = document.getElementById('costBreakdownChart');
    if (!element) return;

    if (financeCharts.costBreakdown) {
        financeCharts.costBreakdown.destroy();
    }

    const options = {
        series: data.values,
        chart: {
            type: 'donut',
            height: 350,
            fontFamily: 'Cairo, sans-serif'
        },
        labels: data.labels,
        colors: ['#6366f1', '#f59e0b', '#10b981', '#8b5cf6', '#ef4444'],
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
                            label: 'الإجمالي',
                            formatter: function (w) {
                                const total = w.globals.seriesTotals.reduce((a, b) => a + b, 0);
                                return '$' + total.toFixed(2);
                            }
                        }
                    }
                }
            }
        },
        dataLabels: {
            enabled: true,
            formatter: function(val, opts) {
                return '$' + opts.w.config.series[opts.seriesIndex].toFixed(2);
            }
        },
        tooltip: {
            y: {
                formatter: function(val) {
                    return '$' + val.toFixed(2);
                }
            }
        }
    };

    financeCharts.costBreakdown = new ApexCharts(element, options);
    financeCharts.costBreakdown.render();
}

// Cost Predictions Chart
function initCostPredictionsChart(data) {
    const element = document.getElementById('costPredictionsChart');
    if (!element) return;

    if (financeCharts.predictions) {
        financeCharts.predictions.destroy();
    }

    const options = {
        series: [
            {
                name: 'التكاليف الفعلية',
                data: data.actualCosts
            },
            {
                name: 'التوقعات',
                data: data.predictedCosts
            }
        ],
        chart: {
            type: 'line',
            height: 300,
            fontFamily: 'Cairo, sans-serif'
        },
        colors: ['#10b981', '#f59e0b'],
        stroke: {
            width: [3, 3],
            dashArray: [0, 5]
        },
        xaxis: {
            categories: data.months
        },
        yaxis: {
            title: {
                text: 'التكلفة ($)'
            },
            labels: {
                formatter: function(val) {
                    return '$' + val.toFixed(0);
                }
            }
        },
        legend: {
            position: 'top'
        },
        tooltip: {
            y: {
                formatter: function(val) {
                    return '$' + val.toFixed(2);
                }
            }
        }
    };

    financeCharts.predictions = new ApexCharts(element, options);
    financeCharts.predictions.render();
    
    // Update predictions summary
    const summaryHTML = `
        <div class="predictions-grid">
            <div class="prediction-item">
                <i class="fas fa-calendar-alt"></i>
                <div>
                    <h4>الشهر القادم</h4>
                    <p class="prediction-value">$${data.nextMonthPrediction.toFixed(2)}</p>
                    <span class="prediction-change ${data.nextMonthChange >= 0 ? 'negative' : 'positive'}">
                        ${data.nextMonthChange >= 0 ? '+' : ''}${data.nextMonthChange}%
                    </span>
                </div>
            </div>
            <div class="prediction-item">
                <i class="fas fa-chart-line"></i>
                <div>
                    <h4>نهاية السنة</h4>
                    <p class="prediction-value">$${data.yearEndPrediction.toFixed(2)}</p>
                    <span class="prediction-change ${data.yearEndChange >= 0 ? 'negative' : 'positive'}">
                        ${data.yearEndChange >= 0 ? '+' : ''}${data.yearEndChange}%
                    </span>
                </div>
            </div>
            <div class="prediction-item">
                <i class="fas fa-lightbulb"></i>
                <div>
                    <h4>توصية AI</h4>
                    <p class="prediction-recommendation">${data.recommendation}</p>
                </div>
            </div>
        </div>
    `;
    document.getElementById('predictionsSummary').innerHTML = summaryHTML;
}

// Load API Costs Table
function loadApiCostsTable(apiCosts) {
    const tableBody = document.getElementById('apiCostsTable');
    
    const rows = apiCosts.map(endpoint => `
        <tr>
            <td>
                <span class="endpoint-badge">${endpoint.method}</span>
                <code>${endpoint.path}</code>
            </td>
            <td>${endpoint.calls.toLocaleString()}</td>
            <td>${endpoint.avgTime}ms</td>
            <td>$${endpoint.costPerCall.toFixed(4)}</td>
            <td><strong>$${endpoint.totalCost.toFixed(2)}</strong></td>
            <td>
                <span class="trend ${endpoint.trend >= 0 ? 'trend-up' : 'trend-down'}">
                    <i class="fas fa-arrow-${endpoint.trend >= 0 ? 'up' : 'down'}"></i>
                    ${Math.abs(endpoint.trend)}%
                </span>
            </td>
        </tr>
    `).join('');
    
    tableBody.innerHTML = rows;
}

// Load Budget Alerts
function loadBudgetAlerts(alerts) {
    const container = document.getElementById('budgetAlerts');
    
    if (!alerts || alerts.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-check-circle"></i>
                <p>لا توجد تنبيهات، الميزانية ضمن الحد المسموح</p>
            </div>
        `;
        return;
    }
    
    const alertsHTML = alerts.map(alert => `
        <div class="alert alert-${alert.severity}">
            <div class="alert-icon">
                <i class="fas fa-${alert.icon}"></i>
            </div>
            <div class="alert-content">
                <h4>${alert.title}</h4>
                <p>${alert.message}</p>
                <span class="alert-time">
                    <i class="fas fa-clock"></i>
                    ${alert.time}
                </span>
            </div>
            ${alert.actionable ? `
                <button class="btn btn-sm btn-outline" onclick="handleAlertAction('${alert.id}')">
                    إجراء
                </button>
            ` : ''}
        </div>
    `).join('');
    
    container.innerHTML = alertsHTML;
}

// Change cost period
function changeCostPeriod(period) {
    console.log(`تغيير فترة التكاليف إلى ${period}`);
    showToast(`جاري تحديث البيانات لفترة ${period}...`, 'info');
    // In production, fetch new data for the selected period
    setTimeout(() => {
        loadFinanceData();
    }, 500);
}

// Export API Costs
function exportApiCosts() {
    console.log('تصدير تكاليف API...');
    showToast('جاري تصدير البيانات...', 'info');
    // In production, generate CSV/Excel file
}

// Configure Budget
function configureBudget() {
    const modal = document.getElementById('budgetModal');
    modal.style.display = 'flex';
}

// Close Budget Modal
function closeBudgetModal() {
    const modal = document.getElementById('budgetModal');
    modal.style.display = 'none';
}

// Save Budget Config
function saveBudgetConfig() {
    const monthlyBudget = document.getElementById('monthlyBudget').value;
    const warningThreshold = document.getElementById('warningThreshold').value;
    const criticalThreshold = document.getElementById('criticalThreshold').value;
    const emailAlerts = document.getElementById('emailAlerts').checked;
    
    console.log('حفظ إعدادات الميزانية:', {
        monthlyBudget,
        warningThreshold,
        criticalThreshold,
        emailAlerts
    });
    
    // In production, save to backend
    showToast('تم حفظ إعدادات الميزانية بنجاح', 'success');
    closeBudgetModal();
}

// Handle Alert Action
function handleAlertAction(alertId) {
    console.log('معالجة إجراء التنبيه:', alertId);
    showToast('جاري معالجة التنبيه...', 'info');
}

// ==================== MOCK DATA GENERATOR ====================

function generateMockFinanceData() {
    // Stats
    const stats = {
        totalCost: 4823.67,
        costChange: -12,
        apiCalls: 487523,
        callsChange: 8,
        aiCost: 1247.89,
        aiChange: 15,
        dbCost: 850.50,
        dbChange: -5
    };
    
    // Cost Trends (30 days)
    const costTrends = {
        dates: [],
        apiCosts: [],
        aiCosts: [],
        dbCosts: [],
        storageCosts: []
    };
    
    for (let i = 29; i >= 0; i--) {
        const date = new Date();
        date.setDate(date.getDate() - i);
        costTrends.dates.push(date.toISOString().split('T')[0]);
        
        costTrends.apiCosts.push((Math.random() * 50 + 100).toFixed(2));
        costTrends.aiCosts.push((Math.random() * 30 + 40).toFixed(2));
        costTrends.dbCosts.push((Math.random() * 20 + 25).toFixed(2));
        costTrends.storageCosts.push((Math.random() * 15 + 10).toFixed(2));
    }
    
    // Cost Breakdown
    const costBreakdown = {
        labels: ['API Calls', 'Dalma AI', 'Database', 'Storage', 'Other'],
        values: [2345.67, 1247.89, 850.50, 289.61, 90.00]
    };
    
    // API Costs by Endpoint
    const apiCosts = [
        {
            method: 'GET',
            path: '/api/users',
            calls: 125432,
            avgTime: 45,
            costPerCall: 0.0012,
            totalCost: 150.52,
            trend: -5
        },
        {
            method: 'POST',
            path: '/api/auth/login',
            calls: 98765,
            avgTime: 120,
            costPerCall: 0.0025,
            totalCost: 246.91,
            trend: 12
        },
        {
            method: 'GET',
            path: '/api/services',
            calls: 87654,
            avgTime: 65,
            costPerCall: 0.0015,
            totalCost: 131.48,
            trend: -2
        },
        {
            method: 'POST',
            path: '/api/dalma/ask',
            calls: 45678,
            avgTime: 2340,
            costPerCall: 0.0273,
            totalCost: 1247.00,
            trend: 18
        },
        {
            method: 'GET',
            path: '/api/trends',
            calls: 76543,
            avgTime: 78,
            costPerCall: 0.0018,
            totalCost: 137.78,
            trend: 3
        },
        {
            method: 'POST',
            path: '/api/orders',
            calls: 34567,
            avgTime: 156,
            costPerCall: 0.0032,
            totalCost: 110.61,
            trend: 7
        },
        {
            method: 'GET',
            path: '/api/providers/:id',
            calls: 23456,
            avgTime: 89,
            costPerCall: 0.0021,
            totalCost: 49.26,
            trend: -8
        },
        {
            method: 'POST',
            path: '/api/upload-image',
            calls: 12345,
            avgTime: 1234,
            costPerCall: 0.0156,
            totalCost: 192.58,
            trend: 22
        }
    ];
    
    // Budget Alerts
    const budgetAlerts = [
        {
            id: 'alert-1',
            severity: 'warning',
            icon: 'exclamation-triangle',
            title: 'تحذير: اقتراب من حد الميزانية',
            message: 'تم استهلاك 85% من الميزانية الشهرية ($4,250 من $5,000)',
            time: 'منذ 30 دقيقة',
            actionable: true
        },
        {
            id: 'alert-2',
            severity: 'danger',
            icon: 'fire',
            title: 'تنبيه: ارتفاع غير طبيعي في تكاليف AI',
            message: 'ارتفاع بنسبة 45% في استخدام Dalma AI خلال الساعات الـ 24 الماضية',
            time: 'منذ ساعتين',
            actionable: true
        }
    ];
    
    // Predictions
    const predictions = {
        months: ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو'],
        actualCosts: [3850, 4120, 4567, 4823, null, null],
        predictedCosts: [null, null, null, 4823, 5234, 5678],
        nextMonthPrediction: 5234.12,
        nextMonthChange: 8.5,
        yearEndPrediction: 62450.00,
        yearEndChange: 12.3,
        recommendation: 'يُنصح بتحسين استخدام Dalma AI لتقليل التكاليف. يمكن توفير حوالي $850/شهر بتطبيق caching ذكي.'
    };
    
    return {
        stats,
        costTrends,
        costBreakdown,
        apiCosts,
        budgetAlerts,
        predictions
    };
}

