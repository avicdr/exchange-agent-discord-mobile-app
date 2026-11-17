import 'package:exchange_sentinel/app_state.dart';
import 'package:exchange_sentinel/models.dart';
import 'package:material_ui/material_ui.dart';

class TransactionApprovalsScreen extends StatefulWidget {
  const TransactionApprovalsScreen({super.key, required this.state});
  final AppState state;

  @override
  State<TransactionApprovalsScreen> createState() => _TransactionApprovalsScreenState();
}

class _TransactionApprovalsScreenState extends State<TransactionApprovalsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final pendingDeals = state.pendingApprovals;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settlement Approvals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Human-in-the-loop financial gate', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh queue',
            onPressed: state.loading ? null : () => state.refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: state.refresh,
        child: Column(
          children: [
            _buildSecurityHeader(pendingDeals.length),
            Expanded(
              child: pendingDeals.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      itemCount: pendingDeals.length,
                      itemBuilder: (context, index) {
                        final deal = pendingDeals[index];
                        return _buildApprovalCard(context, deal);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityHeader(int count) {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: count > 0 ? const Color(0xFF261910) : const Color(0xFF10241A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: count > 0 ? const Color(0xFFF5B942) : const Color(0xFF284235),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            count > 0 ? Icons.gavel_rounded : Icons.shield_outlined,
            color: count > 0 ? const Color(0xFFF5B942) : const Color(0xFF35D07F),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count > 0
                      ? '$count Settlements Pending Your Direct Approval'
                      : 'Settlement Gate Locked & Secure',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI is strictly prohibited from authorizing irreversible transactions. Every disbursement requires independent manual verification on your device.',
                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                ),
              ],
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
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green[400]),
            const SizedBox(height: 16),
            const Text(
              'No Pending Settlement Approvals',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'When payments are detected or customer claims arrive, they are queued here for manual verification.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalCard(BuildContext context, Deal deal) {
    final isI2c = deal.direction == DealDirection.i2c;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFF5B942), width: 1.2),
      ),
      color: const Color(0xFF13221B),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isI2c ? const Color(0xFF194430) : const Color(0xFF15334D),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    deal.directionLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isI2c ? const Color(0xFF7DE6A7) : Colors.lightBlueAccent,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF422E10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF5B942)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFF5B942)),
                      SizedBox(width: 4),
                      Text(
                        'APPROVAL REQUIRED',
                        style: TextStyle(
                          color: Color(0xFFF5B942),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.account_circle, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  deal.customerName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF09140F),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF284235)),
              ),
              child: Column(
                children: [
                  _infoRow('Disbursement Amount', '${deal.amount ?? "—"} ${deal.asset}'),
                  const SizedBox(height: 6),
                  _infoRow('Network / Chain', deal.network ?? 'Polygon'),
                  const SizedBox(height: 6),
                  _infoRow('Agreed Rate', '₹${deal.agreedRate ?? "—"}'),
                  const SizedBox(height: 6),
                  _infoRow('Expected Profit', '₹${deal.expectedProfit}', isProfit: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (isI2c) ...[
              const Text(
                'Customer Receiving Wallet:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              SelectableText(
                deal.destinationAddress ?? 'Address pending confirmation from customer',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white),
              ),
            ] else ...[
              const Text(
                'Customer Bank / UPI Destination:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              SelectableText(
                deal.destinationAddress ?? 'UPI / Bank details in ticket transcript',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _rejectDeal(context, deal),
                    child: const Text('Reject Deal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF35D07F),
                      foregroundColor: const Color(0xFF07110D),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _openApprovalModal(context, deal),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user, size: 16),
                        SizedBox(width: 6),
                        Text('Verify & Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isProfit = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isProfit ? const Color(0xFF7DE6A7) : Colors.white,
          ),
        ),
      ],
    );
  }

  void _openApprovalModal(BuildContext context, Deal deal) {
    final isI2c = deal.direction == DealDirection.i2c;
    final referenceController = TextEditingController(text: deal.settlementReference ?? '');
    final destinationController = TextEditingController(text: deal.destinationAddress ?? '');
    final noteController = TextEditingController();
    bool checkboxPaymentVerified = false;
    bool checkboxDestinationValid = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F1E17),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final canAuthorize = checkboxPaymentVerified && checkboxDestinationValid;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Manual Settlement Authorization',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(bottomSheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Deal: ${deal.id.substring(0, 8)}... (${deal.directionLabel})',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                    const Divider(color: Color(0xFF284235), height: 24),
                    const Text(
                      'Mandatory Human Verification Checklist:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF5B942), fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: checkboxPaymentVerified,
                      activeColor: const Color(0xFF35D07F),
                      title: Text(
                        isI2c
                            ? 'I have independently checked the bank/UPI statement and verified INR received.'
                            : 'I have independently checked the blockchain explorer and confirmed crypto receipt.',
                        style: const TextStyle(fontSize: 12),
                      ),
                      subtitle: const Text(
                        'Customer screenshots are NOT accepted without independent verification.',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      onChanged: (val) => setModalState(() => checkboxPaymentVerified = val ?? false),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: checkboxDestinationValid,
                      activeColor: const Color(0xFF35D07F),
                      title: Text(
                        isI2c
                            ? 'Recipient crypto wallet address matches customer ticket request.'
                            : 'Recipient bank account / UPI ID matches customer instructions.',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onChanged: (val) => setModalState(() => checkboxDestinationValid = val ?? false),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: destinationController,
                      decoration: InputDecoration(
                        labelText: isI2c ? 'Payout Crypto Wallet Address' : 'Payout UPI ID / Bank Details',
                        border: const OutlineInputBorder(),
                        hintText: isI2c ? '0x...' : 'username@bank',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: referenceController,
                      decoration: InputDecoration(
                        labelText: isI2c ? 'Tx Hash or Payment Ref' : 'Bank UTR / Transfer Reference',
                        border: const OutlineInputBorder(),
                        hintText: 'Enter internal or external reference',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Operator Audit Note (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'e.g. Verified HDFC statement at 14:02 IST',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canAuthorize ? const Color(0xFF35D07F) : Colors.grey[800],
                          foregroundColor: canAuthorize ? const Color(0xFF07110D) : Colors.grey[500],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: canAuthorize
                            ? () async {
                                Navigator.pop(bottomSheetContext);
                                try {
                                  if (isI2c) {
                                    await widget.state.approveI2c(
                                      deal,
                                      reference: referenceController.text,
                                      note: noteController.text,
                                      destination: destinationController.text,
                                    );
                                  } else {
                                    await widget.state.confirmCrypto(
                                      deal,
                                      transactionHash: referenceController.text,
                                      note: noteController.text,
                                      destination: destinationController.text,
                                    );
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Settlement Authorized and Recorded'),
                                        backgroundColor: Color(0xFF1E5B37),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Approval failed: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              }
                            : null,
                        child: Text(
                          canAuthorize ? 'CONFIRM & AUTHORIZE SETTLEMENT' : 'COMPLETE CHECKLIST TO AUTHORIZE',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _rejectDeal(BuildContext context, Deal deal) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF14241C),
        title: const Text('Reject Settlement Request?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This will deny the settlement and notify the customer of the cancellation or dispute.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'Reason: unverified funds, suspected fraud, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
            child: const Text('Reject'),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await widget.state.reject(deal, reason: noteController.text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Deal rejected')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
