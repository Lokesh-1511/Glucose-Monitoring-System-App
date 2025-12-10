import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';
import '../services/data_storage_service.dart';
import '../models/user_profile.dart';
import 'skin_tone_capture_page.dart';

/// Profile setup page where users can enter personal information
class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _storageService = DataStorageService();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  String _selectedGender = 'Male';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  /// Load existing profile from storage
  Future<void> _loadProfile() async {
    try {
      await _storageService.init();
      final profile = _storageService.loadUserProfile();

      if (mounted) {
        setState(() {
          if (profile != null) {
            _nameController.text = profile.name;
            _ageController.text = profile.age.toString();
            _heightController.text = profile.height.toString();
            _weightController.text = profile.weight.toString();
            // Ensure gender value matches dropdown options
            if (profile.gender == 'Male' || profile.gender == 'Female' || profile.gender == 'Other') {
              _selectedGender = profile.gender;
            } else {
              _selectedGender = 'Male'; // Default if invalid value
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Save profile to storage
  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _heightController.text.isEmpty ||
        _weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final profile = UserProfile(
        name: _nameController.text,
        age: int.parse(_ageController.text),
        gender: _selectedGender,
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        melaninIndex: 0,
      );

      await _storageService.saveUserProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppTopBar(title: 'User Profile'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppTopBar(title: 'User Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal Information Section
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            InputTextField(
              label: 'Name',
              hint: 'Enter your name',
              controller: _nameController,
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 16),

            InputTextField(
              label: 'Age',
              hint: 'Enter your age',
              controller: _ageController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Gender dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gender',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedGender,
                      isExpanded: true,
                      items: ['Male', 'Female', 'Other']
                          .map((gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value ?? 'Male';
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            InputTextField(
              label: 'Height (cm)',
              hint: 'Enter your height',
              controller: _heightController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            InputTextField(
              label: 'Weight (kg)',
              hint: 'Enter your weight',
              controller: _weightController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 30),

            // Skin Tone Calibration Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Skin Tone Calibration',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Calibrate your skin tone for accurate glucose readings',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Capture Skin Tone',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SkinToneCapturePage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Save button
            PrimaryButton(
              label: 'Save Profile',
              isLoading: _isSaving,
              onPressed: _saveProfile,
            ),
          ],
        ),
      ),
    );
  }
}
