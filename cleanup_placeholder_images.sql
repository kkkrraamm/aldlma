-- ═══════════════════════════════════════════════════════════════
-- 🧹 تنظيف الصور التجريبية القديمة من via.placeholder.com
-- ═══════════════════════════════════════════════════════════════
-- التاريخ: 13 نوفمبر 2025
-- الهدف: حذف جميع الصور التجريبية لحل مشكلة التطبيق
-- ═══════════════════════════════════════════════════════════════

-- 1️⃣ التحقق من عدد الصور التجريبية قبل الحذف
SELECT 
  COUNT(*) as total_placeholder_images,
  COUNT(DISTINCT listing_id) as affected_listings
FROM realty_listing_images
WHERE url LIKE '%via.placeholder%';

-- 2️⃣ عرض العقارات المتأثرة
SELECT 
  l.id,
  l.title,
  l.city,
  COUNT(li.id) as placeholder_images_count
FROM realty_listings l
JOIN realty_listing_images li ON l.id = li.listing_id
WHERE li.url LIKE '%via.placeholder%'
GROUP BY l.id, l.title, l.city
ORDER BY l.id;

-- 3️⃣ حذف جميع الصور التجريبية
DELETE FROM realty_listing_images 
WHERE url LIKE '%via.placeholder%';

-- 4️⃣ التحقق من النتيجة
SELECT 
  l.id,
  l.title,
  l.city,
  COUNT(li.id) as remaining_images
FROM realty_listings l
LEFT JOIN realty_listing_images li ON l.id = li.listing_id
GROUP BY l.id, l.title, l.city
ORDER BY l.id DESC
LIMIT 20;

-- 5️⃣ عرض العقارات التي لا تحتوي على صور الآن
SELECT 
  l.id,
  l.title,
  l.city,
  l.office_id,
  l.created_at
FROM realty_listings l
LEFT JOIN realty_listing_images li ON l.id = li.listing_id
WHERE li.id IS NULL
ORDER BY l.id DESC;

-- ═══════════════════════════════════════════════════════════════
-- ✅ تم! الآن أعد تشغيل التطبيق بـ Hot Restart (r)
-- ═══════════════════════════════════════════════════════════════

