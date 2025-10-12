import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import pg from 'pg';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { body, validationResult } from 'express-validator';
import crypto from 'crypto';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const { Pool } = pg;
const app = express();

// 🔐 Security Headers
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://cdnjs.cloudflare.com"],
      scriptSrc: ["'self'", "'unsafe-inline'", "https://cdnjs.cloudflare.com"],
      imgSrc: ["'self'", "data:", "https:"],
      fontSrc: ["'self'", "https://cdnjs.cloudflare.com"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));

// 🛡️ Rate Limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: {
    error: 'تم تجاوز الحد المسموح من الطلبات',
    details: 'يرجى المحاولة مرة أخرى بعد 15 دقيقة'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // limit each IP to 5 auth requests per windowMs
  message: {
    error: 'تم تجاوز الحد المسموح من محاولات تسجيل الدخول',
    details: 'يرجى المحاولة مرة أخرى بعد 15 دقيقة'
  }
});

app.use(limiter);
app.use('/api/auth', authLimiter);

// 🔒 CORS Configuration
app.use(cors({ 
  origin: process.env.NODE_ENV === 'production' 
    ? ['https://yourdomain.com'] // Replace with your actual domain
    : ['http://localhost:3000', 'http://127.0.0.1:3000', 'http://localhost:5000'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// ==== SECURITY FUNCTIONS ====
const SALT_ROUNDS = 12;
const JWT_SECRET = process.env.JWT_SECRET || crypto.randomBytes(64).toString('hex');

// 🔐 تشفير كلمة المرور
const hashPassword = async (password) => {
  try {
    const salt = await bcrypt.genSalt(SALT_ROUNDS);
    return await bcrypt.hash(password, salt);
  } catch (error) {
    throw new Error('خطأ في تشفير كلمة المرور');
  }
};

// 🔍 التحقق من كلمة المرور
const verifyPassword = async (password, hashedPassword) => {
  try {
    return await bcrypt.compare(password, hashedPassword);
  } catch (error) {
    throw new Error('خطأ في التحقق من كلمة المرور');
  }
};

// 🎫 إنشاء JWT Token
const generateToken = (userId, username, role) => {
  return jwt.sign(
    { 
      userId, 
      username,
      role,
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + (8 * 60 * 60) // 8 hours
    },
    JWT_SECRET,
    { algorithm: 'HS256' }
  );
};

// 🔍 التحقق من JWT Token
const verifyToken = (token) => {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (error) {
    throw new Error('رمز الدخول غير صحيح أو منتهي الصلاحية');
  }
};

// 🧹 تنظيف المدخلات
const sanitizeInput = (input) => {
  if (typeof input !== 'string') return input;
  return input
    .trim()
    .replace(/[<>]/g, '') // إزالة HTML tags
    .replace(/['"]/g, '') // إزالة quotes
    .substring(0, 255); // تحديد الطول الأقصى
};

// 🔒 Middleware للتحقق من المصادقة
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ 
      error: 'رمز الدخول مطلوب',
      code: 'MISSING_TOKEN'
    });
  }

  try {
    const decoded = verifyToken(token);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(403).json({ 
      error: 'رمز الدخول غير صحيح',
      code: 'INVALID_TOKEN'
    });
  }
};

// 🔒 Middleware للتحقق من الصلاحيات
const requireRole = (roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: 'غير مصرح بالوصول' });
    }
    
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'ليس لديك صلاحية للوصول لهذه الصفحة' });
    }
    
    next();
  };
};

// ==== LOGGING SYSTEM ====
const logActivity = (action, details = {}) => {
  const timestamp = new Date().toLocaleString('ar-SA', { 
    timeZone: 'Asia/Riyadh',
    year: 'numeric',
    month: '2-digit', 
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  });
  
  console.error(`\n🔄 [${timestamp}] ${action}`);
  if (Object.keys(details).length > 0) {
    console.error(`📊 التفاصيل:`, JSON.stringify(details, null, 2));
  }
  console.error('─'.repeat(60));
  
  console.log(`\n🔄 [${timestamp}] ${action}`);
  if (Object.keys(details).length > 0) {
    console.log(`📊 التفاصيل:`, JSON.stringify(details, null, 2));
  }
  console.log('─'.repeat(60));
};

