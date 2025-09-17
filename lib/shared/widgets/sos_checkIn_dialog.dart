import 'package:flutter/material.dart';
import 'package:security_guard/data/services/sos_checkin_service.dart';

class SosCheckInDialog extends StatefulWidget {
  final String? checkInId; // Add this parameter

  const SosCheckInDialog({Key? key, this.checkInId}) : super(key: key);

  @override
  State<SosCheckInDialog> createState() => _SosCheckInDialogState();
}

class _SosCheckInDialogState extends State<SosCheckInDialog>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _timerController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _timerAnimation;

  final SosCheckInService sosService = SosCheckInService.instance;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _timerController = AnimationController(
      duration: Duration(minutes: sosService.responseWindowMinutes.value),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _timerAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _timerController, curve: Curves.linear));

    _pulseController.repeat(reverse: true);
    _timerController.forward();

    // Log whether this is notification-triggered or timer-triggered
    print(
      '🔔 SOS Check-in dialog initialized ${widget.checkInId != null ? "(Notification ID: ${widget.checkInId})" : "(Timer-based)"}',
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissal
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Timer indicator
              AnimatedBuilder(
                animation: _timerAnimation,
                builder: (context, child) {
                  return Column(
                    children: [
                      LinearProgressIndicator(
                        value: _timerAnimation.value,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _timerAnimation.value > 0.5
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Time remaining: ${(_timerAnimation.value * sosService.responseWindowMinutes.value).ceil()} min',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // Pulsing security icon - different color for notification vs timer
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color:
                            widget.checkInId != null
                                ? Colors
                                    .orange[100] // Orange for notification-triggered
                                : Colors.blue[100], // Blue for timer-based
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.checkInId != null
                            ? Icons
                                .notifications_active // Different icon for notifications
                            : Icons.security,
                        size: 40,
                        color:
                            widget.checkInId != null
                                ? Colors.orange
                                : Colors.blue,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              Text(
                widget.checkInId != null
                    ? 'Safety Check-In Required' // Different title for notifications
                    : 'Safety Check-In',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                widget.checkInId != null
                    ? 'You have a pending safety check-in. Please confirm your status.'
                    : 'Please confirm your status within the response window',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),

              // Show check-in ID for notification-triggered dialogs (optional)
              if (widget.checkInId != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Check-in ID: ${widget.checkInId}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 30),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.check_circle,
                      label: 'All OK',
                      color: Colors.green,
                      onTap: () {
                        Navigator.of(context).pop();
                        sosService.handleCheckInResponse(
                          CheckInStatus.allOk,
                          checkInId: widget.checkInId, // Pass the checkInId
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.emergency,
                      label: 'SOS',
                      color: Colors.red,
                      onTap: () {
                        Navigator.of(context).pop();
                        sosService.handleCheckInResponse(
                          CheckInStatus.sos,
                          checkInId: widget.checkInId, // Pass the checkInId
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    sosService.handleCheckInResponse(
                      CheckInStatus.ignore,
                      checkInId: widget.checkInId, // Pass the checkInId
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Ignore',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
