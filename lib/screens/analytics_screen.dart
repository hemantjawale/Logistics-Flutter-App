import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_client.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _analytics;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await ApiClient.fetchSummaryAnalytics();
      if (mounted) {
        setState(() {
          _analytics = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildRevenueChart(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _buildPaymentSplit()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTopCustomers()),
                      ],
                    ),
                    const SizedBox(height: 100), // Bottom padding for footer
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Control',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
        ),
        Text(
          'Revenue, expenses and cash flow monitoring',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white60,
              ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Earnings vs Expenses',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              Row(
                children: [
                  _chartLegend('Earnings', Colors.indigoAccent),
                  const SizedBox(width: 12),
                  _chartLegend('Expenses', Colors.redAccent),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value >= 0 && value < days.length) {
                          return Text(days[value.toInt()],
                              style: const TextStyle(color: Colors.white54, fontSize: 10));
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: Colors.indigoAccent,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.indigoAccent.withOpacity(0.1),
                    ),
                    spots: const [
                      FlSpot(0, 30), FlSpot(1, 45), FlSpot(2, 38),
                      FlSpot(3, 60), FlSpot(4, 52), FlSpot(5, 75), FlSpot(6, 68),
                    ],
                  ),
                  LineChartBarData(
                    isCurved: true,
                    color: Colors.redAccent,
                    barWidth: 2,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: false),
                    spots: const [
                      FlSpot(0, 15), FlSpot(1, 20), FlSpot(2, 25),
                      FlSpot(3, 22), FlSpot(4, 30), FlSpot(5, 28), FlSpot(6, 35),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSplit() {
    final paid = _analytics?['payments']?['received'] ?? 65.0;
    final pending = _analytics?['payments']?['pending'] ?? 25.0;
    final overdue = _analytics?['payments']?['overdue'] ?? 10.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Text('Payment Split', style: TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 30,
                sections: [
                  PieChartSectionData(color: Colors.greenAccent, value: paid.toDouble(), showTitle: false, radius: 10),
                  PieChartSectionData(color: Colors.orangeAccent, value: pending.toDouble(), showTitle: false, radius: 10),
                  PieChartSectionData(color: Colors.redAccent, value: overdue.toDouble(), showTitle: false, radius: 10),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _paymentInfoRow('Paid', paid.toString(), Colors.greenAccent),
          _paymentInfoRow('Pending', pending.toString(), Colors.orangeAccent),
          _paymentInfoRow('Overdue', overdue.toString(), Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildTopCustomers() {
    final customers = [
      {'name': 'Amazon', 'revenue': '₹45k'},
      {'name': 'Flipkart', 'revenue': '₹32k'},
      {'name': 'Delhivery', 'revenue': '₹18k'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Accounts', style: TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 16),
          ...customers.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.white12,
                  child: Text(c['name']![0], style: const TextStyle(fontSize: 10)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(c['name']!, 
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis),
                ),
                Text(c['revenue']!, 
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _chartLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _paymentInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          Text(value, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

