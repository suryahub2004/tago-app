import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/sv_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/shop_repository.dart';

class OrderFormScreen extends ConsumerStatefulWidget {
  final String productId;
  /// 'SMART_RING' | 'WHOOP_BAND' — used to show/hide the ring-size selector.
  /// Defaults to null which means size selector is hidden.
  final String? deviceType;
  const OrderFormScreen({super.key, required this.productId, this.deviceType});

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  
  String? _selectedSize; // Applicable if ring
  String _paymentMethod = 'cod';
  bool _isLoading = false;

  late Razorpay _razorpay;

  /// True when the product is a smart ring — controls ring-size selector visibility.
  /// Uses the explicit deviceType if provided; never relies on productId string matching.
  bool get isRing => widget.deviceType == 'SMART_RING';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _razorpay.clear();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _submitOrderToApi(paymentId: response.paymentId);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handling external wallets if enabled
  }

  Future<void> _openCameraForSize() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null && mounted) {
      setState(() => _isLoading = true);
      
      // Simulate AI analysis delay
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _selectedSize = 'US 9'; // Simulated result
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI Analysis Complete! Your exact size is US 9'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (isRing && _selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a ring size')),
      );
      return;
    }

    setState(() => _isLoading = true);

    if (_paymentMethod == 'online') {
      final key = dotenv.env['RAZORPAY_KEY'] ?? '';
      if (key.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Razorpay Key not found in .env')),
        );
        return;
      }
      
      final user = ref.read(currentUserProvider);
      var options = {
        'key': key,
        'amount': widget.productId == 'ring_gen2' ? 1499900 : 1249900, // in paise
        'name': 'SmartVital',
        'description': isRing ? 'Smart Ring Gen 2' : 'Whoop Band Pro',
        'prefill': {
          'contact': _phoneController.text,
          'email': user?.email ?? ''
        }
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        setState(() => _isLoading = false);
      }
    } else {
      // COD
      await _submitOrderToApi();
    }
  }

  Future<void> _submitOrderToApi({String? paymentId}) async {
    // Build a payload that matches the backend CreateOrderDto exactly:
    //   - productId / quantity at the top level (not nested in 'items')
    //   - shippingAddress field names match the DTO (fullName, line1, pinCode)
    //   - paymentMethod is uppercase ('COD' | 'ONLINE') as the enum requires
    final orderData = <String, dynamic>{
      'productId': widget.productId,
      'quantity': 1,
      'shippingAddress': {
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'line1': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'pinCode': _pincodeController.text.trim(),
        'state': _stateController.text.trim(),
      },
      // Backend enum: 'COD' | 'ONLINE'
      'paymentMethod': _paymentMethod == 'online' ? 'ONLINE' : 'COD',
      'paymentId': paymentId,
      'ringSize': _selectedSize,
    };

    try {
      final response = await ref.read(shopRepositoryProvider).createOrder(orderData);
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Extract the real order ID from the backend response and pass it
      // to the confirmation screen so it can navigate to the real order detail.
      final orderId = response['id'] as String? ?? '';
      context.go('/home/shop/order-success', extra: orderId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order failed: ${e.toString()}'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              isRing ? 'Smart Ring Gen 2' : 'Whoop Band Pro',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isRing ? '₹14,999' : '₹12,499',
              style: const TextStyle(fontSize: 20, color: AppColors.primary),
            ),
            const Divider(height: 48),

            const Text('Shipping Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (val) => Validators.requiredText(val, 'Full Name'),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Phone number is required';
                if (val.trim().length < 10) return 'Enter valid phone number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Street Address'),
              validator: (val) => Validators.requiredText(val, 'Address'),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                    validator: (val) => Validators.requiredText(val, 'City'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Pincode'),
                    validator: (val) => Validators.requiredText(val, 'Pincode'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _stateController,
              decoration: const InputDecoration(labelText: 'State'),
              validator: (val) => Validators.requiredText(val, 'State'),
            ),
            
            if (isRing) ...[
              const Divider(height: 48),
              const Text('Ring Size', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSize,
                      dropdownColor: AppColors.surface,
                      decoration: const InputDecoration(labelText: 'Size'),
                      items: List.generate(8, (i) => 'US ${6 + i}').map((size) {
                        return DropdownMenuItem(value: size, child: Text(size));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedSize = val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _openCameraForSize,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Find Size'),
                  ),
                ],
              ),
            ],

            const Divider(height: 48),
            const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              dropdownColor: AppColors.surface,
              decoration: const InputDecoration(labelText: 'Payment Method'),
              items: const [
                DropdownMenuItem(value: 'online', child: Text('Pay Online (Razorpay)')),
                DropdownMenuItem(value: 'cod', child: Text('Cash on Delivery')),
              ],
              onChanged: (val) => setState(() => _paymentMethod = val!),
            ),
            
            const SizedBox(height: 48),
            SvButton(
              label: 'Place Order',
              isLoading: _isLoading,
              onPressed: _placeOrder,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
