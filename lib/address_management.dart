import 'package:flutter/material.dart';
import 'theme_config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models.dart';
import 'google_maps_picker.dart';

class AddressManagement extends StatefulWidget {
  @override
  _AddressManagementState createState() => _AddressManagementState();
}

class _AddressManagementState extends State<AddressManagement> {
  List<DeliveryAddress> _addresses = [
    DeliveryAddress(
      id: 1,
      name: 'المنزل',
      fullAddress: 'حي النزهة، شارع الملك فهد، عرعر',
      latitude: 30.9753,
      longitude: 41.0164,
      isDefault: true,
      additionalInfo: 'بجانب مسجد النور',
    ),
    DeliveryAddress(
      id: 2,
      name: 'العمل',
      fullAddress: 'حي الصناعية، شارع الأمير عبدالله، عرعر',
      latitude: 30.9850,
      longitude: 41.0250,
      isDefault: false,
      additionalInfo: 'مبنى 15، الطابق الثالث',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F9ED),
      appBar: AppBar(
        title: Text(
          'عناوين التوصيل',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // عرض العناوين الحالية
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                return _buildAddressCard(_addresses[index]);
              },
            ),
          ),
          
          // زر إضافة عنوان جديد
          _buildAddNewAddressButton(),
        ],
      ),
    );
  }

  Widget _buildAddressCard(DeliveryAddress address) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // أيقونة نوع العنوان
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getAddressIcon(address.name),
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            address.name,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (address.isDefault) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'افتراضي',
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        address.fullAddress,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (address.additionalInfo.isNotEmpty)
                        Text(
                          address.additionalInfo,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // أزرار الإدارة
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editAddress(address);
                        break;
                      case 'default':
                        _setAsDefault(address.id);
                        break;
                      case 'delete':
                        _deleteAddress(address.id);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('تعديل', style: GoogleFonts.cairo()),
                        ],
                      ),
                    ),
                    if (!address.isDefault)
                      PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 16),
                            SizedBox(width: 8),
                            Text('جعل افتراضي', style: GoogleFonts.cairo()),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('حذف', style: GoogleFonts.cairo(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // أزرار العمليات
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showOnMap(address),
                    icon: Icon(Icons.map, size: 16),
                    label: Text(
                      'عرض على الخريطة',
                      style: GoogleFonts.cairo(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFF10B981)),
                      foregroundColor: Color(0xFF10B981),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectForDelivery(address),
                    icon: Icon(Icons.check, size: 16),
                    label: Text(
                      'اختيار للتوصيل',
                      style: GoogleFonts.cairo(fontSize: 12),
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
    );
  }

  Widget _buildAddNewAddressButton() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: _addNewAddress,
          icon: Icon(Icons.add_location),
          label: Text(
            'إضافة عنوان جديد',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getAddressIcon(String name) {
    switch (name.toLowerCase()) {
      case 'المنزل':
      case 'البيت':
        return Icons.home;
      case 'العمل':
      case 'المكتب':
        return Icons.work;
      case 'الجامعة':
      case 'المدرسة':
        return Icons.school;
      default:
        return Icons.location_on;
    }
  }

  void _addNewAddress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoogleMapsAddressPicker(
          onAddressSelected: (address) {
            setState(() {
              _addresses.add(address);
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'تم إضافة العنوان بنجاح',
                  style: GoogleFonts.cairo(),
                ),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          },
        ),
      ),
    );
  }

  void _editAddress(DeliveryAddress address) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoogleMapsAddressPicker(
          existingAddress: address,
          onAddressSelected: (updatedAddress) {
            setState(() {
              final index = _addresses.indexWhere((a) => a.id == address.id);
              if (index != -1) {
                _addresses[index] = updatedAddress;
              }
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'تم تحديث العنوان بنجاح',
                  style: GoogleFonts.cairo(),
                ),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          },
        ),
      ),
    );
  }

  void _setAsDefault(int addressId) {
    setState(() {
      for (var address in _addresses) {
        address.isDefault = address.id == addressId;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم تعيين العنوان كافتراضي',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _deleteAddress(int addressId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'حذف العنوان',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من حذف هذا العنوان؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _addresses.removeWhere((address) => address.id == addressId);
              });
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم حذف العنوان',
                    style: GoogleFonts.cairo(),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'حذف',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showOnMap(DeliveryAddress address) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapViewPage(address: address),
      ),
    );
  }

  void _selectForDelivery(DeliveryAddress address) {
    Navigator.pop(context, address);
  }
}

// تم نقل DeliveryAddress إلى models.dart
