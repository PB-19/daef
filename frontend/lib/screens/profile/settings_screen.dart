import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:daef/providers/auth_provider.dart';
import 'package:daef/providers/theme_provider.dart';
import 'package:daef/widgets/custom_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _fullNameCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _notificationsEnabled = true;
  bool _apiKeyObscured = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _fullNameCtrl.text = user.fullName ?? '';
      _notificationsEnabled = user.notificationsEnabled;
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      fullName: _fullNameCtrl.text.trim().isNotEmpty ? _fullNameCtrl.text.trim() : null,
      googleApiKey: _apiKeyCtrl.text.trim().isNotEmpty ? _apiKeyCtrl.text.trim() : null,
      notificationsEnabled: _notificationsEnabled,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Profile updated' : auth.error ?? 'Update failed'),
        backgroundColor: success
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error,
      ),
    );
    if (!success) auth.clearError();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account section
              Text('Account', style: tt.titleSmall?.copyWith(color: cs.primary)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _fullNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _apiKeyCtrl,
                        decoration: InputDecoration(
                          labelText: 'Google API Key',
                          hintText: '••••••••••••',
                          prefixIcon: const Icon(Icons.key_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_apiKeyObscured
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => _apiKeyObscured = !_apiKeyObscured),
                          ),
                        ),
                        obscureText: _apiKeyObscured,
                        validator: (v) {
                          if (v != null && v.isNotEmpty && v.length < 10) {
                            return 'API key seems too short';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Preferences section
              Text('Preferences', style: tt.titleSmall?.copyWith(color: cs.primary)),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(themeProvider.icon),
                      title: const Text('Theme'),
                      subtitle: Text(themeProvider.label),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.read<ThemeProvider>().cycle(),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_outlined),
                      title: const Text('Notifications'),
                      value: _notificationsEnabled,
                      onChanged: (v) => setState(() => _notificationsEnabled = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              PrimaryButton(
                label: 'Save Changes',
                onPressed: auth.loading ? null : _saveProfile,
                loading: auth.loading,
              ),
              const SizedBox(height: 24),

              // Danger zone
              Text('Account Actions', style: tt.titleSmall?.copyWith(color: cs.error)),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: Icon(Icons.logout, color: cs.error),
                  title: Text('Sign Out', style: TextStyle(color: cs.error)),
                  onTap: _logout,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
