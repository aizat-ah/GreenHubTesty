import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_models.dart';
import '../../services/admin_service.dart';

class AdminUserFormSheet extends ConsumerStatefulWidget {
  final UserModel? user; // Null if adding, non-null if editing

  const AdminUserFormSheet({super.key, this.user});

  @override
  ConsumerState<AdminUserFormSheet> createState() => _AdminUserFormSheetState();
}

class _AdminUserFormSheetState extends ConsumerState<AdminUserFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  
  UserRole _selectedRole = UserRole.buyer;
  bool _isLoading = false;
  bool _obscurePassword = true;

  

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _phoneController = TextEditingController(text: widget.user?.phone ?? '');
    _passwordController = TextEditingController(text: _isEditing ? '' : 'GreenHub123!');
    _selectedRole = widget.user?.role ?? UserRole.buyer;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(adminServiceProvider);

      if (_isEditing) {
        // Just update role for now, as updating Auth details requires re-authentication or Admin SDK
        await service.updateUserRole(widget.user!.uid, _selectedRole);
      } else {
        await service.addUser(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Role updated successfully' : 'User created successfully'),
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bottom padding for keyboard
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.textLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              Text(
                _isEditing ? 'Edit User Role' : 'Add New User',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                readOnly: _isEditing,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: _isEditing,
                  fillColor: _isEditing ? AppTheme.surfaceDim : null,
                ),
                validator: (val) => val!.isEmpty && !_isEditing ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                readOnly: _isEditing,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: _isEditing,
                  fillColor: _isEditing ? AppTheme.surfaceDim : null,
                ),
                validator: (val) {
                  if (_isEditing) return null;
                  if (val == null || val.isEmpty) return 'Required';
                  if (!val.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                readOnly: _isEditing,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  filled: _isEditing,
                  fillColor: _isEditing ? AppTheme.surfaceDim : null,
                ),
              ),
              const SizedBox(height: 16),

              if (!_isEditing) ...[
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Initial Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.textMid,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              DropdownButtonFormField<UserRole>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'User Role',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(
                      role.name[0].toUpperCase() + role.name.substring(1),
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedRole = val);
                  }
                },
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEditing ? 'Save Changes' : 'Create User'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
