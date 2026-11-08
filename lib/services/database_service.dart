
import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  DatabaseReference get _root => FirebaseDatabase.instance.ref();

  // Generate a unique order ID.
  String newOrderId() {
    final key = _root.child('orders').push().key;

    if (key == null) {
      throw Exception('Could not generate an order ID.');
    }

    return key;
  }

  // PLACE ORDER WITH DUPLICATE-PREVENTION TRANSACTION.
  Future<void> placeOrder({
    required String requestId,
    required String userId,
    required String email,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double deliveryFee,
    required String deliveryLocation,
    required double total,
    required String orderType,
    required String paymentMethod,
    required String deliveryAddress,
    required String contactNumber,
    String receiptUrl = '',
  }) async {
    if (items.isEmpty) {
      throw Exception('Your order has no items.');
    }

    if (total <= 0 || subtotal < 0 || deliveryFee < 0) {
      throw Exception('Invalid order total.');
    }

    final orderRef = _root.child('orders').child(requestId);

    final orderData = <String, dynamic>{
      'orderId': requestId,
      'requestId': requestId,
      'userId': userId,
      'email': email,
      'items': items,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'deliveryLocation': deliveryLocation,
      'total': total,
      'orderType': orderType,
      'paymentMethod': paymentMethod,
      'deliveryAddress': deliveryAddress,
      'contactNumber': contactNumber,
      'status': 'Pending',
      'paymentStatus': paymentMethod == 'GCash'
          ? 'Pending Verification'
          : 'Cash Payment',
      'receiptUrl': receiptUrl,
      'createdAt': ServerValue.timestamp,
    };

    final result = await orderRef.runTransaction(
      (Object? currentData) {
        // Do not create another order using an existing request ID.
        if (currentData != null) {
          return Transaction.abort();
        }

        return Transaction.success(orderData);
      },
      applyLocally: false,
    );

    if (!result.committed) {
      final existing = await orderRef.get();

      final existingUserId =
          existing.child('userId').value?.toString();

      final existingRequestId =
          existing.child('requestId').value?.toString();

      // Treat an existing order from the same request as already submitted.
      if (existing.exists &&
          existingUserId == userId &&
          existingRequestId == requestId) {
        return;
      }

      throw Exception(
        'This order request could not be completed. Please try again.',
      );
    }
  }

  // GET USER ORDERS.
  Query userOrders(String userId) {
    return _root
        .child('orders')
        .orderByChild('userId')
        .equalTo(userId);
  }

  // GET ALL ORDERS.
  Query allOrders() {
    return _root
        .child('orders')
        .orderByChild('createdAt');
  }

  // UPDATE ORDER STATUS.
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    const allowedStatuses = [
      'Pending',
      'Approved',
      'Confirmed',
      'Processing',
      'Preparing',
      'Ready for Pickup',
      'Out for Delivery',
      'Completed',
      'Rejected',
      'Cancelled',
    ];

    if (!allowedStatuses.contains(status)) {
      throw ArgumentError('Invalid order status.');
    }

    await _root.child('orders').child(orderId).update({
      'status': status,
      'updatedAt': ServerValue.timestamp,
    });
  }

  // CANCEL CASH ORDER.
  // Only the owner can cancel, and only while the order is Pending.
  Future<void> cancelPendingCashOrder({
    required String orderId,
    required String userId,
  }) async {
    final orderRef = _root.child('orders').child(orderId);

    final result = await orderRef.runTransaction(
      (Object? currentData) {
        if (currentData == null || currentData is! Map) {
          return Transaction.abort();
        }

        final order = Map<dynamic, dynamic>.from(currentData);

        final existingUserId =
            order['userId']?.toString() ?? '';

        final paymentMethod =
            order['paymentMethod']?.toString() ?? '';

        final status =
            order['status']?.toString() ?? '';

        if (existingUserId != userId) {
          return Transaction.abort();
        }

        if (paymentMethod != 'Cash') {
          return Transaction.abort();
        }

        if (status != 'Pending') {
          return Transaction.abort();
        }

        order['status'] = 'Cancelled';
        order['updatedAt'] = ServerValue.timestamp;

        return Transaction.success(order);
      },
      applyLocally: false,
    );

    if (!result.committed) {
      throw Exception(
        'This order cannot be cancelled. Only your Pending Cash orders can be cancelled.',
      );
    }
  }

  // GET USER PROFILE.
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final snapshot = await _root.child('users').child(userId).get();

    if (!snapshot.exists || snapshot.value == null) {
      return {};
    }

    return Map<String, dynamic>.from(snapshot.value as Map);
  }

  // SAVE USER PROFILE.
  Future<void> saveUserProfile({
    required String userId,
    required String name,
    required String phone,
    required String address,
  }) async {
    await _root.child('users').child(userId).update({
      'name': name,
      'phone': phone,
      'address': address,
      'updatedAt': ServerValue.timestamp,
    });
  }
}
