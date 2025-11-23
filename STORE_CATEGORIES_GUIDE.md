# 🏪 Store Categories System Guide
**تصنيفات المتاجر مع الإيموجي**

---

## 📋 Overview
A complete store categorization system that allows:
- ✅ Store owners to assign their stores to specific categories
- ✅ Customers to browse stores by category with emoji indicators
- ✅ Admin to manage categories (admin panel ready)
- ✅ Professional visual design with gradient selection

---

## 🎯 Features

### 1. **Category Selection in Provider Dashboard**
Location: **Settings Tab** → **Store Management** → **Store Category**

**What it does:**
- Store owners select which category their store belongs to
- 9 predefined categories with emojis and colors
- Required for store to appear in store listing under that category

**Categories Available:**
| Emoji | Category | ID |
|-------|----------|-----|
| 👔 | الملابس والأزياء (Clothing & Fashion) | `clothing` |
| 📱 | الإلكترونيات (Electronics) | `electronics` |
| 🏠 | المنزل والأثاث (Home & Furniture) | `furniture` |
| 🍔 | الغذائية والمشروبات (Food & Beverages) | `food` |
| 💄 | الجمال والعناية (Beauty & Care) | `beauty` |
| ⚽ | الرياضة واللياقة (Sports & Fitness) | `sports` |
| 📚 | الكتب والتعليم (Books & Education) | `education` |
| 🛠️ | الخدمات (Services) | `services` |
| 📦 | الكل (All) | `all` |

### 2. **Category Display in Stores Page**
Location: **Stores Page** → **Categories Bar**

**Features:**
- Horizontal scrollable category pills
- Emoji + Category name (Arabic)
- Color-coded for visual distinction
- Gradient highlight on selection
- Filters stores dynamically

**Visual Design:**
- Professional pill design with borders
- Colors match category theme
- Smooth gradient transition on selection
- Mobile-friendly vertical layout (emoji on top, name below)

### 3. **Category-Based Store Filtering**
When a category is selected:
- Only stores with that category appear
- "الكل" (All) shows all stores
- API query: `/api/stores?category=clothing`

---

## 🔧 Technical Implementation

### Files Modified:
1. **`lib/provider_dashboard_new.dart`**
   - Added category selection UI in `_SettingsTab`
   - New method: `_showCategorySelectionDialog()`
   - Dialog displays all categories with emoji

2. **`lib/stores_page.dart`**
   - Refactored category loading system
   - Changed from `List<String>` to `List<Map<String, dynamic>>`
   - Updated category pills with emoji + name + color
   - Professional layout with vertical stacking

### Key Classes:
```dart
// Category Data Structure
{
  'id': 'clothing',           // Unique identifier
  'name': 'الملابس والأزياء', // Arabic name
  'emoji': '👔',             // Emoji icon
  'color': Colors.blue       // Theme color
}
```

### API Integration Points:

**1. Get Categories:**
```
GET /api/categories
Response: [{
  "id": "clothing",
  "name": "الملابس والأزياء",
  "emoji": "👔",
  "color": "#1E40AF",
  "order": 1,
  "is_active": true
}]
```

**2. Filter Stores by Category:**
```
GET /api/stores?category=clothing
Response: [stores with category='clothing']
```

**3. Update Store Category:**
```
PUT /api/provider/store
Body: {
  "category": "clothing"
}
```

---

## 📱 User Flow

### For Store Owner:
1. Open Provider Dashboard
2. Go to **Settings Tab** (الإعدادات)
3. Select **Store Category** (تصنيف المتجر)
4. Choose from 8 categories (or skip with "All")
5. Confirm selection
6. ✅ Store now appears under that category in public stores page

### For Customer:
1. Open **Stores Page**
2. See category pills at top with emojis
3. Tap category to filter
4. View only stores in that category
5. Category highlights with gradient when selected

---

## 🎨 Design Details

### Category Pill Styling:
```
Normal State:
- Background: Category color with 0.1 opacity
- Border: Category color with 0.3 opacity
- Text: Category color (bold)
- Layout: Emoji on top, name below (vertical)

Selected State:
- Background: Gradient (Green to Dark Green / Gold to Dark Gold)
- Border: Transparent
- Text: White
- Shadow: Elevation 4
- Height: 60px
```

