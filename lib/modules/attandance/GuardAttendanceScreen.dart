// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:security_guard/core/theme/app_colors.dart';
// import 'package:security_guard/modules/attandance/AttendanceHistoryScreen/AttendanceHistoryScreen.dart';


// class GuardAttendanceScreen extends StatefulWidget {
//   const GuardAttendanceScreen({super.key});

//   @override
//   State<GuardAttendanceScreen> createState() => _GuardAttendanceScreenState();
// }

// class _GuardAttendanceScreenState extends State<GuardAttendanceScreen> {
//   File? _capturedImage;

//   Future<void> _capturePhoto() async {
//     final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);

//     if (pickedFile != null) {
//       setState(() {
//         _capturedImage = File(pickedFile.path);
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Column(
//         children: [
//           _buildHeader(),
//           _buildLocationInfo(),
//           _buildProfilePhoto(),
//           const SizedBox(height: 20),
//           _buildClockInButton(),
//           const SizedBox(height: 15),
//           _buildClockOutButton(),
//           const SizedBox(height: 15),
//           _buildLastAction(),
//           const Spacer(),
//           _buildLogo(),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
//       color: AppColors.primary,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: const [
//           SizedBox(height: 10),
//           Center(
//             child: Text(
//               'Guard Attendance',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           Center(
//             child: Text(
//               'Monday, May 19, 2025',
//               style: TextStyle(color: Colors.white, fontSize: 14),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLocationInfo() {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
//       decoration: BoxDecoration(color: Colors.grey[50]),
//       child: Row(
//         children: const [
//           Icon(Icons.location_on, color: Colors.green, size: 24),
//           SizedBox(width: 10),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'GPS Location Verified',
//                 style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
//               ),
//               SizedBox(height: 2),
//               Text(
//                 'Lat: 51.5074° N, Long: 0.1278° W',
//                 style: TextStyle(color: Colors.grey, fontSize: 14),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProfilePhoto() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 20),
//       child: Column(
//         children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(8),
//             child: Container(
//               width: 180,
//               height: 180,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.5),
//                     spreadRadius: 2,
//                     blurRadius: 5,
//                     offset: const Offset(0, 3),
//                   ),
//                 ],
//               ),
//               child: _capturedImage != null
//                   ? Image.file(_capturedImage!, fit: BoxFit.cover)
//                   : Container(
//                       color: Colors.grey[300],
//                       child: const Center(
//                         child: Icon(Icons.person, size: 60, color: Colors.grey),
//                       ),
//                     ),
//             ),
//           ),
//           const SizedBox(height: 15),
//           TextButton.icon(
//             onPressed: _capturePhoto,
//             icon: const Icon(Icons.camera_alt, color: Colors.blue),
//             label: const Text(
//               'Take Photo',
//               style: TextStyle(color: Colors.blue, fontSize: 16),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildClockInButton() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: SizedBox(
//         width: double.infinity,
//         height: 55,
//         child: ElevatedButton(
//           onPressed: () {
//             Get.to(() => AttendanceHistoryScreen());
//           },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.green,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           child: const Text(
//             'CLOCK IN',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildClockOutButton() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: SizedBox(
//         width: double.infinity,
//         height: 55,
//         child: ElevatedButton(
//           onPressed: () {},
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.red,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           child: const Text(
//             'CLOCK OUT',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildLastAction() {
//     return const Padding(
//       padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.check_circle, color: Colors.grey, size: 20),
//           SizedBox(width: 8),
//           Text(
//             'Last action: Clock IN at 09:00 AM',
//             style: TextStyle(color: Colors.grey, fontSize: 14),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLogo() {
//     return Center(
//       child: Container(
//         width: 50,
//         height: 50,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(8),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.3),
//               spreadRadius: 1,
//               blurRadius: 3,
//               offset: const Offset(0, 1),
//             ),
//           ],
//         ),
//         child: Stack(
//           children: [
//             Container(color: Colors.transparent),
//             Center(
//               child: Icon(Icons.shield, size: 40, color: AppColors.primary),
//             ),
//             const Center(
//               child: Text(
//                 'SECU',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 8,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
