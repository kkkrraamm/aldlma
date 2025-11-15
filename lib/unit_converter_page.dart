import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme_config.dart';
import 'calculator_helpers.dart' as helpers;

class UnitConverterPage extends StatefulWidget {
  const UnitConverterPage({super.key});

  @override
  State<UnitConverterPage> createState() => _UnitConverterPageState();
}

class _UnitConverterPageState extends State<UnitConverterPage> {
  final _inputController = TextEditingController();
  String _fromUnit = 'متر مربع';
  String _toUnit = 'قدم مربع';
  double? _result;
  
  bool _showHelp = false;

  final Map<String, double> _units = {
    'متر مربع': 1.0,
    'قدم مربع': 10.764,
    'هكتار': 0.0001,
    'دونم': 0.001,
    'ذراع': 2.25,
    'فدان': 0.000238,
  };

  void _convert() {
    final value = double.tryParse(_inputController.text) ?? 0;
    if (value <= 0) {
      setState(() => _result = null);
      return;
    }

    final valueInMeters = value / _units[_fromUnit]!;
    final converted = valueInMeters * _units[_toUnit]!;
    setState(() => _result = converted);
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
              child: const Icon(Icons.straighten, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'محول الوحدات',
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
          children: [
            if (_showHelp) _buildHelpSection(theme),
            if (_showHelp) const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(theme.isDarkMode ? 0.3 : 0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Text('من', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textPrimaryColor)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _inputController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _convert(),
                    style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textPrimaryColor),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '0',
                      filled: true,
                      fillColor: theme.isDarkMode ? const Color(0xFF2a2f3e) : const Color(0xFFf8fafc),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _fromUnit,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.isDarkMode ? const Color(0xFF2a2f3e) : const Color(0xFFf8fafc),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: _units.keys.map((unit) => DropdownMenuItem(value: unit, child: Text(unit, style: GoogleFonts.cairo()))).toList(),
                    onChanged: (v) {
                      setState(() => _fromUnit = v!);
                      _convert();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Icon(Icons.swap_vert, color: theme.primaryColor, size: 40),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [theme.primaryColor.withOpacity(0.15), theme.primaryColor.withOpacity(0.08)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.primaryColor.withOpacity(0.4), width: 2),
              ),
              child: Column(
                children: [
                  Text('إلى', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textPrimaryColor)),
                  const SizedBox(height: 12),
                  Text(
                    _result != null ? _result!.toStringAsFixed(2) : '0',
                    style: GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.bold, color: theme.primaryColor),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _toUnit,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.isDarkMode ? const Color(0xFF2a2f3e) : const Color(0xFFf8fafc),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: _units.keys.map((unit) => DropdownMenuItem(value: unit, child: Text(unit, style: GoogleFonts.cairo()))).toList(),
                    onChanged: (v) {
                      setState(() => _toUnit = v!);
                      _convert();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection(ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF06b6d4).withOpacity(0.1),
            const Color(0xFF06b6d4).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF06b6d4).withOpacity(0.3), width: 2),
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
                    colors: [Color(0xFF06b6d4), Color(0xFF0891b2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'كيف تستخدم محول الوحدات؟',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF06b6d4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'هذه الأداة تساعدك على تحويل المساحات بين الوحدات المختلفة (متر، قدم، دونم، هكتار، إلخ).',
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
              color: const Color(0xFF06b6d4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF06b6d4).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calculate, color: Color(0xFF06b6d4), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'أمثلة عملية:',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF06b6d4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• 100 متر مربع = 1,076 قدم مربع\n'
                  '• 1 دونم = 1,000 متر مربع\n'
                  '• 1 هكتار = 10,000 متر مربع\n'
                  '• 1 فدان = 4,200 متر مربع\n'
                  '• 1 ذراع = 0.444 متر مربع',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: theme.textSecondaryColor,
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
              color: const Color(0xFF10b981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates, color: Color(0xFF10b981), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'نصيحة: المتر المربع هو الوحدة الأكثر استخداماً في السعودية',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: const Color(0xFF10b981),
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
    _inputController.dispose();
    super.dispose();
  }
}

