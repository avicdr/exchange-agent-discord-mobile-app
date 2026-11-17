import 'dart:async';
import 'dart:convert';

import 'package:exchange_sentinel/alarm_service.dart';
import 'package:exchange_sentinel/api_client.dart';
import 'package:exchange_sentinel/models.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AppState extends ChangeNotifier {
  ApiClient? _api;
  WebSocketChannel? _socket;
  StreamSubscription<dynamic>? _socketSubscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  Overview? overview;
  List<Deal> deals = const [];
  final List<AlertEvent> alerts = [];
  bool connected = false;
  bool isReconnecting = false;
  bool loading = true;
  String? error;
  bool isAlarmActive = false;

  String baseUrl = 'http://10.0.2.2:8000';
  String token = 'development-token-change-me';
  int lastSequence = 0;
  String providerStatus = 'UNKNOWN'; // LIVE, SIMULATED, BLOCKED, UNKNOWN
  String providerReason = '';

  List<Deal> get activeDeals => deals.where((deal) => !deal.isTerminal).toList();
  List<Deal> get pendingApprovals => deals.where((deal) => deal.isSettlementApprovalPending).toList();
  List<Deal> get history => deals.where((deal) => deal.isTerminal).toList();
  AlertEvent? get currentAlert => alerts.isEmpty ? null : alerts.first;

  bool get isAgentPaused => overview?.paused ?? false;

  Future<void> initialize() async {
    loading = true;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      baseUrl = preferences.getString('backend_url') ?? baseUrl;
      token = preferences.getString('api_token') ?? token;
      lastSequence = preferences.getInt('last_sequence') ?? 0;
    } catch (_) {}

    _configure();
    await refresh();
    _connect();
  }

  void _configure() {
    _api?.close();
    _api = ApiClient(baseUrl: baseUrl, token: token);
  }

  Future<void> refresh() async {
    if (_api == null) return;
    try {
      final results = await Future.wait([
        _api!.overview(),
        _api!.deals(),
        _api!.notifications(),
        _api!.providerStatus(),
      ]);
      overview = results[0] as Overview;
      deals = results[1] as List<Deal>;
      final pendingAlerts = results[2] as List<AlertEvent>;
      final provider = results[3] as ProviderInfo;

      for (final alert in pendingAlerts) {
        _queueAlert(alert);
      }
      providerStatus = provider.status;
      providerReason = provider.reason;
      error = null;
    } catch (reason) {
      error = reason.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _connect() async {
    _reconnectTimer?.cancel();
    _socketSubscription?.cancel();
    connected = false;
    try {
      _socket?.sink.close();
    } catch (_) {}

    final wsUrl = baseUrl.replaceFirst(RegExp('^http'), 'ws');
    final uri = Uri.parse('$wsUrl/ws?token=${Uri.encodeQueryComponent(token)}&after=$lastSequence');

    try {
      _socket = WebSocketChannel.connect(uri);
      await _socket!.ready.timeout(const Duration(seconds: 10));
      _socketSubscription = _socket!.stream.listen(
        _onSocketEvent,
        onError: (err) {
          debugPrint('WebSocket error: $err');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('WebSocket closed, scheduling reconnect');
          _scheduleReconnect();
        },
      );
      connected = true;
      isReconnecting = false;
      _startHeartbeat();
      notifyListeners();
    } catch (err) {
      debugPrint('Connection attempt failed: $err');
      _scheduleReconnect();
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      try {
        _socket?.sink.add(jsonEncode({'type': 'ping', 'sequence': lastSequence}));
      } catch (_) {
        _scheduleReconnect();
      }
    });
  }

  Future<void> _onSocketEvent(dynamic raw) async {
    try {
      final event = jsonDecode(raw as String) as Map<String, dynamic>;
      final sequence = event['sequence'] as int?;
      if (sequence != null && sequence <= lastSequence) return;
      if (sequence != null) {
        lastSequence = sequence;
        final preferences = await SharedPreferences.getInstance();
        await preferences.setInt('last_sequence', sequence);
      }

      final type = event['type'] as String?;
      if (type == 'urgent_alert' || type == 'notification') {
        _queueAlert(AlertEvent.fromJson(event));
      } else if (type == 'agent_status') {
        final payload = (event['payload'] as Map?)?.cast<String, dynamic>() ?? event;
        final paused = payload['paused'] as bool? ?? false;
        if (overview != null) {
          overview = Overview(
            online: overview!.online,
            paused: paused,
            active: overview!.active,
            completed: overview!.completed,
            attention: overview!.attention,
            vouches: overview!.vouches,
            profit: overview!.profit,
            discordMode: overview!.discordMode,
            connectedServers: overview!.connectedServers,
            monitoredChannels: overview!.monitoredChannels,
            providerStatus: overview!.providerStatus,
          );
        }
      } else if (type == 'provider_status') {
        final payload = (event['payload'] as Map?)?.cast<String, dynamic>() ?? event;
        final provider = ProviderInfo.fromJson(payload);
        providerStatus = provider.status;
        providerReason = provider.reason;
      }

      if (type != 'pong' && type != 'heartbeat') {
        await refresh();
      }
    } catch (e) {
      debugPrint('Error processing socket event: $e');
    }
  }

  void _queueAlert(AlertEvent alert) {
    if (alerts.any((existing) => existing.id == alert.id)) return;
    alerts.insert(0, alert);
    isAlarmActive = true;
    AlarmService.start(title: alert.title, body: alert.body).catchError((_) {});
    notifyListeners();
  }

  void _scheduleReconnect() {
    if (!connected && isReconnecting) return;
    connected = false;
    isReconnecting = true;
    notifyListeners();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!connected) {
        _connect();
      }
    });
  }

  Future<void> stopAlarm() async {
    isAlarmActive = false;
    await AlarmService.stop().catchError((_) {});
    notifyListeners();
  }

  Future<void> acknowledgeAlert(String alertId) async {
    if (_api == null) return;
    try {
      await _api!.acknowledge(alertId);
      alerts.removeWhere((item) => item.id == alertId);
      if (alerts.isEmpty) {
        await stopAlarm();
      }
      notifyListeners();
    } catch (e) {
      error = 'Failed to acknowledge alert: $e';
      notifyListeners();
    }
  }

  Future<void> dismissAlert(String alertId) async {
    if (_api == null) return;
    try {
      await _api!.dismiss(alertId);
      alerts.removeWhere((item) => item.id == alertId);
      if (alerts.isEmpty) {
        await stopAlarm();
      }
      notifyListeners();
    } catch (e) {
      error = 'Failed to dismiss alert: $e';
      notifyListeners();
    }
  }

  Future<void> acknowledgeCurrent() async {
    final alert = currentAlert;
    if (alert == null) return;
    await acknowledgeAlert(alert.id);
  }

  Future<void> dismissCurrent() async {
    final alert = currentAlert;
    if (alert == null) return;
    await dismissAlert(alert.id);
  }

  Future<void> saveConnection(String url, String nextToken) async {
    baseUrl = url.trim().replaceFirst(RegExp(r'/$'), '');
    token = nextToken.trim();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('backend_url', baseUrl);
      await preferences.setString('api_token', token);
    } catch (_) {}

    _configure();
    await refresh();
    await _connect();
  }

  Future<void> takeOver(Deal deal) async {
    if (_api == null) return;
    try {
      await _api!.action(deal.id, 'TAKE_OVER', _id(deal.id));
      await refresh();
    } catch (e) {
      error = 'Take over failed: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> approveI2c(
    Deal deal, {
    required String reference,
    required String note,
    required String destination,
  }) async {
    if (_api == null) return;
    try {
      await _api!.action(
        deal.id,
        'APPROVE_SETTLEMENT',
        _id(deal.id),
        reference: reference,
        note: note,
        destination: destination,
        verified: true,
      );
      await acknowledgeMatchingAlert(deal.id);
      await refresh();
    } catch (e) {
      error = 'Settlement approval failed: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> confirmCrypto(
    Deal deal, {
    required String transactionHash,
    required String note,
    String? destination,
  }) async {
    if (_api == null) return;
    try {
      await _api!.action(
        deal.id,
        'CONFIRM_CRYPTO_RECEIPT',
        _id(deal.id),
        reference: transactionHash,
        note: note,
        destination: destination,
        verified: true,
      );
      await acknowledgeMatchingAlert(deal.id);
      await refresh();
    } catch (e) {
      error = 'Crypto confirmation failed: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> complete(Deal deal) async {
    if (_api == null) return;
    try {
      await _api!.action(deal.id, 'MARK_COMPLETED', _id(deal.id));
      await refresh();
    } catch (e) {
      error = 'Mark completed failed: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> reject(Deal deal, {String? reason}) async {
    if (_api == null) return;
    try {
      await _api!.action(
        deal.id,
        'REJECT_DEAL',
        _id(deal.id),
        note: reason ?? 'Rejected by mobile operator',
      );
      await acknowledgeMatchingAlert(deal.id);
      await refresh();
    } catch (e) {
      error = 'Reject deal failed: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> acknowledgeMatchingAlert(String dealId) async {
    final matching = alerts.where((a) => a.deal.id == dealId).toList();
    for (final a in matching) {
      await acknowledgeAlert(a.id);
    }
  }

  Future<void> pause() async {
    if (_api == null) return;
    try {
      await _api!.control('pause');
      await refresh();
    } catch (e) {
      error = 'Pause failed: $e';
      notifyListeners();
    }
  }

  Future<void> resume() async {
    if (_api == null) return;
    try {
      await _api!.control('resume');
      await refresh();
    } catch (e) {
      error = 'Resume failed: $e';
      notifyListeners();
    }
  }

  Future<void> emergencyStop() async {
    if (_api == null) return;
    try {
      await _api!.control('emergency-stop');
      await refresh();
    } catch (e) {
      error = 'Emergency stop failed: $e';
      notifyListeners();
    }
  }

  Future<void> control(String action) async {
    if (_api == null) return;
    try {
      await _api!.control(action);
      await refresh();
    } catch (e) {
      error = 'Control action failed: $e';
      notifyListeners();
    }
  }

  String _id(String prefix) =>
      '${DateTime.now().microsecondsSinceEpoch}-$prefix-${DateTime.now().millisecondsSinceEpoch % 1000}';

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _socketSubscription?.cancel();
    try {
      _socket?.sink.close();
    } catch (_) {}
    _api?.close();
    super.dispose();
  }
}
