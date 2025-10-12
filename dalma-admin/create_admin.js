import 'dotenv/config';
import bcrypt from 'bcryptjs';
import pg from 'pg';

const { Pool } = pg;

const pool = new Pool({
  connectionString: 'postgresql://dalma_user:dalma_password@localhost:5432/dalma_db',
  ssl: false
});

async function createAdminUser() {
  try {
    console.log('🔐 إنشاء مستخدم إداري افتراضي...');
    
    // تشفير كلمة المرور المعقدة
    const hashedPassword = await bcrypt.hash('V^w*J)&<4uhzuEzq', 12);
    
    // إدراج المستخدم الإداري
    const { rows } = await pool.query(`
      INSERT INTO admin_users (username, password, role, is_active) 
      VALUES ($1, $2, $3, $4) 
      ON CONFLICT (username) DO UPDATE SET
        password = EXCLUDED.password,
        role = EXCLUDED.role,
        is_active = EXCLUDED.is_active
      RETURNING *
    `, ['admin', hashedPassword, 'admin', true]);
    
    console.log('✅ تم إنشاء المستخدم الإداري بنجاح!');
    console.log('📋 بيانات الدخول:');
    console.log('   اسم المستخدم: admin');
    console.log('   كلمة المرور: V^w*J)&<4uhzuEzq');
    console.log('   الدور: admin');
    console.log('   الحالة: مفعل');
    console.log('   مستوى الأمان: عالي جداً (12 جولة تشفير)');
    
    // إنشاء إعدادات افتراضية
    await pool.query(`
      INSERT INTO home_settings (header_title, header_subtitle, banner_images, partners, sections) 
      VALUES ($1, $2, $3, $4, $5)
      ON CONFLICT (id) DO NOTHING
    `, [
      'مرحباً بك في الدلما',
      'منصة الخدمات المحلية الأولى في عرعر',
      JSON.stringify(['banner1.jpg', 'banner2.jpg']),
      JSON.stringify([
        { name: 'شريك 1', logo: 'partner1.png', url: 'https://example.com' },
        { name: 'شريك 2', logo: 'partner2.png', url: 'https://example.com' }
      ]),
      JSON.stringify([
        { name: 'مطاعم', icon: 'restaurant.png', color: '#FF6B6B' },
        { name: 'صيانة', icon: 'maintenance.png', color: '#4ECDC4' },
        { name: 'تنظيف', icon: 'cleaning.png', color: '#45B7D1' },
        { name: 'حلاقة', icon: 'barber.png', color: '#96CEB4' }
      ])
    ]);
    
    console.log('✅ تم إنشاء الإعدادات الافتراضية');
    
  } catch (error) {
    console.error('❌ خطأ في إنشاء المستخدم الإداري:', error.message);
  } finally {
    await pool.end();
  }
}

createAdminUser();
