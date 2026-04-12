import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
 
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo / icon
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.eco_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'GreenHub',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fresh from the farm',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}