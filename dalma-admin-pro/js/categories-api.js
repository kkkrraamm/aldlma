// ============================================
// API Integration for Categories Admin Panel
// استبدال localStorage بـ API calls
// ============================================

const API_BASE_URL = '';  // سيستخدم current origin

async function getAuthToken() {
  return localStorage.getItem('token') || localStorage.getItem('admin_token');
}

async function getAuthHeaders() {
  const token = await getAuthToken();
  return {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  };
}

// ===== Fetch Categories from API =====
async function fetchCategoriesFromAPI() {
  try {
    const response = await fetch(`${API_BASE_URL}/api/categories/hierarchical`);
    if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
    return await response.json();
  } catch (error) {
    console.error('❌ خطأ في جلب الفئات:', error);
    // استرجاع من localStorage إذا فشل API
    const saved = localStorage.getItem('hierarchicalCategories');
    return saved ? JSON.parse(saved) : { mainCategories: [], subcategories: {} };
  }
}

// ===== Add Main Category =====
async function addMainCategoryAPI(emoji, name_ar, name_en, description) {
  try {
    const response = await fetch(`${API_BASE_URL}/api/admin/categories`, {
      method: 'POST',
      headers: await getAuthHeaders(),
      body: JSON.stringify({
        emoji,
        name_ar,
        name_en,
        description
      })
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'فشل حفظ الفئة');
    }
    
    return await response.json();
  } catch (error) {
    console.error('❌ خطأ في إضافة الفئة:', error);
    throw error;
  }
}

// ===== Update Main Category =====
async function updateMainCategoryAPI(categoryId, name_ar, name_en, description, emoji) {
  try {
    const response = await fetch(`${API_BASE_URL}/api/admin/categories/${categoryId}`, {
      method: 'PUT',
      headers: await getAuthHeaders(),
      body: JSON.stringify({
        name_ar,
        name_en,
        description,
        emoji
      })
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'فشل تحديث الفئة');
    }
    
    return await response.json();
  } catch (error) {
    console.error('❌ خطأ في تحديث الفئة:', error);
    throw error;
  }
}

// ===== Delete Main Category =====
async function deleteMainCategoryAPI(categoryId) {
  try {
    const response = await fetch(`${API_BASE_URL}/api/admin/categories/${categoryId}`, {
      method: 'DELETE',
      headers: await getAuthHeaders()
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'فشل حذف الفئة');
    }
    
    return await response.json();
  } catch (error) {
    console.error('❌ خطأ في حذف الفئة:', error);
    throw error;
  }
}

// ===== Add Subcategory =====
async function addSubcategoryAPI(mainCategoryId, name_ar, name_en, description) {
  try {
    const response = await fetch(`${API_BASE_URL}/api/admin/categories/${mainCategoryId}/subcategories`, {
      method: 'POST',
      headers: await getAuthHeaders(),
      body: JSON.stringify({
        name_ar,
        name_en,
        description
      })
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'فشل حفظ الفئة الفرعية');
    }
    
    return await response.json();
  } catch (error) {
    console.error('❌ خطأ في إضافة الفئة الفرعية:', error);
    throw error;
  }
}

// ===== Update Subcategory =====
async function updateSubcategoryAPI(subcategoryId, name_ar, name_en, description) {
  try {
    const response = await fetch(`${API_BASE_URL}/api/admin/subcategories/${subcategoryId}`, {
      method: 'PUT',
      headers: await getAuthHeaders(),
      body: JSON.stringify({
        name_ar,
        name_en,
        description
      })
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'فشل تحديث الفئة الفرعية');
    }
    
    return await response.json();
  } catch (error) {
    console.error('❌ خطأ في تحديث الفئة الفرعية:', error);
    throw error;
  }
}

// ===== Delete Subcategory =====
async function deleteSubcategoryAPI(subcategoryId) {
  try {
    const response = await fetch(`${API_BASE_URL}/api/admin/subcategories/${subcategoryId}`, {
      method: 'DELETE',
      headers: await getAuthHeaders()
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'فشل حذف الفئة الفرعية');
    }
    
    return await response.json();
  } catch (error) {
    console.error('❌ خطأ في حذف الفئة الفرعية:', error);
    throw error;
  }
}

// ===== Helper: Show Messages =====
function showSuccessMessage(message) {
  const msg = document.getElementById('successMessage');
  if (msg) {
    msg.textContent = message;
    msg.style.display = 'block';
    setTimeout(() => {
      msg.style.display = 'none';
    }, 3000);
  } else {
    alert(message);
  }
}

function showErrorMessage(message) {
  alert(`❌ ${message}`);
  console.error(message);
}
