import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_config.dart';

/// 🔍 أداة فحص الـ Widgets (مثل Developer Tools في المتصفح)
/// الاستخدام: Shift + تحريك الماوس = معاينة | Shift + Click = تحديد
class DalmaWidgetInspector {
  static final DalmaWidgetInspector _instance = DalmaWidgetInspector._internal();
  static DalmaWidgetInspector get instance => _instance;
  DalmaWidgetInspector._internal();

  final ValueNotifier<bool> isShiftPressed = ValueNotifier<bool>(false);
  final ValueNotifier<WidgetInfo?> hoveredWidgetNotifier = ValueNotifier<WidgetInfo?>(null);
  final ValueNotifier<WidgetInfo?> selectedWidgetNotifier = ValueNotifier<WidgetInfo?>(null);

  void handleKeyEvent(KeyEvent event) {
    final wasPressed = isShiftPressed.value;
    
    if (event.logicalKey == LogicalKeyboardKey.shiftLeft || 
        event.logicalKey == LogicalKeyboardKey.shiftRight) {
      isShiftPressed.value = event is KeyDownEvent;
      
      if (!isShiftPressed.value) {
        hoveredWidgetNotifier.value = null; // إخفاء المعاينة عند رفع Shift
      }
      
      if (wasPressed != isShiftPressed.value) {
        print('🔍 [INSPECTOR] Shift ${isShiftPressed.value ? "مضغوط ⬇️" : "محرر ⬆️"} - وضع الفحص ${isShiftPressed.value ? "مفعّل ✅" : "معطّل ❌"}');
      }
    }
  }

  void hoverWidget(BuildContext context, Offset position) {
    if (!isShiftPressed.value) return;
    
    final info = _findWidgetAtPosition(context, position);
    if (info != null) {
      hoveredWidgetNotifier.value = info;
    }
  }

  void selectWidget(BuildContext context, Offset position) {
    if (!isShiftPressed.value) return;

    final info = _findWidgetAtPosition(context, position);
    if (info == null) return;
    
    selectedWidgetNotifier.value = info;
    
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎯 [INSPECTOR] تم اختيار Widget');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📛 الاسم: ${info.widgetName}');
    
    // عرض الوصف إذا كان متوفراً
    if (info.properties['description'] != null) {
      print('🎯 الوصف: ${info.properties['description']}');
    }
    
    // معلومات الموقع في الكود (الأهم!)
    if (info.fullPath != null) {
      print('📂 المسار الكامل: ${info.fullPath}');
    }
    if (info.fileName != null) {
      print('📄 الملف: ${info.fileName}');
    }
    if (info.lineNumber != null) {
      print('📍 السطر: Line ${info.lineNumber}');
      if (info.fullPath != null) {
        print('💡 افتح: ${info.fullPath}:${info.lineNumber}');
      }
    }
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📐 الحجم: ${info.size.width.toStringAsFixed(1)} × ${info.size.height.toStringAsFixed(1)}');
    print('📍 الموقع: (${info.position.dx.toStringAsFixed(1)}, ${info.position.dy.toStringAsFixed(1)})');
    
