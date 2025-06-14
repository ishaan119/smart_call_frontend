// lib/simple_sharing_service.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class SimpleSharingService {
  static const String appStoreUrl = 'https://apps.apple.com/app/smartcall/id123456789';
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.docninja.smartcall';
  static const String webUrl = 'https://smartcall.app';

  // General app sharing
  static Future<void> shareApp(BuildContext context) async {
    const String message = 
        "I've been using SmartCall to stay connected with my family through personalized voice reminders! 💙\n\n"
        "Perfect for:\n"
        "🏥 Medication reminders\n"
        "📞 Daily check-ins\n"
        "📅 Appointment alerts\n"
        "👨‍👩‍👧‍👦 Family coordination\n\n"
        "Download SmartCall: $webUrl\n"
        "Available on Google Play and App Store!";

    await Share.share(
      message,
      subject: 'Stay connected with your loved ones - SmartCall',
    );
  }

  // Share with family context
  static Future<void> shareWithFamily(BuildContext context) async {
    const String message = 
        "Hey! I've been using SmartCall to help our family stay connected with voice reminders.\n\n"
        "📱 It sends personalized voice calls for:\n"
        "• Medication reminders\n"
        "• Daily check-ins\n"
        "• Important appointments\n"
        "• Any family reminders\n\n"
        "Want to help coordinate care together? Download SmartCall:\n"
        "$webUrl\n\n"
        "Perfect for keeping our family connected! 💙";

    await Share.share(
      message,
      subject: 'Help me stay connected with our family',
    );
  }

  // Share success story
  static Future<void> shareSuccessStory(BuildContext context, {String? customStory}) async {
    String message = "🎉 SmartCall has been amazing for our family! ";
    
    if (customStory != null && customStory.isNotEmpty) {
      message += "$customStory\n\n";
    } else {
      message += "It helps us stay connected with personalized voice reminders.\n\n";
    }
    
    message += "SmartCall is perfect for:\n"
        "• Medication reminders for elderly parents\n"
        "• Daily family check-ins\n"
        "• Important appointment alerts\n"
        "• Keeping everyone coordinated\n\n"
        "Try it free: $webUrl\n"
        "Available on Google Play and App Store! 📱";

    await Share.share(
      message,
      subject: '🎉 SmartCall helped our family stay connected!',
    );
  }

  // Share with healthcare context
  static Future<void> shareWithHealthcareProvider(BuildContext context) async {
    const String message = 
        "I wanted to share SmartCall, an app that's been helping me stay compliant with my medication schedule and family coordination.\n\n"
        "🏥 Healthcare Benefits:\n"
        "• Improved medication adherence\n"
        "• Reduced missed appointments\n"
        "• Family caregiver coordination\n"
        "• Automated voice reminders\n\n"
        "Healthcare providers can recommend this to patients for better compliance.\n\n"
        "Learn more: $webUrl\n"
        "Available on all platforms.";

    await Share.share(
      message,
      subject: 'SmartCall: Improve Patient Medication Compliance',
    );
  }

  // Copy app link
  static Future<void> copyAppLink(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: webUrl));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App link copied to clipboard!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Share via specific platform (if you want to add platform-specific sharing later)
  static Future<void> shareToSocialMedia(BuildContext context, String platform) async {
    String message = "Check out SmartCall - the app that helps families stay connected! 💙\n\n"
        "Perfect for medication reminders, daily check-ins, and family coordination.\n\n"
        "$webUrl";

    switch (platform.toLowerCase()) {
      case 'whatsapp':
        message = "💙 SmartCall keeps families connected!\n\n"
            "✅ Medication reminders\n"
            "✅ Daily check-ins\n"
            "✅ Voice messages\n\n"
            "Download: $webUrl";
        break;
      case 'facebook':
      case 'twitter':
        message = "Staying connected with family just got easier! 💙\n\n"
            "SmartCall sends personalized voice reminders for medication, appointments, and daily check-ins.\n\n"
            "Perfect for caring families! $webUrl";
        break;
    }

    await Share.share(message);
  }
}