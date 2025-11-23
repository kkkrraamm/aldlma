// ============================================
// Hierarchical Categories Management System
// ============================================

// Emoji list for category selection
const AVAILABLE_EMOJIS = [
    '🍔', '🍕', '🍜', '🍱', '🍣', '🍛', '🌮', '🥗',
    '👔', '👗', '👠', '👜', '🧥', '👕', '🩳', '🧣',
    '🏠', '🛋️', '🛏️', '🪑', '🚪', '🪟', '🔧', '🔨',
    '💄', '💅', '🧴', '🧼', '🧽', '🧹', '🪮', '✨',
    '⚽', '🏀', '🎾', '⛳', '🏋️', '🤸', '🧘', '🚴',
    '📚', '📖', '✏️', '📝', '🎓', '🖊️', '📐', '🔬',
    '🎵', '🎸', '🎹', '🎤', '🎧', '🎼', '🎺', '🥁',
    '🚗', '🚙', '🚕', '🏎️', '🚓', '🚑', '🚒', '🚐'
];

// Sample data structure
let categoriesData = {
    mainCategories: [],
    subcategories: {}
};

let selectedMainCategory = null;
let selectedEmoji = null;

// ============================================
// Initialization
// ============================================

document.addEventListener('DOMContentLoaded', () => {
    initializeEmojiPicker();
    loadCategories();
    setupModalHandlers();
});

// ============================================
// Emoji Picker
// ============================================

function initializeEmojiPicker() {
    const emojiPicker = document.getElementById('emojiPicker');
    if (!emojiPicker) return;
    
    emojiPicker.innerHTML = AVAILABLE_EMOJIS.map(emoji => 
        `<div class="emoji-option" onclick="selectEmoji('${emoji}', this)">${emoji}</div>`
    ).join('');
}

function selectEmoji(emoji, element) {
    document.querySelectorAll('.emoji-option.selected').forEach(el => 
        el.classList.remove('selected')
    );
    element.classList.add('selected');
    selectedEmoji = emoji;
}

// ============================================
// Main Categories Management
// ============================================

function openAddMainCategoryModal() {
    document.getElementById('addMainCategoryModal').style.display = 'flex';
    selectedEmoji = null;
    document.getElementById('mainCategoryNameAr').value = '';
    document.getElementById('mainCategoryNameEn').value = '';
    document.getElementById('mainCategoryDescription').value = '';
}

function closeAddMainCategoryModal() {
    document.getElementById('addMainCategoryModal').style.display = 'none';
}

function saveMainCategory() {
    const nameAr = document.getElementById('mainCategoryNameAr').value.trim();
    const nameEn = document.getElementById('mainCategoryNameEn').value.trim();
    const description = document.getElementById('mainCategoryDescription').value.trim();

    if (!selectedEmoji) {
        alert('⚠️ الرجاء اختيار إيموجي');
        return;
    }

    if (!nameAr || !nameEn) {
        alert('⚠️ الرجاء إدخال الاسم بالعربية والإنجليزية');
        return;
    }

    const newCategory = {
        id: Date.now().toString(),
        emoji: selectedEmoji,
        name_ar: nameAr,
        name_en: nameEn,
        description: description,
        order: categoriesData.mainCategories.length + 1,
        is_active: true,
        created_at: new Date().toISOString()
    };

    categoriesData.mainCategories.push(newCategory);
    categoriesData.subcategories[newCategory.id] = [];

    saveToLocalStorage();
    renderMainCategories();
    showSuccessMessage('✅ تم إضافة الفئة الرئيسية بنجاح!');
    closeAddMainCategoryModal();
}

function renderMainCategories() {
    const list = document.getElementById('mainCategoriesList');
    
    if (categoriesData.mainCategories.length === 0) {
        list.innerHTML = '<p style="text-align: center; color: var(--text-secondary); padding: 20px;">لا توجد فئات رئيسية</p>';
        return;
    }

    list.innerHTML = categoriesData.mainCategories.map(category => `
        <div class="category-item ${selectedMainCategory === category.id ? 'active' : ''}" onclick="selectMainCategory('${category.id}')">
            <div class="category-emoji">${category.emoji}</div>
            <div class="category-info">
                <div class="category-name">${category.name_ar}</div>
                <div class="category-count">${categoriesData.subcategories[category.id]?.length || 0} فئة فرعية</div>
            </div>
            <div class="category-actions">
                <button class="btn-edit" onclick="editMainCategory('${category.id}', event)">
                    <i class="fas fa-edit"></i>
                </button>
                <button class="btn-delete" onclick="deleteMainCategory('${category.id}', event)">
                    <i class="fas fa-trash"></i>
                </button>
            </div>
        </div>
    `).join('');
}

