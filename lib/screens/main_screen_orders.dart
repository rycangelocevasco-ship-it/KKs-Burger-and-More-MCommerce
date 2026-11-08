
part of 'main_screen.dart';

extension _MainScreenOrders on _MainScreenState {
  Widget _ordersPage() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Please log in first.'));
    }

    return StreamBuilder(
      stream: DatabaseService().userOrders(user.uid).onValue,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not load orders: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final raw = snapshot.data!.snapshot.value;

        final List<Map<dynamic, dynamic>> orders;

        if (raw == null) {
          orders = [];
        } else {
          final map = Map<dynamic, dynamic>.from(raw as Map);

          orders = map.entries.map((entry) {
            final order = Map<dynamic, dynamic>.from(
              entry.value as Map,
            );

            order['orderId'] ??= entry.key.toString();

            return order;
          }).toList()
            ..sort((a, b) {
              final dateA =
                  int.tryParse(a['createdAt']?.toString() ?? '') ?? 0;

              final dateB =
                  int.tryParse(b['createdAt']?.toString() ?? '') ?? 0;

              return dateB.compareTo(dateA);
            });
        }

        // NORMALIZE STATUS AND ORDER TYPE

        String statusOf(Map<dynamic, dynamic> order) {
          return (order['status'] ?? 'Pending')
              .toString()
              .trim()
              .toLowerCase();
        }

        String orderTypeOf(Map<dynamic, dynamic> order) {
          return (order['orderType'] ?? '')
              .toString()
              .trim()
              .toLowerCase()
              .replaceAll('-', '')
              .replaceAll(' ', '')
              .replaceAll('_', '');
        }

        // ACTIVE ORDERS

        const activeStatuses = [
          'pending',
          'approved',
          'processing',
          'ready for pickup',
          'out for delivery',
        ];

        final activeOrders = orders.where((order) {
          return activeStatuses.contains(statusOf(order));
        }).toList();

        final pendingOrders = orders.where((order) {
          return statusOf(order) == 'pending';
        }).toList();

        final approvedOrders = orders.where((order) {
          return statusOf(order) == 'approved';
        }).toList();

        final processingOrders = orders.where((order) {
          return statusOf(order) == 'processing';
        }).toList();

        // PICKUP ONLY

        final readyForPickupOrders = orders.where((order) {
          return statusOf(order) == 'ready for pickup' &&
              orderTypeOf(order) == 'pickup';
        }).toList();

        // DELIVERY ONLY

        final outForDeliveryOrders = orders.where((order) {
          return statusOf(order) == 'out for delivery' &&
              orderTypeOf(order) == 'delivery';
        }).toList();

        final deliveredOrders = orders.where((order) {
          return statusOf(order) == 'delivered';
        }).toList();

        // ALL COMPLETED ORDERS, INCLUDING COMPLETED PICKUP ORDERS

        final completedOrders = orders.where((order) {
          return statusOf(order) == 'completed';
        }).toList();

        final rejectedOrders = orders.where((order) {
          return statusOf(order) == 'rejected';
        }).toList();

        final cancelledOrders = orders.where((order) {
          return statusOf(order) == 'cancelled';
        }).toList();

        return DefaultTabController(
          length: 10,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: _customerCancellationPolicyCard(),
              ),

              // ORDER CATEGORY TABS

              Material(
                color: Colors.white,
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: _brown,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: _yellow,
                  indicatorWeight: 4,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12,
                  ),
                  tabs: [
                    Tab(
                      text: 'Active (${activeOrders.length})',
                    ),
                    Tab(
                      text: 'Pending (${pendingOrders.length})',
                    ),
                    Tab(
                      text: 'Approved (${approvedOrders.length})',
                    ),
                    Tab(
                      text: 'Processing (${processingOrders.length})',
                    ),
                    Tab(
                      text: 'Ready for Pickup (${readyForPickupOrders.length})',
                    ),
                    Tab(
                      text: 'Out for Delivery (${outForDeliveryOrders.length})',
                    ),
                    Tab(
                      text: 'Delivered (${deliveredOrders.length})',
                    ),
                    Tab(
                      text: 'Walk-in / Completed (${completedOrders.length})',
                    ),
                    Tab(
                      text: 'Rejected (${rejectedOrders.length})',
                    ),
                    Tab(
                      text: 'Cancelled (${cancelledOrders.length})',
                    ),
                  ],
                ),
              ),

              // ORDER LISTS PER TAB

              Expanded(
                child: TabBarView(
                  children: [
                    _customerOrdersList(activeOrders, user.uid),
                    _customerOrdersList(pendingOrders, user.uid),
                    _customerOrdersList(approvedOrders, user.uid),
                    _customerOrdersList(processingOrders, user.uid),
                    _customerOrdersList(readyForPickupOrders, user.uid),
                    _customerOrdersList(outForDeliveryOrders, user.uid),
                    _customerOrdersList(deliveredOrders, user.uid),
                    _customerOrdersList(completedOrders, user.uid),
                    _customerOrdersList(rejectedOrders, user.uid),
                    _customerOrdersList(cancelledOrders, user.uid),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------------------------------------------
  // CUSTOMER ORDERS LIST
  // --------------------------------------------------

  Widget _customerOrdersList(
    List<Map<dynamic, dynamic>> orders,
    String userId,
  ) {
    if (orders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 55,
                color: Colors.grey,
              ),
              SizedBox(height: 12),
              Text(
                'No orders found.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 25),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _customerOrderCard(
          orders[index],
          userId,
        );
      },
    );
  }

  // --------------------------------------------------
  // CUSTOMER ORDER CARD
  // --------------------------------------------------

  Widget _customerOrderCard(
    Map<dynamic, dynamic> order,
    String userId,
  ) {
    final orderId = (order['orderId'] ?? '').toString();

    final itemsRaw = order['items'];

    final List<dynamic> items =
        itemsRaw is List ? itemsRaw : [];

    final names = items.map((rawItem) {
      if (rawItem is! Map) return '';

      final item = Map<dynamic, dynamic>.from(rawItem);

      final variant =
          (item['variant'] ?? item['size'] ?? '').toString();

      final productName =
          (item['name'] ?? 'Product').toString();

      final title = variant.isEmpty
          ? productName
          : '$productName ($variant)';

      return '$title x${item['quantity'] ?? 1}';
    }).where((name) => name.isNotEmpty).join(', ');

    final total = _number(order['total']);

    final subtotal = _number(
      order['subtotal'] ?? order['total'],
    );

    final fee = _number(order['deliveryFee']);

    final orderType =
        (order['orderType'] ?? 'Pickup').toString();

    final normalizedOrderType = orderType
        .trim()
        .toLowerCase()
        .replaceAll('-', '')
        .replaceAll(' ', '')
        .replaceAll('_', '');

    final delivery = normalizedOrderType == 'delivery';

    final method =
        (order['paymentMethod'] ?? 'Cash').toString();

    final status =
        (order['status'] ?? 'Pending').toString();

    final paymentStatus =
        (order['paymentStatus'] ?? 'Not Required').toString();

    final receipt =
        (order['receiptUrl'] ?? '').toString();

    final normalizedStatus = status.trim().toLowerCase();

    final normalizedMethod = method.trim().toLowerCase();

    final normalizedPaymentStatus =
        paymentStatus.trim().toLowerCase();

    final canCancel =
        normalizedMethod == 'cash' &&
        normalizedStatus == 'pending';

    Color statusColor;

    switch (normalizedStatus) {
      case 'pending':
        statusColor = Colors.orange;

      case 'approved':
        statusColor = Colors.blue;

      case 'processing':
        statusColor = Colors.deepPurple;

      case 'ready for pickup':
        statusColor = Colors.teal;

      case 'out for delivery':
        statusColor = Colors.indigo;

      case 'delivered':
      case 'completed':
        statusColor = Colors.green;

      case 'rejected':
      case 'cancelled':
        statusColor = Colors.red;

      default:
        statusColor = Colors.grey;
    }

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: _yellow,
                child: Icon(
                  Icons.receipt_long,
                  color: _brown,
                ),
              ),
              title: Text(
                '₱${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: _brown,
                ),
              ),
              subtitle: Text(
                names.isEmpty ? 'No product details' : names,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const Divider(),

            // ORDER INFORMATION

            _orderInfoRow(
              Icons.receipt_outlined,
              'Order ID',
              orderId,
            ),

            _orderInfoRow(
              Icons.shopping_bag_outlined,
              'Subtotal',
              '₱${subtotal.toStringAsFixed(2)}',
            ),

            if (delivery)
              _orderInfoRow(
                Icons.delivery_dining,
                'Delivery Fee',
                '₱${fee.toStringAsFixed(2)}',
              ),

            _orderInfoRow(
              delivery ? Icons.delivery_dining : Icons.store,
              'Order Type',
              orderType,
            ),

            _orderInfoRow(
              Icons.payment,
              'Payment Method',
              method,
            ),

            if (delivery) ...[
              _orderInfoRow(
                Icons.location_on_outlined,
                'Delivery Location',
                (order['deliveryLocation'] ?? 'N/A').toString(),
              ),

              _orderInfoRow(
                Icons.home_outlined,
                'Address',
                (order['deliveryAddress'] ?? 'N/A').toString(),
              ),

              _orderInfoRow(
                Icons.phone_outlined,
                'Contact',
                (order['contactNumber'] ?? 'N/A').toString(),
              ),
            ],

            if (order['createdAt'] != null)
              _orderInfoRow(
                Icons.calendar_today_outlined,
                'Order Date',
                order['createdAt'].toString(),
              ),

            // GCASH PAYMENT INFORMATION

            if (normalizedMethod == 'gcash') ...[
              const Divider(),

              Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: _brown,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Payment Verification',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      paymentStatus,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: normalizedPaymentStatus == 'verified'
                            ? Colors.green
                            : normalizedPaymentStatus == 'rejected'
                                ? Colors.red
                                : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (receipt.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showReceipt(receipt),
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('View Payment Screenshot'),
                  ),
                )
              else
                const Text(
                  'No payment screenshot attached.',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
            ],

            const Divider(),

            // CANCELLATION

            if (canCancel)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _confirmCancelOrder(
                      orderId,
                      userId,
                    );
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('CANCEL ORDER'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(
                      color: Colors.red,
                    ),
                  ),
                ),
              )
            else if (normalizedMethod == 'gcash' &&
                normalizedStatus == 'pending')
              const Text(
                'GCash orders cannot be cancelled because '
                'payments are non-refundable. Please contact '
                'the store if you need assistance.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                ),
              )
            else if (normalizedStatus != 'pending' &&
                normalizedStatus != 'rejected' &&
                normalizedStatus != 'cancelled')
              const Text(
                'This order can no longer be cancelled.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // ORDER INFORMATION ROW
  // --------------------------------------------------

  Widget _orderInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: _brown,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // CANCELLATION POLICY
  // --------------------------------------------------

  Widget _customerCancellationPolicyCard() {
    return Card(
      color: const Color(0xFFFFF8E1),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFFFD54F),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: _brown,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Customer Cancellation Policy',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _brown,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _policyItem(
              Icons.check_circle,
              Colors.green,
              'Cash orders can only be cancelled while the status is Pending.',
            ),

            const SizedBox(height: 8),

            _policyItem(
              Icons.cancel,
              Colors.red,
              'GCash orders cannot be cancelled. Payments are non-refundable.',
            ),

            const SizedBox(height: 8),

            _policyItem(
              Icons.lock_outline,
              Colors.orange,
              'Once an order is Approved, cancellation is no longer allowed.',
            ),

            const SizedBox(height: 8),

            _policyItem(
              Icons.info_outline,
              Colors.blueGrey,
              'Orders that are Processing, Ready for Pickup, or Out for Delivery cannot be cancelled.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _policyItem(
    IconData icon,
    Color color,
    String message,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: _brown,
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // CANCEL ORDER CONFIRMATION
  // --------------------------------------------------

  Future<void> _confirmCancelOrder(
    String orderId,
    String userId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Order?'),
          content: const Text(
            'Are you sure you want to cancel this Cash order? '
            'You can only cancel while the order is still Pending.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('NO'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('YES, CANCEL'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await DatabaseService().cancelPendingCashOrder(
        orderId: orderId,
        userId: userId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your order has been cancelled.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --------------------------------------------------
  // GCASH RECEIPT VIEWER
  // --------------------------------------------------

  void _showReceipt(String receipt) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'GCash Payment Receipt',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 12),

              Flexible(
                child: _receiptImage(receipt),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptImage(String receipt) {
    try {
      if (receipt.startsWith('data:')) {
        return Image.memory(
          base64Decode(receipt.split(',').last),
          fit: BoxFit.contain,
          height: 350,
          errorBuilder: (_, _, _) {
            return const Text(
              'Could not display receipt image.',
            );
          },
        );
      }

      return Image.network(
        receipt,
        fit: BoxFit.contain,
        height: 350,
        errorBuilder: (_, _, _) {
          return const Text(
            'Could not load receipt image.',
          );
        },
      );
    } catch (_) {
      return const Text('Invalid receipt image.');
    }
  }
}
