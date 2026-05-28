// lib/features/admin/admin_driver_management.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../models/driver_model.dart';
import '../../providers/driver_provider.dart';
import '../../services/driver_service.dart';

class AdminDriverManagement extends ConsumerStatefulWidget {
  const AdminDriverManagement({super.key});

  @override
  ConsumerState<AdminDriverManagement> createState() =>
      _AdminDriverManagementState();
}

class _AdminDriverManagementState extends ConsumerState<AdminDriverManagement> {
  final TextEditingController _searchController = TextEditingController();
  DriverStatus? _filterStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DriverModel> _filtered(List<DriverModel> drivers) {
    var list = drivers;
    if (_filterStatus != null) {
      list = list.where((d) => d.status == _filterStatus).toList();
    }
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (d) =>
                d.name.toLowerCase().contains(q) ||
                d.phone.contains(q) ||
                d.vehiclePlate.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(allDriversProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Driver Management',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Add Driver',
            onPressed: () => _showDriverForm(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: driversAsync.when(
              data: (drivers) {
                final filtered = _filtered(drivers);
                if (filtered.isEmpty) {
                  return _buildEmpty();
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _buildDriverCard(filtered[i]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by name, phone, plate...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textLight,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.textLight,
                size: 20,
              ),
              filled: true,
              fillColor: AppTheme.surfaceDim,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', null),
                const SizedBox(width: 8),
                _filterChip('Available', DriverStatus.available),
                const SizedBox(width: 8),
                _filterChip('On Delivery', DriverStatus.onDelivery),
                const SizedBox(width: 8),
                _filterChip('Offline', DriverStatus.offline),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, DriverStatus? status) {
    final selected = _filterStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surfaceDim,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textMid,
          ),
        ),
      ),
    );
  }

  Widget _buildDriverCard(DriverModel driver) {
    final statusColor = driver.status == DriverStatus.available
        ? AppTheme.success
        : driver.status == DriverStatus.onDelivery
        ? AppTheme.warning
        : AppTheme.textLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              child: Text(
                driver.name.isNotEmpty ? driver.name[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          driver.name,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${driver.status.emoji} ${driver.status.label}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _infoRow(Icons.phone_outlined, driver.phone),
                  _infoRow(
                    Icons.two_wheeler_outlined,
                    '${driver.vehicleType} · ${driver.vehiclePlate}',
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: AppTheme.textLight,
                size: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (v) => _onMenuAction(v, driver),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'available',
                  child: Text('Set Available'),
                ),
                const PopupMenuItem(
                  value: 'offline',
                  child: Text('Set Offline'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppTheme.textLight),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMid),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _onMenuAction(String action, DriverModel driver) async {
    final service = ref.read(driverServiceProvider);
    switch (action) {
      case 'edit':
        _showDriverForm(context, driver: driver);
        break;
      case 'available':
        await service.updateDriverStatus(driver.uid, DriverStatus.available);
        break;
      case 'offline':
        await service.updateDriverStatus(driver.uid, DriverStatus.offline);
        break;
      case 'delete':
        _confirmDelete(driver);
        break;
    }
  }

  void _confirmDelete(DriverModel driver) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Driver',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Remove ${driver.name} from the system? This cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(driverServiceProvider).deleteDriver(driver.uid);
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Driver removed')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delivery_dining_outlined,
            size: 64,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 12),
          Text(
            'No drivers found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMid,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to add a driver',
            style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  void _showDriverForm(BuildContext context, {DriverModel? driver}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DriverFormSheet(driver: driver),
    );
  }
}

// ── Driver Form Sheet ─────────────────────────────────────────────────────────

class DriverFormSheet extends ConsumerStatefulWidget {
  final DriverModel? driver;
  const DriverFormSheet({super.key, this.driver});

  @override
  ConsumerState<DriverFormSheet> createState() => _DriverFormSheetState();
}

class _DriverFormSheetState extends ConsumerState<DriverFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _password;
  late TextEditingController _plate;
  String _vehicleType = 'Motorcycle';
  bool _isLoading = false;
  bool _obscure = true;

  bool get _isEditing => widget.driver != null;

  final _vehicleTypes = ['Motorcycle', 'Car', 'Van', 'Truck', 'Bicycle'];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.driver?.name ?? '');
    _email = TextEditingController(text: widget.driver?.email ?? '');
    _phone = TextEditingController(text: widget.driver?.phone ?? '');
    _password = TextEditingController(text: _isEditing ? '' : 'GreenHub123!');
    _plate = TextEditingController(text: widget.driver?.vehiclePlate ?? '');
    _vehicleType = widget.driver?.vehicleType ?? 'Motorcycle';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _plate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final service = ref.read(driverServiceProvider);
      if (_isEditing) {
        await service.updateDriver(
          widget.driver!.copyWith(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            vehicleType: _vehicleType,
            vehiclePlate: _plate.text.trim().toUpperCase(),
          ),
        );
      } else {
        await service.addDriver(
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          vehicleType: _vehicleType,
          vehiclePlate: _plate.text.trim().toUpperCase(),
          password: _password.text,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Driver updated successfully'
                  : 'Driver added successfully',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _isEditing ? 'Edit Driver' : 'Add New Driver',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                _field(
                  controller: _name,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),
                if (!_isEditing) ...[
                  _field(
                    controller: _email,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || !v.contains('@')
                        ? 'Enter valid email'
                        : null,
                  ),
                  const SizedBox(height: 14),
                ],
                _field(
                  controller: _phone,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Phone is required' : null,
                ),
                const SizedBox(height: 14),
                // Vehicle Type Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _vehicleType,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Type',
                    prefixIcon: const Icon(
                      Icons.two_wheeler_outlined,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceDim,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _vehicleTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _vehicleType = v ?? 'Motorcycle'),
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _plate,
                  label: 'Vehicle Plate No.',
                  icon: Icons.badge_outlined,
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Plate is required' : null,
                ),
                if (!_isEditing) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceDim,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) =>
                        v != null && v.length < 6 ? 'Min 6 characters' : null,
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _isEditing ? 'Save Changes' : 'Add Driver',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.words,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: AppTheme.surfaceDim,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
