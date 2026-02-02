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
///
/// Note: This component is mobile-only. On web platforms, a message is shown
/// indicating that Rights Center is only available on mobile devices.
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class RightCenter extends StatefulWidget {
  final String userId;
  final String? clientId;
  final String? supabaseProjectUrl;
  final String? apiKey; // TruConsent API key for x-api-key header
  final String? organizationId; // Organization ID for x-org-id header
  final String? supabaseAnonKey; // Supabase anon key for apikey header

  const RightCenter({
    super.key,
    required this.userId,
    this.clientId,
    this.supabaseProjectUrl,
    this.apiKey,
    this.organizationId,
    this.supabaseAnonKey,
  });

  @override
  State<RightCenter> createState() => _RightCenterState();
}

class _RightCenterState extends State<RightCenter> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _htmlContent;
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    // Only initialize WebView on mobile platforms (not web)
    if (!kIsWeb) {
      _fetchContentThenInitialize();
    } else {
      // On web, set loading to false immediately since we won't load WebView
      _isLoading = false;
    }
  }

  Future<void> _fetchContentThenInitialize() async {
    setState(() {
      _isLoading = true;
      _fetchError = null;
    });

    try {
      final baseUrl = (widget.supabaseProjectUrl ?? 
          'https://iwjwpfuaygfojwrrstly.supabase.co').replaceAll(RegExp(r'/$'), '');
      final clientId = widget.clientId ?? 'mars-money';
      final uri = Uri.parse(
        '$baseUrl/functions/v1/embed-rights-center?'
        'client_id=${Uri.encodeComponent(clientId)}&'
        'data_principal_id=${Uri.encodeComponent(widget.userId)}',
      );

      debugPrint('[RightCenter] Fetching content from: ${uri.toString()}');

      // Prepare headers
      final headers = <String, String>{
        'Content-Type': 'text/html',
      };

      // Add Supabase anon key as apikey header (required by Supabase edge functions)
      if (widget.supabaseAnonKey != null && widget.supabaseAnonKey!.isNotEmpty) {
        headers['apikey'] = widget.supabaseAnonKey!;
        debugPrint('[RightCenter] Added apikey header (Supabase authentication)');
      } else {
        debugPrint('[RightCenter] WARNING: No Supabase anon key - authentication will fail');
      }

      // Add TruConsent headers if provided
      if (widget.apiKey != null && widget.apiKey!.isNotEmpty) {
        headers['x-api-key'] = widget.apiKey!;
      }
      if (widget.organizationId != null && widget.organizationId!.isNotEmpty) {
        headers['x-org-id'] = widget.organizationId!;
      }

      debugPrint('[RightCenter] Fetching with headers: ${headers.keys.join(", ")}');

      // Fetch content with proper headers
      final response = await http.get(uri, headers: headers);

      debugPrint('[RightCenter] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final html = response.body;
        debugPrint('[RightCenter] Content fetched successfully, length: ${html.length}');
        setState(() {
          _htmlContent = html;
        });
        _initializeWebView();
      } else {
        final errorMsg = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        debugPrint('[RightCenter] Fetch error: $errorMsg');
        debugPrint('[RightCenter] Response body: ${response.body}');
        setState(() {
          _fetchError = errorMsg;
          _isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('[RightCenter] Failed to fetch content: $error');
      setState(() {
        _fetchError = error.toString();
        _isLoading = false;
      });
    }
  }

  void _initializeWebView() {
    debugPrint('[RightCenter] Initializing WebView');
    debugPrint('[RightCenter] User ID: ${widget.userId}');
    debugPrint('[RightCenter] Has HTML content: ${_htmlContent != null}');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('[RightCenter] Page started loading: $url');
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            debugPrint('[RightCenter] Page finished loading - SUCCESS: $url');
            debugPrint('[RightCenter] Rights Center should now be visible');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('[RightCenter] WebView ERROR:');
            debugPrint('  Code: ${error.errorCode}');
            debugPrint('  Description: ${error.description}');
            debugPrint('  Error Type: ${error.errorType}');
            debugPrint('  URL: ${error.url}');
            debugPrint('  Is For Main Frame: ${error.isForMainFrame}');
            
            // Provide user-friendly error context
            String errorMessage = 'Failed to load Rights Center';
            if (error.errorCode == -2) {
              errorMessage = 'Network error. Please check your internet connection.';
            } else if (error.errorCode == -6) {
              errorMessage = 'Authentication failed. Please check API configuration.';
            }
            debugPrint('[RightCenter] User-friendly error: $errorMessage');
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('[RightCenter] Navigation request: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      );
    
    // Load HTML content if we have it, otherwise fall back to URL
    final baseUrl = (widget.supabaseProjectUrl ?? 
        'https://iwjwpfuaygfojwrrstly.supabase.co').replaceAll(RegExp(r'/$'), '');
    
    if (_htmlContent != null) {
      debugPrint('[RightCenter] Loading HTML content directly');
      _controller!.loadHtmlString(_htmlContent!, baseUrl: baseUrl);
    } else {
      // Fallback: load from URL (this shouldn't happen if fetch succeeded)
      final clientId = widget.clientId ?? 'mars-money';
      final uri = Uri.parse(
        '$baseUrl/functions/v1/embed-rights-center?'
        'client_id=${Uri.encodeComponent(clientId)}&'
        'data_principal_id=${Uri.encodeComponent(widget.userId)}',
      );
      
      final headers = <String, String>{};
      if (widget.supabaseAnonKey != null && widget.supabaseAnonKey!.isNotEmpty) {
        headers['apikey'] = widget.supabaseAnonKey!;
      }
      if (widget.apiKey != null && widget.apiKey!.isNotEmpty) {
        headers['x-api-key'] = widget.apiKey!;
      }
      if (widget.organizationId != null && widget.organizationId!.isNotEmpty) {
        headers['x-org-id'] = widget.organizationId!;
      }
      
      debugPrint('[RightCenter] Fallback: Loading from URL with headers');
      if (headers.isNotEmpty) {
        _controller!.loadRequest(uri, headers: headers);
      } else {
        _controller!.loadRequest(uri);
      }
    }
  }

  Widget _buildWebMessage() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.phone_android,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Rights Center',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Rights Center is only available on mobile devices.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please use the Android or iOS app to access this feature.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebView() {
    // Show error if fetch failed
    if (_fetchError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to Load Rights Center',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _fetchError!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please check your internet connection and try again.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_controller == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text(
                'Initializing Rights Center...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(controller: _controller!),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading Rights Center...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show message on web, WebView on mobile
    if (kIsWeb) {
      return _buildWebMessage();
    }
    return _buildWebView();
  }
}

