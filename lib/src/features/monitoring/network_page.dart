import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:limit_kuota/src/core/data/database_helper.dart';
import 'package:limit_kuota/src/core/services/intent_helper.dart';
import 'package:limit_kuota/src/features/monitoring/history_page.dart';
import 'package:limit_kuota/src/features/monitoring/settings_page.dart'; // Import halaman baru

class Network extends StatefulWidget {
  const Network({super.key});

  @override
  State<Network> createState() => _NetworkState();
}

class _NetworkState extends State<Network> {
  static const platform = MethodChannel('limit_kuota/channel');

  String wifiUsage = "0.00 MB";
  String mobileUsage = "0.00 MB";
  double dailyLimitGB = 1.0; // Default limit 1GB

  Future<void> fetchUsage() async {
    try {
      final result = await platform.invokeMethod('getTodayUsage');
      String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      int wifiBytes = result['wifi'] ?? 0;
      int mobileBytes = result['mobile'] ?? 0;

      await DatabaseHelper.instance.insertOrUpdate(todayDate, wifiBytes, mobileBytes);

      setState(() {
        wifiUsage = _formatBytes(wifiBytes);
        mobileUsage = _formatBytes(mobileBytes);
      });

      checkLimitAndWarn(wifiBytes + mobileBytes);
    } catch (e) {
      debugPrint("Error fetching usage: $e");
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0.00 MB";
    double mb = bytes / (1024 * 1024);
    if (mb > 1024) return "${(mb / 1024).toStringAsFixed(2)} GB";
    return "${mb.toStringAsFixed(2)} MB";
  }

  double _getMBValue(String value) {
    if (value.contains("GB")) {
      return (double.tryParse(value.split(" ")[0]) ?? 0) * 1024;
    }
    return double.tryParse(value.split(" ")[0]) ?? 0;
  }

  Future<void> checkLimitAndWarn(int currentUsage) async {
    double limitInBytes = dailyLimitGB * 1024 * 1024 * 1024;
    if (currentUsage >= limitInBytes) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Batas Kuota Tercapai!"),
          content: Text("Penggunaan data Anda telah mencapai ${dailyLimitGB.toStringAsFixed(1)} GB."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Nanti")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                IntentHelper.openDataLimitSettings();
              },
              child: const Text("Pengaturan HP"),
            ),
          ],
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUsage();
  }

  @override
  Widget build(BuildContext context) {
    double totalMB = _getMBValue(wifiUsage) + _getMBValue(mobileUsage);
    double limitMB = dailyLimitGB * 1024;
    double progress = totalMB / limitMB;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Monitoring Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              // Navigasi ke Settings dan ambil data limit baru jika ada
              final newLimit = await Navigator.push<double>(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
              if (newLimit != null) {
                setState(() => dailyLimitGB = newLimit);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryPage()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.lightBlue]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total Penggunaan Hari Ini", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    totalMB >= 1024 ? "${(totalMB / 1024).toStringAsFixed(2)} GB" : "${totalMB.toStringAsFixed(2)} MB",
                    style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            _card("WiFi", wifiUsage, Icons.wifi, Colors.orange),
            const SizedBox(height: 12),
            _card("Mobile Data", mobileUsage, Icons.signal_cellular_alt, Colors.green),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Progres Kuota", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("${(progress * 100).toStringAsFixed(1)}% / ${dailyLimitGB}GB"),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress > 1 ? 1 : progress,
                minHeight: 12,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(progress > 0.9 ? Colors.red : Colors.blue),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: fetchUsage,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
              icon: const Icon(Icons.refresh),
              label: const Text("Perbarui Data"),
            )
          ],
        ),
      ),
    );
  }

  Widget _card(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
          const SizedBox(width: 15),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}