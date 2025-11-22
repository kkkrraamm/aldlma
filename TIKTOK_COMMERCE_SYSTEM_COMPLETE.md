# 🎥 نظام التجارة بنمط TikTok - التوثيق الكامل

## 📋 نظرة عامة
نظام تجارة إلكترونية متكامل بنمط TikTok يتيح للتجار (Providers) عرض منتجاتهم عبر فيديوهات قصيرة، مع تجربة تصفح عمودية للمستخدمين.

---

## 🗄️ قاعدة البيانات (PostgreSQL)

### الجداول الرئيسية (9 Tables)

#### 1. **provider_stores** - متاجر التجار
```sql
- id, user_id, store_name, store_description
- store_logo, store_banner, business_license
- contact_phone, contact_email, address
- city, store_rating, is_verified, is_active
- created_at, updated_at
```

#### 2. **store_categories** - تصنيفات المنتجات
```sql
- id, name_ar, name_en, description
- icon, parent_category_id (hierarchy support)
- is_active, created_at
```

#### 3. **store_products** - منتجات المتاجر
```sql
- id, store_id, category_id, name_ar, name_en
- description_ar, description_en, slug
- price, discount_type, discount_value, final_price
- images (JSON), thumbnail, specifications (JSON)
- variants (JSON), tags (JSON)
- stock_quantity, sku, is_trending, trending_score
- is_active, created_at, updated_at
```

#### 4. **explore_videos** - فيديوهات Explore
```sql
- id, store_id, bunny_video_id, video_url
- stream_url (HLS), thumbnail_url, mp4_url
- title, description, duration_seconds
- views_count, likes_count, shares_count, saves_count
- engagement_score (weighted algorithm)
- linked_type (product/category/none)
- linked_product_id, linked_category_id
- is_active, is_archived, last_view_at
- created_at, updated_at
```

#### 5. **video_interactions** - تفاعلات المستخدمين
```sql
- id, video_id, user_id
- interaction_type (view/like/save/share)
- created_at
- UNIQUE(video_id, user_id, interaction_type) لـ view/like/save
```

#### 6. **product_promotions** - عروض ترويجية
```sql
- id, store_id, product_id, promotion_type
- budget, spent, target_views, reached_views
- start_date, end_date, is_active
- created_at, updated_at
```

#### 7. **trending_products** - منتجات رائجة
```sql
- id, product_id, trending_score, views_this_week
- sales_this_week, position, is_active
- created_at, updated_at
```

#### 8. **store_followers** - متابعي المتاجر
```sql
- id, store_id, user_id, created_at
- UNIQUE(store_id, user_id)
```

#### 9. **product_reviews** - تقييمات المنتجات
```sql
- id, product_id, user_id, rating (1-5)
- review_text, images (JSON)
- is_verified_purchase, created_at, updated_at
```

---

## 🚀 Backend APIs (Node.js/Express)

### 🔐 Authentication Middleware
**File:** `dalma-api/middleware/auth.js`

```javascript
import { authenticateToken } // يتحقق من JWT Token
import { isProvider }        // يتحقق من provider_request_status='approved'
import { isAdmin }           // يتحقق من role='admin'
```

---

### 📦 Provider Store APIs
**Base URL:** `/api/provider/store`
**Middleware:** `authenticateToken`, `isProvider`

#### 1. POST `/create` - إنشاء متجر بعد الموافقة
**Body:**
```json
{
  "store_name": "متجر الذهب",
  "store_description": "متخصصون في الذهب الأصلي",
  "store_logo": "https://...",
  "store_banner": "https://...",
  "business_license": "CR-123456",
  "contact_phone": "+966501234567",
  "contact_email": "store@example.com",
  "address": "الرياض، حي النخيل",
  "city": "الرياض"
}
```

#### 2. GET `/` - جلب بيانات المتجر
**Response:**
```json
{
  "store": {
    "id": 1,
    "store_name": "متجر الذهب",
    "store_rating": 4.5,
    "is_verified": true,
    "owner_name": "أحمد محمد",
    "owner_phone": "+966501234567"
  }
}
```

#### 3. PUT `/` - تحديث معلومات المتجر
**Body:** (أي حقل من: store_name, store_description, contact_phone, etc.)

#### 4. GET `/stats` - إحصائيات المتجر
**Response:**
```json
{
  "products_count": 45,
  "videos_count": 12,
  "followers_count": 350,
  "recent_products": [...],
  "recent_videos": [...]
}
```