// ==== DATABASE CONNECTION ====
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:password@localhost:5432/aldlma',
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// ==== API ROUTES ====

// 🏥 Health Check
app.get('/api/health', (req, res) => {
  logActivity('🏥 فحص صحة الخادم الإداري');
  res.json({ 
    ok: true, 
    ts: Date.now(),
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    security: 'enabled',
    service: 'AALDMA Admin Panel'
  });
});

// 🔐 تسجيل دخول الإدارة
app.post('/api/auth/login', [
  body('username').notEmpty().withMessage('اسم المستخدم مطلوب'),
  body('password').notEmpty().withMessage('كلمة المرور مطلوبة')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'بيانات غير صحيحة',
        details: errors.array()
      });
    }

    const { username, password } = req.body;
    const cleanUsername = sanitizeInput(username);
    
    logActivity('🔑 محاولة تسجيل دخول إداري', { username: cleanUsername });
    
    // البحث عن المستخدم الإداري
    const { rows } = await pool.query(
      'SELECT id, username, password, role, is_active FROM admin_users WHERE username = $1',
      [cleanUsername]
    );
    
    if (rows.length === 0) {
      logActivity('❌ محاولة تسجيل دخول إداري فاشلة - مستخدم غير موجود', { username: cleanUsername });
      return res.status(401).json({ 
        error: 'اسم المستخدم أو كلمة المرور غير صحيحة',
        code: 'INVALID_CREDENTIALS'
      });
    }
    
    const user = rows[0];
    
    if (!user.is_active) {
      logActivity('❌ محاولة تسجيل دخول بحساب معطل', { userId: user.id, username: cleanUsername });
      return res.status(401).json({ 
        error: 'هذا الحساب معطل',
        code: 'ACCOUNT_DISABLED'
      });
    }
    
    const isValidPassword = await verifyPassword(password, user.password);
    
    if (!isValidPassword) {
      logActivity('❌ كلمة مرور خاطئة للحساب الإداري', { userId: user.id, username: cleanUsername });
      return res.status(401).json({ 
        error: 'اسم المستخدم أو كلمة المرور غير صحيحة',
        code: 'INVALID_CREDENTIALS'
      });
    }
    
    // إنشاء JWT Token
    const token = generateToken(user.id, cleanUsername, user.role);
    
    logActivity('✅ تم تسجيل الدخول الإداري بنجاح', { 
      userId: user.id, 
      username: user.username,
      role: user.role
    });
    
    res.json({
      id: user.id,
      username: user.username,
      role: user.role,
      token,
      message: 'تم تسجيل الدخول بنجاح'
    });
    
  } catch (e) {
    logActivity('❌ خطأ في تسجيل الدخول الإداري', { error: e.message });
    res.status(500).json({ error: 'خطأ داخلي في الخادم' });
  }
});

