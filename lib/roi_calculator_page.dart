import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme_config.dart';
import 'calculator_helpers.dart' as helpers;

class ROICalculatorPage extends StatefulWidget {
  const ROICalculatorPage({super.key});

  @override
  State<ROICalculatorPage> createState() => _ROICalculatorPageState();
}

class _ROICalculatorPageState extends State<ROICalculatorPage> {
  final _purchasePriceController = TextEditingController();
  final _purchaseCostsController = TextEditingController();
  final _monthlyRentController = TextEditingController();
  final _maintenanceCostController = TextEditingController();
  double _vacancyRate = 5;
  
  double? _annualReturn;
  double? _roi;
  double? _paybackPeriod;
  double? _netProfit;

  void _calculate() {
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0;
    final purchaseCosts = double.tryParse(_purchaseCostsController.text) ?? 0;
    final monthlyRent = double.tryParse(_monthlyRentController.text) ?? 0;
    final maintenanceCost = double.tryParse(_maintenanceCostController.text) ?? 0;
    
    if (purchasePrice <= 0 || monthlyRent <= 0) {
      setState(() {
        _annualReturn = null;
        _roi = null;
        _paybackPeriod = null;
        _netProfit = null;
      });
      return;
    }

    final totalInvestment = purchasePrice + purchaseCosts;
    final annualRent = monthlyRent * 12;
    final vacancyLoss = annualRent * (_vacancyRate / 100);
    final effectiveRent = annualRent - vacancyLoss;
    final annualCosts = maintenanceCost;
    final netAnnualProfit = effectiveRent - annualCosts;
    final roi = (netAnnualProfit / totalInvestment) * 100;
    final paybackYears = totalInvestment / netAnnualProfit;

    setState(() {
      _annualReturn = effectiveRent;
      _roi = roi;
      _paybackPeriod = paybackYears;
      _netProfit = netAnnualProfit;
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
              child: const Icon(Icons.trending_up, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'حاسبة العائد على الاستثمار',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputCard(
              theme,
              'سعر الشراء',
              _purchasePriceController,
              'أدخل سعر العقار',
              Icons.home_work,
              hint: 'السعر الذي دفعته لشراء العقار (شقة، فيلا، أرض تجارية، إلخ).\n\nمثال: إذا اشتريت شقة بـ 400,000 ريال، أدخل هذا المبلغ هنا.',
            ),
            const SizedBox(height: 16),
            _buildInputCard(
              theme,
              'تكاليف الشراء',
              _purchaseCostsController,
              'رسوم، صيانة، إلخ',
              Icons.receipt,
              hint: 'المصاريف الإضافية عند الشراء (رسوم التسجيل، العمولة، الصيانة الأولية، إلخ).\n\nمثال: إذا دفعت 20,000 ريال رسوم ومصاريف، أدخلها هنا.',
            ),
            const SizedBox(height: 16),
            _buildInputCard(
              theme,
              'الإيجار الشهري المتوقع',
              _monthlyRentController,
              'أدخل الإيجار',
              Icons.attach_money,
              hint: 'المبلغ الذي تحصل عليه شهرياً من تأجير العقار.\n\nمثال: إذا كنت تؤجر الشقة بـ 2,000 ريال شهرياً، أدخل هذا المبلغ.',
            ),
            const SizedBox(height: 16),
            _buildInputCard(
              theme,
              'تكاليف الصيانة السنوية',
              _maintenanceCostController,
              'صيانة، إدارة، إلخ',
              Icons.build,
              hint: 'المصاريف السنوية للصيانة والإصلاحات (عادة 1-2% من قيمة العقار).\n\nمثال: إذا كانت الصيانة السنوية 5,000 ريال، أدخلها هنا.',
            ),
            const SizedBox(height: 16),
            _buildSliderCard(
              theme,
              'نسبة الشواغر المتوقعة',
              _vacancyRate,
              0,
              20,
              '%',
              (v) {
                setState(() => _vacancyRate = v);
                _calculate();
              },
              hint: 'النسبة المتوقعة لبقاء العقار فارغاً بدون مستأجر خلال السنة.\n\nمثال: 5% يعني أن العقار قد يبقى فارغاً شهر واحد من السنة (خسارة إيجار شهر).',
              icon: Icons.event_busy,
              color: const Color(0xFF8b5cf6),
            ),
            const SizedBox(height: 30),

            if (_roi != null) ...[
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
                    Text('نتائج الحساب', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textPrimaryColor)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildResultCard(theme, 'العائد السنوي', _annualReturn!, const Color(0xFF10b981), Icons.calendar_today),
              const SizedBox(height: 16),
              _buildResultCard(theme, 'نسبة العائد (ROI)', _roi!, const Color(0xFF3b82f6), Icons.percent, isPercent: true),
              const SizedBox(height: 16),
              _buildResultCard(theme, 'فترة استرداد رأس المال', _paybackPeriod!, const Color(0xFFf59e0b), Icons.schedule, isSuffix: ' سنة'),
              const SizedBox(height: 16),
              _buildResultCard(theme, 'الربح الصافي السنوي', _netProfit!, const Color(0xFF8b5cf6), Icons.account_balance),
              const SizedBox(height: 30),

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
                        Text('المعادلة الحسابية:', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textPrimaryColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ROI = ((الإيجار السنوي - الشواغر - التكاليف) / (سعر الشراء + التكاليف)) × 100\n\nفترة الاسترداد = التكلفة الإجمالية / الربح السنوي',
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
                child: Text('${value.toStringAsFixed(0)} $unit', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: theme.primaryColor)),
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
            child: Slider(value: value, min: min, max: max, divisions: (max - min).toInt(), onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(ThemeConfig theme, String label, double value, Color color, IconData icon, {bool isPercent = false, String isSuffix = ''}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.15), color.withOpacity(0.08)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 2),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)]),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.cairo(fontSize: 13, color: theme.textSecondaryColor, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text(
                  isPercent ? '${value.toStringAsFixed(2)}%' : '${value.toStringAsFixed(0)}$isSuffix${isSuffix.isEmpty ? ' ر.س' : ''}',
                  style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: color, height: 1.2),
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
    _purchasePriceController.dispose();
    _purchaseCostsController.dispose();
    _monthlyRentController.dispose();
    _maintenanceCostController.dispose();
    super.dispose();
  }
}

