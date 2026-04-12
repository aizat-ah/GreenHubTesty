import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:greenhub/providers/product_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../services/image_upload_service.dart';

// Common vegetable categories
const _kCategories = [
  'Leafy Greens',
  'Root Vegetables',
  'Gourds & Squash',
  'Beans & Pods',
  'Herbs & Spices',
  'Fruits & Tomatoes',
  'Mushrooms',
  'Others',
];

const _kUnits = ['kg', 'g', 'bunch', 'piece', 'pack', 'bag'];

class ProductFormSheet extends ConsumerStatefulWidget {
  final ProductModel? existingProduct;

  const ProductFormSheet({super.key, this.existingProduct});

  @override
  ConsumerState<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _categoryCtrl;

  String _selectedUnit = 'kg';
  String _selectedCategory = _kCategories.first;
  bool _isAvailable = true;

  File? _pickedImage;
  String? _existingImageUrl;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  final _imageService = ImageUploadService();

  bool get _isEditing => widget.existingProduct != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProduct;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl =
        TextEditingController(text: p != null ? p.price.toString() : '');
    _stockCtrl =
        TextEditingController(text: p != null ? p.stock.toString() : '');
    _categoryCtrl = TextEditingController(text: p?.category ?? '');
    _selectedUnit = p?.unit ?? 'kg';
    _selectedCategory = (p != null && _kCategories.contains(p.category))
        ? p.category
        : _kCategories.first;
    if (p != null && !_kCategories.contains(p.category)) {
      _categoryCtrl.text = p.category;
    }
    _isAvailable = p?.isAvailable ?? true;
    _existingImageUrl = p?.imageUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _imageService.pickImage(source: source);
    if (file != null) setState(() => _pickedImage = file);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String imageUrl = _existingImageUrl ?? '';

      // Upload new image if picked
      if (_pickedImage != null) {
        setState(() => _isUploadingImage = true);
        imageUrl = await _imageService.uploadProductImage(_pickedImage!);
        setState(() => _isUploadingImage = false);
      }

      final category = _selectedCategory == 'Others' &&
              _categoryCtrl.text.trim().isNotEmpty
          ? _categoryCtrl.text.trim()
          : _selectedCategory;

      final productService = ref.read(productServiceProvider);

      if (_isEditing) {
        final updated = widget.existingProduct!.copyWith(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          price: double.parse(_priceCtrl.text.trim()),
          unit: _selectedUnit,
          stock: double.parse(_stockCtrl.text.trim()),
          category: category,
          isAvailable: _isAvailable,
          imageUrl: imageUrl,
        );
        await productService.updateProduct(updated);
      } else {
        final product = ProductModel(
          id: '',
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          price: double.parse(_priceCtrl.text.trim()),
          unit: _selectedUnit,
          stock: double.parse(_stockCtrl.text.trim()),
          category: category,
          imageUrl: imageUrl,
          isAvailable: _isAvailable,
          createdAt: DateTime.now(),
        );
        await productService.addProduct(product);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? '${_nameCtrl.text} updated!'
                : '${_nameCtrl.text} added!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
            child: Row(
              children: [
                Text(
                  _isEditing ? 'Edit Product' : 'Add New Product',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDim,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: AppTheme.textMid),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image picker
                    _ImagePicker(
                      pickedImage: _pickedImage,
                      existingUrl: _existingImageUrl,
                      isUploading: _isUploadingImage,
                      onPickGallery: () => _pickImage(ImageSource.gallery),
                      onPickCamera: () => _pickImage(ImageSource.camera),
                      onRemove: () => setState(() {
                        _pickedImage = null;
                        _existingImageUrl = null;
                      }),
                    ),
                    const SizedBox(height: 22),

                    // Name
                    _label('Product Name *'),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Bayam, Kangkung, Bendi',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Price + Unit row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Price (RM) *'),
                              TextFormField(
                                controller: _priceCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}')),
                                ],
                                decoration: const InputDecoration(
                                    hintText: '0.00',
                                    prefixText: 'RM '),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  if (double.tryParse(v) == null) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Unit *'),
                              DropdownButtonFormField<String>(
                                value: _selectedUnit,
                                decoration: const InputDecoration(),
                                items: _kUnits
                                    .map((u) => DropdownMenuItem(
                                          value: u,
                                          child: Text(u),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedUnit = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stock
                    _label('Stock *'),
                    TextFormField(
                      controller: _stockCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                          hintText: 'e.g. 50',
                          suffixText: _selectedUnit),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Stock is required';
                        }
                        if (double.tryParse(v) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category
                    _label('Category *'),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(),
                      items: _kCategories
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedCategory = v!),
                    ),

                    // Custom category if "Others"
                    if (_selectedCategory == 'Others') ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _categoryCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Enter custom category name',
                        ),
                        validator: (v) {
                          if (_selectedCategory == 'Others' &&
                              (v == null || v.trim().isEmpty)) {
                            return 'Please enter a category name';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Description
                    _label('Description (Optional)'),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      maxLength: 300,
                      decoration: InputDecoration(
                        hintText:
                            'e.g. Fresh local spinach, harvested daily from Cameron Highlands',
                        counterStyle: GoogleFonts.inter(
                            fontSize: 11, color: AppTheme.textLight),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Available toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDim,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.visibility_outlined,
                              size: 18, color: AppTheme.textMid),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Available for sale',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                Text(
                                  'Customers can see and order this product',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppTheme.textLight),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isAvailable,
                            onChanged: (v) =>
                                setState(() => _isAvailable = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Save button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: AppTheme.primary.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isUploadingImage
                                ? 'Uploading image...'
                                : 'Saving...',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _isEditing ? 'Save Changes' : 'Add Product',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textMid,
        ),
      ),
    );
  }
}

// ─── Image picker widget ──────────────────────────────────────────────────────

class _ImagePicker extends StatelessWidget {
  final File? pickedImage;
  final String? existingUrl;
  final bool isUploading;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onRemove;

  const _ImagePicker({
    required this.pickedImage,
    required this.existingUrl,
    required this.isUploading,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onRemove,
  });

  bool get hasImage =>
      pickedImage != null || (existingUrl != null && existingUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Image',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMid,
          ),
        ),
        const SizedBox(height: 8),

        if (hasImage)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: pickedImage != null
                      ? Image.file(pickedImage!, fit: BoxFit.cover)
                      : CachedNetworkImage(
                          imageUrl: existingUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: const Color(0xFFEEF3EC),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _PickerButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: onPickGallery,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PickerButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  onTap: onPickCamera,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDim,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.divider,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primary, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}