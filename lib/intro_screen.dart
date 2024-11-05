import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'reminders_screen.dart'; // Import your main screen

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final introKey = GlobalKey<IntroductionScreenState>();

  // Function to navigate to the main app screen when intro is done
  void _onIntroEnd() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_seen', true); // Set flag that intro is seen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          builder: (_) => const RemindersScreen()), // Navigate to the main screen
    );
  }

  // Function to build image widget from asset
  Widget _buildFullScreenImage(String assetName) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(assetName),
          fit: BoxFit.cover, // Make the image cover the entire screen
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      key: introKey,
      pages: [
        PageViewModel(
          title: "", // Empty title to remove it
          body: "", // Empty body to remove it
          image: _buildFullScreenImage(
              'assets/images/voice_reminders.png'), // Your full-screen image
          decoration: const PageDecoration(
            fullScreen: true, // This ensures the page is in full-screen mode
            bodyFlex: 0, // Remove body section
            imageFlex: 1, // The image takes the entire space
          ),
        ),
        PageViewModel(
          title: "", // Empty title to remove it
          body: "", // Empty body to remove it
          image: _buildFullScreenImage(
              'assets/images/notifications.png'), // Your full-screen image
          decoration: const PageDecoration(
            fullScreen: true, // This ensures the page is in full-screen mode
            bodyFlex: 0, // Remove body section
            imageFlex: 1, // The image takes the entire space
          ),
        ),
      ],
      onDone: _onIntroEnd, // When the user presses the 'Done' button
      onSkip: _onIntroEnd, // Skip option directly moves to main app
      showSkipButton: true,
      skip: const Text('Skip'),
      next: const Icon(Icons.arrow_forward),
      done: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Colors.grey,
        activeSize: Size(22.0, 10.0),
        activeColor: Colors.blue,
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}
