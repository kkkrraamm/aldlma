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

  bool _showHelp = false;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // قسم المساعدة
            if (_showHelp) _buildHelpSection(theme),
            if (_showHelp) const SizedBox(height: 20),
            
            // سعر العقار
            _buildInputCard(
              theme,
              'سعر العقار',
              _priceController,
              'أدخل سعر العقار',
              Icons.home_work,
              hint: 'السعر الكامل للعقار الذي تريد شراءه (شقة، فيلا، أرض، إلخ).\n\nمثال: إذا كان سعر الشقة 500,000 ريال، أدخل هذا المبلغ هنا. هذا هو السعر قبل أي خصومات أو دفعات.',
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
              hint: 'المبلغ الذي ستدفعه من جيبك عند شراء العقار. كلما زادت النسبة، قل مبلغ التمويل والفوائد.\n\nمثال: إذا كان سعر العقار 500,000 ر.س ونسبة الدفعة 20%، ستدفع 100,000 ر.س والباقي 400,000 ر.س تمويل من البنك.',
              icon: Icons.account_balance_wallet,
              color: const Color(0xFF3b82f6),
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
              hint: 'عدد السنوات التي ستسدد فيها القرض. كلما زادت المدة، قل القسط الشهري لكن تزيد الفوائد الإجمالية.\n\nمثال: 20 سنة = 240 قسط شهري. إذا اخترت 10 سنوات، القسط سيكون أعلى لكن الفوائد أقل.',
              icon: Icons.calendar_today,
              color: const Color(0xFFf59e0b),
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
              hint: 'الفائدة السنوية التي يفرضها البنك على مبلغ التمويل. تختلف من بنك لآخر وحسب نوع التمويل.\n\nمثال: البنوك السعودية عادة تقدم فوائد بين 3-5% سنوياً للتمويل العقاري.',
              icon: Icons.percent,
              color: const Color(0xFFef4444),
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
    String placeholder,
    IconData icon, {
    String? hint,
  }) {
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
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimaryColor,
                  ),
                ),
              ),
              if (hint != null)
                GestureDetector(
                  onTap: () => _showFieldHelp(context, theme, label, hint, icon, theme.primaryColor),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.help_outline,
                      size: 18,
                      color: theme.primaryColor,
                    ),
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
              hintText: placeholder,
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
    Function(double) onChanged, {
    String? hint,
    IconData? icon,
    Color? color,
  }) {
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
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimaryColor,
                        ),
                      ),
                    ),
                    if (hint != null)
                      GestureDetector(
                        onTap: () => _showFieldHelp(context, theme, label, hint, icon ?? Icons.tune, color ?? theme.primaryColor),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.help_outline,
                            size: 18,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
                  'كيف تستخدم حاسبة التمويل؟',
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
          _buildHelpItem(
            theme,
            Icons.home_work,
            'سعر العقار',
            'السعر الكامل للعقار الذي تريد شراءه',
            'مثال: إذا كان سعر الشقة 500,000 ر.س',
            const Color(0xFF10b981),
          ),
          const SizedBox(height: 16),
          _buildHelpItem(
            theme,
            Icons.account_balance_wallet,
            'الدفعة الأولى',
            'المبلغ الذي ستدفعه من جيبك (نسبة من سعر العقار)',
            'مثال: 20% يعني ستدفع 100,000 ر.س والباقي تمويل',
            const Color(0xFF3b82f6),
          ),
          const SizedBox(height: 16),
          _buildHelpItem(
            theme,
            Icons.calendar_today,
            'مدة التمويل',
            'عدد السنوات التي ستسدد فيها القرض',
            'مثال: 20 سنة = 240 قسط شهري',
            const Color(0xFFf59e0b),
          ),
          const SizedBox(height: 16),
          _buildHelpItem(
            theme,
            Icons.percent,
            'نسبة الفائدة',
            'الفائدة السنوية التي يفرضها البنك على التمويل',
            'مثال: 4% سنوياً (تختلف من بنك لآخر)',
            const Color(0xFFef4444),
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
                _buildExampleRow(theme, 'سعر الشقة', '500,000 ر.س'),
                _buildExampleRow(theme, 'الدفعة الأولى (20%)', '100,000 ر.س'),
                _buildExampleRow(theme, 'مبلغ التمويل', '400,000 ر.س'),
                _buildExampleRow(theme, 'المدة', '20 سنة'),
                _buildExampleRow(theme, 'الفائدة', '4% سنوياً'),
                const Divider(height: 24),
                _buildExampleRow(theme, 'القسط الشهري', '≈ 2,424 ر.س', isResult: true),
                _buildExampleRow(theme, 'إجمالي المدفوعات', '≈ 581,760 ر.س', isResult: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(ThemeConfig theme, IconData icon, String title, String description, String example, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: theme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                example,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: color,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExampleRow(ThemeConfig theme, String label, String value, {bool isResult = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: isResult ? 14 : 13,
              fontWeight: isResult ? FontWeight.bold : FontWeight.normal,
              color: isResult ? const Color(0xFF10b981) : theme.textSecondaryColor,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: isResult ? 15 : 13,
              fontWeight: isResult ? FontWeight.bold : FontWeight.w600,
              color: isResult ? const Color(0xFF10b981) : theme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showFieldHelp(BuildContext context, ThemeConfig theme, String title, String description, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // الأيقونة
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 20),
              
              // العنوان
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // الوصف
              Text(
                description,
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  color: theme.textSecondaryColor,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // زر الإغلاق
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'فهمت!',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }
}

