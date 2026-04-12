import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_models.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import 'package:intl/intl.dart';
import 'admin_user_form_sheet.dart';

enum _UserFilter { all, buyer, supplier, admin }

class AdminUserManagement extends ConsumerStatefulWidget {
  const AdminUserManagement({super.key});

  @override
  ConsumerState<AdminUserManagement> createState() =>
      _AdminUserManagementState();
}

class _AdminUserManagementState extends ConsumerState<AdminUserManagement> {
  final TextEditingController _searchController = TextEditingController();
  _UserFilter _currentFilter = _UserFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                final filtered = _filterUsers(users);
                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildUserTile(filtered[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error loading users: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openUserForm(),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: Icon(Icons.search),
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChip(_UserFilter.all, 'All'),
                const SizedBox(width: 8),
                _buildChip(_UserFilter.buyer, 'Buyer'),
                const SizedBox(width: 8),
                _buildChip(_UserFilter.supplier, 'Supplier'),
                const SizedBox(width: 8),
                _buildChip(_UserFilter.admin, 'Admin'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(_UserFilter filter, String label) {
    final isSelected = _currentFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _currentFilter = filter),
      backgroundColor: AppTheme.surfaceDim,
      selectedColor: AppTheme.primary.withOpacity(0.15),
      labelStyle: GoogleFonts.inter(
        color: isSelected ? AppTheme.primaryDark : AppTheme.textMid,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }

  List<UserModel> _filterUsers(List<UserModel> allUsers) {
    final query = _searchController.text.toLowerCase();
    return allUsers.where((user) {
      final matchesSearch = user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
      
      final matchesRole = _currentFilter == _UserFilter.all ||
          (_currentFilter == _UserFilter.buyer && user.role == UserRole.buyer) ||
          (_currentFilter == _UserFilter.supplier && user.role == UserRole.supplier) ||
          (_currentFilter == _UserFilter.admin && user.role == UserRole.admin);

      return matchesSearch && matchesRole;
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No users found matching filters.',
        style: GoogleFonts.inter(
          color: AppTheme.textMid,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildUserTile(UserModel user) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openUserForm(user: user),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
                radius: 24,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: GoogleFonts.poppins(
                    color: _getRoleColor(user.role),
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildRoleBadge(user.role),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textMid,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Joined ${dateFormat.format(user.createdAt)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                onPressed: () => _confirmDeleteOrRemove(user),
                tooltip: 'Delete User',
              )
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.buyer:
        return AppTheme.success;
      case UserRole.supplier:
        return AppTheme.accent;
      case UserRole.admin:
        return AppTheme.error;
    }
  }

  Widget _buildRoleBadge(UserRole role) {
    final color = _getRoleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role.name.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  void _openUserForm({UserModel? user}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AdminUserFormSheet(user: user),
    );
  }

  Future<void> _confirmDeleteOrRemove(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}? This will remove their Firestore document.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(adminServiceProvider).deleteUser(user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User document deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting user: $e')),
          );
        }
      }
    }
  }
}
