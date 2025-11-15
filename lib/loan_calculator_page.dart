import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme_config.dart';

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInputCard(theme, 'مبلغ القرض', _amountController, 'أدخل المبلغ', Icons.money),
            const SizedBox(height: 16),
            _buildInputCard(theme, 'الرسوم الإدارية', _feesController, 'رسوم البنك', Icons.receipt),
            const SizedBox(height: 16),
            _buildSliderCard(theme, 'نسبة الفائدة', _interestRate, 2, 15, '%', (v) {
              setState(() => _interestRate = v);
              _calculate();
            }),
            const SizedBox(height: 16),
            _buildSliderCard(theme, 'مدة السداد', _years, 1, 10, 'سنة', (v) {
              setState(() => _years = v);
              _calculate();
            }),
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
    _amountController.dispose();
    _feesController.dispose();
    super.dispose();
  }
}

