import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme_config.dart';

class PurchaseCostsCalculatorPage extends StatefulWidget {
  const PurchaseCostsCalculatorPage({super.key});

  @override
  State<PurchaseCostsCalculatorPage> createState() => _PurchaseCostsCalculatorPageState();
}

class _PurchaseCostsCalculatorPageState extends State<PurchaseCostsCalculatorPage> {
  final _priceController = TextEditingController();
  double _registrationFee = 2.5;
  double _brokerFee = 2.0;
  final _evaluationController = TextEditingController();
  final _lawyerController = TextEditingController();
  final _otherController = TextEditingController();
  
  double? _totalCosts;
  double? _totalAmount;
  Map<String, double>? _breakdown;

  void _calculate() {
    final price = double.tryParse(_priceController.text) ?? 0;
    final evaluation = double.tryParse(_evaluationController.text) ?? 0;
    final lawyer = double.tryParse(_lawyerController.text) ?? 0;
    final other = double.tryParse(_otherController.text) ?? 0;
    
    if (price <= 0) {
      setState(() {
        _totalCosts = null;
        _totalAmount = null;
        _breakdown = null;
      });
      return;
    }

    final registration = price * (_registrationFee / 100);
    final broker = price * (_brokerFee / 100);
    final costs = registration + broker + evaluation + lawyer + other;
    final total = price + costs;

    setState(() {
      _totalCosts = costs;
      _totalAmount = total;
      _breakdown = {
        'رسوم التسجيل': registration,
        'رسوم الوسيط': broker,
        'رسوم التقييم': evaluation,
        'رسوم المحامي': lawyer,
        'رسوم أخرى': other,
      };
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
              child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'حاسبة تكاليف الشراء',
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
            _buildInputCard(theme, 'سعر العقار', _priceController, 'أدخل سعر العقار', Icons.home),
            const SizedBox(height: 16),
            _buildSliderCard(theme, 'رسوم التسجيل', _registrationFee, 0, 5, '%', (v) {
              setState(() => _registrationFee = v);
              _calculate();
            }),
            const SizedBox(height: 16),
            _buildSliderCard(theme, 'رسوم الوسيط', _brokerFee, 0, 5, '%', (v) {
              setState(() => _brokerFee = v);
              _calculate();
            }),
            const SizedBox(height: 16),
            _buildInputCard(theme, 'رسوم التقييم', _evaluationController, 'اختياري', Icons.assessment),
            const SizedBox(height: 16),
            _buildInputCard(theme, 'رسوم المحامي', _lawyerController, 'اختياري', Icons.gavel),
            const SizedBox(height: 16),
            _buildInputCard(theme, 'رسوم أخرى', _otherController, 'اختياري', Icons.more_horiz),
            const SizedBox(height: 30),

            if (_totalCosts != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [theme.primaryColor.withOpacity(0.15), theme.primaryColor.withOpacity(0.08)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.primaryColor.withOpacity(0.4), width: 2),
                ),
                child: Column(
                  children: [
                    Text('إجمالي التكاليف', style: GoogleFonts.cairo(fontSize: 16, color: theme.textSecondaryColor)),
                    const SizedBox(height: 8),
                    Text('${_totalCosts!.toStringAsFixed(0)} ر.س', style: GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [const Color(0xFF3b82f6).withOpacity(0.15), const Color(0xFF3b82f6).withOpacity(0.08)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3b82f6).withOpacity(0.4), width: 2),
                ),
                child: Column(
                  children: [
                    Text('المبلغ الإجمالي المطلوب', style: GoogleFonts.cairo(fontSize: 16, color: theme.textSecondaryColor)),
                    const SizedBox(height: 8),
                    Text('${_totalAmount!.toStringAsFixed(0)} ر.س', style: GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF3b82f6))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ..._breakdown!.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: GoogleFonts.cairo(fontSize: 14, color: theme.textSecondaryColor)),
                    Text('${e.value.toStringAsFixed(0)} ر.س', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textPrimaryColor)),
                  ],
                ),
              )),
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

  @override
  void dispose() {
    _priceController.dispose();
    _evaluationController.dispose();
    _lawyerController.dispose();
    _otherController.dispose();
    super.dispose();
  }
}

