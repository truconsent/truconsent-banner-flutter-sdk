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

    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;
    
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
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(0, 4),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close, size: 20),
                  color: const Color(0xFF666666),
                  onPressed: _handleCloseClick,
                ),
              ),
            ),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _error!.contains('Banner not found')
                                  ? 'Banner not found. Please check the Banner ID and try again.'
                                  : _error!.contains('Authentication') || _error!.contains('Invalid')
                                      ? 'Authentication failed. Please check your API key and Organization ID.'
                                      : _error!.contains('forbidden')
                                          ? 'Access denied. Your API key does not have permission to access this banner.'
                                          : 'Error: $_error',
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Please check your API credentials and banner ID, then try again.',
                              style: TextStyle(
                                color: Color(0xFF991B1B),
                                fontSize: 12,
                              ),
                            ),
                          ],
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
              ),
          ],
        ),
      ),
    );
  }
}

