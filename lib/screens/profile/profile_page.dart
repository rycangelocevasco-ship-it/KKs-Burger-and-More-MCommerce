
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/database_service.dart';
import '../../services/auth_service.dart';

const _profileBrown = Color(0xFF332719);
const _profileYellow = Color(0xFFFFC928);

class ProfilePage extends StatefulWidget {
  final VoidCallback onViewOrders;

  const ProfilePage({
    super.key,
    required this.onViewOrders,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Password controllers
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _profileLoaded = false;
  bool _changingPassword = false;

  // Password visibility
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  String _username = '';

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // LOAD PROFILE
  Future<void> _loadProfile() async {
    final user = _user;

    if (user == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final data =
          await DatabaseService().getUserProfile(user.uid);

      if (!mounted) return;

      _nameController.text =
          data['name']?.toString() ?? user.displayName ?? '';

      _phoneController.text =
          data['phone']?.toString() ?? '';

      _addressController.text =
          data['address']?.toString() ?? '';

      _username =
          data['username']?.toString() ?? '';

      setState(() {
        _profileLoaded = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      _showMessage('Could not load profile: $e');
    }
  }

  // SAVE PROFILE
  Future<void> _saveProfile() async {
    final user = _user;

    if (user == null) return;

    if (_nameController.text.trim().isEmpty) {
      _showMessage('Please enter your full name.');
      return;
    }

    setState(() => _saving = true);

    try {
      final name = _nameController.text.trim();

      await user.updateDisplayName(name);

      await DatabaseService().saveUserProfile(
        userId: user.uid,
        name: name,
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      await user.reload();

      if (!mounted) return;

      setState(() => _saving = false);

      _showMessage('Profile updated successfully!');
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      _showMessage('Could not update profile: $e');
    }
  }

  // CHANGE PASSWORD
  Future<void> _changePassword() async {
    final user = _user;

    if (user == null || user.email == null) {
      _showMessage('Please log in again.');
      return;
    }

    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    _showCurrentPassword = false;
    _showNewPassword = false;
    _showConfirmPassword = false;

    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // CURRENT PASSWORD
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: !_showCurrentPassword,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showCurrentPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _showCurrentPassword =
                                  !_showCurrentPassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // NEW PASSWORD
                    TextField(
                      controller: _newPasswordController,
                      obscureText: !_showNewPassword,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock_reset),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showNewPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _showNewPassword =
                                  !_showNewPassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // CONFIRM NEW PASSWORD
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: const Icon(Icons.lock_reset),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _showConfirmPassword =
                                  !_showConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Update Password'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || confirmed != true) return;

    final currentPassword =
        _currentPasswordController.text;

    final newPassword =
        _newPasswordController.text;

    final confirmPassword =
        _confirmPasswordController.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Please complete all password fields.');
      return;
    }

    if (newPassword.length < 6) {
      _showMessage(
        'New password must be at least 6 characters.',
      );
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage('New passwords do not match.');
      return;
    }

    setState(() => _changingPassword = true);

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPassword);

      if (!mounted) return;

      setState(() => _changingPassword = false);

      _showMessage('Password changed successfully!');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() => _changingPassword = false);

      String message;

      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = 'Your current password is incorrect.';
      } else if (e.code == 'weak-password') {
        message = 'Please use a stronger password.';
      } else if (e.code == 'requires-recent-login') {
        message =
            'Please log in again before changing your password.';
      } else {
        message = e.message ?? 'Password update failed.';
      }

      _showMessage(message);
    } catch (e) {
      if (!mounted) return;

      setState(() => _changingPassword = false);

      _showMessage('Password update failed: $e');
    }
  }

  // SHOW MESSAGE
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // PROFILE OPTION
  Widget _profileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      child: ListTile(
        leading: Icon(
          icon,
          color: _profileBrown,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  // DISPOSE
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();

    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    final user = _user;

    if (user == null) {
      return const Center(
        child: Text('Please log in first.'),
      );
    }

    if (_loading || !_profileLoaded) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // PROFILE HEADER
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _profileYellow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 48,
                  color: _profileBrown,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _nameController.text.isEmpty
                    ? 'Customer'
                    : _nameController.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _profileBrown,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _username.isNotEmpty
                    ? '@$_username'
                    : 'No username',
                style: const TextStyle(
                  color: _profileBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email ?? '',
                style: const TextStyle(
                  color: _profileBrown,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // PERSONAL INFORMATION
        const Text(
          'PERSONAL INFORMATION',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: _profileBrown,
          ),
        ),

        const SizedBox(height: 10),

        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 12),

        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Contact Number',
            hintText: '09XXXXXXXXX',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 12),

        TextField(
          controller: _addressController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Delivery Address',
            hintText:
                'House No., Street, Barangay, City, Province',
            prefixIcon: Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),

        const SizedBox(height: 14),

        // SAVE PROFILE BUTTON
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: _profileYellow,
              foregroundColor: _profileBrown,
              padding: const EdgeInsets.all(15),
            ),
            icon: const Icon(Icons.save),
            label: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'SAVE PROFILE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 26),

        // ACCOUNT SETTINGS
        const Text(
          'ACCOUNT SETTINGS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: _profileBrown,
          ),
        ),

        const SizedBox(height: 10),

        _profileOption(
          icon: Icons.lock_outline,
          title: 'Change Password',
          subtitle: 'Update your account password',
          onTap: _changingPassword
              ? () {}
              : _changePassword,
        ),

        _profileOption(
          icon: Icons.receipt_long_outlined,
          title: 'My Orders',
          subtitle: 'View your previous orders',
          onTap: widget.onViewOrders,
        ),

        _profileOption(
          icon: Icons.logout,
          title: 'Log Out',
          subtitle: 'Sign out of your account',
          onTap: () async {
            await AuthService().signOut();
          },
        ),

        const SizedBox(height: 20),

        const Center(
          child: Text(
            "KK's Burger and More",
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
