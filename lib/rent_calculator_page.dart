import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme_config.dart';
import 'calculator_helpers.dart' as helpers;

class RentCalculatorPage extends StatefulWidget {
  const RentCalculatorPage({super.key});

  @override
  State<RentCalculatorPage> createState() => _RentCalculatorPageState();
}

class _RentCalculatorPageState extends State<RentCalculatorPage> {
  final _priceController = TextEditingController();
  final _maintenanceController = TextEditingController();
  double _targetReturn = 6.0;
  
  double? _monthlyRent;
  double? _annualRent;
  double? _netReturn;
  
  bool _showHelp = false;

  void _calculate() {
    final price = double.tryParse(_priceController.text) ?? 0;
    final maintenance = double.tryParse(_maintenanceController.text) ?? 0;
    
    if (price <= 0) {
      setState(() {
        _monthlyRent = null;
        _annualRent = null;
        _netReturn = null;
      });
      return;
    }

    final targetAnnualReturn = price * (_targetReturn / 100);
    final annualRentNeeded = targetAnnualReturn + maintenance;
    final monthlyRentNeeded = annualRentNeeded / 12;
    final netAnnualReturn = annualRentNeeded - maintenance;

    setState(() {
      _monthlyRent = monthlyRentNeeded;
      _annualRent = annualRentNeeded;
      _netReturn = netAnnualReturn;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);

    return Scaffold(
      backgroundColor: theme.isDarkMode ? const Color(0xFF0b0f14) : const Color(0xFFf8fafc),
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.home_work, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'حاسبة الإيجار المثالي',
              style: GoogleFonts.cairo(
                fontSize: 18,
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
              child: Icon(_showHelp ? Icons.close : Icons.help_outline, color: Colors.white, size: 20),
            ),
            onPressed: () => setState(() => _showHelp = !_showHelp),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_showHelp) _buildHelpSection(theme),
            if (_showHelp) const SizedBox(height: 20),
            
            _buildInputCard(
              theme,
              'سعر العقار',
              _priceController,
              'أدخل سعر العقار',
              Icons.home,
              hint: 'القيمة السوقية الحالية للعقار.\\n\\nمثال: إذا كانت قيمة الشقة في السوق 500,000 ريال، أدخل هذا المبلغ.',
            ),
            const SizedBox(height: 16),
            _buildInputCard(
              theme,
              'تكاليف الصيانة السنوية',
              _maintenanceController,
              'صيانة، إدارة، إلخ',
              Icons.build,
              hint: 'المصاريف السنوية للصيانة والإصلاحات (عادة 1-2% من قيمة العقار).\\n\\nمثال: إذا كانت الصيانة السنوية 5,000 ريال، أدخلها هنا.',
            ),
            const SizedBox(height: 16),
            _buildSliderCard(
              theme,
              'نسبة العائد المطلوبة',
              _targetReturn,
              4,
              12,
              '%',
              (v) {
                setState(() => _targetReturn = v);
                _calculate();
              },
              hint: 'النسبة السنوية التي تريد تحقيقها من الإيجار (عادة 5-8%).\\n\\nمثال: 6% يعني تريد عائد سنوي 6% من قيمة العقار.',
              icon: Icons.trending_up,
              color: const Color(0xFF3b82f6),
            ),
            const SizedBox(height: 30),

            if (_monthlyRent != null) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [const Color(0xFF8b5cf6).withOpacity(0.2), const Color(0xFF8b5cf6).withOpacity(0.1)]),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF8b5cf6), width: 3),
                ),
                child: Column(
                  children: [
                    Icon(Icons.attach_money, color: const Color(0xFF8b5cf6), size: 48),
                    const SizedBox(height: 12),
                    Text('الإيجار الشهري المثالي', style: GoogleFonts.cairo(fontSize: 18, color: theme.textSecondaryColor)),
                    const SizedBox(height: 8),
                    Text('${_monthlyRent!.toStringAsFixed(0)} ر.س', style: GoogleFonts.cairo(fontSize: 36, fontWeight: FontWeight.bold, color: const Color(0xFF8b5cf6))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.calendar_today, color: theme.primaryColor, size: 32),
                          const SizedBox(height: 8),
                          Text('الإيجار السنوي', style: GoogleFonts.cairo(fontSize: 12, color: theme.textSecondaryColor)),
                          const SizedBox(height: 4),
                          Text('${_annualRent!.toStringAsFixed(0)} ر.س', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textPrimaryColor)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF10b981).withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.trending_up, color: const Color(0xFF10b981), size: 32),
                          const SizedBox(height: 8),
                          Text('العائد الصافي', style: GoogleFonts.cairo(fontSize: 12, color: theme.textSecondaryColor)),
                          const SizedBox(height: 4),
                          Text('${_netReturn!.toStringAsFixed(0)} ر.س', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textPrimaryColor)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text('المعادلة:', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textPrimaryColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'الإيجار الشهري = ((سعر العقار × نسبة العائد) + التكاليف السنوية) / 12',
                      style: GoogleFonts.cairo(fontSize: 12, color: theme.textSecondaryColor, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(ThemeConfig theme, String label, TextEditingController controller, String placeholder, IconData icon, {String? hint}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(theme.isDarkMode ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimaryColor)),
              ),
              if (hint != null)
                helpers.buildHelpButton(context, theme, label, hint, icon, theme.primaryColor),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => _calculate(),
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textPrimaryColor),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: GoogleFonts.cairo(color: theme.textSecondaryColor, fontSize: 14),
              suffixText: 'ر.س',
              suffixStyle: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: theme.primaryColor),
              filled: true,
              fillColor: theme.isDarkMode ? const Color(0xFF2a2f3e) : const Color(0xFFf8fafc),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderCard(ThemeConfig theme, String label, double value, double min, double max, String unit, Function(double) onChanged, {String? hint, IconData? icon, Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(theme.isDarkMode ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(label, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimaryColor)),
                    ),
                    if (hint != null)
                      helpers.buildHelpButton(context, theme, label, hint, icon ?? Icons.tune, color ?? theme.primaryColor),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${value.toStringAsFixed(1)} $unit', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: theme.primaryColor)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: theme.primaryColor,
              inactiveTrackColor: theme.primaryColor.withOpacity(0.2),
              thumbColor: theme.primaryColor,
              overlayColor: theme.primaryColor.withOpacity(0.2),
            ),
            child: Slider(value: value, min: min, max: max, divisions: ((max - min) * 10).toInt(), onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8b5cf6).withOpacity(0.1),
            const Color(0xFF8b5cf6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8b5cf6).withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8b5cf6), Color(0xFF7c3aed)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'كيف تستخدم حاسبة الإيجار المثالي؟',
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8b5cf6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'هذه الحاسبة تساعدك على تحديد الإيجار المثالي لعقارك بناءً على قيمته والعائد المستهدف.',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: theme.textSecondaryColor,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8b5cf6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF8b5cf6).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calculate, color: Color(0xFF8b5cf6), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'مثال عملي:',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8b5cf6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'قيمة العقار: 500,000 ريال\n'
                  'العائد المستهدف: 6% سنوياً\n'
                  'تكاليف الصيانة السنوية: 5,000 ريال',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: theme.textSecondaryColor,
                    height: 1.6,
                  ),
                ),
                const Divider(height: 24),
                Text(
                  '✅ الإيجار الشهري المثالي: ≈ 2,917 ريال\n'
                  '✅ الإيجار السنوي: 35,000 ريال',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8b5cf6),
                    height: 1.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10b981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates, color: Color(0xFF10b981), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'نصيحة: العائد الجيد للإيجار عادة 5-8% سنوياً',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: const Color(0xFF10b981),
                      fontWeight: FontWeight.w600,
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

  @override
  void dispose() {
    _priceController.dispose();
    _maintenanceController.dispose();
    super.dispose();
  }
}

