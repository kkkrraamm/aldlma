import 'package:flutter/material.dart';
import 'theme_config.dart';
import 'package:google_fonts/google_fonts.dart';

class AdvancedBookingCalendar extends StatefulWidget {
  final Function(DateTime selectedDate, String selectedTime) onBookingSelected;
  final int serviceDurationMinutes;

  const AdvancedBookingCalendar({
    Key? key,
    required this.onBookingSelected,
    required this.serviceDurationMinutes,
  }) : super(key: key);

  @override
  _AdvancedBookingCalendarState createState() => _AdvancedBookingCalendarState();
}

class _AdvancedBookingCalendarState extends State<AdvancedBookingCalendar> {
  DateTime _selectedDate = DateTime.now().add(Duration(days: 1));
  String _selectedTime = '';
  
  // الحجوزات الموجودة (بيانات تجريبية)
  final List<Map<String, dynamic>> _existingBookings = [
    {
      'date': DateTime.now().add(Duration(days: 1)),
      'time': '09:15',
    },
    {
      'date': DateTime.now().add(Duration(days: 1)),
      'time': '10:15',
    },
    {
      'date': DateTime.now().add(Duration(days: 1)),
      'time': '14:30',
    },
    {
      'date': DateTime.now().add(Duration(days: 2)),
      'time': '11:00',
    },
  ];

  // توليد أيام الأسبوع
  List<Map<String, dynamic>> get weekDays {
    final now = DateTime.now();
    final days = <Map<String, dynamic>>[];
    
    for (int i = 1; i <= 7; i++) {
      final date = now.add(Duration(days: i));
      final dayNames = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
      final monthNames = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
                         'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
      
      days.add({
        'date': date,
        'dayName': dayNames[date.weekday % 7],
        'dayNumber': date.day,
        'month': monthNames[date.month - 1],
        'available': date.weekday != 5, // الجمعة مغلق
      });
    }
    
    return days;
  }

  // توليد فترات الوقت (فواصل ربع ساعة)
  List<Map<String, dynamic>> get timeSlots {
    final slots = <Map<String, dynamic>>[];
    final startHour = 9;  // 9 صباحاً
    final endHour = 21;   // 9 مساءً
    
    for (int hour = startHour; hour < endHour; hour++) {
      for (int minute = 0; minute < 60; minute += 15) { // فواصل ربع ساعة
        final timeString = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        
        // التحقق من الحجوزات الموجودة
        final isBooked = _existingBookings.any((booking) => 
          _isSameDay(booking['date'], _selectedDate) && 
          booking['time'] == timeString
        );
        
        // تجنب فترة الراحة (1-2 ظهراً)
        final isBreakTime = hour == 13;
        
        slots.add({
          'time': timeString,
          'isBooked': isBooked,
          'available': !isBooked && !isBreakTime,
          'displayTime': _formatTime(hour, minute),
        });
      }
    }
    
    return slots;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'م' : 'ص';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour}:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اختيار التاريخ
          _buildDateSelector(),
          SizedBox(height: 24),
          
          // اختيار الوقت
          _buildTimeSelector(),
          SizedBox(height: 24),
          
          // زر التأكيد
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر التاريخ',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        
        Container(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: weekDays.length,
            itemBuilder: (context, index) {
              final day = weekDays[index];
              final isSelected = _isSameDay(day['date'], _selectedDate);
              
              return Container(
                width: 70,
                margin: EdgeInsets.only(left: 8),
                child: InkWell(
                  onTap: day['available'] ? () {
                    setState(() {
                      _selectedDate = day['date'];
                      _selectedTime = ''; // إعادة تعيين الوقت
                    });
                  } : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: !day['available'] 
                          ? Colors.grey.shade200
                          : isSelected 
                              ? Color(0xFF10B981) 
                              : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? Color(0xFF10B981) 
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day['dayName'],
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: !day['available']
                                ? Colors.grey.shade500
                                : isSelected 
                                    ? Colors.white 
                                    : Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${day['dayNumber']}',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: !day['available']
                                ? Colors.grey.shade500
                                : isSelected 
                                    ? Colors.white 
                                    : Colors.black87,
                          ),
                        ),
                        Text(
                          day['month'],
                          style: GoogleFonts.cairo(
                            fontSize: 8,
                            color: !day['available']
                                ? Colors.grey.shade500
                                : isSelected 
                                    ? Colors.white70 
                                    : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    final slots = timeSlots;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر الوقت',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        
        Container(
          height: 200,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.8,
            ),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              final isSelected = _selectedTime == slot['time'];
              
              return InkWell(
                onTap: slot['available'] ? () {
                  setState(() {
                    _selectedTime = slot['time'];
                  });
                } : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: !slot['available']
                        ? Colors.red.shade50
                        : isSelected
                            ? Color(0xFF10B981)
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: !slot['available']
                          ? Colors.red.shade200
                          : isSelected
                              ? Color(0xFF10B981)
                              : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        slot['displayTime'],
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: !slot['available']
                              ? Colors.red.shade600
                              : isSelected
                                  ? Colors.white
                                  : Colors.black87,
                        ),
                      ),
                      if (slot['isBooked'])
                        Text(
                          'محجوز',
                          style: GoogleFonts.cairo(
                            fontSize: 7,
                            color: Colors.red.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    final canConfirm = _selectedTime.isNotEmpty;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canConfirm ? () {
          widget.onBookingSelected(_selectedDate, _selectedTime);
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF10B981),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: Text(
          canConfirm 
              ? 'تأكيد الموعد - ${_formatSelectedDateTime()}'
              : 'اختر التاريخ والوقت',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  String _formatSelectedDateTime() {
    if (_selectedTime.isEmpty) return '';
    
    final dayNames = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    final dayName = dayNames[_selectedDate.weekday % 7];
    
    final hour = int.parse(_selectedTime.split(':')[0]);
    final minute = int.parse(_selectedTime.split(':')[1]);
    final formattedTime = _formatTime(hour, minute);
    
    return '$dayName ${_selectedDate.day}/${_selectedDate.month} - $formattedTime';
  }
}
