import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/emergency_service.dart';

class SOSButton extends ConsumerStatefulWidget {
  final String? runId;
  final VoidCallback? onPressed;

  const SOSButton({
    super.key,
    this.runId,
    this.onPressed,
  });

  @override
  ConsumerState<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends ConsumerState<SOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  
  bool _isHolding = false;
  bool _isTriggering = false;
  int _holdDuration = 0;
  static const int _requiredHoldTime = 3; // seconds

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.red,
      end: Colors.red.shade900,
    ).animate(_animationController);

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startHolding() {
    if (_isTriggering) return;

    setState(() {
      _isHolding = true;
      _holdDuration = 0;
    });

    HapticFeedback.heavyImpact();
    _startCountdown();
  }

  void _stopHolding() {
    setState(() {
      _isHolding = false;
      _holdDuration = 0;
    });
  }

  void _startCountdown() {
    if (!_isHolding) return;

    Future.delayed(const Duration(seconds: 1), () {
      if (_isHolding && mounted) {
        setState(() {
          _holdDuration++;
        });

        if (_holdDuration >= _requiredHoldTime) {
          _triggerSOS();
        } else {
          HapticFeedback.selectionClick();
          _startCountdown();
        }
      }
    });
  }

  void _triggerSOS() {
    if (_isTriggering) return;

    setState(() {
      _isTriggering = true;
      _isHolding = false;
    });

    HapticFeedback.heavyImpact();
    _showSOSDialog();
  }

  void _showSOSDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SOSDialog(
        runId: widget.runId,
        onConfirm: _sendEmergencyAlert,
        onCancel: () {
          setState(() {
            _isTriggering = false;
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _sendEmergencyAlert() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final emergencyService = ref.read(emergencyServiceProvider);
      await emergencyService.triggerSOS(
        userId: currentUser.uid,
        runId: widget.runId,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency alert sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onPressed?.call();
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send emergency alert: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTriggering = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GestureDetector(
          onTapDown: (_) => _startHolding(),
          onTapUp: (_) => _stopHolding(),
          onTapCancel: _stopHolding,
          child: Transform.scale(
            scale: _isHolding ? 1.1 : _scaleAnimation.value,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isHolding
                    ? Colors.red.shade800
                    : _colorAnimation.value,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: _isHolding ? 15 : 10,
                    spreadRadius: _isHolding ? 5 : 2,
                  ),
                ],
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isHolding)
                    CircularProgressIndicator(
                      value: _holdDuration / _requiredHoldTime,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  if (_isTriggering)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    )
                  else
                    const Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SOSDialog extends StatelessWidget {
  final String? runId;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const SOSDialog({
    super.key,
    this.runId,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.red, size: 28),
          SizedBox(width: 8),
          Text('Emergency Alert'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You are about to send an emergency alert that will:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 12),
          Text('• Notify your emergency contact'),
          Text('• Share your current location'),
          Text('• Alert other runners in your group'),
          Text('• Provide option to call emergency services'),
          SizedBox(height: 16),
          Text(
            'Only use this in genuine emergencies.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Send Alert'),
        ),
      ],
    );
  }
}