    if (info.color != null) {
      print('🎨 اللون: ${_colorToString(info.color!)}');
    }
    if (info.textContent != null) {
      print('📝 النص: "${info.textContent}"');
    }
    if (info.properties.isNotEmpty) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('⚙️ خصائص إضافية:');
      info.properties.forEach((key, value) {
        if (value != null) {
          print('   • $key: $value');
        }
      });
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }

  WidgetInfo? _findWidgetAtPosition(BuildContext context, Offset position) {
    try {
      // الحصول على RenderBox الرئيسي
      final RenderBox? rootBox = context.findRenderObject() as RenderBox?;
      if (rootBox == null) return null;

      // تحويل الموقع إلى إحداثيات محلية
      final localPosition = rootBox.globalToLocal(position);

      // إجراء HitTest
      final result = BoxHitTestResult();
      rootBox.hitTest(result, position: localPosition);

      // البحث عن أصغر widget (آخر واحد في القائمة)
      RenderBox? smallestBox;
      Element? smallestElement;
      double smallestArea = double.infinity;

      for (final entry in result.path) {
        if (entry.target is RenderBox) {
          final box = entry.target as RenderBox;
          
          // محاولة الحصول على Element من debugCreator
          Element? element;
          try {
            final creator = box.debugCreator;
            if (creator != null && creator is DebugCreator) {
              element = creator.element;
            }
          } catch (e) {
            continue;
          }
          
          if (element == null) continue;
          
          // تجنب اختيار الـ Inspector نفسه والـ widgets الكبيرة
          final widgetType = element.widget.runtimeType.toString();
          if (widgetType.contains('InspectorOverlay') ||
              widgetType.contains('WidgetInfoCard') ||
              widgetType.contains('ValueListenableBuilder') ||
              widgetType.contains('MouseRegion') ||
              widgetType.contains('GestureDetector') ||
              widgetType.contains('Stack') ||
              widgetType.contains('Scaffold') ||
              widgetType.contains('AnimatedSwitcher')) {
            continue;
          }

          // حساب المساحة
          final area = box.size.width * box.size.height;
          
          // تجاهل الـ widgets الكبيرة جداً (حجم الشاشة تقريباً)
          if (area > 300000) { // أكبر من 300,000 بكسل مربع
            continue;
          }
          
          // اختيار أصغر widget
          if (area > 0 && area < smallestArea) {
            smallestArea = area;
            smallestBox = box;
            smallestElement = element;
          }
        }
      }

      if (smallestBox != null && smallestElement != null) {
        return _extractWidgetInfo(smallestBox, smallestElement);
      }

      return null;
    } catch (e) {
      print('❌ [INSPECTOR] خطأ في البحث: $e');
      return null;
    }
  }

  WidgetInfo _extractWidgetInfo(RenderBox renderBox, Element element) {
    final widget = element.widget;
    final size = renderBox.size;
    final globalPosition = renderBox.localToGlobal(Offset.zero);

    String widgetName = widget.runtimeType.toString();
    Color? color;
    String? textContent;
    Map<String, dynamic> properties = {};
    String? fileName;
    int? lineNumber;
    String? fullPath;

    // استخراج معلومات من شجرة الـ Widgets والتعرف على العنصر
    String? elementDescription;
    try {
      // الحصول على شجرة الـ Widgets من debugCreator
      final creator = renderBox.debugCreator;
      if (creator != null) {
        final creatorString = creator.toString();
        
        // استخراج أسماء الـ Custom Widgets (التي تبدأ بـ _)
        final customWidgets = <String>[];
        final widgetMatches = RegExp(r'_[A-Z][a-zA-Z0-9]+').allMatches(creatorString);
        for (final match in widgetMatches) {
          final widgetName = match.group(0);
          if (widgetName != null && !customWidgets.contains(widgetName)) {
            customWidgets.add(widgetName);
          }
        }
        
        // التعرف على نوع العنصر بناءً على الموقع والحجم والـ Widget tree
        final widgetSize = size.width * size.height;
        final isSmall = widgetSize < 2000; // أصغر من 2000 بكسل مربع
        final isTopLeft = globalPosition.dx < 100 && globalPosition.dy < 150;
        final isTopRight = globalPosition.dx > 300 && globalPosition.dy < 150;
        
        // محاولة التعرف على العنصر
        if (isSmall && isTopLeft && size.width < 50 && size.height < 50) {
          elementDescription = '🔔 زر الإشعارات (أعلى اليسار)';
        } else if (isSmall && isTopRight && size.width < 50 && size.height < 50) {
          elementDescription = '☰ زر القائمة (أعلى اليمين)';
        } else if (creatorString.contains('notification') || creatorString.contains('Notification')) {
          elementDescription = '🔔 عنصر متعلق بالإشعارات';
        } else if (creatorString.contains('Button') || creatorString.contains('button')) {
          elementDescription = '🔘 زر';
        } else if (creatorString.contains('Icon') || widget is Icon) {
          elementDescription = '🎨 أيقونة';
        } else if (creatorString.contains('Image') || widgetName.contains('Image')) {
          elementDescription = '🖼️ صورة';
        } else if (creatorString.contains('Text') || widget is Text) {
          elementDescription = '📝 نص';
        } else if (creatorString.contains('Card')) {
          elementDescription = '🃏 بطاقة';
        } else if (creatorString.contains('Header') || creatorString.contains('Hero')) {
          elementDescription = '📋 رأس الصفحة (Header)';
        }
        
        if (customWidgets.isNotEmpty) {
          // استخدام أول custom widget كمرجع
          final customWidget = customWidgets.first;
          properties['customWidget'] = customWidget;
          
          // تحسين الوصف بناءً على اسم الـ Widget
          if (customWidget.contains('Notification')) {
            elementDescription = '🔔 زر الإشعارات';
          } else if (customWidget.contains('Search')) {
            elementDescription = '🔍 زر البحث';
          } else if (customWidget.contains('Menu')) {
            elementDescription = '☰ زر القائمة';
          } else if (customWidget.contains('Back')) {
            elementDescription = '← زر الرجوع';
          }
          
          // محاولة تخمين الملف بناءً على اسم الـ Widget
          if (customWidget.contains('Hero') || customWidget.contains('Home')) {
            fileName = 'main.dart';
            fullPath = 'lib/main.dart';
          } else if (customWidget.contains('Account') || customWidget.contains('Profile')) {
            fileName = 'my_account_page.dart';
            fullPath = 'lib/my_account_page.dart';
          } else if (customWidget.contains('Trends')) {
            fileName = 'trends_page.dart';
            fullPath = 'lib/trends_page.dart';
          } else if (customWidget.contains('Service')) {
            fileName = 'services_page.dart';
            fullPath = 'lib/services_page.dart';
          } else if (customWidget.contains('Login')) {
            fileName = 'login_page.dart';
            fullPath = 'lib/login_page.dart';
          } else if (customWidget.contains('Signup')) {
            fileName = 'signup_page.dart';
            fullPath = 'lib/signup_page.dart';
          }
          
          properties['widgetTree'] = customWidgets.join(' ← ');
        }
      }
      
      // إضافة الوصف إذا تم التعرف على العنصر
      if (elementDescription != null) {
        properties['description'] = elementDescription;
      }
      
    } catch (e) {
      print('⚠️ [INSPECTOR] خطأ في استخراج معلومات: $e');
    }

    // استخراج معلومات حسب نوع الـ Widget
    if (widget is Container) {
      color = widget.color ?? (widget.decoration as BoxDecoration?)?.color;
      properties['padding'] = widget.padding?.toString();
      properties['margin'] = widget.margin?.toString();
    } else if (widget is Text) {
      textContent = widget.data;
      color = widget.style?.color;
      properties['fontSize'] = widget.style?.fontSize?.toString();
    } else if (widget is Icon) {
      color = widget.color;
      properties['size'] = widget.size?.toString();
      properties['icon'] = widget.icon?.toString();
    } else if (widget is ElevatedButton || widget is TextButton || widget is OutlinedButton) {
      properties['type'] = 'Button';
    }

    return WidgetInfo(
      widgetName: widgetName,
      size: size,
      position: globalPosition,
      color: color,
      textContent: textContent,
      properties: properties,
      fileName: fileName,
      lineNumber: lineNumber,
      fullPath: fullPath,
    );
  }

  WidgetInfo _getWidgetInfo(BuildContext context, Offset position) {
    final widget = context.widget;
    final RenderBox box = context.findRenderObject() as RenderBox;
    final size = box.size;
    final globalPosition = box.localToGlobal(Offset.zero);

    String widgetName = widget.runtimeType.toString();
    Color? color;
    String? textContent;
    Map<String, dynamic> properties = {};
    String? fileName;
    int? lineNumber;

    // محاولة الحصول على معلومات الملف والسطر من StackTrace
    try {
      final stackTrace = StackTrace.current.toString();
      final lines = stackTrace.split('\n');
      for (var line in lines) {
        if (line.contains('.dart:') && !line.contains('widget_inspector.dart')) {
          final match = RegExp(r'([a-z_]+\.dart):(\d+)').firstMatch(line);
          if (match != null) {
            fileName = match.group(1);
            lineNumber = int.tryParse(match.group(2) ?? '');
            break;
          }
        }
      }
    } catch (e) {
      // تجاهل الأخطاء
    }

    // استخراج معلومات حسب نوع الـ Widget
    if (widget is Container) {
      color = widget.color ?? (widget.decoration as BoxDecoration?)?.color;
      properties['padding'] = widget.padding?.toString();
      properties['margin'] = widget.margin?.toString();
      if (widget.decoration != null) {
        properties['decoration'] = widget.decoration.runtimeType.toString();
      }
    } else if (widget is Text) {
      textContent = widget.data;
      color = widget.style?.color;
      properties['fontSize'] = widget.style?.fontSize?.toString();
      properties['fontWeight'] = widget.style?.fontWeight?.toString();
      properties['textAlign'] = widget.textAlign?.toString();
    } else if (widget is Icon) {
      color = widget.color;
      properties['size'] = widget.size?.toString();
      properties['icon'] = widget.icon?.toString();
    } else if (widget is Card) {
      color = widget.color;
      properties['elevation'] = widget.elevation?.toString();
      properties['shape'] = widget.shape?.toString();
    } else if (widget is ElevatedButton || widget is TextButton || widget is OutlinedButton) {
      properties['type'] = 'Button';
    }

    return WidgetInfo(
      widgetName: widgetName,
      size: size,
      position: globalPosition,
      color: color,
      textContent: textContent,
      properties: properties,
      fileName: fileName,
      lineNumber: lineNumber,
    );
  }

  String _colorToString(Color color) {
    return 'Color(0x${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()})';
  }
}

