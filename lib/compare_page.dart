import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'theme_config.dart';
import 'realty_details_page.dart';

class ComparePage extends StatefulWidget {
  final List<Map<String, dynamic>> properties;
  
  const ComparePage({super.key, required this.properties});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);

    return Scaffold(
      backgroundColor: theme.isDarkMode ? const Color(0xFF0b0f14) : const Color(0xFFf8fafc),
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        elevation: 0,
        title: Text(
          'مقارنة العقارات',
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: _exportToPDF,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareComparison,
          ),
        ],
      ),
      body: widget.properties.length < 2
          ? _buildEmptyState(theme)
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: _buildComparisonTable(theme),
              ),
            ),
    );
  }

  Widget _buildEmptyState(ThemeConfig theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.compare_arrows,
            size: 80,
            color: theme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'اختر عقارين على الأقل للمقارنة',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يمكنك اختيار حتى 4 عقارات',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: theme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(ThemeConfig theme) {
    return DataTable(
      columnSpacing: 16,
      headingRowColor: MaterialStateProperty.all(
        theme.primaryColor.withOpacity(0.1),
      ),
      dataRowColor: MaterialStateProperty.all(
        theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
      ),
      border: TableBorder.all(
        color: theme.isDarkMode
            ? const Color(0xFF2a2f3e)
            : const Color(0xFFe2e8f0),
        width: 1,
      ),
      columns: [
        DataColumn(
          label: Container(
            width: 120,
            child: Text(
              'المواصفات',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                color: theme.textPrimaryColor,
              ),
            ),
          ),
        ),
        ...widget.properties.map((property) {
          final images = property['images'] as List? ?? [];
          final thumbnail = images.isNotEmpty ? images[0] : null;
          
          return DataColumn(
            label: Container(
              width: 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (thumbnail != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        thumbnail,
                        height: 80,
                        width: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 80,
                          color: theme.isDarkMode
                              ? const Color(0xFF2a2f3e)
                              : const Color(0xFFe2e8f0),
                          child: Icon(
                            Icons.home_work,
                            size: 40,
                            color: theme.textSecondaryColor,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    property['title'] ?? '',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
      rows: [
        _buildRow('السعر', widget.properties.map((p) => '${p['price']} ر.س').toList().cast<String>(), theme),
        _buildRow('المساحة', widget.properties.map((p) => '${p['area'] ?? '-'} م²').toList().cast<String>(), theme),
        _buildRow('الغرف', widget.properties.map((p) => '${p['rooms'] ?? '-'}').toList().cast<String>(), theme),
        _buildRow('دورات المياه', widget.properties.map((p) => '${p['bathrooms'] ?? '-'}').toList().cast<String>(), theme),
        _buildRow('المواقف', widget.properties.map((p) => '${p['parking'] ?? '-'}').toList().cast<String>(), theme),
        _buildRow('مفروش', widget.properties.map((p) => p['furnished'] == true ? 'نعم' : 'لا').toList().cast<String>(), theme),
        _buildRow('المدينة', widget.properties.map((p) => '${p['city'] ?? '-'}').toList().cast<String>(), theme),
        _buildRow('الحي', widget.properties.map((p) => '${p['district'] ?? '-'}').toList().cast<String>(), theme),
        _buildRow('الحالة', widget.properties.map((p) => p['status'] == 'for_sale' ? 'للبيع' : 'للإيجار').toList().cast<String>(), theme),
        _buildRow('النوع', widget.properties.map((p) => _getTypeLabel(p['type'])).toList().cast<String>(), theme),
        _buildRow('المكتب', widget.properties.map((p) => '${p['office_name'] ?? '-'}').toList().cast<String>(), theme),
        _buildRow('المشاهدات', widget.properties.map((p) => '${p['views'] ?? 0}').toList().cast<String>(), theme),
      ],
    );
  }

  DataRow _buildRow(String label, List<String> values, ThemeConfig theme) {
    return DataRow(
      cells: [
        DataCell(
          Container(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w600,
                color: theme.textPrimaryColor,
              ),
            ),
          ),
        ),
        ...values.map((value) {
          return DataCell(
            Container(
              width: 150,
              child: Text(
                value,
                style: GoogleFonts.cairo(
                  color: theme.textPrimaryColor,
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
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
    final theme = Provider.of<ThemeConfig>(context, listen: false);
    
    try {
      // إنشاء PDF
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // العنوان
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'مقارنة العقارات',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'تطبيق الدلما',
                        style: pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // جدول المقارنة
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('المواصفات', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        ...widget.properties.map((p) => pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(p['title'] ?? '', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        )),
                      ],
                    ),
                    // الصفوف
                    _buildPDFRow('السعر', widget.properties.map((p) => '${p['price']} ر.س').toList()),
                    _buildPDFRow('المساحة', widget.properties.map((p) => '${p['area'] ?? '-'} م²').toList()),
                    _buildPDFRow('الغرف', widget.properties.map((p) => '${p['rooms'] ?? '-'}').toList()),
                    _buildPDFRow('دورات المياه', widget.properties.map((p) => '${p['bathrooms'] ?? '-'}').toList()),
                    _buildPDFRow('المواقف', widget.properties.map((p) => '${p['parking'] ?? '-'}').toList()),
                    _buildPDFRow('مفروش', widget.properties.map((p) => p['furnished'] == true ? 'نعم' : 'لا').toList()),
                    _buildPDFRow('المدينة', widget.properties.map((p) => '${p['city'] ?? '-'}').toList()),
                    _buildPDFRow('الحي', widget.properties.map((p) => '${p['district'] ?? '-'}').toList()),
                    _buildPDFRow('الحالة', widget.properties.map((p) => p['status'] == 'for_sale' ? 'للبيع' : 'للإيجار').toList()),
                    _buildPDFRow('النوع', widget.properties.map((p) => _getTypeLabel(p['type'])).toList()),
                    _buildPDFRow('المكتب', widget.properties.map((p) => '${p['office_name'] ?? '-'}').toList()),
                  ],
                ),
                pw.SizedBox(height: 20),
                
                // تذييل
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    'تم إنشاء هذا التقرير بواسطة تطبيق الدلما - ${DateTime.now().toString().substring(0, 10)}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ),
              ],
            );
          },
        ),
      );
      
      // حفظ PDF
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/مقارنة_عقارات_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      // عرض رسالة نجاح
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم حفظ PDF في: ${file.path}',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'فتح',
            textColor: Colors.white,
            onPressed: () {
              // TODO: فتح الملف
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ [PDF] خطأ: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل إنشاء PDF',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  pw.TableRow _buildPDFRow(String label, List<dynamic> values) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        ...values.map((v) => pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(v.toString()),
        )),
      ],
    );
  }
  
  void _shareComparison() {
    final theme = Provider.of<ThemeConfig>(context, listen: false);
    
    // إنشاء نص المقارنة
    String text = '📊 مقارنة العقارات\n\n';
    
    for (int i = 0; i < widget.properties.length; i++) {
      final p = widget.properties[i];
      text += '${i + 1}. ${p['title']}\n';
      text += '   💰 ${p['price']} ر.س\n';
      text += '   📐 ${p['area'] ?? '-'} م²\n';
      text += '   🛏️ ${p['rooms'] ?? '-'} غرف\n';
      text += '   📍 ${p['city']} - ${p['district'] ?? ''}\n\n';
    }
    
    text += 'شاهد المزيد في تطبيق الدلما 📲';
    
    // TODO: استخدام share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ المقارنة',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: theme.primaryColor,
      ),
    );
  }
}

