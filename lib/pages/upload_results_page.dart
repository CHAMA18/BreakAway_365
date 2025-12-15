import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

/// Dedicated page for uploading assessment results. Mirrors the handed-off design
/// so admins land on a focused workspace after choosing "Upload Results".
class UploadAssessmentResultsPage extends StatefulWidget {
  const UploadAssessmentResultsPage({
    super.key,
    required this.memberId,
    required this.memberName,
    this.onNavigateBack,
  });

  final String memberId;
  final String memberName;
  final VoidCallback? onNavigateBack;

  @override
  State<UploadAssessmentResultsPage> createState() => _UploadAssessmentResultsPageState();
}

class _UploadAssessmentResultsPageState extends State<UploadAssessmentResultsPage> {
  static const List<String> _assessmentTitles = <String>[
    'Kolbe Index',
    'Guiding Genius Report',
    'Working Genius',
    'Print Assessment',
    'Guiding Truths',
    'VIA Character Assessment',
  ];

  final Map<String, PlatformFile?> _selectedFiles = {};
  final Map<String, bool> _uploadingStatus = {};
  
  // Assessment value controllers
  final Map<String, Map<String, TextEditingController>> _assessmentControllers = {};
  
  // Kolbe Index fields - K_fact, K_follow, K_quick, K_implementor, K_strengths
  final _kolbeFactController = TextEditingController();
  final _kolbeFollowController = TextEditingController();
  final _kolbeQuickController = TextEditingController();
  final _kolbeImplementorController = TextEditingController();
  final _kolbeStrengthsController = TextEditingController();
  
  // Working Genius fields - WG_zone, WG_strengths
  final _wgZoneController = TextEditingController();
  final _wgStrengthsController = TextEditingController();
  
  // Guiding Genius Time fields - GG_strengths, GG_energizing
  final _ggStrengthsController = TextEditingController();
  final _ggEnergizingController = TextEditingController();
  
  // Print Assessment fields - PA_drive, PA_sdrive
  final _paDriveController = TextEditingController();
  final _paSdriveController = TextEditingController();
  
  // Guiding Truths fields - GT_truths
  final _gtTruthsController = TextEditingController();
  
  // VIA Character Assessment fields
  final _viaTopStrengthsController = TextEditingController();
  
  @override
  void dispose() {
    _kolbeFactController.dispose();
    _kolbeFollowController.dispose();
    _kolbeQuickController.dispose();
    _kolbeImplementorController.dispose();
    _kolbeStrengthsController.dispose();
    _wgZoneController.dispose();
    _wgStrengthsController.dispose();
    _ggStrengthsController.dispose();
    _ggEnergizingController.dispose();
    _paDriveController.dispose();
    _paSdriveController.dispose();
    _gtTruthsController.dispose();
    _viaTopStrengthsController.dispose();
    super.dispose();
  }
  
  bool _hasAssessmentValues(String title) {
    switch (title) {
      case 'Kolbe Index':
        return _kolbeFactController.text.isNotEmpty ||
               _kolbeFollowController.text.isNotEmpty ||
               _kolbeQuickController.text.isNotEmpty ||
               _kolbeImplementorController.text.isNotEmpty ||
               _kolbeStrengthsController.text.isNotEmpty;
      case 'Working Genius':
        return _wgZoneController.text.isNotEmpty ||
               _wgStrengthsController.text.isNotEmpty;
      case 'Guiding Genius Report':
        return _ggStrengthsController.text.isNotEmpty ||
               _ggEnergizingController.text.isNotEmpty;
      case 'Print Assessment':
        return _paDriveController.text.isNotEmpty ||
               _paSdriveController.text.isNotEmpty;
      case 'Guiding Truths':
        return _gtTruthsController.text.isNotEmpty;
      case 'VIA Character Assessment':
        return _viaTopStrengthsController.text.isNotEmpty;
      default:
        return false;
    }
  }
  
