import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/irrigation_provider.dart';
import 'dashboard_screen.dart';
import 'device_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/splash_screen.mp4');

    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {});
        _controller.play();
        _controller.addListener(_videoListener);
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (!_isNavigated) {
            _navigateToHome();
          }
        });
      }
    }).catchError((error) {
      _navigateToHome();
    });

    Future.delayed(const Duration(milliseconds: 5000), () {
      if (!_isNavigated) {
        _navigateToHome();
      }
    });
  }

  void _videoListener() {
    if (_controller.value.position >= _controller.value.duration && !_isNavigated) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    _isNavigated = true;
    _controller.removeListener(_videoListener);
    if (!mounted) return;

    final provider = context.read<IrrigationProvider>();
    final targetScreen = provider.isTokenConfigured
        ? const DashboardScreen()
        : const DeviceSetupScreen(isInitialSetup: true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      body: Center(
        child: _controller.value.isInitialized
            ? SizedBox(
                width: 300,
                height: 300,
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
