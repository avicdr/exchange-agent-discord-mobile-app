import 'package:exchange_sentinel/app_state.dart';
import 'package:exchange_sentinel/models.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class ActiveTicketsScreen extends StatefulWidget {
  const ActiveTicketsScreen({super.key, required this.state});
  final AppState state;

  @override
  State<ActiveTicketsScreen> createState() => _ActiveTicketsScreenState();
}

class _ActiveTicketsScreenState extends State<ActiveTicketsScreen> {
  String _selectedFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final allDeals = state.activeDeals;

    final filteredDeals = allDeals.where((deal) {
      if (_selectedFilter == 'ALL') return true;
      if (_selectedFilter == 'ATTENTION') return deal.needsAttention;
      if (_selectedFilter == 'NEGOTIATING') {
        return deal.status == 'NEGOTIATING' || deal.status == 'QUALIFYING' || deal.status == 'TERMS_AGREED';
      }
      if (_selectedFilter == 'PAYMENT') {
        return deal.status.contains('PAYMENT') || deal.status.contains('DEPOSIT');
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Tickets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Discord channel intake & queue', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh tickets',
            onPressed: state.loading ? null : () => state.refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: state.refresh,
        child: Column(
          children: [
            _buildFilterChips(allDeals),
            Expanded(
              child: filteredDeals.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      itemCount: filteredDeals.length,
                      itemBuilder: (context, index) {
                        final deal = filteredDeals[index];
                        return _buildTicketCard(context, deal);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(List<Deal> deals) {
    final attentionCount = deals.where((d) => d.needsAttention).length;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          _filterChip('ALL', 'All (${deals.length})'),
          const SizedBox(width: 8),
          _filterChip('ATTENTION', 'Attention ($attentionCount)', isUrgent: attentionCount > 0),
          const SizedBox(width: 8),
          _filterChip('NEGOTIATING', 'Negotiating'),
          const SizedBox(width: 8),
          _filterChip('PAYMENT', 'Payment Flow'),
        ],
      ),
    );
  }

  Widget _filterChip(String id, String label, {bool isUrgent = false}) {
    final selected = _selectedFilter == id;
    return ChoiceChip(
      selected: selected,
      label: Text(
        label,
        style: TextStyle(
          color: selected
              ? Colors.white
              : (isUrgent ? Colors.redAccent : Colors.grey[300]),
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selectedColor: isUrgent ? Colors.red[800] : const Color(0xFF1E3A2B),
      backgroundColor: const Color(0xFF14241C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isUrgent
              ? Colors.redAccent.withAlpha(128)
              : (selected ? const Color(0xFF35D07F) : const Color(0xFF284235)),
        ),
      ),
      onSelected: (_) => setState(() => _selectedFilter = id),
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
            Icon(Icons.confirmation_number_outlined, size: 56, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              'No active tickets found',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Incoming Discord ticket channels in allowlisted servers will appear here automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, Deal deal) {
    final isUrgent = deal.needsAttention;
    final isI2c = deal.direction == DealDirection.i2c;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUrgent ? Colors.redAccent.withAlpha(200) : const Color(0xFF284235),
          width: isUrgent ? 1.5 : 1,
        ),
      ),
      color: const Color(0xFF0F1E17),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isI2c ? const Color(0xFF133E2B) : const Color(0xFF1B3145),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isI2c ? const Color(0xFF35D07F) : Colors.lightBlueAccent,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          deal.directionLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isI2c ? const Color(0xFF7DE6A7) : Colors.lightBlueAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        deal.network ?? 'Polygon',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                _statusBadge(deal.status, isUrgent),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    deal.customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Profit: ₹${deal.expectedProfit}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7DE6A7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Amount: ${deal.amount ?? "—"} ${deal.asset}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(width: 14),
                Text(
                  'Rate: ₹${deal.agreedRate ?? "—"}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
            const Divider(color: Color(0xFF22382C), height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ch: ${deal.channelId.isNotEmpty ? deal.channelId : "ticket"}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                Row(
                  children: [
                    if (deal.ticketUrl.isNotEmpty)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[300],
                          side: const BorderSide(color: Color(0xFF284235)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.open_in_new, size: 13),
                        label: const Text('Discord', style: TextStyle(fontSize: 11)),
                        onPressed: () => _launchUrl(deal.ticketUrl),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isUrgent ? const Color(0xFF9F2732) : const Color(0xFF1E3A2B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _showDealActions(context, deal),
                      child: const Text('Take Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status, bool isUrgent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isUrgent ? const Color(0xFF4C151B) : const Color(0xFF162A20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent ? Colors.redAccent : const Color(0xFF2E533F),
        ),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isUrgent ? const Color(0xFFFF9EA6) : const Color(0xFFA5E6C2),
        ),
      ),
    );
  }

  void _showDealActions(BuildContext context, Deal deal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1E17),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      deal.customerName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    _statusBadge(deal.status, deal.needsAttention),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Direction: ${deal.directionLabel} | Amount: ${deal.amount ?? "—"} ${deal.asset}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF284235)),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.handyman, color: Color(0xFF35D07F)),
                  title: const Text('Take Over Deal'),
                  subtitle: const Text('Switch from autonomous AI to manual operator control'),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    try {
                      await widget.state.takeOver(deal);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Successfully took over deal control')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to take over: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                ),
                if (deal.ticketUrl.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.open_in_new, color: Colors.blueAccent),
                    title: const Text('Open Discord Ticket'),
                    subtitle: Text(deal.ticketUrl, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _launchUrl(deal.ticketUrl);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
                  title: const Text('Mark Completed'),
                  subtitle: const Text('Finalize deal after customer confirmed receipt'),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    try {
                      await widget.state.complete(deal);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Deal marked as COMPLETED')),
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
                ListTile(
                  leading: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                  title: const Text('Reject / Cancel Deal'),
                  subtitle: const Text('Abort trade and issue refund if applicable'),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    _confirmReject(context, deal);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmReject(BuildContext context, Deal deal) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF14241C),
        title: const Text('Reject Deal?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This will terminate the exchange and notify the customer. Provide an internal or customer note:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g. Unverified payment source / customer requested cancellation',
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
            child: const Text('Reject Deal'),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await widget.state.reject(deal, reason: controller.text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Deal rejected')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
