# 📘 **Provider APIs Documentation**

## 🚀 **جميع APIs مقدم الخدمة**

### Base URL:
```
https://dalma-api.onrender.com
```

### Authentication:
جميع الطلبات تحتاج إلى Header:
```
Authorization: Bearer YOUR_JWT_TOKEN
```

---

## 🧑‍💼 **1. البروفايل (Profile)**

### GET `/api/provider/profile`
**الوصف:** جلب بروفايل مقدم الخدمة الكامل  
**Response:**
```json
{
  "profile": {
    "id": 1,
    "name": "مطعم الدلما",
    "phone": "0597414141",
    "business_name": "مطعم الدلما",
    "business_category": "مطاعم",
    "location_lat": 24.7136,
    "location_lng": 46.6753,
    "location_address": "الرياض، حي النخيل",
    "whatsapp_number": "0597414141",
    "email": "info@dalma.sa",
    "website_url": "https://dalma.sa",
    "profile_views": 150,
    "total_orders": 45,
    "avg_rating": 4.8,
    "total_reviews": 30
  },
  "deliveryOptions": { ... }
}
```

### PUT `/api/provider/profile`
**الوصف:** تحديث بيانات البروفايل  
**Body:**
```json
{
  "name": "مطعم الدلما المحدث",
  "business_name": "مطعم الدلما",
  "business_category": "مطاعم",
  "bio": "أفضل مطعم في الرياض",
  "location_lat": 24.7136,
  "location_lng": 46.6753,
  "location_address": "الرياض، حي النخيل",
  "whatsapp_number": "0597414141",
  "email": "info@dalma.sa",
  "website_url": "https://dalma.sa"
}
```

### PUT `/api/provider/images`
**الوصف:** تحديث الصور (البروفايل/اللوجو/البانر)  
**Body:**
```json
{
  "profile_image": "https://cloudinary.com/...",
  "business_logo": "https://cloudinary.com/...",
  "business_banner": "https://cloudinary.com/..."
}
```

---

## 🛍️ **2. الخدمات (Services)**

### GET `/api/provider/services`
**الوصف:** جلب جميع الخدمات  
**Response:**
```json
{
  "services": [
    {
      "id": 1,
      "service_name": "شاورما دجاج",
      "description": "شاورما دجاج طازجة",
      "price": 25.00,
      "category": "وجبات سريعة",
      "is_active": true,
      "orders_count": 120,
      "rating": 4.8,
      "addons": [
        {
          "id": 1,
          "name": "جبن إضافي",
          "price": 3.00,
          "addon_limit": 2
        }
      ]
    }
  ]
}
```

### GET `/api/provider/services/:id`
**الوصف:** جلب تفاصيل خدمة واحدة

### POST `/api/provider/services`
**الوصف:** إضافة خدمة جديدة  
**Body:**
```json
{
  "service_name": "شاورما دجاج",
  "description": "شاورما دجاج طازجة",
  "price": 25.00,
  "category": "وجبات سريعة",
  "addons": [
    {
      "name": "جبن إضافي",
      "description": "جبن موزاريلا",
      "price": 3.00,
      "limit": 2
    }
  ]
}
```

### PUT `/api/provider/services/:id`
**الوصف:** تحديث خدمة  
**Body:**
```json
{
  "service_name": "شاورما دجاج مشوي",
  "price": 28.00,
  "is_active": true
}
```

### DELETE `/api/provider/services/:id`
**الوصف:** حذف خدمة

### POST `/api/provider/services/:id/addons`
**الوصف:** إضافة إضافة لخدمة  
**Body:**
```json
{
  "name": "صوص حار",
  "description": "صوص حار مميز",
  "price": 2.00,
  "addon_limit": 1
}
```

### DELETE `/api/provider/services/:serviceId/addons/:addonId`
**الوصف:** حذف إضافة من خدمة

---

## 📦 **3. الطلبات (Orders)**

### GET `/api/provider/orders?status=pending`
**الوصف:** جلب الطلبات (مع تصفية اختيارية)  
**Query Parameters:**
- `status`: pending, preparing, ready, completed, cancelled

**Response:**
```json
{
  "orders": [
    {
      "id": 1,
      "order_number": "DLMA-2025-0001",
      "customer_name": "أحمد محمد",
      "customer_phone": "0501234567",
      "status": "pending",
      "subtotal": 50.00,
      "delivery_fee": 10.00,
      "total": 60.00,
      "payment_method": "cash",
      "payment_status": "unpaid",
      "created_at": "2025-10-14T10:30:00Z",
      "items": [
        {
          "service_name": "شاورما دجاج",
          "quantity": 2,
          "price": 25.00,
          "addons": [...]
        }
      ]
    }
  ]
}
```

### PUT `/api/provider/orders/:id/status`
**الوصف:** تحديث حالة الطلب  
**Body:**
```json
{
  "status": "preparing",
  "provider_notes": "جاري التحضير"
}
```

