import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'theme_config.dart';
import 'realty_details_page.dart';

class ComparePage extends StatefulWidget {
  final List<Map<String, dynamic>> properties;
  
  const ComparePage({super.key, required this.properties});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);

    return Scaffold(
      backgroundColor: theme.isDarkMode ? const Color(0xFF0b0f14) : const Color(0xFFf8fafc),
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.compare_arrows, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'مقارنة العقارات',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
            ),
            onPressed: _exportToPDF,
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.share, color: Colors.white, size: 20),
            ),
            onPressed: _shareComparison,
          ),
          const SizedBox(width: 8),
        ],
        bottom: widget.properties.length >= 2 ? TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          labelStyle: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.cairo(fontSize: 14),
          tabs: const [
            Tab(text: 'نظرة عامة'),
            Tab(text: 'رسوم بيانية'),
            Tab(text: 'تفاصيل'),
          ],
        ) : null,
      ),
      body: widget.properties.length < 2
          ? _buildEmptyState(theme)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(theme),
                _buildChartsTab(theme),
                _buildDetailsTab(theme),
              ],
            ),
    );
  }

  Widget _buildEmptyState(ThemeConfig theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withOpacity(0.1),
                  theme.primaryColor.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.compare_arrows,
              size: 80,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'اختر عقارين على الأقل للمقارنة',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'يمكنك اختيار حتى 4 عقارات للمقارنة',
            style: GoogleFonts.cairo(
              fontSize: 15,
              color: theme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: theme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'اضغط على ❤️ في أي عقار لإضافته للمقارنة',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // نظرة عامة - Overview Tab
  Widget _buildOverviewTab(ThemeConfig theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // بطاقات العقارات
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.properties.length,
              itemBuilder: (context, index) {
                return _buildPropertyCard(widget.properties[index], theme, index);
              },
            ),
          ),
          const SizedBox(height: 24),
          
          // مقارنة سريعة
          _buildQuickComparison(theme),
          const SizedBox(height: 24),
          
          // أفضل قيمة
          _buildBestValue(theme),
          const SizedBox(height: 24),
          
          // نصائح ذكية
          _buildSmartTips(theme),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> property, ThemeConfig theme, int index) {
    final images = property['images'] as List? ?? [];
    final thumbnail = images.isNotEmpty ? images[0] : null;
    final priceRaw = property['price'];
    final areaRaw = property['area'];
    final price = priceRaw is String ? double.tryParse(priceRaw) ?? 0 : (priceRaw as num?)?.toDouble() ?? 0;
    final area = areaRaw is String ? double.tryParse(areaRaw) ?? 0 : (areaRaw as num?)?.toDouble() ?? 0;
    final pricePerMeter = area > 0 ? (price / area).toStringAsFixed(0) : '-';
    
    final colors = [
      const Color(0xFF10b981),
      const Color(0xFF3b82f6),
      const Color(0xFFf59e0b),
      const Color(0xFFec4899),
    ];
    
    final color = colors[index % colors.length];

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة العقار
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: thumbnail != null
                    ? Image.network(
                        thumbnail,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildImagePlaceholder(theme),
                      )
                    : _buildImagePlaceholder(theme),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'عقار ${index + 1}',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان
                Text(
                  property['title'] ?? '',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // السعر
                Row(
                  children: [
                    Icon(Icons.attach_money, color: color, size: 18),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${_formatNumber(price)} ر.س',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // المساحة والسعر للمتر
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.square_foot,
                        '$area م²',
                        theme,
                        color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.calculate,
                        '$pricePerMeter/م²',
                        theme,
                        color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(ThemeConfig theme) {
    return Container(
      height: 140,
      width: double.infinity,
      color: theme.isDarkMode ? const Color(0xFF2a2f3e) : const Color(0xFFe2e8f0),
      child: Icon(
        Icons.home_work,
        size: 60,
        color: theme.textSecondaryColor.withOpacity(0.5),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, ThemeConfig theme, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickComparison(ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.isDarkMode ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.speed, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'مقارنة سريعة',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          ...widget.properties.asMap().entries.map((entry) {
            final index = entry.key;
            final property = entry.value;
            final rooms = property['rooms'] ?? 0;
            final bathrooms = property['bathrooms'] ?? 0;
            final parking = property['parking'] ?? 0;
            final furnished = property['furnished'] == true;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getPropertyColor(index),
                          _getPropertyColor(index).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFeatureBadge(Icons.bed, '$rooms', theme),
                        _buildFeatureBadge(Icons.bathroom, '$bathrooms', theme),
                        _buildFeatureBadge(Icons.local_parking, '$parking', theme),
                        if (furnished)
                          _buildFeatureBadge(Icons.weekend, 'مفروش', theme),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String text, ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme.primaryColor, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestValue(ThemeConfig theme) {
    // حساب أفضل قيمة (أقل سعر للمتر)
    int bestValueIndex = 0;
    double bestPricePerMeter = double.infinity;
    
    for (int i = 0; i < widget.properties.length; i++) {
      final priceRaw = widget.properties[i]['price'];
      final areaRaw = widget.properties[i]['area'];
      final price = priceRaw is String ? double.tryParse(priceRaw) ?? 0 : (priceRaw as num?)?.toDouble() ?? 0;
      final area = areaRaw is String ? double.tryParse(areaRaw) ?? 1 : (areaRaw as num?)?.toDouble() ?? 1;
      final pricePerMeter = area > 0 ? (price / area).toDouble() : 0.0;
      
      if (pricePerMeter < bestPricePerMeter && pricePerMeter > 0) {
        bestPricePerMeter = pricePerMeter.toDouble();
        bestValueIndex = i;
      }
    }
    
    final bestProperty = widget.properties[bestValueIndex];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10b981).withOpacity(0.15),
            const Color(0xFF10b981).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10b981).withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10b981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10b981).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.star, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أفضل قيمة',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10b981),
                      ),
                    ),
                    Text(
                      'عقار ${bestValueIndex + 1} - أقل سعر للمتر المربع',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: theme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bestProperty['title'] ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${bestPricePerMeter.toStringAsFixed(0)} ر.س / م²',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10b981),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10b981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.trending_down,
                    color: Color(0xFF10b981),
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartTips(ThemeConfig theme) {
    final tips = _generateSmartTips();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.isDarkMode ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3b82f6),
                      const Color(0xFF3b82f6).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'نصائح ذكية',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: tip['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(tip['icon'], color: tip['color'], size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip['text'],
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: theme.textSecondaryColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateSmartTips() {
    final tips = <Map<String, dynamic>>[];
    
    // حساب فرق الأسعار
    final prices = widget.properties.map((p) {
      final priceRaw = p['price'];
      return priceRaw is String ? double.tryParse(priceRaw) ?? 0 : (priceRaw as num?)?.toDouble() ?? 0;
    }).toList();
    final maxPrice = prices.reduce(math.max);
    final minPrice = prices.reduce(math.min);
    final priceDiff = ((maxPrice - minPrice) / minPrice * 100).toStringAsFixed(0);
    
    if (maxPrice > minPrice * 1.2) {
      tips.add({
        'icon': Icons.trending_up,
        'color': const Color(0xFFf59e0b),
        'text': 'فرق السعر بين أغلى وأرخص عقار هو $priceDiff%، قد يكون هناك اختلاف في الموقع أو الجودة.',
      });
    }
    
    // حساب متوسط السعر للمتر
    double totalPricePerMeter = 0;
    int validCount = 0;
    for (var property in widget.properties) {
      final priceRaw = property['price'];
      final areaRaw = property['area'];
      final price = priceRaw is String ? double.tryParse(priceRaw) ?? 0 : (priceRaw as num?)?.toDouble() ?? 0;
      final area = areaRaw is String ? double.tryParse(areaRaw) ?? 0 : (areaRaw as num?)?.toDouble() ?? 0;
      if (area > 0) {
        totalPricePerMeter += price / area;
        validCount++;
      }
    }
    if (validCount > 0) {
      final avgPricePerMeter = (totalPricePerMeter / validCount).toStringAsFixed(0);
      tips.add({
        'icon': Icons.calculate,
        'color': const Color(0xFF3b82f6),
        'text': 'متوسط السعر للمتر المربع: $avgPricePerMeter ر.س، استخدم هذا كمعيار للمقارنة.',
      });
    }
    
    // التحقق من المفروش
    final furnishedCount = widget.properties.where((p) => p['furnished'] == true).length;
    if (furnishedCount > 0 && furnishedCount < widget.properties.length) {
      tips.add({
        'icon': Icons.weekend,
        'color': const Color(0xFF10b981),
        'text': 'بعض العقارات مفروشة، عادة تكون أغلى بـ 10-15% لكن توفر عليك تكلفة الأثاث.',
      });
    }
    
    // التحقق من المساحات
    final areas = widget.properties.map((p) {
      final areaRaw = p['area'];
      return areaRaw is String ? double.tryParse(areaRaw) ?? 0 : (areaRaw as num?)?.toDouble() ?? 0;
    }).toList();
    final maxArea = areas.reduce(math.max);
    final minArea = areas.reduce(math.min);
    if (maxArea > minArea * 1.5) {
      tips.add({
        'icon': Icons.square_foot,
        'color': const Color(0xFFec4899),
        'text': 'هناك فرق كبير في المساحات، تأكد من اختيار المساحة المناسبة لاحتياجاتك.',
      });
    }
    
    return tips;
  }

  // رسوم بيانية - Charts Tab
  Widget _buildChartsTab(ThemeConfig theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPriceChart(theme),
          const SizedBox(height: 24),
          _buildPricePerMeterChart(theme),
          const SizedBox(height: 24),
          _buildFeaturesChart(theme),
          const SizedBox(height: 24),
          _buildAreaChart(theme),
        ],
      ),
    );
  }

  Widget _buildPriceChart(ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.isDarkMode ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10b981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.attach_money, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'مقارنة الأسعار',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: widget.properties.map((p) {
                  final priceRaw = p['price'];
                  return priceRaw is String ? double.tryParse(priceRaw) ?? 0 : (priceRaw as num?)?.toDouble() ?? 0;
                }).reduce(math.max) * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'عقار ${value.toInt() + 1}',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.textSecondaryColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatNumberShort(value),
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: theme.textSecondaryColor,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: widget.properties.map((p) {
                    final priceRaw = p['price'];
                    return priceRaw is String ? double.tryParse(priceRaw) ?? 0 : (priceRaw as num?)?.toDouble() ?? 0;
                  }).reduce(math.max) / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.isDarkMode
                          ? const Color(0xFF2a2f3e)
                          : const Color(0xFFe2e8f0),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: widget.properties.asMap().entries.map((entry) {
                  final index = entry.key;
                  final property = entry.value;
                  final priceRaw = property['price'];
                  final price = priceRaw is String ? double.tryParse(priceRaw) ?? 0 : (priceRaw as num?)?.toDouble() ?? 0;
                  
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: price,
                        gradient: LinearGradient(
                          colors: [
                            _getPropertyColor(index),
                            _getPropertyColor(index).withOpacity(0.7),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 40,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricePerMeterChart(ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.isDarkMode ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3b82f6), Color(0xFF2563eb)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calculate, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'السعر للمتر المربع',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: widget.properties.map((p) {
                  final priceRaw = p['price'];
                  final areaRaw = p['area'];
                  final price = priceRaw is String ? double.tryParse(priceRaw) ?? 0 : (priceRaw as num?)?.toDouble() ?? 0;
                  final area = areaRaw is String ? double.tryParse(areaRaw) ?? 1 : (areaRaw as num?)?.toDouble() ?? 1;
                  return price / area;
                }).reduce(math.max) * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'عقار ${value.toInt() + 1}',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.textSecondaryColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: theme.textSecondaryColor,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.isDarkMode
                          ? const Color(0xFF2a2f3e)
                          : const Color(0xFFe2e8f0),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: widget.properties.asMap().entries.map((entry) {
                  final index = entry.key;
                  final property = entry.value;
                  final priceRaw = property['price'];
                  final areaRaw = property['area'];
                  final price = priceRaw is String ? double.tryParse(priceRaw) ?? 0 : (priceRaw as num?)?.toDouble() ?? 0;
                  final area = areaRaw is String ? double.tryParse(areaRaw) ?? 1 : (areaRaw as num?)?.toDouble() ?? 1;
                  final pricePerMeter = price / area;
                  
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: pricePerMeter.toDouble(),
                        gradient: LinearGradient(
                          colors: [
                            _getPropertyColor(index),
                            _getPropertyColor(index).withOpacity(0.7),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 40,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesChart(ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.isDarkMode ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFf59e0b), Color(0xFFd97706)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.home, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'مقارنة المميزات',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'عقار ${value.toInt() + 1}',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.textSecondaryColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: theme.textSecondaryColor,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.isDarkMode
                          ? const Color(0xFF2a2f3e)
                          : const Color(0xFFe2e8f0),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: widget.properties.asMap().entries.map((entry) {
                  final index = entry.key;
                  final property = entry.value;
                  final roomsRaw = property['rooms'];
                  final bathroomsRaw = property['bathrooms'];
                  final parkingRaw = property['parking'];
                  final rooms = roomsRaw is String ? double.tryParse(roomsRaw) ?? 0 : (roomsRaw as num?)?.toDouble() ?? 0;
                  final bathrooms = bathroomsRaw is String ? double.tryParse(bathroomsRaw) ?? 0 : (bathroomsRaw as num?)?.toDouble() ?? 0;
                  final parking = parkingRaw is String ? double.tryParse(parkingRaw) ?? 0 : (parkingRaw as num?)?.toDouble() ?? 0;
                  
                  return BarChartGroupData(
                    x: index,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: rooms,
                        color: const Color(0xFF10b981),
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: bathrooms,
                        color: const Color(0xFF3b82f6),
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: parking,
                        color: const Color(0xFFf59e0b),
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('غرف', const Color(0xFF10b981), theme),
              const SizedBox(width: 16),
              _buildLegendItem('حمامات', const Color(0xFF3b82f6), theme),
              const SizedBox(width: 16),
              _buildLegendItem('مواقف', const Color(0xFFf59e0b), theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAreaChart(ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.isDarkMode ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFec4899), Color(0xFFdb2777)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.square_foot, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'مقارنة المساحات',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: widget.properties.map((p) {
                  final areaRaw = p['area'];
                  return areaRaw is String ? double.tryParse(areaRaw) ?? 0 : (areaRaw as num?)?.toDouble() ?? 0;
                }).reduce(math.max) * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'عقار ${value.toInt() + 1}',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.textSecondaryColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()} م²',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: theme.textSecondaryColor,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.isDarkMode
                          ? const Color(0xFF2a2f3e)
                          : const Color(0xFFe2e8f0),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: widget.properties.asMap().entries.map((entry) {
                  final index = entry.key;
                  final property = entry.value;
                  final areaRaw = property['area'];
                  final area = areaRaw is String ? double.tryParse(areaRaw) ?? 0 : (areaRaw as num?)?.toDouble() ?? 0;
                  
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: area,
                        gradient: LinearGradient(
                          colors: [
                            _getPropertyColor(index),
                            _getPropertyColor(index).withOpacity(0.7),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 40,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, ThemeConfig theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: theme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  // تفاصيل - Details Tab
  Widget _buildDetailsTab(ThemeConfig theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: widget.properties.asMap().entries.map((entry) {
          final index = entry.key;
          final property = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildDetailCard(property, theme, index),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetailCard(Map<String, dynamic> property, ThemeConfig theme, int index) {
    final color = _getPropertyColor(index);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  property['title'] ?? '',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildDetailRow('السعر', '${_formatNumber(property['price'])} ر.س', Icons.attach_money, color, theme),
          _buildDetailRow('المساحة', '${property['area'] ?? '-'} م²', Icons.square_foot, color, theme),
          _buildDetailRow('السعر/م²', '${_calculatePricePerMeter(property)} ر.س', Icons.calculate, color, theme),
          _buildDetailRow('الغرف', '${property['rooms'] ?? '-'}', Icons.bed, color, theme),
          _buildDetailRow('الحمامات', '${property['bathrooms'] ?? '-'}', Icons.bathroom, color, theme),
          _buildDetailRow('المواقف', '${property['parking'] ?? '-'}', Icons.local_parking, color, theme),
          _buildDetailRow('مفروش', property['furnished'] == true ? 'نعم' : 'لا', Icons.weekend, color, theme),
          _buildDetailRow('الحالة', property['status'] == 'for_sale' ? 'للبيع' : 'للإيجار', Icons.sell, color, theme),
          _buildDetailRow('النوع', _getTypeLabel(property['type']), Icons.home_work, color, theme),
          _buildDetailRow('المدينة', '${property['city'] ?? '-'}', Icons.location_city, color, theme),
          _buildDetailRow('الحي', '${property['district'] ?? '-'}', Icons.location_on, color, theme),
          _buildDetailRow('المكتب', '${property['office_name'] ?? '-'}', Icons.business, color, theme),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color color, ThemeConfig theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: theme.textSecondaryColor,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPropertyColor(int index) {
    const colors = [
      Color(0xFF10b981),
      Color(0xFF3b82f6),
      Color(0xFFf59e0b),
      Color(0xFFec4899),
    ];
    return colors[index % colors.length];
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    final num = number is String ? double.tryParse(number) ?? 0 : number;
    return num.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _formatNumberShort(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}م';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}ك';
    }
    return number.toStringAsFixed(0);
  }

  String _calculatePricePerMeter(Map<String, dynamic> property) {
    final priceRaw = property['price'];
    final areaRaw = property['area'];
    final price = priceRaw is String ? double.tryParse(priceRaw) ?? 0 : (priceRaw as num?)?.toDouble() ?? 0;
    final area = areaRaw is String ? double.tryParse(areaRaw) ?? 0 : (areaRaw as num?)?.toDouble() ?? 0;
    if (area == 0) return '-';
    return (price / area).toStringAsFixed(0);
  }

  String _getTypeLabel(String? type) {
    switch (type) {
      case 'apartment':
        return 'شقة';
      case 'villa':
        return 'فيلا';
      case 'land':
        return 'أرض';
      case 'building':
        return 'عمارة';
      case 'farm':
        return 'مزرعة';
      case 'warehouse':
        return 'مستودع';
      case 'office':
        return 'مكتب';
      case 'shop':
        return 'محل';
      default:
        return '-';
    }
  }
  
  Future<void> _exportToPDF() async {
    // TODO: Implement PDF export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'سيتم إضافة ميزة التصدير قريباً',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: const Color(0xFF10b981),
      ),
    );
  }
  
  Future<void> _shareComparison() async {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'سيتم إضافة ميزة المشاركة قريباً',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: const Color(0xFF3b82f6),
      ),
    );
  }
}
