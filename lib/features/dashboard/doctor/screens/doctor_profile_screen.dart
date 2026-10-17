import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/clinova_colors.dart';
import '../../../../shared/widgets/demo_banner.dart';
import '../../../../shared/widgets/neumorphic_card.dart';
import '../models/doctor_profile_model.dart';
import '../services/doctor_profile_repository.dart';

/// Doctor Profile Screen
///
/// Features:
/// - Circular profile photo avatar with device photo picker (Camera / Gallery / Remove) and initials fallback.
/// - Full Name & Specialization in header with edit toggle.
/// - Personal, Professional/Clinical Credentials, Contact & Workplace, and Account/Practice sections.
/// - View Mode & Edit Mode with Save Changes, Form validation, and Cancel snapshot restore.
/// - Clearly distinguishes unverified/demo credentials with subtle badges/indicators.
/// - Persists across sessions using DoctorProfileRepository (SharedPreferences).
/// - Layered botanical leaf artwork conforming to Clinova's design system.
class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  bool _isEditing = false;
  late DoctorProfileModel _snapshot;
  Uint8List? _selectedPhotoBytes;

  // Controllers
  late TextEditingController _fullNameController;
  late TextEditingController _specialtyController;
  late TextEditingController _qualificationController;
  late TextEditingController _experienceController;
  late TextEditingController _licenseController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _hospitalController;
  late TextEditingController _addressController;

  DateTime? _selectedDob;

  final List<String> _months = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    final current = DoctorProfileRepository.instance.profile;
    _snapshot = current;
    _selectedPhotoBytes = current.photoBytes;
    _selectedDob = current.dateOfBirth;

    _fullNameController = TextEditingController(text: current.fullName);
    _specialtyController = TextEditingController(text: current.specialty);
    _qualificationController = TextEditingController(text: current.qualification);
    _experienceController = TextEditingController(text: current.yearsOfExperience);
    _licenseController = TextEditingController(text: current.licenseNumber);
    _emailController = TextEditingController(text: current.email);
    _phoneController = TextEditingController(text: current.phone);
    _hospitalController = TextEditingController(text: current.hospitalName);
    _addressController = TextEditingController(text: current.clinicAddress);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _specialtyController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _licenseController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _hospitalController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    final clean = name.replaceAll('Dr.', '').trim();
    final parts = clean.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return "DR";
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return "${parts.first[0]}${parts.last[0]}".toUpperCase();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return "Not specified";
    return "${_months[dt.month - 1]} ${dt.day}, ${dt.year}";
  }

  void _startEditing() {
    final current = DoctorProfileRepository.instance.profile;
    _snapshot = current;
    _selectedPhotoBytes = current.photoBytes;
    _selectedDob = current.dateOfBirth;

    _fullNameController.text = current.fullName;
    _specialtyController.text = current.specialty;
    _qualificationController.text = current.qualification;
    _experienceController.text = current.yearsOfExperience;
    _licenseController.text = current.licenseNumber;
    _emailController.text = current.email;
    _phoneController.text = current.phone;
    _hospitalController.text = current.hospitalName;
    _addressController.text = current.clinicAddress;

    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    // Restore snapshot
    setState(() {
      _selectedPhotoBytes = _snapshot.photoBytes;
      _selectedDob = _snapshot.dateOfBirth;
      _fullNameController.text = _snapshot.fullName;
      _specialtyController.text = _snapshot.specialty;
      _qualificationController.text = _snapshot.qualification;
      _experienceController.text = _snapshot.yearsOfExperience;
      _licenseController.text = _snapshot.licenseNumber;
      _emailController.text = _snapshot.email;
      _phoneController.text = _snapshot.phone;
      _hospitalController.text = _snapshot.hospitalName;
      _addressController.text = _snapshot.clinicAddress;
      _isEditing = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updated = _snapshot.copyWith(
      fullName: _fullNameController.text.trim(),
      specialty: _specialtyController.text.trim(),
      qualification: _qualificationController.text.trim(),
      yearsOfExperience: _experienceController.text.trim(),
      licenseNumber: _licenseController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      hospitalName: _hospitalController.text.trim(),
      clinicAddress: _addressController.text.trim(),
      dateOfBirth: _selectedDob,
      photoBytes: _selectedPhotoBytes,
      clearPhoto: _selectedPhotoBytes == null,
    );

    await DoctorProfileRepository.instance.saveProfile(updated);

    if (!mounted) return;

    setState(() {
      _snapshot = updated;
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E5D46),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              "Doctor profile updated successfully.",
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              content: const Text("Photo updated. Tap 'Save Changes' to apply."),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text("Could not select image: $e"),
          ),
        );
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF6FAF7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.photo_camera_rounded, color: Color(0xFF28654F), size: 22),
                SizedBox(width: 10),
                Text(
                  "Doctor Profile Photo",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF19372B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF28654F)),
              title: const Text("Choose from Gallery", style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF28654F)),
              title: const Text("Take a Photo", style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_selectedPhotoBytes != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFC53030)),
                title: const Text(
                  "Remove Current Photo",
                  style: TextStyle(color: Color(0xFFC53030), fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedPhotoBytes = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF5A756B),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      content: const Text("Photo removed. Tap 'Save Changes' to apply."),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(1985, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF28654F),
              onPrimary: Colors.white,
              surface: Color(0xFFF7FBF8),
              onSurface: Color(0xFF19372B),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    return StreamBuilder<DoctorProfileModel>(
      stream: DoctorProfileRepository.instance.profileStream,
      initialData: DoctorProfileRepository.instance.profile,
      builder: (context, snapshot) {
        final profile = snapshot.data ?? _snapshot;
        final displayName = _isEditing ? _fullNameController.text : profile.fullName;
        final displaySpecialty = _isEditing ? _specialtyController.text : profile.specialty;
        final initials = _getInitials(displayName.isNotEmpty ? displayName : "Doctor");

        return Scaffold(
          backgroundColor: ClinovaColors.background,
          appBar: AppBar(
            backgroundColor: ClinovaColors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E5D46)),
              tooltip: "Back to Dashboard",
              onPressed: () {
                if (_isEditing) {
                  _cancelEditing();
                }
                Navigator.of(context).pop();
              },
            ),
            title: const Text(
              "Doctor Profile",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF19372B),
                letterSpacing: -0.2,
              ),
            ),
            actions: [
              if (!_isEditing)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: TextButton.icon(
                    key: const Key('edit_doctor_profile_btn_top'),
                    onPressed: _startEditing,
                    icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF1E5D46)),
                    label: const Text(
                      "Edit Profile",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E5D46),
                      ),
                    ),
                  ),
                )
              else ...[
                TextButton(
                  key: const Key('cancel_doctor_profile_btn_top'),
                  onPressed: _cancelEditing,
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5A756B),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 14, left: 4),
                  child: ElevatedButton(
                    key: const Key('save_doctor_profile_btn_top'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF28654F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _saveProfile,
                    child: const Text(
                      "Save",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : 18,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const DemoBanner(compact: true, margin: EdgeInsets.only(bottom: 16)),

                        // SECTION A: Profile Header & Photo
                        _buildHeaderCard(
                          profile: profile,
                          displayName: displayName,
                          displaySpecialty: displaySpecialty,
                          initials: initials,
                          isDesktop: isDesktop,
                        ),
                        const SizedBox(height: 18),

                        // SECTION B: Personal Information
                        _buildPersonalInfoCard(profile),
                        const SizedBox(height: 18),

                        // SECTION C: Professional Credentials
                        _buildProfessionalInfoCard(profile),
                        const SizedBox(height: 18),

                        // SECTION D: Contact & Workplace Information
                        _buildWorkplaceInfoCard(profile),
                        const SizedBox(height: 18),

                        // SECTION E: Account & Practice Information (Read-only)
                        _buildAccountInfoCard(profile),
                        const SizedBox(height: 24),

                        // Bottom Action Controls (In edit mode)
                        if (_isEditing)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  key: const Key('cancel_doctor_profile_btn_bottom'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: const BorderSide(color: Color(0xFFBED4C6)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: _cancelEditing,
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF5A756B),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: ElevatedButton.icon(
                                  key: const Key('save_doctor_profile_btn_bottom'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF28654F),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: _saveProfile,
                                  icon: const Icon(Icons.check_rounded, size: 18),
                                  label: const Text(
                                    "Save Changes",
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- SECTION A: Profile Header & Photo ---
  Widget _buildHeaderCard({
    required DoctorProfileModel profile,
    required String displayName,
    required String displaySpecialty,
    required String initials,
    required bool isDesktop,
  }) {
    final photo = _isEditing ? _selectedPhotoBytes : profile.photoBytes;

    return NeumorphicCard(
      padding: const EdgeInsets.all(22),
      borderRadius: 20,
      child: Stack(
        children: [
          // Botanical leaf decoration in top right corner (opacity 10%, non-blocking)
          Positioned(
            right: -25,
            top: -20,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.10,
                child: Image.asset(
                  ClinovaConstants.leavesAsset,
                  height: 130,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Circular Avatar
                  Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: ClinovaColors.accentLight.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ClinovaColors.primaryAccent.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.center,
                        child: photo != null
                            ? Image.memory(
                                photo,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              )
                            : Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: ClinovaColors.primaryAccent,
                                ),
                              ),
                      ),
                      if (_isEditing)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: InkWell(
                            key: const Key('change_doctor_photo_btn'),
                            onTap: _showPhotoOptions,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF28654F),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName.isNotEmpty ? displayName : "Doctor Name",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: ClinovaColors.primaryText,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          displaySpecialty.isNotEmpty ? displaySpecialty : "Medical Practitioner",
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: ClinovaColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: ClinovaColors.primaryAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: ClinovaColors.primaryAccent.withValues(alpha: 0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: const Text(
                                "LICENSED PHYSICIAN",
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: ClinovaColors.primaryAccent,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD97706).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFD97706).withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                profile.isLicenseVerified ? "Verified Practitioner" : "Pending Verification",
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB45309),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_isEditing) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _showPhotoOptions,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 15, color: Color(0xFF28654F)),
                    label: Text(
                      photo != null ? "Change / Remove Photo" : "Upload Photo",
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF28654F),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              const Divider(height: 1, color: ClinovaColors.borderLight),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.verified_user_outlined, size: 16, color: ClinovaColors.secondaryAccent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Clinova Clinical Workspace — Verified credentials with HIPAA-compliant authorization.",
                      style: TextStyle(
                        fontSize: 12,
                        color: ClinovaColors.secondaryText,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SECTION B: Personal Information ---
  Widget _buildPersonalInfoCard(DoctorProfileModel profile) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Personal Information",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ClinovaColors.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: ClinovaColors.borderLight),
          const SizedBox(height: 12),
          if (!_isEditing) ...[
            _buildProfileRow(
              icon: Icons.person_outline_rounded,
              label: "Full Name",
              value: profile.fullName,
            ),
            _buildProfileRow(
              icon: Icons.cake_outlined,
              label: "Date of Birth",
              value: _formatDate(profile.dateOfBirth),
            ),
          ] else ...[
            _buildTextField(
              controller: _fullNameController,
              label: "Full Name *",
              hint: "e.g., Dr. Marcus Vance",
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return "Full name is required";
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Date of Birth (Optional)",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: ClinovaColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _selectDateOfBirth,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBED4C6)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(_selectedDob),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: ClinovaColors.primaryText,
                                ),
                              ),
                              const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF28654F)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- SECTION C: Professional / Clinical Credentials ---
  Widget _buildProfessionalInfoCard(DoctorProfileModel profile) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  "Clinical Credentials",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ClinovaColors.primaryText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  profile.isLicenseVerified ? "Verified License" : "Pending Review",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: ClinovaColors.borderLight),
          const SizedBox(height: 12),
          if (!_isEditing) ...[
            _buildProfileRow(
              icon: Icons.medical_services_outlined,
              label: "Specialty",
              value: profile.specialty,
            ),
            _buildProfileRow(
              icon: Icons.school_outlined,
              label: "Medical Qualification",
              value: profile.qualification,
            ),
            _buildProfileRow(
              icon: Icons.timeline_rounded,
              label: "Years of Experience",
              value: "${profile.yearsOfExperience} Years",
            ),
            _buildProfileRow(
              icon: Icons.badge_outlined,
              label: "Medical License",
              value: profile.licenseNumber,
              trailingSubtitle: profile.isLicenseVerified ? "State Medical Board Certified" : "Pending Verification",
            ),
            _buildProfileRow(
              icon: Icons.local_hospital_outlined,
              label: "Clinical Department",
              value: "Internal Medicine & Triage",
            ),
            _buildProfileRow(
              icon: Icons.check_circle_outline_rounded,
              label: "Practice Status",
              value: "Active Practitioner",
            ),
          ] else ...[
            _buildTextField(
              controller: _specialtyController,
              label: "Specialization / Department",
              hint: "e.g., General Internal Medicine",
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _qualificationController,
              label: "Medical Qualifications / Degrees",
              hint: "e.g., MBBS, MD (Internal Medicine)",
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _experienceController,
              label: "Years of Experience",
              hint: "e.g., 12",
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _licenseController,
              label: "Medical Registration / License Number",
              hint: "e.g., CLIN-8821-MD",
              helperText: "Note: Real-time verification is performed against authorized medical boards.",
            ),
          ],
        ],
      ),
    );
  }

  // --- SECTION D: Contact & Workplace Information ---
  Widget _buildWorkplaceInfoCard(DoctorProfileModel profile) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Contact & Workplace",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ClinovaColors.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: ClinovaColors.borderLight),
          const SizedBox(height: 12),
          if (!_isEditing) ...[
            _buildProfileRow(
              icon: Icons.alternate_email_rounded,
              label: "Professional Email",
              value: profile.email,
            ),
            _buildProfileRow(
              icon: Icons.phone_outlined,
              label: "Contact Phone",
              value: profile.phone,
            ),
            _buildProfileRow(
              icon: Icons.local_hospital_outlined,
              label: "Primary Hospital / Clinic",
              value: profile.hospitalName,
            ),
            _buildProfileRow(
              icon: Icons.location_on_outlined,
              label: "Practice Address",
              value: profile.clinicAddress,
            ),
          ] else ...[
            _buildTextField(
              controller: _emailController,
              label: "Professional Email",
              hint: "dr.name@hospital.org",
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v != null && v.trim().isNotEmpty && !v.contains('@')) {
                  return "Enter a valid email address";
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _phoneController,
              label: "Contact Phone Number",
              hint: "+1 (555) 000-0000",
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _hospitalController,
              label: "Clinic / Hospital Affiliation",
              hint: "e.g., St. Jude Clinical Medical Center",
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _addressController,
              label: "Practice Address",
              hint: "Building, Street, Suite",
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  // --- SECTION E: Account & Practice Information (Read-Only) ---
  Widget _buildAccountInfoCard(DoctorProfileModel profile) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Account & Practice Information",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ClinovaColors.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: ClinovaColors.borderLight),
          const SizedBox(height: 10),
          _buildProfileRow(
            icon: Icons.badge_outlined,
            label: "Doctor System ID",
            value: profile.doctorId,
          ),
          _buildProfileRow(
            icon: Icons.account_circle_outlined,
            label: "Account Email",
            value: profile.accountEmail,
          ),
          _buildProfileRow(
            icon: Icons.lock_outline_rounded,
            label: "Practice Status",
            value: profile.practiceStatus,
          ),
          _buildProfileRow(
            icon: Icons.rule_folder_outlined,
            label: "Case Review Permissions",
            value: "Full Clinical Review & Approval",
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? helperText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: ClinovaColors.secondaryText,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ClinovaColors.primaryText,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9AB2A6)),
            helperText: helperText,
            helperMaxLines: 2,
            helperStyle: const TextStyle(fontSize: 11, color: Color(0xFF6B8B7B)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFBED4C6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFBED4C6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF28654F), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String label,
    required String value,
    String? trailingSubtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: ClinovaColors.secondaryAccent),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ClinovaColors.secondaryText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ClinovaColors.primaryText,
                  ),
                ),
                if (trailingSubtitle != null)
                  Text(
                    trailingSubtitle,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFB45309),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
