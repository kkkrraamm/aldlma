-- =============================================
-- حذف الصور Base64 من قاعدة البيانات
-- =============================================
-- 
-- هذا السكريبت يحذف جميع الصور المخزنة كـ Base64
-- (التي تبدأ بـ data:image/)
-- 
-- يجب تنفيذه قبل البدء باستخدام Cloudinary
-- =============================================

-- 1. عرض عدد الصور Base64 الموجودة
SELECT COUNT(*) as base64_images_count
FROM realty_listing_images
WHERE url LIKE 'data:image/%';

-- 2. عرض العقارات المتأثرة
SELECT DISTINCT l.id, l.title, l.office_id
FROM realty_listings l
JOIN realty_listing_images img ON img.listing_id = l.id
WHERE img.url LIKE 'data:image/%'
ORDER BY l.id;

-- 3. حذف الصور Base64
DELETE FROM realty_listing_images
WHERE url LIKE 'data:image/%';

-- 4. التحقق من الحذف
SELECT COUNT(*) as remaining_base64_images
FROM realty_listing_images
WHERE url LIKE 'data:image/%';

-- 5. عرض العقارات بدون صور (اختياري)
SELECT l.id, l.title, l.office_id, 
       (SELECT COUNT(*) FROM realty_listing_images WHERE listing_id = l.id) as images_count
FROM realty_listings l
WHERE l.is_active = true
ORDER BY images_count, l.id;

