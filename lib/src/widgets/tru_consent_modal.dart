/// TruConsentModal - Main Flutter widget for displaying consent banner
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/banner.dart';
import '../services/banner_service.dart';
import '../services/consent_manager.dart';
import 'banner_ui.dart';
import 'cookie_banner_ui.dart';

class TruConsentModal extends StatefulWidget {
  final String apiKey;
  final String organizationId;
  final String bannerId;
  final String userId;
  final String? apiBaseUrl;
  final String? logoUrl;
  final String companyName;
  final Function(ConsentAction)? onClose;

  const TruConsentModal({
    super.key,
    required this.apiKey,
    required this.organizationId,
    required this.bannerId,
    required this.userId,
    this.apiBaseUrl,
    this.logoUrl,
    this.companyName = 'Mars Company',
    this.onClose,
  });

  @override
  State<TruConsentModal> createState() => _TruConsentModalState();
}

class _TruConsentModalState extends State<TruConsentModal> {
  Banner? _banner;
  bool _isLoading = true;
  bool _actionLoading = false;
  String? _error;
  bool _visible = true;
  bool _actionTaken = false;
  bool _actionRunning = false;
  bool _closeButtonClicked = false;
  late String _requestId;
  List<Purpose> _purposes = [];

  @override
  void initState() {
    super.initState();
    _requestId = const Uuid().v4();
    _loadBanner();
  }

  Future<void> _loadBanner() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final banner = await fetchBanner(
        bannerId: widget.bannerId,
        apiKey: widget.apiKey,
        organizationId: widget.organizationId,
        apiBaseUrl: widget.apiBaseUrl,
      );
      setState(() {
        _banner = banner;
        _purposes = List.from(banner.purposes);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendLogEvent(ConsentAction action, [List<Purpose>? purposesToSend]) async {
    if (_banner == null || _actionRunning) return;

    if (action != ConsentAction.noAction) {
      _actionTaken = true;
    }

    _actionRunning = true;
    try {
      await submitConsent(
        collectionPointId: _banner!.collectionPoint,
        userId: widget.userId,
        purposes: purposesToSend ?? _purposes,
        action: action,
        apiKey: widget.apiKey,
        organizationId: widget.organizationId,
        requestId: _requestId,
        apiBaseUrl: widget.apiBaseUrl,
      );
    } catch (e) {
      debugPrint('Failed to log consent event: $e');
      rethrow;
    } finally {
      _actionRunning = false;
    }
  }

  void _close(ConsentAction type) {
    setState(() {
      _visible = false;
    });
    if (widget.onClose != null) {
      widget.onClose!(type);
    }
  }

  Future<void> _handleAction(ConsentAction action) async {
    if (_banner == null) return;
    setState(() {
      _actionLoading = true;
      _error = null;
    });

    try {
      await _sendLogEvent(action);
      _close(action);
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Please try again.';
      });
    } finally {
      setState(() {
        _actionLoading = false;
      });
    }
  }

  Future<void> _handleAcceptSelected() async {
    if (_banner == null) return;
    setState(() {
      _actionLoading = true;
      _error = null;
    });

    try {
      final updatedPurposes = acceptMandatoryPurposes(_purposes);
      await _sendLogEvent(ConsentAction.approved, updatedPurposes);
      _close(ConsentAction.approved);
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Please try again.';
      });
    } finally {
      setState(() {
        _actionLoading = false;
      });
    }
  }

  void _handleCloseClick() {
    _closeButtonClicked = true;

    if (!_actionTaken) {
      _sendLogEvent(ConsentAction.noAction);
      _actionTaken = true;
    }
    _close(ConsentAction.noAction);
  }

  void _updatePurpose(String purposeId, String newStatus) {
    setState(() {
      _purposes = updatePurposeStatus(_purposes, purposeId, newStatus);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final resolvedCompanyName = _banner?.organizationName ??
        _banner?.organization?.name ??
        widget.companyName;
    final resolvedLogoUrl = _banner?.organization?.logoUrl ?? widget.logoUrl;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _handleCloseClick,
              ),
            ),
            if (_isLoading)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading...'),
                  ],
                ),
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (_banner != null)
                    Expanded(
                      child: SingleChildScrollView(
                        child: _banner!.consentType == 'cookie_consent'
                            ? CookieBannerUI(
                                banner: _banner!,
                                companyName: resolvedCompanyName,
                                logoUrl: resolvedLogoUrl,
                                onRejectAll: () => _handleAction(ConsentAction.declined),
                                onConsentAll: () => _handleAction(ConsentAction.approved),
                              )
                            : BannerUI(
                                banner: Banner(
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
                                ),
                                companyName: resolvedCompanyName,
                                logoUrl: resolvedLogoUrl,
                                onChangePurpose: _updatePurpose,
                                onRejectAll: () => _handleAction(ConsentAction.declined),
                                onConsentAll: () => _handleAction(ConsentAction.approved),
                                onAcceptSelected: _handleAcceptSelected,
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

