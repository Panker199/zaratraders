import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OrderTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  LatLng? _location;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  Future<void> _resolveLocation() async {
    final order = widget.order;

    // Use stored coordinates if available
    final lat = order['latitude'];
    final lng = order['longitude'];
    if (lat != null && lng != null) {
      setState(() {
        _location = LatLng((lat as num).toDouble(), (lng as num).toDouble());
        _loading = false;
      });
      return;
    }

    // Fall back to geocoding from address
    final address = order['address'] as String?;
    if (address != null && address.isNotEmpty) {
      try {
        final locations = await locationFromAddress(address);
        if (!mounted) return;
        if (locations.isNotEmpty) {
          setState(() {
            _location = LatLng(locations[0].latitude, locations[0].longitude);
            _loading = false;
          });
          return;
        }
      } catch (_) {
        if (!mounted) return;
      }
    }

    if (!mounted) return;
    // Default: Karachi, Pakistan
    setState(() {
      _location = const LatLng(24.8607, 67.0011);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.order;
    final orderId = order['id'] as String? ?? '';
    final status = order['status'] as String? ?? 'pending';
    final items = order['items'] as List<dynamic>? ?? [];
    final total = order['total'] as num? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Track Order',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Map area
          SizedBox(
            height: 280,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _location ?? const LatLng(24.8607, 67.0011),
                      zoom: 14,
                    ),
                    markers: _location != null
                        ? {
                            Marker(
                              markerId: const MarkerId('delivery'),
                              position: _location!,
                              infoWindow: InfoWindow(
                                title: order['customerName'] as String? ?? 'Delivery',
                                snippet: order['address'] as String? ?? '',
                              ),
                            ),
                          }
                        : {},
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                    mapType: MapType.normal,
                  ),
          ),
          // Order info
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(status.toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _statusColor(status))),
                            ),
                            const Spacer(),
                            Text('#${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (order['customerName'] != null)
                          _infoRow(Icons.person_outline,
                              '${order['customerName']}'),
                        if (order['customerEmail'] != null)
                          _infoRow(Icons.email_outlined,
                              '${order['customerEmail']}'),
                        if (order['address'] != null)
                          _infoRow(Icons.location_on_outlined,
                              '${order['address']}'),
                        if (order['customerPhone'] != null)
                          _infoRow(Icons.phone_outlined,
                              '${order['customerPhone']}'),
                        if (order['paymentMethod'] != null)
                          _infoRow(
                              order['paymentMethod'] == 'Cash on Delivery'
                                  ? Icons.money_rounded
                                  : order['paymentMethod'] == 'JazzCash'
                                      ? Icons.phone_android_rounded
                                      : Icons.account_balance_wallet_rounded,
                              '${order['paymentMethod']}${order['paymentStatus'] == 'paid' ? ' • Paid' : ' • Pending'}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Items (${items.length})',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ...items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text('${item['name'] ?? 'Item'}  x${item['quantity'] ?? 1}',
                                        style: theme.textTheme.bodySmall),
                                  ),
                                  Text('Rs. ${((item['price'] as num? ?? 0) * (item['quantity'] as int? ?? 1)).toStringAsFixed(2)}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            )),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            Text('Rs. ${total.toStringAsFixed(2)}',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Delivery Status',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        _statusStep('Pending', ['pending'], status, Icons.receipt_long_outlined, Colors.orange),
                        _statusStep('Confirmed', ['confirmed'], status, Icons.check_circle_outlined, Colors.blue),
                        _statusStep('Shipped', ['shipped'], status, Icons.local_shipping_outlined, Colors.purple),
                        _statusStep('Delivered', ['delivered'], status, Icons.verified_outlined, Colors.green),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _statusStep(String label, List<String> matchedStatuses, String current, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isActive = matchedStatuses.contains(current);
    final isPast = _isPast(current, matchedStatuses.first);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isPast || isActive ? color.withValues(alpha: 0.15) : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 16,
                color: isPast || isActive ? color : Colors.grey.shade400),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isPast || isActive ? theme.colorScheme.onSurface : Colors.grey.shade400)),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('CURRENT',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
            ),
        ],
      ),
    );
  }

  bool _isPast(String current, String target) {
    const order = ['pending', 'confirmed', 'shipped', 'delivered'];
    final curIdx = order.indexOf(current);
    final tgtIdx = order.indexOf(target);
    return curIdx > tgtIdx;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'shipped': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}
