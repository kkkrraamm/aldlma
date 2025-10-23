// فئة العنوان المشتركة
class DeliveryAddress {
  final int id;
  final String name;
  final String fullAddress;
  final double latitude;
  final double longitude;
  bool isDefault;
  final String additionalInfo;
  
  DeliveryAddress({
    required this.id,
    required this.name,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    required this.additionalInfo,
  });
}