  void _showAssessmentValuesDialog(String title, void Function(String, {bool isError}) showFeedback) {
    showDialog(
      context: context,
      builder: (ctx) => _AssessmentValuesDialog(
        title: title,
        kolbeFactController: _kolbeFactController,
        kolbeFollowController: _kolbeFollowController,
        kolbeQuickController: _kolbeQuickController,
        kolbeImplementorController: _kolbeImplementorController,
        kolbeStrengthsController: _kolbeStrengthsController,
        wgZoneController: _wgZoneController,
        wgStrengthsController: _wgStrengthsController,
        ggStrengthsController: _ggStrengthsController,
        ggEnergizingController: _ggEnergizingController,
        paDriveController: _paDriveController,
        paSdriveController: _paSdriveController,
        gtTruthsController: _gtTruthsController,
        viaTopStrengthsController: _viaTopStrengthsController,
        onSave: () {
          Navigator.of(ctx).pop();
          setState(() {}); // Refresh UI to show values indicator
          showFeedback('Assessment values saved');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = widget.memberName.isEmpty ? 'Member' : widget.memberName;
    final user = FirebaseAuth.instance.currentUser;
    final String userName = user?.displayName ?? user?.email ?? 'Admin';

    void showFeedback(String message, {bool isError = false}) {
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }

    Future<void> pickFile(String assessmentType) async {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        );

        if (result != null && result.files.isNotEmpty) {
          setState(() {
            _selectedFiles[assessmentType] = result.files.first;
          });
          showFeedback('File selected: ${result.files.first.name}');
        }
      } catch (e) {
        showFeedback('Error selecting file: $e', isError: true);
      }
    }

    Future<void> uploadAllResults() async {
      if (_selectedFiles.isEmpty) {
        showFeedback('Please select at least one file to upload', isError: true);
        return;
      }

      setState(() {
        for (final type in _selectedFiles.keys) {
          _uploadingStatus[type] = true;
        }
      });

      try {
        debugPrint('🚀 Starting upload for member: ${widget.memberName} (${widget.memberId})');
        final uploadedResults = <Map<String, dynamic>>[];

        for (final entry in _selectedFiles.entries) {
          final assessmentType = entry.key;
          final file = entry.value;

          if (file == null || file.bytes == null) {
            debugPrint('⚠️ Skipping $assessmentType - no file or bytes');
            continue;
          }

          debugPrint('📤 Uploading $assessmentType: ${file.name}');
          
          // Upload file to Firebase Storage
          final fileName = '${widget.memberId}_${assessmentType.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.${file.extension}';
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('assessment_results')
              .child(widget.memberId)
              .child(fileName);

          final uploadTask = await storageRef.putData(file.bytes!);
          final downloadUrl = await uploadTask.ref.getDownloadURL();

          debugPrint('✅ File uploaded to Storage: $downloadUrl');

          uploadedResults.add({
            'assessmentType': assessmentType,
            'fileName': file.name,
            'fileUrl': downloadUrl,
            'fileSize': file.size,
            'uploadedAt': FieldValue.serverTimestamp(),
            'uploadedBy': user?.uid,
            'uploadedByEmail': user?.email,
          });
        }

        // Save all assessment results to a single document in 'assessmentResults' collection
        // Document is uniquely identified by memberId field (doc reference to users)
        debugPrint('💾 Saving ${uploadedResults.length} assessment results to Firestore...');
        
        // Get member document reference
        final memberRef = FirebaseFirestore.instance.collection('users').doc(widget.memberId);
        
        // Check if member already has assessment results
        final existingQuery = await FirebaseFirestore.instance
            .collection('assessmentResults')
            .where('memberId', isEqualTo: memberRef)
            .limit(1)
            .get();
        
        // Prepare data to update/create
        final Map<String, dynamic> assessmentData = {
          'memberId': memberRef,
          'memberName': widget.memberName,
          'updatedAt': FieldValue.serverTimestamp(),
          'uploadedBy': user?.uid,
          'uploadedByEmail': user?.email,
        };
        
        // Add file URLs with correct field names based on assessment type
        for (final result in uploadedResults) {
          final assessmentType = result['assessmentType'] as String;
          final fileUrl = result['fileUrl'] as String;
          
          // Store file URL in appropriate field
          if (assessmentType == 'Kolbe Index') {
            assessmentData['Kolbe'] = fileUrl;
          } else if (assessmentType == 'Guiding Genius Report') {
            assessmentData['GuidingGenius'] = fileUrl;
          } else if (assessmentType == 'Guiding Truths') {
            assessmentData['GuidingTruths'] = fileUrl;
          } else if (assessmentType == 'Working Genius') {
            assessmentData['WorkingGenius'] = fileUrl;
          } else if (assessmentType == 'Print Assessment') {
            assessmentData['Print'] = fileUrl;
          } else if (assessmentType == 'VIA Character Assessment') {
            assessmentData['VIA'] = fileUrl;
          }
        }
        
        // Add Kolbe values
        if (_kolbeFactController.text.isNotEmpty || _kolbeFollowController.text.isNotEmpty ||
            _kolbeQuickController.text.isNotEmpty || _kolbeImplementorController.text.isNotEmpty) {
          assessmentData['K_fact'] = int.tryParse(_kolbeFactController.text.trim()) ?? 0;
          assessmentData['K_follow'] = int.tryParse(_kolbeFollowController.text.trim()) ?? 0;
          assessmentData['K_quick'] = int.tryParse(_kolbeQuickController.text.trim()) ?? 0;
          assessmentData['K_implementor'] = int.tryParse(_kolbeImplementorController.text.trim()) ?? 0;
          assessmentData['K_strengths'] = _kolbeStrengthsController.text.trim();
        }
        
        // Add Guiding Genius Time values
        if (_ggStrengthsController.text.isNotEmpty ||
            _ggEnergizingController.text.isNotEmpty) {
          assessmentData['GG_strengths'] = _ggStrengthsController.text.trim();
          assessmentData['GG_enegizing'] = _ggEnergizingController.text.trim();
        }
        
        // Add Working Genius values
        if (_wgZoneController.text.isNotEmpty || _wgStrengthsController.text.isNotEmpty) {
          assessmentData['WG_zone'] = _wgZoneController.text.trim();
          assessmentData['WG_strengths'] = _wgStrengthsController.text.trim();
        }
        
        // Add Print Assessment values
        if (_paDriveController.text.isNotEmpty || _paSdriveController.text.isNotEmpty) {
          assessmentData['PA_drive'] = _paDriveController.text.trim();
          assessmentData['PA_sdrive'] = _paSdriveController.text.trim();
        }
        
        // Add Guiding Truths values
        if (_gtTruthsController.text.isNotEmpty) {
          assessmentData['GT_truths'] = _gtTruthsController.text.trim();
        }
        
        // Add VIA values
        if (_viaTopStrengthsController.text.isNotEmpty) {
          assessmentData['topStrengths'] = _viaTopStrengthsController.text.trim();
        }
        
        // Update existing or create new document
        if (existingQuery.docs.isNotEmpty) {
          await existingQuery.docs.first.reference.update(assessmentData);
          debugPrint('✅ Updated assessment results for member ${widget.memberId}');
        } else {
          assessmentData['createdAt'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance.collection('assessmentResults').add(assessmentData);
          debugPrint('✅ Created new assessment results for member ${widget.memberId}');
        }

        setState(() {
          _selectedFiles.clear();
          _uploadingStatus.clear();
        });

        debugPrint('🎉 Successfully uploaded and saved all assessment results!');
        showFeedback('Successfully uploaded ${uploadedResults.length} assessment result(s) for $displayName');

        // Navigate back after a short delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          if (widget.onNavigateBack != null) {
            widget.onNavigateBack!();
          } else {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        debugPrint('❌ Error uploading assessment results: $e');
        showFeedback('Error uploading files: $e', isError: true);
        setState(() {
          _uploadingStatus.clear();
        });
      }
    }

    bool hasAssessmentValues(String title) => _hasAssessmentValues(title);
    
    void showAssessmentValuesDialog(String title) => _showAssessmentValuesDialog(title, showFeedback);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Row(
        children: [
          _UploadPageSidebar(
            displayName: userName,
            onNavigateBack: widget.onNavigateBack ?? () => Navigator.of(context).pop(),
            onLogout: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
          Expanded(
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                'Upload Assessment Results for $displayName',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            _PrimaryActionButton(
                              label: 'Enter Results',
                              onPressed: () => showFeedback('Manual entry flow is coming soon'),
                              height: 44,
                              horizontalPadding: 24,
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x140F172A),
                                blurRadius: 30,
                                offset: Offset(0, 20),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              LayoutBuilder(
                                builder: (BuildContext context, BoxConstraints constraints) {
                                  final bool useTwoColumns = constraints.maxWidth >= 720;
                                  final double cardWidth = useTwoColumns
                                      ? (constraints.maxWidth - 32) / 2
                                      : constraints.maxWidth;

                                  return Wrap(
                                    spacing: 32,
                                    runSpacing: 32,
                                    children: _assessmentTitles
                                        .map(
                                          (String title) => SizedBox(
                                            width: cardWidth,
                                            child: _AssessmentUploadCard(
                                              title: title,
                                              selectedFile: _selectedFiles[title],
                                              isUploading: _uploadingStatus[title] ?? false,
                                              onTap: () => pickFile(title),
                                              onEditValues: () => _showAssessmentValuesDialog(title, showFeedback),
                                              hasValues: _hasAssessmentValues(title),
                                            ),
                                          ),
                                        )
                                        .toList(growable: false),
                                  );
                                },
                              ),
                              const SizedBox(height: 36),
                              Align(
                                alignment: Alignment.centerRight,
                                child: _PrimaryActionButton(
                                  label: _uploadingStatus.isNotEmpty ? 'Uploading...' : 'Upload Results',
                                  onPressed: _uploadingStatus.isNotEmpty ? null : uploadAllResults,
                                  height: 48,
                                  horizontalPadding: 32,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadPageSidebar extends StatelessWidget {
  const _UploadPageSidebar({
    required this.displayName,
    required this.onNavigateBack,
    required this.onLogout,
  });

  final String displayName;
  final VoidCallback onNavigateBack;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 44,
                  child: Image.asset(
                    'assets/images/Breakaway365_small_white.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.person_outline, color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Admin',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SidebarSection(
                    title: 'MAIN',
                    items: [
                      _SidebarItemData(
                        icon: Icons.arrow_back,
                        label: 'Back to Dashboard',
                        onTap: onNavigateBack,
                      ),
                      _SidebarItemData(
                        icon: Icons.upload_file,
                        label: 'Upload Results',
                        isActive: true,
                      ),
                    ],
                  ),
                  _SidebarSection(
                    title: 'USER MANAGEMENT',
                    items: [
                      _SidebarItemData(
                        icon: Icons.group_outlined,
                        label: 'Member Management',
                        onTap: onNavigateBack,
                      ),
                    ],
                  ),
                  _SidebarSection(
                    title: 'SETTINGS',
                    items: [
                      _SidebarItemData(
                        icon: Icons.logout,
                        label: 'Logout',
                        isDestructive: true,
                        onTap: onLogout,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  const _SidebarSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<_SidebarItemData> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 12),
          for (final item in items) _SidebarTile(item: item),
        ],
      ),
    );
  }
}

class _SidebarItemData {
  const _SidebarItemData({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.isDestructive = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDestructive;
  final VoidCallback? onTap;
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({required this.item});

  final _SidebarItemData item;

  @override
  Widget build(BuildContext context) {
    final bool active = item.isActive;
    final bool destructive = item.isDestructive;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: active
            ? const Color(0xFFEFF5FF)
            : destructive
                ? const Color(0xFFFFF5F5)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: item.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: destructive
                      ? const Color(0xFFDC2626)
                      : active
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFF374151),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: destructive
                          ? const Color(0xFFDC2626)
                          : active
                              ? const Color(0xFF1D4ED8)
                              : const Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssessmentUploadCard extends StatelessWidget {
  const _AssessmentUploadCard({
    required this.title,
    required this.selectedFile,
    required this.isUploading,
    required this.onTap,
    this.onEditValues,
    this.hasValues = false,
  });

  final String title;
  final PlatformFile? selectedFile;
  final bool isUploading;
  final VoidCallback onTap;
  final VoidCallback? onEditValues;
  final bool hasValues;

  @override
  Widget build(BuildContext context) {
    final bool hasFile = selectedFile != null;
    
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        constraints: const BoxConstraints(minHeight: 180),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hasFile ? const Color(0xFF10B981) : const Color(0xFFDDE3F0),
            width: hasFile ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      if (hasFile) ...[
                        const SizedBox(height: 6),
                        Text(
                          selectedFile!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: isUploading ? null : onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isUploading
                          ? const Color(0xFF9CA3AF)
                          : hasFile
                              ? const Color(0xFF10B981)
                              : const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: isUploading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            hasFile ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isUploading ? null : onEditValues,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      side: BorderSide(
                        color: hasValues ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(
                      hasValues ? Icons.check_circle : Icons.edit_outlined,
                      size: 18,
                      color: hasValues ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                    ),
                    label: Text(
                      hasValues ? 'Values Added' : 'Add Values',
                      style: TextStyle(
                        color: hasValues ? const Color(0xFF10B981) : const Color(0xFF374151),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.onPressed,
    required this.height,
    required this.horizontalPadding,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF9CA3AF),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class _AssessmentValuesDialog extends StatelessWidget {
  const _AssessmentValuesDialog({
    required this.title,
    required this.kolbeFactController,
    required this.kolbeFollowController,
    required this.kolbeQuickController,
    required this.kolbeImplementorController,
    required this.kolbeStrengthsController,
    required this.wgZoneController,
    required this.wgStrengthsController,
    required this.ggStrengthsController,
    required this.ggEnergizingController,
    required this.paDriveController,
    required this.paSdriveController,
    required this.gtTruthsController,
    required this.viaTopStrengthsController,
    required this.onSave,
  });

  final String title;
  final TextEditingController kolbeFactController;
  final TextEditingController kolbeFollowController;
  final TextEditingController kolbeQuickController;
  final TextEditingController kolbeImplementorController;
  final TextEditingController kolbeStrengthsController;
  final TextEditingController wgZoneController;
  final TextEditingController wgStrengthsController;
  final TextEditingController ggStrengthsController;
  final TextEditingController ggEnergizingController;
  final TextEditingController paDriveController;
  final TextEditingController paSdriveController;
  final TextEditingController gtTruthsController;
  final TextEditingController viaTopStrengthsController;
  final VoidCallback onSave;

  static const Color _titleColor = Color(0xFF111827);
  static const Color _mutedColor = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _buttonBlue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(28, 24, 20, 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter $title Values',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _titleColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'These values will populate the member\'s assessment results page',
                          style: TextStyle(
                            fontSize: 14,
                            color: _mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: _mutedColor),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: _buildFieldsForAssessment(),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _buttonBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Values'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldsForAssessment() {
    switch (title) {
      case 'Kolbe Index':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the Kolbe Index scores (1-10)',
              style: TextStyle(color: _mutedColor, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildNumberField('Fact Finder (K_fact)', kolbeFactController)),
                const SizedBox(width: 16),
                Expanded(child: _buildNumberField('Follow Through (K_follow)', kolbeFollowController)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildNumberField('Quick Start (K_quick)', kolbeQuickController)),
                const SizedBox(width: 16),
                Expanded(child: _buildNumberField('Implementor (K_implementor)', kolbeImplementorController)),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField('Strengths (K_strengths)', kolbeStrengthsController,
              hint: 'Enter key strengths', maxLines: 2),
          ],
        );
      case 'Working Genius':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField('Genius Zone (WG_zone)', wgZoneController, 
              hint: 'e.g., Wonder, Invention, Discernment...'),
            const SizedBox(height: 16),
            _buildTextField('Strengths (WG_strengths)', wgStrengthsController,
              hint: 'e.g., Galvanizing, Enablement, Tenacity...'),
          ],
        );
      case 'Guiding Genius Report':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            _buildTextField('Strengths (GG_strengths)', ggStrengthsController,
              hint: 'Enter key strengths from the report', maxLines: 3),
            const SizedBox(height: 16),
            _buildTextField('Energizing (GG_enegizing)', ggEnergizingController,
              hint: 'Enter energizing activities', maxLines: 3),
          ],
        );
      case 'Print Assessment':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField('Primary Drive (PA_drive)', paDriveController,
              hint: 'e.g., Achieve, Be Noticed, Be in Charge...'),
            const SizedBox(height: 16),
            _buildTextField('Secondary Drive (PA_sdrive)', paSdriveController,
              hint: 'e.g., Be Prepared, Be Right, Be Connected...'),
          ],
        );
      case 'Guiding Truths':
        return _buildTextField('Truths (GT_truths)', gtTruthsController,
          hint: 'Enter guiding truths content', maxLines: 5);
      case 'VIA Character Assessment':
        return _buildTextField('Top Strengths', viaTopStrengthsController,
          hint: 'Enter top character strengths (comma separated)', maxLines: 3);
      default:
        return const Text('No fields available for this assessment');
    }
  }

  Widget _buildNumberField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _titleColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '0-10',
            hintStyle: TextStyle(color: _mutedColor.withValues(alpha: 0.6)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _buttonBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _titleColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _mutedColor.withValues(alpha: 0.6)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 16 : 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _buttonBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}