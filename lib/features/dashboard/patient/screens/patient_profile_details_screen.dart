import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/neumorphic_card.dart';
import '../models/patient_profile_model.dart';
import '../services/patient_profile_repository.dart';

/// Visually polished Patient Profile Screen with subtle botanical leaf accents,
/// directly editable fields, device photo picker, and persistent storage.
class PatientProfileDetailsScreen extends StatefulWidget {
  const PatientProfileDetailsScreen({super.key});

  @override
  State<PatientProfileDetailsScreen> createState() =>
      _PatientProfileDetailsScreenState();
}

class _PatientProfileDetailsScreenState
    extends State<PatientProfileDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late bool _isExistingSavedProfile;

  // Snapshot for Cancel functionality
  late PatientProfileModel _snapshot;
  Uint8List? _selectedPhotoBytes;

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
    _isExistingSavedProfile =
        PatientProfileRepository.instance.hasSavedProfile;
    final profile = PatientProfileRepository.instance.profile;
    _snapshot = profile;
    _selectedPhotoBytes = profile.photoBytes;

    _fullNameController = TextEditingController(text: profile.fullName);
    _mobileController = TextEditingController(text: profile.mobileNumber);
    _emailController = TextEditingController(text: profile.email);
    _addressController = TextEditingController(text: profile.homeAddress);
    _heightController = TextEditingController(text: profile.heightCm ?? '');
    _weightController = TextEditingController(text: profile.weightKg ?? '');
    _emergencyNameController =
        TextEditingController(text: profile.emergencyContactName ?? '');
    _emergencyPhoneController =
        TextEditingController(text: profile.emergencyContactPhone ?? '');
    _allergiesController =
        TextEditingController(text: profile.allergies ?? '');
    _conditionsController =
        TextEditingController(text: profile.conditions ?? '');
    _medicationsController =
        TextEditingController(text: profile.medications ?? '');

    _selectedDob = profile.dateOfBirth;
    _selectedGender = profile.gender ?? 'Female';
    _selectedBloodGroup =
        _normalizeBloodGroup(profile.bloodGroup) ?? 'B+';
    _selectedRelationship =
        profile.emergencyContactRelationship ?? 'Father';
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF28654F),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              content:
                  const Text("Photo selected. Remember to save your profile."),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC53030),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF28654F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        content: const Text("Photo removed."),
        duration: const Duration(seconds: 2),
      ),
    );
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
                  leading: const Icon(Icons.photo_library_outlined,
                      color: Color(0xFF28654F)),
                  title: const Text("Upload from Device",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined,
                      color: Color(0xFF28654F)),
                  title: const Text("Take Photo",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                if (hasPhoto)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFD32F2F)),
                    title: const Text("Remove Photo",
                        style: TextStyle(
                            color: Color(0xFFD32F2F),
                            fontWeight: FontWeight.w600)),
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFC53030),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text("Please check required fields before saving."),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final updated = PatientProfileModel(
      fullName: _fullNameController.text.trim(),
      dateOfBirth: _selectedDob,
      gender: _selectedGender,
      bloodGroup: _selectedBloodGroup,
      mobileNumber: _mobileController.text.trim(),
      email: _emailController.text.trim(),
      homeAddress: _addressController.text.trim(),
      heightCm: _heightController.text.trim().isEmpty
          ? null
          : _heightController.text.trim(),
      weightKg: _weightController.text.trim().isEmpty
          ? null
          : _weightController.text.trim(),
      emergencyContactName: _emergencyNameController.text.trim().isEmpty
          ? null
          : _emergencyNameController.text.trim(),
      emergencyContactRelationship: _selectedRelationship,
      emergencyContactPhone: _emergencyPhoneController.text.trim().isEmpty
          ? null
          : _emergencyPhoneController.text.trim(),
      allergies: _allergiesController.text.trim().isEmpty
          ? null
          : _allergiesController.text.trim(),
      conditions: _conditionsController.text.trim().isEmpty
          ? null
          : _conditionsController.text.trim(),
      medications: _medicationsController.text.trim().isEmpty
          ? null
          : _medicationsController.text.trim(),
      photoBytes: _selectedPhotoBytes,
    );

    await PatientProfileRepository.instance.saveProfile(updated);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF28654F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text("Profile saved successfully."),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );

    // Return to Patient Dashboard after successful save
    Navigator.of(context).pop(true);
  }

  void _cancel() {
    _fullNameController.text = _snapshot.fullName;
    _mobileController.text = _snapshot.mobileNumber;
    _emailController.text = _snapshot.email;
    _addressController.text = _snapshot.homeAddress;
    _heightController.text = _snapshot.heightCm ?? '';
    _weightController.text = _snapshot.weightKg ?? '';
    _emergencyNameController.text = _snapshot.emergencyContactName ?? '';
    _emergencyPhoneController.text = _snapshot.emergencyContactPhone ?? '';
    _allergiesController.text = _snapshot.allergies ?? '';
    _conditionsController.text = _snapshot.conditions ?? '';
    _medicationsController.text = _snapshot.medications ?? '';

    setState(() {
      _selectedDob = _snapshot.dateOfBirth;
      _selectedGender = _snapshot.gender ?? 'Female';
      _selectedBloodGroup =
          _normalizeBloodGroup(_snapshot.bloodGroup) ?? 'B+';
      _selectedRelationship =
          _snapshot.emergencyContactRelationship ?? 'Father';
      _selectedPhotoBytes = _snapshot.photoBytes;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF5A756B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        content: const Text("Unsaved changes discarded."),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6FAF6),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF28654F)),
          tooltip: "Back to Dashboard",
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Patient Profile",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF233A32),
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          if (_isExistingSavedProfile)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F0E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFDCEBE2),
                      width: 1.2,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_note_rounded,
                          size: 16, color: Color(0xFF28654F)),
                      SizedBox(width: 5),
                      Text(
                        "Edit Profile",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF28654F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 18,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Photo Card at Top
                    _buildProfilePhotoHeader(isDesktop),
                    const SizedBox(height: 20),

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
                            // Date of Birth
                            Expanded(
                              flex: 2,
                              child: InkWell(
                                onTap: _selectDateOfBirth,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12.5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFDCEBE2),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Date of Birth",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF5A756B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _selectedDob == null
                                                ? "Select Date"
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
                                    horizontal: 14, vertical: 12.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE7F0E9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFDCEBE2),
                                    width: 1.2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                                      _computedAge != null
                                          ? "$_computedAge yrs"
                                          : "--",
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
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(
                                        () => _selectedBloodGroup = val);
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
                          keyboardType: TextInputType.phone,
                          hintText: "+91 98765 43210",
                          validator: (v) {
                            if (v != null && v.trim().isNotEmpty) {
                              if (v.trim().length < 8) {
                                return "Please enter a valid mobile number";
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: "Email Address",
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          hintText: "ananya.sharma@example.com",
                          validator: (v) {
                            if (v != null && v.trim().isNotEmpty) {
                              final emailRegex =
                                  RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                              if (!emailRegex.hasMatch(v.trim())) {
                                return "Please enter a valid email address";
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: "Home Address",
                          controller: _addressController,
                          hintText:
                              "Sector 62, Noida, Uttar Pradesh, India",
                          maxLines: 2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Section 3: Physical Information
                    _buildSectionCard(
                      title: "Physical Information",
                      icon: Icons.monitor_weight_outlined,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: "Height (cm)",
                                controller: _heightController,
                                keyboardType: TextInputType.number,
                                hintText: "158",
                                validator: (v) {
                                  if (v != null && v.trim().isNotEmpty) {
                                    final val = double.tryParse(v.trim());
                                    if (val == null || val <= 0) {
                                      return "Enter positive height (cm)";
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
                                hintText: "54",
                                validator: (v) {
                                  if (v != null && v.trim().isNotEmpty) {
                                    final val = double.tryParse(v.trim());
                                    if (val == null || val <= 0) {
                                      return "Enter positive weight (kg)";
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
                          hintText: "Rahul Sharma",
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                label: "Relationship",
                                value: _selectedRelationship,
                                items: _relationshipOptions,
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(
                                        () => _selectedRelationship = val);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                label: "Emergency Phone",
                                controller: _emergencyPhoneController,
                                keyboardType: TextInputType.phone,
                                hintText: "+91 98765 12340",
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
                      subtitle:
                          "Optional details to assist medical providers during consultations.",
                      children: [
                        _buildTextField(
                          label: "Known Allergies",
                          controller: _allergiesController,
                          hintText: "None reported (leave blank if none)",
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: "Existing Medical Conditions",
                          controller: _conditionsController,
                          hintText: "None reported (leave blank if none)",
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
                    const SizedBox(height: 28),

                    // Bottom Action Buttons
                    if (_isExistingSavedProfile) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _cancel,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF5A756B),
                                backgroundColor: const Color(0xFFE7F0E9),
                                side: const BorderSide(
                                    color: Color(0xFFDCEBE2), width: 1.2),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _saveProfile,
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text(
                                "Save Changes",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF28654F),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _saveProfile,
                          icon: const Icon(Icons.check_circle_outline_rounded,
                              size: 20),
                          label: const Text(
                            "Save Profile",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF28654F),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Profile Photo Header Card ---
  Widget _buildProfilePhotoHeader(bool isDesktop) {
    final hasPhoto = _selectedPhotoBytes != null;

    return NeumorphicCard(
      padding: EdgeInsets.zero,
      borderRadius: 22,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Soft botanical leaf watermark in top right corner (subtle 8% opacity)
            Positioned(
              right: -20,
              top: -15,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset(
                    ClinovaConstants.leavesAsset,
                    height: 130,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isDesktop ? 24 : 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circular Avatar with camera badge and sage border
                  InkWell(
                    onTap: _showPhotoOptionsBottomSheet,
                    borderRadius: BorderRadius.circular(44),
                    child: Stack(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFE7F0E9),
                            border: Border.all(
                              color: const Color(0xFFBED4C6),
                              width: 2.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.white,
                                offset: Offset(-2, -2),
                                blurRadius: 4,
                              ),
                              BoxShadow(
                                color: Color(0xFFBED4C6),
                                offset: Offset(2, 3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: hasPhoto
                                ? Image.memory(
                                    _selectedPhotoBytes!,
                                    fit: BoxFit.cover,
                                    width: 88,
                                    height: 88,
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.camera_alt_outlined,
                                      size: 38,
                                      color: Color(0xFF28654F),
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF28654F),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  offset: const Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: Icon(
                              hasPhoto ? Icons.edit_rounded : Icons.add_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 22),
                  // User text summary & instructions with prominent name typography
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fullNameController.text.trim().isNotEmpty
                              ? _fullNameController.text.trim()
                              : "Patient Profile",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF233A32),
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _emailController.text.trim().isNotEmpty
                              ? _emailController.text.trim()
                              : "Enter your contact and medical details below",
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF5A756B),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: _showPhotoOptionsBottomSheet,
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasPhoto
                                    ? Icons.photo_camera_rounded
                                    : Icons.add_photo_alternate_outlined,
                                size: 16,
                                color: const Color(0xFF28654F),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                hasPhoto
                                    ? "Change or remove photo"
                                    : "Add Photo from Device",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF28654F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Section Card Container with Subtle Botanical Leaf Decoration ---
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    String? subtitle,
    required List<Widget> children,
  }) {
    return NeumorphicCard(
      padding: EdgeInsets.zero,
      borderRadius: 22,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Subtle translucent botanical leaf decoration in bottom right corner (opacity 7%)
            Positioned(
              right: -25,
              bottom: -20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.07,
                  child: Image.asset(
                    ClinovaConstants.leavesAsset,
                    height: 135,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7F0E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 19, color: const Color(0xFF28654F)),
                      ),
                      const SizedBox(width: 12),
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
                        fontSize: 12,
                        color: Color(0xFF6B8A7A),
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Directly Editable TextFormField Helper ---
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
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
            if (isRequired)
              const Text(
                " *",
                style: TextStyle(
                  color: Color(0xFFD32F2F),
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
          ],
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF233A32),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF88A496),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12.5),
            isDense: true,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFDCEBE2),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF28654F),
                width: 1.8,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFD32F2F),
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFD32F2F),
                width: 1.8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Dropdown Field Helper ---
  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final matchedValue = items.contains(value) ? value : items.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF233A32),
          ),
        ),
        const SizedBox(height: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFDCEBE2),
              width: 1.2,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: matchedValue,
              isExpanded: true,
              icon: const Icon(
                Icons.arrow_drop_down_rounded,
                color: Color(0xFF28654F),
              ),
              items: items
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF233A32),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
