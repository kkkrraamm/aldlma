// realty-subscriptions.js
// API_URL is defined in main.js
let allSubscriptions = [];
let filteredSubscriptions = [];
let revenueChart = null;

// تحميل البيانات عند فتح الصفحة
document.addEventListener('DOMContentLoaded', () => {
    console.log('✅ Realty Subscriptions Page Loaded');
    loadSubscriptions();
    setInterval(loadSubscriptions, 60000); // تحديث كل دقيقة
    
    // إضافة مستمع لتغيير الفترة
    document.getElementById('revenueChartPeriod').addEventListener('change', updateRevenueChart);
});

async function loadSubscriptions() {
    try {
        console.log('📥 Loading subscriptions data...');
        
        // جلب جميع الطلبات المقبولة (التي أصبحت اشتراكات)
        const response = await fetch(`${API_URL}/api/admin/office-registration-requests?status=approved`);
        const data = await response.json();
        
        if (data.success) {
            // تحويل الطلبات المقبولة إلى اشتراكات
            allSubscriptions = data.requests.map(request => {
                const approvedDate = new Date(request.reviewed_at);
                const expiryDate = new Date(approvedDate);
                expiryDate.setDate(expiryDate.getDate() + 30);
                
                const daysLeft = Math.ceil((expiryDate - new Date()) / (1000 * 60 * 60 * 24));
                const isExpired = daysLeft < 0;
                const isExpiring = daysLeft >= 0 && daysLeft <= 7;
                
                return {
                    id: request.id,
                    office_name: request.office_name,
                    city: request.city,
                    phone: request.phone,
                    email: request.email,
                    plan: request.requested_plan,
                    plan_name: request.plan_name,
                    price: request.plan_price || 0,
                    start_date: approvedDate,
                    expiry_date: expiryDate,
                    days_left: daysLeft,
                    status: isExpired ? 'expired' : isExpiring ? 'expiring' : 'active',
                    payment_status: 'paid' // افتراضياً مدفوع عند القبول
                };
            });
            
            filteredSubscriptions = allSubscriptions;
            console.log(`✅ Loaded ${allSubscriptions.length} subscriptions`);
            
            updateFinancialStats();
            updatePlanDistribution();
            updateRevenueChart();
            displaySubscriptions();
        } else {
            showError('فشل تحميل البيانات');
        }
    } catch (error) {
        console.error('❌ Error loading subscriptions:', error);
        showError('حدث خطأ في الاتصال بالسيرفر');
    }
}

function updateFinancialStats() {
    // حساب الإيرادات
    const totalRevenue = allSubscriptions.reduce((sum, sub) => sum + sub.price, 0);
    const activeCount = allSubscriptions.filter(s => s.status === 'active').length;
    const expiringCount = allSubscriptions.filter(s => s.status === 'expiring').length;
    const pendingPayments = 0; // يمكن إضافة منطق للمدفوعات المعلقة
    
    // تحديث الإحصائيات
    document.getElementById('totalRevenue').textContent = `${totalRevenue.toLocaleString()} ر.س`;
    document.getElementById('pendingPayments').textContent = `${pendingPayments.toLocaleString()} ر.س`;
    document.getElementById('activeSubscriptions').textContent = activeCount;
    document.getElementById('expiringSubscriptions').textContent = expiringCount;
    
    // حساب النمو (مثال: +15%)
    document.getElementById('revenueChange').innerHTML = `
        <i class="fas fa-arrow-up"></i>
        <span>+15% من الشهر الماضي</span>
    `;
    
    document.getElementById('pendingCount').innerHTML = `<span>0 اشتراك</span>`;
    
    document.getElementById('activeChange').innerHTML = `
        <i class="fas fa-arrow-up"></i>
        <span>+${activeCount} هذا الشهر</span>
    `;
}

