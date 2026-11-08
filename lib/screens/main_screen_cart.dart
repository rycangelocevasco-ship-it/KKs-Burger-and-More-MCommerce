
part of 'main_screen.dart';

extension _MainScreenCart on _MainScreenState {
  Widget _cartPage() {
    final lines = _cart.values.toList();

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (lines.isEmpty)
          const SizedBox(
            height: 220,
            child: Center(
              child: Text(
                'Your cart is empty. Add something delicious!',
              ),
            ),
          )
        else
          ...lines.map((line) {
            final isRiceMeal =
                line.product.category == 'Rice Meals';

            final addonPrice = isRiceMeal
                ? line.price - line.product.price
                : 0.0;

            return Card(
              color: Colors.white,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: ListTile(
                title: Text(
                  line.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₱${line.price.toStringAsFixed(2)} each',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (isRiceMeal) ...[
                      Text(
                        'Base: ₱${line.product.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      if (addonPrice > 0)
                        Text(
                          'Add-ons: +₱${addonPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                    Text(
                      'Available stock: ${line.product.stock}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _changeQty(line.key, -1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '${line.quantity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: line.quantity >= line.product.stock
                          ? null
                          : () => _changeQty(line.key, 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
            );
          }),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryRow(
                'Subtotal',
                '₱${_total.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 6),
              _summaryRow(
                'Delivery Fee',
                _orderType == 'Pickup'
                    ? '₱0.00'
                    : _deliveryLocation == null
                        ? 'Select location'
                        : '₱${_currentDeliveryFee.toStringAsFixed(2)}',
              ),
              const Divider(height: 20),
              _summaryRow(
                'Total',
                '₱${_grandTotal.toStringAsFixed(2)}',
                large: true,
              ),
              const SizedBox(height: 16),
              const Text(
                'Order Type',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _orderType,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.delivery_dining),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Pickup',
                    child: Text('Pickup'),
                  ),
                  DropdownMenuItem(
                    value: 'Delivery',
                    child: Text('Delivery'),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;

                  _refresh(() {
                    _orderType = v;
                    if (v == 'Pickup') {
                      _deliveryLocation = null;
                    }
                  });
                },
              ),
              if (_orderType == 'Delivery') ...[
                const SizedBox(height: 14),
                const Text(
                  'Delivery Location',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _deliveryLocation,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                    hintText: 'Select your delivery location',
                  ),
                  items: _deliveryRates.keys
                      .map(
                        (location) => DropdownMenuItem(
                          value: location,
                          child: Text(location),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      _refresh(() => _deliveryLocation = v),
                ),
                const SizedBox(height: 8),
                _infoPanel(
                  'Complete Delivery Address',
                  (_homeProfileData['address'] ?? '')
                          .toString()
                          .trim()
                          .isEmpty
                      ? 'Please add your complete address in Profile.'
                      : _homeProfileData['address'].toString(),
                  Icons.home_outlined,
                ),
              ],
              const SizedBox(height: 14),
              const Text(
                'Payment Method',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.payment),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Cash',
                    child: Text('Cash'),
                  ),
                  DropdownMenuItem(
                    value: 'GCash',
                    child: Text('GCash'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    _refresh(() => _paymentMethod = v);
                  }
                },
              ),
              if (_paymentMethod == 'GCash') ...[
                const SizedBox(height: 12),
                _gcashPanel(),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cart.isEmpty ||
                          _checkingOut ||
                          _uploadingReceipt ||
                          (_paymentMethod == 'GCash' &&
                              _gcashReceipt == null) ||
                          (_orderType == 'Delivery' &&
                              _deliveryLocation == null) ||
                          lines.any(
                            (line) =>
                                line.product.stock < line.quantity,
                          )
                      ? null
                      : _checkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _yellow,
                    foregroundColor: _brown,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _checkingOut || _uploadingReceipt
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'CHECKOUT',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _gcashPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _yellow, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: _brown,
              ),
              SizedBox(width: 8),
              Text(
                'GCash Payment Details',
                style: TextStyle(
                  color: _brown,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Send your payment to this GCash number:'),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(
                child: SelectableText(
                  '09559980534',
                  style: TextStyle(
                    color: _brown,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    const ClipboardData(text: '09559980534'),
                  );
                  _showMessage('GCash number copied!');
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Account Name: SH***A M** S.',
            style: TextStyle(
              color: _brown,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'IMPORTANT: Please verify that the recipient name matches the account name above before sending your payment.',
            style: TextStyle(
              color: Colors.red,
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'After sending your payment, upload a screenshot of your GCash transaction. '
            'The admin will review your payment before verifying it.',
            style: TextStyle(fontSize: 11, height: 1.35),
          ),
          const SizedBox(height: 12),
          if (_gcashReceipt != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  maxHeight: 240,
                ),
                color: Colors.white,
                child: Image.memory(
                  _gcashReceipt!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Could not preview image.'),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _gcashReceiptName.isEmpty
                  ? 'Payment screenshot selected'
                  : _gcashReceiptName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: _uploadingReceipt
                      ? null
                      : _pickGcashReceipt,
                  child: const Text('Change'),
                ),
                IconButton(
                  tooltip: 'Remove receipt',
                  onPressed: _uploadingReceipt
                      ? null
                      : () {
                          _refresh(() {
                            _gcashReceipt = null;
                            _gcashReceiptName = '';
                            _gcashReceiptContentType = 'image/jpeg';
                          });
                        },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ] else
            const Text(
              'No payment screenshot selected',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  _uploadingReceipt ? null : _pickGcashReceipt,
              icon: const Icon(Icons.image_outlined),
              label: Text(
                _gcashReceipt == null
                    ? 'UPLOAD PAYMENT SCREENSHOT'
                    : 'CHANGE PAYMENT SCREENSHOT',
              ),
            ),
          ),
          if (_gcashReceipt == null)
            const Text(
              '* Screenshot is required for GCash checkout.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}
