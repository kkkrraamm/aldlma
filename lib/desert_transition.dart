import 'package:flutter/material.dart';

class DesertWindTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const DesertWindTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // الصفحة الجديدة مع انزلاق ناعم
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
        
        // تأثير الغبار الصحراوي البسيط
        ...List.generate(12, (index) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final progress = animation.value;
              final screenWidth = MediaQuery.of(context).size.width;
              final screenHeight = MediaQuery.of(context).size.height;
              
              return Positioned(
                left: (index * 60.0 + progress * screenWidth) % screenWidth,
                top: (index * 40.0 + progress * 50) % screenHeight,
                child: Opacity(
                  opacity: (1.0 - progress) * 0.4,
                  child: Transform.rotate(
                    angle: progress * 2 + index,
                    child: Container(
                      width: 8 + (index % 3) * 2,
                      height: 8 + (index % 3) * 2,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4B895).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.brown.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
        
        // ضباب صحراوي خفيف
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        const Color(0xFFF5DEB3).withOpacity(0.2 * animation.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
