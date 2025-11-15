import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme_config.dart';

class FinishingCostCalculatorPage extends StatefulWidget {
  const FinishingCostCalculatorPage({super.key});

  @override
  State<FinishingCostCalculatorPage> createState() => _FinishingCostCalculatorPageState();
}

class _FinishingCostCalculatorPageState extends State<FinishingCostCalculatorPage> {
  final _areaController = TextEditingController();
  String _floorType = 'سيراميك';
  String _paintType = 'عادي';
  int _bathrooms = 2;
  int _kitchens = 1;
  
  double? _totalCost;
  Map<String, double>? _breakdown;

  final Map<String, double> _floorCosts = {
    'سيراميك': 80,
    'بورسلان': 120,
    'رخام': 200,
    'باركيه': 150,
  };

  final Map<String, double> _paintCosts = {
    'عادي': 15,
    'بلاستيك': 25,
    'جوتن': 40,
  };

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 0;
    
    if (area <= 0) {
      setState(() {
        _totalCost = null;
        _breakdown = null;
      });
      return;
    }

    final floorCost = area * _floorCosts[_floorType]!;
    final paintCost = area * _paintCosts[_paintType]!;
    final bathroomCost = _bathrooms * 8000;
    final kitchenCost = _kitchens * 15000;
    final electricCost = area * 50;
    final plumbingCost = area * 40;
    final total = floorCost + paintCost + bathroomCost + kitchenCost + electricCost + plumbingCost;

    setState(() {
      _totalCost = total;
      _breakdown = {
        'الأرضيات': floorCost,
        'الدهان': paintCost,
        'الحمامات': bathroomCost,
        'المطبخ': kitchenCost,
        'الكهرباء': electricCost,
        'السباكة': plumbingCost,
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
              child: const Icon(Icons.brush, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'حاسبة تكلفة التشطيب',
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
            _buildInputCard(theme, 'المساحة', _areaController, 'بالمتر المربع', Icons.square_foot),
            const SizedBox(height: 16),
            _buildDropdownCard(theme, 'نوع الأرضيات', _floorType, _floorCosts, (v) {
              setState(() => _floorType = v);
              _calculate();
            }),
            const SizedBox(height: 16),
            _buildDropdownCard(theme, 'نوع الدهان', _paintType, _paintCosts, (v) {
              setState(() => _paintType = v);
              _calculate();
            }),
            const SizedBox(height: 16),
            _buildCounterCard(theme, 'عدد الحمامات', _bathrooms, (v) {
              setState(() => _bathrooms = v);
              _calculate();
            }),
            const SizedBox(height: 16),
            _buildCounterCard(theme, 'عدد المطابخ', _kitchens, (v) {
              setState(() => _kitchens = v);
              _calculate();
            }),
            const SizedBox(height: 30),

            if (_totalCost != null) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [const Color(0xFFa855f7).withOpacity(0.2), const Color(0xFFa855f7).withOpacity(0.1)]),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFa855f7), width: 3),
                ),
                child: Column(
                  children: [
                    Icon(Icons.brush, color: const Color(0xFFa855f7), size: 48),
                    const SizedBox(height: 12),
                    Text('تكلفة التشطيب المتوقعة', style: GoogleFonts.cairo(fontSize: 18, color: theme.textSecondaryColor)),
                    const SizedBox(height: 8),
                    Text('${_totalCost!.toStringAsFixed(0)} ر.س', style: GoogleFonts.cairo(fontSize: 36, fontWeight: FontWeight.bold, color: const Color(0xFFa855f7))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
                    Text('تفصيل التكاليف:', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textPrimaryColor)),
                    const SizedBox(height: 16),
                    ..._breakdown!.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(e.key, style: GoogleFonts.cairo(fontSize: 14, color: theme.textSecondaryColor)),
                            ],
                          ),
                          Text('${e.value.toStringAsFixed(0)} ر.س', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textPrimaryColor)),
                        ],
                      ),
                    )),
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
              filled: true,
              fillColor: theme.isDarkMode ? const Color(0xFF2a2f3e) : const Color(0xFFf8fafc),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownCard(ThemeConfig theme, String label, String value, Map<String, double> options, Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(theme.isDarkMode ? 0.3 : 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimaryColor)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.isDarkMode ? const Color(0xFF2a2f3e) : const Color(0xFFf8fafc),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            items: options.keys.map((k) => DropdownMenuItem(value: k, child: Text('$k (${options[k]} ر.س/م²)', style: GoogleFonts.cairo()))).toList(),
            onChanged: (v) => onChanged(v!),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterCard(ThemeConfig theme, String label, int value, Function(int) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(theme.isDarkMode ? 0.3 : 0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimaryColor)),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove_circle, color: theme.primaryColor),
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$value', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primaryColor)),
              ),
              IconButton(
                icon: Icon(Icons.add_circle, color: theme.primaryColor),
                onPressed: () => onChanged(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }
}

