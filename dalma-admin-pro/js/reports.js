// Reports Management JavaScript
console.log('📊 [REPORTS] Module loaded');

// API Configuration (API_URL is defined in main.js)

let currentReportData = null;

// Generate report
async function generateReport() {
    try {
        const reportType = document.getElementById('reportType').value;
        const period = document.getElementById('reportPeriod').value;

        console.log(`📊 [REPORTS] Generating ${reportType} report for period ${period}...`);
        showToast('جاري إنشاء التقرير...', 'info');

        const endpoint = reportType === 'users' ? '/api/admin/reports/users' : '/api/admin/reports/services';
        
        const response = await fetch(`${API_URL}${endpoint}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
                'x-api-key': localStorage.getItem('admin_apiKey')
            },
            body: JSON.stringify({ period })
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        const data = await response.json();
        currentReportData = data;
        
        console.log('✅ [REPORTS] Report generated successfully');
        showToast('تم إنشاء التقرير بنجاح', 'success');

        // Show report results
        document.getElementById('reportResults').style.display = 'block';
        document.getElementById('exportPdfBtn').style.display = 'inline-block';
        document.getElementById('exportExcelBtn').style.display = 'inline-block';

        if (reportType === 'users') {
            renderUsersReport(data);
        } else {
            renderServicesReport(data);
        }

    } catch (error) {
        console.error('❌ [REPORTS] Error generating report:', error);
        showToast('فشل إنشاء التقرير: ' + error.message, 'error');
    }
}

// Render users report
function renderUsersReport(data) {
    // Hide services report, show users report
    document.getElementById('servicesReport').style.display = 'none';
    document.getElementById('usersReport').style.display = 'block';

    // Update date
    const date = new Date(data.generated_at);
    document.getElementById('reportDate').textContent = `تم الإنشاء: ${date.toLocaleString('ar-SA')}`;

    // Update statistics
    const summary = data.summary;
    document.getElementById('totalUsers').textContent = summary.total_users || 0;
    document.getElementById('newUsers30d').textContent = summary.new_users_30d || 0;
    document.getElementById('newUsers7d').textContent = summary.new_users_7d || 0;
    document.getElementById('regularUsers').textContent = summary.regular_users || 0;
    document.getElementById('mediaUsers').textContent = summary.media_users || 0;
    document.getElementById('providerUsers').textContent = summary.provider_users || 0;

    // Render daily registrations
    const tbody = document.getElementById('dailyRegistrations');
    if (data.daily_data && data.daily_data.length > 0) {
        tbody.innerHTML = data.daily_data.map(day => {
            const date = new Date(day.date);
            return `
                <tr>
                    <td>${date.toLocaleDateString('ar-SA')}</td>
                    <td><strong>${day.count}</strong></td>
                </tr>
            `;
        }).join('');
    } else {
        tbody.innerHTML = '<tr><td colspan="2" class="text-center">لا توجد بيانات</td></tr>';
    }
}

// Render services report
function renderServicesReport(data) {
    // Hide users report, show services report
    document.getElementById('usersReport').style.display = 'none';
    document.getElementById('servicesReport').style.display = 'block';

    const tbody = document.getElementById('servicesTableBody');
    
    if (data.summary && data.summary.length > 0) {
        const totalServices = data.summary.reduce((sum, item) => sum + parseInt(item.services_per_category), 0);
        
        tbody.innerHTML = data.summary.map(item => {
            const percentage = ((item.services_per_category / totalServices) * 100).toFixed(1);
            return `
                <tr>
                    <td><strong>${item.category || 'غير محدد'}</strong></td>
                    <td>${item.services_per_category}</td>
                    <td>
                        <div style="display: flex; align-items: center; gap: 10px;">
                            <div style="flex: 1; height: 8px; background: #e0e0e0; border-radius: 4px; overflow: hidden;">
                                <div style="width: ${percentage}%; height: 100%; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);"></div>
                            </div>
                            <span>${percentage}%</span>
                        </div>
                    </td>
                </tr>
            `;
        }).join('');
    } else {
        tbody.innerHTML = '<tr><td colspan="3" class="text-center">لا توجد خدمات</td></tr>';
    }
}

// Export to PDF (simplified version - in production, use jsPDF library)
function exportPDF() {
    if (!currentReportData) {
        showToast('لا يوجد تقرير لتصديره', 'warning');
        return;
    }

    console.log('📄 [REPORTS] Exporting to PDF...');
    showToast('تصدير PDF قيد التطوير - استخدم تصدير Excel', 'info');
    
    // In production, you would use jsPDF library:
    // const doc = new jsPDF();
    // doc.text('تقرير دلما', 10, 10);
    // doc.save('dalma-report.pdf');
}

// Export to Excel (simplified version - in production, use XLSX library)
function exportExcel() {
    if (!currentReportData) {
        showToast('لا يوجد تقرير لتصديره', 'warning');
        return;
    }

    console.log('📊 [REPORTS] Exporting to Excel...');
    
    try {
        const reportType = document.getElementById('reportType').value;
        let csvContent = '';

        if (reportType === 'users') {
            csvContent = 'تقرير المستخدمين\n\n';
            csvContent += 'الإحصائية,القيمة\n';
            csvContent += `إجمالي المستخدمين,${currentReportData.summary.total_users}\n`;
            csvContent += `جدد (30 يوم),${currentReportData.summary.new_users_30d}\n`;
            csvContent += `جدد (7 أيام),${currentReportData.summary.new_users_7d}\n`;
            csvContent += `مستخدمين عاديين,${currentReportData.summary.regular_users}\n`;
            csvContent += `إعلاميين,${currentReportData.summary.media_users}\n`;
            csvContent += `مقدمي خدمات,${currentReportData.summary.provider_users}\n\n`;
            
            csvContent += 'التاريخ,عدد التسجيلات\n';
            currentReportData.daily_data.forEach(day => {
                csvContent += `${day.date},${day.count}\n`;
            });
        } else {
            csvContent = 'تقرير الخدمات\n\n';
            csvContent += 'الفئة,عدد الخدمات\n';
            currentReportData.summary.forEach(item => {
                csvContent += `${item.category},${item.services_per_category}\n`;
            });
        }

        // Create download link
        const blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);
        link.setAttribute('href', url);
        link.setAttribute('download', `dalma-report-${Date.now()}.csv`);
        link.style.visibility = 'hidden';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        console.log('✅ [REPORTS] Excel export successful');
        showToast('تم تصدير التقرير بنجاح', 'success');

    } catch (error) {
        console.error('❌ [REPORTS] Error exporting Excel:', error);
        showToast('فشل تصدير التقرير', 'error');
    }
}

console.log('✅ [REPORTS] Module initialized');

