import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme_config.dart';

class MortgageCalculatorPage extends StatefulWidget {
  final double? initialPrice;
  
  const MortgageCalculatorPage({super.key, this.initialPrice});

  @override
  State<MortgageCalculatorPage> createState() => _MortgageCalculatorPageState();
}

class _MortgageCalculatorPageState extends State<MortgageCalculatorPage> {
  final _priceController = TextEditingController();
  double _downPaymentPercent = 20;
  int _years = 20;
  double _interestRate = 4.0;
  
  double? _monthlyPayment;
  double? _totalPayment;
  double? _totalInterest;

  @override
  void initState() {
    super.initState();
    if (widget.initialPrice != null) {
      _priceController.text = widget.initialPrice!.toStringAsFixed(0);
      _calculate();
    }
  }

  void _calculate() {
    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      setState(() {
        _monthlyPayment = null;
        _totalPayment = null;
        _totalInterest = null;
      });
      return;
    }

    final downPayment = price * (_downPaymentPercent / 100);
    final loanAmount = price - downPayment;
    final monthlyRate = _interestRate / 100 / 12;
    final numberOfPayments = _years * 12;

    // حساب القسط الشهري باستخدام معادلة التمويل
    final monthlyPayment = loanAmount *
        (monthlyRate * pow(1 + monthlyRate, numberOfPayments)) /
        (pow(1 + monthlyRate, numberOfPayments) - 1);

    final totalPayment = monthlyPayment * numberOfPayments + downPayment;
    final totalInterest = totalPayment - price;

    setState(() {
      _monthlyPayment = monthlyPayment;
      _totalPayment = totalPayment;
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
              child: const Icon(Icons.calculate, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'حاسبة التمويل',
              style: GoogleFonts.cairo(
                fontSize: 20,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // سعر العقار
            _buildInputCard(
              theme,
              'سعر العقار',
              _priceController,
              'أدخل سعر العقار',
              Icons.home_work,
            ),
            const SizedBox(height: 20),

            // نسبة الدفعة الأولى
            _buildSliderCard(
              theme,
              'نسبة الدفعة الأولى',
              _downPaymentPercent,
              0,
              50,
              '%',
              (value) {
                setState(() => _downPaymentPercent = value);
                _calculate();
              },
            ),
            const SizedBox(height: 20),

            // مدة التمويل
            _buildSliderCard(
              theme,
              'مدة التمويل',
              _years.toDouble(),
              5,
              30,
              'سنة',
              (value) {
                setState(() => _years = value.toInt());
                _calculate();
              },
            ),
            const SizedBox(height: 20),

            // نسبة الفائدة
            _buildSliderCard(
              theme,
              'نسبة الفائدة السنوية',
              _interestRate,
              2,
              10,
              '%',
              (value) {
                setState(() => _interestRate = value);
                _calculate();
              },
            ),
            const SizedBox(height: 30),

            // النتائج
            if (_monthlyPayment != null) ...[
              // عنوان النتائج
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primaryColor.withOpacity(0.1), theme.primaryColor.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.analytics, color: theme.primaryColor, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'نتائج الحساب',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildResultCard(
                theme,
                'القسط الشهري',
                _monthlyPayment!,
                const Color(0xFF10b981),
                Icons.calendar_month,
              ),
              const SizedBox(height: 16),
              _buildResultCard(
                theme,
                'إجمالي المبلغ المدفوع',
                _totalPayment!,
                const Color(0xFF3b82f6),
                Icons.payments,
              ),
              const SizedBox(height: 16),
              _buildResultCard(
                theme,
                'إجمالي الفوائد',
                _totalInterest!,
                const Color(0xFFf59e0b),
                Icons.trending_up,
              ),
              const SizedBox(height: 20),
              
              // معلومات إضافية
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      theme,
                      'الدفعة الأولى',
                      '${((double.tryParse(_priceController.text) ?? 0) * (_downPaymentPercent / 100)).toStringAsFixed(0)} ر.س',
                      Icons.money,
                      theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      theme,
                      'مبلغ التمويل',
                      '${((double.tryParse(_priceController.text) ?? 0) * (1 - _downPaymentPercent / 100)).toStringAsFixed(0)} ر.س',
                      Icons.account_balance,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // ملاحظة
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'هذه الحسابات تقريبية وقد تختلف حسب البنك والشروط',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: theme.textPrimaryColor,
                        ),
                      ),
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

  Widget _buildInputCard(
    ThemeConfig theme,
    String label,
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => _calculate(),
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textPrimaryColor,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.cairo(
                color: theme.textSecondaryColor,
              ),
              suffixText: 'ر.س',
              suffixStyle: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.primaryColor,
              ),
              filled: true,
              fillColor: theme.isDarkMode
                  ? const Color(0xFF2a2f3e)
                  : const Color(0xFFf8fafc),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderCard(
    ThemeConfig theme,
    String label,
    double value,
    double min,
    double max,
    String unit,
    Function(double) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value.toStringAsFixed(unit == '%' ? 0 : 1)} $unit',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: theme.primaryColor,
              inactiveTrackColor: theme.primaryColor.withOpacity(0.2),
              thumbColor: theme.primaryColor,
              overlayColor: theme.primaryColor.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: ((max - min) * (unit == '%' ? 1 : 10)).toInt(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(
    ThemeConfig theme,
    String label,
    double value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: theme.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${value.toStringAsFixed(0)} ر.س',
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard(
    ThemeConfig theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.isDarkMode ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: theme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }
}

