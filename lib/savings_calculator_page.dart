import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme_config.dart';
import 'calculator_helpers.dart' as helpers;

class SavingsCalculatorPage extends StatefulWidget {
  const SavingsCalculatorPage({super.key});

  @override
  State<SavingsCalculatorPage> createState() => _SavingsCalculatorPageState();
}

class _SavingsCalculatorPageState extends State<SavingsCalculatorPage> {
  final _initialController = TextEditingController();
  final _monthlyController = TextEditingController();
  double _interestRate = 3.0;
  double _years = 10;
  
  double? _finalAmount;
  double? _totalSavings;
  double? _totalInterest;
  
  bool _showHelp = false;

  void _calculate() {
    final initial = double.tryParse(_initialController.text) ?? 0;
    final monthly = double.tryParse(_monthlyController.text) ?? 0;
    
    if (initial <= 0 && monthly <= 0) {
      setState(() {
        _finalAmount = null;
        _totalSavings = null;
        _totalInterest = null;
      });
      return;
    }

    final monthlyRate = _interestRate / 100 / 12;
    final months = _years * 12;
    
    final futureValueInitial = initial * pow(1 + monthlyRate, months);
    final futureValueMonthly = monthly * ((pow(1 + monthlyRate, months) - 1) / monthlyRate);
    final finalAmount = futureValueInitial + futureValueMonthly;
    final totalSavings = initial + (monthly * months);
    final totalInterest = finalAmount - totalSavings;

    setState(() {
      _finalAmount = finalAmount;
      _totalSavings = totalSavings;
      _totalInterest = totalInterest;
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
              child: const Icon(Icons.savings, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'حاسبة الادخار',
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
              'المبلغ الحالي', 
              _initialController, 
              'المبلغ المدخر حالياً', 
              Icons.account_balance,
              'المبلغ الذي تملكه حالياً في حساب الادخار.\n\nمثال: إذا كان لديك 10,000 ريال مدخرة، أدخل 10000',
            ),
            const SizedBox(height: 16),
            _buildInputCard(
              theme, 
              'الادخار الشهري', 
              _monthlyController, 
              'المبلغ الشهري', 
              Icons.calendar_month,
              'المبلغ الذي ستضيفه كل شهر.\n\nمثال: إذا كنت ستدخر 1,000 ريال شهرياً، أدخل 1000',
            ),
            const SizedBox(height: 16),
            _buildSliderCard(
              theme, 
              'نسبة الفائدة السنوية', 
              _interestRate, 
              0, 
              10, 
              '%', 
              (v) {
                setState(() => _interestRate = v);
                _calculate();
              },
              'نسبة الفائدة السنوية التي يقدمها البنك.\n\nمثال: إذا كانت الفائدة 3% سنوياً، اختر 3',
            ),
            const SizedBox(height: 16),
            _buildSliderCard(
              theme, 
              'المدة', 
              _years, 
              1, 
              30, 
              'سنة', 
              (v) {
                setState(() => _years = v);
                _calculate();
              },
              'عدد السنوات التي ستستمر في الادخار.\n\nمثال: إذا كنت ستدخر لمدة 10 سنوات، اختر 10',
            ),
            const SizedBox(height: 30),

            if (_finalAmount != null) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [const Color(0xFF10b981).withOpacity(0.2), const Color(0xFF10b981).withOpacity(0.1)]),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF10b981), width: 3),
                ),
                child: Column(
                  children: [
                    Icon(Icons.account_balance_wallet, color: const Color(0xFF10b981), size: 48),
                    const SizedBox(height: 12),
                    Text('المبلغ النهائي', style: GoogleFonts.cairo(fontSize: 18, color: theme.textSecondaryColor)),
                    const SizedBox(height: 8),
                    Text('${_finalAmount!.toStringAsFixed(0)} ر.س', style: GoogleFonts.cairo(fontSize: 36, fontWeight: FontWeight.bold, color: const Color(0xFF10b981))),
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
                          Icon(Icons.savings, color: theme.primaryColor, size: 32),
                          const SizedBox(height: 8),
                          Text('إجمالي الادخار', style: GoogleFonts.cairo(fontSize: 12, color: theme.textSecondaryColor)),
                          const SizedBox(height: 4),
                          Text('${_totalSavings!.toStringAsFixed(0)} ر.س', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textPrimaryColor)),
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
                        border: Border.all(color: const Color(0xFF3b82f6).withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.trending_up, color: const Color(0xFF3b82f6), size: 32),
                          const SizedBox(height: 8),
                          Text('الفوائد المكتسبة', style: GoogleFonts.cairo(fontSize: 12, color: theme.textSecondaryColor)),
                          const SizedBox(height: 4),
                          Text('${_totalInterest!.toStringAsFixed(0)} ر.س', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textPrimaryColor)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(ThemeConfig theme, String label, TextEditingController controller, String hint, IconData icon, String helpText) {
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
              Text(label, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimaryColor)),
              const Spacer(),
              helpers.buildHelpButton(context, theme, label, helpText, icon, const Color(0xFF10b981)),
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
              hintText: hint,
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

  Widget _buildSliderCard(ThemeConfig theme, String label, double value, double min, double max, String unit, Function(double) onChanged, String helpText) {
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
                    Expanded(child: Text(label, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimaryColor))),
                    const SizedBox(width: 8),
                    helpers.buildHelpButton(context, theme, label, helpText, Icons.tune, const Color(0xFF10b981)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${value.toStringAsFixed(unit == '%' ? 1 : 0)} $unit', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: theme.primaryColor)),
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
            child: Slider(value: value, min: min, max: max, divisions: ((max - min) * (unit == '%' ? 10 : 1)).toInt(), onChanged: onChanged),
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
            const Color(0xFF10b981).withOpacity(0.1),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10b981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'كيف تستخدم حاسبة الادخار؟',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10b981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'هذه الحاسبة تساعدك على معرفة كم ستدخر بعد فترة معينة مع احتساب الفوائد.',
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
              color: const Color(0xFF10b981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10b981).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calculate, color: Color(0xFF10b981), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'مثال عملي:',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10b981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'المبلغ الأولي: 10,000 ريال\n'
                  'الإضافة الشهرية: 1,000 ريال\n'
                  'نسبة الفائدة: 3% سنوياً\n'
                  'المدة: 10 سنوات',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: theme.textSecondaryColor,
                    height: 1.6,
                  ),
                ),
                const Divider(height: 24),
                Text(
                  '✅ المبلغ النهائي: ≈ 149,641 ريال\n'
                  '✅ إجمالي المدخر: 130,000 ريال\n'
                  '✅ الفوائد المكتسبة: ≈ 19,641 ريال',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10b981),
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
              color: const Color(0xFF3b82f6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates, color: Color(0xFF3b82f6), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'نصيحة: الادخار المبكر يضاعف أرباحك بفضل الفائدة المركبة!',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: const Color(0xFF3b82f6),
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
    _initialController.dispose();
    _monthlyController.dispose();
    super.dispose();
  }
}

