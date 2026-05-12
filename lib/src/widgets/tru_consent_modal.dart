/// TruConsentModal - Main Flutter widget for displaying consent banner
import 'dart:math';
import 'package:flutter/material.dart' hide Banner;
import 'package:uuid/uuid.dart';
import '../models/banner.dart' as models;
import '../services/banner_service.dart'
    show
        fetchBanner,
        submitConsent,
        sendSuppressionUpdate,
        sendNoticeShown,
        defaultApiBaseUrl;
import '../services/consent_manager.dart';
import 'banner_ui.dart';
import 'cookie_banner_ui.dart';

/// Generates a session ID in the format: sess_{timestamp}_{random8chars}
String _generateSessionId() {
  final ts = DateTime.now().millisecondsSinceEpoch;
  final chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rng = Random();
  final rand = List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  return 'sess_${ts}_$rand';
}

/// Main widget for displaying the TruConsent consent banner modal.
class TruConsentModal extends StatefulWidget {
  /// API key for TruConsent authentication
  final String apiKey;

  /// Organization ID for TruConsent
  final String organizationId;

  /// Banner/Collection Point ID to display
  final String bannerId;

  /// User ID for consent tracking
  final String userId;

  /// Asset ID for multi-asset scenarios
  final String? assetId;

  /// Optional base URL for the API. Defaults to production URL if not provided.
  final String? apiBaseUrl;

  /// Optional company logo URL to display in the banner
  final String? logoUrl;

  /// Company name to display in the banner.
  final String companyName;

  /// Callback function called when the modal closes with the user's consent action
  final Function(models.ConsentAction)? onClose;

  /// Optional custom submit handler; if provided, suppression API is skipped.
  final Function(List<models.Purpose>, models.ConsentAction)? onSubmit;

  const TruConsentModal({
    super.key,
    required this.apiKey,
    required this.organizationId,
    required this.bannerId,
    required this.userId,
    this.assetId,
    this.apiBaseUrl,
    this.logoUrl,
    this.companyName = 'Mars Company',
    this.onClose,
    this.onSubmit,
  });

  @override
  State<TruConsentModal> createState() => _TruConsentModalState();
}

class _TruConsentModalState extends State<TruConsentModal> {
  models.Banner? _banner;
  bool _isLoading = true;
  String? _error;
  bool _visible = true;
  bool _actionTaken = false;
  bool _actionRunning = false;
  late String _requestId;
  late String _sessionId;
  List<models.Purpose> _purposes = [];

  // Performance timestamps (seconds)
  int? _bannerFetchedAt;
  int? _bannerDisplayedAt;

  // H-Case state
  bool _showHCase = false;
  String? _pendingHCaseAction;

  // Re-consent
  bool _reconsentMode = false;

  @override
  void initState() {
    super.initState();
    _requestId = const Uuid().v4();
    _sessionId = _generateSessionId();
    _loadBanner();
  }

