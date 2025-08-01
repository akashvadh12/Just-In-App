import 'package:flutter/material.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/core/theme/app_text_styles.dart';

class QRScannerWidget extends StatefulWidget {
  final VoidCallback onTap;
  final controller; // Your controller

  const QRScannerWidget({
    Key? key,
    required this.onTap,
    required this.controller,
  }) : super(key: key);

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize blink animation
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _blinkAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    ));
    
    // Start the repeating blink animation
    _blinkController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _blinkAnimation,
          builder: (context, child) {
            return Container(
              width: 280,
              height: 380,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(_blinkAnimation.value),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(_blinkAnimation.value * 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 64,
                    color: AppColors.primary.withOpacity(_blinkAnimation.value),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap to Scan QR Code',
                    style: TextStyle(
                      color: AppColors.primary.withOpacity(_blinkAnimation.value),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.controller.scannedQRData.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (widget.controller.isQRMatched.value)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Location matched! Patrol started.',
                                style: AppTextStyles.subtitle.copyWith(
                                  color: AppColors.greenColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          if (widget.controller.qrScanError.value.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                widget.controller.qrScanError.value,
                                style: AppTextStyles.subtitle.copyWith(
                                  color: AppColors.error,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
