import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'boss/boss_shell.dart';
import 'customer/customer_shell.dart';
import 'driver_shell.dart';
import 'services/auth_service.dart';
import 'services/auth_session.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 2000), _restoreSession);
  }

  Future<void> _restoreSession() async {
    final session = AuthSession.instance;
    Widget? shell;
    if (session.token != null && session.userId != null) {
      switch (session.role) {
        case 'client':
          shell = const CustomerShell();
          break;
        case 'driver':
          shell = const DriverShell();
          break;
        case 'boss':
          shell = const BossShell();
          break;
      }
    }
    if (shell == null) {
      // Unknown or incomplete session: discard tokens before onboarding.
      if (session.token != null || session.refreshToken != null) {
        await AuthService.instance.logout();
      }
      if (mounted) Navigator.of(context).pushReplacementNamed('/onboarding');
      return;
    }
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => shell!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.asset(
                'assets/images/logo.png',
                width: 160,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -30),
              child: Text(
                'ORIZZONTE',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111111),
                  letterSpacing: 0.06,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
