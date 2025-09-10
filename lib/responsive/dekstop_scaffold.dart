import 'package:flutter/material.dart';
import 'package:login_ui/loginpage.dart';

class DesktopScaffold extends StatelessWidget {
  const DesktopScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Loginpage(),
    );
  }
}
