import 'package:exchange_sentinel/app_state.dart';
import 'package:exchange_sentinel/screens/active_tickets_screen.dart';
import 'package:exchange_sentinel/screens/emergency_pause_screen.dart';
import 'package:exchange_sentinel/screens/live_alerts_screen.dart';
import 'package:exchange_sentinel/screens/overview_screen.dart';
import 'package:exchange_sentinel/screens/transaction_approvals_screen.dart';
import 'package:material_ui/material_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.initialize();
  runApp(ExchangeSentinelApp(appState: appState));
}

class ExchangeSentinelApp extends StatelessWidget {
  const ExchangeSentinelApp({super.key, required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exchange Sentinel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF07110D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF35D07F),
          secondary: Color(0xFF7DE6A7),
          surface: Color(0xFF0F1E17),
          error: Color(0xFFF05B63),
          onPrimary: Color(0xFF07110D),
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF07110D),
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0A1611),
          selectedItemColor: Color(0xFF35D07F),
          unselectedItemColor: Color(0xFF8B9E94),
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
        ),
        useMaterial3: true,
      ),
      home: MainShell(state: appState),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.state});
  final AppState state;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final state = widget.state;
        final pendingApprovalsCount = state.pendingApprovals.length;
        final alertsCount = state.alerts.length;

        final screens = [
          ActiveTicketsScreen(state: state),
          TransactionApprovalsScreen(state: state),
          EmergencyPauseScreen(state: state),
          LiveAlertsScreen(state: state),
          OverviewScreen(state: state),
        ];

        return Scaffold(
          body: Column(
            children: [
              if (!state.connected) _buildOfflineBanner(state),
              if (state.error != null && !state.connected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  color: const Color(0xFF4C151B),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 14, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.error!,
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(child: screens[_currentIndex]),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.confirmation_number_outlined),
                activeIcon: Icon(Icons.confirmation_number),
                label: 'Tickets',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: pendingApprovalsCount > 0,
                  label: Text('$pendingApprovalsCount'),
                  backgroundColor: const Color(0xFFF5B942),
                  textColor: Colors.black,
                  child: const Icon(Icons.gavel_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: pendingApprovalsCount > 0,
                  label: Text('$pendingApprovalsCount'),
                  backgroundColor: const Color(0xFFF5B942),
                  textColor: Colors.black,
                  child: const Icon(Icons.gavel),
                ),
                label: 'Approvals',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: state.isAgentPaused,
                  backgroundColor: Colors.redAccent,
                  smallSize: 8,
                  child: const Icon(Icons.pause_circle_outline),
                ),
                activeIcon: const Icon(Icons.pause_circle_filled),
                label: 'Emergency',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: alertsCount > 0,
                  label: Text('$alertsCount'),
                  backgroundColor: Colors.redAccent,
                  child: const Icon(Icons.notifications_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: alertsCount > 0,
                  label: Text('$alertsCount'),
                  backgroundColor: Colors.redAccent,
                  child: const Icon(Icons.notifications),
                ),
                label: 'Alerts',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Overview',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfflineBanner(AppState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: state.isReconnecting ? const Color(0xFF3B2B11) : const Color(0xFF381519),
      child: Row(
        children: [
          Icon(
            state.isReconnecting ? Icons.sync : Icons.cloud_off,
            size: 16,
            color: state.isReconnecting ? Colors.amber : Colors.redAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.isReconnecting
                  ? 'Reconnecting to Exchange Sentinel WebSocket...'
                  : 'Backend Disconnected - Automatic retry in progress',
              style: TextStyle(
                fontSize: 12,
                color: state.isReconnecting ? Colors.amber[100] : Colors.red[100],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
