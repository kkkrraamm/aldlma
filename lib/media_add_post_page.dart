// lib/media_add_post_page.dart
// إضافة منشور جديد - نظام احترافي مثل Instagram/TikTok
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
import 'package:video_player/video_player.dart';

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
  final _descriptionController = TextEditingController();
  
  // للصور المتعددة (حتى 5 صور)
  List<File> _selectedImages = [];
  List<String> _uploadedImageUrls = [];
  
  // للفيديو
  File? _selectedVideo;
  String? _uploadedVideoUrl;
  String? _videoThumbnailUrl;
  VideoPlayerController? _videoController;
  
  bool _isUploading = false;
  String _mediaType = 'none'; // none, images, video
  final String _baseUrl = ApiConfig.baseUrl;

  @override
  void dispose() {
    _descriptionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // اختيار صور متعددة (حتى 5)
  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      NotificationsService.instance.toast(
        'الحد الأقصى 5 صور',
        color: Colors.orange,
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage();
    
    if (pickedFiles.isNotEmpty) {
      int remainingSlots = 5 - _selectedImages.length;
      int toAdd = pickedFiles.length > remainingSlots ? remainingSlots : pickedFiles.length;
      
      setState(() {
        for (int i = 0; i < toAdd; i++) {
          _selectedImages.add(File(pickedFiles[i].path));
        }
        _mediaType = 'images';
        // إزالة الفيديو إذا كان موجود
        _selectedVideo = null;
        _uploadedVideoUrl = null;
        _videoThumbnailUrl = null;
        _videoController?.dispose();
        _videoController = null;
      });
      
      if (pickedFiles.length > toAdd) {
        NotificationsService.instance.toast(
          'تم إضافة $toAdd صور فقط (الحد الأقصى 5)',
          color: Colors.orange,
        );
      }
    }
  }

  // اختيار فيديو
  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      File videoFile = File(pickedFile.path);
      
      // التحقق من حجم الفيديو (حد أقصى 50 ميجا)
      int fileSize = await videoFile.length();
      if (fileSize > 50 * 1024 * 1024) {
        NotificationsService.instance.toast(
          'حجم الفيديو كبير جداً (الحد الأقصى 50 ميجا)',
          color: Colors.red,
        );
        return;
      }
      
      setState(() {
        _selectedVideo = videoFile;
        _mediaType = 'video';
        // إزالة الصور إذا كانت موجودة
        _selectedImages.clear();
        _uploadedImageUrls.clear();
        
        // تشغيل الفيديو للمعاينة
        _videoController = VideoPlayerController.file(videoFile)
          ..initialize().then((_) {
            setState(() {});
          });
      });
    }
  }

  // حذف صورة
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (_selectedImages.isEmpty) {
        _mediaType = 'none';
      }
    });
  }

  // حذف الفيديو
  void _removeVideo() {
    setState(() {
      _selectedVideo = null;
      _uploadedVideoUrl = null;
      _videoThumbnailUrl = null;
      _videoController?.dispose();
      _videoController = null;
      _mediaType = 'none';
    });
  }

  // رفع الصور
  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      for (File image in _selectedImages) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/api/media/upload-image'),
        );

        request.headers.addAll({
          'Authorization': 'Bearer $token',
          'X-API-Key': ApiConfig.apiKey,
        });

        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );

        var response = await request.send();
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);

        if (response.statusCode == 200) {
          final data = json.decode(responseString);
          _uploadedImageUrls.add(data['url']);
        } else {
          throw Exception('Failed to upload image');
        }
      }
    } catch (e) {
      NotificationsService.instance.toast('فشل رفع الصور: $e', color: Colors.red);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // رفع الفيديو
  Future<void> _uploadVideo() async {
    if (_selectedVideo == null) return;

    setState(() => _isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/media/upload-video'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'X-API-Key': ApiConfig.apiKey,
      });

      request.files.add(
        await http.MultipartFile.fromPath('video', _selectedVideo!.path),
      );

      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200) {
        final data = json.decode(responseString);
        _uploadedVideoUrl = data['video_url'];
        _videoThumbnailUrl = data['thumbnail_url'];
      } else {
        throw Exception('Failed to upload video');
      }
    } catch (e) {
      NotificationsService.instance.toast('فشل رفع الفيديو: $e', color: Colors.red);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // نشر المنشور
  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    if (_mediaType == 'none') {
      NotificationsService.instance.toast(
        'الرجاء إضافة صور أو فيديو',
        color: Colors.orange,
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // رفع الملفات أولاً
      if (_mediaType == 'images') {
        await _uploadImages();
      } else if (_mediaType == 'video') {
        await _uploadVideo();
      }

      // إنشاء المنشور
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final body = {
        'description': _descriptionController.text.trim(),
      };

      if (_mediaType == 'images') {
        body['media_urls'] = _uploadedImageUrls;
      } else if (_mediaType == 'video') {
        body['video_url'] = _uploadedVideoUrl;
        body['video_thumbnail'] = _videoThumbnailUrl;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/media/posts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-API-Key': ApiConfig.apiKey,
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        NotificationsService.instance.toast('تم نشر المنشور بنجاح! 🎉', color: Colors.green);
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to create post: ${response.body}');
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
        backgroundColor: isDark ? ThemeConfig.kNightDeep : primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'إضافة منشور جديد',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isUploading)
            TextButton(
              onPressed: _submitPost,
              child: Text(
                'نشر',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
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
                  // اختيار نوع الوسائط
                  _buildMediaTypeSelector(theme, isDark, primaryColor),
                  const SizedBox(height: 20),
                  
                  // عرض الوسائط المختارة
                  if (_mediaType == 'images')
                    _buildImagesPreview(theme, isDark, primaryColor),
                  
                  if (_mediaType == 'video')
                    _buildVideoPreview(theme, isDark, primaryColor),
                  
                  if (_mediaType != 'none')
                    const SizedBox(height: 20),
                  
                  // الوصف
                  _buildDescriptionField(theme, isDark, primaryColor),
                  const SizedBox(height: 20),
                  
                  // نصائح
                  _buildTips(theme, isDark, primaryColor),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          
          // مؤشر التحميل
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'جاري النشر...',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaTypeSelector(ThemeConfig theme, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? ThemeConfig.kNightAccent : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختر نوع المحتوى',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMediaButton(
                  icon: Icons.photo_library_rounded,
                  label: 'صور',
                  subtitle: 'حتى 5 صور',
                  onTap: _pickImages,
                  theme: theme,
                  isDark: isDark,
                  primaryColor: primaryColor,
                  isSelected: _mediaType == 'images',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMediaButton(
                  icon: Icons.videocam_rounded,
                  label: 'فيديو',
                  subtitle: 'TikTok/Reels',
                  onTap: _pickVideo,
                  theme: theme,
                  isDark: isDark,
                  primaryColor: primaryColor,
                  isSelected: _mediaType == 'video',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeConfig theme,
    required bool isDark,
    required Color primaryColor,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? primaryColor.withOpacity(0.1) 
              : (isDark ? ThemeConfig.kNightAccent : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? primaryColor : theme.textSecondaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? primaryColor : theme.textPrimaryColor,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: theme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesPreview(ThemeConfig theme, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? ThemeConfig.kNightAccent : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الصور المختارة (${_selectedImages.length}/5)',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimaryColor,
                ),
              ),
              if (_selectedImages.length < 5)
                TextButton.icon(
                  onPressed: _pickImages,
                  icon: Icon(Icons.add_photo_alternate, size: 18),
                  label: Text('إضافة', style: GoogleFonts.cairo(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedImages.asMap().entries.map((entry) {
              int index = entry.key;
              File image = entry.value;
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      image,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview(ThemeConfig theme, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? ThemeConfig.kNightAccent : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الفيديو المختار',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimaryColor,
                ),
              ),
              IconButton(
                onPressed: _removeVideo,
                icon: Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'حذف',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_videoController != null && _videoController!.value.isInitialized)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField(ThemeConfig theme, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? ThemeConfig.kNightAccent : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الوصف',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            maxLines: 6,
            style: GoogleFonts.cairo(color: theme.textPrimaryColor),
            decoration: InputDecoration(
              hintText: 'اكتب وصف المنشور... يمكنك إضافة #هاشتاق أو @منشن',
              hintStyle: GoogleFonts.cairo(color: theme.textSecondaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? ThemeConfig.kNightAccent : Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? ThemeConfig.kNightAccent : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              filled: true,
              fillColor: isDark ? ThemeConfig.kNightSoft : Colors.grey.shade50,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'الرجاء كتابة وصف للمنشور';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTips(ThemeConfig theme, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'نصائح',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTip('• يمكنك رفع حتى 5 صور أو فيديو واحد', theme),
          _buildTip('• استخدم #هاشتاق للمواضيع', theme),
          _buildTip('• استخدم @username لمنشن شخص', theme),
          _buildTip('• حجم الفيديو: حد أقصى 50 ميجا', theme),
        ],
      ),
    );
  }

  Widget _buildTip(String text, ThemeConfig theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          fontSize: 12,
          color: theme.textSecondaryColor,
        ),
      ),
    );
  }
}
