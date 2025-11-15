import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'theme_config.dart';
import 'chat_page.dart';

class AddPropertyPage extends StatefulWidget {
  const AddPropertyPage({super.key});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  Timer? _autoScrollTimer;
  
  // قائمة المكاتب المعتمدة (مثال)
  final List<Map<String, dynamic>> _approvedOffices = [
    {
      'id': '1',
      'name': 'مكتب الدلما العقاري',
      'logo': 'https://via.placeholder.com/150/10b981/FFFFFF?text=الدلما',
      'rating': 4.8,
      'properties': 120,
    },
    {
      'id': '2',
      'name': 'مكتب العقارات الذهبية',
      'logo': 'https://via.placeholder.com/150/f59e0b/FFFFFF?text=الذهبية',
      'rating': 4.9,
      'properties': 95,
    },
    {
      'id': '3',
      'name': 'مكتب النخبة للعقارات',
      'logo': 'https://via.placeholder.com/150/3b82f6/FFFFFF?text=النخبة',
      'rating': 4.7,
      'properties': 150,
    },
    {
      'id': '4',
      'name': 'مكتب الرائد العقاري',
      'logo': 'https://via.placeholder.com/150/ec4899/FFFFFF?text=الرائد',
      'rating': 4.6,
      'properties': 80,
    },
    {
      'id': '5',
      'name': 'مكتب الأمانة للعقارات',
      'logo': 'https://via.placeholder.com/150/8b5cf6/FFFFFF?text=الأمانة',
      'rating': 4.9,
      'properties': 110,
    },
    {
      'id': '6',
      'name': 'مكتب التميز العقاري',
      'logo': 'https://via.placeholder.com/150/ef4444/FFFFFF?text=التميز',
      'rating': 4.8,
      'properties': 130,
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // بدء التمرير التلقائي
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;
        
        // إذا وصلنا للنهاية، نرجع للبداية
        if (currentScroll >= maxScroll) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.animateTo(
            currentScroll + 1,
            duration: const Duration(milliseconds: 50),
            curve: Curves.linear,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);
    
    return Scaffold(
      backgroundColor: theme.isDarkMode ? const Color(0xFF0b0f14) : Colors.white,
      body: Stack(
        children: [
          // خلفية متدرجة
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.primaryColor.withOpacity(0.1),
                  theme.isDarkMode ? const Color(0xFF0b0f14) : Colors.white,
                ],
              ),
            ),
          ),
          
          // المحتوى
          SafeArea(
            child: Column(
              children: [
                // الهيدر
                _buildHeader(theme),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        
                        // العنوان الرئيسي
                        _buildMainTitle(theme),
                        
                        const SizedBox(height: 30),
                        
                        // شعارات المكاتب المتحركة
                        _buildAnimatedLogos(theme),
                        
                        const SizedBox(height: 40),
                        
                        // نص الدعوة للتواصل
                        _buildCallToAction(theme),
                        
                        const SizedBox(height: 30),
                        
                        // قائمة المكاتب
                        _buildOfficesList(theme),
                        
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: theme.isDarkMode ? Colors.white : const Color(0xFF1e293b),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Text(
            'ضيف عقارك',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.isDarkMode ? Colors.white : const Color(0xFF1e293b),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTitle(ThemeConfig theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.home_work,
                  color: Colors.white,
                  size: 50,
                ),
                const SizedBox(height: 16),
                Text(
                  'هل تريد إضافة عقارك؟',
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'تواصل مع المكاتب العقارية المعتمدة',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLogos(ThemeConfig theme) {
    return Container(
      height: 120,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _approvedOffices.length * 100, // تكرار لا نهائي
        itemBuilder: (context, index) {
          final office = _approvedOffices[index % _approvedOffices.length];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      office['logo'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: theme.primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.business,
                            color: theme.primaryColor,
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        color: theme.primaryColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'معتمد',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCallToAction(ThemeConfig theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3b82f6),
            const Color(0xFF2563eb),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3b82f6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            'تواصل دردشة مع المكاتب المعتمدة',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'اختر المكتب المناسب وابدأ المحادثة الآن',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOfficesList(ThemeConfig theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المكاتب المعتمدة',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.isDarkMode ? Colors.white : const Color(0xFF1e293b),
            ),
          ),
          const SizedBox(height: 16),
          ..._approvedOffices.map((office) => _buildOfficeCard(office, theme)).toList(),
        ],
      ),
    );
  }

  Widget _buildOfficeCard(Map<String, dynamic> office, ThemeConfig theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1e293b) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _openChatWithOffice(office);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // شعار المكتب
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      office['logo'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: theme.primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.business,
                            color: theme.primaryColor,
                            size: 35,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // معلومات المكتب
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              office['name'],
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.isDarkMode ? Colors.white : const Color(0xFF1e293b),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  color: theme.primaryColor,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'معتمد',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: const Color(0xFFf59e0b),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${office['rating']}',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.isDarkMode ? Colors.white70 : const Color(0xFF64748b),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.home,
                            color: theme.primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${office['properties']} عقار',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: theme.isDarkMode ? Colors.white70 : const Color(0xFF64748b),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // زر الدردشة
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primaryColor,
                        theme.primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chat_bubble,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openChatWithOffice(Map<String, dynamic> office) {
    // فتح صفحة الدردشة مع المكتب
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          officeId: int.parse(office['id']),
          officeName: office['name'],
          officeLogo: office['logo'],
        ),
      ),
    );
  }
}

