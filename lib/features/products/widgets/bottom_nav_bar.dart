import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class BottomNavBar extends StatefulWidget {
  final String currentRoute;

  const BottomNavBar({
    super.key,
    required this.currentRoute,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _animateIcon(int index) {
    _controllers[index].forward(from: 0.0);
  }

  void _navigateTo(String route, int index) {
    _animateIcon(index);
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    const darkGreen = Color(0xFF1B4332); // Darker shade of primary
    const accentGreen = Color(0xFF52B788); // primaryLight for highlights

    return Container(
      decoration: BoxDecoration(
        color: darkGreen,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Home button
              _NavBarItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: widget.currentRoute == '/home',
                onTap: () => _navigateTo('/home', 0),
                controller: _controllers[0],
                activeColor: accentGreen,
              ),

              // Orders button (center)
              _NavBarItem(
                icon: Icons.receipt_long_rounded,
                label: 'Orders',
                isActive: widget.currentRoute == '/orders',
                onTap: () => _navigateTo('/orders', 1),
                controller: _controllers[1],
                activeColor: accentGreen,
              ),

              // Cart button
              _NavBarItem(
                icon: Icons.shopping_basket_rounded,
                label: 'Cart',
                isActive: widget.currentRoute == '/cart',
                onTap: () => _navigateTo('/cart', 2),
                controller: _controllers[2],
                activeColor: accentGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final AnimationController controller;
  final Color activeColor;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.controller,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.15).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeInOutBack),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? activeColor.withOpacity(0.15)
                    : Colors.transparent,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isActive
                    ? activeColor
                    : Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? activeColor
                    : Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
