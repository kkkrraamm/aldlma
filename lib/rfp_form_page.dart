import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'theme_config.dart';
import 'api_config.dart';

class RfpFormPage extends StatefulWidget {
  const RfpFormPage({super.key});

  @override
  State<RfpFormPage> createState() => _RfpFormPageState();
}

class _RfpFormPageState extends State<RfpFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedCity = 'عرعر';
  String? _selectedType = 'apartment';
  String? _selectedStatus = 'for_sale';
  String? _contactPref = 'call';
  double? _budgetMin;
  double? _budgetMax;
  double? _areaMin;
  double? _areaMax;
  int? _rooms;
  
  bool _isSubmitting = false;

  final List<String> _cities = ['عرعر', 'رفحاء', 'طريف', 'القريات', 'سكاكا'];
  final Map<String, String> _types = {
    'apartment': 'شقة',
    'villa': 'فيلا',
    'land': 'أرض',
    'building': 'عمارة',
    'farm': 'مزرعة',
    'warehouse': 'مستودع',
    'office': 'مكتب',
    'shop': 'محل',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);
    
    return Scaffold(
      backgroundColor: theme.isDarkMode ? const Color(0xFF0b0f14) : const Color(0xFFf8fafc),
      appBar: AppBar(
        title: Text(
          'طلب عقار خاص',
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: theme.primaryColor,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // مقدمة
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'املأ البيانات وستتلقى عروض من المكاتب العقارية',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: theme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // المدينة
            _buildDropdown(
              label: 'المدينة *',
              value: _selectedCity,
              items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (value) => setState(() => _selectedCity = value),
              theme: theme,
            ),
            const SizedBox(height: 16),

            // نوع العقار
            _buildDropdown(
              label: 'نوع العقار *',
              value: _selectedType,
              items: _types.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedType = value),
              theme: theme,
            ),
            const SizedBox(height: 16),

            // الحالة
            _buildDropdown(
              label: 'الحالة *',
              value: _selectedStatus,
              items: const [
                DropdownMenuItem(value: 'for_sale', child: Text('للبيع')),
                DropdownMenuItem(value: 'for_rent', child: Text('للإيجار')),
              ],
              onChanged: (value) => setState(() => _selectedStatus = value),
              theme: theme,
            ),
            const SizedBox(height: 24),

            // الميزانية
            Text(
              'الميزانية (ر.س)',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: _inputDecoration('من', theme),
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.cairo(color: theme.textPrimaryColor),
                    onChanged: (value) {
                      _budgetMin = double.tryParse(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: _inputDecoration('إلى', theme),
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.cairo(color: theme.textPrimaryColor),
                    onChanged: (value) {
                      _budgetMax = double.tryParse(value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // المساحة
            Text(
              'المساحة (م²)',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: _inputDecoration('من', theme),
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.cairo(color: theme.textPrimaryColor),
                    onChanged: (value) {
                      _areaMin = double.tryParse(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: _inputDecoration('إلى', theme),
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.cairo(color: theme.textPrimaryColor),
                    onChanged: (value) {
                      _areaMax = double.tryParse(value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // عدد الغرف
            TextFormField(
              decoration: _inputDecoration('عدد الغرف', theme),
              keyboardType: TextInputType.number,
              style: GoogleFonts.cairo(color: theme.textPrimaryColor),
              onChanged: (value) {
                _rooms = int.tryParse(value);
              },
            ),
            const SizedBox(height: 16),

            // ملاحظات
            TextFormField(
              controller: _notesController,
              decoration: _inputDecoration('ملاحظات أو تفاصيل إضافية', theme),
              maxLines: 4,
              style: GoogleFonts.cairo(color: theme.textPrimaryColor),
            ),
            const SizedBox(height: 16),

            // رقم الجوال
            TextFormField(
              controller: _phoneController,
              decoration: _inputDecoration('رقم الجوال *', theme),
              keyboardType: TextInputType.phone,
              style: GoogleFonts.cairo(color: theme.textPrimaryColor),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'رقم الجوال مطلوب';
                }
                if (!RegExp(r'^05\d{8}$').hasMatch(value)) {
                  return 'رقم الجوال غير صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // طريقة التواصل المفضلة
            Text(
              'طريقة التواصل المفضلة',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('اتصال', style: GoogleFonts.cairo(fontSize: 13)),
                    value: 'call',
                    groupValue: _contactPref,
                    activeColor: theme.primaryColor,
                    onChanged: (value) => setState(() => _contactPref = value),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('واتساب', style: GoogleFonts.cairo(fontSize: 13)),
                    value: 'whatsapp',
                    groupValue: _contactPref,
                    activeColor: theme.primaryColor,
                    onChanged: (value) => setState(() => _contactPref = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // زر الإرسال
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRfp,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'إرسال الطلب',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    required ThemeConfig theme,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _inputDecoration(label, theme),
      dropdownColor: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
      style: GoogleFonts.cairo(color: theme.textPrimaryColor),
      items: items,
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration(String label, ThemeConfig theme) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(color: theme.textSecondaryColor),
      filled: true,
      fillColor: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.isDarkMode ? const Color(0xFF2a2f3e) : const Color(0xFFe2e8f0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.isDarkMode ? const Color(0xFF2a2f3e) : const Color(0xFFe2e8f0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primaryColor, width: 2),
      ),
    );
  }

  Future<void> _submitRfp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/realty/rfp/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_phone': _phoneController.text,
          'city': _selectedCity,
          'type': _selectedType,
          'status': _selectedStatus,
          'budget_min': _budgetMin,
          'budget_max': _budgetMax,
          'area_min': _areaMin,
          'area_max': _areaMax,
          'rooms': _rooms,
          'notes': _notesController.text,
          'contact_pref': _contactPref,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (!mounted) return;
        
        // عرض رسالة نجاح
        showDialog(
          context: context,
          builder: (context) {
            final theme = Provider.of<ThemeConfig>(context);
            return AlertDialog(
              backgroundColor: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: theme.primaryColor, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    'تم الإرسال!',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              content: Text(
                data['message'] ?? 'تم إرسال طلبك بنجاح. ستتلقى عروض من المكاتب قريباً.',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  height: 1.6,
                  color: theme.textSecondaryColor,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // إغلاق الـ dialog
                    Navigator.pop(context); // العودة للصفحة السابقة
                  },
                  child: Text(
                    'حسناً',
                    style: GoogleFonts.cairo(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      } else {
        throw Exception('فشل إرسال الطلب');
      }
    } catch (e) {
      debugPrint('❌ [RFP] خطأ: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء إرسال الطلب',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

