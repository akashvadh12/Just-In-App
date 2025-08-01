
// Updated MobileQRScannerView with better navigation handling
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:security_guard/core/theme/app_colors.dart';

class MobileQRScannerView extends StatefulWidget {
  final void Function(String code) onScanned;

  const MobileQRScannerView({super.key, required this.onScanned});

  @override
  State<MobileQRScannerView> createState() => _MobileQRScannerViewState();
}

class _MobileQRScannerViewState extends State<MobileQRScannerView> {
  final MobileScannerController scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  
  bool isFlashOn = false;
  bool isScanHandled = false;

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  Future<void> toggleFlash() async {
    try {
      await scannerController.toggleTorch();
      setState(() {
        isFlashOn = !isFlashOn;
      });
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  void handleScan(String? code) async {
    if (isScanHandled || code == null || code.isEmpty) return;
    
    setState(() {
      isScanHandled = true;
    });

    debugPrint('QR Scanned: $code');

    // Stop the scanner first
    try {
      await scannerController.stop();
    } catch (e) {
      debugPrint('Error stopping scanner: $e');
    }

    // Close any active snackbars first to prevent GetX controller conflicts
    try {
      Get.closeAllSnackbars();
    } catch (e) {
      debugPrint('Error closing snackbars: $e');
    }

    // Navigate back safely
    if (mounted && Get.isDialogOpen != true) {
      try {
        // Use Navigator.pop as a safer alternative to Get.back()
        Navigator.of(context).pop();
        
        // Call the onScanned callback after navigation
        Future.delayed(const Duration(milliseconds: 100), () {
          widget.onScanned(code);
        });
      } catch (e) {
        debugPrint('Error navigating back: $e');
        // Fallback: just call the callback without navigation
        widget.onScanned(code);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanSize = MediaQuery.of(context).size.width * 0.7;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
            onPressed: toggleFlash,
          ),
        ],
      ),
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: MobileScanner(
              controller: scannerController,
              onDetect: (capture) {
                if (capture.barcodes.isNotEmpty) {
                  final barcode = capture.barcodes.first;
                  debugPrint('Barcode detected: ${barcode.rawValue}');
                  handleScan(barcode.rawValue);
                }
              },
            ),
          ),

          // Scanning area overlay
          Center(
            child: Container(
              width: scanSize,
              height: scanSize,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Corner brackets
          Center(
            child: SizedBox(
              width: scanSize,
              height: scanSize,
              child: Stack(
                children: [
                  // Top-left corner
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 4),
                          left: BorderSide(color: Colors.white, width: 4),
                        ),
                      ),
                    ),
                  ),
                  // Top-right corner
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 4),
                          right: BorderSide(color: Colors.white, width: 4),
                        ),
                      ),
                    ),
                  ),
                  // Bottom-left corner
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 4),
                          left: BorderSide(color: Colors.white, width: 4),
                        ),
                      ),
                    ),
                  ),
                  // Bottom-right corner
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 4),
                          right: BorderSide(color: Colors.white, width: 4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'Align the QR code within the box',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Manual close button - use Navigator.pop instead of Get.back()
                    try {
                      Get.closeAllSnackbars();
                      Navigator.of(context).pop();
                    } catch (e) {
                      debugPrint('Error closing scanner: $e');
                    }
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}