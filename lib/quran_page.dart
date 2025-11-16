import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import 'theme_config.dart';

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  int? _selectedSurah;
  
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);
    
    return Scaffold(
      backgroundColor: theme.isDarkMode ? const Color(0xFF0f172a) : const Color(0xFFf5f3e8),
      body: _selectedSurah == null
          ? _buildSurahList(theme)
          : _buildSurahReader(theme, _selectedSurah!),
    );
  }

  // قائمة السور
  Widget _buildSurahList(ThemeConfig theme) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          backgroundColor: const Color(0xFF047857),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF059669),
                    Color(0xFF047857),
                    Color(0xFF065f46),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'القرآن الكريم',
                      style: GoogleFonts.amiriQuran(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '114 سورة',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            title: Text(
              'القرآن الكريم',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        
        // قائمة السور
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final surahNumber = index + 1;
                final surahName = quran.getSurahNameArabic(surahNumber);
                final versesCount = quran.getVerseCount(surahNumber);
                final revelationType = quran.getPlaceOfRevelation(surahNumber);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.isDarkMode ? const Color(0xFF1e293b) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSurah = surahNumber;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // رقم السورة
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF059669),
                                    Color(0xFF047857),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '$surahNumber',
                                  style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // معلومات السورة
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    surahName,
                                    style: GoogleFonts.amiriQuran(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: theme.isDarkMode ? Colors.white : const Color(0xFF1e293b),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$revelationType • $versesCount آية',
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      color: theme.isDarkMode ? Colors.white70 : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // سهم
                            Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: theme.isDarkMode ? Colors.white38 : Colors.grey[400],
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: 114,
            ),
          ),
        ),
      ],
    );
  }

  // صفحة قراءة السورة
  Widget _buildSurahReader(ThemeConfig theme, int surahNumber) {
    final surahName = quran.getSurahNameArabic(surahNumber);
    final versesCount = quran.getVerseCount(surahNumber);
    
    return Scaffold(
      backgroundColor: theme.isDarkMode ? const Color(0xFF0f172a) : const Color(0xFFf5f3e8),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: const Color(0xFF047857),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedSurah = null;
                });
              },
            ),
            title: Text(
              surahName,
              style: GoogleFonts.amiriQuran(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.bookmark_border_rounded, color: Colors.white),
                onPressed: () {
                  // TODO: حفظ المكان
                },
              ),
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Colors.white),
                onPressed: () {
                  // TODO: البحث
                },
              ),
            ],
          ),
          
          // البسملة (ما عدا التوبة)
          if (surahNumber != 1 && surahNumber != 9)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.isDarkMode ? const Color(0xFF1e293b) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  quran.basmala,
                  style: GoogleFonts.amiriQuran(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF047857),
                    height: 2,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          
          // الآيات
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final verseNumber = index + 1;
                  final verseText = quran.getVerse(surahNumber, verseNumber);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.isDarkMode ? const Color(0xFF1e293b) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // نص الآية
                        Text(
                          '$verseText ﴿$verseNumber﴾',
                          style: GoogleFonts.amiriQuran(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: theme.isDarkMode ? Colors.white : const Color(0xFF1e293b),
                            height: 2,
                          ),
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // أزرار الآية
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildVerseActionButton(
                              icon: Icons.share_rounded,
                              onTap: () {
                                // TODO: مشاركة الآية
                              },
                              theme: theme,
                            ),
                            const SizedBox(width: 8),
                            _buildVerseActionButton(
                              icon: Icons.copy_rounded,
                              onTap: () {
                                // TODO: نسخ الآية
                              },
                              theme: theme,
                            ),
                            const SizedBox(width: 8),
                            _buildVerseActionButton(
                              icon: Icons.bookmark_border_rounded,
                              onTap: () {
                                // TODO: حفظ الآية
                              },
                              theme: theme,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                childCount: versesCount,
              ),
            ),
          ),
          
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeConfig theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF047857),
            ),
          ),
        ),
      ),
    );
  }
}

