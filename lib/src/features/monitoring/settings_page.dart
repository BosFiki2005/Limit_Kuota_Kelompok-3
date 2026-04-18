import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _tempLimit = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pengaturan")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Batas Peringatan Data", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Tentukan kapan aplikasi harus memberi peringatan penggunaan data."),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Text("${_tempLimit.toStringAsFixed(1)} GB", 
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const Text("Batas Harian", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Slider(
              value: _tempLimit,
              min: 0.1,
              max: 5.0,
              divisions: 49,
              onChanged: (val) => setState(() => _tempLimit = val),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  // Mengirim kembali nilai limit ke halaman sebelumnya
                  Navigator.pop(context, _tempLimit);
                },
                child: const Text("Simpan Perubahan", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}