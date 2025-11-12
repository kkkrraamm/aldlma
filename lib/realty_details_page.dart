import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme_config.dart';
import 'api_config.dart';

class RealtyDetailsPage extends StatefulWidget {
  final int listingId;
  
  const RealtyDetailsPage({super.key, required this.listingId});

  @override
  State<RealtyDetailsPage> createState() => _RealtyDetailsPageState();
}

class _RealtyDetailsPageState extends State<RealtyDetailsPage> {
  Map<String, dynamic>? _listing;
  bool _isLoading = true;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadListing();
  }

  Future<void> _loadListing() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/realty/listing/${widget.listingId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _listing = jsonDecode(response.body);
          _isLoading = false;
        });
        
        // تسجيل حدث الفتح
        _postEvent('listing_open');
      } else {
        throw Exception('فشل تحميل التفاصيل');
      }
    } catch (e) {
      debugPrint('❌ [REALTY] خطأ: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.isDarkMode ? const Color(0xFF0b0f14) : const Color(0xFFf8fafc),
        appBar: AppBar(
          backgroundColor: theme.primaryColor,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(color: theme.primaryColor),
        ),
      );
    }

    if (_listing == null) {
      return Scaffold(
        backgroundColor: theme.isDarkMode ? const Color(0xFF0b0f14) : const Color(0xFFf8fafc),
        appBar: AppBar(
          backgroundColor: theme.primaryColor,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'العقار غير موجود',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: theme.textSecondaryColor,
            ),
          ),
        ),
      );
    }

    final images = _listing!['images'] as List? ?? [];
    final similar = _listing!['similar'] as List? ?? [];

    return Scaffold(
      backgroundColor: theme.isDarkMode ? const Color(0xFF0b0f14) : const Color(0xFFf8fafc),
      body: CustomScrollView(
        slivers: [
          // معرض الصور
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: theme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: images.isNotEmpty
                  ? Stack(
                      children: [
                        PageView.builder(
                          itemCount: images.length,
                          onPageChanged: (index) {
                            setState(() => _currentImageIndex = index);
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              images[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: theme.isDarkMode
                                    ? const Color(0xFF2a2f3e)
                                    : const Color(0xFFe2e8f0),
                                child: Icon(
                                  Icons.home_work,
                                  size: 80,
                                  color: theme.textSecondaryColor,
                                ),
                              ),
                            );
                          },
                        ),
                        // مؤشر الصور
                        if (images.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_currentImageIndex + 1} / ${images.length}',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      color: theme.isDarkMode
                          ? const Color(0xFF2a2f3e)
                          : const Color(0xFFe2e8f0),
                      child: Icon(
                        Icons.home_work,
                        size: 80,
                        color: theme.textSecondaryColor,
                      ),
                    ),
            ),
          ),

          // المحتوى
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العنوان والسعر
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _listing!['title'] ?? 'بدون عنوان',
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.textPrimaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_formatPrice(_listing!['price'])} ر.س',
                            style: GoogleFonts.cairo(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _listing!['status'] == 'for_sale'
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _listing!['status'] == 'for_sale' ? 'للبيع' : 'للإيجار',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: _listing!['status'] == 'for_sale'
                                    ? Colors.green
                                    : Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // الموقع
                  Row(
                    children: [
                      Icon(Icons.location_on, color: theme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${_listing!['city']}${_listing!['district'] != null ? ' • ${_listing!['district']}' : ''}',
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          color: theme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // المواصفات
                  _buildSpecsSection(theme),
                  const SizedBox(height: 24),

                  // الوصف
                  if (_listing!['description'] != null &&
                      _listing!['description'].toString().isNotEmpty) ...[
                    Text(
                      'الوصف',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _listing!['description'],
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        height: 1.8,
                        color: theme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // معلومات المكتب
                  _buildOfficeSection(theme),
                  const SizedBox(height: 24),

                  // عقارات مشابهة
                  if (similar.isNotEmpty) ...[
                    Text(
                      'عقارات مشابهة',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: similar.length,
                        itemBuilder: (context, index) {
                          return _buildSimilarCard(similar[index], theme);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildSpecsSection(ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المواصفات',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              if (_listing!['area'] != null)
                _buildSpecItem(
                  Icons.square_foot,
                  'المساحة',
                  '${_listing!['area']} م²',
                  theme,
                ),
              if (_listing!['rooms'] != null)
                _buildSpecItem(
                  Icons.bed,
                  'الغرف',
                  '${_listing!['rooms']}',
                  theme,
                ),
              if (_listing!['bathrooms'] != null)
                _buildSpecItem(
                  Icons.bathroom,
                  'دورات المياه',
                  '${_listing!['bathrooms']}',
                  theme,
                ),
              if (_listing!['parking'] != null)
                _buildSpecItem(
                  Icons.local_parking,
                  'مواقف',
                  '${_listing!['parking']}',
                  theme,
                ),
              _buildSpecItem(
                Icons.weekend,
                'مفروش',
                _listing!['furnished'] == true ? 'نعم' : 'لا',
                theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String label, String value, ThemeConfig theme) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Icon(icon, color: theme.primaryColor, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: theme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _buildOfficeSection(ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // شعار المكتب
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _listing!['office_logo'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _listing!['office_logo'],
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.business,
                    color: theme.primaryColor,
                    size: 30,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _listing!['office_name'] ?? 'مكتب عقاري',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _listing!['office_city'] ?? '',
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
    );
  }

  Widget _buildSimilarCard(dynamic listing, ThemeConfig theme) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RealtyDetailsPage(listingId: listing['id']),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: listing['thumbnail'] != null
                  ? Image.network(
                      listing['thumbnail'],
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 100,
                      color: theme.isDarkMode
                          ? const Color(0xFF2a2f3e)
                          : const Color(0xFFe2e8f0),
                      child: Icon(
                        Icons.home_work,
                        color: theme.textSecondaryColor,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing['title'] ?? '',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatPrice(listing['price'])} ر.س',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _handleCall,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.call),
                label: Text(
                  'اتصال',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _handleWhatsApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.chat),
                label: Text(
                  'واتساب',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCall() async {
    await _postEvent('click_call');
    
    final phone = _listing!['office_phone'];
    if (phone != null) {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Future<void> _handleWhatsApp() async {
    await _postEvent('click_whatsapp');
    
    final phone = _listing!['office_phone'];
    if (phone != null) {
      // إزالة الصفر الأول وإضافة كود السعودية
      String formattedPhone = phone.toString().replaceFirst(RegExp(r'^0'), '966');
      final message = 'مرحباً، أنا مهتم بالعقار: ${_listing!['title']}';
      final uri = Uri.parse('https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}');
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _postEvent(String eventType) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/realty/events'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'event_type': eventType,
          'ref_id': widget.listingId,
          'meta': {},
        }),
      );
    } catch (e) {
      debugPrint('❌ [EVENT] خطأ: $e');
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final num = double.tryParse(price.toString()) ?? 0;
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)} مليون';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(0)} ألف';
    }
    return num.toStringAsFixed(0);
  }
}

