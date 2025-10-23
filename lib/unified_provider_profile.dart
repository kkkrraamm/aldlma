// lib/unified_provider_profile.dart
// Dalma Oasis Profile – Unified Provider Profile (Luxury Edition)
// نسخة فاخرة محدثة مع تكامل كامل مع ثيم الدلما 🌿✨

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme_config.dart';
import 'notifications.dart';
import 'cart_manager.dart'; // CartManager + CartAddon
import 'cart_page.dart';

class UnifiedProviderProfile extends StatefulWidget {
  final int providerId;
  const UnifiedProviderProfile({super.key, required this.providerId});
  
  @override
  State<UnifiedProviderProfile> createState() => _UnifiedProviderProfileState();
}

class _UnifiedProviderProfileState extends State<UnifiedProviderProfile> 
    with TickerProviderStateMixin {
  final CartManager _cart = CartManager();

  late AnimationController _fadeCtrl, _slideCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  
  bool _showBooking = false;
  Map<String, dynamic>? _selectedProduct;
  late Map<String, dynamic> provider;
  late List<String> tabs;
  String activeTab = "";

  // إضافات مؤقتة لنموذج المنتج
  final Map<int, int> _selectedAddons = {};

  @override
  void initState() {
    super.initState();
    provider = _providerData(widget.providerId);
    tabs = (provider['tabs'] as List<String>?)?.toList() ?? ['الخدمات'];
    activeTab = tabs.first;

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _slide = Tween<Offset>(begin: const Offset(0, .2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutBack));

    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;

    final products = (provider['products'] as List<dynamic>)
        .where((p) => p['category'] == activeTab)
        .toList();

    return AnimatedBuilder(
      animation: theme,
      builder: (context, _) {
    return Scaffold(
          backgroundColor: theme.backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
                  _LuxuryHeader(provider: provider),
                  _QuickActions(provider: provider, onCall: _makeCall, onWhatsApp: _openWhatsApp, onWebsite: _openWebsite),
                  _ExperienceBar(provider: provider),

                  // تبويبات ثابتة مع مؤشر متوهج
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyTabs(
                      tabs: tabs,
                      activeTab: activeTab,
                      isDark: theme.isDarkMode,
                      onTabTap: (tab) => setState(() => activeTab = tab),
                    ),
                  ),

                  // قائمة المنتجات (Grid على الجوال = 1/2 عمود حسب العرض)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    sliver: SliverToBoxAdapter(
                child: FadeTransition(
                        opacity: _fade,
                        child: SlideTransition(
                          position: _slide,
                          child: LayoutBuilder(
                            builder: (context, c) {
                              final w = c.maxWidth;
                              final crossAxisCount = w >= 720 ? 2 : 1;
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: crossAxisCount == 1 ? 2.5 : 2.2,
                                ),
                                itemCount: products.length,
                                itemBuilder: (_, i) {
                                  final p = products[i] as Map<String, dynamic>;
                                  return _ProductCard(
                                    product: p,
                                    onOrder: () => _openAddonsSheet(p),
                                    onBook: p['allowBooking'] == true ? () => _openBooking(p) : null,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      ),
              ),
            ],
          ),
          
              // السلة العائمة
              _FloatingCart(providerId: widget.providerId, cart: _cart),

              // مودال الحجز
              if (_showBooking && _selectedProduct != null)
                _BookingModal(
                  product: _selectedProduct!,
                  onClose: () => setState(() => _showBooking = false),
                  onConfirm: (form) {
                    NotificationsService.instance.toast('تم الحجز بنجاح 🎉');
                    setState(() {
                      _showBooking = false;
                      _selectedProduct = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _openBooking(Map<String, dynamic> product) {
    setState(() {
      _selectedProduct = product;
      _showBooking = true;
    });
  }

  void _openAddonsSheet(Map<String, dynamic> product) {
    final theme = ThemeConfig.instance;
    final maxAddons = product['maxAddons'] as int? ?? 3; // الحد الأقصى
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _GlassSheet(
          child: StatefulBuilder(
            builder: (context, setM) {
              final addons = (product['addons'] as List?) ?? [];
              final selectedCount = _selectedAddons.length;
              final canAddMore = selectedCount < maxAddons;
              
              return Padding(
                padding: EdgeInsets.only(
                  left: 16, right: 16, top: 16,
                  bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Grip(),
                    const SizedBox(height: 8),
                    Text(product['name'], style: GoogleFonts.cairo(
                      color: theme.textPrimaryColor, fontWeight: FontWeight.w800, fontSize: 18,
                    )),
                    const SizedBox(height: 4),
                    // مؤشر الحد الأقصى
                    if (addons.isNotEmpty)
              Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                          color: (theme.isDarkMode ? ThemeConfig.kGoldNight : ThemeConfig.kGreen).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (theme.isDarkMode ? ThemeConfig.kGoldNight : ThemeConfig.kGreen).withOpacity(0.3),
                          ),
                ),
                child: Text(
                          'يمكنك اختيار $selectedCount من $maxAddons إضافات',
                  style: GoogleFonts.cairo(
                            color: theme.isDarkMode ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                  ),
                ),
              ),
                    const SizedBox(height: 12),
                    if (addons.isEmpty)
                      Text('لا توجد إضافات لهذا المنتج', style: GoogleFonts.cairo(color: theme.textSecondaryColor)),
                    if (addons.isNotEmpty)
                      ...addons.map((a) {
                        final id = a['id'] as int;
                        final selected = _selectedAddons.containsKey(id);
                        final canSelect = selected || canAddMore;
                        final quantity = _selectedAddons[id] ?? 0;
                        final maxQuantity = a['maxQuantity'] as int? ?? 5;
                        
                        return Opacity(
                          opacity: canSelect ? 1.0 : 0.5,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                              color: selected 
                                ? (theme.isDarkMode ? ThemeConfig.kGoldNight : ThemeConfig.kGreen).withOpacity(0.05)
                                : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected 
                                  ? (theme.isDarkMode ? ThemeConfig.kGoldNight : ThemeConfig.kGreen).withOpacity(0.3)
                                  : theme.borderColor.withOpacity(0.3),
              ),
            ),
            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                                Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                            a['name'],
                              style: GoogleFonts.cairo(
                                              color: theme.textPrimaryColor,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                              ),
                            ),
                                          const SizedBox(height: 2),
                            Text(
                                            '${(a['price'] / 100).toStringAsFixed(2)} ر.س × الكمية',
                              style: GoogleFonts.cairo(
                                              color: theme.textSecondaryColor,
                                              fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                                    Switch(
                                      value: selected,
                                      activeColor: theme.isDarkMode ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                                      onChanged: canSelect ? (v) => setM(() {
                                        if (v) {
                                          _selectedAddons[id] = 1;
                                        } else {
                                          _selectedAddons.remove(id);
                                        }
                                      }) : null,
                      ),
                    ],
                  ),
                                // أزرار الكمية (تظهر فقط عند الاختيار)
                                if (selected) ...[
                                  const SizedBox(height: 8),
                                  Row(
                              children: [
                                Text(
                                        'الكمية:',
                                  style: GoogleFonts.cairo(
                                          color: theme.textSecondaryColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // زر تقليل
                                      IconButton(
                                        onPressed: quantity > 1 ? () => setM(() {
                                          _selectedAddons[id] = quantity - 1;
                                        }) : null,
                                        icon: const Icon(Icons.remove_circle_outline),
                                        color: theme.isDarkMode ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                                        iconSize: 28,
                                      ),
                                      // عرض الكمية
                        Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                                          color: (theme.isDarkMode ? ThemeConfig.kGoldNight : ThemeConfig.kGreen).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                            color: (theme.isDarkMode ? ThemeConfig.kGoldNight : ThemeConfig.kGreen).withOpacity(0.3),
                                          ),
                                        ),
                                        child: Text(
                                          '$quantity',
                                          style: GoogleFonts.cairo(
                                            color: theme.isDarkMode ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      // زر زيادة
                                      IconButton(
                                        onPressed: quantity < maxQuantity ? () => setM(() {
                                          _selectedAddons[id] = quantity + 1;
                                        }) : null,
                                        icon: const Icon(Icons.add_circle_outline),
                                        color: theme.isDarkMode ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                                        iconSize: 28,
                                      ),
                                      const Spacer(),
                                      // السعر الإجمالي
                                          Text(
                                        '${((a['price'] * quantity) / 100).toStringAsFixed(2)} ر.س',
                                            style: GoogleFonts.cairo(
                                          color: theme.isDarkMode ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                            ),
                                          ),
                                      ],
                                    ),
                                  if (quantity >= maxQuantity)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                        'الحد الأقصى: $maxQuantity',
                                          style: GoogleFonts.cairo(
                                          color: Colors.orange,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56, // ارتفاع أكبر
                      child: _DalmaButton.primary(
                        label: '🛒  إضافة إلى السلة',
                        onTap: () {
                          // تحويل الإضافات إلى CartAddon
                          final cartAddons = <int, CartAddon>{};
                          final addons = (product['addons'] as List?) ?? [];
                          for (final addonId in _selectedAddons.keys) {
                            final addon = addons.firstWhere((a) => a['id'] == addonId);
                            cartAddons[addonId] = CartAddon(
                              id: addonId,
                              name: addon['name'],
                              description: addon['description'] ?? '',
                              price: addon['price'],
                              quantity: _selectedAddons[addonId] ?? 1,
                            );
                          }
                          
                          _cart.addToCart(
                            providerId: widget.providerId,
                            productId: product['id'],
                            productName: product['name'],
                            providerName: provider['businessName'],
                            basePrice: product['price'],
                            selectedAddons: cartAddons,
                          );
                          
                          Navigator.pop(context);
                          setState(() {}); // تحديث السلة فوراً
                          NotificationsService.instance.toast('تمت الإضافة للسلة 🛍️');
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
        );
      },
    );
  }

  // التواصل
  Future<void> _makeCall() async {
    final phone = provider['phone'];
    if (phone == null) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      NotificationsService.instance.toast('لا يمكن فتح تطبيق الهاتف');
    }
  }

  Future<void> _openWhatsApp() async {
    final phone = provider['phone'];
    if (phone == null) return;
    final cleanPhone = phone.toString().replaceAll('+', '').replaceAll(' ', '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      NotificationsService.instance.toast('لا يمكن فتح واتساب');
    }
  }

  Future<void> _openWebsite() async {
    final website = provider['website'];
    if (website == null) return;
    final uri = Uri.parse('https://$website');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      NotificationsService.instance.toast('لا يمكن فتح المتصفح');
    }
  }

  // بيانات نموذجية – اربط لاحقًا بقاعدتك
  Map<String, dynamic> _providerData(int id) {
    final map = {
      1: {
        'id': 1,
        'businessName': 'مطعم الدلما التراثي',
        'businessDescription': 'أطباق سعودية تراثية بطابع فاخر.',
        'category': 'مطاعم',
        'logo': '🍽️',
        'rating': 4.8,
        'totalReviews': 127,
        'isVerified': true,
        'workingHours': 'السبت - الخميس: 6:00 ص - 12:00 ص',
        'address': 'عرعر، شارع الملك فهد',
        'specialties': ['كبسة', 'مندي', 'مظبي', 'حنيذ'],
        'phone': '+966501234567',
        'website': 'www.dalma-restaurant.com',
        'tabs': ['الأطباق الرئيسية', 'المقبلات', 'الشوربات', 'المشروبات', 'الحلويات', 'السلطات'],
        'products': [
          {
            'id': 1,
            'name': 'كبسة لحم الدلما الملكية',
            'description': 'لحم خروف طازج مع بهارات الدلما الخاصة.',
            'price': 4500,
            'allowOrder': true,
            'allowBooking': false,
            'category': 'الأطباق الرئيسية',
            'isPopular': true,
            'emoji': '🍛',
            'maxAddons': 2, // الحد الأقصى للإضافات
            'addons': [
              {'id': 1, 'name': 'لحم إضافي', 'price': 1500, 'description': 'قطع لحم إضافية', 'maxQuantity': 3},
              {'id': 2, 'name': 'رز إضافي', 'price': 800, 'description': 'صحن رز كبير', 'maxQuantity': 5},
              {'id': 3, 'name': 'سلطة', 'price': 600, 'description': 'سلطة طازجة', 'maxQuantity': 2},
              {'id': 4, 'name': 'شوربة', 'price': 700, 'description': 'شوربة ساخنة', 'maxQuantity': 4},
            ],
              },
              {
                'id': 2,
            'name': 'مضغوط لحم',
            'description': 'نكهة مدخنة أصيلة.',
            'price': 4200,
            'allowOrder': true,
            'allowBooking': true,
            'category': 'الأطباق الرئيسية',
            'emoji': '🥘',
            'addons': [],
          },
          {
            'id': 3,
            'name': 'مندي دجاج',
            'description': 'دجاج مشوي على الطريقة اليمنية.',
            'price': 3800,
            'allowOrder': true,
            'allowBooking': false,
            'category': 'الأطباق الرئيسية',
            'emoji': '🍗',
            'addons': [{'id': 10, 'name': 'صحن إضافي', 'price': 500}],
          },
          {
            'id': 4,
            'name': 'شوربة فطر كريمية',
            'description': 'قوام مخملي غني.',
            'price': 1800,
            'allowOrder': true,
            'allowBooking': false,
            'category': 'الشوربات',
            'emoji': '🍲',
            'addons': [{'id': 3, 'name': 'خبز محمّص', 'price': 400}],
          },
          {
            'id': 5,
            'name': 'شوربة عدس',
            'description': 'دافئة ومغذية.',
            'price': 1200,
            'allowOrder': true,
            'allowBooking': false,
            'category': 'الشوربات',
            'emoji': '🥣',
            'addons': [],
          },
          {
            'id': 6,
            'name': 'سمبوسة لحم',
            'description': 'مقرمشة وخفيفة.',
            'price': 1200,
            'allowOrder': true,
            'allowBooking': false,
            'category': 'المقبلات',
            'emoji': '🥟',
            'addons': [],
          },
          {
            'id': 7,
            'name': 'كبة مقلية',
            'description': 'مقرمشة من الخارج طرية من الداخل.',
            'price': 1500,
            'allowOrder': true,
            'allowBooking': false,
            'category': 'المقبلات',
            'emoji': '🧆',
            'addons': [],
          },
          {
            'id': 8,
            'name': 'عصير برتقال طازج',
            'description': 'معصور يومياً.',
            'price': 800,
            'allowOrder': true,
            'allowBooking': false,
            'category': 'المشروبات',
            'emoji': '🍊',
            'addons': [{'id': 11, 'name': 'حجم كبير', 'price': 300}],
          },
          {
            'id': 9,
            'name': 'قهوة عربية',
            'description': 'بنكهة الهيل الأصيلة.',
            'price': 600,
            'allowOrder': true,
            'allowBooking': false,
            'category': 'المشروبات',
            'emoji': '☕',
            'addons': [],
          },
          {
            'id': 10,
            'name': 'كنافة بالقشطة',
            'description': 'حلويات شرقية فاخرة.',
            'price': 2500,
            'allowOrder': true,
            'allowBooking': false,
            'category': 'الحلويات',
            'emoji': '🍰',
            'addons': [{'id': 12, 'name': 'قشطة إضافية', 'price': 500}],
          },
          {
            'id': 11,
            'name': 'بسبوسة',
            'description': 'محلاة بالعسل.',
            'price': 1800,
            'allowOrder': true,
            'allowBooking': false,
            'category': 'الحلويات',
            'emoji': '🧁',
            'addons': [],
          },
          {
            'id': 12,
            'name': 'سلطة فتوش',
            'description': 'خضار طازجة مع الخبز المحمص.',
            'price': 1500,
            'allowOrder': true,
            'allowBooking': false,
            'category': 'السلطات',
            'emoji': '🥗',
            'addons': [],
          },
          {
            'id': 13,
            'name': 'تبولة',
            'description': 'بقدونس طازج وليمون.',
            'price': 1200,
            'allowOrder': true,
            'allowBooking': false,
            'category': 'السلطات',
            'emoji': '🌿',
            'addons': [],
          },
        ],
      },
    };
    return map[id] ?? map[1]!;
  }
}

/// =========================
/// أقسام الواجهة (Widgets)
/// =========================

class _LuxuryHeader extends StatelessWidget {
  final Map<String, dynamic> provider;
  const _LuxuryHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 280,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // خلفية متدرجة
            Container(decoration: BoxDecoration(gradient: theme.headerGradient)),
            // تأثير زجاج خفيف فوق التدرج
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 180,
                margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: theme.cardColor.withOpacity(isDark ? .35 : .5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.borderColor.withOpacity(.3)),
                  boxShadow: theme.cardShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          // اللوجو الدائري مع توهج ناعم
            Container(
                            width: 84, height: 84,
              decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark 
                                ? ThemeConfig.kNightSoft.withOpacity(.4)
                                : Colors.white.withOpacity(.85),
                        boxShadow: [
                          BoxShadow(
                                  color: (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen)
                                      .withOpacity(isDark ? .15 : .2),
                                  blurRadius: isDark ? 12 : 16,
                                  spreadRadius: 0,
                                )
                        ],
                      ),
                      child: Center(
                        child: Text(
                                provider['logo'] ?? '🌿',
                                style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                          const SizedBox(height: 10),
                                    Text(
                            provider['businessName'] ?? 'مزود الخدمة',
                            textAlign: TextAlign.center,
                                      style: GoogleFonts.cairo(
                              color: theme.textPrimaryColor,
                              fontWeight: FontWeight.w900,
                                  fontSize: 18,
                              letterSpacing: .3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              const Icon(Icons.star, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text('${provider['rating'] ?? 0.0}',
                                  style: GoogleFonts.cairo(color: theme.textPrimaryColor, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 6),
                              Text('(${provider['totalReviews'] ?? 0} تقييم)',
                                  style: GoogleFonts.cairo(color: theme.textSecondaryColor)),
                              const SizedBox(width: 8),
                              if (provider['isVerified'] == true)
                                  Row(
                                children: [
                                    Icon(Icons.verified, color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen, size: 18),
                                    const SizedBox(width: 4),
                                    Text('موثّق', style: GoogleFonts.cairo(color: theme.textSecondaryColor)),
                                    ],
                                  ),
                                ],
                            ),
                          ],
                        ),
                  ),
                ),
                ),
              ),
            ),

            // أزرار أعلى (رجوع + مشاركة)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Row(
            children: [
                    _RoundIcon(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.maybePop(context),
                    ),
                    const Spacer(),
                    _RoundIcon(icon: Icons.share_rounded, onTap: () {
                      NotificationsService.instance.toast('مشاركة البروفايل 📤');
                    }),
                    const SizedBox(width: 8),
                    _RoundIcon(icon: Icons.favorite_border_rounded, onTap: () {
                      NotificationsService.instance.toast('تمت الإضافة للمفضلة ❤️');
                    }),
                  ],
                    ),
                  ),
                ),
              ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final Map<String, dynamic> provider;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onWebsite;
  
  const _QuickActions({
    required this.provider,
    required this.onCall,
    required this.onWhatsApp,
    required this.onWebsite,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
          child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
                children: [
            Expanded(child: _DalmaButton.glass(icon: Icons.phone, label: 'اتصال', onTap: onCall)),
            const SizedBox(width: 10),
            Expanded(child: _DalmaButton.glass(icon: Icons.chat_bubble, label: 'واتساب', onTap: onWhatsApp)),
            const SizedBox(width: 10),
            Expanded(child: _DalmaButton.glass(icon: Icons.language, label: 'الموقع', onTap: onWebsite)),
          ],
          ),
        ),
      );
  }
}

class _ExperienceBar extends StatelessWidget {
  final Map<String, dynamic> provider;
  const _ExperienceBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final chips = (provider['specialties'] as List?)?.cast<String>() ?? [];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), // زيادة المسافة السفلية
                    child: Container(
          padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.borderColor),
            boxShadow: [ // تقليل الظل لتجنب التداخل
                BoxShadow(
                color: Colors.black.withOpacity(theme.isDarkMode ? 0.3 : 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
                ),
              ],
            ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              _InfoRow(icon: Icons.access_time, title: 'أوقات العمل', value: provider['workingHours'] ?? '-'),
              const SizedBox(height: 6),
              _InfoRow(icon: Icons.location_on, title: 'العنوان', value: provider['address'] ?? '-'),
              if (chips.isNotEmpty) const SizedBox(height: 10),
              if (chips.isNotEmpty)
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: chips.map((s) => _Chip(s)).toList(),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onOrder;
  final VoidCallback? onBook;

  const _ProductCard({
    required this.product,
    required this.onOrder,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    final price = (product['price'] ?? 0) / 100;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
        color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
        boxShadow: theme.cardShadow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOrder,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // صورة/أيقونة
                  Container(
                width: 70, height: 70,
                    decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                    colors: isDark
                        ? [ThemeConfig.kNightSoft, ThemeConfig.kNightAccent]
                        : [ThemeConfig.kBeige, ThemeConfig.kMint],
                      ),
                    ),
                    child: Center(
                      child: Text(
                    (product['emoji'] ?? '🍽️').toString(),
                    style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
              const SizedBox(width: 12),
                  
              // معلومات
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                            Expanded(
                              child: Text(
                          product['name'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                            color: theme.textPrimaryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                                ),
                              ),
                            ),
                            if (product['isPopular'] == true)
                              Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                            color: (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kSand).withOpacity(.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kSand).withOpacity(.35)),
                          ),
                          child: Text('الأكثر طلباً', style: GoogleFonts.cairo(
                            color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kSand,
                            fontWeight: FontWeight.w700, fontSize: 11,
                          )),
                        ),
                    ]),
                    const SizedBox(height: 6),
                        Text(
                      product['description'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(color: theme.textSecondaryColor),
                    ),
                    const SizedBox(height: 10),
                    Row(
                children: [
                  Text(
                          '${price.toStringAsFixed(2)} ر.س',
                    style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w900,
                            color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        if (onBook != null)
                          _DalmaButton.ghost(
                            label: 'حجز',
                            onTap: onBook!,
                          ),
                        const SizedBox(width: 8),
                        _DalmaButton.primarySmall(
                          label: 'اطلب الآن',
                          onTap: onOrder,
                      ),
                    ],
                  ),
                ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =========================
/// مودال الحجز
/// =========================

class _BookingModal extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onClose;
  final void Function(Map<String, dynamic> form) onConfirm;
  const _BookingModal({required this.product, required this.onClose, required this.onConfirm});

  @override
  State<_BookingModal> createState() => _BookingModalState();
}

class _BookingModalState extends State<_BookingModal> {
  final _form = {
    'customerName': '',
    'customerPhone': '',
    'scheduledDate': '',
    'notes': '',
  };

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;

    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onClose,
      child: Container(
          color: Colors.black.withOpacity(.45),
      child: Center(
            child: _GlassCard(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                child: Column(
          mainAxisSize: MainAxisSize.min,
                  children: [
                      _Grip(),
                      const SizedBox(height: 10),
                      // رأس المودال
                    Row(
          children: [
            Container(
                            width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
        gradient: LinearGradient(
                                colors: isDark
                                    ? [ThemeConfig.kGoldNight, ThemeConfig.kGoldNight.withOpacity(.7)]
                                    : [ThemeConfig.kGreen, const Color(0xFF059669)],
                            ),
                          ),
                            child: const Center(child: Text('🗓️', style: TextStyle(fontSize: 24))),
                        ),
                          const SizedBox(width: 12),
                        Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                                Text(widget.product['name'] ?? '',
                                    style: GoogleFonts.cairo(color: theme.textPrimaryColor, fontWeight: FontWeight.w900, fontSize: 16)),
                                Text('${((widget.product['price'] ?? 0) / 100).toStringAsFixed(2)} ر.س',
                                    style: GoogleFonts.cairo(color: theme.textSecondaryColor)),
                            ],
                          ),
                        ),
                        IconButton(
                            onPressed: widget.onClose,
                            icon: const Icon(Icons.close_rounded),
                            color: theme.textSecondaryColor,
          ),
        ],
      ),
                      const SizedBox(height: 14),
                      // الحقول
                      _Field(label: 'الاسم', onChanged: (v) => _form['customerName'] = v),
                      const SizedBox(height: 10),
                      _Field(label: 'رقم الجوال', keyboardType: TextInputType.phone, onChanged: (v) => _form['customerPhone'] = v),
                      const SizedBox(height: 10),
                      _Field(
                        label: 'التاريخ (YYYY-MM-DD)',
                        hint: '2025-11-01',
                        onChanged: (v) => _form['scheduledDate'] = v,
                      ),
                      const SizedBox(height: 10),
                      _Field(label: 'ملاحظات', maxLines: 3, onChanged: (v) => _form['notes'] = v),
                      const SizedBox(height: 16),
        Row(
        children: [
            Expanded(
                            child: _DalmaButton.ghost(label: 'رجوع', onTap: widget.onClose),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DalmaButton.primary(
                              label: 'تأكيد الحجز',
                              onTap: () => widget.onConfirm(_form),
            ),
          ),
        ],
      ),
                ],
                ),
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}

/// =========================
/// السلة العائمة
/// =========================

class _FloatingCart extends StatelessWidget {
  final int providerId;
  final CartManager cart;
  const _FloatingCart({required this.providerId, required this.cart});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    
    // استخدام AnimatedBuilder للتحديث التلقائي
    return AnimatedBuilder(
      animation: cart,
      builder: (context, _) {
        final items = cart.getProviderCart(providerId);
        if (items.isEmpty) return const SizedBox.shrink();

        final total = cart.getProviderCartTotal(providerId) / 100;

        final isDark = theme.isDarkMode;
        final colors = isDark
            ? [ThemeConfig.kGoldNight, ThemeConfig.kGoldNight.withOpacity(.8)]
            : [ThemeConfig.kGreen, const Color(0xFF059669)];

        return Positioned(
          left: 16, right: 16, bottom: 16,
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CartPage(providerId: providerId))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                  BoxShadow(color: colors.last.withOpacity(.35), blurRadius: 18, spreadRadius: 1, offset: const Offset(0, 6)),
                ],
                    ),
                    child: Row(
                      children: [
                  const Icon(Icons.shopping_bag_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Text('${items.length} عنصر', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('${total.toStringAsFixed(2)} ر.س', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                  ),
                );
              },
    );
  }
}

/// =========================
/// عناصر مساعدة + ستايلات
/// =========================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoRow({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Icon(icon, size: 18, color: theme.textSecondaryColor),
        const SizedBox(width: 8),
          Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.cairo(color: theme.textSecondaryColor),
              children: [
                TextSpan(text: '$title: ', style: GoogleFonts.cairo(color: theme.textPrimaryColor, fontWeight: FontWeight.w800)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
        color: (isDark ? ThemeConfig.kNightAccent : ThemeConfig.kBeige).withOpacity(.4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.borderColor),
      ),
      child: Text(text, style: GoogleFonts.cairo(color: theme.textPrimaryColor, fontWeight: FontWeight.w600)),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
              child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(.7),
          shape: BoxShape.circle,
          border: Border.all(color: theme.borderColor.withOpacity(.6)),
          boxShadow: theme.cardShadow,
        ),
        child: Icon(icon, color: theme.textPrimaryColor, size: 18),
        ),
      );
    }
  }

