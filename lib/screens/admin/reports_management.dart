
import 'package:flutter/material.dart';

import 'admin_constants.dart';
import 'admin_helpers.dart';

class ReportsManagement extends StatelessWidget {
  final ValueChanged<String> onNavigateToOrders;

  const ReportsManagement({
    super.key,
    required this.onNavigateToOrders,
  });

  // --------------------------------------------------
  // ORDER STATUS HELPERS
  // --------------------------------------------------

  String getStatus(Map<String, dynamic> order) {
    return (order['status'] ?? 'Pending')
        .toString()
        .trim()
        .toLowerCase();
  }

  String getOrderType(Map<String, dynamic> order) {
    return (order['orderType'] ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('-', '')
        .replaceAll(' ', '');
  }

  bool isDelivered(Map<String, dynamic> order) {
    return getStatus(order) == 'delivered';
  }

  bool isCompleted(Map<String, dynamic> order) {
    return getStatus(order) == 'completed';
  }

  bool isWalkIn(Map<String, dynamic> order) {
  return getOrderType(order) == 'walkin';
}

bool isWalkInCompleted(Map<String, dynamic> order) {
  return isCompleted(order);
}
  bool isIncludedInSales(Map<String, dynamic> order) {
    return isDelivered(order) || isCompleted(order);
  }

  bool isActiveOrder(Map<String, dynamic> order) {
    const activeStatuses = [
      'pending',
      'approved',
      'processing',
      'ready for pickup',
      'out for delivery',
    ];

    return activeStatuses.contains(getStatus(order));
  }

  int countStatus(
    List<Map<String, dynamic>> orders,
    String status,
  ) {
    return orders.where((order) {
      return getStatus(order) == status.toLowerCase();
    }).length;
  }

  int countWalkInOrders(List<Map<String, dynamic>> orders) {
    return orders.where(isWalkInCompleted).length;
  }

  // --------------------------------------------------
  // SALES COMPUTATIONS
  // --------------------------------------------------

  double getDeliveryFee(Map<String, dynamic> order) {
    return double.tryParse(
          order['deliveryFee']?.toString() ?? '',
        ) ??
        0;
  }

  double getProductSubtotal(Map<String, dynamic> order) {
    final subtotal = order['subtotal'];

    if (subtotal != null) {
      return double.tryParse(subtotal.toString()) ?? 0;
    }

    return getOrderTotal(order) - getDeliveryFee(order);
  }

  double calculateProductSales(
    List<Map<String, dynamic>> orders,
  ) {
    return orders.fold<double>(0, (total, order) {
      if (!isIncludedInSales(order)) return total;

      return total + getProductSubtotal(order);
    });
  }

  double calculateDeliveryFees(
    List<Map<String, dynamic>> orders,
  ) {
    return orders.fold<double>(0, (total, order) {
      if (!isDelivered(order)) return total;

      return total + getDeliveryFee(order);
    });
  }

  double calculateCustomerPayments(
    List<Map<String, dynamic>> orders,
  ) {
    return orders.fold<double>(0, (total, order) {
      if (!isIncludedInSales(order)) return total;

      return total + getOrderTotal(order);
    });
  }

  // --------------------------------------------------
  // BEST SELLERS
  // --------------------------------------------------

  Map<String, int> calculateBestSellers(
    List<Map<String, dynamic>> orders,
  ) {
    final Map<String, int> products = {};

    for (final order in orders) {
      if (!isIncludedInSales(order)) continue;

      for (final item in getOrderItems(order)) {
        final name = (item['name'] ?? 'Product').toString();

        final quantity = int.tryParse(
              item['quantity']?.toString() ?? '1',
            ) ??
            1;

        products[name] = (products[name] ?? 0) + quantity;
      }
    }

    return products;
  }

  // --------------------------------------------------
  // REPORT ORDER LIST
  // --------------------------------------------------

  void showOrdersList(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> orders,
  ) {
    final sortedOrders = [...orders];

    sortedOrders.sort((a, b) {
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.82,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF9F3),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(22),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),

              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: adminBrown,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${sortedOrders.length} orders found',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: sortedOrders.isEmpty
                    ? const Center(
                        child: Text('No orders found.'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(15),
                        itemCount: sortedOrders.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final order = sortedOrders[index];

                          final id =
                              order['id']?.toString() ?? 'Unknown';

                          final status =
                              (order['status'] ?? 'Pending').toString();

                          final orderType =
                              (order['orderType'] ?? 'N/A').toString();

                          final paymentMethod =
                              (order['paymentMethod'] ?? 'N/A').toString();

                          final total = getOrderTotal(order);

                          final products = getOrderProducts(order);

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.receipt_long_outlined,
                                      color: adminBrown,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        id,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: adminYellow.withValues(
                                          alpha: 0.25,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          20,
                                        ),
                                      ),
                                      child: Text(
                                        status,
                                        style: const TextStyle(
                                          color: adminBrown,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                Text(
                                  products,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$orderType • $paymentMethod',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '₱${total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: adminBrown,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  formatOrderDate(order['createdAt']),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------------------------------------------
  // REPORT SUMMARY CARD
  // --------------------------------------------------

  Widget reportCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: 165,
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: color, size: 29),
                    if (onTap != null)
                      Icon(
                        Icons.open_in_new,
                        color: Colors.grey.shade400,
                        size: 15,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: adminBrown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // SALES ROW
  // --------------------------------------------------

  Widget salesRow(
    String title,
    double amount, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: adminBrown,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
        Text(
          '₱${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: adminBrown,
            fontSize: bold ? 20 : 16,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // MAIN BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ordersReference.onValue,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load reports: ${snapshot.error}',
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final orders = getOrders(snapshot.data!.snapshot);

        // ORDER COUNTS

        final activeOrders = orders.where(isActiveOrder).toList();

        final pending = countStatus(orders, 'Pending');
        final approved = countStatus(orders, 'Approved');
        final processing = countStatus(orders, 'Processing');
        final readyForPickup = countStatus(orders, 'Ready for Pickup');
        final outForDelivery = countStatus(orders, 'Out for Delivery');

        final delivered = countStatus(orders, 'Delivered');
        final walkInCompleted = countWalkInOrders(orders);

        final rejected = countStatus(orders, 'Rejected');
        final cancelled = countStatus(orders, 'Cancelled');

        // SALES

        final productSales = calculateProductSales(orders);
        final deliveryFees = calculateDeliveryFees(orders);
        final customerPayments = calculateCustomerPayments(orders);

        // BEST SELLERS

        final bestSellers = calculateBestSellers(orders);

        final sortedProducts = bestSellers.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // FILTERED ORDER LISTS

        final deliveredOrders = orders.where(isDelivered).toList();

        final walkInOrders = orders.where(isWalkInCompleted).toList();

        final rejectedOrders = orders.where((order) {
          return getStatus(order) == 'rejected';
        }).toList();

        final cancelledOrders = orders.where((order) {
          return getStatus(order) == 'cancelled';
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sales and Order Reports',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: adminBrown,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Overview of your store performance.',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 20),

              // SALES SUMMARY

              Card(
                color: adminYellow,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sales Summary',
                        style: TextStyle(
                          color: adminBrown,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Includes delivered and completed walk-in orders.',
                        style: TextStyle(
                          color: adminBrown,
                          fontSize: 11,
                        ),
                      ),

                      const SizedBox(height: 18),

                      salesRow('Product Sales', productSales),

                      const SizedBox(height: 10),

                      salesRow('Delivery Fees', deliveryFees),

                      const Divider(
                        color: adminBrown,
                        height: 25,
                      ),

                      salesRow(
                        'Total Customer Payments',
                        customerPayments,
                        bold: true,
                      ),

                      const SizedBox(height: 12),

                      Text(
                        '$delivered delivered orders + '
                        '$walkInCompleted walk-in orders counted',
                        style: const TextStyle(
                          color: adminBrown,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: adminBrown,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Tap a card to view the corresponding orders.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  reportCard(
                    context,
                    'Active Orders',
                    activeOrders.length.toString(),
                    Icons.shopping_bag,
                    Colors.blue,
                    onTap: () {
                      onNavigateToOrders('All Active Orders');
                    },
                  ),

                  reportCard(
                    context,
                    'Pending',
                    pending.toString(),
                    Icons.hourglass_empty,
                    Colors.orange,
                    onTap: () {
                      onNavigateToOrders('Pending');
                    },
                  ),

                  reportCard(
                    context,
                    'Approved',
                    approved.toString(),
                    Icons.thumb_up,
                    Colors.green,
                    onTap: () {
                      onNavigateToOrders('Approved');
                    },
                  ),

                  reportCard(
                    context,
                    'Processing',
                    processing.toString(),
                    Icons.restaurant,
                    Colors.blueAccent,
                    onTap: () {
                      onNavigateToOrders('Processing');
                    },
                  ),

                  reportCard(
                    context,
                    'Ready for Pickup',
                    readyForPickup.toString(),
                    Icons.store,
                    Colors.deepPurple,
                    onTap: () {
                      onNavigateToOrders('Ready for Pickup');
                    },
                  ),

                  reportCard(
                    context,
                    'Out for Delivery',
                    outForDelivery.toString(),
                    Icons.delivery_dining,
                    Colors.teal,
                    onTap: () {
                      onNavigateToOrders('Out for Delivery');
                    },
                  ),

                  reportCard(
                    context,
                    'Delivered',
                    delivered.toString(),
                    Icons.check_circle,
                    Colors.green,
                    onTap: () {
                      showOrdersList(
                        context,
                        'Delivered Orders',
                        deliveredOrders,
                      );
                    },
                  ),

                  reportCard(
                    context,
                    'Walk-in / Completed',
                    walkInCompleted.toString(),
                    Icons.storefront,
                    Colors.deepPurple,
                    onTap: () {
                      showOrdersList(
                        context,
                        'Walk-in / Completed Orders',
                        walkInOrders,
                      );
                    },
                  ),

                  reportCard(
                    context,
                    'Rejected',
                    rejected.toString(),
                    Icons.cancel,
                    Colors.red,
                    onTap: () {
                      showOrdersList(
                        context,
                        'Rejected Orders',
                        rejectedOrders,
                      );
                    },
                  ),

                  reportCard(
                    context,
                    'Cancelled',
                    cancelled.toString(),
                    Icons.remove_shopping_cart,
                    Colors.grey,
                    onTap: () {
                      showOrdersList(
                        context,
                        'Cancelled Orders',
                        cancelledOrders,
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // BEST SELLERS

              const Text(
                'Best-Selling Products',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: adminBrown,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Based on delivered and completed orders.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 12),

              if (sortedProducts.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'No completed product sales yet.',
                    ),
                  ),
                )
              else
                ...sortedProducts.take(5).map((product) {
                  final maxQuantity = sortedProducts.first.value;

                  final progress = maxQuantity > 0
                      ? product.value / maxQuantity
                      : 0.0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 9),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  product.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              Text(
                                '${product.value} sold',
                                style: const TextStyle(
                                  color: adminBrown,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 9),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 9,
                              backgroundColor: Colors.grey.shade200,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                adminYellow,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 20),

              // REPORT INFORMATION

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: adminBrown,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'Reports update automatically whenever '
                          'order information changes in Firebase. '
                          'Delivered and completed orders are included '
                          'in product sales. Delivery fees are counted '
                          'only from delivered orders.',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
