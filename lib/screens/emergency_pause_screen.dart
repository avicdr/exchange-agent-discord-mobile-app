import 'package:exchange_sentinel/app_state.dart';
import 'package:material_ui/material_ui.dart';

class EmergencyPauseScreen extends StatelessWidget {
  const EmergencyPauseScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final isPaused = state.isAgentPaused;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Emergency Controls', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Kill switch & agent pause controls', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusHero(isPaused),
            const SizedBox(height: 24),
            _buildEmergencyStopButton(context),
            const SizedBox(height: 16),
            _buildPauseResumeToggle(context, isPaused),
            const SizedBox(height: 24),
            _buildSafeguardInfo(),
            const SizedBox(height: 16),
            _buildRunbookCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHero(bool isPaused) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPaused ? const Color(0xFF381519) : const Color(0xFF10281E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaused ? const Color(0xFFF05B63) : const Color(0xFF35D07F),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isPaused ? Icons.pause_circle_filled : Icons.check_circle,
            color: isPaused ? const Color(0xFFF05B63) : const Color(0xFF35D07F),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            isPaused ? 'AGENT IS CURRENTLY PAUSED' : 'AGENT IS RUNNING & WATCHING',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isPaused ? const Color(0xFFFF9EA6) : const Color(0xFF7DE6A7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPaused
                ? 'All autonomous conversations, rate quotations, and payment intake are halted. Outgoing settlements remain strictly blocked.'
                : 'Discord intake is active for allowlisted channels. AI is responding to inquiries but CANNOT disburse funds without your approval.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[300], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyStopButton(BuildContext context) {
    return Card(
      color: const Color(0xFF261013),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF8B1E27)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.report_problem, color: Color(0xFFF05B63), size: 20),
                SizedBox(width: 8),
                Text(
                  'Global Emergency Stop',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Immediately halts the backend engine, closes Discord message intake, and locks all pending settlements.',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9F2732),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.power_settings_new),
                label: const Text(
                  'TRIGGER EMERGENCY STOP',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                onPressed: () => _confirmEmergencyStop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseResumeToggle(BuildContext context, bool isPaused) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isPaused ? const Color(0xFF204230) : const Color(0xFF422B10),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
            label: Text(
              isPaused ? 'Resume Agent' : 'Pause Agent',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              if (isPaused) {
                await state.resume();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Agent resumed successfully')),
                  );
                }
              } else {
                await state.pause();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Agent paused')),
                  );
                }
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSafeguardInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101E17),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF223E2F)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_clock, color: Color(0xFF35D07F), size: 18),
              SizedBox(width: 8),
              Text('Fail-Closed Architecture', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• AI cannot execute blockchain broadcasts or fiat transfers.\n'
            '• In the event of network disconnection, all operations halt safely.\n'
            '• Screenshots provided by counterparties are treated as zero proof.\n'
            '• Idempotency keys prevent double disbursements under all failure modes.',
            style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildRunbookCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF233B4A)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_outlined, color: Colors.lightBlueAccent, size: 18),
              SizedBox(width: 8),
              Text('Emergency Recovery Protocol', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '1. Check audit logs to identify the trigger event.\n'
            '2. Confirm all live wallet balances and open orders on explorer.\n'
            '3. Address counterparty disputes in Discord directly.\n'
            '4. Tap "Resume Agent" only after clearing discrepancies.',
            style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  void _confirmEmergencyStop(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2A1014),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Color(0xFFF05B63)),
            SizedBox(width: 8),
            Text('Confirm Emergency Stop', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Are you sure you want to trigger EMERGENCY STOP? This will immediately halt all operations, pause incoming Discord message ingestion, and prevent any settlements.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9F2732)),
            child: const Text('CONFIRM STOP', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await state.emergencyStop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('EMERGENCY STOP TRIGGERED'),
                    backgroundColor: Color(0xFF9F2732),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