function selectMainCategory(categoryId) {
    selectedMainCategory = categoryId;
    renderMainCategories();
    renderSubcategories();
}

function editMainCategory(categoryId, event) {
    event.stopPropagation();
    const category = categoriesData.mainCategories.find(c => c.id === categoryId);
    if (!category) return;

    const nameAr = prompt('الاسم بالعربية:', category.name_ar);
    if (!nameAr) return;

    const nameEn = prompt('الاسم بالإنجليزية:', category.name_en);
    if (!nameEn) return;

    category.name_ar = nameAr;
    category.name_en = nameEn;
    category.updated_at = new Date().toISOString();

    saveToLocalStorage();
    renderMainCategories();
    showSuccessMessage('✅ تم تحديث الفئة بنجاح!');
}

function deleteMainCategory(categoryId, event) {
    event.stopPropagation();
    
    if (!confirm('⚠️ هل أنت متأكد من حذف هذه الفئة وجميع فئاتها الفرعية؟')) {
        return;
    }

    categoriesData.mainCategories = categoriesData.mainCategories.filter(c => c.id !== categoryId);
    delete categoriesData.subcategories[categoryId];

    if (selectedMainCategory === categoryId) {
        selectedMainCategory = null;
    }

    saveToLocalStorage();
    renderMainCategories();
    renderSubcategories();
    showSuccessMessage('✅ تم حذف الفئة بنجاح!');
}

// ============================================
// Subcategories Management
// ============================================

function renderSubcategories() {
    const content = document.getElementById('subcategoriesContent');

    if (!selectedMainCategory) {
        content.innerHTML = `
            <div class="no-category-selected">
                <i class="fas fa-inbox" style="font-size: 48px; margin-bottom: 16px; opacity: 0.5;"></i>
                <p>اختر فئة رئيسية لعرض فئاتها الفرعية</p>
            </div>
        `;
        return;
    }

    const mainCategory = categoriesData.mainCategories.find(c => c.id === selectedMainCategory);
    const subcategories = categoriesData.subcategories[selectedMainCategory] || [];

    let html = `
        <div style="margin-bottom: 20px;">
            <h4 style="margin-bottom: 12px;">الفئات الفرعية لـ: ${mainCategory.emoji} ${mainCategory.name_ar}</h4>
            <button class="btn btn-primary" onclick="openAddSubcategoryModal()">
                <i class="fas fa-plus"></i>
                إضافة فئة فرعية
            </button>
        </div>
    `;

    if (subcategories.length === 0) {
        html += `
            <div style="text-align: center; padding: 40px 20px;">
                <i class="fas fa-folder-open" style="font-size: 48px; margin-bottom: 16px; opacity: 0.5;"></i>
                <p>لا توجد فئات فرعية. قم بإضافة واحدة!</p>
            </div>
        `;
    } else {
        html += '<div class="subcategories-list">';
        html += subcategories.map(sub => `
            <div class="subcategory-card">
                <div class="subcategory-name">${sub.name_ar}</div>
                <div style="font-size: 12px; color: var(--text-secondary); margin-bottom: 10px;">${sub.name_en}</div>
                <div class="subcategory-actions">
                    <button class="btn btn-edit" onclick="editSubcategory('${sub.id}', event)">
                        <i class="fas fa-edit"></i> تعديل
                    </button>
                    <button class="btn btn-delete" onclick="deleteSubcategory('${sub.id}', event)">
                        <i class="fas fa-trash"></i> حذف
                    </button>
                </div>
            </div>
        `).join('');
        html += '</div>';
    }

    content.innerHTML = html;
}

function openAddSubcategoryModal() {
    if (!selectedMainCategory) {
        alert('⚠️ الرجاء اختيار فئة رئيسية أولاً');
        return;
    }
    
    document.getElementById('addSubcategoryModal').style.display = 'flex';
    document.getElementById('subcategoryNameAr').value = '';
    document.getElementById('subcategoryNameEn').value = '';
    document.getElementById('subcategoryDescription').value = '';
}

function closeAddSubcategoryModal() {
    document.getElementById('addSubcategoryModal').style.display = 'none';
}

