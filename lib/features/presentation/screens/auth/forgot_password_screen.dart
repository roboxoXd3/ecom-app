import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class ForgotPasswordScreen extends StatelessWidget {
  ForgotPasswordScreen({super.key});

  final TextEditingController _emailController = TextEditingController();
  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter your email address to receive a password reset link',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            Obx(
              () => ElevatedButton(
                onPressed:
                    authController.isLoading.value
                        ? null
                        : () {
                          if (_emailController.text.isEmpty) {
                            Get.snackbar(
                              'Error',
                              'Please enter your email',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            return;
                          }
                          authController.forgotPassword(_emailController.text);
                        },
                child:
                    authController.isLoading.value
                        ? const CircularProgressIndicator()
                        : const Text('Send Reset Link'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
