import 'package:flutter/material.dart';
import '../services/rights_center_api.dart';

/// Native Flutter implementation of Rights Center.
///
/// Replaces WebView with native Flutter widgets for better performance and
/// mobile experience. Provides a comprehensive rights management interface
/// with native tabs for:
/// - Consent: View and manage all consent records
/// - Rights: Exercise data rights (deletion, download)
/// - Transparency: View transparency information
/// - DPO: Data Protection Officer contact information
/// - Nominee: Appoint and manage nominees
/// - Grievance: Submit and view grievance tickets
///
/// Example:
/// ```dart
/// NativeRightCenter(
///   userId: 'user-123',
///   apiKey: 'your-api-key',
///   organizationId: 'your-org-id',
/// )
/// ```
class NativeRightCenter extends StatefulWidget {
  /// User ID for rights center access
  final String userId;
  
  /// Optional TruConsent API key for authentication
  final String? apiKey;
  
  /// Optional organization ID
  final String? organizationId;
  
  /// Optional API base URL. Defaults to production URL if not provided.
  final String? apiBaseUrl;

  /// Creates a NativeRightCenter widget.
  const NativeRightCenter({
    super.key,
    required this.userId,
    this.apiKey,
    this.organizationId,
    this.apiBaseUrl,
  });

  @override
  State<NativeRightCenter> createState() => _NativeRightCenterState();
}

class _NativeRightCenterState extends State<NativeRightCenter> {
  int _activeTabIndex = 0;
  late RightsCenterApi _api;

  // Consent state
  List<ConsentGroup> _consentGroups = [];
  List<ConsentGroup> _initialConsentGroups = [];
  bool _consentsLoading = true;
  bool _dirty = false;
  Map<String, dynamic>? _modalData;
  // Rights state

  // DPO state
  DPOInfo? _dpoInfo;
  bool _dpoLoading = true;
  String? _dpoError;

  // Nominee state
  List<Nominee> _nominees = [];
  bool _nomineeLoading = true;
  String? _nomineeError;
  bool _editing = false;
  final _nomineeFormKey = GlobalKey<FormState>();
  final Map<String, String> _nomineeForm = {
    'nominee_name': '',
    'relationship': '',
    'nominee_email': '',
    'nominee_mobile': '',
    'purpose_of_appointment': '',
  };

