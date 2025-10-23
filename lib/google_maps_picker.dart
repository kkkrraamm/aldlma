import 'package:flutter/material.dart';
import 'theme_config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models.dart';

class GoogleMapsAddressPicker extends StatefulWidget {
  final DeliveryAddress? existingAddress;
  final Function(DeliveryAddress) onAddressSelected;
  
  const GoogleMapsAddressPicker({
    Key? key,
    this.existingAddress,
    required this.onAddressSelected,
  }) : super(key: key);
  
  @override
  _GoogleMapsAddressPickerState createState() => _GoogleMapsAddressPickerState();
}

class _GoogleMapsAddressPickerState extends State<GoogleMapsAddressPicker> {
  final _nameController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  
  // إحداثيات مختارة (افتراضياً عرعر)
  double _selectedLat = 30.9753;
  double _selectedLng = 41.0164;
  String _selectedAddress = 'عرعر، المملكة العربية السعودية';
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingAddress != null) {
      _nameController.text = widget.existingAddress!.name;
      _additionalInfoController.text = widget.existingAddress!.additionalInfo;
      _selectedLat = widget.existingAddress!.latitude;
      _selectedLng = widget.existingAddress!.longitude;
      _selectedAddress = widget.existingAddress!.fullAddress;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F9ED),
      body: Column(
        children: [
          // الخريطة
          Expanded(
            flex: 2,
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // محاكاة خريطة مع رابط لخرائط جوجل
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFE8F5E8),
                            Color(0xFFF0F9FF),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // شوارع وهمية
                          Positioned(
                            top: 50,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 2,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          Positioned(
                            top: 100,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 2,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            bottom: 0,
                            left: 100,
                            child: Container(
                              width: 2,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          
                          // المؤشر
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'انقر لفتح خرائط جوجل',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // طبقة شفافة للنقر
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _openGoogleMaps,
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                    
                    // أزرار التحكم
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Column(
                        children: [
                          // زر الموقع الحالي
                          FloatingActionButton.small(
                            heroTag: "current_location",
                            onPressed: _getCurrentLocation,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.my_location,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          SizedBox(height: 8),
                          
                          // زر التكبير
                          FloatingActionButton.small(
                            heroTag: "zoom_in",
                            onPressed: _zoomIn,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.zoom_in,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 4),
                          
                          // زر التصغير
                          FloatingActionButton.small(
                            heroTag: "zoom_out",
                            onPressed: _zoomOut,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.zoom_out,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // مؤشر التحميل
                    if (_isLoadingAddress)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF10B981),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'جاري تحديد العنوان...',
                                style: GoogleFonts.cairo(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // نموذج تفاصيل العنوان
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // مقبض السحب
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // العنوان المحدد
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedAddress,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // اسم العنوان
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'اسم العنوان',
                      labelStyle: GoogleFonts.cairo(),
                      hintText: 'مثل: المنزل، العمل، الجامعة',
                      prefixIcon: Icon(Icons.label, color: Color(0xFF10B981)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF10B981), width: 2),
                      ),
                    ),
                    style: GoogleFonts.cairo(),
                  ),
                  SizedBox(height: 12),
                  
                  // معلومات إضافية
                  TextField(
                    controller: _additionalInfoController,
                    decoration: InputDecoration(
                      labelText: 'معلومات إضافية (اختياري)',
                      labelStyle: GoogleFonts.cairo(),
                      hintText: 'مثل: الطابق، رقم الشقة، نقطة مرجعية',
                      prefixIcon: Icon(Icons.info, color: Color(0xFF10B981)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF10B981), width: 2),
                      ),
                    ),
                    style: GoogleFonts.cairo(),
                    maxLines: 2,
                  ),
                  
                  Spacer(),
                  
                  // زر الحفظ
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.existingAddress != null ? 'تحديث العنوان' : 'حفظ العنوان',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  void _openGoogleMaps() async {
    final url = 'https://www.google.com/maps/@$_selectedLat,$_selectedLng,15z';
    
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لا يمكن فتح خرائط جوجل',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في فتح الخرائط',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateSelectedLocation(double lat, double lng) async {
    setState(() {
      _selectedLat = lat;
      _selectedLng = lng;
      _isLoadingAddress = true;
    });

    // محاكاة تحديث العنوان
    await Future.delayed(Duration(milliseconds: 500));
    setState(() {
      _selectedAddress = 'الموقع المحدد - عرعر، المملكة العربية السعودية';
      _isLoadingAddress = false;
    });
  }

  // تم تبسيط النظام

  void _getCurrentLocation() async {
    // محاكاة الحصول على الموقع الحالي
    setState(() {
      _selectedLat = 30.9753;
      _selectedLng = 41.0164;
      _selectedAddress = 'موقعك الحالي - عرعر، المملكة العربية السعودية';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم تحديد موقعك الحالي',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _zoomIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('انقر على الخريطة لفتح خرائط جوجل', style: GoogleFonts.cairo()),
        duration: Duration(milliseconds: 1000),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _zoomOut() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('انقر على الخريطة لفتح خرائط جوجل', style: GoogleFonts.cairo()),
        duration: Duration(milliseconds: 1000),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _saveAddress() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى إدخال اسم العنوان',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newAddress = DeliveryAddress(
      id: widget.existingAddress?.id ?? DateTime.now().millisecondsSinceEpoch,
      name: _nameController.text.trim(),
      fullAddress: _selectedAddress,
      latitude: _selectedLat,
      longitude: _selectedLng,
      isDefault: widget.existingAddress?.isDefault ?? false,
      additionalInfo: _additionalInfoController.text.trim(),
    );

    widget.onAddressSelected(newAddress);
    Navigator.pop(context);
  }
}

// صفحة عرض العنوان على الخريطة
class MapViewPage extends StatefulWidget {
  final DeliveryAddress address;
  
  const MapViewPage({Key? key, required this.address}) : super(key: key);
  
  @override
  _MapViewPageState createState() => _MapViewPageState();
}

class _MapViewPageState extends State<MapViewPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F9ED),
      appBar: AppBar(
        title: Text(
          widget.address.name,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _openInGoogleMaps,
            icon: Icon(Icons.open_in_new),
            tooltip: 'فتح في خرائط جوجل',
          ),
        ],
      ),
      body: Stack(
        children: [
          // محاكاة خريطة مع الموقع
          GestureDetector(
            onTap: _openInGoogleMaps,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE8F5E8),
                    Color(0xFFF0F9FF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // المؤشر
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            'انقر لفتح في خرائط جوجل',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // معلومات العنوان
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.address.name,
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.address.fullAddress,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (widget.address.additionalInfo.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      widget.address.additionalInfo,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openInGoogleMaps,
                          icon: Icon(Icons.map),
                          label: Text(
                            'فتح في خرائط جوجل',
                            style: GoogleFonts.cairo(),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Color(0xFF10B981)),
                            foregroundColor: Color(0xFF10B981),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context, widget.address);
                          },
                          icon: Icon(Icons.check),
                          label: Text(
                            'اختيار العنوان',
                            style: GoogleFonts.cairo(),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF10B981),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openInGoogleMaps() async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${widget.address.latitude},${widget.address.longitude}';
    
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم فتح الموقع في خرائط جوجل',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لا يمكن فتح خرائط جوجل',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في فتح الخرائط',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
