import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:limit_kuota/src/core/data/database_helper.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<Map<String, dynamic>>> _historyList;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      _refreshHistory();
    });
  }

  void _refreshHistory() {
    setState(() {
      _historyList = DatabaseHelper.instance.getHistory();
    });
  }

  String _formatDate(String date) {
    final parsed = DateTime.parse(date);
    return DateFormat('dd MMM', 'id_ID').format(parsed);
  }

  String _formatBytes(int bytes) {
    double mb = bytes / (1024 * 1024);
    return "${mb.toStringAsFixed(1)} MB";
  }

  Widget _buildChart(List<Map<String, dynamic>> data) {
    /// ❗ HANDLE DATA KOSONG / 1 DATA
    if (data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("Belum ada data")),
      );
    }

    if (data.length == 1) {
      /// bikin dummy supaya chart tidak rusak
      data = [
        {
          'date': data[0]['date'],
          'wifi': 0,
          'mobile': 0,
        },
        ...data,
      ];
    }

    List<FlSpot> wifi = [];
    List<FlSpot> mobile = [];

    double maxY = 0;

    for (int i = 0; i < data.length; i++) {
      double wifiVal = (data[i]['wifi'] ?? 0) / (1024 * 1024);
      double mobileVal = (data[i]['mobile'] ?? 0) / (1024 * 1024);

      wifi.add(FlSpot(i.toDouble(), wifiVal));
      mobile.add(FlSpot(i.toDouble(), mobileVal));

      if (wifiVal > maxY) maxY = wifiVal;
      if (mobileVal > maxY) maxY = mobileVal;
    }

    /// biar gak 0 semua
    if (maxY == 0) maxY = 10;

    double intervalY = (maxY / 5).ceilToDouble();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY + intervalY,

            /// GRID
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: intervalY,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 1,
                );
              },
            ),

            borderData: FlBorderData(show: false),

            /// TOOLTIP
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                tooltipRoundedRadius: 12,
                tooltipPadding: const EdgeInsets.all(8),
                getTooltipItems: (spots) {
                  return spots.map((spot) {
                    return LineTooltipItem(
                      "${spot.y.toStringAsFixed(1)} MB",
                      const TextStyle(color: Colors.white),
                    );
                  }).toList();
                },
              ),
            ),

            titlesData: FlTitlesData(
              topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),

              /// X AXIS
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= data.length) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _formatDate(data[index]['date']),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),

              /// Y AXIS
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: intervalY,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),

            lineBarsData: [
              /// WIFI
              LineChartBarData(
                spots: wifi,
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.3),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              /// MOBILE
              LineChartBarData(
                spots: mobile,
                isCurved: true,
                color: Colors.green,
                barWidth: 3,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.3),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Riwayat Penggunaan"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyList,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          return Column(
            children: [
              _buildChart(data),

              Expanded(
                child: ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(_formatDate(item['date'])),
                        subtitle: Text(
                          "WiFi: ${_formatBytes(item['wifi'])} | Mobile: ${_formatBytes(item['mobile'])}",
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }
}