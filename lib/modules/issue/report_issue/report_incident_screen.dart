import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/core/theme/app_text_styles.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({Key? key}) : super(key: key);

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  int _characterCount = 0;
  final int _maxCharacters = 500;

  final List<String> _selectedPhotos = [
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4',
    'https://images.unsplash.com/photo-1618941716939-553df3c6c278',
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_updateCharacterCount);
  }

  void _updateCharacterCount() {
    setState(() {
      _characterCount = _descriptionController.text.length;
    });
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_updateCharacterCount);
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.whiteColor,
        title: const Text('Report Incident'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Location Section
              const Text('Current Location', style: AppTextStyles.heading),
              const SizedBox(height: 8),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.greyColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        // Using a placeholder image instead of Google Maps static API
                        child: Container(
                          color: AppColors.lightGrey,
                          child: Center(
                            child: Image(
                              image: NetworkImage(
                                "https://storage.googleapis.com/gweb-uniblog-publish-prod/images/blurry_images_ML.width-500.format-webp.webp",
                              ),
                              fit: BoxFit.cover,
                              width:
                                  double
                                      .infinity, // Optionally control width/height
                              height: double.infinity,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '123 Security Ave, Downtown',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '40.7128° N, 74.0060° W',
                            style: TextStyle(
                              color: AppColors.greyColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Incident Photos Section
              const Text('Incident Photos', style: AppTextStyles.heading),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Add Photos Button
                    GestureDetector(
                      onTap: () {
                        // Add photo functionality would go here
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.greyColor.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add, color: AppColors.greyColor),
                            const SizedBox(height: 2),
                            Text(
                              'Add Photos',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.greyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Selected Photos
                    ..._selectedPhotos
                        .map(
                          (photoUrl) => Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(photoUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  // Remove photo functionality would go here
                                  setState(() {
                                    _selectedPhotos.remove(photoUrl);
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  margin: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: AppColors.blackColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),

                    // Empty photo placeholder
                    Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.lightGrey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Incident Description Section
              const Text('Incident Description', style: AppTextStyles.heading),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.greyColor.withOpacity(0.3),
                  ),
                ),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 8,
                  maxLength: _maxCharacters,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(_maxCharacters),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Describe the incident in detail...',
                    hintStyle: AppTextStyles.hint,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                    counterText: '',
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '$_characterCount/$_maxCharacters',
                    style: TextStyle(color: AppColors.greyColor, fontSize: 12),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '* Required fields must be filled',
                style: TextStyle(color: AppColors.error, fontSize: 12),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    // Submit functionality would go here
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.whiteColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Submit Report',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
