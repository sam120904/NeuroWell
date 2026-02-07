import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'widgets/dashboard_sidebar.dart';
import 'widgets/dashboard_header.dart';
import '../monitoring/live_view.dart';
import 'patient_list.dart';
import 'session_history.dart';
import 'dashboard_overview.dart';

class DashboardLayout extends StatefulWidget {
  const DashboardLayout({super.key});

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  String _activeRoute = '/dashboard';

  void _navigate(String route) {
    setState(() {
      _activeRoute = route;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      drawer: !isDesktop
          ? Drawer(
              child: DashboardSidebar(
                activeRoute: _activeRoute,
                onNavigate: (route) {
                  _navigate(route);
                  Navigator.pop(context); // Close drawer
                },
              ),
            )
          : null,
      body: Row(
        children: [
          if (isDesktop)
            DashboardSidebar(
              activeRoute: _activeRoute,
              onNavigate: _navigate,
            ),
          Expanded(
            child: Column(
              children: [
                DashboardHeader(
                  title: _getTitle(_activeRoute),
                  subtitle: _getSubtitle(_activeRoute),
                  onMenuPressed: !isDesktop
                      ? () => Scaffold.of(context).openDrawer()
                      : null,
                ),
                Expanded(
                  child: _getContent(_activeRoute),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTitle(String route) {
    switch (route) {
      case '/dashboard': return 'Overview';
      case '/live': return 'Patient Monitoring';
      case '/patients': return 'Patients';
      case '/history': return 'Session History';
      default: return 'Dashboard';
    }
  }

  String _getSubtitle(String route) {
    switch (route) {
      case '/live': return 'Real-time biofeedback stream & AI analysis';
      case '/patients': return 'Manage your patient roster';
      case '/history': return 'Review past sessions';
      default: 
        final user = FirebaseAuth.instance.currentUser;
        final name = user?.displayName ?? 'User';
        return 'Welcome back, $name';
    }
  }

  Widget _getContent(String route) {
    switch (route) {
      case '/dashboard':
        return const DashboardOverview(); // Use the widget
      case '/live':
        return const LiveMonitoringView();
      case '/patients':
         return const PatientList();
      case '/history':
         return const SessionHistory();
      default:
        return const Center(child: Text('Dashboard Overview Placeholder'));
    }
  }
}
