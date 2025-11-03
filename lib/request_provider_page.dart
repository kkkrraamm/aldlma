import 'package:flutter/material.dart';
import 'theme_config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'secure_api_service.dart';
import 'package:geolocator/geolocator.dart';

class RequestProviderPage extends StatefulWidget {
  const RequestProviderPage({Key? key}) : super(key: key);

  @override
  _RequestProviderPageState createState() => _RequestProviderPageState();
}

class _RequestProviderPageState extends State<RequestProviderPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  bool _hasCommercialLicense = false;
  File? _licenseImage;
  final ImagePicker _picker = ImagePicker();
  
  String? _selectedCategory;
  final List<Map<String, dynamic>> _categories = [
    {'name': 'مطاعم', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'name': 'صيانة', 'icon': Icons.build, 'color': Colors.blue},
    {'name': 'تنظيف', 'icon': Icons.cleaning_services, 'color': Colors.green},
    {'name': 'تصميم', 'icon': Icons.palette, 'color': Colors.purple},
    {'name': 'نقل', 'icon': Icons.local_shipping, 'color': Colors.brown},
    {'name': 'تعليم', 'icon': Icons.school, 'color': Colors.indigo},
    {'name': 'صحة ورياضة', 'icon': Icons.fitness_center, 'color': Colors.red},
    {'name': 'تجميل', 'icon': Icons.face, 'color': Colors.pink},
    {'name': 'تقنية', 'icon': Icons.computer, 'color': Colors.teal},
    {'name': 'أخرى', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
    _loadUserPhone();
  }

  Future<void> _loadUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('user_phone');
    if (phone != null) {
      setState(() => _whatsappController.text = phone);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _businessNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickLicenseImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() => _licenseImage = File(image.path));
      }
    } catch (e) {
      _showErrorDialog('خطأ في اختيار الصورة: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoading = true);
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('خدمة الموقع معطلة');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('تم رفض إذن الموقع');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('إذن الموقع مرفوض بشكل دائم');
      }

      _currentPosition = await Geolocator.getCurrentPosition();
      
      setState(() {
        _locationController.text = 'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, '
            'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم تحديد موقعك بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorDialog('خطأ في تحديد الموقع: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      _showErrorDialog('يرجى اختيار نوع النشاط التجاري');
      return;
    }

    if (_hasCommercialLicense && _licenseImage == null) {
      _showErrorDialog('يرجى إرفاق صورة السجل التجاري');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = SecureApiService();
      
      // Prepare request data
      final requestData = {
        'business_name': _businessNameController.text.trim(),
        'business_category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'location_address': _locationController.text.trim(),
        'whatsapp_number': _whatsappController.text.trim(),
        'email': _emailController.text.trim(),
        'has_commercial_license': _hasCommercialLicense,
        'license_number': _hasCommercialLicense ? _licenseNumberController.text.trim() : null,
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
      };

      // TODO: Handle image upload if needed
      
      final response = await api.post('/api/request-provider', requestData, requireAuth: true);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'فشل إرسال الطلب');
      }
    } catch (e) {
      _showErrorDialog('خطأ في إرسال الطلب: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: Colors.green, size: 60),
            ),
            const SizedBox(height: 16),
            Text(
              'تم إرسال الطلب بنجاح! 🎉',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'تم استلام طلبك لتصبح مقدم خدمة.\n\nسيتم مراجعة طلبك من قبل فريق الإدارة خلال 24-48 ساعة، وسيتم إشعارك بالنتيجة عبر الواتساب والإيميل.',
          style: GoogleFonts.cairo(),
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Go back with success result
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('حسناً', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خطأ'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('طلب أن تصبح مقدم خدمة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF6B6B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Section
                  _buildHeroSection(),
                  const SizedBox(height: 30),
                  
                  // Category Selection
                  _buildCategorySelection(),
                  const SizedBox(height: 20),
                  
                  // Business Info Card
                  _buildBusinessInfoCard(),
                  const SizedBox(height: 20),
                  
                  // Location Card
                  _buildLocationCard(),
                  const SizedBox(height: 20),
                  
                  // Contact Info Card
                  _buildContactInfoCard(),
                  const SizedBox(height: 20),
                  
                  // License Card
                  _buildLicenseCard(),
                  const SizedBox(height: 30),
                  
                  // Submit Button
                  _buildSubmitButton(),
                  const SizedBox(height: 20),
                  
                  // Terms Text
                  _buildTermsText(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFE85454)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.storefront, size: 60, color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'انضم لشبكة مقدمي الخدمات',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'قدّم خدماتك لآلاف العملاء وزد من دخلك',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اختر نوع النشاط التجاري *',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['name'];
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category['name']),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (category['color'] as Color).withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? (category['color'] as Color)
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category['icon'],
                          size: 32,
                          color: isSelected
                              ? (category['color'] as Color)
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          category['name'],
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.black : Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'معلومات النشاط التجاري',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF6B6B),
              ),
            ),
            const SizedBox(height: 20),
            
            _buildTextField(
              controller: _businessNameController,
              label: 'اسم النشاط التجاري',
              hint: 'مثال: مطعم الذواقة',
              icon: Icons.business,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'اسم النشاط مطلوب';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _descriptionController,
              label: 'وصف النشاط',
              hint: 'اكتب وصفاً مختصراً عن خدماتك...',
              icon: Icons.description,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'وصف النشاط مطلوب';
                }
                if (value.trim().length < 20) {
                  return 'الوصف قصير جداً (20 حرف على الأقل)';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الموقع',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF6B6B),
              ),
            ),
            const SizedBox(height: 20),
            
            _buildTextField(
              controller: _locationController,
              label: 'العنوان',
              hint: 'اكتب عنوان نشاطك التجاري',
              icon: Icons.location_on,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'العنوان مطلوب';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _getCurrentLocation,
              icon: Icon(Icons.my_location, color: const Color(0xFFFF6B6B)),
              label: Text(
                'تحديد موقعي الحالي',
                style: GoogleFonts.cairo(color: const Color(0xFFFF6B6B)),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: const Color(0xFFFF6B6B)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'معلومات التواصل',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF6B6B),
              ),
            ),
            const SizedBox(height: 20),
            
            _buildTextField(
              controller: _whatsappController,
              label: 'رقم الواتساب',
              hint: '05xxxxxxxx',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'رقم الواتساب مطلوب';
                }
                if (!RegExp(r'^05\d{8}$').hasMatch(value.trim())) {
                  return 'رقم الواتساب غير صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _emailController,
              label: 'البريد الإلكتروني (اختياري)',
              hint: 'example@email.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_user, color: Colors.blue, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'السجل التجاري (اختياري)',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'إذا كان لديك سجل تجاري، سيعطيك أولوية في الظهور',
              style: GoogleFonts.cairo(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              value: _hasCommercialLicense,
              onChanged: (value) => setState(() => _hasCommercialLicense = value),
              title: Text('لدي سجل تجاري', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              activeColor: Colors.blue,
              contentPadding: EdgeInsets.zero,
            ),
            
            if (_hasCommercialLicense) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _licenseNumberController,
                label: 'رقم السجل التجاري',
                hint: '1234567890',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              if (_licenseImage != null) ...[
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _licenseImage!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                      onPressed: () => setState(() => _licenseImage = null),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              
              OutlinedButton.icon(
                onPressed: _pickLicenseImage,
                icon: Icon(Icons.upload_file, color: Colors.blue),
                label: Text(
                  _licenseImage == null ? 'إرفاق صورة السجل التجاري' : 'تغيير الصورة',
                  style: GoogleFonts.cairo(color: Colors.blue),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.cairo(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFFFF6B6B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        labelStyle: GoogleFonts.cairo(),
        hintStyle: GoogleFonts.cairo(color: Colors.grey.shade400),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitRequest,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF6B6B),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : Text(
              'إرسال الطلب',
              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildTermsText() {
    return Text(
      'بإرسال هذا الطلب، أنت توافق على شروط وأحكام المنصة وسياسة الخصوصية',
      style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600),
      textAlign: TextAlign.center,
    );
  }
}

