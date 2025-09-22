import 'package:flutter/material.dart';
import 'package:security_guard/data/services/notification_services.dart';
import 'package:security_guard/data/services/sos_checkin_service.dart';

class SosCheckInDialog extends StatefulWidget {
  final String? checkInId;
  final int? remainingSeconds; // Optional - from API when available

  const SosCheckInDialog({Key? key, this.checkInId, this.remainingSeconds}) : super(key: key);

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

    // Use API remaining time if available, otherwise use default
    final timerDuration = widget.remainingSeconds ?? (sosService.responseWindowMinutes.value * 60);
    print('🔔 SOS Check-in dialog starting with ${timerDuration}s remaining');
    print('widget.remainingSeconds: ${widget.remainingSeconds}');
      print('sosService.responseWindowMinutes: ${sosService.responseWindowMinutes.value}');

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _timerController = AnimationController(
      duration: Duration(seconds: timerDuration-5),
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

    // Add status listener to timer controller for auto-close
    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          Navigator.of(context).pop();
          // sosService.handleCheckInResponse(
          //   CheckInStatus.miss,
          //   checkInId: widget.checkInId,
          // );
        }
      }
    });

    _timerController.forward();

    print('🔔 SOS Check-in dialog initialized with ${timerDuration}s remaining');
  }

  @override
  void dispose() {
    NotificationServices.cancelAllNotifications();
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
              // Timer indicator showing remaining time
              AnimatedBuilder(
                animation: _timerAnimation,
                builder: (context, child) {
                  final totalSeconds = widget.remainingSeconds ?? (sosService.responseWindowMinutes.value * 60);
                  final remainingSeconds = (_timerAnimation.value * totalSeconds).ceil();
                  final remainingMinutes = (remainingSeconds / 60).ceil();
                  
                  final isWarning = remainingSeconds <= 60; // Warning in last minute
                  final isCritical = remainingSeconds <= 10; // Critical when 10 seconds or less
                  
                  return Column(
                    children: [
                      LinearProgressIndicator(
                        value: _timerAnimation.value,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCritical 
                              ? Colors.red[700]!
                              : isWarning 
                                  ? Colors.red
                                  : _timerAnimation.value > 0.5
                                      ? Colors.green
                                      : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        remainingSeconds > 60 
                            ? 'Time remaining: ${remainingMinutes}m'
                            : 'Time remaining: ${remainingSeconds}s',
                        style: TextStyle(
                          fontSize: 12, 
                          color: isWarning ? Colors.red : Colors.grey[600],
                          fontWeight: isWarning ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      // Show warning text in last minute
                      if (isWarning && !isCritical) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Dialog will close automatically!',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (isCritical) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Time expired - Closing...',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // Pulsing security icon
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: widget.checkInId != null
                            ? Colors.orange[100] 
                            : Colors.blue[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.checkInId != null
                            ? Icons.notifications_active
                            : Icons.security,
                        size: 40,
                        color: widget.checkInId != null
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
                    ? 'Safety Check-In Required'
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
                          checkInId: widget.checkInId,
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
                          checkInId: widget.checkInId,
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
                      checkInId: widget.checkInId,
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