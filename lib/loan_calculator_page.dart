import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme_config.dart';
import 'calculator_helpers.dart' as helpers;

class LoanCalculatorPage extends StatefulWidget {
  const LoanCalculatorPage({super.key});

  @override
  State<LoanCalculatorPage> createState() => _LoanCalculatorPageState();
}

class _LoanCalculatorPageState extends State<LoanCalculatorPage> {
  final _amountController = TextEditingController();
  final _feesController = TextEditingController();
  double _interestRate = 5.0;
  double _years = 5;
  
  double? _monthlyPayment;
  double? _totalAmount;
  double? _totalInterest;
  
  bool _showHelp = false;

  void _calculate() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final fees = double.tryParse(_feesController.text) ?? 0;
    
    if (amount <= 0) {
      setState(() {
        _monthlyPayment = null;
        _totalAmount = null;
        _totalInterest = null;
      });
      return;
    }

    final totalLoan = amount + fees;
    final monthlyRate = _interestRate / 100 / 12;
    final months = _years * 12;
    final monthly = totalLoan * (monthlyRate * pow(1 + monthlyRate, months)) / (pow(1 + monthlyRate, months) - 1);
    final total = monthly * months;
    final interest = total - totalLoan;

    setState(() {
      _monthlyPayment = monthly;
      _totalAmount = total;
      _totalInterest = interest;
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
              child: const Icon(Icons.credit_card, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'حاسبة القرض الشخصي',
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
            

            _buildInputCard(theme, 'مبلغ القرض', _amountController, 'أدخل المبلغ', Icons.money, 'المبلغ الذي تريد اقتراضه من البنك.\n\nمثال: إذا كنت تريد قرض 50,000 ريال، أدخل 50000'),
            const SizedBox(height: 16),
            _buildInputCard(theme, 'الرسوم الإدارية', _feesController, 'رسوم البنك', Icons.receipt, 'الرسوم التي يفرضها البنك عند منح القرض.\n\nمثال: إذا كانت الرسوم 2,000 ريال، أدخل 2000'),
            const SizedBox(height: 16),
            _buildSliderCard(theme, 'نسبة الفائدة', _interestRate, 2, 15, '%', (v) {
              setState(() => _interestRate = v);
              _calculate();
            }, 'نسبة الفائدة السنوية على القرض.\n\nمثال: إذا كانت الفائدة 5% سنوياً، اختر 5'),
            const SizedBox(height: 16),
            _buildSliderCard(theme, 'مدة السداد', _years, 1, 10, 'سنة', (v) {
              setState(() => _years = v);
              _calculate();
            }, 'عدد السنوات التي ستسدد فيها القرض.\n\nمثال: إذا كانت المدة 5 سنوات، اختر 5'),
            const SizedBox(height: 30),

            if (_monthlyPayment != null) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [const Color(0xFFec4899).withOpacity(0.2), const Color(0xFFec4899).withOpacity(0.1)]),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFec4899), width: 3),
                ),
                child: Column(
                  children: [
                    Icon(Icons.calendar_month, color: const Color(0xFFec4899), size: 48),
                    const SizedBox(height: 12),
                    Text('القسط الشهري', style: GoogleFonts.cairo(fontSize: 18, color: theme.textSecondaryColor)),
                    const SizedBox(height: 8),
                    Text('${_monthlyPayment!.toStringAsFixed(0)} ر.س', style: GoogleFonts.cairo(fontSize: 36, fontWeight: FontWeight.bold, color: const Color(0xFFec4899))),
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
                        border: Border.all(color: const Color(0xFF3b82f6).withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.payments, color: const Color(0xFF3b82f6), size: 32),
                          const SizedBox(height: 8),
                          Text('إجمالي المبلغ', style: GoogleFonts.cairo(fontSize: 12, color: theme.textSecondaryColor)),
                          const SizedBox(height: 4),
                          Text('${_totalAmount!.toStringAsFixed(0)} ر.س', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textPrimaryColor)),
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
                        border: Border.all(color: const Color(0xFFf59e0b).withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.trending_up, color: const Color(0xFFf59e0b), size: 32),
                          const SizedBox(height: 8),
                          Text('الفوائد', style: GoogleFonts.cairo(fontSize: 12, color: theme.textSecondaryColor)),
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
              helpers.buildHelpButton(context, theme, label, helpText, icon, const Color(0xFFec4899)),
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
                    helpers.buildHelpButton(context, theme, label, helpText, Icons.tune, const Color(0xFFec4899)),
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
            const Color(0xFFec4899).withOpacity(0.1),
            const Color(0xFFec4899).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFec4899).withOpacity(0.3), width: 2),
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
                    colors: [Color(0xFFec4899), Color(0xFFdb2777)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'كيف تستخدم حاسبة القرض الشخصي؟',
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFec4899),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'هذه الحاسبة تساعدك على معرفة القسط الشهري والتكلفة الإجمالية للقرض الشخصي.',
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
              color: const Color(0xFFec4899).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFec4899).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calculate, color: Color(0xFFec4899), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'مثال عملي:',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFec4899),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'مبلغ القرض: 50,000 ريال\n'
                  'رسوم إدارية: 2,000 ريال\n'
                  'نسبة الفائدة: 5% سنوياً\n'
                  'المدة: 5 سنوات',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: theme.textSecondaryColor,
                    height: 1.6,
                  ),
                ),
                const Divider(height: 24),
                Text(
                  '✅ القسط الشهري: ≈ 981 ريال\n'
                  '✅ إجمالي المدفوعات: ≈ 58,860 ريال\n'
                  '✅ إجمالي الفوائد: ≈ 6,860 ريال',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFec4899),
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
              color: const Color(0xFFef4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Color(0xFFef4444), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تنبيه: تأكد من قدرتك على سداد القسط الشهري قبل الاقتراض!',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: const Color(0xFFef4444),
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
    _amountController.dispose();
    _feesController.dispose();
    super.dispose();
  }
}

