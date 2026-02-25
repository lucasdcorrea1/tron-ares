import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/tron_sidebar.dart';

class TronShellPage extends StatelessWidget {
  final Widget child;

  const TronShellPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final isWide = MediaQuery.of(context).size.width > 800;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            TronSidebar(currentPath: location),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Mobile: drawer-based navigation
    return Scaffold(
      body: child,
      drawer: Drawer(
        child: TronSidebar(currentPath: location),
      ),
    );
  }
}
