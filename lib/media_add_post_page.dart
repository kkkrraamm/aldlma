// lib/media_add_post_page.dart
// إضافة منشور جديد - تصميم فخم متكامل مع هوية الدلما
// by Abdulkarim ✨

import 'dart:ui';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_config.dart';
import 'notifications.dart';
import 'api_config.dart';

class MediaAddPostPage extends StatefulWidget {
  const MediaAddPostPage({super.key});

  @override
  State<MediaAddPostPage> createState() => _MediaAddPostPageState();
}

class _MediaAddPostPageState extends State<MediaAddPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  final String _baseUrl = ApiConfig.baseUrl;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => _buildImageSourceDialog(),
    );

    if (source == null) return;

    final XFile? pickedFile = await picker.pickImage(source: source);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  Widget _buildImageSourceDialog() {
    final theme = Provider.of<ThemeConfig>(context, listen: false);
    final isDark = theme.isDarkMode;
    final primaryColor = isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen;

    return AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'اختر مصدر الصورة',
        style: GoogleFonts.cairo(
          color: theme.textPrimaryColor,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSourceOption(
            icon: Icons.camera_alt_rounded,
            label: 'الكاميرا',
            color: Colors.blue,
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          const SizedBox(height: 12),
          _buildSourceOption(
            icon: Icons.photo_library_rounded,
            label: 'المعرض',
            color: primaryColor,
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Provider.of<ThemeConfig>(context, listen: false);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: theme.textPrimaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No token found');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/media/upload-image'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['X-API-Key'] = ApiConfig.apiKey;
      request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _uploadedImageUrl = data['imageUrl'];
        });
        NotificationsService.instance.toast('تم رفع الصورة بنجاح! ✅', color: Colors.green);
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      NotificationsService.instance.toast('فشل رفع الصورة: $e', color: Colors.red);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No token found');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/media/posts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-API-Key': ApiConfig.apiKey,
        },
        body: json.encode({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'content': _contentController.text,
          'media': _uploadedImageUrl,
        }),
      );

      if (response.statusCode == 201) {
        NotificationsService.instance.toast('تم نشر المنشور بنجاح! 🎉', color: Colors.green);
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to create post');
      }
    } catch (e) {
      NotificationsService.instance.toast('فشل نشر المنشور: $e', color: Colors.red);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);
    final isDark = theme.isDarkMode;
    final primaryColor = isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'إضافة منشور جديد',
          style: GoogleFonts.cairo(
            color: theme.textPrimaryColor,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // صورة المنشور
                  _buildImageSection(theme, isDark, primaryColor),
                  const SizedBox(height: 20),
                  
                  // العنوان
                  _buildTextField(
                    controller: _titleController,
                    label: 'عنوان المنشور',
                    icon: Icons.title_rounded,
                    hint: 'أدخل عنواناً جذاباً...',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال عنوان المنشور';
                      }
                      return null;
                    },
                    theme: theme,
                    primaryColor: primaryColor,
                  ),
                  const SizedBox(height: 16),
                  
                  // الوصف
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'وصف مختصر',
                    icon: Icons.description_rounded,
                    hint: 'وصف قصير يظهر في البطاقة...',
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال وصف مختصر';
                      }
                      return null;
                    },
                    theme: theme,
                    primaryColor: primaryColor,
                  ),
                  const SizedBox(height: 16),
                  
                  // المحتوى
                  _buildTextField(
                    controller: _contentController,
                    label: 'محتوى المنشور',
                    icon: Icons.article_rounded,
                    hint: 'اكتب محتوى المنشور هنا...',
                    maxLines: 8,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال محتوى المنشور';
                      }
                      return null;
                    },
                    theme: theme,
                    primaryColor: primaryColor,
                  ),
                  const SizedBox(height: 30),
                  
                  // زر النشر
                  _buildSubmitButton(theme, isDark, primaryColor),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          // Loading Overlay
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageSection(ThemeConfig theme, bool isDark, Color primaryColor) {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_selectedImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _selectedImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton.icon(
            onPressed: _isUploading ? null : _pickImage,
            icon: Icon(_selectedImage == null ? Icons.add_photo_alternate_rounded : Icons.edit_rounded),
            label: Text(
              _selectedImage == null ? 'إضافة صورة' : 'تغيير الصورة',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required String? Function(String?) validator,
    required ThemeConfig theme,
    required Color primaryColor,
    int maxLines = 1,
  }) {
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.cairo(
                  color: theme.textPrimaryColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            validator: validator,
            style: GoogleFonts.cairo(
              color: theme.textPrimaryColor,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.cairo(
                color: theme.textSecondaryColor,
                fontSize: 14,
              ),
              filled: true,
              fillColor: theme.backgroundColor.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.borderColor.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.borderColor.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ThemeConfig theme, bool isDark, Color primaryColor) {
    return ElevatedButton.icon(
      onPressed: _isUploading ? null : _submitPost,
      icon: const Icon(Icons.publish_rounded, size: 24),
      label: Text(
        'نشر المنشور',
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        shadowColor: primaryColor.withOpacity(0.5),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 🎨 Glass Card Widget
// ═══════════════════════════════════════════════════════════════

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const _GlassCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.borderColor.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