function saveSubcategory() {
    const nameAr = document.getElementById('subcategoryNameAr').value.trim();
    const nameEn = document.getElementById('subcategoryNameEn').value.trim();
    const description = document.getElementById('subcategoryDescription').value.trim();
    const editId = document.getElementById('editSubcategoryId')?.value;

    if (!nameAr || !nameEn) {
        alert('⚠️ الرجاء إدخال الاسم بالعربية والإنجليزية');
        return;
    }

    // Check if editing or adding new
    if (editId && window.editingSubcategoryId) {
        // Edit existing subcategory
        const mainCatId = window.editingMainCategoryId || selectedMainCategory;
        const subcategories = categoriesData.subcategories[mainCatId];
        const subcategory = subcategories.find(s => s.id === editId);
        
        if (subcategory) {
            subcategory.name_ar = nameAr;
            subcategory.name_en = nameEn;
            subcategory.description = description;
            subcategory.updated_at = new Date().toISOString();
            
            saveToLocalStorage();
            renderMainCategories();
            renderSubcategories();
            showSuccessMessage('✅ تم تحديث الفئة الفرعية بنجاح!');
        }
        
        // Reset editing state
        window.editingSubcategoryId = null;
        window.editingMainCategoryId = null;
        if (typeof resetSubcategoryModal === 'function') {
            resetSubcategoryModal();
        }
    } else {
        // Add new subcategory
        const newSubcategory = {
            id: Date.now().toString(),
            name_ar: nameAr,
            name_en: nameEn,
            description: description,
            order: (categoriesData.subcategories[selectedMainCategory]?.length || 0) + 1,
            is_active: true,
            created_at: new Date().toISOString()
        };

        if (!categoriesData.subcategories[selectedMainCategory]) {
            categoriesData.subcategories[selectedMainCategory] = [];
        }

        categoriesData.subcategories[selectedMainCategory].push(newSubcategory);
        
        saveToLocalStorage();
        renderMainCategories();
        renderSubcategories();
        showSuccessMessage('✅ تم إضافة الفئة الفرعية بنجاح!');
    }
    
    closeAddSubcategoryModal();
}

function editSubcategory(subcategoryId, event) {
    event.stopPropagation();
    
    // Call the function from HTML file to open edit modal
    if (typeof openEditSubcategoryModal === 'function') {
        openEditSubcategoryModal(selectedMainCategory, subcategoryId);
    } else {
        // Fallback to prompt if function not available
        const subcategories = categoriesData.subcategories[selectedMainCategory];
        const subcategory = subcategories.find(s => s.id === subcategoryId);
        if (!subcategory) return;

        const nameAr = prompt('الاسم بالعربية:', subcategory.name_ar);
        if (!nameAr) return;

        const nameEn = prompt('الاسم بالإنجليزية:', subcategory.name_en);
        if (!nameEn) return;

        subcategory.name_ar = nameAr;
        subcategory.name_en = nameEn;
        subcategory.updated_at = new Date().toISOString();

        saveToLocalStorage();
        renderSubcategories();
        showSuccessMessage('✅ تم تحديث الفئة الفرعية بنجاح!');
    }
}

function deleteSubcategory(subcategoryId, event) {
    event.stopPropagation();
    
    if (!confirm('⚠️ هل أنت متأكد من حذف هذه الفئة الفرعية؟')) {
        return;
    }

    categoriesData.subcategories[selectedMainCategory] = 
        categoriesData.subcategories[selectedMainCategory].filter(s => s.id !== subcategoryId);

    saveToLocalStorage();
    renderSubcategories();
    showSuccessMessage('✅ تم حذف الفئة الفرعية بنجاح!');
}

// ============================================
// Storage & Persistence
// ============================================

function saveToLocalStorage() {
    localStorage.setItem('hierarchicalCategories', JSON.stringify(categoriesData));
    // In production, send to API: POST /api/admin/categories
}

function loadCategories() {
    // Load from API (استبدال localStorage بـ API)
    loadCategoriesFromAPI();
}

