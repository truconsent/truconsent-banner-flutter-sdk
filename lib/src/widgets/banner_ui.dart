import 'package:flutter/material.dart' hide Banner;
import '../models/banner.dart' as models;
import '../services/consent_manager.dart';
import 'modern_banner_header.dart';
import 'modern_purpose_card.dart';
import 'modern_banner_footer.dart';
import 'modern_banner_actions.dart';
import 'h_case_warning_widget.dart';

/// Standard consent banner UI widget.
///
/// Supports NORMAL, NOTICE_ONLY, and TABBED banner cases.
class BannerUI extends StatefulWidget {
  final models.Banner banner;
  final String companyName;
  final String? logoUrl;
  final Function(String, String) onChangePurpose;
  final VoidCallback onRejectAll;
  final VoidCallback onConsentAll;
  final VoidCallback onAcceptSelected;
  final VoidCallback? onNoticeShown;
  final bool showHCaseWarning;
  final String? hCaseStrategy;
  final String? hCaseMessage;
  final String? hCaseProceedText;
  final String? hCaseBackText;
  final VoidCallback? onHCaseProceed;
  final VoidCallback? onHCaseBack;
  final String? primaryColor;
  final String? secondaryColor;

  const BannerUI({
    super.key,
    required this.banner,
    required this.companyName,
    this.logoUrl,
    required this.onChangePurpose,
    required this.onRejectAll,
    required this.onConsentAll,
    required this.onAcceptSelected,
    this.onNoticeShown,
    this.showHCaseWarning = false,
    this.hCaseStrategy,
    this.hCaseMessage,
    this.hCaseProceedText,
    this.hCaseBackText,
    this.onHCaseProceed,
    this.onHCaseBack,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  State<BannerUI> createState() => _BannerUIState();
}

class _BannerUIState extends State<BannerUI> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late models.UIState _uiState;

  @override
  void initState() {
    super.initState();
    _uiState = deriveUIState(widget.banner.purposes);
    final tabCount = _tabCount();
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void didUpdateWidget(BannerUI old) {
    super.didUpdateWidget(old);
    _uiState = deriveUIState(widget.banner.purposes);
    final tabCount = _tabCount();
    if (_tabController.length != tabCount) {
      _tabController.dispose();
      _tabController = TabController(length: tabCount, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _tabCount() {
    if (_uiState.bannerCase == models.BannerCase.tabbed) {
      return widget.banner.reconsentMode ? 3 : 2;
    }
    return 1;
  }

  Color _parseColor(String? colorString) {
    if (colorString == null) return const Color(0xFF7030bc);
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF7030bc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.banner.bannerSettings;
    final finalPrimaryColor = settings?.primaryColor ?? widget.primaryColor ?? '#7030bc';
    final parsedPrimaryColor = _parseColor(finalPrimaryColor);
    final footerText = settings?.footerText ??
        'Review our [Privacy Policy] and [Transparency Centre], [DPO Details]. Use the [Rights Centre] anytime to withdraw consent, delete data, name a nominee, or raise a grievance.';
    final bannerTitle = settings?.bannerTitle;
    final disclaimerText = settings?.disclaimerText;
    final actionButtonText = settings?.actionButtonText ?? 'Accept All';

    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;

    Widget content = _buildBannerContent(
      isMobile: isMobile,
      settings: settings,
      bannerTitle: bannerTitle,
      disclaimerText: disclaimerText,
      footerText: footerText,
      actionButtonText: actionButtonText,
      parsedPrimaryColor: parsedPrimaryColor,
      finalPrimaryColor: finalPrimaryColor,
    );

    if (widget.showHCaseWarning) {
      return Stack(
        children: [
          content,
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: HCaseWarningWidget(
                  strategy: widget.hCaseStrategy ?? 'soft_first',
                  message: widget.hCaseMessage ??
                      'Important: You have not provided consent for one or more required items. Please acknowledge this to continue.',
                  proceedText: widget.hCaseProceedText,
                  backText: widget.hCaseBackText,
                  onProceed: widget.onHCaseProceed ?? () {},
                  onBack: widget.onHCaseBack,
                  primaryColor: parsedPrimaryColor,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return content;
  }

  Widget _buildBannerContent({
    required bool isMobile,
    required models.BannerSettings? settings,
    required String? bannerTitle,
    required String? disclaimerText,
    required String footerText,
    required String actionButtonText,
    required Color parsedPrimaryColor,
    required String finalPrimaryColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.purple.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: ModernBannerHeader(
              logoUrl: settings?.logoUrl ?? widget.logoUrl,
              orgName: widget.companyName,
              bannerTitle: bannerTitle,
              disclaimerText: disclaimerText,
            ),
          ),

          // Purposes Section
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 24,
              vertical: isMobile ? 16 : 20,
            ),
            child: _buildPurposesSection(isMobile, parsedPrimaryColor),
          ),

          // Footer
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 24,
                    vertical: isMobile ? 12 : 16,
                  ),
                  child: ModernBannerFooter(
                    footerText: footerText,
                    orgName: widget.companyName,
                  ),
                ),
                _buildActions(
                  isMobile: isMobile,
                  actionButtonText: actionButtonText,
                  finalPrimaryColor: finalPrimaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurposesSection(bool isMobile, Color primaryColor) {
    switch (_uiState.bannerCase) {
      case models.BannerCase.noticeOnly:
        return _buildNoticeOnlySection(isMobile);
      case models.BannerCase.tabbed:
        return _buildTabbedSection(isMobile, primaryColor);
      case models.BannerCase.normal:
        return _buildNormalSection(isMobile);
    }
  }

  Widget _buildNoticeOnlySection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informational',
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        ..._uiState.noticePurposes.map((p) => Padding(
              padding: EdgeInsets.only(bottom: isMobile ? 10 : 12),
              child: ModernPurposeCard(
                purpose: p,
                banner: widget.banner,
                onToggle: widget.onChangePurpose,
                readOnly: true,
              ),
            )),
      ],
    );
  }

  Widget _buildTabbedSection(bool isMobile, Color primaryColor) {
    final tabs = <Tab>[
      const Tab(text: 'Informational'),
      const Tab(text: 'Consent'),
      if (widget.banner.reconsentMode) const Tab(text: 'Re-consent'),
    ];

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: primaryColor,
          tabs: tabs,
        ),
        SizedBox(
          height: 300,
          child: TabBarView(
            controller: _tabController,
            children: [
              // Informational tab
              SingleChildScrollView(
                padding: EdgeInsets.only(top: isMobile ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _uiState.noticePurposes
                      .map((p) => Padding(
                            padding: EdgeInsets.only(bottom: isMobile ? 10 : 12),
                            child: ModernPurposeCard(
                              purpose: p,
                              banner: widget.banner,
                              onToggle: widget.onChangePurpose,
                              readOnly: true,
                            ),
                          ))
                      .toList(),
                ),
              ),
              // Consent tab
              SingleChildScrollView(
                padding: EdgeInsets.only(top: isMobile ? 12 : 16),
                child: _buildConsentPurposes(isMobile),
              ),
              if (widget.banner.reconsentMode)
                SingleChildScrollView(
                  padding: EdgeInsets.only(top: isMobile ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Updated consent required',
                        style: TextStyle(fontSize: isMobile ? 13 : 14, color: Colors.grey[700]),
                      ),
                      ..._uiState.consentPurposes
                          .map((p) => Padding(
                                padding: EdgeInsets.only(bottom: isMobile ? 10 : 12),
                                child: ModernPurposeCard(
                                  purpose: p,
                                  banner: widget.banner,
                                  onToggle: widget.onChangePurpose,
                                ),
                              ))
                          .toList(),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNormalSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.banner.purposes.isNotEmpty)
          Text(
            'Consent Preferences',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        if (widget.banner.purposes.isNotEmpty) SizedBox(height: isMobile ? 12 : 16),
        _buildConsentPurposes(isMobile),
      ],
    );
  }

  Widget _buildConsentPurposes(bool isMobile) {
    final mandatory = _uiState.mandatoryConsentPurposes;
    final optional = _uiState.optionalConsentPurposes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mandatory.isNotEmpty) ...[
          _buildGroupHeader('Necessary', isMobile),
          SizedBox(height: isMobile ? 8 : 10),
          ...mandatory.map((p) => Padding(
                padding: EdgeInsets.only(bottom: isMobile ? 10 : 12),
                child: ModernPurposeCard(
                  purpose: p,
                  banner: widget.banner,
                  onToggle: widget.onChangePurpose,
                ),
              )),
        ],
        if (optional.isNotEmpty) ...[
          SizedBox(height: isMobile ? 8 : 12),
          _buildGroupHeader('Optional', isMobile),
          SizedBox(height: isMobile ? 8 : 10),
          ...optional.map((p) => Padding(
                padding: EdgeInsets.only(bottom: isMobile ? 10 : 12),
                child: ModernPurposeCard(
                  purpose: p,
                  banner: widget.banner,
                  onToggle: widget.onChangePurpose,
                ),
              )),
        ],
        // Fallback: show all purposes if neither mandatory nor optional (e.g., unclassified)
        if (mandatory.isEmpty && optional.isEmpty)
          ...widget.banner.purposes.map((p) => Padding(
                padding: EdgeInsets.only(bottom: isMobile ? 10 : 12),
                child: ModernPurposeCard(
                  purpose: p,
                  banner: widget.banner,
                  onToggle: widget.onChangePurpose,
                ),
              )),
      ],
    );
  }

  Widget _buildGroupHeader(String label, bool isMobile) {
    return Text(
      label,
      style: TextStyle(
        fontSize: isMobile ? 12 : 13,
        fontWeight: FontWeight.w700,
        color: Colors.grey[500],
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildActions({
    required bool isMobile,
    required String actionButtonText,
    required String finalPrimaryColor,
  }) {
    if (_uiState.bannerCase == models.BannerCase.noticeOnly) {
      // Notice-only: show "I Understand" button
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 24,
          vertical: isMobile ? 12 : 16,
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.onNoticeShown,
            style: ElevatedButton.styleFrom(
              backgroundColor: _parseColor(finalPrimaryColor),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isMobile ? 13 : 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'I Understand',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    return ModernBannerActions(
      onRejectAll: widget.onRejectAll,
      onConsentAll: widget.onConsentAll,
      onAcceptSelected: widget.onAcceptSelected,
      purposes: widget.banner.purposes,
      actionButtonText: actionButtonText,
      primaryColor: finalPrimaryColor,
    );
  }

  Color _parseColor(String? colorString) {
    if (colorString == null) return const Color(0xFF7030bc);
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF7030bc);
    }
  }
}
