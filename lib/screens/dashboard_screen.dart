import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _analytics;
  List<Map<String, dynamic>> _activeShipments = [];
  List<Map<String, dynamic>> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final analytics = await ApiClient.fetchSummaryAnalytics();
      final shipments = await ApiClient.fetchShipments(status: 'In Transit');

      // Generate alerts based on data
      final List<Map<String, dynamic>> alerts = [];
      
      // Shipment alerts
      final delayedCount = analytics['shipments']?['delayed'] ?? 0;
      if (delayedCount > 0) {
        alerts.add({
          'type': 'Delay',
          'severity': Colors.orangeAccent,
          'title': '$delayedCount Shipments Delayed',
          'subtitle': 'Check route optimization',
        });
      }

      // Fleet alerts
      final criticalVehicles = analytics['fleet']?['critical'] ?? 0;
      if (criticalVehicles > 0) {
        alerts.add({
          'type': 'Maintenance',
          'severity': Colors.redAccent,
          'title': '$criticalVehicles Vehicles Critical',
          'subtitle': 'Immediate maintenance required',
        });
      }

      // Payment alerts
      final overduePayments = analytics['payments']?['overdue'] ?? 0;
      if (overduePayments > 0) {
        alerts.add({
          'type': 'Payment',
          'severity': Colors.purpleAccent,
          'title': '$overduePayments Overdue Payments',
          'subtitle': 'Follow up with customers',
        });
      }

      if (mounted) {
        setState(() {
          _analytics = analytics;
          _activeShipments = shipments;
          _alerts = alerts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF020617),
            Color(0xFF020617),
            Color(0xFF020617),
          ],
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Header(colorScheme: colorScheme),
                            const SizedBox(height: 20),
                            if (_analytics != null)
                              _KpiRow(analytics: _analytics!),
                            const SizedBox(height: 24),
                            _SectionHeader(
                              title: 'Live Shipments',
                              subtitle: 'Track routes and ETAs in real time',
                            ),
                            const SizedBox(height: 12),
                            _ShipmentsStrip(shipments: _activeShipments),
                            const SizedBox(height: 24),
                            _SectionHeader(
                              title: 'Smart Alerts',
                              subtitle:
                                  'Delays, maintenance and payments at a glance',
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.builder(
                        itemCount: _alerts.length,
                        itemBuilder: (context, index) {
                          final alert = _alerts[index];
                          return _AnimatedItem(
                            index: index,
                            child: _AlertCard(alert: alert),
                          );
                        },
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Next-Gen Logistics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Control tower for shipments, fleet & payments',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ),
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.secondary,
              ],
            ),
          ),
          child: const Icon(Icons.insights_rounded, size: 22),
        ),
      ],
    );
  }
}

class _KpiRow extends StatelessWidget {
  final Map<String, dynamic> analytics;

  const _KpiRow({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final onTimeDelivery = analytics['shipments']?['onTimeDelivery'] ?? 0;
    final activeShipments = analytics['shipments']?['inTransit'] ?? 0;
    final delayedShipments = analytics['shipments']?['delayed'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _AnimatedItem(
            index: 0,
            child: _KpiCard(
              label: 'On-time delivery',
              value: '${(onTimeDelivery * 100).round()}%',
              trend: 'Based on last 30 days',
              accent: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF22C55E)],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AnimatedItem(
            index: 1,
            child: _KpiCard(
              label: 'Active shipments',
              value: '$activeShipments',
              trend: '$delayedShipments at risk of delay',
              accent: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF22D3EE)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.accent,
  });

  final String label;
  final String value;
  final String trend;
  final LinearGradient accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF020617),
          ],
        ),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) => accent.createShader(bounds),
            child: Text(
              trend,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShipmentsStrip extends StatelessWidget {
  final List<Map<String, dynamic>> shipments;

  const _ShipmentsStrip({required this.shipments});

  Color _statusColor(String status) {
    switch (status) {
      case 'In Transit':
        return Colors.blueAccent;
      case 'Delivered':
        return Colors.greenAccent;
      case 'Delayed':
        return Colors.orangeAccent;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (shipments.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No active shipments',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: shipments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final shipment = shipments[index];
          final status = shipment['status'] ?? 'Pending';
          final color = _statusColor(status);
          final eta = shipment['eta'] != null
              ? DateFormat('MMM d').format(DateTime.parse(shipment['eta']))
              : 'N/A';
          final progress = (shipment['progress'] ?? 0.0).toDouble();

          return _AnimatedItem(
            index: index,
            child: Container(
              width: 240,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1E293B),
                    const Color(0xFF020617),
                  ],
                ),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: color.withOpacity(0.18),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              status,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: color),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        shipment['trackingNumber'] ?? '',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.radio_button_checked,
                          size: 14, color: Colors.tealAccent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shipment['origin'] ?? '',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              shipment['destination'] ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.white70),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.08),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(color),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(progress * 100).round()}%',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ETA: $eta',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final Map<String, dynamic> alert;

  @override
  Widget build(BuildContext context) {
    final Color color = alert['severity'] as Color;

    IconData icon;
    switch (alert['type']) {
      case 'Delay':
        icon = Icons.schedule_rounded;
        break;
      case 'Maintenance':
        icon = Icons.build_rounded;
        break;
      case 'Payment':
        icon = Icons.payments_rounded;
        break;
      default:
        icon = Icons.notifications_active_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF020617),
            Color(0xFF020617),
          ],
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.16),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['title'] as String,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert['subtitle'] as String,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(
              alert['type'] as String,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.tune_rounded, size: 20),
        ),
      ],
    );
  }
}

class _AnimatedItem extends StatelessWidget {
  const _AnimatedItem({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 450 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: child,
    );
  }
}
