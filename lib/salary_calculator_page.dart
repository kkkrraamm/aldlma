import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme_config.dart';

class SalaryCalculatorPage extends StatefulWidget {
  const SalaryCalculatorPage({super.key});

  @override
  State<SalaryCalculatorPage> createState() => _SalaryCalculatorPageState();
}

class _SalaryCalculatorPageState extends State<SalaryCalculatorPage> {
  final _basicSalaryController = TextEditingController();
  final _allowancesController = TextEditingController();
  final _deductionsController = TextEditingController();
  double _gosi = 9.75;
  
  double? _netSalary;
  double? _gosiAmount;
  double? _annualNet;

  void _calculate() {
    final basic = double.tryParse(_basicSalaryController.text) ?? 0;
    final allowances = double.tryParse(_allowancesController.text) ?? 0;
    final deductions = double.tryParse(_deductionsController.text) ?? 0;
    
    if (basic <= 0) {
      setState(() {
        _netSalary = null;
        _gosiAmount = null;
        _annualNet = null;
      });
      return;
    }

    final grossSalary = basic + allowances;
    final gosiDeduction = basic * (_gosi / 100);
    final netMonthly = grossSalary - gosiDeduction - deductions;
    final annualNet = netMonthly * 12;

    setState(() {
      _netSalary = netMonthly;
      _gosiAmount = gosiDeduction;
      _annualNet = annualNet;
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
              child: const Icon(Icons.payments, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'حاسبة الراتب الصافي',
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
            _buildInputCard(theme, 'الراتب الأساسي', _basicSalaryController, 'أدخل الراتب', Icons.account_balance_wallet),
            const SizedBox(height: 16),
            _buildInputCard(theme, 'البدلات', _allowancesController, 'بدل سكن، نقل، إلخ', Icons.add_circle),
            const SizedBox(height: 16),
            _buildInputCard(theme, 'خصومات أخرى', _deductionsController, 'قروض، إلخ', Icons.remove_circle),
            const SizedBox(height: 16),
            _buildSliderCard(theme, 'نسبة التأمينات', _gosi, 9, 12, '%', (v) {
              setState(() => _gosi = v);
              _calculate();
            }),
            const SizedBox(height: 30),

            if (_netSalary != null) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [const Color(0xFF6366f1).withOpacity(0.2), const Color(0xFF6366f1).withOpacity(0.1)]),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF6366f1), width: 3),
                ),
                child: Column(
                  children: [
                    Icon(Icons.account_balance_wallet, color: const Color(0xFF6366f1), size: 48),
                    const SizedBox(height: 12),
                    Text('الراتب الصافي', style: GoogleFonts.cairo(fontSize: 18, color: theme.textSecondaryColor)),
                    const SizedBox(height: 8),
                    Text('${_netSalary!.toStringAsFixed(0)} ر.س', style: GoogleFonts.cairo(fontSize: 36, fontWeight: FontWeight.bold, color: const Color(0xFF6366f1))),
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
                        border: Border.all(color: const Color(0xFFef4444).withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.remove_circle, color: const Color(0xFFef4444), size: 32),
                          const SizedBox(height: 8),
                          Text('التأمينات', style: GoogleFonts.cairo(fontSize: 12, color: theme.textSecondaryColor)),
                          const SizedBox(height: 4),
                          Text('${_gosiAmount!.toStringAsFixed(0)} ر.س', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textPrimaryColor)),
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
                          Icon(Icons.calendar_today, color: const Color(0xFF10b981), size: 32),
                          const SizedBox(height: 8),
                          Text('الصافي السنوي', style: GoogleFonts.cairo(fontSize: 12, color: theme.textSecondaryColor)),
                          const SizedBox(height: 4),
                          Text('${_annualNet!.toStringAsFixed(0)} ر.س', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textPrimaryColor)),
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
                child: Text('${value.toStringAsFixed(2)} $unit', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: theme.primaryColor)),
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
            child: Slider(value: value, min: min, max: max, divisions: ((max - min) * 100).toInt(), onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _basicSalaryController.dispose();
    _allowancesController.dispose();
    _deductionsController.dispose();
    super.dispose();
  }
}