/// 📦 معلومات الـ Widget
class WidgetInfo {
  final String widgetName;
  final Size size;
  final Offset position;
  final Color? color;
  final String? textContent;
  final Map<String, dynamic> properties;
  final String? fileName;
  final int? lineNumber;
  final String? fullPath;

  WidgetInfo({
    required this.widgetName,
    required this.size,
    required this.position,
    this.color,
    this.textContent,
    this.properties = const {},
    this.fileName,
    this.lineNumber,
    this.fullPath,
  });
}

/// 🎯 Widget للتفاعل مع الفحص (Shift + Hover/Click)
class InspectorOverlay extends StatelessWidget {
  final Widget child;

  const InspectorOverlay({super.key, required this.child});

  void _handleTap(BuildContext context, Offset position) {
    DalmaWidgetInspector.instance.selectWidget(context, position);
  }

  void _handleHover(BuildContext context, PointerEvent event) {
    DalmaWidgetInspector.instance.hoverWidget(context, event.position);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DalmaWidgetInspector.instance.isShiftPressed,
      builder: (context, isShiftPressed, _) {
        if (!isShiftPressed) return child;

        return Stack(
          children: [
            // المحتوى الأصلي مع MouseRegion للتفاعل
            MouseRegion(
              onHover: (event) => _handleHover(context, event),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (details) {
                  _handleTap(context, details.globalPosition);
                },
                child: child,
              ),
            ),
            
            // تحديد الـ Widget المعاين (hover)
              ValueListenableBuilder<WidgetInfo?>(
                valueListenable: DalmaWidgetInspector.instance.hoveredWidgetNotifier,
                builder: (context, hoveredInfo, _) {
                  if (hoveredInfo == null) return const SizedBox.shrink();
                  
                  return Positioned(
                    left: hoveredInfo.position.dx,
                    top: hoveredInfo.position.dy,
                    width: hoveredInfo.size.width,
                    height: hoveredInfo.size.height,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                          color: Colors.blue.withOpacity(0.1),
                        ),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            color: Colors.blue,
                            child: Text(
                              hoveredInfo.widgetName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            
            // عرض معلومات الـ Widget المختار (selected)
            ValueListenableBuilder<WidgetInfo?>(
                valueListenable: DalmaWidgetInspector.instance.selectedWidgetNotifier,
                builder: (context, selectedInfo, _) {
                  if (selectedInfo == null) return const SizedBox.shrink();
                  
                  return Stack(
                    children: [
                      // تحديد أحمر للـ Widget المختار
                      Positioned(
                        left: selectedInfo.position.dx,
                        top: selectedInfo.position.dy,
                        width: selectedInfo.size.width,
                        height: selectedInfo.size.height,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.red,
                                width: 3,
                              ),
                              color: Colors.red.withOpacity(0.15),
                            ),
                          ),
                        ),
                      ),
                      
                      // بطاقة المعلومات
                      _WidgetInfoCard(info: selectedInfo),
                    ],
                  );
                },
              ),
            
            // رسالة توجيهية
            Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🔍 وضع الفحص مفعّل | حرّك الماوس للمعاينة | اضغط للتحديد | ارفع Shift للإلغاء',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          );
      },
    );
  }
}

