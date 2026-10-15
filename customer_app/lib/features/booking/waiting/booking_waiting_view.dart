import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:district_car_shared/models/models.dart';
import '../../../../services/haptic_service.dart';
import '../../../../theme/theme.dart';
import 'booking_search_state.dart';
import 'cancel_sheet.dart';
import 'driver_found_card.dart';
import 'help_support_sheet.dart';
import 'no_driver_state.dart';
import 'searching_hero.dart';
import 'status_block.dart';
import 'support_strip.dart';
import 'trip_summary_card.dart';

/// Top-Tier "Finding Drivers" Booking Waiting Screen
/// Redesigned with live animated radar map scene, 1-second dynamic feedback,
/// expandable search radius, segmented progress, scheduled-ride auto-minimization,
/// and 7-8 minute immediate ride timeout handling.
class BookingWaitingView extends StatefulWidget {
  final BookingModel booking;
  final Map<String, dynamic> rawData;
  final Future<void> Function(String reason)? onCancelConfirmed;
  final VoidCallback? onRetrySearch;

  const BookingWaitingView({
    super.key,
    required this.booking,
    required this.rawData,
    this.onCancelConfirmed,
    this.onRetrySearch,
  });

  @override
  State<BookingWaitingView> createState() => _BookingWaitingViewState();
}

