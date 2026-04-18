import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:limit_kuota/src/core/theme/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isAlertOn = true;
  double limitData = 1; // GB

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        children: [
          // 🌙 DARK MODE
          ListTile(
            title: const Text("Dark Mode"),
            trailing: Switch(
              value: themeProvider.isDark,
              onChanged: (value) {
                themeProvider.toggleTheme(value);
              },
            ),
          ),

          const Divider(),

          // 📶 PERINGATAN DATA
          ListTile(
            title: const Text("Peringatan Data"),
            trailing: Switch(
              value: isAlertOn,
              onChanged: (value) {
                setState(() {
                  isAlertOn = value;
                });
              },
            ),
          ),

          // 🔢 BATAS KUOTA
          if (isAlertOn)
            ListTile(
              title: const Text("Batas Kuota"),
              subtitle: Slider(
                value: limitData,
                min: 1,
                max: 10,
                divisions: 9,
                label: "${limitData.toInt()} GB",
                onChanged: (value) {
                  setState(() {
                    limitData = value;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}