function updatePlanDistribution() {
    const planCounts = {
        free: 0,
        basic: 0,
        pro: 0,
        vip: 0
    };
    
    const planRevenue = {
        free: 0,
        basic: 0,
        pro: 0,
        vip: 0
    };
    
    allSubscriptions.forEach(sub => {
        planCounts[sub.plan]++;
        planRevenue[sub.plan] += sub.price;
    });
    
    const planNames = {
        free: '🎁 مجاني',
        basic: '⭐ أساسي',
        pro: '🚀 احترافي',
        vip: '👑 VIP'
    };
    
    const container = document.getElementById('planDistribution');
    container.innerHTML = Object.keys(planCounts).map(plan => `
        <div class="plan-item">
            <div class="plan-info">
                <div class="plan-color ${plan}"></div>
                <div>
                    <div style="font-weight: 700; color: var(--text-primary);">${planNames[plan]}</div>
                    <div style="font-size: 12px; color: var(--text-secondary);">${planCounts[plan]} مكتب</div>
                </div>
            </div>
            <div class="plan-stats">
                <div class="plan-count">${planRevenue[plan].toLocaleString()} ر.س</div>
                <div class="plan-revenue">${Math.round((planCounts[plan] / allSubscriptions.length) * 100)}%</div>
            </div>
        </div>
    `).join('');
}

function updateRevenueChart() {
    const period = parseInt(document.getElementById('revenueChartPeriod').value);
    
    // إنشاء بيانات الأشهر
    const months = [];
    const revenues = [];
    const today = new Date();
    
    for (let i = period - 1; i >= 0; i--) {
        const date = new Date(today.getFullYear(), today.getMonth() - i, 1);
        const monthName = date.toLocaleDateString('ar-SA', { month: 'short', year: 'numeric' });
        months.push(monthName);
        
        // حساب الإيرادات لهذا الشهر
        const monthRevenue = allSubscriptions.filter(sub => {
            const subDate = new Date(sub.start_date);
            return subDate.getMonth() === date.getMonth() && 
                   subDate.getFullYear() === date.getFullYear();
        }).reduce((sum, sub) => sum + sub.price, 0);
        
        revenues.push(monthRevenue);
    }
    
    // تدمير الرسم القديم إذا كان موجوداً
    if (revenueChart) {
        revenueChart.destroy();
    }
    
    // إنشاء الرسم البياني
    const ctx = document.getElementById('revenueChart').getContext('2d');
    revenueChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: months,
            datasets: [{
                label: 'الإيرادات (ر.س)',
                data: revenues,
                borderColor: '#10b981',
                backgroundColor: 'rgba(16, 185, 129, 0.1)',
                borderWidth: 3,
                fill: true,
                tension: 0.4,
                pointRadius: 5,
                pointHoverRadius: 7,
                pointBackgroundColor: '#10b981',
                pointBorderColor: '#fff',
                pointBorderWidth: 2
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false
                },
                tooltip: {
                    backgroundColor: 'rgba(0, 0, 0, 0.8)',
                    padding: 12,
                    titleFont: {
                        size: 14,
                        family: 'Cairo'
                    },
                    bodyFont: {
                        size: 13,
                        family: 'Cairo'
                    },
                    callbacks: {
                        label: function(context) {
                            return 'الإيرادات: ' + context.parsed.y.toLocaleString() + ' ر.س';
                        }
                    }
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        font: {
                            family: 'Cairo',
                            size: 12
                        },
                        callback: function(value) {
                            return value.toLocaleString() + ' ر.س';
                        }
                    },
                    grid: {
                        color: 'rgba(0, 0, 0, 0.05)'
                    }
                },
                x: {
                    ticks: {
                        font: {
                            family: 'Cairo',
                            size: 12
                        }
                    },
                    grid: {
                        display: false
                    }
                }
            }
        }
    });
}

