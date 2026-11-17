enum DealDirection { i2c, c2i }

class ProviderInfo {
  const ProviderInfo({
    required this.status,
    required this.reason,
    required this.isLive,
    required this.isSimulated,
    required this.isBlocked,
  });

  factory ProviderInfo.fromJson(Map<String, dynamic> json) => ProviderInfo(
        status: (json['status'] ?? json['provider_status']) as String? ?? 'BLOCKED',
        reason: (json['reason'] ?? json['provider_reason']) as String? ?? '',
        isLive: json['is_live'] as bool? ?? false,
        isSimulated: json['is_simulated'] as bool? ?? false,
        isBlocked: json['is_blocked'] as bool? ?? false,
      );

  final String status;
  final String reason;
  final bool isLive;
  final bool isSimulated;
  final bool isBlocked;
}

class Deal {
  const Deal({
    required this.id,
    required this.customerName,
    required this.serverId,
    required this.channelId,
    required this.ticketUrl,
    required this.direction,
    required this.asset,
    required this.network,
    required this.amount,
    required this.agreedRate,
    required this.expectedProfit,
    required this.status,
    required this.settlementReference,
    required this.settlementSimulated,
    this.destinationAddress,
    this.depositAddress,
    this.paymentReference,
    this.customerId,
    this.createdAt,
    this.updatedAt,
  });

  factory Deal.fromJson(Map<String, dynamic> json) => Deal(
        id: json['id'] as String,
        customerName: json['customer_name'] as String? ?? 'Unknown Customer',
        customerId: json['customer_id'] as String?,
        serverId: json['server_id'] as String? ?? '',
        channelId: json['channel_id'] as String? ?? '',
        ticketUrl: json['ticket_url'] as String? ?? '',
        direction: json['direction'] == 'C2I' ? DealDirection.c2i : DealDirection.i2c,
        asset: json['asset'] as String? ?? 'USDT',
        network: json['network'] as String? ?? 'Polygon',
        amount: json['amount']?.toString(),
        agreedRate: json['agreed_rate']?.toString(),
        expectedProfit: json['expected_profit']?.toString() ?? '0',
        status: json['status'] as String? ?? 'DISCOVERED',
        settlementReference: json['settlement_reference'] as String?,
        settlementSimulated: json['settlement_simulated'] as bool? ?? false,
        destinationAddress: (json['destination_address'] ?? json['settlement_destination']) as String?,
        depositAddress: json['deposit_address'] as String?,
        paymentReference: (json['payment_reference'] ?? json['settlement_reference']) as String?,
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
        updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      );

  final String id;
  final String customerName;
  final String? customerId;
  final String serverId;
  final String channelId;
  final String ticketUrl;
  final DealDirection direction;
  final String asset;
  final String? network;
  final String? amount;
  final String? agreedRate;
  final String expectedProfit;
  final String status;
  final String? settlementReference;
  final bool settlementSimulated;
  final String? destinationAddress;
  final String? depositAddress;
  final String? paymentReference;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isTerminal => const {'COMPLETED', 'CANCELLED', 'EXPIRED', 'DISPUTED', 'REFUNDED'}.contains(status);
  bool get needsAttention => status == 'AWAITING_HUMAN' || status == 'HUMAN_TAKEOVER' || status == 'SETTLEMENT_APPROVAL_PENDING';
  bool get isSettlementApprovalPending =>
      status == 'SETTLEMENT_PENDING' ||
      status == 'AWAITING_HUMAN' ||
      status == 'SETTLEMENT_APPROVAL_PENDING' ||
      status == 'PAYMENT_VERIFIED';
  String get directionLabel => direction == DealDirection.i2c ? 'INR → $asset' : '$asset → INR';
  String get formattedStatus => status.replaceAll('_', ' ');
}

class AlertEvent {
  const AlertEvent({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.deal,
    this.createdAt,
    this.acknowledged = false,
  });

  factory AlertEvent.fromJson(Map<String, dynamic> json) {
    final payload = (json['payload'] as Map?)?.cast<String, dynamic>() ?? json;
    final dealMap = (payload['deal'] ?? (json['payload'] as Map?)?['deal']) as Map<String, dynamic>?;
    final deal = dealMap != null
        ? Deal.fromJson(dealMap)
        : Deal(
            id: (payload['deal_id'] ?? json['deal_id'] ?? 'unknown') as String,
            customerName: (payload['customer_name'] ?? 'Unknown Customer') as String,
            serverId: '',
            channelId: '',
            ticketUrl: '',
            direction: DealDirection.i2c,
            asset: 'USDT',
            network: 'Polygon',
            amount: '0',
            agreedRate: '0',
            expectedProfit: '0',
            status: 'AWAITING_HUMAN',
            settlementReference: null,
            settlementSimulated: false,
          );

    return AlertEvent(
      id: (payload['notification_id'] ?? json['id'] ?? 'alert-${DateTime.now().millisecondsSinceEpoch}') as String,
      kind: (payload['kind'] ?? json['kind'] ?? 'ACTION') as String,
      title: (payload['title'] ?? json['title'] ?? 'Deal needs attention') as String,
      body: (payload['body'] ?? json['body'] ?? '') as String,
      deal: deal,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : DateTime.now(),
      acknowledged: json['acknowledged'] as bool? ?? false,
    );
  }

  final String id;
  final String kind;
  final String title;
  final String body;
  final Deal deal;
  final DateTime? createdAt;
  final bool acknowledged;
}

class Overview {
  const Overview({
    required this.online,
    required this.paused,
    required this.active,
    required this.completed,
    required this.attention,
    required this.vouches,
    required this.profit,
    this.discordMode = 'official_bot',
    this.connectedServers = 0,
    this.monitoredChannels = 0,
    this.providerStatus = 'LIVE',
  });

  factory Overview.fromJson(Map<String, dynamic> json) => Overview(
        online: json['agent_online'] as bool? ?? false,
        paused: json['agent_paused'] as bool? ?? false,
        active: json['active_deals'] as int? ?? 0,
        completed: json['completed_deals'] as int? ?? 0,
        attention: json['attention_required'] as int? ?? 0,
        vouches: json['verified_vouches'] as int? ?? 0,
        profit: json['estimated_profit_inr']?.toString() ?? '0',
        discordMode: json['discord_mode'] as String? ?? 'official_bot',
        connectedServers: json['connected_discord_servers'] as int? ?? 0,
        monitoredChannels: json['monitored_channels'] as int? ?? 0,
        providerStatus: (json['provider_status'] as String?) ??
            ((json['agent_online'] as bool? ?? false) ? 'LIVE' : 'SIMULATED'),
      );

  final bool online;
  final bool paused;
  final int active;
  final int completed;
  final int attention;
  final int vouches;
  final String profit;
  final String discordMode;
  final int connectedServers;
  final int monitoredChannels;
  final String providerStatus;
}
