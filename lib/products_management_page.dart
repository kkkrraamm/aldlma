// lib/products_management_page.dart
// صفحة إدارة المنتجات الكاملة - Page complète de gestion des produits

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_config.dart';
import 'notifications.dart';
import 'api_config.dart';

class ProductsManagementPage extends StatefulWidget {
  const ProductsManagementPage({super.key});

  @override
  State<ProductsManagementPage> createState() => _ProductsManagementPageState();
}

class _ProductsManagementPageState extends State<ProductsManagementPage> {
  final theme = ThemeConfig.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('authToken');

      // تحميل المنتجات
      final productsResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/provider/products'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      // تحميل التصنيفات
      final categoriesResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/provider/categories'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (productsResponse.statusCode == 200 && categoriesResponse.statusCode == 200) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(
            jsonDecode(productsResponse.body)['data'] ?? [],
          );
          _categories = List<Map<String, dynamic>>.from(
            jsonDecode(categoriesResponse.body)['data'] ?? [],
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      NotificationsService.instance.toast('خطأ في تحميل البيانات');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        title: Text(
          'إدارة المنتجات',
          style: GoogleFonts.cairo(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: theme.textPrimaryColor,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Text(
                  '${_products.length} منتج',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.primaryColor,
              ),
            )
          : Column(
              children: [
                // شريط التصفية والبحث
                _buildFilterBar(),
                
                // قائمة المنتجات
                Expanded(
                  child: _products.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            return _ProductItemCard(
                              product: _products[index],
                              theme: theme,
                              onEdit: () => _showEditProductSheet(_products[index]),
                              onDelete: () => _showDeleteConfirmation(_products[index]),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductSheet(),
        label: Text(
          'إضافة منتج',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: theme.primaryColor,
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: theme.cardColor,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث عن منتج...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.borderColor),
            ),
            child: PopupMenuButton(
              onSelected: (value) {
                NotificationsService.instance.toast('تصفية: $value');
              },
              itemBuilder: (context) => [
                const PopupMenuItem(child: Text('الكل')),
                const PopupMenuItem(child: Text('نشط')),
                const PopupMenuItem(child: Text('غير نشط')),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list_rounded),
                    const SizedBox(width: 4),
                    Text(
                      'التصفية',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: theme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد منتجات',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة منتجات لمتجرك',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: theme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProductSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddProductSheet(
        categories: _categories,
        theme: theme,
        onSave: (product) {
          setState(() => _products.add(product));
          Navigator.pop(context);
          NotificationsService.instance.toast('✅ تم إضافة المنتج بنجاح!');
        },
      ),
    );
  }

  void _showEditProductSheet(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditProductSheet(
        product: product,
        categories: _categories,
        theme: theme,
        onSave: (updatedProduct) {
          final index = _products.indexWhere((p) => p['id'] == product['id']);
          if (index != -1) {
            setState(() => _products[index] = updatedProduct);
          }
          Navigator.pop(context);
          NotificationsService.instance.toast('✅ تم تحديث المنتج!');
        },
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          'حذف المنتج؟',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'هل أنت متأكد من حذف "${product['name']}"؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => _products.removeWhere((p) => p['id'] == product['id']));
              Navigator.pop(context);
              NotificationsService.instance.toast('🗑️ تم حذف المنتج!');
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Product Item Card
// ============================================
class _ProductItemCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final ThemeConfig theme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductItemCard({
    required this.product,
    required this.theme,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // صورة المنتج
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.borderColor),
                      ),
                      child: Icon(
                        Icons.image_rounded,
                        color: theme.textSecondaryColor,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // معلومات المنتج
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'] ?? 'منتج',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: theme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product['category'] ?? 'بدون تصنيف',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: theme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${product['price'] ?? 0} ر.س',
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'المخزون: ${product['stock'] ?? 0}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // الأزرار
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 20),
                          onPressed: onEdit,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
                // خيارات المنتج
                if (product['options'] != null && (product['options'] as List).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الخيارات (${(product['options'] as List).length})',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (product['options'] as List)
                              .take(3)
                              .map((opt) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.backgroundColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${opt['name']}: +${opt['price']} ر.س',
                                      style: GoogleFonts.cairo(fontSize: 11),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// Add Product Sheet
// ============================================
class _AddProductSheet extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final ThemeConfig theme;
  final Function(Map<String, dynamic>) onSave;

  const _AddProductSheet({
    required this.categories,
    required this.theme,
    required this.onSave,
  });

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  String? _selectedCategory;
  List<Map<String, dynamic>> _options = [];
  List<Map<String, dynamic>> _addons = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _priceController = TextEditingController();
    _stockController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس الصفحة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'إضافة منتج جديد',
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: widget.theme.textPrimaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // المعلومات الأساسية
              Text(
                'المعلومات الأساسية',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: widget.theme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),

              // اسم المنتج
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'اسم المنتج',
                  hintText: 'مثال: قهوة إسبريسو',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.shopping_bag_rounded),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),

              // الوصف
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'وصف المنتج',
                  hintText: 'وصف تفصيلي للمنتج...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.description_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // التصنيف
              DropdownButtonFormField(
                value: _selectedCategory,
                items: widget.categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat['id'],
                    child: Text(cat['name'] ?? 'بدون اسم'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                decoration: InputDecoration(
                  labelText: 'التصنيف',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.category_rounded),
                ),
              ),
              const SizedBox(height: 24),

              // السعر والمخزون
              Text(
                'السعر والمخزون',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: widget.theme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'السعر الأساسي',
                        hintText: '0.00',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.attach_money_rounded),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'المخزون',
                        hintText: '0',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.inventory_rounded),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // الخيارات
              _buildOptionsSection(),
              const SizedBox(height: 24),

              // الإضافات
              _buildAddonsSection(),
              const SizedBox(height: 32),

              // أزرار الحفظ
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.theme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _saveProduct,
                      child: Text(
                        'إضافة المنتج',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'خيارات المنتج',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: widget.theme.textPrimaryColor,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showAddOptionDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_options.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.theme.borderColor),
            ),
            child: Center(
              child: Text(
                'لم تضف أي خيارات بعد (مثل: الحجم، اللون)',
                style: GoogleFonts.cairo(
                  color: widget.theme.textSecondaryColor,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _options.length,
            itemBuilder: (context, index) {
              final option = _options[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.theme.borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option['name'] ?? '',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '+${option['price']} ر.س',
                          style: GoogleFonts.cairo(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_rounded, color: Colors.red),
                      onPressed: () => setState(() => _options.removeAt(index)),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAddonsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الإضافات',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: widget.theme.textPrimaryColor,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showAddAddonDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_addons.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.theme.borderColor),
            ),
            child: Center(
              child: Text(
                'لم تضف أي إضافات بعد (مثل: صوص إضافي)',
                style: GoogleFonts.cairo(
                  color: widget.theme.textSecondaryColor,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _addons.length,
            itemBuilder: (context, index) {
              final addon = _addons[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.theme.borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          addon['name'] ?? '',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '+${addon['price']} ر.س',
                          style: GoogleFonts.cairo(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_rounded, color: Colors.red),
                      onPressed: () => setState(() => _addons.removeAt(index)),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _showAddOptionDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        title: Text('إضافة خيار', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'اسم الخيار (مثل: كبير)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'السعر الإضافي',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                setState(() {
                  _options.add({
                    'name': nameCtrl.text,
                    'price': double.parse(priceCtrl.text),
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showAddAddonDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.cardColor,
        title: Text('إضافة إضافة', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'اسم الإضافة',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'السعر',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                setState(() {
                  _addons.add({
                    'name': nameCtrl.text,
                    'price': double.parse(priceCtrl.text),
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _saveProduct() {
    if (_formKey.currentState?.validate() ?? false) {
      final product = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'name': _nameController.text,
        'description': _descController.text,
        'price': double.parse(_priceController.text),
        'stock': int.parse(_stockController.text),
        'category': _selectedCategory,
        'options': _options,
        'addons': _addons,
      };

      widget.onSave(product);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }
}

// ============================================
// Edit Product Sheet
// ============================================
class _EditProductSheet extends StatefulWidget {
  final Map<String, dynamic> product;
  final List<Map<String, dynamic>> categories;
  final ThemeConfig theme;
  final Function(Map<String, dynamic>) onSave;

  const _EditProductSheet({
    required this.product,
    required this.categories,
    required this.theme,
    required this.onSave,
  });

  @override
  State<_EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends State<_EditProductSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  String? _selectedCategory;
  late List<Map<String, dynamic>> _options;
  late List<Map<String, dynamic>> _addons;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product['name']);
    _descController = TextEditingController(text: widget.product['description'] ?? '');
    _priceController = TextEditingController(text: widget.product['price'].toString());
    _stockController = TextEditingController(text: widget.product['stock'].toString());
    _selectedCategory = widget.product['category'];
    _options = List<Map<String, dynamic>>.from(widget.product['options'] ?? []);
    _addons = List<Map<String, dynamic>>.from(widget.product['addons'] ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تعديل المنتج',
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: widget.theme.textPrimaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'اسم المنتج',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'الوصف',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'السعر',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'المخزون',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.theme.primaryColor,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: _saveProduct,
                child: Text(
                  'حفظ التغييرات',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProduct() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedProduct = {
        ...widget.product,
        'name': _nameController.text,
        'description': _descController.text,
        'price': double.parse(_priceController.text),
        'stock': int.parse(_stockController.text),
        'options': _options,
        'addons': _addons,
      };

      widget.onSave(updatedProduct);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }
}
