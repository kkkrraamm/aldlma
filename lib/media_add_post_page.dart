import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'theme_config.dart';

/// ➕ صفحة إضافة منشور جديد
class MediaAddPostPage extends StatefulWidget {
  const MediaAddPostPage({Key? key}) : super(key: key);

  @override
  State<MediaAddPostPage> createState() => _MediaAddPostPageState();
}

class _MediaAddPostPageState extends State<MediaAddPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  
  File? _selectedImage;
  bool _isUploading = false;
  final String _baseUrl = 'https://dalma-api.onrender.com';

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
      builder: (context) => AlertDialog(
        title: const Text('اختر مصدر الصورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('الكاميرا'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('المعرض'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ فشل اختيار الصورة: $e')),
      );
    }
  }

  Future<String?> _uploadImageToCloudinary(File image) async {
    try {
      // رفع الصورة باستخدام API التطبيق
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/media/upload-image'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'X-API-Key': 'FKSOE445DF8F44F3BA62C9084DBBC023E3E3F',
      });

      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        return jsonResponse['url'];
      } else {
        print('❌ [UPLOAD] Error: ${response.statusCode} - $responseData');
        return null;
      }
    } catch (e) {
      print('❌ [UPLOAD] Error: $e');
      return null;
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      String? mediaUrl;
      
      // رفع الصورة إذا تم اختيارها
      if (_selectedImage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📤 جارٍ رفع الصورة...')),
        );
        
        mediaUrl = await _uploadImageToCloudinary(_selectedImage!);
        
        if (mediaUrl == null) {
          throw Exception('فشل رفع الصورة');
        }
      }

      // إنشاء المنشور
      final response = await http.post(
        Uri.parse('$_baseUrl/api/media/posts'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-API-Key': 'FKSOE445DF8F44F3BA62C9084DBBC023E3E3F',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'content': _contentController.text.trim(),
          'media_type': mediaUrl != null ? 'image' : 'text',
          'media_url': mediaUrl,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم نشر المنشور بنجاح!')),
        );
        Navigator.pop(context, true); // إرجاع true للإشارة إلى النجاح
      } else {
        throw Exception('فشل نشر المنشور: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ خطأ: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = ThemeConfig.instance;
    final isDarkMode = themeConfig.isDarkMode;
    final primaryColor = themeConfig.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('➕ منشور جديد'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // العنوان
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'العنوان *',
                hintText: 'أدخل عنوان المنشور',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[100],
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'الرجاء إدخال العنوان';
                }
                if (value.trim().length < 5) {
                  return 'العنوان قصير جداً (5 أحرف على الأقل)';
                }
                return null;
              },
              maxLength: 100,
            ),

            const SizedBox(height: 16),

            // الوصف المختصر
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'الوصف المختصر',
                hintText: 'وصف قصير عن المنشور',
                prefixIcon: const Icon(Icons.short_text),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[100],
              ),
              maxLines: 2,
              maxLength: 200,
            ),

            const SizedBox(height: 16),

            // المحتوى
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'المحتوى *',
                hintText: 'اكتب محتوى المنشور هنا...',
                prefixIcon: const Icon(Icons.article),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                alignLabelWithHint: true,
              ),
              maxLines: 10,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'الرجاء إدخال محتوى المنشور';
                }
                if (value.trim().length < 20) {
                  return 'المحتوى قصير جداً (20 حرف على الأقل)';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // قسم الصورة
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (_selectedImage != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.edit),
                          label: const Text('تغيير الصورة'),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() => _selectedImage = null);
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('حذف', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ] else ...[
                    Icon(Icons.image, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    const Text(
                      'إضافة صورة (اختياري)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'الصور تزيد من تفاعل الجمهور',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('اختيار صورة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // زر النشر
            ElevatedButton(
              onPressed: _isUploading ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '📤 نشر المنشور',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),

            const SizedBox(height: 16),

            // ملاحظة
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'سيتم نشر المنشور فوراً وسيكون مرئياً لجميع متابعيك',
                      style: TextStyle(color: Colors.blue[900], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

