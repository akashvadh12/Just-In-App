import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/core/theme/app_colors.dart';

import 'package:security_guard/modules/home/view/home_view.dart';
import 'package:security_guard/modules/issue/report_issue/report_incident_screen.dart';
import 'package:security_guard/modules/petrol/views/patrol_check_in_view.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';
import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';


// Mock live chat screen
class LiveChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Chat Support'), elevation: 0),
      body: Center(child: Text('Live Chat Screen Coming Soon')),
    );
  }
}

// Legal document screen for Terms & Conditions and Privacy Policy
class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalDocumentScreen({
    required this.title,
    required this.content,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
       iconTheme: const IconThemeData(color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Markdown(
          data: content,
          styleSheet: MarkdownStyleSheet(
            h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            p: const TextStyle(fontSize: 16),
            listBullet: const TextStyle(fontSize: 16),
          ),
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
