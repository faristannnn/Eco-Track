import 'package:flutter/material.dart';
import 'package:login_ui/responsive/dekstop_scaffold.dart';
import 'package:login_ui/responsive/tablet_scaffold.dart';
import 'package:login_ui/responsive/mobile_scaffold.dart';
import 'package:login_ui/responsive/responsive_layout.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blue,
      ),
      home : ResponsiveLayout(
        mobileScaffold: MobileScaffold(),
        tabletScaffold: TabletScaffold(),
        desktopScaffold: DesktopScaffold()
      ),
    );
  }
}