import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme_config.dart';
import 'calculator_helpers.dart' as helpers;

class ConstructionCostCalculatorPage extends StatefulWidget {
  const ConstructionCostCalculatorPage({super.key});

  @override
  State<ConstructionCostCalculatorPage> createState() => _ConstructionCostCalculatorPageState();
}

class _ConstructionCostCalculatorPageState extends State<ConstructionCostCalculatorPage> {
  final _landAreaController = TextEditingController();
  final _buildAreaController = TextEditingController();
  String _finishType = 'عادي';
  int _floors = 1;
  
  double? _totalCost;
  double? _costPerMeter;
  double? _estimatedDuration;
  
  bool _showHelp = false;

  final Map<String, double> _finishCosts = {
    'عادي': 800,
    'جيد': 1200,
    'فاخر': 1800,
    'سوبر فاخر': 2500,
  };

  void _calculate() {
    final buildArea = double.tryParse(_buildAreaController.text) ?? 0;
    
    if (buildArea <= 0) {
      setState(() {
        _totalCost = null;
        _costPerMeter = null;
        _estimatedDuration = null;
      });
      return;
    }

    final costPerMeter = _finishCosts[_finishType]!;
    final totalCost = buildArea * costPerMeter * _floors;
    final duration = (buildArea * _floors) / 100;

    setState(() {
      _totalCost = totalCost;
      _costPerMeter = costPerMeter;
      _estimatedDuration = duration;
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
              child: const Icon(Icons.construction, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'حاسبة تكلفة البناء',
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
            

            _buildInputCard(theme, 'مساحة الأرض', _landAreaController, 'بالمتر المربع', Icons.landscape, 'مساحة الأرض الإجمالية.\\n\\nمثال: إذا كانت أرضك 500 متر مربع، أدخل 500'),
            const SizedBox(height: 16),
            _buildInputCard(theme, 'مساحة البناء', _buildAreaController, 'بالمتر المربع', Icons.home_work, 'مساحة البناء الفعلية (عادة 60-70% من مساحة الأرض).\\n\\nمثال: إذا كانت مساحة البناء 300 متر، أدخل 300'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(theme.isDarkMode ? 0.3 : 0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('نوع التشطيب', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimaryColor)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _finishType,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.isDarkMode ? const Color(0xFF2a2f3e) : const Color(0xFFf8fafc),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: _finishCosts.keys.map((type) => DropdownMenuItem(value: type, child: Text('$type (${_finishCosts[type]} ر.س/م²)', style: GoogleFonts.cairo()))).toList(),
                    onChanged: (v) {
                      setState(() => _finishType = v!);
                      _calculate();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(theme.isDarkMode ? 0.3 : 0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('عدد الأدوار', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimaryColor)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text('$_floors', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                      ),
                    ],
                  ),
                  Slider(
                    value: _floors.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (v) {
                      setState(() => _floors = v.toInt());
                      _calculate();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            if (_totalCost != null) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [const Color(0xFFf97316).withOpacity(0.2), const Color(0xFFf97316).withOpacity(0.1)]),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFf97316), width: 3),
                ),
                child: Column(
                  children: [
                    Icon(Icons.construction, color: const Color(0xFFf97316), size: 48),
                    const SizedBox(height: 12),
                    Text('تكلفة البناء المتوقعة', style: GoogleFonts.cairo(fontSize: 18, color: theme.textSecondaryColor)),
                    const SizedBox(height: 8),
                    Text('${_totalCost!.toStringAsFixed(0)} ر.س', style: GoogleFonts.cairo(fontSize: 36, fontWeight: FontWeight.bold, color: const Color(0xFFf97316))),
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
                          Icon(Icons.attach_money, color: theme.primaryColor, size: 32),
                          const SizedBox(height: 8),
                          Text('تكلفة المتر', style: GoogleFonts.cairo(fontSize: 12, color: theme.textSecondaryColor)),
                          const SizedBox(height: 4),
                          Text('${_costPerMeter!.toStringAsFixed(0)} ر.س', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textPrimaryColor)),
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
                          Icon(Icons.schedule, color: const Color(0xFF3b82f6), size: 32),
                          const SizedBox(height: 8),
                          Text('المدة المتوقعة', style: GoogleFonts.cairo(fontSize: 12, color: theme.textSecondaryColor)),
                          const SizedBox(height: 4),
                          Text('${_estimatedDuration!.toStringAsFixed(1)} شهر', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textPrimaryColor)),
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
              helpers.buildHelpButton(context, theme, label, helpText, icon, const Color(0xFFf97316)),
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
              suffixText: 'م²',
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

  Widget _buildHelpSection(ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFf97316).withOpacity(0.1),
            const Color(0xFFf97316).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFf97316).withOpacity(0.3), width: 2),
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
                    colors: [Color(0xFFf97316), Color(0xFFea580c)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'كيف تستخدم حاسبة تكلفة البناء؟',
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFf97316),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'هذه الحاسبة تساعدك على تقدير تكلفة بناء عقار جديد بناءً على المساحة والجودة.',
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
              color: const Color(0xFFf97316).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFf97316).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calculate, color: Color(0xFFf97316), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'مثال عملي:',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFf97316),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'مساحة الأرض: 500 متر مربع\n'
                  'مساحة البناء: 300 متر مربع\n'
                  'جودة البناء: جيد (1,200 ر.س/م²)\n'
                  'عدد الأدوار: 2',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: theme.textSecondaryColor,
                    height: 1.6,
                  ),
                ),
                const Divider(height: 24),
                Text(
                  '✅ التكلفة الإجمالية: ≈ 360,000 ريال\n'
                  '✅ التكلفة للمتر: 1,200 ريال\n'
                  '✅ المدة المتوقعة: ≈ 12 شهر',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFf97316),
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
                    'نصيحة: احسب 10-15% إضافية للطوارئ والتكاليف غير المتوقعة',
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
    _landAreaController.dispose();
    _buildAreaController.dispose();
    super.dispose();
  }
}

