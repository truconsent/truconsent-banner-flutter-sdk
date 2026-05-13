import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/rights_center_api.dart';

Color _hexToColor(String hex) {
  final clean = hex.replaceAll('#', '');
  final full = clean.length == 6 ? 'FF$clean' : clean;
  return Color(int.parse(full, radix: 16));
}

/// Native Flutter implementation of Rights Center.
///
/// Provides a comprehensive rights management interface with native tabs for:
/// - Consent: View and manage all consent records
/// - Rights: Exercise data rights (access, deletion)
/// - Nominee: Appoint and manage nominees
/// - Grievance: Submit and view grievance tickets
/// - Transparency: View transparency information
/// - DPO: Data Protection Officer contact information
///
/// Tabs are shown/hidden based on [RightsCenterSettings] fetched from the API.
///
/// Example:
/// ```dart
/// NativeRightCenter(
///   userId: 'user-123',
///   apiKey: 'your-api-key',
///   organizationId: 'your-org-id',
///   apiUrl: 'https://trukit-dev.truconsent.io',
/// )
/// ```
class NativeRightCenter extends StatefulWidget {
  final String userId;
  final String? apiKey;
  final String? organizationId;
  final String? apiUrl;
  final String? assetId;
  final String? authToken;

  const NativeRightCenter({
    super.key,
    required this.userId,
    this.apiKey,
    this.organizationId,
    this.apiUrl,
    this.assetId,
    this.authToken,
  });

  @override
  State<NativeRightCenter> createState() => _NativeRightCenterState();
}

class _NativeRightCenterState extends State<NativeRightCenter> {
  late RightsCenterApi _api;

  // Theme helpers — derived from _settings after fetch
  Color get _bgColor => _hexToColor(_settings.backgroundColor);
  Color get _primaryText => _hexToColor(_settings.primaryTextColor);
  Color get _secondaryText => _hexToColor(_settings.secondaryTextColor);
  Color get _btnColor => _hexToColor(_settings.buttonColor);
  Color get _btnTextColor => _hexToColor(_settings.buttonTextColor);

  // Global
  bool _isInitializing = true;
  RightsCenterSettings _settings = RightsCenterSettings.defaults;
  String _activeTab = 'Consent';

  // Consent
  List<Map<String, dynamic>> _consents = [];
  Map<String, String> _initialConsents = {};
  bool _consentsLoading = false;
  bool _dirty = false;
  Set<String> _changedPurposeIds = {};
  bool _showSaveSuccess = false;

  // Rights
  bool _showAccessModal = false;
  bool _showDeleteModal = false;
  bool _accessConfirmed = false;
  bool _deleteConfirmed = false;

  // DPO
  DPOInfo? _dpoInfo;

  // Nominee
  List<Nominee> _nominees = [];
  bool _editing = false;
  final _nomineeFormKey = GlobalKey<FormState>();
  final Map<String, String> _nomineeForm = {
    'nominee_name': '',
    'relationship': '',
    'nominee_email': '',
    'nominee_mobile': '',
    'purpose_of_appointment': '',
  };

  // Grievance
  List<GrievanceTicket> _tickets = [];
  bool _showGrievanceForm = false;
  final _grievanceFormKey = GlobalKey<FormState>();
  final Map<String, String> _grievanceForm = {
    'subject': '',
    'category': '',
    'description': '',
  };

