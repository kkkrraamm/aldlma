-- =============================================
-- AALDMA Control Panel Database Schema
-- =============================================

-- إدارة المستخدمين الإداريين
CREATE TABLE IF NOT EXISTS admin_users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  password TEXT NOT NULL,
  role VARCHAR(20) NOT NULL DEFAULT 'editor', -- admin, editor, moderator
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- إعدادات الصفحة الرئيسية
CREATE TABLE IF NOT EXISTS home_settings (
  id SERIAL PRIMARY KEY,
  header_title TEXT,
  header_subtitle TEXT,
  banner_images JSONB,
  partners JSONB,
  sections JSONB,
  created_by INTEGER REFERENCES admin_users(id),
  updated_by INTEGER REFERENCES admin_users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- إعدادات صفحة الترندات
CREATE TABLE IF NOT EXISTS trends_settings (
  id SERIAL PRIMARY KEY,
  header_title TEXT,
  header_subtitle TEXT,
  algorithm_weights JSONB, -- أوزان الخوارزمية
  verified_media_only BOOLEAN DEFAULT true,
  created_by INTEGER REFERENCES admin_users(id),
  updated_by INTEGER REFERENCES admin_users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- إعدادات صفحة الخدمات
CREATE TABLE IF NOT EXISTS services_settings (
  id SERIAL PRIMARY KEY,
  header_title TEXT,
  header_subtitle TEXT,
  categories JSONB,
  featured_services JSONB,
  created_by INTEGER REFERENCES admin_users(id),
  updated_by INTEGER REFERENCES admin_users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- إعدادات التطبيق العامة
CREATE TABLE IF NOT EXISTS app_settings (
  id SERIAL PRIMARY KEY,
  app_name TEXT DEFAULT 'الدلما',
  app_logo TEXT,
  primary_color VARCHAR(7) DEFAULT '#1E40AF',
  secondary_color VARCHAR(7) DEFAULT '#3B82F6',
  social_links JSONB,
  privacy_policy TEXT,
  terms_of_service TEXT,
  created_by INTEGER REFERENCES admin_users(id),
  updated_by INTEGER REFERENCES admin_users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- سجل أنشطة الإدارة
CREATE TABLE IF NOT EXISTS admin_activity_log (
  id SERIAL PRIMARY KEY,
  admin_user_id INTEGER REFERENCES admin_users(id),
  action VARCHAR(100) NOT NULL,
  target_type VARCHAR(50), -- user, media, provider, order, etc.
  target_id INTEGER,
  details JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- إشعارات الإدارة
CREATE TABLE IF NOT EXISTS admin_notifications (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type VARCHAR(20) DEFAULT 'info', -- info, warning, error, success
  is_read BOOLEAN DEFAULT false,
  admin_user_id INTEGER REFERENCES admin_users(id),
  created_at TIMESTAMP DEFAULT NOW()
);

-- إضافة أدوار المستخدمين في جدول المستخدمين
ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user';
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_date TIMESTAMP;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_activity TIMESTAMP DEFAULT NOW();

-- إضافة جدول المنشورات للإعلاميين
CREATE TABLE IF NOT EXISTS media_posts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  content TEXT,
  media_type VARCHAR(20) DEFAULT 'text', -- text, image, video
  media_url TEXT,
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  shares_count INTEGER DEFAULT 0,
  views_count INTEGER DEFAULT 0,
  is_approved BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- إضافة جدول التفاعلات
CREATE TABLE IF NOT EXISTS post_interactions (
  id SERIAL PRIMARY KEY,
  post_id INTEGER REFERENCES media_posts(id) ON DELETE CASCADE,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  interaction_type VARCHAR(20) NOT NULL, -- like, comment, share, view
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(post_id, user_id, interaction_type)
);

-- إضافة جدول المتابعات
CREATE TABLE IF NOT EXISTS user_follows (
  id SERIAL PRIMARY KEY,
  follower_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  following_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(follower_id, following_id)
);

-- إدراج مستخدم إداري افتراضي
INSERT INTO admin_users (username, password, role) 
VALUES ('admin', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J4Q4Q4Q4Q', 'admin')
ON CONFLICT (username) DO NOTHING;

-- إدراج إعدادات افتراضية
INSERT INTO home_settings (header_title, header_subtitle, banner_images, partners, sections) 
VALUES (
  'مرحباً بك في الدلما',
  'منصة الخدمات المحلية الأولى في عرعر',
  '["banner1.jpg", "banner2.jpg"]',
  '[{"name": "شريك 1", "logo": "partner1.png", "url": "https://example.com"}]',
  '[{"name": "مطاعم", "icon": "restaurant.png", "color": "#FF6B6B"}, {"name": "صيانة", "icon": "maintenance.png", "color": "#4ECDC4"}]'
) ON CONFLICT (id) DO NOTHING;

-- إنشاء فهارس للأداء
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_media_posts_user_id ON media_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_media_posts_created_at ON media_posts(created_at);
CREATE INDEX IF NOT EXISTS idx_admin_activity_log_admin_user_id ON admin_activity_log(admin_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_activity_log_created_at ON admin_activity_log(created_at);

-- تحديث timestamp تلقائياً
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_admin_users_updated_at BEFORE UPDATE ON admin_users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_home_settings_updated_at BEFORE UPDATE ON home_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_trends_settings_updated_at BEFORE UPDATE ON trends_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_services_settings_updated_at BEFORE UPDATE ON services_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_app_settings_updated_at BEFORE UPDATE ON app_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_media_posts_updated_at BEFORE UPDATE ON media_posts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
