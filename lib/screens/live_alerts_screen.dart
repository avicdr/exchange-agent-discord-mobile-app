import 'package:exchange_sentinel/app_state.dart';
import 'package:exchange_sentinel/models.dart';
import 'package:material_ui/material_ui.dart';

class LiveAlertsScreen extends StatelessWidget {
  const LiveAlertsScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final alerts = state.alerts;
    final isAlarmActive = state.isAlarmActive;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live Alerts & Alarms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('High-priority operational notifications', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          if (isAlarmActive)
            IconButton(
              icon: const Icon(Icons.volume_off, color: Colors.redAccent),
              tooltip: 'Silence alarm',
              onPressed: () => state.stopAlarm(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh alerts',
            onPressed: state.loading ? null : () => state.refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: state.refresh,
        child: Column(
          children: [
            if (isAlarmActive) _buildActiveAlarmBanner(context),
            Expanded(
              child: alerts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        return _buildAlertCard(context, alert);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAlarmBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4C151B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withAlpha(50),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.warning, color: Colors.redAccent, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'URGENT ALARM ACTIVE',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Full-screen siren is sounding for customer payment or takeover claim.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.volume_off),
              label: const Text(
                'STOP ALARM SOUND',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                await state.stopAlarm();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alarm siren stopped')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              'No Pending Alerts',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'All clear! Urgent alerts such as customer payment claims, duplicate hashes, or high-risk counterparties will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, AlertEvent alert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF6E2830), width: 1.2),
      ),
      color: const Color(0xFF1F1113),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF551920),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.redAccent, width: 0.8),
                  ),
                  child: Text(
                    alert.kind.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF9EA6),
                    ),
                  ),
                ),
                Text(
                  _formatTime(alert.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alert.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              alert.body,
              style: TextStyle(color: Colors.grey[300], fontSize: 13),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF12080A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Customer: ${alert.deal.customerName}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${alert.deal.directionLabel} · ${alert.deal.amount ?? "—"} ${alert.deal.asset}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF7DE6A7)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[300],
                    side: const BorderSide(color: Color(0xFF452427)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () async {
                    await state.dismissAlert(alert.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alert dismissed')),
                      );
                    }
                  },
                  child: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF35D07F),
                    foregroundColor: const Color(0xFF07110D),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () async {
                    await state.acknowledgeAlert(alert.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alert acknowledged')),
                      );
                    }
                  },
                  child: const Text(
                    'Acknowledge',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
