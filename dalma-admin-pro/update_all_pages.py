#!/usr/bin/env python3
"""
Script to update all Admin Pro pages with the new unified top bar
"""

import os
import re

# List of pages to update with their titles
PAGES = {
    'offices-management.html': 'إدارة المكاتب',
    'upgrade-requests.html': 'طلبات الترقية',
    'realty-subscriptions.html': 'اشتراكات العقار',
    'content-management.html': 'إدارة المحتوى',
    'notifications.html': 'الإشعارات',
    'ip-management.html': 'إدارة IPs',
    'security-monitoring.html': 'مراقبة الأمان',
    'roles-management.html': 'الأدوار والصلاحيات',
    'finance-monitoring.html': 'المالية',
    'reports.html': 'التقارير',
    'ai-analytics.html': 'التحليلات الذكية',
    'settings.html': 'الإعدادات',
}

def update_page(filename, page_title):
    """Update a single page"""
    filepath = os.path.join(os.path.dirname(__file__), filename)
    
    if not os.path.exists(filepath):
        print(f"⏭️  {filename} - ملف غير موجود")
        return False
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # 1. Add topbar.css if not present
    if 'topbar.css' not in content:
        content = content.replace(
            '<link rel="stylesheet" href="css/unified-sidebar.css">',
            '<link rel="stylesheet" href="css/unified-sidebar.css">\n    <link rel="stylesheet" href="css/topbar.css">'
        )
    
    # 2. Remove old header
    old_header_pattern = r'<header class="header">.*?</header>\s*'
    content = re.sub(old_header_pattern, '', content, flags=re.DOTALL)
    
    # 3. Add topbar.js if not present
    if 'topbar.js' not in content:
        content = content.replace(
            '<script src="js/sidebar.js">',
            '<script src="js/topbar.js"></script>\n    <script src="js/sidebar.js">'
        )
    
    # 4. Add renderTopBar initialization if not present
    if 'renderTopBar' not in content:
        # Find the last </body> tag
        body_end = content.rfind('</body>')
        if body_end != -1:
            init_script = f'''    
    <script>
        document.addEventListener('DOMContentLoaded', () => {{
            renderTopBar('{page_title}');
        }});
    </script>
'''
            content = content[:body_end] + init_script + content[body_end:]
    
    # Save if changed
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✅ {filename} - تم التحديث")
        return True
    else:
        print(f"⏭️  {filename} - لا يحتاج تحديث")
        return False

def main():
    """Main function"""
    print("🚀 بدء تحديث صفحات Admin Pro...\n")
    
    updated_count = 0
    for filename, page_title in PAGES.items():
        if update_page(filename, page_title):
            updated_count += 1
    
    print(f"\n✅ تم تحديث {updated_count} من {len(PAGES)} صفحة")

if __name__ == '__main__':
    main()