#### 5. GET `/categories` - قائمة التصنيفات
**Response:**
```json
{
  "categories": [
    {
      "id": 1,
      "name_ar": "إلكترونيات",
      "children": [
        { "id": 5, "name_ar": "هواتف" },
        { "id": 6, "name_ar": "حواسيب" }
      ]
    }
  ]
}
```

---

### 🛍️ Provider Products APIs
**Base URL:** `/api/provider/products`

#### 1. POST `/` - إضافة منتج
**Body:**
```json
{
  "category_id": 1,
  "name_ar": "هاتف ذكي",
  "name_en": "Smartphone",
  "description_ar": "هاتف بمواصفات عالية",
  "price": 2500,
  "discount_type": "percentage",
  "discount_value": 10,
  "images": ["https://...", "https://..."],
  "thumbnail": "https://...",
  "specifications": {
    "ram": "8GB",
    "storage": "256GB"
  },
  "variants": [
    { "color": "أسود", "size": "128GB", "price_diff": 0 }
  ],
  "tags": ["جديد", "عروض"],
  "stock_quantity": 50,
  "sku": "PHONE-001"
}
```

**Auto-calculation:** `final_price = price - discount`

#### 2. GET `/` - قائمة المنتجات
**Query Params:**
- `page=1`
- `limit=20`
- `category_id=5`
- `is_active=true`
- `is_trending=true`
- `search=هاتف`

#### 3. GET `/:id` - تفاصيل منتج
**Response:** منتج + اسم التصنيف + متوسط التقييمات

#### 4. PUT `/:id` - تحديث منتج
**Body:** أي حقل (مع إعادة حساب `final_price` تلقائياً)

#### 5. DELETE `/:id` - حذف منتج (soft delete)
يضع `is_active = false` بدلاً من الحذف النهائي

#### 6. POST `/:id/images` - إضافة صور للمنتج
**Body:**
```json
{
  "images": ["https://new-image1.jpg", "https://new-image2.jpg"]
}
```
يُضاف للصور الموجودة (لا يستبدلها)

---

### 🎥 Provider Videos APIs
**Base URL:** `/api/provider/videos`

#### 1. POST `/upload` - رفع فيديو إلى Bunny.net
**Body:**
```json
{
  "title": "مراجعة هاتف جديد",
  "description": "شرح مفصل للمزايا",
  "video": "base64_encoded_video_data",
  "linked_type": "product",
  "linked_product_id": 12
}
```

**Flow:**
1. POST إلى Bunny.net لإنشاء فيديو
2. PUT لرفع الملف
3. حفظ metadata في PostgreSQL

**Response:**
```json
{
  "message": "تم رفع الفيديو بنجاح",
  "video": {
    "id": 5,
    "bunny_video_id": "abc-123",
    "stream_url": "https://vz-7acdcb5c-236.b-cdn.net/abc-123/playlist.m3u8",
    "thumbnail_url": "https://vz-7acdcb5c-236.b-cdn.net/abc-123/thumbnail.jpg"
  }
}
```

#### 2. GET `/` - قائمة الفيديوهات
**Query:**
- `page=1`, `limit=20`
- `linked_type=product`
- `is_active=true`

**Response:** فيديوهات + بيانات المنتج/التصنيف المرتبط

#### 3. GET `/:id` - تفاصيل فيديو
**Response:** فيديو + عدد الإعجابات/المشاهدات/المشاركات

#### 4. PUT `/:id/link` - ربط فيديو بمنتج
**Body:**
```json
{
  "linked_type": "product",
  "linked_product_id": 25
}
```

#### 5. DELETE `/:id` - حذف فيديو
- Soft delete في PostgreSQL (`is_active = false`)
- Hard delete من Bunny.net (DELETE API call)

#### 6. GET `/:id/analytics` - تحليلات الفيديو
**Response:**
```json
{
  "video_id": 5,
  "views_count": 1250,
  "likes_count": 89,
  "saves_count": 34,
  "shares_count": 12,
  "engagement_score": 678.5,
  "engagement_rate": 10.8,
  "interactions": [
    { "type": "view", "count": 1250 },
    { "type": "like", "count": 89 }
  ]
}
```

---

### 🔍 Explore Videos APIs (Public)
**Base URL:** `/api/explore/videos`
**Middleware:** `authenticateToken`

#### 1. GET `/` - جلب Feed الفيديوهات
**Query:**
- `page=1`, `limit=20`
- `category_id=5`

