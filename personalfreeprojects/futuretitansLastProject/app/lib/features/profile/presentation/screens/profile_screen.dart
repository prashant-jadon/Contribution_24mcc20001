import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
               // Avatar
               CircleAvatar(
                 radius: 50,
                 backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.2),
                 backgroundImage: user?.profilePicture != null ? NetworkImage(user!.profilePicture!) : null,
                 child: user?.profilePicture == null
                     ? const Icon(Icons.person, size: 50, color: AppTheme.primaryGold)
                     : null,
               ),
               const SizedBox(height: 16),
               Text(
                 user?.name ?? 'Titan',
                 style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
               ),
               const SizedBox(height: 8),
               Text(
                 user?.email ?? '',
                 style: const TextStyle(color: AppTheme.textSecondary),
               ),
               const SizedBox(height: 24),
               
               // Stats Array
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                 children: [
                   _buildStatColumn('Modules', '0'),
                   _buildDivider(),
                   _buildStatColumn('SSI Score', '${user?.ssiScore ?? 0}'),
                   _buildDivider(),
                   _buildStatColumn('Badges', '0'),
                 ],
               ),
               
               const SizedBox(height: 48),
               
               // Settings List
               _buildSettingsTile(
                 icon: Icons.person_outline,
                 title: 'Edit Profile',
                 onTap: () {
                   context.push('/profile/edit');
                 },
               ),
               _buildSettingsTile(
                 icon: Icons.payment_outlined,
                 title: 'Subscription & Payments', // Razorpay point
                 onTap: () {
                   context.push('/profile/payment');
                 },
                 trailingText: user?.hasPaid == true ? 'Active' : 'Free Plan',
                 trailingColor: user?.hasPaid == true ? Colors.green : AppTheme.primaryGoldDark,
               ),
               _buildSettingsTile(
                 icon: Icons.help_outline,
                 title: 'Help & Support',
                 onTap: () => context.push('/profile/help'),
               ),
               _buildSettingsTile(
                 icon: Icons.logout,
                 title: 'Logout',
                 textColor: Colors.red,
                 onTap: () {
                    ref.read(authControllerProvider.notifier).logout();
                 },
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    String? trailingText,
    Color? trailingColor,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
         padding: const EdgeInsets.all(8),
         decoration: BoxDecoration(
           color: (textColor ?? AppTheme.primaryGold).withValues(alpha: 0.1),
           borderRadius: BorderRadius.circular(10),
         ),
         child: Icon(icon, color: textColor ?? AppTheme.primaryGoldDark, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor ?? AppTheme.textDark,
        ),
      ),
      trailing: trailingText != null 
          ? Text(
              trailingText,
              style: TextStyle(color: trailingColor, fontWeight: FontWeight.bold, fontSize: 12),
            )
          : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }
}
