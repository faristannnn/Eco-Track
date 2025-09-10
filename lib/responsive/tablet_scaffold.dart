import 'package:flutter/material.dart';
import 'package:login_ui/loginpage.dart';

class TabletScaffold extends StatelessWidget {
  const TabletScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Loginpage(),
    );
  }
}
