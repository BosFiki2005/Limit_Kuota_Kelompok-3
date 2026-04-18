import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:limit_kuota/src/core/data/database_helper.dart';
import 'package:limit_kuota/src/core/services/intent_helper.dart';
import 'package:limit_kuota/src/features/monitoring/history_page.dart';

class Network extends StatefulWidget {
  const Network({super.key});

  @override
  State<Network> createState() => _NetworkState();
}

class _NetworkState extends State<Network> {
  static const platform = MethodChannel('limit_kuota/channel');

  String wifiUsage = "0.00 MB";
  String mobileUsage = "0.00 MB";

  Future<void> fetchUsage() async {
    try {
      final result = await platform.invokeMethod('getTodayUsage');

      String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      int wifiBytes = result['wifi'] ?? 0;
      int mobileBytes = result['mobile'] ?? 0;

      await DatabaseHelper.instance
          .insertOrUpdate(todayDate, wifiBytes, mobileBytes);

      setState(() {
        wifiUsage = _formatBytes(wifiBytes);
        mobileUsage = _formatBytes(mobileBytes);
      });

      checkLimitAndWarn(wifiBytes + mobileBytes);
    } catch (e) {}
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0.00 MB";
    double mb = bytes / (1024 * 1024);
    if (mb > 1024) {
      return "${(mb / 1024).toStringAsFixed(2)} GB";
    }
    return "${mb.toStringAsFixed(2)} MB";
  }

  double _getValue(String value) {
    return double.tryParse(value.split(" ")[0]) ?? 0;
  }

  Future<void> checkLimitAndWarn(int currentUsage) async {
    int limitInBytes = 1024 * 1024 * 1024;

    if (currentUsage >= limitInBytes) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Batas Kuota Tercapai!"),
          content: const Text("Silakan aktifkan data limit di pengaturan."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Nanti"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                IntentHelper.openDataLimitSettings();
              },
              child: const Text("Pengaturan"),
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
    double total = _getValue(wifiUsage) + _getValue(mobileUsage);
    double progress = total / 1024;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const HistoryPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // TOTAL CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${total.toStringAsFixed(2)} MB",
                style: const TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 20),

            _card("WiFi", wifiUsage, Icons.wifi),
            const SizedBox(height: 10),
            _card("Mobile", mobileUsage, Icons.signal_cellular_alt),

            const SizedBox(height: 20),

            LinearProgressIndicator(value: progress > 1 ? 1 : progress),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: fetchUsage,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
            )
          ],
        ),
      ),
    );
  }

  Widget _card(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 10),
          Text(title),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}