class _StickyTabs extends SliverPersistentHeaderDelegate {
  final List<String> tabs;
  final String activeTab;
  final bool isDark;
  final Function(String) onTabTap;
  
  _StickyTabs({
    required this.tabs,
    required this.activeTab,
    required this.isDark,
    required this.onTabTap,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = ThemeConfig.instance;
    final selectedColor = isDark ? ThemeConfig.kGoldNight : const Color(0xFF10B981);
    final unselectedColor = isDark ? const Color(0xFF333333) : const Color(0xFF374151);
    final scrollbarColor = isDark ? ThemeConfig.kGoldNight : const Color(0xFF10B981);
    
    return Container(
      color: theme.backgroundColor,
      child: Column(
          children: [
            Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              reverse: true, // RTL
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isActive = tab == activeTab;
                
                return GestureDetector(
                  onTap: () => onTabTap(tab),
              child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                  child: Text(
                      tab,
                      textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                        fontSize: isActive ? 18 : 16,
                        fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                        color: isActive ? selectedColor : unselectedColor,
                        height: 1.0,
                        letterSpacing: 0.2,
                    ),
                  ),
                ),
                );
              },
            ),
          ),
          // شريط التمرير الأفقي
            Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
              decoration: BoxDecoration(
              color: isDark 
                ? ThemeConfig.kNightAccent.withOpacity(0.3) 
                : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final indicatorWidth = constraints.maxWidth / tabs.length;
                final activeIndex = tabs.indexOf(activeTab);
                
                return Stack(
          children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      right: indicatorWidth * (tabs.length - 1 - activeIndex),
                      child: Container(
                        width: indicatorWidth,
                        height: 4,
              decoration: BoxDecoration(
                          color: scrollbarColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                    ),
                  ),
                ],
                );
              },
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? ThemeConfig.kNightAccent.withOpacity(0.3) : Colors.grey.shade200,
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 68;
  @override
  double get minExtent => 68;
  @override
  bool shouldRebuild(covariant _StickyTabs oldDelegate) => 
    oldDelegate.activeTab != activeTab || oldDelegate.isDark != isDark;
}

