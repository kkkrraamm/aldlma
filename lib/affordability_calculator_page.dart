import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme_config.dart';

class AffordabilityCalculatorPage extends StatefulWidget {
  const AffordabilityCalculatorPage({super.key});

  @override
  State<AffordabilityCalculatorPage> createState() => _AffordabilityCalculatorPageState();
}

class _AffordabilityCalculatorPageState extends State<AffordabilityCalculatorPage> {
  final _salaryController = TextEditingController();
  final _obligationsController = TextEditingController();
  final _downPaymentController = TextEditingController();
  double _years = 20;
  double _interestRate = 4.0;
  
  double? _maxPrice;
  double? _monthlyPayment;
  double? _debtToIncome;

  void _calculate() {
    final salary = double.tryParse(_salaryController.text) ?? 0;
    final obligations = double.tryParse(_obligationsController.text) ?? 0;
    final downPayment = double.tryParse(_downPaymentController.text) ?? 0;
    
    if (salary <= 0) {
      setState(() {
        _maxPrice = null;
        _monthlyPayment = null;
        _debtToIncome = null;
      });
      return;
    }

    final availableIncome = salary - obligations;
    final maxMonthlyPayment = availableIncome * 0.33;
    final monthlyRate = _interestRate / 100 / 12;
    final numberOfPayments = _years * 12;
    final maxLoan = maxMonthlyPayment * (pow(1 + monthlyRate, numberOfPayments) - 1) / (monthlyRate * pow(1 + monthlyRate, numberOfPayments));
    final maxPropertyPrice = maxLoan + downPayment;
    final debtRatio = (maxMonthlyPayment / salary) * 100;

    setState(() {
      _maxPrice = maxPropertyPrice;
      _monthlyPayment = maxMonthlyPayment;
      _debtToIncome = debtRatio;
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
              child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'حاسبة القدرة الشرائية',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInputCard(theme, 'الراتب الشهري', _salaryController, 'أدخل راتبك', Icons.payments),
            const SizedBox(height: 16),
            _buildInputCard(theme, 'الالتزامات الشهرية', _obligationsController, 'أقساط، إيجار، إلخ', Icons.credit_card),
            const SizedBox(height: 16),
            _buildInputCard(theme, 'الدفعة الأولى المتاحة', _downPaymentController, 'المبلغ المدخر', Icons.savings),
            const SizedBox(height: 16),
            _buildSliderCard(theme, 'مدة التمويل', _years, 5, 30, 'سنة', (v) {
              setState(() => _years = v);
              _calculate();
            }),
            const SizedBox(height: 16),
            _buildSliderCard(theme, 'نسبة الفائدة', _interestRate, 2, 10, '%', (v) {
              setState(() => _interestRate = v);
              _calculate();
            }),
            const SizedBox(height: 30),

            if (_maxPrice != null) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [const Color(0xFF10b981).withOpacity(0.2), const Color(0xFF10b981).withOpacity(0.1)]),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF10b981), width: 3),
                  boxShadow: [BoxShadow(color: const Color(0xFF10b981).withOpacity(0.3), blurRadius: 20)],
                ),
                child: Column(
                  children: [
                    Icon(Icons.home_work, color: const Color(0xFF10b981), size: 48),
                    const SizedBox(height: 12),
                    Text('أقصى سعر عقار', style: GoogleFonts.cairo(fontSize: 18, color: theme.textSecondaryColor)),
                    const SizedBox(height: 8),
                    Text('${_maxPrice!.toStringAsFixed(0)} ر.س', style: GoogleFonts.cairo(fontSize: 36, fontWeight: FontWeight.bold, color: const Color(0xFF10b981))),
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
                          Icon(Icons.calendar_month, color: const Color(0xFF3b82f6), size: 32),
                          const SizedBox(height: 8),
                          Text('القسط الشهري', style: GoogleFonts.cairo(fontSize: 12, color: theme.textSecondaryColor)),
                          const SizedBox(height: 4),
                          Text('${_monthlyPayment!.toStringAsFixed(0)} ر.س', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textPrimaryColor)),
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
                          Icon(Icons.percent, color: const Color(0xFFf59e0b), size: 32),
                          const SizedBox(height: 8),
                          Text('نسبة الدين', style: GoogleFonts.cairo(fontSize: 12, color: theme.textSecondaryColor)),
                          const SizedBox(height: 4),
                          Text('${_debtToIncome!.toStringAsFixed(1)}%', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textPrimaryColor)),
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
                      'القسط المتاح = (الراتب - الالتزامات) × 33%\nأقصى سعر = القسط × عدد الأقساط / معامل التمويل + الدفعة',
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

  Widget _buildInputCard(ThemeConfig theme, String label, TextEditingController controller, String hint, IconData icon) {
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

  Widget _buildSliderCard(ThemeConfig theme, String label, double value, double min, double max, String unit, Function(double) onChanged) {
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
              Text(label, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimaryColor)),
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

  @override
  void dispose() {
    _salaryController.dispose();
    _obligationsController.dispose();
    _downPaymentController.dispose();
    super.dispose();
  }
}

