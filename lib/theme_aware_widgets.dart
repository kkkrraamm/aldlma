import 'package:flutter/material.dart';
import 'theme_config.dart';

/// 🎨 Container يتتبع الألوان تلقائياً
class ThemeAwareContainer extends StatelessWidget {
  final Color? color;
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxDecoration? decoration;
  final double? width;
  final double? height;
  final String debugLabel;

  const ThemeAwareContainer({
    super.key,
    this.color,
    this.child,
    this.padding,
    this.margin,
    this.decoration,
    this.width,
    this.height,
    this.debugLabel = 'ThemeAwareContainer',
  });

  @override
  Widget build(BuildContext context) {
    // تتبع اللون إذا كان موجوداً
    if (color != null) {
      ThemeConfig.logColorUsage(debugLabel, 'backgroundColor', color!);
    }
    
    // تتبع ألوان الـ decoration
    if (decoration != null && decoration is BoxDecoration) {
      final boxDec = decoration as BoxDecoration;
      if (boxDec.color != null) {
        ThemeConfig.logColorUsage(debugLabel, 'decorationColor', boxDec.color!);
      }
      if (boxDec.border != null && boxDec.border is Border) {
        final border = boxDec.border as Border;
        if (border.top.color != Colors.transparent) {
          ThemeConfig.logColorUsage(debugLabel, 'borderColor', border.top.color);
        }
      }
    }

    return Container(
      color: color,
      padding: padding,
      margin: margin,
      decoration: decoration,
      width: width,
      height: height,
      child: child,
    );
  }
}

/// 🎨 Text يتتبع الألوان تلقائياً
class ThemeAwareText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String debugLabel;

  const ThemeAwareText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.debugLabel = 'ThemeAwareText',
  });

  @override
  Widget build(BuildContext context) {
    // تتبع لون النص
    if (style?.color != null) {
      ThemeConfig.logColorUsage(debugLabel, 'textColor', style!.color!);
    }

    return Text(
      data,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// 🔍 Extension لتسهيل التتبع
extension ColorTracking on Color {
  Color track(String widgetName, String colorType) {
    ThemeConfig.logColorUsage(widgetName, colorType, this);
    return this;
  }
}