class _GlassSheet extends StatelessWidget {
  final Widget child;
  const _GlassSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(.85),
            border: Border(top: BorderSide(color: theme.borderColor)),
          ),
                    child: child,
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _GlassCard({required this.child, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
          margin: const EdgeInsets.all(24),
          padding: padding,
                          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(.9),
            border: Border.all(color: theme.borderColor),
            boxShadow: theme.cardShadow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
        ),
      );
    }
  }

class _Grip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    return Container(
      width: 42, height: 5,
      decoration: BoxDecoration(
        color: theme.borderColor,
        borderRadius: BorderRadius.circular(999),
        ),
      );
    }
  }

class _Field extends StatelessWidget {
  final String label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String> onChanged;
  const _Field({
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;

    return TextField(
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      style: GoogleFonts.cairo(color: theme.textPrimaryColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.cairo(color: theme.textSecondaryColor),
        hintStyle: GoogleFonts.cairo(color: theme.textSecondaryColor.withOpacity(.7)),
        filled: true,
        fillColor: isDark ? ThemeConfig.kNightAccent.withOpacity(.35) : Colors.grey[50],
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.borderColor),
                    borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen, width: 2),
                        borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

/// أزرار الدلما (Primary / Ghost / Small / Glass)
class _DalmaButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final IconData? icon;
  final Gradient? gradient;
  final Color? foreground;
  final Color? outline;
  final EdgeInsetsGeometry padding;
  final bool filled;

  const _DalmaButton._({
    required this.onTap,
    required this.label,
    this.icon,
    this.gradient,
    this.foreground,
    this.outline,
    required this.filled,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  factory _DalmaButton.primary({required String label, required VoidCallback onTap}) {
    final isDark = ThemeConfig.instance.isDarkMode;
    final colors = isDark
        ? [ThemeConfig.kGoldNight, ThemeConfig.kGoldNight.withOpacity(.85)]
        : [ThemeConfig.kGreen, const Color(0xFF059669)];
    return _DalmaButton._(
      onTap: onTap,
      label: label,
      gradient: LinearGradient(colors: colors),
      foreground: isDark ? ThemeConfig.kNightDeep : Colors.white,
      filled: true,
    );
  }

  factory _DalmaButton.primarySmall({required String label, required VoidCallback onTap}) {
    final btn = _DalmaButton.primary(label: label, onTap: onTap);
    return _DalmaButton._(
      onTap: onTap,
      label: label,
      gradient: btn.gradient,
      foreground: btn.foreground,
      filled: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  factory _DalmaButton.ghost({required String label, required VoidCallback onTap}) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    return _DalmaButton._(
      onTap: onTap,
      label: label,
      foreground: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kSand,
      outline: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kSand,
      filled: false,
    );
  }

  factory _DalmaButton.glass({required IconData icon, required String label, required VoidCallback onTap}) {
    final theme = ThemeConfig.instance;
    return _DalmaButton._(
      onTap: onTap,
      label: label,
      icon: icon,
      foreground: theme.textPrimaryColor,
      filled: false,
      outline: theme.borderColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
        children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: foreground ?? theme.textPrimaryColor),
          const SizedBox(width: 8),
        ],
        Flexible(
                                  child: Text(
            label,
                                    style: GoogleFonts.cairo(
              color: foreground ?? theme.textPrimaryColor,
              fontWeight: FontWeight.w900,
              fontSize: 17,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
                                    ),
                                  ),
                              ],
    );

    if (filled) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white.withOpacity(0.3),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Ink(
                                decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (gradient?.colors.first ?? ThemeConfig.kGreen).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 1,
                              ),
                            ],
                          ),
            child: Container(
              padding: padding,
              child: child,
            ),
          ),
        ),
      );
    }
    // Ghost / Glass
    return InkWell(
      onTap: onTap,
                borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: padding,
              decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(.6),
                borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (outline ?? theme.borderColor).withOpacity(.8)),
        ),
        child: child,
      ),
    );
  }
}