**Response:**
```json
{
  "videos": [
    {
      "id": 5,
      "store_name": "متجر الذهب",
      "store_logo": "https://...",
      "store_verified": true,
      "stream_url": "https://vz-7acdcb5c-236.b-cdn.net/.../playlist.m3u8",
      "thumbnail_url": "https://...",
      "title": "مراجعة هاتف",
      "views_count": 1250,
      "likes_count": 89,
      "engagement_score": 678.5,
      "linked_product": {
        "id": 12,
        "name_ar": "هاتف ذكي",
        "price": 2500,
        "final_price": 2250,
        "thumbnail": "https://..."
      }
    }
  ],
  "pagination": {
    "currentPage": 1,
    "itemsPerPage": 20,
    "hasMore": true
  }
}
```

**Sorting:** `ORDER BY engagement_score DESC, created_at DESC`

#### 2. POST `/:id/view` - تسجيل مشاهدة
- يزيد `views_count` بـ 1
- يحدث `last_view_at`
- يحفظ في `video_interactions`

#### 3. POST `/:id/like` - إعجاب/إلغاء إعجاب
**Response:**
```json
{ "message": "تم الإعجاب", "liked": true }
```

#### 4. POST `/:id/save` - حفظ/إلغاء حفظ
**Response:**
```json
{ "message": "تم الحفظ", "saved": true }
```

#### 5. POST `/:id/share` - تسجيل مشاركة
- يزيد `shares_count` بـ 1
- يمكن تكرار المشاركات (لا يوجد UNIQUE constraint)

**Engagement Score Formula:**
```javascript
engagement_score = (likes * 3) + (saves * 5) + (shares * 10) + (views * 0.1)
```

---

### 🏪 Stores Public APIs
**Base URL:** `/api/stores`

#### 1. GET `/:id` - معلومات متجر
**Response:**
```json
{
  "store": {
    "id": 1,
    "store_name": "متجر الذهب",
    "store_description": "...",
    "store_rating": 4.5,
    "is_verified": true,
    "followers_count": 350,
    "owner_name": "أحمد"
  }
}
```

#### 2. GET `/:id/products` - منتجات متجر
#### 3. GET `/:id/videos` - فيديوهات متجر
#### 4. POST `/:id/follow` - متابعة/إلغاء متابعة
#### 5. GET `/:id/following-status` - حالة المتابعة

---

## 📱 Flutter UI Components

### 1. **explore_page.dart** - صفحة Explore (TikTok-style)
```dart
import 'package:aldlma/explore_page.dart';
```

**Features:**
- ✅ PageView عمودي للتمرير بين الفيديوهات
- ✅ VideoPlayerController مع Auto-play و Looping
- ✅ أزرار تفاعل: إعجاب، حفظ، مشاركة
- ✅ ProductLinkCard لعرض المنتج المرتبط
- ✅ ProductBottomSheet للتفاصيل الكاملة
- ✅ تسجيل المشاهدات تلقائياً
- ✅ API Calls لجميع التفاعلات

**Usage:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => ExplorePage()),
);
```

---

### 2. **provider_video_upload.dart** - رفع فيديو
```dart
import 'package:aldlma/provider_video_upload.dart';
```

**Features:**
- ✅ اختيار فيديو من المعرض (ImagePicker)
- ✅ معاينة الفيديو قبل الرفع
- ✅ عنوان + وصف + ربط بمنتج
- ✅ Progress Indicator أثناء الرفع
- ✅ تحويل إلى Base64 ورفع لـ Bunny.net
- ✅ Dropdown لاختيار منتج

**Usage:**
```dart
final result = await Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => ProviderVideoUploadPage()),
);
if (result == true) {
  // تحديث القائمة
}
```

---

### 3. **store_profile_page.dart** - صفحة المتجر
```dart
import 'package:aldlma/store_profile_page.dart';
```

**Features:**
- ✅ SliverAppBar مع Banner و Logo
- ✅ زر متابعة/إلغاء متابعة
- ✅ TabBar: منتجات، فيديوهات
- ✅ GridView للمنتجات والفيديوهات
- ✅ عرض التقييم وعدد المتابعين
- ✅ علامة Verified للمتاجر الموثقة

**Usage:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => StoreProfilePage(storeId: "1"),
  ),
);
```

---

## 🎨 الألوان والثيم

### Dark Mode
- **Primary:** `#D4AF37` (ذهبي)
- **Background:** `#1A1A1A`

### Light Mode
- **Primary:** `#10b981` (أخضر)
- **Background:** `#FFFFFF`

---

## 🔐 التوثيق (Authentication)

جميع الـ APIs تتطلب **JWT Token**:

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Middleware Checks:**
1. `authenticateToken` - يتحقق من صلاحية التوكن
2. `isProvider` - يتحقق من `provider_request_status='approved'`
3. `isAdmin` - يتحقق من `role='admin'`

---

## 📊 معادلة Engagement Score