class _BookingWaitingViewState extends State<BookingWaitingView>
    with SingleTickerProviderStateMixin {
  late final BookingSearchController _searchController;
  bool _hasAutoMinimized = false;
  AnimationController? _scheduledProgressController;
  Timer? _autoMinimizeTimer;

  bool get _isScheduled {
    final type = widget.booking.bookingType;
    final slot = widget.booking.scheduledTimeSlot;
    final date = widget.booking.scheduledDate;
    return type == 'scheduled' ||
        (slot != null && !slot.contains('Now')) ||
        (date != null && date.isNotEmpty && date != 'Today');
  }

  @override
  void initState() {
    super.initState();
    // Immediate rides timeout after 450s (7.5 minutes, 7-8 min range)
    _searchController = BookingSearchController(
      initialStartedAt: widget.booking.createdAt,
      maxTimeoutSeconds: 450,
      onTimeout: () {
        try {
          FirebaseFirestore.instance.collection('bookings').doc(widget.booking.id).update({
            'status': 'no_driver_found',
            'closedReason': 'No driver immediate for immediate ride',
            'closedAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      },
      onAnalyticsEvent: (name, params) {
        debugPrint('[WAITING_SCREEN_ANALYTICS] $name => $params');
      },
    );

    // Initial backend check
    _searchController.updateFromBackend(
      status: widget.booking.status,
      driverId: widget.booking.driverId,
      rawData: widget.rawData,
    );

    // If it's a scheduled ride and still searching/pending, show scheduled animation then minimize
    if (_isScheduled && widget.booking.status == 'searching_driver') {
      _scheduledProgressController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2400),
      )..forward();

      _autoMinimizeTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted && !_hasAutoMinimized) {
          _hasAutoMinimized = true;
          context.go('/');
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant BookingWaitingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _searchController.updateFromBackend(
      status: widget.booking.status,
      driverId: widget.booking.driverId,
      rawData: widget.rawData,
    );
  }

  @override
  void dispose() {
    _autoMinimizeTimer?.cancel();
    _scheduledProgressController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Top back button minimizes to home screen while searching continues in background
  void _handleTopBack() {
    HapticService.selectionClick();
    context.go('/');
  }

  /// Explicit Cancel button at the bottom opens CancelSheet
  void _handleCancelRide() {
    CancelSheet.show(
      context: context,
      secondsWaited: _searchController.state.elapsedSeconds,
      onConfirmCancel: (reason) {
        _searchController.cancelSearch(reason);
        if (widget.onCancelConfirmed != null) {
          widget.onCancelConfirmed!(reason);
        }
      },
    );
  }

  void _copyBookingId() {
    HapticService.selectionClick();
    Clipboard.setData(ClipboardData(text: widget.booking.readableId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking ID ${widget.booking.readableId} copied to clipboard!'),
        backgroundColor: AppTokens.primaryDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _searchController,
      builder: (context, _) {
        final state = _searchController.state;
        final isDriverFound = state is DriverFoundState;
        final isNoDriver = state is NoDriverFoundState;

        // If user is scheduled ride and driver is NOT yet found, show scheduled animation screen
        if (_isScheduled && !isDriverFound && !isNoDriver) {
          return _buildScheduledAnimationScreen();
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _handleTopBack();
          },
          child: Scaffold(
            backgroundColor: AppTokens.background,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: const Color(0xFF101A14), // Seamless top hero bar
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: _handleTopBack,
                tooltip: 'Back to Home (Searching in background)',
              ),
              title: InkWell(
                onTap: _copyBookingId,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2A22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.booking.readableId,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.copy_rounded, size: 13, color: AppTokens.marigold),
                    ],
                  ),
                ),
              ),
              centerTitle: false,
              actions: [
                // App Bar Help Action Button
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: TextButton.icon(
                    onPressed: () => HelpSupportSheet.show(context, widget.booking),
                    icon: const Icon(Icons.help_outline_rounded, size: 17, color: AppTokens.marigold),
                    label: const Text(
                      'Help',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2A22),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              top: false,
              child: Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      // 1. HERO RADAR / MAP SCENE (~48% height)
                      SliverToBoxAdapter(
                        child: SearchingHero(
                          radiusKm: state.radiusKm,
                          matchedDriversCount: state.matchedDriversCount,
                        ),
                      ),

                      // 2. SECONDARY STATE SWITCHING
                      if (isNoDriver) ...[
                        SliverToBoxAdapter(
                          child: NoDriverState(
                            booking: widget.booking,
                            onRetry: () {
                              _searchController.retry();
                              widget.onRetrySearch?.call();
                            },
                          ),
                        ),
                      ] else ...[
                        // 3. STATUS BLOCK (Serif Headline, 4s Messages, Progress, Timer)
                        SliverToBoxAdapter(
                          child: StatusBlock(
                            elapsedSeconds: state.elapsedSeconds,
                            activeProgressStep: state.activeProgressStep,
                            customHeadline: state.statusHeadline,
                            customSubMessage: state.statusSubMessage,
                          ),
                        ),

                        // 4. COMPACT & COLLAPSIBLE TRIP SUMMARY CARD
                        SliverToBoxAdapter(
                          child: TripSummaryCard(booking: widget.booking),
                        ),

                        // 5. SAFETY & SUPPORT STRIP (WhatsApp + Call Support + Share)
                        SliverToBoxAdapter(
                          child: SupportStrip(booking: widget.booking),
                        ),

                        // 6. QUIET TEXT BUTTON "CANCEL RIDE"
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 24),
                            child: Center(
                              child: TextButton(
                                onPressed: _handleCancelRide,
                                child: const Text(
                                  'Cancel ride / राइड रद्द करें',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTokens.secondaryText,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // 7. DRIVER FOUND BOTTOM CARD OVERLAY
                  if (isDriverFound)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: DriverFoundCard(
                        state: state as DriverFoundState,
                        booking: widget.booking,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Scheduled Ride Confirmation Animation Screen
  Widget _buildScheduledAnimationScreen() {
    final dateStr = widget.booking.scheduledDate ?? 'Today';
    final timeStr = widget.booking.scheduledTimeSlot ?? 'Scheduled Slot';

    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTokens.ink,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          widget.booking.readableId,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Celebratory Calendar Icon Badge
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppTokens.primaryTint,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTokens.primary, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTokens.primary.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.event_available_rounded, size: 48, color: AppTokens.primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Ride Scheduled Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTokens.ink,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'आपकी राइड सफलतापूर्वक शेड्यूल कर दी गई है',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.secondaryText,
                ),
              ),
              const SizedBox(height: 24),

              // Schedule Details Box
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTokens.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time_filled_rounded, size: 18, color: AppTokens.marigoldDark),
                        const SizedBox(width: 8),
                        Text(
                          '$dateStr · $timeStr',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTokens.ink,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppTokens.border),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 18, color: AppTokens.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.booking.pickup.address,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.flag_rounded, size: 18, color: AppTokens.terracotta),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.booking.destination.address,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Reassurance message
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTokens.surface2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.notifications_active_outlined, size: 18, color: AppTokens.primaryDark),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pickup se pehle aapko driver details mil jayegi aur screen par notify kiya jayega.',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTokens.ink),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Automatic minimization progress bar indicator
              if (_scheduledProgressController != null) ...[
                AnimatedBuilder(
                  animation: _scheduledProgressController!,
                  builder: (context, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _scheduledProgressController!.value,
                        backgroundColor: AppTokens.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTokens.primary),
                        minHeight: 4,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Minimizing to home screen in 2 seconds...',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.secondaryText,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Manual Return to Home button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    _hasAutoMinimized = true;
                    context.go('/');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Return to Home / होम स्क्रीन पर जाएं',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
