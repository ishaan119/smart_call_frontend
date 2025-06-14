// lib/share_button_widget.dart
import 'package:flutter/material.dart';
import 'simple_sharing_service.dart';
import 'simple_share_screen.dart';

class ShareButtonWidget {
  // Simple share button for app bar
  static Widget buildAppBarShareButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.share),
      tooltip: 'Share SmartCall',
      onSelected: (String value) {
        switch (value) {
          case 'share_app':
            SimpleSharingService.shareApp(context);
            break;
          case 'share_family':
            SimpleSharingService.shareWithFamily(context);
            break;
          case 'copy_link':
            SimpleSharingService.copyAppLink(context);
            break;
          case 'more_options':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SimpleShareScreen()),
            );
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'share_app',
          child: ListTile(
            leading: Icon(Icons.share, size: 20),
            title: Text('Share App'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'share_family',
          child: ListTile(
            leading: Icon(Icons.family_restroom, size: 20),
            title: Text('Share with Family'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'copy_link',
          child: ListTile(
            leading: Icon(Icons.link, size: 20),
            title: Text('Copy Link'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'more_options',
          child: ListTile(
            leading: Icon(Icons.more_horiz, size: 20),
            title: Text('More Options'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  // Simple floating action button for sharing
  static Widget buildFloatingShareButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => SimpleSharingService.shareApp(context),
      backgroundColor: Colors.orange,
      icon: const Icon(Icons.share),
      label: const Text('Share'),
    );
  }

  // Quick share card widget
  static Widget buildShareCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1577FE), Color(0xFF21D4FD)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Love SmartCall?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Share it with family and friends!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => SimpleSharingService.shareApp(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1577FE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Share'),
            ),
          ],
        ),
      ),
    );
  }
}