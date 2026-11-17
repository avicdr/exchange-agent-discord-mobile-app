import 'package:exchange_sentinel/alarm_service.dart';
import 'package:exchange_sentinel/app_state.dart';
import 'package:material_ui/material_ui.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key, required this.state});
  final AppState state;

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  late TextEditingController _urlController;
  late TextEditingController _tokenController;
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.state.baseUrl);
    _tokenController = TextEditingController(text: widget.state.token);
  }

  @override
  void didUpdateWidget(OverviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.baseUrl != _urlController.text) {
      _urlController.text = widget.state.baseUrl;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final overview = state.overview;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Operations Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Metrics, telemetry & connectivity', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh data',
            onPressed: state.loading ? null : () => state.refresh(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildConnectionCard(state),
            const SizedBox(height: 16),
            _buildProviderStatusCard(state),
            const SizedBox(height: 16),
            _buildMetricsGrid(overview),
            const SizedBox(height: 20),
            _buildBackendSettingsCard(),
            const SizedBox(height: 20),
            _buildDiagnosticsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(AppState state) {
    final isOnline = state.connected;
    final isReconnecting = state.isReconnecting;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF102118),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline ? const Color(0xFF35D07F) : Colors.amber,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline
                  ? const Color(0xFF35D07F)
                  : (isReconnecting ? Colors.amber : Colors.red),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline
                      ? 'WebSocket Synchronized (Live)'
                      : (isReconnecting ? 'Reconnecting to Backend...' : 'Disconnected'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  'Sequence: #${state.lastSequence} · ${state.baseUrl}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => state.refresh(),
            child: const Text('Sync', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderStatusCard(AppState state) {
    final status = state.providerStatus;
    Color statusColor;
    String statusDesc;

    switch (status) {
      case 'LIVE':
        statusColor = const Color(0xFF35D07F);
        statusDesc = 'Discord Gateway v10 connected with live events and blockchain monitor.';
        break;
      case 'SIMULATED':
        statusColor = Colors.cyanAccent;
        statusDesc = 'Running in simulated environment for mock testing & safe rehearsal.';
        break;
      case 'BLOCKED':
        statusColor = const Color(0xFFF05B63);
        statusDesc = 'Provider challenged by Discord Cloudflare/CAPTCHA. Safe fail-closed mode.';
        break;
      default:
        statusColor = Colors.amber;
        statusDesc = 'Waiting for provider telemetry from the backend.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14211A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF284235)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Provider Telemetry',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            state.providerReason.isNotEmpty ? state.providerReason : statusDesc,
            style: TextStyle(color: Colors.grey[300], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(overview) {
    final active = overview?.active ?? 0;
    final attention = overview?.attention ?? 0;
    final completed = overview?.completed ?? 0;
    final vouches = overview?.vouches ?? 0;
    final profit = overview?.profit ?? '0';

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _metricCard('Active Deals', '$active', Icons.sync_alt, Colors.blueAccent)),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                'Attention Req.',
                '$attention',
                Icons.warning_amber_rounded,
                attention > 0 ? Colors.redAccent : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _metricCard('Completed', '$completed', Icons.task_alt, const Color(0xFF35D07F))),
            const SizedBox(width: 12),
            Expanded(child: _metricCard('Verified Vouches', '$vouches', Icons.verified, Colors.purpleAccent)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF132A1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF28563C)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estimated Realized Profit', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('Calculated after fee deducts', style: TextStyle(fontSize: 10, color: Colors.white54)),
                ],
              ),
              Text(
                '₹$profit',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7DE6A7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E17),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF284235)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildBackendSettingsCard() {
    return Card(
      color: const Color(0xFF0F1E17),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF284235)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backend API Connection',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Configured for local network or secure reverse proxy.',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Backend Base URL',
                hintText: 'http://10.0.2.2:8000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenController,
              obscureText: _obscureToken,
              decoration: InputDecoration(
                labelText: 'Bearer API Token',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureToken ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureToken = !_obscureToken),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF35D07F),
                  foregroundColor: const Color(0xFF07110D),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  await widget.state.saveConnection(
                    _urlController.text,
                    _tokenController.text,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings saved & reconnected')),
                    );
                  }
                },
                child: const Text('Save & Reconnect', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticsCard() {
    return Card(
      color: const Color(0xFF0F1E17),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF284235)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hardware & Alarm Diagnostics',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Test urgent takeover alarm tone, vibration, and background notifications.',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.volume_up, size: 16),
                    label: const Text('Test Siren', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      AlarmService.start(
                        title: 'TEST ALARM',
                        body: 'Testing device siren and vibration.',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.volume_off, size: 16),
                    label: const Text('Stop Siren', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      AlarmService.stop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
