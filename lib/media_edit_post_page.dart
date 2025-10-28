import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'theme_config.dart';

/// ✏️ صفحة تعديل منشور موجود
class MediaEditPostPage extends StatefulWidget {
  final Map<String, dynamic> post;
  
  const MediaEditPostPage({Key? key, required this.post}) : super(key: key);

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
  final String _baseUrl = 'https://dalma-api.onrender.com';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.post['description'] ?? '');
    _contentController = TextEditingController(text: widget.post['content'] ?? '');
    _existingImageUrl = widget.post['media_url'];
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
          _newImage = File(image.path);
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
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      String? mediaUrl = _existingImageUrl;
      
      // رفع الصورة الجديدة إذا تم اختيارها
      if (_newImage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📤 جارٍ رفع الصورة...')),
        );
        
        mediaUrl = await _uploadImageToCloudinary(_newImage!);
        
        if (mediaUrl == null) {
          throw Exception('فشل رفع الصورة');
        }
      }

      // تحديث المنشور
      final response = await http.put(
        Uri.parse('$_baseUrl/api/media/posts/${widget.post['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-API-Key': 'FKSOE445DF8F44F3BA62C9084DBBC023E3E3F',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'content': _contentController.text.trim(),
          'media_url': mediaUrl,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم تحديث المنشور بنجاح!')),
        );
        Navigator.pop(context, true); // إرجاع true للإشارة إلى النجاح
      } else {
        throw Exception('فشل تحديث المنشور: ${response.statusCode}');
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
        title: const Text('✏️ تعديل المنشور'),
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
                  if (_newImage != null) ...[
                    // الصورة الجديدة المختارة
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _newImage!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'سيتم استبدال الصورة القديمة بهذه',
                              style: TextStyle(color: Colors.green[900], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.edit),
                          label: const Text('تغيير'),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() => _newImage = null);
                          },
                          icon: const Icon(Icons.cancel, color: Colors.orange),
                          label: const Text('إلغاء', style: TextStyle(color: Colors.orange)),
                        ),
                      ],
                    ),
                  ] else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) ...[
                    // الصورة الحالية
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _existingImageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Center(child: Icon(Icons.broken_image, size: 50)),
                        ),
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
                            setState(() => _existingImageUrl = null);
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('حذف الصورة', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ] else ...[
                    // لا توجد صورة
                    Icon(Icons.image, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    const Text(
                      'لا توجد صورة',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('إضافة صورة'),
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

            // زر الحفظ
            ElevatedButton(
              onPressed: _isUploading ? null : _updatePost,
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
                      '💾 حفظ التعديلات',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

