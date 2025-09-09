import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({super.key, required this.camera});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final controller = CameraController(widget.camera, ResolutionPreset.high);

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    // Hot reload/restart safety
    if (_controller != null) {
      _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      _initializeCamera();
    }
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final XFile file = await _controller!.takePicture();
    if (mounted) {
      Navigator.pop(context, File(file.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitialized && _controller != null
          ? Stack(
              children: [
                CameraPreview(_controller!),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: FloatingActionButton(
                      onPressed: _takePhoto,
                      child: const Icon(Icons.camera_alt),
                    ),
                  ),
                )
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
