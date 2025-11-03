// lib/media_edit_post_page.dart
// تعديل منشور - تصميم فخم متكامل مع هوية الدلما
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

class MediaEditPostPage extends StatefulWidget {
  final Map<String, dynamic> post;
  
  const MediaEditPostPage({super.key, required this.post});

  @override
  State<MediaEditPostPage> createState() => _MediaEditPostPageState();
}

class _MediaEditPostPageState extends State<MediaEditPostPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _contentController;
  
  File? _newImage;
  String? _existingImageUrl;
  bool _isUploading = false;
  final String _baseUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post['title']);
    _descriptionController = TextEditingController(text: widget.post['description']);
    _contentController = TextEditingController(text: widget.post['content']);
    _existingImageUrl = widget.post['media'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _newImage = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_newImage == null) return;

    setState(() => _isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) throw Exception('No token found');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/media/upload-image'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['X-API-Key'] = ApiConfig.apiKey;
      request.files.add(await http.MultipartFile.fromPath('image', _newImage!.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _existingImageUrl = data['imageUrl'];
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

  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) throw Exception('No token found');

      final response = await http.put(
        Uri.parse('$_baseUrl/api/media/posts/${widget.post['id']}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-API-Key': ApiConfig.apiKey,
        },
        body: json.encode({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'content': _contentController.text,
          'media': _existingImageUrl,
        }),
      );

      if (response.statusCode == 200) {
        NotificationsService.instance.toast('تم تحديث المنشور بنجاح! 🎉', color: Colors.green);
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to update post');
      }
    } catch (e) {
      NotificationsService.instance.toast('فشل تحديث المنشور: $e', color: Colors.red);
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
          'تعديل المنشور',
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
                  
                  // زر التحديث
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
          if (_newImage != null || _existingImageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _newImage != null
                  ? Image.file(
                      _newImage!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      _existingImageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: primaryColor.withOpacity(0.1),
                        child: Icon(Icons.image_not_supported, color: primaryColor, size: 40),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton.icon(
            onPressed: _isUploading ? null : _pickImage,
            icon: const Icon(Icons.edit_rounded),
            label: Text(
              'تغيير الصورة',
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
      onPressed: _isUploading ? null : _updatePost,
      icon: const Icon(Icons.check_circle_rounded, size: 24),
      label: Text(
        'حفظ التعديلات',
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
