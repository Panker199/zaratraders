import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';

class OrderFormScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final double total;

  const OrderFormScreen({
    super.key,
    required this.items,
    required this.total,
  });

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  final _bundleCtrl = TextEditingController();
  final _giftMessageCtrl = TextEditingController();
  final _specialInstrCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String _bundleType = 'Standard';
  String _weightUnit = 'kg';

  String _paymentMethod = 'Cash on Delivery';
  final _paymentMethods = ['Cash on Delivery', 'JazzCash', 'EasyPaisa'];
  double? _latitude;
  double? _longitude;
  bool _locating = false;
  bool _submitting = false;
  bool _autoLocating = false;
  Timer? _locateDebounce;
  List<Location> _streetSuggestions = [];
  bool _streetSearching = false;
  Timer? _streetDebounce;
  final _streetFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _streetCtrl.addListener(_onStreetChanged);
    _streetCtrl.addListener(_onAddressFieldChanged);
    _cityCtrl.addListener(_onAddressFieldChanged);
    _provinceCtrl.addListener(_onAddressFieldChanged);
    _postalCtrl.addListener(_onAddressFieldChanged);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _streetCtrl.removeListener(_onStreetChanged);
    _streetCtrl.removeListener(_onAddressFieldChanged);
    _cityCtrl.removeListener(_onAddressFieldChanged);
    _provinceCtrl.removeListener(_onAddressFieldChanged);
    _postalCtrl.removeListener(_onAddressFieldChanged);
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _provinceCtrl.dispose();
    _postalCtrl.dispose();
    _bundleCtrl.dispose();
    _giftMessageCtrl.dispose();
    _specialInstrCtrl.dispose();
    _weightCtrl.dispose();
    _locateDebounce?.cancel();
    _streetDebounce?.cancel();
    _streetFocusNode.dispose();
    super.dispose();
  }

  void _onStreetChanged() {
    _streetDebounce?.cancel();
    final text = _streetCtrl.text.trim();
    if (text.length < 3) {
      setState(() => _streetSuggestions = []);
      return;
    }
    _streetDebounce = Timer(const Duration(milliseconds: 500), () => _searchStreetSuggestions(text));
  }

  Future<void> _searchStreetSuggestions(String query) async {
    setState(() => _streetSearching = true);
    try {
      final locations = await locationFromAddress(query);
      if (!mounted) return;
      setState(() => _streetSuggestions = locations);
    } catch (_) {
      if (!mounted) return;
      setState(() => _streetSuggestions = []);
    } finally {
      if (mounted) setState(() => _streetSearching = false);
    }
  }

  void _selectSuggestion(Location loc) {
    setState(() {
      _latitude = loc.latitude;
      _longitude = loc.longitude;
      _streetSuggestions = [];
    });
    _streetFocusNode.unfocus();
    _locateDebounce?.cancel();
    // Reverse geocode to fill address fields
    placemarkFromCoordinates(loc.latitude, loc.longitude).then((places) {
      if (!mounted) return;
      if (places.isNotEmpty) {
        final p = places[0];
        _streetCtrl.text = '${p.street ?? ''}${p.street != null && p.subLocality != null ? ', ' : ''}${p.subLocality ?? ''}';
        _cityCtrl.text = p.locality ?? p.subAdministrativeArea ?? '';
        _provinceCtrl.text = p.administrativeArea ?? '';
        _postalCtrl.text = p.postalCode ?? '';
      }
    }).catchError((_) {});
  }

  void _onAddressFieldChanged() {
    _locateDebounce?.cancel();
    _locateDebounce = Timer(const Duration(milliseconds: 600), _autoLocateAddress);
  }

  Future<void> _autoLocateAddress() async {
    final address = _fullAddress;
    if (address.isEmpty) {
      if (mounted) setState(() { _latitude = null; _longitude = null; });
      return;
    }
    if (_autoLocating) return;
    setState(() => _autoLocating = true);
    try {
      final locations = await locationFromAddress(address);
      if (!mounted) return;
      if (locations.isNotEmpty) {
        setState(() {
          _latitude = locations[0].latitude;
          _longitude = locations[0].longitude;
        });
      }
    } catch (_) {
      // Silently ignore — user can still use Pick on Map
    } finally {
      if (mounted) setState(() => _autoLocating = false);
    }
  }

  String get _fullAddress {
    final parts = [
      _streetCtrl.text.trim(),
      _cityCtrl.text.trim(),
      _provinceCtrl.text.trim(),
      _postalCtrl.text.trim(),
    ];
    return parts.where((p) => p.isNotEmpty).join(', ');
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => const _MapPickerScreen(),
      ),
    );
    if (result != null) {
      if (!mounted) return;
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
      // Reverse geocode to fill address
      try {
        setState(() => _locating = true);
        final places = await placemarkFromCoordinates(result.latitude, result.longitude);
        if (!mounted) return;
        if (places.isNotEmpty) {
          final p = places[0];
          _streetCtrl.text = '${p.street ?? ''}${p.street != null && p.subLocality != null ? ', ' : ''}${p.subLocality ?? ''}';
          _cityCtrl.text = p.locality ?? p.subAdministrativeArea ?? '';
          _provinceCtrl.text = p.administrativeArea ?? '';
          _postalCtrl.text = p.postalCode ?? '';
        }
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not resolve address from location'),
              behavior: SnackBarBehavior.floating),
        );
      } finally {
        if (mounted) setState(() => _locating = false);
      }
    }
  }

  Future<void> _placeOrder() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) return;
    if (_submitting) return;
    setState(() => _submitting = true);

    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    final messenger = ScaffoldMessenger.of(context);

    try {
      await AdminService().placeOrder({
        'customerName': '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
        'customerEmail': _emailCtrl.text.trim(),
        'customerPhone': _phoneCtrl.text.trim(),
        'placedBy': user?.id ?? '',
        'placedByRole': user?.role.name ?? 'shopkeeper',
        'address': _fullAddress,
        if (_latitude != null) 'latitude': _latitude,
        if (_longitude != null) 'longitude': _longitude,
        'bundleNotes': _bundleCtrl.text.trim(),
        'bundleType': _bundleType,
        'giftMessage': _giftMessageCtrl.text.trim(),
        'specialInstructions': _specialInstrCtrl.text.trim(),
        'weight': double.tryParse(_weightCtrl.text.trim()) ?? 0,
        'weightUnit': _weightUnit,
        'paymentMethod': _paymentMethod,
        'paymentStatus': _paymentMethod == 'Cash on Delivery' ? 'pending' : 'paid',
        'items': widget.items,
        'total': widget.total,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Order placed successfully!'),
            behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to place order: $e'),
            behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // === PERSONAL DETAILS ===
            _SectionLabel('Personal Details'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Last Name *',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
            ),

            const SizedBox(height: 24),

            // === DELIVERY ADDRESS ===
            _SectionLabel('Delivery Address'),
            const SizedBox(height: 10),
            Stack(
              clipBehavior: Clip.none,
              children: [
                TextFormField(
                  controller: _streetCtrl,
                  focusNode: _streetFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Street Address *',
                    prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                    suffixIcon: _streetSearching
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)))
                        : _streetSuggestions.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() => _streetSuggestions = []))
                            : null,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                if (_streetSuggestions.isNotEmpty)
                  Positioned(
                    top: 56,
                    left: 0,
                    right: 0,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _streetSuggestions.length,
                        separatorBuilder: (_, _) => const Divider(height: 1, indent: 12),
                        itemBuilder: (context, i) {
                          final loc = _streetSuggestions[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_outlined, size: 18, color: Colors.teal),
                            title: Text(
                                '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}',
                                style: const TextStyle(fontSize: 13)),
                            onTap: () => _selectSuggestion(loc),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _cityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'City *',
                      prefixIcon: Icon(Icons.location_city_outlined, size: 20),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _provinceCtrl,
                    decoration: const InputDecoration(labelText: 'Province'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _postalCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Postal Code',
                prefixIcon: Icon(Icons.markunread_mailbox_outlined, size: 20),
              ),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickOnMap,
                    icon: _locating
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : _autoLocating
                            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey.shade400))
                            : Icon(_latitude != null ? Icons.check_circle : Icons.map_outlined,
                                size: 18, color: _latitude != null ? Colors.green : null),
                    label: Text(
                      _locating
                          ? 'Locating...'
                          : _autoLocating
                              ? 'Locating address...'
                              : _latitude != null
                                  ? 'Located (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})'
                                  : 'Pick on Map',
                      overflow: TextOverflow.ellipsis),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _latitude != null ? Colors.green : null,
                    ),
                  ),
                ),
                if (_latitude != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.location_on, size: 20, color: Colors.green),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // === BUNDLE CUSTOMIZATION ===
            _SectionLabel('Bundle Customization'),
            const SizedBox(height: 8),

            // Bundle Type
            DropdownButtonFormField<String>(
              initialValue: _bundleType,
              isExpanded: true,
              isDense: true,
              decoration: const InputDecoration(
                labelText: 'Bundle Type',
                prefixIcon: Icon(Icons.inventory_2_outlined, size: 20),
              ),
              items: const [
                DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                DropdownMenuItem(value: 'Premium', child: Text('Premium')),
                DropdownMenuItem(value: 'Cotton', child: Text('Cotton')),
                DropdownMenuItem(value: 'Carton', child: Text('Carton')),
                DropdownMenuItem(value: 'Custom', child: Text('Custom')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _bundleType = v);
              },
            ),
            const SizedBox(height: 8),

            // Weight
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _weightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Weight',
                      prefixIcon: Icon(Icons.monitor_weight_outlined, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _weightUnit,
                    isExpanded: true,
                    isDense: true,
                    decoration: const InputDecoration(labelText: 'Unit', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    items: const [
                      DropdownMenuItem(value: 'kg', child: Text('kg')),
                      DropdownMenuItem(value: 'g', child: Text('g')),
                      DropdownMenuItem(value: 'lb', child: Text('lb')),
                      DropdownMenuItem(value: 'oz', child: Text('oz')),
                      DropdownMenuItem(value: 'm', child: Text('m (meters)')),
                      DropdownMenuItem(value: 'yd', child: Text('yd (yards)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _weightUnit = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Gift Message
            TextFormField(
              controller: _giftMessageCtrl,
              decoration: const InputDecoration(
                hintText: 'Add a gift message...',
                prefixIcon: Icon(Icons.card_giftcard_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 8),

            // Special Instructions
            TextFormField(
              controller: _specialInstrCtrl,
              decoration: const InputDecoration(
                hintText: 'Any special instructions, gift wrapping, customization...',
                prefixIcon: Icon(Icons.edit_note_outlined, size: 20),
              ),
            ),

            const SizedBox(height: 16),

            // === PAYMENT METHOD ===
            _SectionLabel('Payment Method'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _paymentMethods.map((method) {
                final active = _paymentMethod == method;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        method == 'Cash on Delivery'
                            ? Icons.money_rounded
                            : method == 'JazzCash'
                                ? Icons.phone_android_rounded
                                : Icons.account_balance_wallet_rounded,
                        size: 16,
                        color: active ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(method, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  selected: active,
                  onSelected: (_) => setState(() => _paymentMethod = method),
                  selectedColor: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // === ORDER SUMMARY ===
            _SectionLabel('Order Summary'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...widget.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('${item['name'] ?? 'Item'}  x${item['quantity'] ?? 1}',
                                style: theme.textTheme.bodySmall),
                          ),
                          Text(
                            'Rs. ${((item['price'] as num? ?? 0) * (item['quantity'] as int? ?? 1)).toStringAsFixed(2)}',
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Rs. ${widget.total.toStringAsFixed(2)}',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF60cdff))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _placeOrder,
              icon: _submitting
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.shopping_cart_checkout, size: 20),
              label: Text('Place Order — Rs. ${widget.total.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF60cdff),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.5));
  }
}

class _MapPickerScreen extends StatefulWidget {
  const _MapPickerScreen();

  @override
  State<_MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<_MapPickerScreen> {
  LatLng _selected = const LatLng(24.8607, 67.0011);
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  List<Location> _results = [];
  bool _searching = false;
  Timer? _debounce;
  GoogleMapController? _mapCtrl;
  bool _permissionGranted = false;
  bool _locatingDevice = false;
  String _selectedAddress = '';

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLocate();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _requestPermissionAndLocate() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied || req == LocationPermission.deniedForever) {
          if (mounted) setState(() => _permissionGranted = false);
          return;
        }
      }
      if (mounted) setState(() => _permissionGranted = true);
      await _locateDevice();
    } catch (_) {
      if (mounted) setState(() => _permissionGranted = false);
    }
  }

  Future<void> _locateDevice() async {
    if (!_permissionGranted) {
      await _requestPermissionAndLocate();
      return;
    }
    setState(() => _locatingDevice = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _selected = latLng);
      _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
      await _resolveAddress(latLng);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get current location. Enable GPS and try again.'),
            behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _locatingDevice = false);
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final locations = await locationFromAddress(query);
      if (!mounted) return;
      setState(() => _results = locations);
    } catch (_) {
      if (!mounted) return;
      setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _goToLocation(Location loc) {
    final latLng = LatLng(loc.latitude, loc.longitude);
    setState(() {
      _selected = latLng;
      _results = [];
      _selectedAddress = '';
    });
    _focusNode.unfocus();
    _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
    _resolveAddress(latLng);
  }

  Future<void> _resolveAddress(LatLng latLng) async {
    try {
      final places = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (!mounted) return;
      if (places.isNotEmpty) {
        final p = places[0];
        final parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.subAdministrativeArea,
          p.administrativeArea,
          p.postalCode,
          p.country,
        ];
        setState(() {
          _selectedAddress = parts.where((x) => x != null && x.isNotEmpty).join(', ');
        });
      }
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          if (_permissionGranted)
            IconButton(
              icon: _locatingDevice
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location, size: 20),
              onPressed: _locateDevice,
              tooltip: 'My Location',
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_selected),
            child: const Text('Confirm'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              focusNode: _focusNode,
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () => _search(v));
              },
              decoration: InputDecoration(
                hintText: 'Search location...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searching
                    ? const SizedBox(width: 20, height: 20, child: Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ))
                    : _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _results = []);
                            })
                        : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          if (_results.isNotEmpty)
            SizedBox(
              height: 180,
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
                itemBuilder: (context, i) {
                  final loc = _results[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on_outlined, size: 18),
                    title: Text(_searchCtrl.text,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14)),
                    subtitle: Text('${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    onTap: () => _goToLocation(loc),
                  );
                },
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: (ctrl) => _mapCtrl = ctrl,
                  initialCameraPosition: CameraPosition(target: _selected, zoom: 12),
                  onTap: (latLng) {
                    setState(() {
                      _selected = latLng;
                      _selectedAddress = '';
                    });
                    _resolveAddress(latLng);
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selected,
                      draggable: true,
                      onDragEnd: (latLng) {
                        setState(() {
                          _selected = latLng;
                          _selectedAddress = '';
                        });
                        _resolveAddress(latLng);
                      },
                    ),
                  },
                  myLocationEnabled: _permissionGranted,
                  myLocationButtonEnabled: false,
                  mapType: MapType.normal,
                ),
                // Address banner
                if (_selectedAddress.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.red.shade400),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(_selectedAddress,
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Set This Location FAB
                Positioned(
                  bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(_selected),
                        icon: const Icon(Icons.check_circle, size: 20),
                        label: Text(
                          _selectedAddress.isNotEmpty
                              ? 'Set This Location'
                              : 'Set This Location',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22)),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                      ),
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
}