async function loadCategoriesFromAPI() {
    try {
      const response = await fetch('https://dalma-api.onrender.com/api/categories/hierarchical');
      if (!response.ok) throw new Error('فشل جلب الفئات');
      
      const data = await response.json();
      categoriesData = data;
      renderMainCategories();
    } catch (error) {
      console.error('❌ خطأ في جلب الفئات:', error);
      // في حالة الخطأ، جاري من localStorage أو بيانات تجريبية
      const saved = localStorage.getItem('hierarchicalCategories');
      if (saved) {
        categoriesData = JSON.parse(saved);
      } else {
        // بيانات تجريبية للتطوير
        categoriesData = {
          mainCategories: [
            { id: 1, emoji: '🍕', name_ar: 'الغذاء والمشروبات', name_en: 'Food & Beverages', description: 'المطاعم والمقاهي والمخابز' },
            { id: 2, emoji: '👕', name_ar: 'الملابس والأزياء', name_en: 'Clothing & Fashion', description: 'الملابس والأحذية والإكسسوارات' },
            { id: 3, emoji: '📱', name_ar: 'الإلكترونيات', name_en: 'Electronics', description: 'الأجهزة الإلكترونية والأدوات' },
            { id: 4, emoji: '🏠', name_ar: 'المنزل والأثاث', name_en: 'Home & Furniture', description: 'الأثاث ومستلزمات المنزل' }
          ],
          subcategories: {
            1: [
              { id: 1, name_ar: 'المطاعم', name_en: 'Restaurants', description: 'مطاعم الوجبات السريعة والمطاعم الفاخرة' },
              { id: 2, name_ar: 'المقاهي', name_en: 'Cafes', description: 'المقاهي والقهوة والحلويات' }
            ],
            2: [
              { id: 3, name_ar: 'الملابس الرجالية', name_en: 'Mens Clothing', description: 'ملابس رجالية وقمصان' },
              { id: 4, name_ar: 'الملابس النسائية', name_en: 'Womens Clothing', description: 'ملابس نسائية وفساتين' }
            ]
          }
        };
        showSuccessMessage('⚠️ تم تحميل بيانات تجريبية (اتصال الإنترنت مطلوب للبيانات الحقيقية)');
      }
      renderMainCategories();
    }
}// ============================================
// UI Helpers
// ============================================

function showSuccessMessage(message) {
    const msg = document.getElementById('successMessage');
    msg.textContent = message;
    msg.style.display = 'block';
    setTimeout(() => {
        msg.style.display = 'none';
    }, 3000);
}

function setupModalHandlers() {
    // Close modals on overlay click
    document.querySelector('.modal-overlay').addEventListener('click', closeAllModals);
    
    // Close modals on Escape key
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') closeAllModals();
    });
}

function closeAllModals() {
    document.getElementById('addMainCategoryModal').style.display = 'none';
    document.getElementById('addSubcategoryModal').style.display = 'none';
}

// ============================================
// Export Functions (for API integration)
// ============================================

function getCategories() {
    return categoriesData;
}

function getCategoryById(categoryId) {
    return categoriesData.mainCategories.find(c => c.id === categoryId);
}

function getSubcategoriesForCategory(categoryId) {
    return categoriesData.subcategories[categoryId] || [];
}

function getCategoryHierarchy() {
    return categoriesData.mainCategories.map(cat => ({
        ...cat,
        subcategories: categoriesData.subcategories[cat.id] || []
    }));
}

// ============================================
// Sample Data (for testing)
// ============================================

function loadSampleData() {
    categoriesData = {
        mainCategories: [
            {
                id: '1',
                emoji: '🍔',
                name_ar: 'أكل',
                name_en: 'Food',
                description: 'المنتجات الغذائية والأطعمة',
                order: 1,
                is_active: true,
                created_at: new Date().toISOString()
            },
            {
                id: '2',
                emoji: '👔',
                name_ar: 'ملابس',
                name_en: 'Clothing',
                description: 'الملابس والأزياء',
                order: 2,
                is_active: true,
                created_at: new Date().toISOString()
            }
        ],
        subcategories: {
            '1': [
                { id: '1-1', name_ar: 'برقر', name_en: 'Burger', order: 1, is_active: true },
                { id: '1-2', name_ar: 'عربي', name_en: 'Arabic', order: 2, is_active: true },
                { id: '1-3', name_ar: 'صيني', name_en: 'Chinese', order: 3, is_active: true },
                { id: '1-4', name_ar: 'أرز', name_en: 'Rice', order: 4, is_active: true }
            ],
            '2': [
                { id: '2-1', name_ar: 'رجالي', name_en: 'Mens', order: 1, is_active: true },
                { id: '2-2', name_ar: 'نسائي', name_en: 'Womens', order: 2, is_active: true },
                { id: '2-3', name_ar: 'أطفال', name_en: 'Kids', order: 3, is_active: true }
            ]
        }
    };
    
    saveToLocalStorage();
    renderMainCategories();
}

// Load sample data for first time (development only)
// Uncomment to test:
// loadSampleData();
