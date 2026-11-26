import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/api/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  late Razorpay _razorpay;
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isPaid = false;
  int _price = 999;
  String? _error;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchPaymentStatus();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchPaymentStatus() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(ApiConstants.paymentStatus);
      if (response.statusCode == 200) {
        setState(() {
          _isPaid = response.data['isPaid'] ?? false;
          _price = response.data['price'] ?? 999;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to check payment status';
        _isLoading = false;
      });
    }
  }

  Future<void> _initiatePayment() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(ApiConstants.paymentInitiate);
      if (response.statusCode == 200) {
        final data = response.data;
        final options = {
          'key': data['keyId'],
          'amount': data['amount'],
          'currency': data['currency'] ?? 'INR',
          'order_id': data['orderId'],
          'name': 'Future Titans',
          'description': 'Course Access',
          'prefill': {
            'email': ref.read(authControllerProvider).user?.email ?? '',
          },
        };
        _razorpay.open(options);
      } else {
        setState(() {
          _error = response.data['error'] ?? 'Failed to initiate payment';
          _isProcessing = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data['error'] ?? e.message ?? 'Network error';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Verify payment with backend
    try {
      final dio = ref.read(dioProvider);
      final verifyResponse = await dio.post(ApiConstants.paymentVerify, data: {
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
      });

      if (verifyResponse.statusCode == 200) {
        setState(() {
          _isPaid = true;
          _isProcessing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful! Welcome to Future Titans.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Payment received but verification failed. Please contact support.';
        _isProcessing = false;
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isProcessing = false;
      _error = 'Payment failed: ${response.message}';
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet selected: ${response.walletName}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Payment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isPaid
              ? _buildAlreadyPaidView()
              : _buildPaymentView(),
    );
  }

  Widget _buildAlreadyPaidView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, size: 80, color: Colors.green.shade600),
            ),
            const SizedBox(height: 24),
            Text(
              'You\'re All Set!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You already have full course access.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Continue Learning'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pricing Header
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGold, AppTheme.primaryGoldDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGold.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.workspace_premium, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Future Titans Course',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'One-time payment for complete access',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹$_price',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      ' one-time',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Features
          const Text(
            'What\'s included',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(Icons.check_circle, 'All Masterclass Modules & Chapters'),
          _buildFeatureRow(Icons.check_circle, 'zunnova AI Mentoring Chat'),
          _buildFeatureRow(Icons.check_circle, 'Startup Idea Submission'),
          _buildFeatureRow(Icons.check_circle, 'SSI Score & Achievements'),
          const SizedBox(height: 32),

          // Error
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
            ),

          // Pay Button
          ElevatedButton(
            onPressed: _isProcessing ? null : _initiatePayment,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Pay ₹$_price Now',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Secure payment powered by Razorpay. By proceeding, you agree to our Terms of Service.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryGoldDark, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: AppTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