  @override
  void initState() {
    super.initState();
    _api = RightsCenterApi(
      apiUrl: widget.apiUrl ?? 'https://trukit-dev.truconsent.io',
      apiKey: widget.apiKey ?? '',
      organizationId: widget.organizationId ?? '',
      userId: widget.userId,
    );
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _isInitializing = true);
    await Future.wait([
      _fetchSettings(),
      _fetchDPO(),
      _fetchNominees(),
      _fetchTickets(),
      _fetchUserConsents(),
    ]);
    if (mounted) setState(() => _isInitializing = false);
  }

  Future<void> _fetchSettings() async {
    try {
      final s = await _api.getRightsCenterSettings(assetId: widget.assetId);
      if (mounted) setState(() => _settings = s);
    } catch (e) {
      debugPrint('[NativeRightCenter] fetchSettings error: $e');
    }
  }

  Future<void> _fetchUserConsents() async {
    if (mounted) setState(() => _consentsLoading = true);
    try {
      final list = await _api.getUserConsentsFlat(
        widget.userId,
        assetId: widget.assetId,
      );
      if (mounted) {
        setState(() {
          _consents = list;
          _initialConsents = {
            for (final p in list) p['id'].toString(): p['consented'].toString()
          };
          _dirty = false;
          _changedPurposeIds = {};
        });
      }
    } catch (e) {
      debugPrint('[NativeRightCenter] fetchUserConsents error: $e');
      if (mounted) setState(() => _consents = []);
    } finally {
      if (mounted) setState(() => _consentsLoading = false);
    }
  }

  Future<void> _fetchDPO() async {
    try {
      final info = await _api.getDPOInfo();
      if (mounted) setState(() => _dpoInfo = info);
    } catch (e) {
      debugPrint('[NativeRightCenter] fetchDPO error: $e');
    }
  }

  Future<void> _fetchNominees() async {
    try {
      final data = await _api.getNominees(widget.userId);
      if (mounted) {
        setState(() {
          _nominees = data;
          if (data.isNotEmpty) {
            final n = data.first;
            _nomineeForm['nominee_name'] = n.nominee_name;
            _nomineeForm['relationship'] = n.relationship;
            _nomineeForm['nominee_email'] = n.nominee_email;
            _nomineeForm['nominee_mobile'] = n.nominee_mobile;
            _nomineeForm['purpose_of_appointment'] = n.purpose_of_appointment ?? '';
          }
        });
      }
    } catch (e) {
      debugPrint('[NativeRightCenter] fetchNominees error: $e');
      if (mounted) setState(() => _nominees = []);
    }
  }

  Future<void> _fetchTickets() async {
    try {
      final data = await _api.getGrievanceTickets(widget.userId);
      if (mounted) setState(() => _tickets = data);
    } catch (e) {
      debugPrint('[NativeRightCenter] fetchTickets error: $e');
      if (mounted) setState(() => _tickets = []);
    }
  }

  // ─── Consent handlers ────────────────────────────────────────────────────────

  void _toggleConsent(String id) {
    setState(() {
      _consents = _consents.map((p) {
        if (p['id'].toString() == id) {
          final cur = p['consented'] == 'accepted' ? 'declined' : 'accepted';
          return {...p, 'consented': cur};
        }
        return p;
      }).toList();

      // Track changed vs initial
      final cur = _consents.firstWhere((p) => p['id'].toString() == id)['consented'];
      final initial = _initialConsents[id] ?? 'declined';
      if (cur != initial) {
        _changedPurposeIds.add(id);
      } else {
        _changedPurposeIds.remove(id);
      }
      _dirty = _changedPurposeIds.isNotEmpty;
    });
  }

  Future<void> _saveConsents() async {
    try {
      final changed = _consents
          .where((p) => _changedPurposeIds.contains(p['id'].toString()))
          .map((p) => Map<String, dynamic>.from(p))
          .toList();

      await _api.saveConsentToRightsCenter(
        widget.userId,
        changed,
        assetId: widget.assetId,
      );

      setState(() {
        _dirty = false;
        _changedPurposeIds = {};
        _showSaveSuccess = true;
        _initialConsents = {
          for (final p in _consents) p['id'].toString(): p['consented'].toString()
        };
      });

      // Hide success banner after 3 s
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showSaveSuccess = false);
      });

      await _fetchUserConsents();
    } catch (e) {
      debugPrint('[NativeRightCenter] saveConsents error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save consent changes. Please try again.')),
        );
      }
    }
  }

  // ─── Rights handlers ─────────────────────────────────────────────────────────

  Future<void> _requestAccess() async {
    try {
      await _api.createAccessRequest(widget.userId, assetId: widget.assetId);
      if (mounted) {
        setState(() {
          _accessConfirmed = true;
          _showAccessModal = false;
        });
      }
    } catch (e) {
      debugPrint('[NativeRightCenter] createAccessRequest error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit access request. Please try again.')),
        );
      }
    }
  }

  Future<void> _requestDeletion() async {
    try {
      await _api.createDeletionRequest(widget.userId, assetId: widget.assetId);
      if (mounted) {
        setState(() {
          _deleteConfirmed = true;
          _showDeleteModal = false;
        });
      }
    } catch (e) {
      debugPrint('[NativeRightCenter] createDeletionRequest error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit deletion request. Please try again.')),
        );
      }
    }
  }

  // ─── Nominee handlers ─────────────────────────────────────────────────────────

  Future<void> _submitNominee() async {
    if (!_nomineeFormKey.currentState!.validate()) return;
    final nominee = _nominees.isNotEmpty ? _nominees.first : null;
    final payload = Nominee(
      nominee_name: _nomineeForm['nominee_name']!,
      relationship: _nomineeForm['relationship']!,
      nominee_email: _nomineeForm['nominee_email']!,
      nominee_mobile: _nomineeForm['nominee_mobile']!,
      purpose_of_appointment: _nomineeForm['purpose_of_appointment']?.isEmpty ?? true
          ? null
          : _nomineeForm['purpose_of_appointment'],
    );

    try {
      if (nominee != null && _editing && nominee.id != null) {
        final updated = await _api.updateNominee(nominee.id!, payload);
        setState(() {
          _nominees = [updated];
          _editing = false;
        });
      } else {
        final created = await _api.createNominee(payload, widget.userId);
        setState(() => _nominees = [created]);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nominee saved successfully')),
        );
      }
    } catch (e) {
      debugPrint('[NativeRightCenter] submitNominee error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save nominee. Please try again.')),
        );
      }
    }
  }

  Future<void> _deleteNominee() async {
    final nominee = _nominees.isNotEmpty ? _nominees.first : null;
    if (nominee?.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Nominee'),
        content: const Text('Are you sure you want to delete this nominee?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.deleteNominee(nominee!.id!);
        setState(() {
          _nominees = [];
          _nomineeForm.updateAll((_, __) => '');
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nominee deleted successfully')),
          );
        }
      } catch (e) {
        debugPrint('[NativeRightCenter] deleteNominee error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete nominee. Please try again.')),
          );
        }
      }
    }
  }

  // ─── Grievance handlers ───────────────────────────────────────────────────────

  Future<void> _submitGrievance() async {
    if (!_grievanceFormKey.currentState!.validate()) return;

    final ticket = GrievanceTicket(
      subject: _grievanceForm['subject']!,
      category: _grievanceForm['category']!,
      description: _grievanceForm['description']!,
    );

    try {
      final created = await _api.createGrievanceTicket(ticket, widget.userId);
      setState(() {
        _tickets = [created, ..._tickets];
        _showGrievanceForm = false;
        _grievanceForm.updateAll((_, __) => '');
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grievance ticket created successfully')),
        );
      }
    } catch (e) {
      debugPrint('[NativeRightCenter] submitGrievance error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create grievance ticket. Please try again.')),
        );
      }
    }
  }

  // ─── Tab list ─────────────────────────────────────────────────────────────────

  List<String> get _enabledTabs {
    final tabs = <String>[];
    if (_settings.showConsentsSection) tabs.add('Consent');
    if (_settings.showRightsSection) tabs.add('Rights');
    if (_settings.showNomineesSection) tabs.add('Nominee');
    if (_settings.showGrievanceSection) tabs.add('Grievance');
    if (_settings.showTransparencySection) tabs.add('Transparency');
    if (_settings.showDpoSection) tabs.add('DPO');
    if (tabs.isEmpty) tabs.add('Consent'); // fallback
    return tabs;
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading Rights Center...'),
          ],
        ),
      );
    }

    final tabs = _enabledTabs;
    if (!tabs.contains(_activeTab)) {
      _activeTab = tabs.first;
    }

    return ColoredBox(
      color: _bgColor,
      child: Column(
        children: [
          // Tab bar
          Container(
            color: _bgColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tabs.map((tab) => _buildTabButton(tab)).toList(),
              ),
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: _buildTabContent(_activeTab),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label) {
    final isActive = _activeTab == label;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? _btnColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? _btnColor : _secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(String tab) {
    switch (tab) {
      case 'Consent':
        return _buildConsentTab();
      case 'Rights':
        return _buildRightsTab();
      case 'Nominee':
        return _buildNomineeTab();
      case 'Grievance':
        return _buildGrievanceTab();
      case 'Transparency':
        return _buildTransparencyTab();
      case 'DPO':
        return _buildDPOTab();
      default:
        return _buildConsentTab();
    }
  }

  // ─── Consent Tab ──────────────────────────────────────────────────────────────

  Widget _buildConsentTab() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _settings.consentsSectionTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _primaryText,
                  ),
                ),
              ),
              if (_dirty) ...[
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveConsents,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _btnColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text('Save Changes', style: TextStyle(color: _btnTextColor)),
                ),
              ],
            ],
          ),
        ),
        if (_showSaveSuccess)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF059669), size: 18),
                SizedBox(width: 8),
                Text('Consent preferences saved successfully.',
                    style: TextStyle(color: Color(0xFF065F46))),
              ],
            ),
          ),
        if (_consentsLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_consents.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'You currently have no consent records to display.',
                style: TextStyle(color: _secondaryText),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _consents.length,
              itemBuilder: (ctx, i) => _buildConsentCard(_consents[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildConsentCard(Map<String, dynamic> p) {
    final id = p['id'].toString();
    final isMandatory = p['is_mandatory'] == true;
    final isLegitimate = p['isLegitimate'] == true;
    final consented = p['consented'] == 'accepted';
    final dataElements = (p['dataElements'] as List?)?.cast<dynamic>() ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + badges
            Row(
              children: [
                Expanded(
                  child: Text(
                    p['name'] ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _primaryText,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isMandatory)
                  _badge('Necessary', const Color(0xFFFEE2E2), const Color(0xFF991B1B))
                else if (isLegitimate)
                  _badge('Legitimate Interest', const Color(0xFFE0F2FE), const Color(0xFF0369A1))
                else
                  _badge('Optional', const Color(0xFFDCFCE7), const Color(0xFF166534)),
              ],
            ),
            const SizedBox(height: 6),
            // Expiry & processing
            if ((p['expiry_period'] ?? '').toString().isNotEmpty)
              Text(
                'Expiry: ${p['expiry_period']}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            const SizedBox(height: 8),
            // Consented status pill + toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: consented
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    consented ? 'Yes' : 'No',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: consented
                          ? const Color(0xFF065F46)
                          : const Color(0xFF991B1B),
                    ),
                  ),
                ),
                Switch(
                  value: consented,
                  onChanged: isLegitimate ? null : (_) => _toggleConsent(id),
                ),
              ],
            ),
            // Data elements chips
            if (dataElements.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: dataElements.map<Widget>((de) {
                  final name = de is Map ? (de['name'] ?? de.toString()) : de.toString();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  // ─── Rights Tab ───────────────────────────────────────────────────────────────

  Widget _buildRightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _settings.rightsSectionTitle,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primaryText),
          ),
          const SizedBox(height: 8),
          Text(
            'You can access, correct, delete, or export your data.',
            style: TextStyle(fontSize: 14, color: _secondaryText),
          ),
          const SizedBox(height: 24),

          // Access Request
          if (_accessConfirmed)
            _successBox('Your data access request has been submitted successfully.')
          else ...[
            ElevatedButton(
              onPressed: () => setState(() => _showAccessModal = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _btnColor,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text('Request to Access My Data', style: TextStyle(color: _btnTextColor)),
            ),
          ],

          const SizedBox(height: 16),

          // Delete Request
          if (_deleteConfirmed)
            _successBox('Your data deletion request has been submitted successfully.')
          else ...[
            ElevatedButton(
              onPressed: () => setState(() => _showDeleteModal = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text('Request to Delete My Data', style: TextStyle(color: _btnTextColor)),
            ),
          ],

          // Access confirmation dialog
          if (_showAccessModal)
            _buildConfirmDialog(
              title: 'Confirm Data Access Request',
              message: 'Are you sure you want to request access to your personal data?',
              confirmLabel: 'Confirm',
              confirmColor: const Color(0xFF2563EB),
              onConfirm: _requestAccess,
              onCancel: () => setState(() => _showAccessModal = false),
            ),

          // Delete confirmation dialog
          if (_showDeleteModal)
            _buildConfirmDialog(
              title: 'Confirm Data Deletion',
              message:
                  'Are you sure you want to request data deletion? This action cannot be undone.',
              confirmLabel: 'Confirm Deletion',
              confirmColor: const Color(0xFFDC2626),
              onConfirm: _requestDeletion,
              onCancel: () => setState(() => _showDeleteModal = false),
            ),
        ],
      ),
    );
  }

  Widget _successBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF059669), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: Color(0xFF065F46), fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
  }) {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _primaryText)),
            const SizedBox(height: 10),
            Text(message, style: TextStyle(fontSize: 14, color: _secondaryText)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
                    child: Text(confirmLabel, style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Nominee Tab ──────────────────────────────────────────────────────────────

  Widget _buildNomineeTab() {
    final nominee = _nominees.isNotEmpty ? _nominees.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _settings.nomineesSectionTitle,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primaryText),
          ),
          const SizedBox(height: 16),
          // Warning box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Your nominee will be able to exercise all data rights on your behalf.',
              style: TextStyle(fontSize: 14, color: Color(0xFF92400E)),
            ),
          ),
          const SizedBox(height: 16),

          // Existing nominee (view mode)
          if (nominee != null && !_editing)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Name', nominee.nominee_name),
                    _infoRow('Relationship', nominee.relationship),
                    _infoRow('Email', nominee.nominee_email),
                    _infoRow('Mobile', nominee.nominee_mobile),
                    if (nominee.purpose_of_appointment != null && nominee.purpose_of_appointment!.isNotEmpty)
                      _infoRow('Purpose of Appointment', nominee.purpose_of_appointment!),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => setState(() => _editing = true),
                            style: ElevatedButton.styleFrom(backgroundColor: _btnColor),
                            child: Text('Edit', style: TextStyle(color: _btnTextColor)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _deleteNominee,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                            child: const Text('Delete', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            // Form mode
            Form(
              key: _nomineeFormKey,
              child: Column(
                children: [
                  _textField(
                    label: 'Name *',
                    hint: 'Full name of nominee',
                    key: 'nominee_name',
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  _dropdownField(
                    label: 'Relationship *',
                    key: 'relationship',
                    options: const ['Spouse', 'Parent', 'Child', 'Sibling', 'Other'],
                  ),
                  const SizedBox(height: 16),
                  _textField(
                    label: 'Email *',
                    hint: 'nominee@example.com',
                    key: 'nominee_email',
                    required: true,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _textField(
                    label: 'Mobile Number *',
                    hint: '+1234567890',
                    key: 'nominee_mobile',
                    required: true,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Purpose of Appointment',
                      hintText: 'Explain why you are appointing this nominee',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    initialValue: _nomineeForm['purpose_of_appointment'],
                    onChanged: (v) => _nomineeForm['purpose_of_appointment'] = v,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitNominee,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _btnColor,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text(
                      _editing ? 'Update Nominee' : 'Add Nominee',
                      style: TextStyle(color: _btnTextColor),
                    ),
                  ),
                  if (_editing) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => setState(() => _editing = false),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                      child: const Text('Cancel'),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Grievance Tab ────────────────────────────────────────────────────────────

  Widget _buildGrievanceTab() {
    // External mode
    if (_settings.grievanceMode == 'external' &&
        _settings.grievanceExternalUrl.isNotEmpty) {
      return Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.open_in_new),
          label: const Text('Open Grievance Portal'),
          onPressed: () async {
            final uri = Uri.tryParse(_settings.grievanceExternalUrl);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Grievance Tickets',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    SizedBox(height: 4),
                    Text('Submit privacy concerns or view your existing tickets',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => setState(() => _showGrievanceForm = !_showGrievanceForm),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _btnColor,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                child: Text('Create New Ticket', style: TextStyle(color: _btnTextColor, fontSize: 13)),
              ),
            ],
          ),
          if (_showGrievanceForm) ...[
            const SizedBox(height: 16),
            Form(
              key: _grievanceFormKey,
              child: Column(
                children: [
                  _textField(
                    label: 'Subject *',
                    hint: 'Brief description of your concern',
                    key: 'subject',
                    required: true,
                    formMap: _grievanceForm,
                  ),
                  const SizedBox(height: 16),
                  _dropdownField(
                    label: 'Category *',
                    key: 'category',
                    options: const ['Privacy Concern', 'Data Access', 'Other'],
                    formMap: _grievanceForm,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Detailed description of your concern or request',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    initialValue: _grievanceForm['description'],
                    onChanged: (v) => _grievanceForm['description'] = v,
                    validator: (v) => (v?.isEmpty ?? true) ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitGrievance,
                          style: ElevatedButton.styleFrom(backgroundColor: _btnColor),
                          child: Text('Submit Ticket', style: TextStyle(color: _btnTextColor)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _showGrievanceForm = false),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text('Your Tickets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          if (_tickets.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No tickets found. Create your first grievance ticket above.'),
              ),
            )
          else
            ..._tickets.map((ticket) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(ticket.subject,
                                  style: const TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                ticket.status ?? 'Open',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
                              ),
                            ),
                          ],
                        ),
                        if (ticket.ticket_id != null) ...[
                          const SizedBox(height: 4),
                          Text('Ticket #${ticket.ticket_id}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        ],
                        const SizedBox(height: 6),
                        Text(ticket.category,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        Text(ticket.description,
                            style:
                                const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5)),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  // ─── Transparency Tab ─────────────────────────────────────────────────────────

  Widget _buildTransparencyTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transparency',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primaryText)),
          const SizedBox(height: 8),
          Text(
            _settings.transparencyDescription.isNotEmpty
                ? _settings.transparencyDescription
                : 'We collect your data to provide better services and comply with regulations. '
                    'Your data is stored securely and used only for the purposes you\'ve consented to.',
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
          ),
        ],
      ),
    );
  }

  // ─── DPO Tab ──────────────────────────────────────────────────────────────────

  Widget _buildDPOTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DPO Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primaryText)),
          const SizedBox(height: 16),
          if (_dpoInfo == null)
            const Text('No DPO information available.',
                style: TextStyle(color: Color(0xFF64748B)))
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow('Full Name', _dpoInfo!.full_name ?? 'N/A'),
                    _infoRow('Email', _dpoInfo!.email ?? 'N/A'),
                    _infoRow('Appointment Date', _dpoInfo!.appointment_date ?? 'N/A'),
                    if (_settings.dpoQualificationsEnabled)
                      _infoRow('Qualifications', _dpoInfo!.qualifications ?? 'N/A'),
                    if (_settings.dpoResponsibilitiesEnabled)
                      _infoRow('Responsibilities', _dpoInfo!.responsibilities ?? 'N/A'),
                    if (_settings.dpoWorkingHoursEnabled)
                      _infoRow('Working Hours', _dpoInfo!.working_hours ?? 'N/A'),
                    if (_settings.dpoResponseTimeEnabled)
                      _infoRow('Response Time', _dpoInfo!.response_time ?? 'N/A'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Shared helpers ───────────────────────────────────────────────────────────

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: _secondaryText)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _primaryText)),
        ],
      ),
    );
  }

  Widget _textField({
    required String label,
    required String hint,
    required String key,
    bool required = false,
    TextInputType? keyboardType,
    Map<String, String>? formMap,
  }) {
    final map = formMap ?? _nomineeForm;
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      initialValue: map[key],
      onChanged: (v) => map[key] = v,
      validator: required ? (v) => (v?.isEmpty ?? true) ? '${label.replaceAll(' *', '')} is required' : null : null,
    );
  }

  Widget _dropdownField({
    required String label,
    required String key,
    required List<String> options,
    Map<String, String>? formMap,
  }) {
    final map = formMap ?? _nomineeForm;
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      value: (map[key]?.isEmpty ?? true) ? null : map[key],
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: (v) => map[key] = v ?? '',
      validator: (v) => (v?.isEmpty ?? true) ? '${label.replaceAll(' *', '')} is required' : null,
    );
  }
}