### Colors (Light Mode):
- Primary: Green (#10b981)
- Gold accent: #D4AF37

### Colors (Dark Mode):
- Primary: Gold (#D4AF37)
- Green accent: #10b981

---

## 🚀 Integration Steps

### Step 1: Backend API
Add endpoints:
```javascript
// GET all active categories
GET /api/categories

// Filter stores by category
GET /api/stores?category=clothing

// Update store category
PUT /api/provider/store
{
  "category": "clothing"
}

// Admin: Add/Edit/Delete categories
POST /api/admin/categories
PUT /api/admin/categories/:id
DELETE /api/admin/categories/:id
```

### Step 2: Database Schema
```sql
ALTER TABLE stores ADD COLUMN category VARCHAR(50);
CREATE TABLE categories (
  id SERIAL PRIMARY KEY,
  name_ar VARCHAR(100),
  emoji VARCHAR(10),
  color VARCHAR(20),
  order INT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Step 3: Update Hardcoded Categories
Replace hardcoded categories in both files with API call:
```dart
Future<void> _loadCategories() async {
  try {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/categories'),
      headers: await ApiConfig.getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        _categories = data.cast<Map<String, dynamic>>();
      });
    }
  } catch (e) {
    print('❌ Error loading categories: $e');
  }
}
```

---

## 🔄 Current Implementation Status

### ✅ Completed:
- [x] Category selection UI in provider dashboard
- [x] Category display in stores page with emojis
- [x] Visual design with colors and gradients
- [x] Professional pill layout with vertical emoji+name
- [x] Store filtering by category
- [x] Dark mode support
- [x] RTL Arabic support
- [x] No compilation errors

### 🟡 In Progress:
- [ ] Backend API integration
- [ ] Database schema updates
- [ ] Admin category management interface
- [ ] Category validation

### 📋 To-Do:
- [ ] Add category creation in admin panel
- [ ] Add category edit/delete in admin
- [ ] Database migrations
- [ ] API authentication

---

## 💾 Data Persistence

Currently: **Hardcoded in app** (for testing)

To Enable: **Replace with API calls**

Example categories already defined:
```dart
final categories = [
  {'id': 'all', 'name': 'الكل', 'emoji': '📦', 'color': Colors.grey},
  {'id': 'clothing', 'name': 'الملابس والأزياء', 'emoji': '👔', 'color': Colors.blue},
  {'id': 'electronics', 'name': 'الإلكترونيات', 'emoji': '📱', 'color': Colors.purple},
  {'id': 'furniture', 'name': 'المنزل والأثاث', 'emoji': '🏠', 'color': Colors.orange},
  {'id': 'food', 'name': 'الغذائية والمشروبات', 'emoji': '🍔', 'color': Colors.red},
  {'id': 'beauty', 'name': 'الجمال والعناية', 'emoji': '💄', 'color': Colors.pink},
  {'id': 'sports', 'name': 'الرياضة واللياقة', 'emoji': '⚽', 'color': Colors.green},
  {'id': 'education', 'name': 'الكتب والتعليم', 'emoji': '📚', 'color': Colors.indigo},
  {'id': 'services', 'name': 'الخدمات', 'emoji': '🛠️', 'color': Colors.teal},
];
```

---

## 🎓 Example Usage

### For Provider Dashboard:
```dart
// In Settings Tab
_SettingItem(
  icon: Icons.category_rounded,
  title: 'تصنيف المتجر',
  subtitle: 'حدد التصنيف الذي ينتمي إليه متجرك',
  onTap: () => _showCategorySelectionDialog(context),
),
```

### For Stores Page:
```dart
// Category filtering
if (category['id'] == _selectedCategoryId) {
  // Show stores for this category
}

// Display category pill
Text(
  '${category['emoji']} ${category['name']}',
  style: TextStyle(color: category['color']),
)
```

---

## 🐛 Known Issues
- None currently reported

---

## 📞 Support
For questions or issues with the store categories system, check:
1. `lib/provider_dashboard_new.dart` - Settings tab implementation
2. `lib/stores_page.dart` - Category display and filtering
3. Backend API integration guide (when available)

---

## 📅 Version History
- **v1.0** (Nov 23, 2025): Initial release
  - Store category selection in dashboard
  - Category display with emojis in stores page
  - Professional UI with colors and gradients
  - Ready for backend integration

---

**التصنيفات مع الإيموجي جاهزة للاستخدام! 🎉**
