import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/account_deletion_service.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../auth/login_screen.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  final RxBool _isLoading = false.obs;
  final RxBool _passwordVisible = false.obs;
  final RxBool _understandConsequences = false.obs;
  final RxBool _confirmDataDeletion = false.obs;
  final RxBool _isEligible = true.obs;
  final RxString _eligibilityMessage = ''.obs;

  @override
  void initState() {
    super.initState();
    _checkEligibility();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkEligibility() async {
    _isLoading.value = true;
    
    final result = await AccountDeletionService.checkDeletionEligibility();
    
    _isEligible.value = result.success;
    _eligibilityMessage.value = result.message;
    
    _isLoading.value = false;
  }

  Future<void> _handleDeleteAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_understandConsequences.value || !_confirmDataDeletion.value) {
      SnackbarUtils.showError(
        'Please confirm that you understand the consequences of deleting your account',
      );
      return;
    }

    // Show final confirmation dialog
    final confirmed = await _showFinalConfirmationDialog();
    if (!confirmed) return;

    _isLoading.value = true;

    try {
      // Verify password first
      final passwordValid = await AccountDeletionService.verifyPassword(
        _passwordController.text,
      );

      if (!passwordValid) {
        _isLoading.value = false;
        SnackbarUtils.showError(
          'Incorrect password. Please try again.',
        );
        return;
      }

      // Proceed with deletion
      final result = await AccountDeletionService.deleteAccount(
        _passwordController.text,
      );

      _isLoading.value = false;

      if (result.success) {
        // Show success message
        SnackbarUtils.showSuccess(
          'Your account has been successfully deleted. '
          'All personal information has been removed.',
        );

        // Navigate to login screen after a delay
        await Future.delayed(const Duration(seconds: 2));
        Get.offAll(() => const LoginScreen());
      } else {
        // Handle errors
        if (result.isVendor) {
          _showVendorBlockingDialog(result.message);
        } else {
          SnackbarUtils.showError(
            result.message,
          );
        }
      }
    } catch (e) {
      _isLoading.value = false;
      print('Error during account deletion: $e');
      SnackbarUtils.showError(
        'An unexpected error occurred. Please try again or contact support.',
      );
    }
  }

  Future<bool> _showFinalConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Final Confirmation'),
          ],
        ),
        content: const Text(
          'This action cannot be undone!\n\n'
          'Are you absolutely sure you want to delete your account? '
          'All your personal information will be permanently removed.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Delete My Account'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showVendorBlockingDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.store, color: AppTheme.primaryColor, size: 28),
            SizedBox(width: 12),
            Text('Vendor Account Active'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to vendor support or contact page
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deletionInfo = AccountDeletionService.getDeletionInfo();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Account'),
        backgroundColor: Colors.red.shade50,
        foregroundColor: Colors.red.shade900,
      ),
      body: Obx(() {
        if (_isLoading.value && _eligibilityMessage.value.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning Card
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red.shade700,
                          size: 40,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Warning!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'This action is permanent and cannot be undone.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Eligibility Check
                if (!_isEligible.value) ...[
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade700,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _eligibilityMessage.value,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // What will be deleted
                _buildSectionHeader('What Will Be Deleted'),
                _buildInfoCard(
                  icon: Icons.delete_forever,
                  iconColor: Colors.red,
                  items: deletionInfo['deleted']!,
                ),

                const SizedBox(height: 20),

                // What will be retained
                _buildSectionHeader('What Will Be Retained'),
                _buildInfoCard(
                  icon: Icons.archive,
                  iconColor: Colors.orange,
                  items: deletionInfo['anonymized']!,
                ),

                const SizedBox(height: 24),

                // Confirmation checkboxes
                _buildSectionHeader('Confirmation'),
                Obx(
                  () => CheckboxListTile(
                    title: const Text(
                      'I understand that this action is permanent and cannot be undone',
                    ),
                    value: _understandConsequences.value,
                    onChanged: _isEligible.value
                        ? (value) => _understandConsequences.value = value ?? false
                        : null,
                    activeColor: AppTheme.primaryColor,
                  ),
                ),
                Obx(
                  () => CheckboxListTile(
                    title: const Text(
                      'I confirm that I want to delete all my personal data',
                    ),
                    value: _confirmDataDeletion.value,
                    onChanged: _isEligible.value
                        ? (value) => _confirmDataDeletion.value = value ?? false
                        : null,
                    activeColor: AppTheme.primaryColor,
                  ),
                ),

                const SizedBox(height: 24),

                // Password field
                _buildSectionHeader('Enter Your Password to Confirm'),
                TextFormField(
                  controller: _passwordController,
                  enabled: _isEligible.value,
                  obscureText: !_passwordVisible.value,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: Obx(
                      () => IconButton(
                        icon: Icon(
                          _passwordVisible.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => _passwordVisible.toggle(),
                      ),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Delete button
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading.value || !_isEligible.value
                          ? null
                          : _handleDeleteAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: _isLoading.value
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                          : const Text(
                            'Delete My Account Permanently',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Cancel button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _isLoading.value ? null : () => Get.back(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required List<String> items,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