// 📊 Dashboard Statistics
app.get('/api/dashboard/stats', authenticateToken, async (req, res) => {
  try {
    logActivity('📊 طلب إحصائيات لوحة التحكم', { userId: req.user.userId });
    
    const [usersCount, mediaCount, providersCount, ordersCount, recentUsers, recentOrders] = await Promise.all([
      pool.query('SELECT COUNT(*) FROM users'),
      pool.query('SELECT COUNT(*) FROM users WHERE role = \'media\''),
      pool.query('SELECT COUNT(*) FROM users WHERE role = \'provider\''),
      pool.query('SELECT COUNT(*) FROM orders'),
      pool.query('SELECT COUNT(*) FROM users WHERE created_at > NOW() - INTERVAL \'24 hours\''),
      pool.query('SELECT COUNT(*) FROM orders WHERE created_at > NOW() - INTERVAL \'24 hours\'')
    ]);
    
    const stats = {
      totalUsers: parseInt(usersCount.rows[0].count),
      totalMedia: parseInt(mediaCount.rows[0].count),
      totalProviders: parseInt(providersCount.rows[0].count),
      totalOrders: parseInt(ordersCount.rows[0].count),
      newUsers24h: parseInt(recentUsers.rows[0].count),
      newOrders24h: parseInt(recentOrders.rows[0].count),
      timestamp: new Date().toISOString()
    };
    
    logActivity('✅ تم جلب إحصائيات لوحة التحكم', stats);
    res.json(stats);
  } catch (e) {
    logActivity('❌ خطأ في جلب إحصائيات لوحة التحكم', { error: e.message });
    res.status(500).json({ error: 'خطأ داخلي في الخادم' });
  }
});

// 🏠 Home Settings
app.get('/api/home/settings', authenticateToken, async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM home_settings ORDER BY id DESC LIMIT 1');
    res.json(rows[0] || {});
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.put('/api/home/settings', authenticateToken, requireRole(['admin', 'editor']), async (req, res) => {
  try {
    const { header_title, header_subtitle, banner_images, partners, sections } = req.body;
    
    const { rows } = await pool.query(`
      INSERT INTO home_settings (header_title, header_subtitle, banner_images, partners, sections, updated_by, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6, NOW())
      ON CONFLICT (id) DO UPDATE SET
        header_title = EXCLUDED.header_title,
        header_subtitle = EXCLUDED.header_subtitle,
        banner_images = EXCLUDED.banner_images,
        partners = EXCLUDED.partners,
        sections = EXCLUDED.sections,
        updated_by = EXCLUDED.updated_by,
        updated_at = NOW()
      RETURNING *
    `, [header_title, header_subtitle, JSON.stringify(banner_images), JSON.stringify(partners), JSON.stringify(sections), req.user.userId]);
    
    logActivity('✅ تم تحديث إعدادات الصفحة الرئيسية', { userId: req.user.userId });
    res.json(rows[0]);
  } catch (e) {
    logActivity('❌ خطأ في تحديث إعدادات الصفحة الرئيسية', { error: e.message });
    res.status(500).json({ error: e.message });
  }
});

// Serve the main dashboard
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
});

// ==== ERROR HANDLING ====
app.use((err, req, res, next) => {
  logActivity('❌ خطأ عام في الخادم الإداري', { error: err.message, stack: err.stack });
  res.status(500).json({ 
    error: 'خطأ داخلي في الخادم',
    message: process.env.NODE_ENV === 'development' ? err.message : 'حدث خطأ غير متوقع'
  });
});

// 404 Handler
app.use('*', (req, res) => {
  logActivity('❌ مسار غير موجود في الخادم الإداري', { path: req.originalUrl, method: req.method });
  res.status(404).json({ 
    error: 'المسار غير موجود',
    path: req.originalUrl 
  });
});

// ==== SERVER STARTUP ====
const port = process.env.ADMIN_PORT || 5000;

app.listen(port, () => {
  console.log(`\n🏛️ AALDMA Control Panel Started Successfully!`);
  console.log(`🔐 Security Features: ENABLED`);
  console.log(`🛡️  Password Encryption: bcrypt (${SALT_ROUNDS} rounds)`);
  console.log(`🎫 JWT Authentication: ENABLED`);
  console.log(`⚡ Rate Limiting: ENABLED`);
  console.log(`🔒 Security Headers: ENABLED`);
  console.log(`🌐 Admin Panel running on port: ${port}`);
  console.log(`📊 Dashboard: http://localhost:${port}`);
  console.log(`🔐 Security level: MAXIMUM`);
  console.log(`─`.repeat(60));
  
  // Log every 30 seconds to ensure visibility
  setInterval(() => {
    logActivity('💓 Admin Panel Heartbeat - All Systems Operational');
  }, 30000);
});

export default app;