---

## 🚚 **4. خيارات التوصيل (Delivery Options)**

### GET `/api/provider/delivery-options`
**الوصف:** جلب خيارات التوصيل

### PUT `/api/provider/delivery-options`
**الوصف:** تحديث خيارات التوصيل  
**Body:**
```json
{
  "enable_custom_delivery": true,
  "custom_delivery_fee": 15.00,
  "enable_pickup": true,
  "jahez_enabled": true,
  "jahez_link": "https://jahez.sa/restaurant/dalma",
  "hungerstation_enabled": true,
  "hungerstation_link": "https://hungerstation.com/sa/restaurant/dalma",
  "talabat_enabled": false,
  "mrsool_enabled": false
}
```

---

## 📊 **5. الإحصاءات (Stats)**

### GET `/api/provider/stats?range=30d`
**الوصف:** جلب إحصاءات الأداء  
**Query Parameters:**
- `range`: 7d, 30d, 90d, all

**Response:**
```json
{
  "orders": {
    "total_orders": 150,
    "completed_orders": 140,
    "cancelled_orders": 10,
    "total_revenue": 5000.00
  },
  "reviews": {
    "avg_rating": 4.8,
    "total_reviews": 30
  },
  "topServices": [
    {
      "service_name": "شاورما دجاج",
      "order_count": 120,
      "total_sales": 3000.00
    }
  ],
  "repeatCustomers": 25,
  "expenses": {
    "total_expenses": 2000.00,
    "expenses_count": 15
  },
  "financial": {
    "revenue": 5000.00,
    "expenses": 2000.00,
    "netProfit": 3000.00
  }
}
```

---

## ⭐ **6. التقييمات (Reviews)**

### GET `/api/provider/reviews`
**الوصف:** جلب تقييمات العملاء  
**Response:**
```json
{
  "reviews": [
    {
      "id": 1,
      "customer_name": "أحمد محمد",
      "rating": 5,
      "comment": "ممتاز جداً",
      "order_number": "DLMA-2025-0001",
      "created_at": "2025-10-14T10:30:00Z"
    }
  ]
}
```

---

## 🔔 **7. الإشعارات (Notifications)**

### GET `/api/provider/notifications?unread_only=true`
**الوصف:** جلب الإشعارات  
**Query Parameters:**
- `unread_only`: true/false

### PUT `/api/provider/notifications/:id/read`
**الوصف:** تحديد الإشعار كمقروء

---

## 🎁 **8. العروض والخصومات (Promotions)**

### GET `/api/provider/promotions`
**الوصف:** جلب العروض

### POST `/api/provider/promotions`
**الوصف:** إضافة عرض جديد  
**Body:**
```json
{
  "service_id": 1,
  "title": "خصم 20% على الشاورما",
  "description": "عرض محدود",
  "discount_percent": 20,
  "start_date": "2025-10-15T00:00:00Z",
  "end_date": "2025-10-20T23:59:59Z"
}
```

### PUT `/api/provider/promotions/:id`
**الوصف:** تحديث عرض

### DELETE `/api/provider/promotions/:id`
**الوصف:** حذف عرض

---

## 💰 **9. المصروفات (Expenses)**

### GET `/api/provider/expenses`
**الوصف:** جلب المصروفات

### POST `/api/provider/expenses`
**الوصف:** إضافة مصروف جديد  
**Body:**
```json
{
  "name": "شراء مواد خام",
  "description": "دجاج وخضروات",
  "amount": 500.00,
  "category": "مواد خام",
  "expense_date": "2025-10-14"
}
```

### DELETE `/api/provider/expenses/:id`
**الوصف:** حذف مصروف

---

## 🔐 **معلومات إضافية:**

### حالات الطلبات (Order Statuses):
- `pending` - بانتظار القبول
- `preparing` - قيد التنفيذ
- `ready` - جاهز للتسليم
- `completed` - مكتمل
- `cancelled` - ملغى

### طرق الدفع (Payment Methods):
- `cash` - نقدي
- `card` - بطاقة
- `transfer` - تحويل بنكي
- `online` - دفع إلكتروني

---

## ✅ **ملاحظات:**
1. جميع التواريخ بصيغة ISO 8601
2. جميع الأسعار بالريال السعودي
3. الـ Token يجب تجديده كل 24 ساعة
4. Rate Limiting: 100 طلب كل 15 دقيقة
5. جميع Responses بترميز UTF-8 لدعم العربية

---

## 🧪 **اختبار APIs:**

يمكنك اختبار APIs باستخدام:
- **Postman** (يوجد Collection جاهز)
- **Admin Dashboard** (واجهة ويب)
- **Flutter App** (التطبيق الرسمي)

---

**تم إنشاء هذا التوثيق بواسطة:** Dalma API System  
**آخر تحديث:** 14 أكتوبر 2025

