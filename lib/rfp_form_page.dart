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
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _areaMinController = TextEditingController();
  final _areaMaxController = TextEditingController();
  final _roomsController = TextEditingController();
  
  String? _selectedCity = 'عرعر';
  String? _selectedType = 'land';
  String? _selectedStatus = 'for_sale';
  String? _contactPref = 'whatsapp';
  
  bool _isSubmitting = false;
  int _currentStep = 0;

  final List<String> _cities = [
    // المدن الرئيسية
    'عرعر', 'رفحاء', 'طريف', 'العويقيلة',
    // المراكز التابعة لعرعر
    'الجديدة', 'أم خنصر', 'حزم الجلاميد',
    // المراكز التابعة لرفحاء
    'لينة', 'الشعبة', 'سماح', 'نصاب', 'طلعة التمياط', 'بن شريم', 'بن هباس',
    'لوقة', 'أم رضمة', 'الخشيبي', 'زبالا', 'العجرمية', 'رغوة', 'الحدقة', 'الحدق',
    'أعيوج لينة', 'الجميمة',
    // المراكز التابعة لطريف
    'الجراني',
    // المراكز التابعة للعويقيلة
    'صحن', 'الأيدية', 'الكاسب', 'نعيجان', 'أبو رواث', 'الدويد', 'زهوة',
    // القرى والهجر
    'أم الضيان', 'قليب بن غنيم', 'حدق الجندة', 'قيصومة فيحان', 'ابن سوقي',
    'ابن عجل', 'الشريفات', 'الجبهان', 'المركوز', 'الديدب', 'السليمانية',
    'ابن سعيد', 'ابن بكر', 'ابن عايش', 'السلمانية', 'الأدية', 'آل علي',
    'دغيليب الوجعان', 'كمب الثنيان', 'الركعا',
    // مدن أخرى
    'القريات', 'سكاكا', 'حائل', 'تبوك', 'الجوف', 'دومة الجندل',
  ];
  
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
      backgroundColor: theme.isDarkMode ? const Color(0xFF0b0f14) : const Color(0xFFf5f7fa),
      body: SafeArea(
        child: Column(
          children: [
            // Header حديث
            _buildModernHeader(theme),
            
            // المحتوى
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // مقدمة جذابة
                      _buildIntroCard(theme),
                      const SizedBox(height: 24),
                      
                      // الخطوة 1: ماذا تبحث عنه؟
                      _buildSectionTitle('1. ماذا تبحث عنه؟', theme),
                      const SizedBox(height: 12),
                      _buildTypeSelector(theme),
                      const SizedBox(height: 16),
                      _buildStatusSelector(theme),
                      const SizedBox(height: 24),
                      
                      // الخطوة 2: أين؟
                      _buildSectionTitle('2. في أي مدينة؟', theme),
                      const SizedBox(height: 12),
                      _buildCitySelector(theme),
                      const SizedBox(height: 24),
                      
                      // الخطوة 3: الميزانية
                      _buildSectionTitle('3. ما هي ميزانيتك؟', theme),
                      const SizedBox(height: 12),
                      _buildBudgetRange(theme),
                      const SizedBox(height: 24),
                      
                      // الخطوة 4: المواصفات
                      _buildSectionTitle('4. المواصفات (اختياري)', theme),
                      const SizedBox(height: 12),
                      _buildAreaRange(theme),
                      const SizedBox(height: 16),
                      _buildRoomsInput(theme),
                      const SizedBox(height: 24),
                      
                      // الخطوة 5: ملاحظات
                      _buildSectionTitle('5. ملاحظات إضافية', theme),
                      const SizedBox(height: 12),
                      _buildNotesInput(theme),
                      const SizedBox(height: 24),
                      
                      // الخطوة 6: معلومات التواصل
                      _buildSectionTitle('6. كيف نتواصل معك؟', theme),
                      const SizedBox(height: 12),
                      _buildPhoneInput(theme),
                      const SizedBox(height: 16),
                      _buildContactPref(theme),
                      const SizedBox(height: 32),
                      
                      // زر الإرسال
                      _buildSubmitButton(theme),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // زر الرجوع
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 16),
              // العنوان
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'طلب عقار خاص',
                      style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'احصل على عروض من عدة مكاتب',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard(ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withOpacity(0.1),
            theme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.info_outline, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'املأ البيانات بدقة وسنرسل طلبك لجميع المكاتب المتخصصة',
              style: GoogleFonts.cairo(
                fontSize: 13,
                height: 1.6,
                color: theme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeConfig theme) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector(ThemeConfig theme) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _types.entries.map((e) {
        final isSelected = _selectedType == e.key;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = e.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                    )
                  : null,
              color: isSelected ? null : (theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? theme.primaryColor : (theme.isDarkMode ? const Color(0xFF2a2f3e) : const Color(0xFFe2e8f0)),
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              e.value,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : theme.textSecondaryColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusSelector(ThemeConfig theme) {
    return Row(
      children: [
        Expanded(child: _buildStatusChip('for_sale', 'للبيع', Icons.sell, theme)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatusChip('for_rent', 'للإيجار', Icons.key, theme)),
      ],
    );
  }

  Widget _buildStatusChip(String value, String label, IconData icon, ThemeConfig theme) {
    final isSelected = _selectedStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                )
              : null,
          color: isSelected ? null : (theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? theme.primaryColor : (theme.isDarkMode ? const Color(0xFF2a2f3e) : const Color(0xFFe2e8f0)),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : theme.textSecondaryColor,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : theme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitySelector(ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.isDarkMode ? const Color(0xFF2a2f3e) : const Color(0xFFe2e8f0),
          width: 2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCity,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: theme.primaryColor),
          style: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: theme.textPrimaryColor,
          ),
          dropdownColor: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
          items: _cities.map((city) {
            return DropdownMenuItem(
              value: city,
              child: Row(
                children: [
                  Icon(Icons.location_city, size: 18, color: theme.primaryColor),
                  const SizedBox(width: 12),
                  Text(city),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedCity = value),
        ),
      ),
    );
  }

  Widget _buildBudgetRange(ThemeConfig theme) {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: _budgetMinController,
            label: 'الحد الأدنى',
            hint: '100,000',
            prefix: 'ر.س',
            keyboardType: TextInputType.number,
            theme: theme,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_forward, size: 16, color: theme.primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTextField(
            controller: _budgetMaxController,
            label: 'الحد الأقصى',
            hint: '500,000',
            prefix: 'ر.س',
            keyboardType: TextInputType.number,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildAreaRange(ThemeConfig theme) {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: _areaMinController,
            label: 'المساحة من',
            hint: '200',
            suffix: 'م²',
            keyboardType: TextInputType.number,
            theme: theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTextField(
            controller: _areaMaxController,
            label: 'المساحة إلى',
            hint: '500',
            suffix: 'م²',
            keyboardType: TextInputType.number,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomsInput(ThemeConfig theme) {
    return _buildTextField(
      controller: _roomsController,
      label: 'عدد الغرف',
      hint: '4',
      icon: Icons.bed,
      keyboardType: TextInputType.number,
      theme: theme,
    );
  }

  Widget _buildNotesInput(ThemeConfig theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.isDarkMode ? const Color(0xFF2a2f3e) : const Color(0xFFe2e8f0),
          width: 2,
        ),
      ),
      child: TextFormField(
        controller: _notesController,
        maxLines: 4,
        style: GoogleFonts.cairo(color: theme.textPrimaryColor),
        decoration: InputDecoration(
          labelText: 'أخبرنا بالتفاصيل...',
          labelStyle: GoogleFonts.cairo(color: theme.textSecondaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          hintText: 'مثال: أبحث عن أرض في حي هادئ قريبة من الخدمات',
          hintStyle: GoogleFonts.cairo(
            fontSize: 13,
            color: theme.textSecondaryColor.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInput(ThemeConfig theme) {
    return _buildTextField(
      controller: _phoneController,
      label: 'رقم الجوال',
      hint: '05XXXXXXXX',
      icon: Icons.phone,
      keyboardType: TextInputType.phone,
      theme: theme,
      isRequired: true,
      validator: (value) {
        if (value == null || value.isEmpty) return 'رقم الجوال مطلوب';
        if (!RegExp(r'^05\d{8}$').hasMatch(value)) return 'رقم الجوال غير صحيح';
        return null;
      },
    );
  }

  Widget _buildContactPref(ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.isDarkMode ? const Color(0xFF2a2f3e) : const Color(0xFFe2e8f0),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'طريقة التواصل المفضلة',
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildContactOption('call', 'اتصال', Icons.call, theme),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContactOption('whatsapp', 'واتساب', Icons.chat, theme),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(String value, String label, IconData icon, ThemeConfig theme) {
    final isSelected = _contactPref == value;
    return GestureDetector(
      onTap: () => setState(() => _contactPref = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                )
              : null,
          color: isSelected ? null : (theme.isDarkMode ? const Color(0xFF0b0f14) : const Color(0xFFf1f5f9)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : theme.textSecondaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : theme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? prefix,
    String? suffix,
    IconData? icon,
    TextInputType? keyboardType,
    required ThemeConfig theme,
    bool isRequired = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.isDarkMode ? const Color(0xFF2a2f3e) : const Color(0xFFe2e8f0),
          width: 2,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.cairo(
          color: theme.textPrimaryColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        validator: validator,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          labelStyle: GoogleFonts.cairo(
            color: theme.textSecondaryColor,
            fontSize: 13,
          ),
          hintText: hint,
          hintStyle: GoogleFonts.cairo(
            color: theme.textSecondaryColor.withOpacity(0.5),
            fontSize: 14,
          ),
          prefixIcon: icon != null ? Icon(icon, color: theme.primaryColor, size: 22) : null,
          prefixText: prefix != null ? '$prefix ' : null,
          prefixStyle: GoogleFonts.cairo(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
          suffixText: suffix,
          suffixStyle: GoogleFonts.cairo(
            color: theme.textSecondaryColor,
            fontSize: 12,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ThemeConfig theme) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRfp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    'إرسال الطلب',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _submitRfp() async {
    if (!_formKey.currentState!.validate()) return;

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
          'budget_min': double.tryParse(_budgetMinController.text),
          'budget_max': double.tryParse(_budgetMaxController.text),
          'area_min': double.tryParse(_areaMinController.text),
          'area_max': double.tryParse(_areaMaxController.text),
          'rooms': int.tryParse(_roomsController.text),
          'notes': _notesController.text,
          'contact_pref': _contactPref,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (!mounted) return;
        
        final theme = Provider.of<ThemeConfig>(context, listen: false);
        
        // عرض نجاح مع أنيميشن
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _buildSuccessDialog(theme, data['message'] ?? 'تم الإرسال بنجاح'),
        );
      } else {
        throw Exception('فشل إرسال الطلب');
      }
    } catch (e) {
      debugPrint('❌ [RFP] خطأ: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء إرسال الطلب', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildSuccessDialog(ThemeConfig theme, String message) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // أيقونة النجاح
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.green.withOpacity(0.7)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 24),
            Text(
              'تم إرسال طلبك!',
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                height: 1.6,
                color: theme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // إغلاق Dialog
                  Navigator.pop(context); // العودة للصفحة السابقة
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'حسناً',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _notesController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _areaMinController.dispose();
    _areaMaxController.dispose();
    _roomsController.dispose();
    super.dispose();
  }
}