/// ℹ️ بطاقة عرض معلومات الـ Widget المختار
class _WidgetInfoCard extends StatelessWidget {
  final WidgetInfo info;

  const _WidgetInfoCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // العنوان مع زر الإغلاق
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        info.widgetName,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimaryColor,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        DalmaWidgetInspector.instance.selectedWidgetNotifier.value = null;
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.close, color: Colors.grey, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // عرض الوصف إذا كان متوفراً
                if (info.properties['description'] != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.isDarkMode 
                        ? ThemeConfig.kGoldNight.withOpacity(0.15)
                        : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.isDarkMode 
                          ? ThemeConfig.kGoldNight.withOpacity(0.3)
                          : Colors.amber.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '🎯',
                          style: TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            info.properties['description'].toString(),
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.textPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                    // معلومات الملف والسطر
                    if (info.fullPath != null)
                      _InfoRow(
                        icon: Icons.folder_open,
                        label: 'المسار',
                        value: info.fullPath!,
                      ),
                    if (info.fileName != null)
                      _InfoRow(
                        icon: Icons.insert_drive_file,
                        label: 'الملف',
                        value: info.fileName!,
                      ),
                    if (info.lineNumber != null)
                      _InfoRow(
                        icon: Icons.code,
                        label: 'السطر',
                        value: 'Line ${info.lineNumber}',
                      ),
                
                // المعلومات الأساسية
                _InfoRow(
                  icon: Icons.straighten,
                  label: 'الحجم',
                  value: '${info.size.width.toStringAsFixed(1)} × ${info.size.height.toStringAsFixed(1)}',
                ),
                _InfoRow(
                  icon: Icons.location_on,
                  label: 'الموقع',
                  value: '(${info.position.dx.toStringAsFixed(1)}, ${info.position.dy.toStringAsFixed(1)})',
                ),
                
                if (info.color != null)
                  _InfoRow(
                    icon: Icons.palette,
                    label: 'اللون',
                    value: DalmaWidgetInspector.instance._colorToString(info.color!),
                    colorPreview: info.color,
                  ),
                
                if (info.textContent != null)
                  _InfoRow(
                    icon: Icons.text_fields,
                    label: 'النص',
                    value: info.textContent!,
                  ),
                
                // الخصائص الإضافية
                if (info.properties.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'خصائص إضافية:',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...info.properties.entries.where((e) => e.value != null).map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 2),
                      child: Text(
                        '• ${e.key}: ${e.value}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textSecondaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 📝 صف واحد من المعلومات
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? colorPreview;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.colorPreview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: theme.textSecondaryColor),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.textSecondaryColor,
              ),
            ),
          ),
          if (colorPreview != null) ...[
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(right: 6, top: 2),
              decoration: BoxDecoration(
                color: colorPreview,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: theme.borderColor),
              ),
            ),
          ],
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: theme.textPrimaryColor,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
