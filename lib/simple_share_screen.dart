// lib/simple_share_screen.dart
import 'package:flutter/material.dart';
import 'simple_sharing_service.dart';

class SimpleShareScreen extends StatelessWidget {
  const SimpleShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share SmartCall'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1577FE),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 32),
            _buildSharingOptions(context),
            const SizedBox(height: 32),
            _buildCustomShareSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1577FE), Color(0xFF21D4FD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.favorite,
            size: 56,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'Share SmartCall',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Help others stay connected with their loved ones through personalized voice reminders.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSharingOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Share SmartCall',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildShareOption(
          'Share App',
          'Share with friends and family',
          Icons.share,
          Colors.blue,
          () => SimpleSharingService.shareApp(context),
        ),
        const SizedBox(height: 12),
        _buildShareOption(
          'Share with Family',
          'Invite family members to coordinate care',
          Icons.family_restroom,
          Colors.green,
          () => SimpleSharingService.shareWithFamily(context),
        ),
        const SizedBox(height: 12),
        _buildShareOption(
          'Share Success Story',
          'Tell others about your positive experience',
          Icons.star,
          Colors.orange,
          () => _showSuccessStoryDialog(context),
        ),
        const SizedBox(height: 12),
        _buildShareOption(
          'Share with Healthcare Provider',
          'Recommend to your doctor or care team',
          Icons.local_hospital,
          Colors.teal,
          () => SimpleSharingService.shareWithHealthcareProvider(context),
        ),
        const SizedBox(height: 12),
        _buildShareOption(
          'Copy App Link',
          'Get link to share anywhere',
          Icons.link,
          Colors.purple,
          () => SimpleSharingService.copyAppLink(context),
        ),
      ],
    );
  }

  Widget _buildShareOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildCustomShareSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Social Media',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSocialButton(
                'WhatsApp',
                Icons.chat,
                Colors.green,
                () => SimpleSharingService.shareToSocialMedia(context, 'whatsapp'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSocialButton(
                'Facebook',
                Icons.facebook,
                Colors.blue[800]!,
                () => SimpleSharingService.shareToSocialMedia(context, 'facebook'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSocialButton(
                'Twitter',
                Icons.alternate_email,
                Colors.lightBlue,
                () => SimpleSharingService.shareToSocialMedia(context, 'twitter'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSocialButton(
                'More Options',
                Icons.more_horiz,
                Colors.grey[600]!,
                () => SimpleSharingService.shareApp(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  void _showSuccessStoryDialog(BuildContext context) {
    final TextEditingController storyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Your Success Story'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tell others how SmartCall helped your family:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: storyController,
              decoration: const InputDecoration(
                labelText: 'Your story (optional)',
                hintText: 'e.g., "Helped my dad remember his medication every day!"',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              SimpleSharingService.shareSuccessStory(
                context,
                customStory: storyController.text.trim().isEmpty 
                    ? null 
                    : storyController.text.trim(),
              );
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }
}