```javascript
engagement_score = 
  (likes_count * 3) + 
  (saves_count * 5) + 
  (shares_count * 10) + 
  (views_count * 0.1)
```

**Weights:**
- **Views:** 0.1 (كل 1000 مشاهدة = 100 نقطة)
- **Likes:** 3 (كل إعجاب = 3 نقاط)
- **Saves:** 5 (كل حفظ = 5 نقاط)
- **Shares:** 10 (كل مشاركة = 10 نقاط)

---

## 🎬 Bunny.net Integration

### Configuration
- **Library ID:** `547399`
- **CDN:** `vz-7acdcb5c-236.b-cdn.net`
- **API Key:** في Environment Variables

### Upload Flow
1. **Create Video:**
   ```http
   POST https://video.bunnycdn.com/library/547399/videos
   Body: { "title": "مراجعة منتج" }
   ```

2. **Upload File:**
   ```http
   PUT https://video.bunnycdn.com/library/547399/videos/{videoId}
   Headers: { "Content-Type": "application/octet-stream" }
   Body: <binary_video_data>
   ```

3. **URLs Generated:**
   - HLS Stream: `.../playlist.m3u8`
   - Thumbnail: `.../thumbnail.jpg`
   - MP4: `.../play_720p.mp4`

---

## 🚀 الأوامر والنشر

### Backend (Render)
```bash
cd dalma-api
npm install
npm start  # يشغل index.js على Port 3000
```

**Environment Variables:**
```env
DATABASE_URL=postgres://...
JWT_SECRET=your_secret
BUNNY_API_KEY=your_bunny_key
BUNNY_LIBRARY_ID=547399
BUNNY_CDN_URL=https://vz-7acdcb5c-236.b-cdn.net
```

### Flutter App
```bash
cd aldlma
flutter pub get
flutter run
```

**Required Packages:**
```yaml
dependencies:
  video_player: ^2.8.0
  http: ^1.1.0
  provider: ^6.1.0
  cached_network_image: ^3.3.0
  share_plus: ^7.2.0
  image_picker: ^1.0.0
```

---

## 📁 الملفات الجديدة

### Backend
1. `dalma-api/routes/providerStore.js` (346 lines)
2. `dalma-api/routes/providerProducts.js` (461 lines)
3. `dalma-api/routes/providerVideos.js` (408 lines)
4. `dalma-api/routes/exploreVideos.js` (400+ lines)
5. `dalma-api/routes/storesPublic.js` (200+ lines)
6. `dalma-api/middleware/auth.js` (58 lines)

### Flutter
1. `aldlma/lib/explore_page.dart` (700+ lines)
2. `aldlma/lib/provider_video_upload.dart` (500+ lines)
3. `aldlma/lib/store_profile_page.dart` (600+ lines)

---

## ✅ الميزات المكتملة

### Backend
✅ Provider Store APIs (5 endpoints)
✅ Provider Products APIs (6 endpoints)
✅ Provider Videos APIs (6 endpoints)
✅ Explore Videos APIs (5 endpoints)
✅ Stores Public APIs (5 endpoints)
✅ Authentication Middleware
✅ Bunny.net Integration
✅ Engagement Score Algorithm
✅ Video Interactions Tracking

### Frontend
✅ Explore Page (TikTok-style)
✅ Video Upload Page
✅ Store Profile Page
✅ Video Player Controls
✅ Product Link Overlay
✅ Follow System
✅ Like/Save/Share Functionality

---

## 📝 الخطوات التالية (اختياري)

1. **Product Detail Page** - صفحة تفاصيل المنتج كاملة
2. **Shopping Cart** - سلة التسوق والدفع
3. **Admin Dashboard** - لوحة تحكم لإدارة المتاجر
4. **Analytics Dashboard** - تحليلات للتجار
5. **Push Notifications** - إشعارات للمتابعين عند رفع فيديو
6. **Search & Filters** - بحث متقدم بالفيديوهات والمنتجات
7. **Trending Algorithm** - خوارزمية لعرض الفيديوهات الرائجة

---

## 🎯 ملخص النظام

هذا نظام تجارة إلكترونية متكامل بنمط TikTok:
- التجار يرفعون فيديوهات لمنتجاتهم
- المستخدمون يتصفحون بشكل عمودي (TikTok-style)
- تفاعلات كاملة (إعجاب، حفظ، مشاركة)
- ربط مباشر بين الفيديو والمنتج
- نظام متابعة للمتاجر
- خوارزمية Engagement Score لترتيب الفيديوهات
- استضافة فيديوهات احترافية عبر Bunny.net

---

**📌 جاهز للتشغيل والاختبار!**
