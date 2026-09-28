import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/services/connectivity_service.dart';
import '../core/theme/app_theme.dart';

class NoInternetOverlay extends StatefulWidget {
  final Widget child;

  const NoInternetOverlay({super.key, required this.child});

  @override
  State<NoInternetOverlay> createState() => _NoInternetOverlayState();
}

class _NoInternetOverlayState extends State<NoInternetOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  bool _isRetrying = false;
  bool _wasOffline = false;
  bool _showRestoredBanner = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    ConnectivityService.instance.isConnectedNotifier.addListener(_onConnectivityChanged);

    // Initial check
    if (!ConnectivityService.instance.isConnectedNotifier.value) {
      _wasOffline = true;
      _animController.forward();
    }
  }

  @override
  void dispose() {
    ConnectivityService.instance.isConnectedNotifier.removeListener(_onConnectivityChanged);
    _animController.dispose();
    super.dispose();
  }

  void _onConnectivityChanged() {
    final isConnected = ConnectivityService.instance.isConnectedNotifier.value;
    if (!isConnected) {
      _wasOffline = true;
      _animController.forward();
    } else {
      if (_wasOffline) {
        _animController.reverse();
        _showBackOnlineBanner();
        _wasOffline = false;
      }
    }
  }

  void _showBackOnlineBanner() {
    setState(() => _showRestoredBanner = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showRestoredBanner = false);
      }
    });
  }

  Future<void> _manualRetry() async {
    setState(() => _isRetrying = true);
    await ConnectivityService.instance.checkConnection();
    if (mounted) {
      setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final cardBg = isDark ? const Color(0xFF131D2D) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF23354E) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : AppColors.primaryNavy;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;
    final statusBg = isDark ? const Color(0xFF1B283D) : const Color(0xFFF8FAFC);

    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isConnectedNotifier,
      builder: (context, isConnected, _) {
        return Stack(
          children: [
            widget.child,

            // Restored Green Banner / Toast at bottom
            if (_showRestoredBanner && isConnected)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                left: 20,
                right: 20,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.wifi_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Internet connection restored',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Disconnected Modal Overlay
            if (!isConnected || _animController.value > 0)
              FadeTransition(
                opacity: _fadeAnim,
                child: Material(
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      // Backdrop Blur & Dim
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.45),
                          ),
                        ),
                      ),

                      // Centered Modal Card
                      Center(
                        child: ScaleTransition(
                          scale: _scaleAnim,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 28),
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Icon with pulsating badge
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2).withValues(alpha: isDark ? 0.15 : 1.0),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFFECACA).withValues(alpha: isDark ? 0.3 : 1.0),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.wifi_off_rounded,
                                      color: Color(0xFFDC2626),
                                      size: 34,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Title
                                Text(
                                  'No Internet Connection',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),

                                // Subtitle
                                Text(
                                  'Please check your Wi-Fi or mobile data settings. We will automatically reconnect as soon as your network is back.',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: textSecondary,
                                    height: 1.45,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),

                                // Reconnecting Indicator Row
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: cardBorder),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            _isRetrying
                                                ? const Color(0xFFDC2626)
                                                : (isDark ? AppColors.goldAccentLight : AppColors.primaryNavy),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        _isRetrying ? 'Checking connection...' : 'Waiting for connection...',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Retry Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isRetrying ? null : _manualRetry,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark ? AppColors.goldAccent : AppColors.primaryNavy,
                                      foregroundColor: isDark ? AppColors.primaryNavyDark : Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isRetrying
                                        ? SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: isDark ? AppColors.primaryNavyDark : Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Retry Connection',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
