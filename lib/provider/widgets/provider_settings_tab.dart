// ⚙️ Provider Settings Tab - تبويب الإعدادات

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../provider_models.dart';
import '../provider_api_service.dart';

class ProviderSettingsTab extends StatefulWidget {
  final ProviderProfile profile;
  final DeliveryOptions? deliveryOptions;

  const ProviderSettingsTab({
    Key? key,
    required this.profile,
    this.deliveryOptions,
  }) : super(key: key);

  @override
  State<ProviderSettingsTab> createState() => _ProviderSettingsTabState();
}

class _ProviderSettingsTabState extends State<ProviderSettingsTab> {
  bool _enableCustomDelivery = false;
  final _deliveryFeeController = TextEditingController();
  bool _enablePickup = true;
  bool _jahezEnabled = false;
  final _jahezLinkController = TextEditingController();
  bool _hungerstationEnabled = false;
  final _hungerstationLinkController = TextEditingController();
  bool _talabatEnabled = false;
  final _talabatLinkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.deliveryOptions != null) {
      _enableCustomDelivery = widget.deliveryOptions!.enableCustomDelivery;
      _deliveryFeeController.text = widget.deliveryOptions!.customDeliveryFee.toString();
      _enablePickup = widget.deliveryOptions!.enablePickup;
      _jahezEnabled = widget.deliveryOptions!.jahezEnabled;
      _jahezLinkController.text = widget.deliveryOptions!.jahezLink ?? '';
      _hungerstationEnabled = widget.deliveryOptions!.hungerstationEnabled;
      _hungerstationLinkController.text = widget.deliveryOptions!.hungerstationLink ?? '';
      _talabatEnabled = widget.deliveryOptions!.talabatEnabled;
      _talabatLinkController.text = widget.deliveryOptions!.talabatLink ?? '';
    }
  }

  @override
  void dispose() {
    _deliveryFeeController.dispose();
    _jahezLinkController.dispose();
    _hungerstationLinkController.dispose();
    _talabatLinkController.dispose();
    super.dispose();
  }

  Future<void> _saveDeliveryOptions() async {
    try {
      await ProviderApiService.updateDeliveryOptions({
        'enable_custom_delivery': _enableCustomDelivery,
        'custom_delivery_fee': double.tryParse(_deliveryFeeController.text) ?? 0.0,
        'enable_pickup': _enablePickup,
        'jahez_enabled': _jahezEnabled,
        'jahez_link': _jahezLinkController.text.isEmpty ? null : _jahezLinkController.text,
        'hungerstation_enabled': _hungerstationEnabled,
        'hungerstation_link': _hungerstationLinkController.text.isEmpty 
            ? null 
            : _hungerstationLinkController.text,
        'talabat_enabled': _talabatEnabled,
        'talabat_link': _talabatLinkController.text.isEmpty ? null : _talabatLinkController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم حفظ الإعدادات'),
          backgroundColor: Color(0xFF2D6A4F),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطأ: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // حالة النشاط
          _buildSectionTitle('حالة النشاط'),
          Card(
            child: ListTile(
              leading: Icon(
                widget.profile.isActive ? Icons.check_circle : Icons.cancel,
                color: widget.profile.isActive ? Colors.green : Colors.red,
              ),
              title: Text(widget.profile.isActive ? 'نشط' : 'متوقف'),
              subtitle: Text(
                widget.profile.isActive 
                    ? 'يمكن للعملاء رؤية ملفك والطلب منك' 
                    : 'لا يمكن للعملاء رؤية ملفك',
              ),
              trailing: Switch(
                value: widget.profile.isActive,
                onChanged: (value) {
                  // TODO: تحديث حالة النشاط
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('قريباً: تحديث حالة النشاط')),
                  );
                },
                activeColor: const Color(0xFF2D6A4F),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // خيارات التوصيل
          _buildSectionTitle('خيارات التوصيل'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('توصيل خاص'),
                    subtitle: const Text('تفعيل خدمة التوصيل الخاصة بك'),
                    value: _enableCustomDelivery,
                    onChanged: (value) {
                      setState(() {
                        _enableCustomDelivery = value;
                      });
                    },
                    activeColor: const Color(0xFF2D6A4F),
                  ),
                  if (_enableCustomDelivery)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _deliveryFeeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'رسوم التوصيل',
                          suffixText: 'ر.س',
                        ),
                      ),
                    ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('الاستلام الذاتي'),
                    subtitle: const Text('السماح للعملاء بالاستلام مباشرة'),
                    value: _enablePickup,
                    onChanged: (value) {
                      setState(() {
                        _enablePickup = value;
                      });
                    },
                    activeColor: const Color(0xFF2D6A4F),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // تطبيقات التوصيل
          _buildSectionTitle('تطبيقات التوصيل'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDeliveryAppSwitch(
                    title: 'جاهز',
                    icon: Icons.delivery_dining,
                    value: _jahezEnabled,
                    onChanged: (value) {
                      setState(() {
                        _jahezEnabled = value;
                      });
                    },
                    controller: _jahezLinkController,
                    hint: 'رابط المطعم في جاهز',
                  ),
                  const Divider(),
                  _buildDeliveryAppSwitch(
                    title: 'هنقرستيشن',
                    icon: Icons.fastfood,
                    value: _hungerstationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _hungerstationEnabled = value;
                      });
                    },
                    controller: _hungerstationLinkController,
                    hint: 'رابط المطعم في هنقرستيشن',
                  ),
                  const Divider(),
                  _buildDeliveryAppSwitch(
                    title: 'طلبات',
                    icon: Icons.local_shipping,
                    value: _talabatEnabled,
                    onChanged: (value) {
                      setState(() {
                        _talabatEnabled = value;
                      });
                    },
                    controller: _talabatLinkController,
                    hint: 'رابط المطعم في طلبات',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // زر الحفظ
          ElevatedButton.icon(
            onPressed: _saveDeliveryOptions,
            icon: const Icon(Icons.save),
            label: const Text('حفظ إعدادات التوصيل'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D6A4F),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // الحساب
          _buildSectionTitle('الحساب'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock, color: Colors.orange),
                  title: const Text('تغيير كلمة المرور'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('قريباً: تغيير كلمة المرور')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('تسجيل الخروج'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D6A4F),
        ),
      ),
    );
  }

  Widget _buildDeliveryAppSwitch({
    required String title,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      children: [
        SwitchListTile(
          title: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF2D6A4F),
        ),
        if (value)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: const Icon(Icons.link, size: 20),
              ),
            ),
          ),
      ],
    );
  }
}

