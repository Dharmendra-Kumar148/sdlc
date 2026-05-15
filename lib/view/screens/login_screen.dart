import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/logger_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConstants.primaryBlue.withOpacity(0.1),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  const Text("Welcome to\nCreator Engine", style: AppConstants.headingStyle),
                  const SizedBox(height: 12),
                  const Text("Professional tools for modern creators.", style: AppConstants.bodyStyle),
                  const Spacer(),
                  _buildLoginButton(
                    context,
                    label: "Continue with Google",
                    icon: Icons.g_mobiledata,
                    onTap: () => _login(context, "Google"),
                  ),
                  const SizedBox(height: 16),
                  _buildLoginButton(
                    context,
                    label: "Continue with Apple",
                    icon: Icons.apple,
                    onTap: () => _login(context, "Apple"),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, {required String label, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _login(BuildContext context, String provider) async {
    LoggerService.log(LoggerService.auth, "Login attempt via $provider");
    
    // Bypassing real Firebase Auth for now as cloud services are mocked
    LoggerService.success(LoggerService.auth, "Logged in as guest for session.");
    Navigator.pushReplacementNamed(context, '/dashboard');
  }
}
