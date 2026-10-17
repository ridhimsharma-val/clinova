import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/auth/auth_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/clinova_colors.dart';
import '../../../../shared/widgets/neumorphic_card.dart';
import '../models/patient_profile_model.dart';
import '../services/patient_profile_repository.dart';

/// Dedicated Patient Onboarding Setup page displayed after login/signup
/// if the patient profile has not yet been completed.
class PatientOnboardingScreen extends StatefulWidget {
  const PatientOnboardingScreen({super.key});

  @override
  State<PatientOnboardingScreen> createState() => _PatientOnboardingScreenState();
}

class _PatientOnboardingScreenState extends State<PatientOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  bool _isSaving = false;
  String? _errorMessage;

  // Form Controllers
  late TextEditingController _fullNameController;
  late TextEditingController _mobileController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _allergiesController;
  late TextEditingController _conditionsController;
  late TextEditingController _medicationsController;

  DateTime? _selectedDob;
  String? _selectedGender;
  String? _selectedBloodGroup;
  String? _selectedRelationship;
  Uint8List? _selectedPhotoBytes;

  final List<String> _genderOptions = [
    'Female',
    'Male',
    'Non-Binary',
    'Prefer not to say',
  ];

  final List<String> _bloodGroupOptions = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
    'Unknown / Not specified',
  ];

  final List<String> _relationshipOptions = [
    'Father',
    'Mother',
    'Spouse',
    'Sibling',
    'Child',
    'Friend',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final currentProfile = PatientProfileRepository.instance.profile;
    final currentSession = AuthConfig.authService.currentSession;

    _selectedPhotoBytes = currentProfile.photoBytes;

    // Pre-fill available details from registration/session if current profile is blank
    final initialName = currentProfile.fullName.isNotEmpty
        ? currentProfile.fullName
        : (currentSession?.name.isNotEmpty == true &&
                !currentSession!.name.toLowerCase().contains('patient')
            ? currentSession.name
            : '');
    final initialEmail = currentProfile.email.isNotEmpty
        ? currentProfile.email
        : (currentSession?.email ?? '');

    _fullNameController = TextEditingController(text: initialName);
    _mobileController = TextEditingController(text: currentProfile.mobileNumber);
    _emailController = TextEditingController(text: initialEmail);
    _addressController = TextEditingController(text: currentProfile.homeAddress);
    _heightController = TextEditingController(text: currentProfile.heightCm ?? '');
    _weightController = TextEditingController(text: currentProfile.weightKg ?? '');
    _emergencyNameController =
        TextEditingController(text: currentProfile.emergencyContactName ?? '');
    _emergencyPhoneController =
        TextEditingController(text: currentProfile.emergencyContactPhone ?? '');
    _allergiesController = TextEditingController(text: currentProfile.allergies ?? '');
    _conditionsController = TextEditingController(text: currentProfile.conditions ?? '');
    _medicationsController = TextEditingController(text: currentProfile.medications ?? '');

    _selectedDob = currentProfile.dateOfBirth;
    _selectedGender = currentProfile.gender ?? 'Female';
    _selectedBloodGroup = _normalizeBloodGroup(currentProfile.bloodGroup) ?? 'B+';
    _selectedRelationship = currentProfile.emergencyContactRelationship ?? 'Father';
  }

  String? _normalizeBloodGroup(String? bg) {
    if (bg == null) return null;
    if (bg == 'Unknown' || bg == 'Unknown / Not specified') {
      return 'Unknown / Not specified';
    }
    return bg;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  int? get _computedAge {
    if (_selectedDob == null) return null;
    final now = DateTime.now();
    int age = now.year - _selectedDob!.year;
    if (now.month < _selectedDob!.month ||
        (now.month == _selectedDob!.month && now.day < _selectedDob!.day)) {
      age--;
    }
    return age >= 0 ? age : 0;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedPhotoBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC53030),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text("Could not select image: $e"),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedPhotoBytes = null;
    });
  }

  void _showPhotoOptionsBottomSheet() {
    final hasPhoto = _selectedPhotoBytes != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF6FAF6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBED4C6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Text(
                  hasPhoto ? "Profile Photo Options" : "Add Profile Photo",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF233A32),
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF28654F)),
                  title: const Text("Upload from Device", style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF28654F)),
                  title: const Text("Take Photo", style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                if (hasPhoto)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFD32F2F)),
                    title: const Text(
                      "Remove Photo",
                      style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _removePhoto();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _selectedDob ?? DateTime(2000, 8, 15);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF28654F),
              onPrimary: Colors.white,
              surface: Color(0xFFF6FAF6),
              onSurface: Color(0xFF233A32),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  Future<void> _handleCompleteOnboarding() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = "Please complete all required fields marked with * before continuing.";
      });
      return;
    }

    if (_selectedDob == null) {
      setState(() {
        _errorMessage = "Please select your date of birth.";
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedProfile = PatientProfileModel(
        fullName: _fullNameController.text.trim(),
        dateOfBirth: _selectedDob,
        gender: _selectedGender,
        bloodGroup: _selectedBloodGroup,
        mobileNumber: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        homeAddress: _addressController.text.trim(),
        heightCm: _heightController.text.trim().isEmpty ? null : _heightController.text.trim(),
        weightKg: _weightController.text.trim().isEmpty ? null : _weightController.text.trim(),
        emergencyContactName: _emergencyNameController.text.trim().isEmpty
            ? null
            : _emergencyNameController.text.trim(),
        emergencyContactRelationship: _selectedRelationship,
        emergencyContactPhone: _emergencyPhoneController.text.trim().isEmpty
            ? null
            : _emergencyPhoneController.text.trim(),
        allergies: _allergiesController.text.trim().isEmpty ? null : _allergiesController.text.trim(),
        conditions:
            _conditionsController.text.trim().isEmpty ? null : _conditionsController.text.trim(),
        medications:
            _medicationsController.text.trim().isEmpty ? null : _medicationsController.text.trim(),
        photoBytes: _selectedPhotoBytes,
        isProfileCompleted: true,
      );

      final success = await PatientProfileRepository.instance.saveProfile(updatedProfile);

      if (!success) {
        throw Exception("Failed to persist patient profile.");
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF28654F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text("Profile setup completed successfully! Welcome to Clinova."),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // Navigate to Patient Dashboard
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.patientDashboard,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = "Could not save your profile to the database: $e. Please check your connection and try again.";
      });
    }
  }

  Future<void> _handleSignOut() async {
    await AuthConfig.authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.welcome, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: ClinovaColors.background,
      appBar: AppBar(
        backgroundColor: ClinovaColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE2EFE6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBED4C6), width: 0.8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: Color(0xFF28654F)),
                  SizedBox(width: 6),
                  Text(
                    "Mandatory Account Setup",
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF28654F),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _handleSignOut,
            icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFF5A756B)),
            label: const Text(
              "Sign Out",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5A756B),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Stack(
        children: [
          // Botanical leaf watermark in top right corner
          Positioned(
            top: -20,
            right: -25,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.08,
                child: Image.asset(
                  ClinovaConstants.leavesAsset,
                  width: isDesktop ? 220 : 160,
                  height: isDesktop ? 220 : 160,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // Botanical leaf watermark in bottom left corner
          Positioned(
            bottom: -30,
            left: -25,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.07,
                child: Transform.rotate(
                  angle: 3.14159,
                  child: Image.asset(
                    ClinovaConstants.leavesAsset,
                    width: isDesktop ? 200 : 140,
                    height: isDesktop ? 200 : 140,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 16,
              vertical: 20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card with Welcoming Copy
                      _buildHeaderCard(isDesktop),
                      const SizedBox(height: 20),

                      // Profile Photo Section Card
                      _buildPhotoCard(),
                      const SizedBox(height: 18),

                      // Section 1: Personal Information
                      _buildSectionCard(
                        title: "Personal Information",
                        icon: Icons.person_outline_rounded,
                        children: [
                          _buildTextField(
                            label: "Full Name",
                            controller: _fullNameController,
                            isRequired: true,
                            hintText: "Enter full name",
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return "Full name is required";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date of Birth Picker
                              Expanded(
                                flex: 2,
                                child: InkWell(
                                  onTap: _selectDateOfBirth,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _selectedDob == null && _errorMessage != null
                                            ? const Color(0xFFC53030)
                                            : const Color(0xFFDCEBE2),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: const [
                                            Text(
                                              "Date of Birth",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF5A756B),
                                              ),
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              "*",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFFC53030),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _selectedDob == null
                                                  ? "Select Date of Birth"
                                                  : "${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.year}",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: _selectedDob == null
                                                    ? const Color(0xFF88A496)
                                                    : const Color(0xFF233A32),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.calendar_today_rounded,
                                              size: 16,
                                              color: Color(0xFF28654F),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Age (Calculated)
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE7F0E9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFDCEBE2),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Age (Calculated)",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF5A756B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _computedAge != null ? "$_computedAge yrs" : "--",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF28654F),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              // Gender Dropdown
                              Expanded(
                                child: _buildDropdown(
                                  label: "Gender",
                                  value: _selectedGender,
                                  items: _genderOptions,
                                  isRequired: true,
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedGender = val);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Blood Group Dropdown
                              Expanded(
                                child: _buildDropdown(
                                  label: "Blood Group",
                                  value: _selectedBloodGroup,
                                  items: _bloodGroupOptions,
                                  isRequired: false,
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedBloodGroup = val);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Section 2: Contact Information
                      _buildSectionCard(
                        title: "Contact Information",
                        icon: Icons.contact_phone_outlined,
                        children: [
                          _buildTextField(
                            label: "Mobile Number",
                            controller: _mobileController,
                            isRequired: true,
                            keyboardType: TextInputType.phone,
                            hintText: "+91 98765 43210",
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return "Mobile number is required";
                              }
                              if (v.trim().length < 8) {
                                return "Please enter a valid mobile number (min 8 digits)";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: "Email Address",
                            controller: _emailController,
                            isRequired: true,
                            keyboardType: TextInputType.emailAddress,
                            hintText: "patient@example.com",
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return "Email address is required";
                              }
                              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                              if (!emailRegex.hasMatch(v.trim())) {
                                return "Please enter a valid email address";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: "Home Address",
                            controller: _addressController,
                            isRequired: true,
                            hintText: "Street address, City, State, Country",
                            maxLines: 2,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return "Home address is required";
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Section 3: Physical Information
                      _buildSectionCard(
                        title: "Physical Information",
                        icon: Icons.monitor_weight_outlined,
                        subtitle: "Optional baseline metrics for your clinical profile.",
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: "Height (cm)",
                                  controller: _heightController,
                                  keyboardType: TextInputType.number,
                                  hintText: "165",
                                  validator: (v) {
                                    if (v != null && v.trim().isNotEmpty) {
                                      final val = double.tryParse(v.trim());
                                      if (val == null || val <= 0) {
                                        return "Enter positive height";
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  label: "Weight (kg)",
                                  controller: _weightController,
                                  keyboardType: TextInputType.number,
                                  hintText: "62",
                                  validator: (v) {
                                    if (v != null && v.trim().isNotEmpty) {
                                      final val = double.tryParse(v.trim());
                                      if (val == null || val <= 0) {
                                        return "Enter positive weight";
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Section 4: Emergency Contact
                      _buildSectionCard(
                        title: "Emergency Contact",
                        icon: Icons.emergency_outlined,
                        children: [
                          _buildTextField(
                            label: "Contact Person's Name",
                            controller: _emergencyNameController,
                            isRequired: true,
                            hintText: "Full name of emergency contact",
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return "Emergency contact name is required";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildDropdown(
                                  label: "Relationship",
                                  value: _selectedRelationship,
                                  items: _relationshipOptions,
                                  isRequired: true,
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedRelationship = val);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  label: "Emergency Phone",
                                  controller: _emergencyPhoneController,
                                  isRequired: true,
                                  keyboardType: TextInputType.phone,
                                  hintText: "+91 98765 12340",
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return "Emergency phone is required";
                                    }
                                    if (v.trim().length < 8) {
                                      return "Valid phone required";
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Section 5: Medical Information (Optional)
                      _buildSectionCard(
                        title: "Medical Information",
                        icon: Icons.health_and_safety_outlined,
                        subtitle: "Optional details to assist medical providers during consultations.",
                        children: [
                          _buildTextField(
                            label: "Known Allergies",
                            controller: _allergiesController,
                            hintText: "None known (leave blank if none)",
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: "Existing Medical Conditions",
                            controller: _conditionsController,
                            hintText: "None known (leave blank if none)",
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: "Current Medications & Supplements",
                            controller: _medicationsController,
                            hintText: "None reported (leave blank if none)",
                            maxLines: 2,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Error message banner if save fails or required fields missing
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE8E8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF8B4B4), width: 1.0),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFC53030), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFC53030),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Submit Action Button
                      ElevatedButton(
                        onPressed: _isSaving ? null : _handleCompleteOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ClinovaColors.primaryAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSaving
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    "Saving Profile...",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Complete Setup & Open Dashboard",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 19, color: Colors.white),
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Sign Out link
                      Center(
                        child: TextButton(
                          onPressed: _handleSignOut,
                          child: const Text(
                            "Wrong account? Sign out",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5A756B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(bool isDesktop) {
    return NeumorphicCard(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 26 : 18,
        vertical: 22,
      ),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ClinovaColors.accentLight.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: ClinovaColors.primaryAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Complete Your Patient Profile",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: ClinovaColors.primaryText,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "Let's set up your profile so Clinova can keep your patient information organized.",
                      style: TextStyle(
                        fontSize: 13.5,
                        color: ClinovaColors.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD2E6DA), width: 0.8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF28654F)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "All required fields marked with * must be filled once to activate your medical dashboard.",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF28654F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard() {
    return NeumorphicCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 18,
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE2EFE6),
                  border: Border.all(color: const Color(0xFFBED4C6), width: 1.5),
                ),
                child: ClipOval(
                  child: _selectedPhotoBytes != null
                      ? Image.memory(
                          _selectedPhotoBytes!,
                          fit: BoxFit.cover,
                          width: 72,
                          height: 72,
                        )
                      : const Icon(
                          Icons.person_rounded,
                          size: 38,
                          color: Color(0xFF28654F),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _showPhotoOptionsBottomSheet,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF28654F),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Patient Photo (Optional)",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF233A32),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  "Upload a portrait for clinical identification across consults.",
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF5A756B),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _showPhotoOptionsBottomSheet,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.add_a_photo_outlined, size: 14, color: Color(0xFF28654F)),
                  label: Text(
                    _selectedPhotoBytes != null ? "Change photo" : "Select photo",
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF28654F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    String? subtitle,
    required List<Widget> children,
  }) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2EFE6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF28654F)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF233A32),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF5A756B),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF233A32),
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 3),
              const Text(
                "*",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC53030),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF233A32),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF88A496),
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDCEBE2), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDCEBE2), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF28654F), width: 1.6),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC53030), width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC53030), width: 1.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    bool isRequired = false,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF233A32),
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 3),
              const Text(
                "*",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC53030),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: items.contains(value) ? value : items.first,
          onChanged: onChanged,
          items: items.map((opt) {
            return DropdownMenuItem<String>(
              value: opt,
              child: Text(
                opt,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF233A32),
                ),
              ),
            );
          }).toList(),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDCEBE2), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDCEBE2), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF28654F), width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}