  Future<void> _loadBanner() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final fetchStart = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    try {
      final banner = await fetchBanner(
        bannerId: widget.bannerId,
        apiKey: widget.apiKey,
        organizationId: widget.organizationId,
        userId: widget.userId,
        assetId: widget.assetId,
        apiBaseUrl: widget.apiBaseUrl ?? defaultApiBaseUrl,
      );

      _bannerFetchedAt = fetchStart;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Auto-hide if consentStatus == 'complete' or purposes empty (not in reconsentMode)
      if (!banner.reconsentMode) {
        if (banner.consentStatus == 'complete' ||
            banner.purposes.isEmpty) {
          setState(() {
            _visible = false;
            _isLoading = false;
          });
          return;
        }
      }

      final normalizedPurposes = normalizePurposes(banner.purposes);

      setState(() {
        _banner = banner;
        _purposes = normalizedPurposes;
        _reconsentMode = banner.reconsentMode;
        _isLoading = false;
        _bannerDisplayedAt = now;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String get _resolvedApiBase => widget.apiBaseUrl ?? defaultApiBaseUrl;

  Future<void> _sendLogEvent(
    models.ConsentAction action,
    List<models.Purpose> purposesToSend, {
    String? buttonUsed,
    bool hCaseAcknowledged = false,
  }) async {
    if (_banner == null || _actionRunning) return;
    if (action != models.ConsentAction.noAction) {
      _actionTaken = true;
    }

    _actionRunning = true;
    try {
      if (widget.onSubmit != null) {
        widget.onSubmit!(purposesToSend, action);
      } else {
        // hCaseAcknowledged is expressed via buttonUsed='h_case_proceed' in the payload
        await submitConsent(
          collectionPointId: _banner!.collectionPoint,
          userId: widget.userId,
          purposes: purposesToSend,
          action: action,
          apiKey: widget.apiKey,
          organizationId: widget.organizationId,
          requestId: _requestId,
          assetId: widget.assetId ?? _banner!.asset?.id,
          sessionId: _sessionId,
          buttonUsed: hCaseAcknowledged ? 'h_case_proceed' : buttonUsed,
          reconsentCampaignId: _banner!.reconsentCampaignId,
          expiryReconsentRequestId: _banner!.expiryReconsentRequestId,
          bannerFetchedAt: _bannerFetchedAt,
          bannerDisplayedAt: _bannerDisplayedAt,
          apiBaseUrl: _resolvedApiBase,
        );
        // Suppression update if not custom handler
        if (action != models.ConsentAction.noticeShown) {
          final declined = purposesToSend
              .where((p) => p.consented == 'declined' && !p.isLegitimate)
              .map((p) => p.id)
              .toList();
          if (declined.isNotEmpty) {
            sendSuppressionUpdate(
              userId: widget.userId,
              declinedPurposeIds: declined,
              apiKey: widget.apiKey,
              organizationId: widget.organizationId,
              apiBaseUrl: _resolvedApiBase,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to log consent event: $e');
      rethrow;
    } finally {
      _actionRunning = false;
    }
  }

  void _close(models.ConsentAction type) {
    setState(() {
      _visible = false;
    });
    widget.onClose?.call(type);
  }

  // -------- Action Handlers --------

  Future<void> _handleAcceptAll() async {
    if (_banner == null) return;
    _clearError();
    try {
      final updated = _purposes.map((p) => p.copyWith(consented: 'accepted')).toList();
      await _sendLogEvent(models.ConsentAction.approved, updated, buttonUsed: 'accept_all');
      _close(models.ConsentAction.approved);
    } catch (_) {
      _setError();
    }
  }

  Future<void> _handleRejectAll() async {
    if (_banner == null) return;
    _clearError();

    // Check H-Case before declining
    if (checkHCaseIntercept(_purposes.map((p) => p.copyWith(consented: 'declined')).toList())) {
      setState(() {
        _showHCase = true;
        _pendingHCaseAction = 'reject_all';
      });
      return;
    }

    try {
      final updated = _purposes.map((p) {
        if (p.isLegitimate) return p.copyWith(consented: 'shown');
        return p.copyWith(consented: 'declined');
      }).toList();
      await _sendLogEvent(models.ConsentAction.declined, updated, buttonUsed: 'reject_all');
      _close(models.ConsentAction.declined);
    } catch (_) {
      _setError();
    }
  }

  Future<void> _handleOnlyNecessary() async {
    if (_banner == null) return;
    _clearError();
    try {
      final updated = _purposes.map((p) {
        if (p.isLegitimate) return p.copyWith(consented: 'shown');
        if (p.isMandatory) return p.copyWith(consented: 'accepted');
        return p.copyWith(consented: 'declined');
      }).toList();
      final hasOptional = _purposes.any((p) => !p.isMandatory && !p.isLegitimate);
      final action = hasOptional
          ? models.ConsentAction.partialConsent
          : models.ConsentAction.approved;
      await _sendLogEvent(action, updated, buttonUsed: 'only_necessary');
      _close(action);
    } catch (_) {
      _setError();
    }
  }

  Future<void> _handleSavePreferences() async {
    if (_banner == null) return;
    _clearError();

    // Check H-Case
    if (checkHCaseIntercept(_purposes)) {
      setState(() {
        _showHCase = true;
        _pendingHCaseAction = 'save_preferences';
      });
      return;
    }

    try {
      final consentPurposes = _purposes.where((p) => !p.isLegitimate).toList();
      final acceptedCount = consentPurposes.where((p) => p.consented == 'accepted').length;
      models.ConsentAction action;
      if (acceptedCount == 0) {
        action = models.ConsentAction.declined;
      } else if (acceptedCount == consentPurposes.length) {
        action = models.ConsentAction.approved;
      } else {
        action = models.ConsentAction.partialConsent;
      }
      await _sendLogEvent(action, _purposes, buttonUsed: 'save_preferences');
      _close(action);
    } catch (_) {
      _setError();
    }
  }

  Future<void> _handleNoticeShown() async {
    if (_banner == null) return;
    _clearError();
    try {
      if (widget.onSubmit != null) {
        widget.onSubmit!(_purposes, models.ConsentAction.noticeShown);
      } else {
        await sendNoticeShown(
          collectionPointId: _banner!.collectionPoint,
          userId: widget.userId,
          purposes: _purposes,
          apiKey: widget.apiKey,
          organizationId: widget.organizationId,
          requestId: _requestId,
          assetId: widget.assetId ?? _banner!.asset?.id,
          sessionId: _sessionId,
          bannerFetchedAt: _bannerFetchedAt,
          bannerDisplayedAt: _bannerDisplayedAt,
          reconsentCampaignId: _banner!.reconsentCampaignId,
          apiBaseUrl: _resolvedApiBase,
        );
      }
      _close(models.ConsentAction.noticeShown);
    } catch (_) {
      _setError();
    }
  }

  void _handleCloseClick() {
    if (!_actionTaken) {
      final noActionPurposes = _purposes.map((p) {
        if (p.isLegitimate) return p.copyWith(consented: 'shown');
        return p.copyWith(consented: 'declined');
      }).toList();
      _sendLogEvent(models.ConsentAction.noAction, noActionPurposes, buttonUsed: 'close');
      _actionTaken = true;
    }
    _close(models.ConsentAction.noAction);
  }

  void _handleHCaseProceed() {
    setState(() => _showHCase = false);
    final action = _pendingHCaseAction;
    _pendingHCaseAction = null;

    final updated = _purposes.map((p) {
      if (p.isLegitimate) return p.copyWith(consented: 'shown');
      if (action == 'reject_all') return p.copyWith(consented: 'declined');
      return p; // save_preferences: use current toggles
    }).toList();

    _sendLogEvent(
      models.ConsentAction.partialConsent,
      updated,
      buttonUsed: 'h_case_proceed',
      hCaseAcknowledged: true,
    ).then((_) => _close(models.ConsentAction.partialConsent)).catchError((_) => _setError());
  }

  void _handleHCaseBack() {
    setState(() {
      _showHCase = false;
      _pendingHCaseAction = null;
    });
  }

  void _updatePurpose(String purposeId, String newStatus) {
    setState(() {
      _purposes = updatePurposeStatus(_purposes, purposeId, newStatus);
    });
  }

  void _clearError() => setState(() => _error = null);
  void _setError() => setState(() => _error = 'Something went wrong. Please try again.');

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final resolvedCompanyName = _banner?.organizationName ??
        _banner?.organization?.name ??
        widget.companyName;
    final resolvedLogoUrl = _banner?.organization?.logoUrl ?? widget.logoUrl;

    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;
    final settings = _banner?.bannerSettings;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 20 : 28,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? screenSize.width * 0.96 : 720,
          maxHeight: isMobile ? screenSize.height - 80 : screenSize.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (_isLoading)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading banner...'),
                  ],
                ),
              )
            else
              Padding(
                padding: EdgeInsets.all(isMobile ? 20 : 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          border: Border.all(color: const Color(0xFFDC2626)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFDC2626), fontSize: 14),
                        ),
                      ),
                    if (_error == null && _banner == null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          border: Border.all(color: const Color(0xFFDC2626)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'No banner data available',
                          style: TextStyle(color: Color(0xFFDC2626)),
                        ),
                      ),
                    if (_banner != null)
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: _banner!.consentType == 'cookie_consent'
                              ? CookieBannerUI(
                                  banner: _banner!,
                                  companyName: resolvedCompanyName,
                                  logoUrl: resolvedLogoUrl,
                                  onRejectAll: _handleRejectAll,
                                  onConsentAll: _handleAcceptAll,
                                )
                              : BannerUI(
                                  banner: models.Banner(
                                    bannerId: _banner!.bannerId,
                                    collectionPoint: _banner!.collectionPoint,
                                    version: _banner!.version,
                                    title: _banner!.title,
                                    expiryType: _banner!.expiryType,
                                    asset: _banner!.asset,
                                    purposes: _purposes,
                                    dataElements: _banner!.dataElements,
                                    legalEntities: _banner!.legalEntities,
                                    tools: _banner!.tools,
                                    processingActivities: _banner!.processingActivities,
                                    consentType: _banner!.consentType,
                                    cookieConfig: _banner!.cookieConfig,
                                    bannerSettings: _banner!.bannerSettings,
                                    organization: _banner!.organization,
                                    organizationName: _banner!.organizationName,
                                    reconsentMode: _reconsentMode,
                                    reconsentCampaignId: _banner!.reconsentCampaignId,
                                    reconsentUiMode: _banner!.reconsentUiMode,
                                    versionDiff: _banner!.versionDiff,
                                    reconsentSource: _banner!.reconsentSource,
                                    expiryReconsentRequestId: _banner!.expiryReconsentRequestId,
                                    consentStatus: _banner!.consentStatus,
                                  ),
                                  companyName: resolvedCompanyName,
                                  logoUrl: resolvedLogoUrl,
                                  onChangePurpose: _updatePurpose,
                                  onRejectAll: _handleRejectAll,
                                  onConsentAll: _handleAcceptAll,
                                  onAcceptSelected: _handleSavePreferences,
                                  onNoticeShown: _handleNoticeShown,
                                  showHCaseWarning: _showHCase,
                                  hCaseStrategy: settings?.hCaseLoggingStrategy ?? 'soft_first',
                                  hCaseMessage: settings?.hCaseWarningMessage,
                                  hCaseProceedText: settings?.hCaseProceedButtonText,
                                  hCaseBackText: settings?.hCaseBackButtonText,
                                  onHCaseProceed: _handleHCaseProceed,
                                  onHCaseBack: _handleHCaseBack,
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            // Close button
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(18),
                color: Colors.transparent,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, size: 20),
                    color: const Color(0xFF666666),
                    onPressed: _handleCloseClick,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
