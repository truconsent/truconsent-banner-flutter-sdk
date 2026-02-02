/// RightCenter - Flutter implementation
///
/// For stability and parity with the web demo (iframe embed), we render the hosted
/// Rights Center inside a WebView.
///
/// This component provides a comprehensive rights management interface with tabs for:
/// - Consent: View and manage all consent records
/// - Rights: Exercise data rights (deletion, download)
/// - Transparency: View transparency information
/// - DPO: Data Protection Officer contact information
/// - Nominee: Appoint and manage nominees
/// - Grievance: Submit and view grievance tickets
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RightCenter extends StatefulWidget {
  final String userId;
  final String? clientId;
  final String? supabaseProjectUrl;

  const RightCenter({
    super.key,
    required this.userId,
    this.clientId,
    this.supabaseProjectUrl,
  });

  @override
  State<RightCenter> createState() => _RightCenterState();
}

class _RightCenterState extends State<RightCenter> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final baseUrl = (widget.supabaseProjectUrl ?? 
        'https://iwjwpfuaygfojwrrstly.supabase.co').replaceAll(RegExp(r'/$'), '');
    final clientId = widget.clientId ?? 'mars-money';
    final uri = Uri.parse(
      '$baseUrl/functions/v1/embed-rights-center?'
      'client_id=${Uri.encodeComponent(clientId)}&'
      'data_principal_id=${Uri.encodeComponent(widget.userId)}',
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

