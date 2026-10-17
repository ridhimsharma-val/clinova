import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/clinova_colors.dart';
import '../../../../shared/widgets/demo_banner.dart';
import '../../../../shared/widgets/neumorphic_icon_container.dart';
import '../../patient/services/demo_case_repository.dart';

/// Clinova Doctor Case Queue Screen
///
/// Features:
/// - Real-time search across Case ID, patient name/ID, category, and chief complaint.
/// - Functional status filter chips: All Cases, Pending, In Review, Reviewed, Archived.
/// - Search and filter compose seamlessly.
/// - Every case card is fully clickable and opens its corresponding Case Review page.
/// - Preserves search and filter state when returning.
/// - Prominent Clinova botanical leaf decoration system.
class DoctorCaseQueueScreen extends StatefulWidget {
  final String initialFilter;
  final String initialQuery;

  const DoctorCaseQueueScreen({
    super.key,
    this.initialFilter = 'All Cases',
    this.initialQuery = '',
  });

  @override
  State<DoctorCaseQueueScreen> createState() => _DoctorCaseQueueScreenState();
}

class _DoctorCaseQueueScreenState extends State<DoctorCaseQueueScreen> {
  late String _selectedFilter;
  late final TextEditingController _searchController;
  StreamSubscription? _casesSub;

  final List<String> _filters = const [
    'All Cases',
    'Pending',
    'In Review',
    'Reviewed',
    'Archived',
  ];

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _searchController = TextEditingController(text: widget.initialQuery);
    DemoCaseRepository.instance.fetchCasesFromSupabase();

    _casesSub = DemoCaseRepository.instance.casesStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _casesSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<PatientCaseSummary> _getFilteredCases() {
    final all = DemoCaseRepository.instance.cases;
    final query = _searchController.text.trim();

    return all.where((c) {
      final matchesFilter = c.matchesFilter(_selectedFilter);
      final matchesSearch = c.matchesSearch(query);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  void _openCaseReview(PatientCaseSummary caseItem) {
    Navigator.of(context).pushNamed(
      AppRoutes.doctorCaseReview,
      arguments: caseItem,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;
    final filteredCases = _getFilteredCases();

    return Scaffold(
      backgroundColor: ClinovaColors.background,
      appBar: AppBar(
        backgroundColor: ClinovaColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E5D46)),
          tooltip: "Back to Dashboard",
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Clinical Case Queue",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF19372B),
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: RefreshIndicator(
              color: const Color(0xFF28654F),
              onRefresh: () => DemoCaseRepository.instance.fetchCasesFromSupabase(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 18,
                  vertical: 16,
                ),
                children: [
                  const DemoBanner(compact: true, margin: EdgeInsets.only(bottom: 16)),

                // Search Bar Card
                _buildSearchInput(isDesktop),
                const SizedBox(height: 14),

                // Status Filter Chips
                _buildFilterChips(),
                const SizedBox(height: 18),

                // Results Counter & Active Filter Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${filteredCases.length} ${filteredCases.length == 1 ? 'case' : 'cases'} found",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF426757),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty || _selectedFilter != 'All Cases')
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = 'All Cases';
                            _searchController.clear();
                          });
                        },
                        child: const Text(
                          "Reset filters",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E5D46),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Case Items or Polished Empty State
                if (filteredCases.isEmpty)
                  _buildEmptyState()
                else
                  ...filteredCases.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCaseQueueCard(c, isDesktop),
                      )),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  // --- Search Bar ---
  Widget _buildSearchInput(bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCECE1), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 5,
          ),
          BoxShadow(
            color: Color(0xFFBED4C6),
            offset: Offset(3, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF19372B),
        ),
        decoration: InputDecoration(
          hintText: "Search by Case ID, patient name, or complaint...",
          hintStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF7E9A8E),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: Color(0xFF28654F),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF6B8B7B)),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // --- Filter Chips ---
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              selectedColor: const Color(0xFFD6EDE0),
              backgroundColor: const Color(0xFFF7FBF8),
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF145338) : const Color(0xFF5D7B6E),
              ),
              side: BorderSide(
                color: isSelected ? const Color(0xFF1E5D46) : const Color(0xFFDCECE1),
                width: isSelected ? 1.2 : 0.8,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onSelected: (val) {
                if (val) setState(() => _selectedFilter = filter);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Case Queue Card with Botanical Leaves ---
  Widget _buildCaseQueueCard(PatientCaseSummary caseItem, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCECE1), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 5,
          ),
          BoxShadow(
            color: Color(0xFFBED4C6),
            offset: Offset(3, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _openCaseReview(caseItem),
          borderRadius: BorderRadius.circular(18),
          splashColor: const Color(0xFFE2EFE7),
          highlightColor: const Color(0xFFF0F7F2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Botanical leaf watermark in lower right corner (opacity 9%)
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.09,
                      child: Image.asset(
                        ClinovaConstants.leavesAsset,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Reference, Category, and Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              NeumorphicIconContainer(
                                size: 38,
                                iconSize: 18,
                                borderRadius: 10,
                                icon: Icons.folder_outlined,
                                iconColor: const Color(0xFF1E5D46),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    caseItem.reference,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E5D46),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  Text(
                                    "Patient: ${caseItem.patientName ?? 'Aarav Sharma'} • ${caseItem.patientId ?? 'PAT-8842'}",
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF5D7B6E),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: caseItem.statusBgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: caseItem.statusBorderColor, width: 0.8),
                            ),
                            child: Text(
                              caseItem.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: caseItem.statusTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Case Title / Chief Concern
                      Text(
                        caseItem.title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF19372B),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Metadata Row: Category & Date
                      Row(
                        children: [
                          if (caseItem.category != null && caseItem.category!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF4EE),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFD2E6DA), width: 0.8),
                              ),
                              child: Text(
                                caseItem.category!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF235843),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          const Icon(Icons.calendar_today_rounded, size: 12.5, color: Color(0xFF6B8B7B)),
                          const SizedBox(width: 4),
                          Text(
                            caseItem.date,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF5A756B),
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            "Review details →",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E5D46),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Empty State ---
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCECE1), width: 1.0),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 44, color: Color(0xFF8DA39A)),
            const SizedBox(height: 12),
            const Text(
              "No cases match your filter criteria.",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF19372B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              "Try adjusting your search terms or selecting a different status filter above.",
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF5A756B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
