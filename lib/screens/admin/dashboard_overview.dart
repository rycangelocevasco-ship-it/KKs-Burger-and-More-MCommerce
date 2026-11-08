import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import 'admin_constants.dart';
import 'admin_helpers.dart' as helpers;

class DashboardOverview extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  final ValueChanged<String> onRecentOrderTap;

  const DashboardOverview({
    super.key,
    required this.onNavigate,
    required this.onRecentOrderTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .snapshots(),
      builder: (context, productsSnapshot) {
        return StreamBuilder<DatabaseEvent>(
          stream: helpers.usersReference.onValue,
          builder: (context, usersSnapshot) {
            return StreamBuilder<DatabaseEvent>(
              stream: helpers.ordersReference.onValue,
              builder: (context, ordersSnapshot) {
                if (productsSnapshot.hasError ||
                    usersSnapshot.hasError ||
                    ordersSnapshot.hasError) {
                  return const Center(
                    child: Text('Unable to load dashboard data.'),
                  );
                }

                if (!productsSnapshot.hasData ||
                    !usersSnapshot.hasData ||
                    !ordersSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final products = productsSnapshot.data!.docs;

                final users = helpers.getUsers(
                  usersSnapshot.data!.snapshot,
                );

                final orders = helpers.getOrders(
                  ordersSnapshot.data!.snapshot,
                );

                final sales = orders.fold<double>(
                  0,
                  (total, order) {
                    final status = (order['status'] ?? 'Pending')
                        .toString()
                        .trim()
                        .toLowerCase();

                    if (status == 'delivered' ||
                        status == 'completed') {
                      return total + helpers.getOrderTotal(order);
                    }

                    return total;
                  },
                );

                final recentOrders = [...orders];

                recentOrders.sort((a, b) {
                  final aDate = int.tryParse(
                        a['createdAt']?.toString() ?? '',
                      ) ??
                      0;

                  final bDate = int.tryParse(
                        b['createdAt']?.toString() ?? '',
                      ) ??
                      0;

                  return bDate.compareTo(aDate);
                });

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome, Admin!',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: adminBrown,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "Here's what's happening in your store.",
                      ),
                      const SizedBox(height: 22),

                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _statCard(
                            'Products',
                            products.length.toString(),
                            Icons.fastfood,
                            Colors.orange,
                            onTap: () => onNavigate(1),
                          ),
                          _statCard(
                            'Orders',
                            orders.length.toString(),
                            Icons.shopping_bag,
                            Colors.blue,
                            onTap: () =>
                                onRecentOrderTap('All Active Orders'),
                          ),
                          _statCard(
                            'Customers',
                            users.length.toString(),
                            Icons.people,
                            Colors.green,
                            onTap: () => onNavigate(3),
                          ),
                          _statCard(
                            'Delivered Sales',
                            '₱${sales.toStringAsFixed(2)}',
                            Icons.payments,
                            Colors.purple,
                            onTap: () => onNavigate(4),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'Recent Orders',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Tap an order to open Orders Management.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (recentOrders.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('No orders yet.'),
                          ),
                        )
                      else
                        ...recentOrders.take(5).map((order) {
                          final status =
                              (order['status'] ?? 'Pending').toString();

                          const activeStatuses = [
                            'Pending',
                            'Approved',
                            'Processing',
                            'Ready for Pickup',
                            'Out for Delivery',
                          ];

                          final destination =
                              activeStatuses.contains(status)
                                  ? status
                                  : 'All Active Orders';

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 9),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              onTap: () {
                                onRecentOrderTap(destination);
                              },
                              leading: const CircleAvatar(
                                backgroundColor: adminYellow,
                                child: Icon(
                                  Icons.receipt_long,
                                  color: adminBrown,
                                ),
                              ),
                              title: Text(
                                helpers.getCustomerName(order, users),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '₱${helpers.getOrderTotal(order).toStringAsFixed(2)} • $status',
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: adminBrown,
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 165,
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: color, size: 30),
                    Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: adminBrown,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}