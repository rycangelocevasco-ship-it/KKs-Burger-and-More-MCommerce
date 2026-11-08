
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'admin_constants.dart';

// FIREBASE REFERENCES

DatabaseReference get ordersReference =>
    FirebaseDatabase.instance.ref('orders');

DatabaseReference get usersReference =>
    FirebaseDatabase.instance.ref('users');

// CONVERT FIREBASE DATA

Map<String, dynamic> convertToMap(Object? value) {
  if (value is Map) {
    return value.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }
  return {};
}

List<Map<String, dynamic>> getOrderItems(
  Map<String, dynamic> order,
) {
  final items = order['items'];

  if (items is List) {
    return items
        .whereType<Map>()
        .map((item) => convertToMap(item))
        .toList();
  }

  if (items is Map) {
    return items.values
        .whereType<Map>()
        .map((item) => convertToMap(item))
        .toList();
  }

  return [];
}

List<Map<String, dynamic>> getOrders(DataSnapshot snapshot) {
  final List<Map<String, dynamic>> orders = [];

  for (final child in snapshot.children) {
    final data = convertToMap(child.value);
    data['id'] = child.key;
    orders.add(data);
  }

  orders.sort((a, b) {
    final dateA =
        int.tryParse(a['createdAt']?.toString() ?? '') ?? 0;
    final dateB =
        int.tryParse(b['createdAt']?.toString() ?? '') ?? 0;
    return dateB.compareTo(dateA);
  });

  return orders;
}

List<Map<String, dynamic>> getUsers(DataSnapshot snapshot) {
  final List<Map<String, dynamic>> users = [];

  for (final child in snapshot.children) {
    final data = convertToMap(child.value);
    data['id'] = child.key;
    users.add(data);
  }

  return users;
}

// ORDER TOTAL

double getOrderTotal(Map<String, dynamic> order) {
  final total = num.tryParse(
        order['total']?.toString() ?? '',
      ) ??
      num.tryParse(
        order['totalAmount']?.toString() ?? '',
      );

  if (total != null) return total.toDouble();

  double computedTotal = 0;

  for (final item in getOrderItems(order)) {
    final subtotal = num.tryParse(
      item['subtotal']?.toString() ?? '',
    );

    if (subtotal != null) {
      computedTotal += subtotal;
    } else {
      final price = num.tryParse(
            item['price']?.toString() ?? '',
          ) ??
          0;
      final quantity = num.tryParse(
            item['quantity']?.toString() ?? '1',
          ) ??
          1;
      computedTotal += price * quantity;
    }
  }

  return computedTotal;
}

// FIND CUSTOMER

Map<String, dynamic>? findOrderCustomer(
  Map<String, dynamic> order,
  List<Map<String, dynamic>> users,
) {
  final userId = order['userId']?.toString();
  final email = order['email']?.toString().toLowerCase();

  for (final user in users) {
    if (userId != null &&
        userId.isNotEmpty &&
        user['id']?.toString() == userId) {
      return user;
    }

    if (email != null &&
        email.isNotEmpty &&
        user['email']?.toString().toLowerCase() == email) {
      return user;
    }
  }

  return null;
}

String getCustomerName(
  Map<String, dynamic> order, [
  List<Map<String, dynamic>> users = const [],
]) {
  final customer = findOrderCustomer(order, users);

  return customer?['name']?.toString() ??
      order['customerName']?.toString() ??
      order['email']?.toString() ??
      'Customer';
}

String getOrderProducts(Map<String, dynamic> order) {
  final items = getOrderItems(order);

  if (items.isEmpty) return 'No product details';

  return items.map((item) {
    final name = item['name'] ?? 'Product';
    final quantity = item['quantity'] ?? 1;
    return '$name x$quantity';
  }).join(', ');
}

String formatOrderDate(Object? timestamp) {
  final milliseconds =
      int.tryParse(timestamp?.toString() ?? '');

  if (milliseconds == null) return 'Date unavailable';

  final date =
      DateTime.fromMillisecondsSinceEpoch(milliseconds);

  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '${date.month}/${date.day}/${date.year} $hour:$minute';
}

// PAYMENT RECEIPT VIEWER

void showPaymentReceipt(
  BuildContext context,
  String receiptData,
) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'GCash Payment Screenshot',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: adminBrown,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: Builder(
                  builder: (context) {
                    try {
                      if (receiptData.startsWith('data:')) {
                        final parts = receiptData.split(',');
                        if (parts.length < 2) {
                          return const Text(
                            'Invalid Base64 receipt format.',
                          );
                        }

                        final bytes = base64Decode(parts.last);

                        return InteractiveViewer(
                          child: Image.memory(
                            bytes,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Text(
                                'Could not display receipt image.',
                              );
                            },
                          ),
                        );
                      }

                      if (receiptData.startsWith('http://') ||
                          receiptData.startsWith('https://')) {
                        return Image.network(
                          receiptData,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Text(
                              'Could not load receipt image.',
                            );
                          },
                        );
                      }

                      return const Text(
                        'Unsupported receipt image format.',
                      );
                    } catch (e) {
                      return const Text('Invalid receipt image.');
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