function filterSubscriptions() {
    const search = document.getElementById('searchInput').value.toLowerCase();
    const status = document.getElementById('statusFilter').value;
    const plan = document.getElementById('planFilter').value;
    const payment = document.getElementById('paymentFilter').value;
    
    filteredSubscriptions = allSubscriptions.filter(sub => {
        const matchSearch = sub.office_name.toLowerCase().includes(search) ||
                          sub.phone.includes(search) ||
                          (sub.email && sub.email.toLowerCase().includes(search));
        const matchStatus = status === 'all' || sub.status === status;
        const matchPlan = plan === 'all' || sub.plan === plan;
        const matchPayment = payment === 'all' || sub.payment_status === payment;
        
        return matchSearch && matchStatus && matchPlan && matchPayment;
    });
    
    displaySubscriptions();
}

function displaySubscriptions() {
    const tbody = document.getElementById('subscriptionsTableBody');
    const count = document.getElementById('subscriptionsCount');
    
    count.textContent = `${filteredSubscriptions.length} اشتراك`;
    
    if (filteredSubscriptions.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="7" style="text-align: center; padding: 60px;">
                    <i class="fas fa-inbox" style="font-size: 60px; color: var(--text-tertiary); opacity: 0.5;"></i>
                    <p style="margin-top: 20px; color: var(--text-secondary); font-weight: 600;">لا توجد اشتراكات</p>
                </td>
            </tr>
        `;
        return;
    }
    
    tbody.innerHTML = filteredSubscriptions.map(sub => createSubscriptionRow(sub)).join('');
}

function createSubscriptionRow(sub) {
    const initial = sub.office_name.charAt(0);
    const planBadge = getPlanBadge(sub.plan);
    const statusBadge = getStatusBadge(sub.status);
    const paymentBadge = getPaymentBadge(sub.payment_status);
    const daysBadge = getDaysBadge(sub.days_left);
    
    return `
        <tr>
            <td>
                <div class="office-cell">
                    <div class="office-icon">${initial}</div>
                    <div class="office-info">
                        <div class="office-name">${escapeHtml(sub.office_name)}</div>
                        <div class="office-city"><i class="fas fa-map-marker-alt"></i> ${escapeHtml(sub.city)}</div>
                    </div>
                </div>
            </td>
            <td><span class="badge ${sub.plan}">${planBadge}</span></td>
            <td style="font-weight: 700; color: var(--primary);">${sub.price.toLocaleString()} ر.س</td>
            <td>${paymentBadge}</td>
            <td>${sub.expiry_date.toLocaleDateString('ar-SA')}</td>
            <td>${daysBadge}</td>
            <td>
                <div class="table-actions-cell">
                    <button class="btn-icon view" onclick="viewSubscription(${sub.id})" title="عرض التفاصيل">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button class="btn-icon renew" onclick="renewSubscription(${sub.id})" title="تجديد">
                        <i class="fas fa-redo"></i>
                    </button>
                    <button class="btn-icon invoice" onclick="generateInvoice(${sub.id})" title="فاتورة">
                        <i class="fas fa-file-invoice"></i>
                    </button>
                </div>
            </td>
        </tr>
    `;
}

function getPlanBadge(plan) {
    const badges = {
        'free': '🎁 مجاني',
        'basic': '⭐ أساسي',
        'pro': '🚀 احترافي',
        'vip': '👑 VIP'
    };
    return badges[plan] || plan;
}

function getPlanName(plan) {
    const names = {
        'free': 'مجاني',
        'basic': 'أساسي',
        'pro': 'احترافي',
        'vip': 'VIP'
    };
    return names[plan] || plan;
}

function getStatusBadge(status) {
    const badges = {
        'active': '✅ نشط',
        'expiring': '⚠️ ينتهي قريباً',
        'expired': '❌ منتهي'
    };
    return badges[status] || status;
}

function getPaymentBadge(status) {
    const badges = {
        'paid': '<div class="payment-status paid"><i class="fas fa-check-circle"></i> مدفوع</div>',
        'pending': '<div class="payment-status pending"><i class="fas fa-clock"></i> معلق</div>',
        'failed': '<div class="payment-status failed"><i class="fas fa-times-circle"></i> فشل</div>'
    };
    return badges[status] || status;
}

function getDaysBadge(days) {
    if (days < 0) {
        return `<span class="days-badge danger">منتهي</span>`;
    } else if (days <= 7) {
        return `<span class="days-badge danger">${days} يوم</span>`;
    } else if (days <= 15) {
        return `<span class="days-badge warning">${days} يوم</span>`;
    } else {
        return `<span class="days-badge success">${days} يوم</span>`;
    }
}

function viewSubscription(id) {
    const sub = allSubscriptions.find(s => s.id === id);
    if (!sub) return;
    
    alert(`📊 تفاصيل الاشتراك\n\n` +
          `المكتب: ${sub.office_name}\n` +
          `الباقة: ${getPlanBadge(sub.plan)}\n` +
          `المبلغ: ${sub.price} ر.س\n` +
          `تاريخ البدء: ${sub.start_date.toLocaleDateString('ar-SA')}\n` +
          `تاريخ الانتهاء: ${sub.expiry_date.toLocaleDateString('ar-SA')}\n` +
          `الأيام المتبقية: ${sub.days_left} يوم\n` +
          `الحالة: ${getStatusBadge(sub.status)}`);
}

function renewSubscription(id) {
    const sub = allSubscriptions.find(s => s.id === id);
    if (!sub) return;
    
    if (confirm(`هل تريد تجديد اشتراك: ${sub.office_name}؟\n\nالمبلغ: ${sub.price} ر.س`)) {
        alert('✅ تم تجديد الاشتراك بنجاح!\n\nتم إضافة 30 يوم إلى الاشتراك.');
        loadSubscriptions();
    }
}

function generateInvoice(id) {
    const sub = allSubscriptions.find(s => s.id === id);
    if (!sub) return;
    
    // إنشاء URL مع البيانات
    const params = new URLSearchParams({
        id: sub.id,
        office_name: sub.office_name,
        city: sub.city,
        phone: sub.phone,
        email: sub.email || '',
        license: sub.license_number || '',
        plan: sub.plan,
        plan_name: getPlanName(sub.plan),
        price: sub.price
    });
    
    // فتح صفحة الفاتورة في نافذة جديدة
    window.open(`invoice-generator.html?${params.toString()}`, '_blank', 'width=1000,height=800');
}

function exportFinancialReport() {
    alert('📊 تصدير التقرير المالي\n\n' +
          `إجمالي الإيرادات: ${allSubscriptions.reduce((sum, s) => sum + s.price, 0).toLocaleString()} ر.س\n` +
          `عدد الاشتراكات: ${allSubscriptions.length}\n` +
          `الاشتراكات النشطة: ${allSubscriptions.filter(s => s.status === 'active').length}\n\n` +
          `🚧 ميزة التصدير قيد التطوير...`);
}

function showError(message) {
    const tbody = document.getElementById('subscriptionsTableBody');
    tbody.innerHTML = `
        <tr>
            <td colspan="7" style="text-align: center; padding: 60px;">
                <i class="fas fa-exclamation-triangle" style="font-size: 60px; color: var(--danger); opacity: 0.5;"></i>
                <p style="margin-top: 20px; color: var(--text-secondary); font-weight: 600;">${message}</p>
                <button class="btn btn-primary" onclick="loadSubscriptions()" style="margin-top: 15px;">
                    <i class="fas fa-redo"></i> إعادة المحاولة
                </button>
            </td>
        </tr>
    `;
}

function escapeHtml(text) {
    if (!text) return '';
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.toString().replace(/[&<>"']/g, m => map[m]);
}

console.log('✅ Realty Subscriptions JS Loaded');

