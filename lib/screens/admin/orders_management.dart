
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import 'admin_constants.dart';
import 'admin_helpers.dart' as helpers;

class OrdersManagement extends StatefulWidget {
  final String initialStatus;

  const OrdersManagement({
    super.key,
    this.initialStatus = 'Pending',
  });

  @override
  State<OrdersManagement> createState() => _OrdersManagementState();
}

class _OrdersManagementState extends State<OrdersManagement> {
  late String selectedStatus;
  bool showStatusGuide = false;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.initialStatus;
  }

  @override
  void didUpdateWidget(covariant OrdersManagement oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialStatus != widget.initialStatus) {
      selectedStatus = widget.initialStatus;
    }
  }

  static const List<String> orderStatuses = [
    'All Active Orders',
    'Pending',
    'Approved',
    'Processing',
    'Ready for Pickup',
    'Out for Delivery',
  ];

  static const Map<String, IconData> statusIcons = {
    'All Active Orders': Icons.list_alt,
    'Pending': Icons.notifications_active_outlined,
    'Approved': Icons.check_circle_outline,
    'Processing': Icons.restaurant_outlined,
    'Ready for Pickup': Icons.shopping_bag_outlined,
    'Out for Delivery': Icons.delivery_dining,
  };

  // --------------------------------------------------
  // DEDUCT STOCK ONLY ONCE PER ORDER
  // --------------------------------------------------

  Future<void> deductStockOnce(
    String orderId,
    Map<String, dynamic> order,
  ) async {
    final firestore = FirebaseFirestore.instance;

    final deductionRef = firestore
        .collection('stockDeductionOrders')
        .doc(orderId);

    final items = helpers.getOrderItems(order);

    if (items.isEmpty) {
      throw Exception('This order has no product details.');
    }

    final Map<String, int> quantities = {};
    final Map<String, String> productNames = {};

    for (final item in items) {
      final productId = item['productId']?.toString() ?? '';

      final quantity = int.tryParse(
            item['quantity']?.toString() ?? '',
          ) ??
          0;

      if (productId.isEmpty || quantity <= 0) {
        throw Exception('Invalid product information in this order.');
      }

      quantities[productId] =
          (quantities[productId] ?? 0) + quantity;

      productNames[productId] =
          item['name']?.toString() ?? productId;
    }

    await firestore.runTransaction((transaction) async {
      final deductionSnapshot = await transaction.get(deductionRef);

      if (deductionSnapshot.exists) return;

      final productCollection = firestore.collection('products');
      final List<Map<String, dynamic>> updates = [];

      for (final entry in quantities.entries) {
        final productRef = productCollection.doc(entry.key);
        final productSnapshot = await transaction.get(productRef);

        if (!productSnapshot.exists) {
          throw Exception(
            '${productNames[entry.key]} was not found in Firestore.',
          );
        }

        final productData = productSnapshot.data() ?? {};
        final stockValue = productData['stock'];

        if (stockValue is! num) {
          throw Exception(
            'Stock for ${productNames[entry.key]} is missing or invalid.',
          );
        }

        final currentStock = stockValue.toInt();
        final orderedQuantity = entry.value;

        if (currentStock < orderedQuantity) {
          throw Exception(
            'Insufficient stock for ${productNames[entry.key]}. '
            'Available: $currentStock, ordered: $orderedQuantity.',
          );
        }

        updates.add({
          'ref': productRef,
          'newStock': currentStock - orderedQuantity,
        });
      }

      for (final update in updates) {
        transaction.update(
          update['ref'] as DocumentReference,
          {
            'stock': update['newStock'],
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      transaction.set(deductionRef, {
        'orderId': orderId,
        'deductedAt': FieldValue.serverTimestamp(),
        'status': 'Deducted',
        'items': quantities.entries.map((entry) {
          return {
            'productId': entry.key,
            'productName': productNames[entry.key],
            'quantity': entry.value,
          };
        }).toList(),
      });
    });
  }

  // --------------------------------------------------
  // UPDATE PAYMENT STATUS
  // --------------------------------------------------

  Future<void> updatePaymentStatus(
    BuildContext context,
    String orderId,
    String newPaymentStatus,
  ) async {
    try {
      final orderRef = helpers.ordersReference.child(orderId);
      final snapshot = await orderRef.get();

      if (!snapshot.exists || snapshot.value == null) {
        throw Exception('Order not found.');
      }

      final order = helpers.convertToMap(snapshot.value);

      final paymentMethod =
          (order['paymentMethod'] ?? '').toString();

      if (paymentMethod != 'GCash') {
        throw Exception(
          'Payment verification is only for GCash orders.',
        );
      }

      final receipt = (order['receiptUrl'] ?? '').toString();

      if (receipt.isEmpty) {
        throw Exception('This order has no payment screenshot.');
      }

      final currentPaymentStatus =
          (order['paymentStatus'] ?? 'Pending Verification').toString();

      if (currentPaymentStatus == newPaymentStatus) return;

      if (newPaymentStatus != 'Verified' &&
          newPaymentStatus != 'Rejected') {
        throw Exception('Invalid payment status.');
      }

      if (currentPaymentStatus == 'Verified' ||
          currentPaymentStatus == 'Rejected') {
        throw Exception('This payment has already been reviewed.');
      }

      await orderRef.update({
        'paymentStatus': newPaymentStatus,
        'paymentVerifiedAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newPaymentStatus == 'Verified'
                ? 'GCash payment successfully verified.'
                : 'GCash payment has been rejected.',
          ),
          backgroundColor: newPaymentStatus == 'Verified'
              ? Colors.green
              : Colors.red,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment update failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // --------------------------------------------------
  // AVAILABLE STATUS OPTIONS
  // --------------------------------------------------

  List<String> availableStatuses(
    String currentStatus,
    String orderType,
  ) {
    final isWalkIn = orderType == 'Walk-in';
    final isDelivery = orderType == 'Delivery';

    switch (currentStatus) {
      case 'Pending':
        return [
          'Pending',
          'Approved',
          'Rejected',
          'Cancelled',
        ];

      case 'Approved':
        return [
          'Approved',
          'Processing',
        ];

      case 'Processing':
        if (isWalkIn) {
          return [
            'Processing',
            'Completed',
          ];
        }

        return [
          'Processing',
          isDelivery ? 'Out for Delivery' : 'Ready for Pickup',
        ];

     case 'Ready for Pickup':
  return [
    'Ready for Pickup',
    'Completed',
  ];

case 'Out for Delivery':
  return [
    'Out for Delivery',
    'Delivered',
  ];

      case 'Delivered':
      case 'Completed':
      case 'Rejected':
      case 'Cancelled':
        return [currentStatus];

      default:
        return [currentStatus];
    }
  }

  // --------------------------------------------------
  // UPDATE ORDER STATUS
  // --------------------------------------------------

  Future<void> updateStatus(
  BuildContext context,
  String id,
  String newStatus,
) async {
  try {
    final orderRef = helpers.ordersReference.child(id);
    final orderSnapshot = await orderRef.get();

    if (!orderSnapshot.exists || orderSnapshot.value == null) {
      throw Exception('Order not found.');
    }

    final order = helpers.convertToMap(orderSnapshot.value);

    final currentStatus =
        (order['status'] ?? 'Pending').toString();

    final paymentMethod =
        (order['paymentMethod'] ?? 'Cash').toString();

    final paymentStatus =
        (order['paymentStatus'] ?? 'Not Required').toString();

    final orderType =
        (order['orderType'] ?? 'Pickup').toString();

    print('========== ORDER STATUS DEBUG ==========');
    print('Order ID: $id');
    print('Order Type: $orderType');
    print('Previous Status: $currentStatus');
    print('Selected Status: $newStatus');

    if (currentStatus == newStatus) return;

    final allowed = availableStatuses(currentStatus, orderType);

    if (!allowed.contains(newStatus)) {
      throw Exception(
        'Invalid status change: $currentStatus to $newStatus.',
      );
    }

    if (orderType == 'Walk-in' && paymentMethod != 'Cash') {
      throw Exception('Walk-in orders must use Cash payment.');
    }

    if (newStatus == 'Approved' &&
        paymentMethod == 'GCash' &&
        paymentStatus != 'Verified') {
      throw Exception(
        'Cannot approve this order yet. Verify the GCash payment first.',
      );
    }

    if (newStatus == 'Approved' && currentStatus == 'Pending') {
      await deductStockOnce(id, order);
    }

    await orderRef.update({
      'status': newStatus,
      'updatedAt': ServerValue.timestamp,
      if (newStatus == 'Delivered')
        'deliveredAt': ServerValue.timestamp,
      if (newStatus == 'Completed')
        'completedAt': ServerValue.timestamp,
      if (newStatus == 'Rejected')
        'rejectedAt': ServerValue.timestamp,
      if (newStatus == 'Cancelled')
        'cancelledAt': ServerValue.timestamp,
    });

    final updatedSnapshot = await orderRef.get();
    final updatedOrder =
        helpers.convertToMap(updatedSnapshot.value);

    print('Firebase Saved Status: ${updatedOrder['status']}');
    print('========================================');

    if (!context.mounted) return;

    String message;

    if (newStatus == 'Approved') {
      message = 'Order approved! Product stock has been updated.';
    } else if (newStatus == 'Delivered') {
      message = 'Order delivered! Sales report has been updated.';
    } else if (newStatus == 'Completed') {
      message = 'Pickup order completed!';
    } else {
      message = 'Order successfully updated to $newStatus.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Update failed: ${e.toString().replaceFirst('Exception: ', '')}',
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 6),
      ),
    );
  }
}
  // --------------------------------------------------
  // COLORS
  // --------------------------------------------------

  Color paymentStatusColor(String status) {
    switch (status) {
      case 'Verified':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Color orderStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Approved':
        return Colors.blue;
      case 'Processing':
        return Colors.deepPurple;
      case 'Ready for Pickup':
        return Colors.teal;
      case 'Out for Delivery':
        return Colors.indigo;
      default:
        return adminBrown;
    }
  }

  // --------------------------------------------------
  // SECTION LABEL
  // --------------------------------------------------

  Widget sectionLabel(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: adminBrown,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------
  // STATUS GUIDE
  // --------------------------------------------------

  Widget statusGuide() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: showStatusGuide,
          onExpansionChanged: (value) {
            setState(() {
              showStatusGuide = value;
            });
          },
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 2,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: const Icon(
            Icons.info_outline,
            color: adminBrown,
          ),
          title: const Text(
            'Order Status Guide',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: adminBrown,
            ),
          ),
          subtitle: const Text(
            'View order process and cancellation rules',
            style: TextStyle(fontSize: 11),
          ),
          children: const [
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pending → Approved → Processing'),
                  SizedBox(height: 5),
                  Text(
  'Pickup: Processing → Ready for Pickup → Completed',
),
                  SizedBox(height: 5),
                  Text(
                    'Delivery: Processing → Out for Delivery → Delivered',
                  ),
                  SizedBox(height: 5),
                  Text('Walk-in: Processing → Completed'),
                  Divider(height: 20),
                  Text(
                    'Customer Cancellation Policy',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text('• Cash: Can cancel while Pending only.'),
                  Text('• GCash: No customer cancellation.'),
                  Text('• Approved and later statuses: Cannot cancel.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // STATUS NAVIGATION
  // --------------------------------------------------

  Widget orderNavigation(
    List<Map<String, dynamic>> allOrders,
  ) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: orderStatuses.length,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final status = orderStatuses[index];

          final count = status == 'All Active Orders'
              ? allOrders.length
              : allOrders.where((order) {
                  return (order['status'] ?? 'Pending').toString() ==
                      status;
                }).length;

          final selected = selectedStatus == status;

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                selectedStatus = status;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 128,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: selected ? adminBrown : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? adminBrown : Colors.grey.shade200,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: adminBrown.withValues(alpha: 0.16),
                          blurRadius: 9,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        statusIcons[status],
                        size: 19,
                        color: selected ? Colors.white : adminBrown,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.18)
                              : adminYellow.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: selected ? Colors.white : adminBrown,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    status == 'Pending'
                        ? 'New Orders'
                        : status == 'All Active Orders'
                            ? 'All Active'
                            : status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : adminBrown,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --------------------------------------------------
  // EMPTY ORDERS
  // --------------------------------------------------

  Widget emptyOrdersView() {
    final label = selectedStatus == 'Pending'
        ? 'new orders'
        : selectedStatus == 'All Active Orders'
            ? 'active orders'
            : '$selectedStatus orders';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 38,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: adminYellow.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 36,
              color: adminBrown,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: adminBrown,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'There are no $label at the moment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // INFORMATION ROW
  // --------------------------------------------------

  Widget infoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // ORDER CARD
  // --------------------------------------------------

  Widget buildOrderCard(
    BuildContext context,
    Map<String, dynamic> order,
    List<Map<String, dynamic>> users,
  ) {
    final id = order['id']?.toString() ?? '';

    final storedStatus =
        (order['status'] ?? 'Pending').toString();

    final customer = helpers.findOrderCustomer(order, users);

    final customerName = helpers.getCustomerName(order, users);

    final customerEmail =
        customer?['email']?.toString() ??
            order['email']?.toString() ??
            'No email';

    final customerPhone =
        customer?['phone']?.toString() ??
            order['contactNumber']?.toString() ??
            'No phone number';

    final customerAddress =
        customer?['address']?.toString() ??
            order['deliveryAddress']?.toString() ??
            'No address';

    final total = helpers.getOrderTotal(order);

    final paymentMethod =
        (order['paymentMethod'] ?? 'Cash').toString();

    final isGcash = paymentMethod == 'GCash';

    final paymentStatus =
        (order['paymentStatus'] ??
                (isGcash
                    ? 'Pending Verification'
                    : 'Not Required'))
            .toString();

    final receiptUrl = (order['receiptUrl'] ?? '').toString();

    final orderType =
        (order['orderType'] ?? 'Pickup').toString();

    final statuses = availableStatuses(storedStatus, orderType);

    final canApprove = !isGcash || paymentStatus == 'Verified';

    final subtotal = double.tryParse(
          order['subtotal']?.toString() ?? '',
        ) ??
        total;

    final deliveryFee = double.tryParse(
          order['deliveryFee']?.toString() ?? '',
        ) ??
        0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ORDER HEADER

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: adminYellow.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: adminBrown,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ORDER REFERENCE',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 0.8,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        id.isEmpty ? 'Unknown Order' : id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: orderStatusColor(storedStatus).withValues(
                      alpha: 0.11,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    storedStatus,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: orderStatusColor(storedStatus),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 14),

            // CUSTOMER INFORMATION

            sectionLabel('CUSTOMER INFORMATION'),

            infoRow(Icons.person_outline, 'Name', customerName),
            infoRow(Icons.email_outlined, 'Email', customerEmail),
            infoRow(Icons.phone_outlined, 'Phone', customerPhone),
            infoRow(Icons.location_on_outlined, 'Address', customerAddress),

            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 14),

            // ORDER DETAILS

            sectionLabel('ORDER DETAILS'),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: adminCream,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                helpers.getOrderProducts(order),
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 10),

            infoRow(
              Icons.shopping_bag_outlined,
              'Order Type',
              orderType,
            ),

            if (orderType == 'Delivery')
              infoRow(
                Icons.map_outlined,
                'Location',
                (order['deliveryLocation'] ?? 'N/A').toString(),
              ),

            infoRow(
              Icons.calendar_today_outlined,
              'Order Date',
              helpers.formatOrderDate(order['createdAt']),
            ),

            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 14),

            // PAYMENT SUMMARY

            sectionLabel('PAYMENT SUMMARY'),

            infoRow(
              Icons.receipt_outlined,
              'Subtotal',
              '₱${subtotal.toStringAsFixed(2)}',
            ),

            if (orderType == 'Delivery')
              infoRow(
                Icons.delivery_dining,
                'Delivery Fee',
                '₱${deliveryFee.toStringAsFixed(2)}',
              ),

            const SizedBox(height: 9),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: adminYellow.withValues(alpha: 0.17),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL AMOUNT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: adminBrown,
                    ),
                  ),
                  Text(
                    '₱${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: adminBrown,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            infoRow(
              Icons.payments_outlined,
              'Payment',
              paymentMethod,
            ),

            // GCASH VERIFICATION

            if (isGcash) ...[
              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 14),

              sectionLabel('GCASH PAYMENT VERIFICATION'),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: paymentStatusColor(paymentStatus).withValues(
                    alpha: 0.07,
                  ),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: paymentStatusColor(paymentStatus).withValues(
                      alpha: 0.22,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      paymentStatus == 'Verified'
                          ? Icons.verified
                          : paymentStatus == 'Rejected'
                              ? Icons.cancel_outlined
                              : Icons.pending_outlined,
                      color: paymentStatusColor(paymentStatus),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        paymentStatus,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: paymentStatusColor(paymentStatus),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              if (receiptUrl.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      helpers.showPaymentReceipt(context, receiptUrl);
                    },
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: const Text('VIEW PAYMENT SCREENSHOT'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: adminBrown,
                      side: const BorderSide(color: adminBrown),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                )
              else
                const Text(
                  'No payment screenshot attached.',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                  ),
                ),

              if (paymentStatus != 'Verified' &&
                  paymentStatus != 'Rejected' &&
                  receiptUrl.isNotEmpty) ...[
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: id.isEmpty
                            ? null
                            : () {
                                updatePaymentStatus(
                                  context,
                                  id,
                                  'Verified',
                                );
                              },
                        icon: const Icon(
                          Icons.check_circle_outline,
                          size: 17,
                        ),
                        label: const Text('VERIFY'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: id.isEmpty
                            ? null
                            : () {
                                updatePaymentStatus(
                                  context,
                                  id,
                                  'Rejected',
                                );
                              },
                        icon: const Icon(Icons.close, size: 17),
                        label: const Text('REJECT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (paymentStatus == 'Rejected')
                const Padding(
                  padding: EdgeInsets.only(top: 9),
                  child: Text(
                    'Payment was rejected. The customer needs to submit a valid payment screenshot.',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                    ),
                  ),
                ),

              if (paymentStatus == 'Verified')
                const Padding(
                  padding: EdgeInsets.only(top: 9),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Payment verified. This order can now be approved.',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 14),

            // ORDER ACTIONS

            sectionLabel('ORDER ACTIONS'),

            DropdownButtonFormField<String>(
              initialValue: statuses.contains(storedStatus)
                  ? storedStatus
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Update Order Status',
                prefixIcon: const Icon(
                  Icons.sync_alt,
                  color: adminBrown,
                ),
                filled: true,
                fillColor: adminCream,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: BorderSide.none,
                ),
              ),
              items: statuses.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(
                    status,
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null || id.isEmpty) return;

                if (value == 'Approved' && !canApprove) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Verify GCash payment before approving this order.',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                updateStatus(context, id, value);
              },
            ),

            if (storedStatus == 'Pending') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: id.isEmpty || !canApprove
                      ? null
                      : () {
                          updateStatus(context, id, 'Approved');
                        },
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    isGcash && !canApprove
                        ? 'VERIFY PAYMENT FIRST'
                        : 'APPROVE ORDER',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canApprove ? Colors.green.shade700 : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // MAIN BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: helpers.usersReference.onValue,
      builder: (context, usersSnapshot) {
        return StreamBuilder<DatabaseEvent>(
          stream: helpers.ordersReference.onValue,
          builder: (context, ordersSnapshot) {
            if (ordersSnapshot.hasError || usersSnapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Error loading data:\n'
                    '${ordersSnapshot.error ?? usersSnapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (!ordersSnapshot.hasData || !usersSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final allOrders = helpers.getOrders(
              ordersSnapshot.data!.snapshot,
            );

            final users = helpers.getUsers(
              usersSnapshot.data!.snapshot,
            );

            // Only active orders appear here.
            final activeOrders = allOrders.where((order) {
              final status =
                  (order['status'] ?? 'Pending').toString();

              return orderStatuses.contains(status) &&
                  status != 'All Active Orders';
            }).toList();

            // Latest orders first.
            activeOrders.sort((a, b) {
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

            final filteredOrders = selectedStatus == 'All Active Orders'
                ? activeOrders
                : activeOrders.where((order) {
                    return (order['status'] ?? 'Pending').toString() ==
                        selectedStatus;
                  }).toList();

            return CustomScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                // HEADER

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Orders Management',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: adminBrown,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Manage and monitor customer orders.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: adminYellow.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    activeOrders.length.toString(),
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      color: adminBrown,
                                    ),
                                  ),
                                  const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: adminBrown,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 17),

                        statusGuide(),

                        sectionLabel(
                          'ORDER STATUS',
                          subtitle: 'Swipe horizontally to view each category.',
                        ),

                        orderNavigation(activeOrders),

                        const SizedBox(height: 18),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedStatus == 'Pending'
                                    ? 'New Orders'
                                    : selectedStatus,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: adminBrown,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: adminYellow.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${filteredOrders.length} orders',
                                style: const TextStyle(
                                  color: adminBrown,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // ORDER LIST

                if (filteredOrders.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: emptyOrdersView(),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return buildOrderCard(
                            context,
                            filteredOrders[index],
                            users,
                          );
                        },
                        childCount: filteredOrders.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
