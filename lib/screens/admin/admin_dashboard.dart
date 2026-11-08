import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_constants.dart';
import 'dashboard_overview.dart';
import 'product_management.dart';
import 'orders_management.dart';
import 'users_management.dart';
import 'reports_management.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;
  String ordersInitialStatus = 'Pending';

  final List<String> titles = [
    'Dashboard',
    'Product Management',
    'Orders Management',
    'Users Management',
    'Reports',
  ];

  void navigateToPage(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void navigateToOrders(String status) {
    setState(() {
      ordersInitialStatus = status;
      selectedIndex = 2;
    });
  }

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: adminYellow,
              foregroundColor: adminBrown,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardOverview(
        onNavigate: navigateToPage,
        onRecentOrderTap: navigateToOrders,
      ),
      const ProductManagement(),
      OrdersManagement(
        key: const ValueKey('orders-management'),
        initialStatus: ordersInitialStatus,
      ),
      const UsersManagement(),
      ReportsManagement(
        onNavigateToOrders: navigateToOrders,
      ),
    ];

    return Scaffold(
      backgroundColor: adminCream,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          titles[selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: adminYellow,
        foregroundColor: adminBrown,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: navigateToPage,
        backgroundColor: Colors.white,
        indicatorColor: adminYellow.withValues(alpha: 0.4),
        elevation: 3,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.fastfood_outlined),
            selectedIcon: Icon(Icons.fastfood),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}