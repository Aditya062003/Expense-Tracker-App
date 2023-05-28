import 'package:flutter/material.dart';

class ThemeSwitchButton extends StatefulWidget {
  @override
  _ThemeSwitchButtonState createState() => _ThemeSwitchButtonState();
}

class _ThemeSwitchButtonState extends State<ThemeSwitchButton> {
  bool isDarkModeEnabled = false;

  void toggleTheme() {
    setState(() {
      isDarkModeEnabled = !isDarkModeEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(isDarkModeEnabled ? Icons.wb_sunny : Icons.nightlight_round),
      onPressed: toggleTheme,
    );
  }
}
