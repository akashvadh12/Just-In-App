import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';

import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:security_guard/core/theme/app_colors.dart';

class QRScannerView extends StatefulWidget {
  final Function(QRViewController) onQRViewCreated;
  const QRScannerView({super.key, required this.onQRViewCreated});

  @override
  State<QRScannerView> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends State<QRScannerView> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isFlashOn = false;

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    widget.onQRViewCreated(ctrl);

    // Update flash status
    controller?.getFlashStatus().then((flash) {
      setState(() {
        isFlashOn = flash ?? false;
      });
    });
  }

  Future<void> _toggleFlash() async {
    if (controller != null) {
      await controller!.toggleFlash();
      final flash = await controller!.getFlashStatus();
      setState(() {
        isFlashOn = flash ?? false;
      });
    }
  }

  @override
  void dispose() {
    controller?.stopCamera(); // Ensure camera is stopped
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            onPressed: _toggleFlash,
            icon: Icon(
              isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            tooltip: isFlashOn ? "Turn off flashlight" : "Turn on flashlight",
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: AppColors.primary,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          const Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'Scan the QR code at the checkpoint',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