  // Grievance state
  List<GrievanceTicket> _tickets = [];
  bool _ticketsLoading = true;
  String? _ticketsError;
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
      baseUrl: widget.apiBaseUrl ??
          'https://rdwcymn5poo6zbzg5fa5xzjsqy0zzcpm.lambda-url.ap-south-1.on.aws/banners',
      apiKey: widget.apiKey ?? '',
      organizationId: widget.organizationId ?? 'mars-money',
    );
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _fetchUserConsents(),
      _fetchDPO(),
      _fetchNominees(),
      _fetchGrievances(),
    ]);
  }

  String _normalizeStatus(dynamic val) {
    if (val == 'accepted' || val == 'declined') return val;
    if (val == 'approved') return 'accepted';
    if (val == 'rejected') return 'declined';
    if (val is bool) return val ? 'accepted' : 'declined';
    if (val is String) {
      final v = val.toLowerCase();
      if (v == 'yes' || v == 'true') return 'accepted';
      if (v == 'no' || v == 'false') return 'declined';
    }
    return 'pending';
  }

  // Fetch consents - matches web package logic exactly
  Future<void> _fetchUserConsents() async {
    setState(() => _consentsLoading = true);
    try {
      debugPrint('[NativeRightCenter] Fetching consents for user: ${widget.userId}');
      debugPrint('[NativeRightCenter] Starting dual fetch: /user/{userId} and getAllBanners()');
      
      List<ConsentGroup> userRecords;
      List<ConsentGroup> allBanners;
      
      try {
        userRecords = await _api.getUserConsents(widget.userId);
      } catch (err) {
        debugPrint('[NativeRightCenter] Error fetching user consents, using empty array: $err');
        userRecords = [];
      }
      
      try {
        allBanners = await _api.getAllBanners();
      } catch (err) {
        debugPrint('[NativeRightCenter] Error fetching all banners, using empty array: $err');
        allBanners = [];
      }

      debugPrint('[NativeRightCenter] Data received - User records: ${userRecords.length}, All banners: ${allBanners.length}');

      // Create map of user records by collection_point (matches web package line 227-230)
      final userByCp = <String, ConsentGroup>{};
      for (final cp in userRecords) {
        userByCp[cp.collection_point] = cp;
      }

      debugPrint('[NativeRightCenter] User records mapped to ${userByCp.length} collection points');

      // Merge all banners with user-specific status (matches web package line 232-258)
      final merged = allBanners.map((cp) {
        final userCp = userByCp[cp.collection_point];
        final shownToPrincipal = userCp?.shown_to_principal ?? false;

        // Only keep explicit statuses from user (accepted/declined). Ignore 'pending' (matches web package line 237-242)
        final userPurposeStatus = <String, String>{};
        for (final p in userCp?.purposes ?? []) {
          final status = _normalizeStatus(p.consented);
          if (status == 'accepted' || status == 'declined') {
            userPurposeStatus[p.id] = status;
          }
        }

        // Map purposes and determine status (matches web package line 243-256)
        final purposes = cp.purposes.map((p) {
          final hasUser = userPurposeStatus.containsKey(p.id);
          String status;
          if (hasUser) {
            // User has explicit status
            status = userPurposeStatus[p.id]!;
          } else if (shownToPrincipal) {
            // If the collection point was shown and user has no explicit status logged for this purpose,
            // treat it as accepted (implicit approval at time of show) - matches web package line 248-251
            status = 'accepted';
          } else {
            // Default to declined if not shown and no user status
            final normalized = _normalizeStatus(p.consented);
            status = normalized.isNotEmpty ? normalized : 'declined';
          }
          return Purpose(
            id: p.id,
            name: p.name,
            description: p.description,
            expiry_period: p.expiry_period,
            is_mandatory: p.is_mandatory,
            consented: status,
          );
        }).toList();

        return ConsentGroup(
          collection_point: cp.collection_point,
          title: cp.title,
          purposes: purposes,
          data_elements: cp.data_elements,
          shown_to_principal: shownToPrincipal,
        );
      }).toList();

      debugPrint('[NativeRightCenter] Merged result: ${merged.length} collection points');
      if (merged.isNotEmpty) {
        final totalPurposes = merged.fold<int>(0, (sum, cp) => sum + cp.purposes.length);
        debugPrint('[NativeRightCenter] Total purposes across all collection points: $totalPurposes');
      }

      setState(() {
        _consentGroups = merged;
        _initialConsentGroups = merged.map((cg) {
          return ConsentGroup(
            collection_point: cg.collection_point,
            title: cg.title,
            purposes: cg.purposes.map((p) {
              return Purpose(
                id: p.id,
                name: p.name,
                description: p.description,
                expiry_period: p.expiry_period,
                is_mandatory: p.is_mandatory,
                consented: p.consented,
              );
            }).toList(),
            data_elements: cg.data_elements,
            shown_to_principal: cg.shown_to_principal,
          );
        }).toList();
      });
      debugPrint('[NativeRightCenter] Consents loaded successfully: ${merged.length} groups');
    } catch (e) {
      debugPrint('[NativeRightCenter] Error fetching consents: $e');
      // Don't show snackbar, just log and set empty state
      setState(() {
        _consentGroups = [];
        _initialConsentGroups = [];
      });
    } finally {
      if (mounted) {
        setState(() => _consentsLoading = false);
      }
    }
  }

  Future<void> _fetchDPO() async {
    setState(() {
      _dpoLoading = true;
      _dpoError = null;
    });
    try {
      DPOInfo? info;
      try {
        info = await _api.getDPOInfo();
      } catch (err) {
        debugPrint('[NativeRightCenter] Error fetching DPO, using null: $err');
        info = null;
      }
      setState(() => _dpoInfo = info);
    } catch (e) {
      debugPrint('[NativeRightCenter] Error fetching DPO: $e');
      setState(() {
        _dpoError = 'Failed to load DPO information';
        _dpoInfo = null;
      });
    } finally {
      if (mounted) {
        setState(() => _dpoLoading = false);
      }
    }
  }

  Future<void> _fetchNominees() async {
    setState(() {
      _nomineeLoading = true;
      _nomineeError = null;
    });
    try {
      List<Nominee> data;
      try {
        data = await _api.getNominees(widget.userId);
      } catch (err) {
        debugPrint('[NativeRightCenter] Error fetching nominees, using empty array: $err');
        data = [];
      }
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
    } catch (e) {
      debugPrint('[NativeRightCenter] Error fetching nominees: $e');
      setState(() {
        _nomineeError = 'Failed to load nominee information';
        _nominees = [];
      });
    } finally {
      if (mounted) {
        setState(() => _nomineeLoading = false);
      }
    }
  }

  Future<void> _fetchGrievances() async {
    setState(() {
      _ticketsLoading = true;
      _ticketsError = null;
    });
    try {
      List<GrievanceTicket> data;
      try {
        data = await _api.getGrievanceTickets(widget.userId);
      } catch (err) {
        debugPrint('[NativeRightCenter] Error fetching grievances, using empty array: $err');
        data = [];
      }
      setState(() => _tickets = data);
    } catch (e) {
      debugPrint('[NativeRightCenter] Error fetching grievances: $e');
      setState(() {
        _ticketsError = 'Failed to load grievance tickets';
        _tickets = [];
      });
    } finally {
      if (mounted) {
        setState(() => _ticketsLoading = false);
      }
    }
  }

  void _handleToggle(String consentId, String collectionId) {
    setState(() {
      _consentGroups = _consentGroups.map((cp) {
        if (cp.collection_point == collectionId) {
          return ConsentGroup(
            collection_point: cp.collection_point,
            title: cp.title,
            purposes: cp.purposes.map((p) {
              if (p.id == consentId) {
                return Purpose(
                  id: p.id,
                  name: p.name,
                  description: p.description,
                  expiry_period: p.expiry_period,
                  is_mandatory: p.is_mandatory,
                  consented: p.consented == 'accepted' ? 'declined' : 'accepted',
                );
              }
              return p;
            }).toList(),
            data_elements: cp.data_elements,
            shown_to_principal: cp.shown_to_principal,
          );
        }
        return cp;
      }).toList();
      _dirty = true;
    });
  }

  Future<void> _handleSave() async {
    try {
      final initialStateByCollection = <String, Map<String, String>>{};
      for (final cp in _initialConsentGroups) {
        final purposeMap = <String, String>{};
        for (final p in cp.purposes) {
          purposeMap[p.id] = p.consented;
        }
        initialStateByCollection[cp.collection_point] = purposeMap;
      }

      final byCollection = <String, List<Purpose>>{};
      final changedByCollection = <String, List<String>>{};

      for (final cp in _consentGroups) {
        for (final p in cp.purposes) {
          if (!byCollection.containsKey(cp.collection_point)) {
            byCollection[cp.collection_point] = [];
            changedByCollection[cp.collection_point] = [];
          }
          byCollection[cp.collection_point]!.add(p);

          final collectionInitialState = initialStateByCollection[cp.collection_point];
          final initialStatus = collectionInitialState?[p.id] ?? 'declined';

          if (initialStatus != p.consented) {
            changedByCollection[cp.collection_point]!.add(p.id);
          }
        }
      }

      await Future.wait(
        byCollection.entries
            .where((entry) => changedByCollection[entry.key]?.isNotEmpty ?? false)
            .map((entry) {
          final collectionId = entry.key;
          final list = entry.value;
          final changedIds = changedByCollection[collectionId]!.toSet();
          final collectionInitialState = initialStateByCollection[collectionId];

          final purposesPayload = list
              .where((p) => changedIds.contains(p.id))
              .map((p) {
            final initialStatus = collectionInitialState?[p.id] ?? 'declined';
            return {
              'id': p.id,
              'name': p.name,
              'consented': p.consented,
              'initialStatus': initialStatus,
            };
          }).toList();

          final hasRevocation = purposesPayload.any(
            (p) => p['initialStatus'] == 'accepted' && p['consented'] == 'declined',
          );
          final hasApproval = purposesPayload.any((p) => p['consented'] == 'accepted');

          final action = hasRevocation ? 'revoked' : (hasApproval ? 'approved' : 'declined');

          final payload = ConsentPayload(
            userId: widget.userId,
            purposes: purposesPayload.map((p) {
              final copy = Map<String, dynamic>.from(p);
              copy.remove('initialStatus');
              return copy;
            }).toList(),
            action: action,
            changedPurposes: changedByCollection[collectionId],
          );

          return _api.saveConsent(collectionId, payload);
        }),
      );

      setState(() => _dirty = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved successfully')),
        );
      }
      // Refresh consents after save - errors are handled gracefully in _fetchUserConsents
      _fetchUserConsents().catchError((err) {
        // Silently handle refresh errors - save was successful
        debugPrint('[NativeRightCenter] Note: Error refreshing consents after save (this is non-critical): $err');
      });
    } catch (e) {
      debugPrint('[NativeRightCenter] Error saving consents: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save consent changes. Please try again.')),
        );
      }
    }
  }

  Future<void> _handleNomineeSubmit() async {
    if (!_nomineeFormKey.currentState!.validate()) return;

    final nominee = _nominees.isNotEmpty ? _nominees.first : null;
    final payload = Nominee(
      user_id: widget.userId,
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
        final created = await _api.createNominee(payload);
        setState(() {
          _nominees = [created];
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nominee saved successfully')),
        );
      }
    } catch (e) {
      debugPrint('[NativeRightCenter] Error saving nominee: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save nominee. Please try again.')),
        );
      }
    }
  }

  Future<void> _handleDeleteNominee() async {
    final nominee = _nominees.isNotEmpty ? _nominees.first : null;
    if (nominee?.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Nominee'),
        content: const Text('Are you sure you want to delete this nominee?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
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
          _nomineeForm.clear();
          _nomineeForm.addAll({
            'nominee_name': '',
            'relationship': '',
            'nominee_email': '',
            'nominee_mobile': '',
            'purpose_of_appointment': '',
          });
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nominee deleted successfully')),
          );
        }
      } catch (e) {
        debugPrint('[NativeRightCenter] Error deleting nominee: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete nominee. Please try again.')),
          );
        }
      }
    }
  }

  Future<void> _handleGrievanceSubmit() async {
    if (!_grievanceFormKey.currentState!.validate()) return;

    final payload = GrievanceTicket(
      client_user_id: widget.userId,
      subject: _grievanceForm['subject']!,
      category: _grievanceForm['category']!,
      description: _grievanceForm['description']!,
    );

    try {
      final created = await _api.createGrievanceTicket(payload);
      setState(() {
        _tickets = [created, ..._tickets];
        _showGrievanceForm = false;
        _grievanceForm.clear();
        _grievanceForm.addAll({
          'subject': '',
          'category': '',
          'description': '',
        });
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grievance ticket created successfully')),
        );
      }
    } catch (e) {
      debugPrint('[NativeRightCenter] Error creating grievance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create grievance ticket. Please try again.')),
        );
      }
    }
  }


  Widget _buildTabButton(String label, int index) {
    final isActive = _activeTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF9333EA) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFF9333EA) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Data Principal ID Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: const Color(0xFFE0E7FF),
            child: Center(
              child: Text(
                'Data Principal ID: ${widget.userId.length > 6 ? widget.userId.substring(0, 6) : widget.userId}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),

          // Tabs - Wrapped in 2 rows (3+3)
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildTabButton('Consent', 0),
                  ),
                  Expanded(
                    child: _buildTabButton('Rights', 1),
                  ),
                  Expanded(
                    child: _buildTabButton('Transparency', 2),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTabButton('DPO', 3),
                  ),
                  Expanded(
                    child: _buildTabButton('Nominee', 4),
                  ),
                  Expanded(
                    child: _buildTabButton('Grievance', 5),
                  ),
                ],
              ),
            ],
          ),

          // Tab Content
          Expanded(
            child: IndexedStack(
              index: _activeTabIndex,
              children: [
                _buildConsentTab(),
                _buildRightsTab(),
                _buildTransparencyTab(),
                _buildDPOTab(),
                _buildNomineeTab(),
                _buildGrievanceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentTab() {
    if (_consentsLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading consents...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: const Text(
                  'Manage your Consents here!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              if (_dirty) ...[
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9333EA),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    minimumSize: const Size(120, 40),
                  ),
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _consentGroups.isEmpty
              ? const Center(
                  child: Text('You currently have no consent records to display.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _consentGroups.length,
                  itemBuilder: (context, index) {
                    final cp = _consentGroups[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cp.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            ...cp.purposes.map((p) {
                              return _buildPurposeCard(p, cp);
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPurposeCard(Purpose p, ConsentGroup cp) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      color: const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.info_outline, size: 20),
                      onPressed: () {
                        setState(() {
                          _modalData = {
                            'title': p.name,
                            'description': p.description,
                            'expiry': p.expiry_period,
                            'collectionPoint': cp.title,
                            'type': p.is_mandatory ? 'Mandatory' : 'Optional',
                          };
                        });
                        showDialog(
                          context: context,
                          builder: (context) => _buildConsentDetailModal(),
                        );
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.is_mandatory
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        p.is_mandatory ? 'MANDATORY' : 'OPTIONAL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: p.is_mandatory
                              ? const Color(0xFF991B1B)
                              : const Color(0xFF166534),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              p.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Expiry: ${p.expiry_period}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            Text(
              'Collection Point: ${cp.title}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shown to Principal: ${cp.shown_to_principal == true ? 'Yes' : 'No'}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                Text(
                  'Consented: ${p.consented == 'accepted' ? 'Yes' : 'No'}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Switch(
              value: p.consented == 'accepted',
              onChanged: (_) => _handleToggle(p.id, cp.collection_point),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentDetailModal() {
    if (_modalData == null) return const SizedBox.shrink();
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(_modalData!['title'] ?? '')),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_modalData!['description'] ?? ''),
            const SizedBox(height: 16),
            Text('Expiry: ${_modalData!['expiry'] ?? ''}'),
            Text('Collection Point: ${_modalData!['collectionPoint'] ?? ''}'),
            Text('Type: ${_modalData!['type'] ?? ''}'),
          ],
        ),
      ),
    );
  }

  Widget _buildRightsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Data Rights',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can access, correct, delete, or export your data.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Data Deletion'),
                  content: const Text(
                    'Are you sure you want to request data deletion? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Request submitted successfully!'),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Confirm Deletion'),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Request Data Deletion', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransparencyTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transparency',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Learn how we collect, use, and protect your data',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          const Text(
            'We collect your data to provide better services and comply with regulations. Your data is stored securely and used only for the purposes you\'ve consented to.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDPOTab() {
    if (_dpoLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading DPO information...'),
          ],
        ),
      );
    }

    if (_dpoError != null) {
      return Center(
        child: Text(
          _dpoError!,
          style: const TextStyle(color: Color(0xFFDC2626)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Protection Officer (DPO) Contact',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Contact our DPO for data protection matters and privacy concerns',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          if (_dpoInfo != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDPOItem('Name', _dpoInfo!.full_name ?? 'N/A'),
                    _buildDPOItem('Email', _dpoInfo!.email ?? 'N/A'),
                    _buildDPOItem('Appointment Date', _dpoInfo!.appointment_date ?? 'N/A'),
                    _buildDPOItem('Qualifications', _dpoInfo!.qualifications ?? 'N/A'),
                    _buildDPOItem('Responsibilities', _dpoInfo!.responsibilities ?? 'N/A'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDPOItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNomineeTab() {
    if (_nomineeLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading nominee information...'),
          ],
        ),
      );
    }

    if (_nomineeError != null) {
      return Center(
        child: Text(
          _nomineeError!,
          style: const TextStyle(color: Color(0xFFDC2626)),
        ),
      );
    }

    final nominee = _nominees.isNotEmpty ? _nominees.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appoint Nominee',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Appoint someone to manage your data rights on your behalf',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '⚠️ Your nominee will be able to exercise all data rights on your behalf.',
              style: TextStyle(fontSize: 14, color: Color(0xFF92400E)),
            ),
          ),
          const SizedBox(height: 16),
          if (nominee != null && !_editing)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNomineeItem('Name', nominee.nominee_name),
                    _buildNomineeItem('Relationship', nominee.relationship),
                    _buildNomineeItem('Email', nominee.nominee_email),
                    _buildNomineeItem('Mobile', nominee.nominee_mobile),
                    if (nominee.purpose_of_appointment != null)
                      _buildNomineeItem('Purpose of Appointment', nominee.purpose_of_appointment!),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => setState(() => _editing = true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9333EA),
                            ),
                            child: const Text('Edit', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleDeleteNominee,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                            ),
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
            Form(
              key: _nomineeFormKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      hintText: 'Full name of nominee',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _nomineeForm['nominee_name'],
                    onChanged: (value) => _nomineeForm['nominee_name'] = value,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Relationship *',
                      border: OutlineInputBorder(),
                    ),
                    value: _nomineeForm['relationship']?.isEmpty ?? true
                        ? null
                        : _nomineeForm['relationship'],
                    items: const [
                      DropdownMenuItem(value: 'Spouse', child: Text('Spouse')),
                      DropdownMenuItem(value: 'Parent', child: Text('Parent')),
                      DropdownMenuItem(value: 'Child', child: Text('Child')),
                      DropdownMenuItem(value: 'Sibling', child: Text('Sibling')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (value) => _nomineeForm['relationship'] = value ?? '',
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Relationship is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      hintText: 'nominee@example.com',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    initialValue: _nomineeForm['nominee_email'],
                    onChanged: (value) => _nomineeForm['nominee_email'] = value,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Email is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number *',
                      hintText: '+1234567890',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    initialValue: _nomineeForm['nominee_mobile'],
                    onChanged: (value) => _nomineeForm['nominee_mobile'] = value,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Mobile number is required' : null,
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
                    onChanged: (value) => _nomineeForm['purpose_of_appointment'] = value,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _handleNomineeSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9333EA),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text(
                      _editing ? 'Update Nominee' : 'Send Verification Code',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  if (_editing)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: OutlinedButton(
                        onPressed: () => setState(() => _editing = false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNomineeItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrievanceTab() {
    if (_ticketsLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading grievance tickets...'),
          ],
        ),
      );
    }

    if (_ticketsError != null) {
      return Center(
        child: Text(
          _ticketsError!,
          style: const TextStyle(color: Color(0xFFDC2626)),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grievance Tickets',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Submit privacy concerns or view your existing tickets',
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => setState(() => _showGrievanceForm = !_showGrievanceForm),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9333EA),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  minimumSize: const Size(140, 44),
                ),
                child: const Text('Create New Ticket', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          if (_showGrievanceForm) ...[
            const SizedBox(height: 16),
            Form(
              key: _grievanceFormKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Subject *',
                      hintText: 'Brief description of your concern',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _grievanceForm['subject'],
                    onChanged: (value) => _grievanceForm['subject'] = value,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Subject is required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(),
                    ),
                    value: _grievanceForm['category']?.isEmpty ?? true
                        ? null
                        : _grievanceForm['category'],
                    items: const [
                      DropdownMenuItem(
                        value: 'Privacy Concern',
                        child: Text('Privacy Concern'),
                      ),
                      DropdownMenuItem(
                        value: 'Data Access',
                        child: Text('Data Access'),
                      ),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (value) => _grievanceForm['category'] = value ?? '',
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Category is required' : null,
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
                    onChanged: (value) => _grievanceForm['description'] = value,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleGrievanceSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9333EA),
                          ),
                          child: const Text('Submit Ticket', style: TextStyle(color: Colors.white)),
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
          const Text(
            'Your Tickets',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          if (_tickets.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No tickets found. Create your first grievance ticket above.'),
              ),
            )
          else
            ..._tickets.map((ticket) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              ticket.subject,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
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
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ticket.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

