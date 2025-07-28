import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/verification_service.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  
  Map<String, bool> _verificationStatus = {
    'phone': false,
    'email': false,
    'strava': false,
  };
  
  bool _isLoading = false;
  String? _verificationId;
  bool _showCodeInput = false;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final verificationService = ref.read(verificationServiceProvider);
      final status = await verificationService.getVerificationStatus(user.uid);
      setState(() {
        _verificationStatus = status;
      });
    }
  }

  Future<void> _verifyPhone() async {
    if (_phoneController.text.isEmpty) {
      _showSnackBar('Please enter a phone number');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneController.text,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);
          await _loadVerificationStatus();
          setState(() {
            _isLoading = false;
          });
          _showSnackBar('Phone number verified successfully!');
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
          });
          _showSnackBar('Verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _showCodeInput = true;
            _isLoading = false;
          });
          _showSnackBar('Verification code sent to your phone');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.isEmpty || _verificationId == null) {
      _showSnackBar('Please enter the verification code');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _codeController.text,
      );

      await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);
      await _loadVerificationStatus();
      
      setState(() {
        _isLoading = false;
        _showCodeInput = false;
      });
      
      _showSnackBar('Phone number verified successfully!');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Invalid verification code');
    }
  }

  Future<void> _verifyEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final verificationService = ref.read(verificationServiceProvider);
      final success = await verificationService.verifyEmail();
      if (success) {
        await _loadVerificationStatus();
        _showSnackBar('Email verified successfully!');
      } else {
        _showSnackBar('Verification email sent. Please check your inbox.');
      }
    } catch (e) {
      _showSnackBar('Error sending verification email: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _connectStrava() async {
    try {
      final verificationService = ref.read(verificationServiceProvider);
      final authUrl = await verificationService.getStravaAuthUrl();
      if (authUrl != null) {
        final uri = Uri.parse(authUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          _showSnackBar('Please complete Strava authentication in your browser');
        }
      }
    } catch (e) {
      _showSnackBar('Error connecting to Strava: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Verification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verify your account to build trust in the running community',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            
            // Email Verification
            _buildVerificationCard(
              icon: Icons.email,
              title: 'Email Verification',
              subtitle: _verificationStatus['email']! 
                  ? 'Email verified' 
                  : 'Verify your email address',
              isVerified: _verificationStatus['email']!,
              onTap: _verificationStatus['email']! ? null : _verifyEmail,
            ),
            
            const SizedBox(height: 16),
            
            // Phone Verification
            _buildPhoneVerificationCard(),
            
            const SizedBox(height: 16),
            
            // Strava Verification
            _buildVerificationCard(
              icon: Icons.directions_run,
              title: 'Strava Connection',
              subtitle: _verificationStatus['strava']!
                  ? 'Connected to Strava'
                  : 'Connect your Strava account',
              isVerified: _verificationStatus['strava']!,
              onTap: _verificationStatus['strava']! ? null : _connectStrava,
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'Benefits of Verification:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('• Increased trust from other runners'),
            const Text('• Priority in popular runs'),
            const Text('• Enhanced safety features'),
            const Text('• Reduced spam and fake accounts'),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isVerified,
    VoidCallback? onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: isVerified ? Colors.green : Colors.grey,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: isVerified
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.arrow_forward_ios),
        onTap: _isLoading ? null : onTap,
      ),
    );
  }

  Widget _buildPhoneVerificationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.phone,
                  color: _verificationStatus['phone']! ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Phone Verification',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _verificationStatus['phone']!
                            ? 'Phone number verified'
                            : 'Verify your phone number',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (_verificationStatus['phone']!)
                  const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            
            if (!_verificationStatus['phone']!) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+39 123 456 7890',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              
              if (_showCodeInput) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Verification Code',
                    hintText: '123456',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyCode,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Verify Code'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyPhone,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Send Code'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}