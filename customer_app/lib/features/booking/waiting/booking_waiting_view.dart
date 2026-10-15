import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// expandable search radius, segmented progress, and zero blue tokens.
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

class _BookingWaitingViewState extends State<BookingWaitingView> {
  late final BookingSearchController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = BookingSearchController(
      initialStartedAt: widget.booking.createdAt,
      maxTimeoutSeconds: 150,
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
    _searchController.dispose();
    super.dispose();
  }

  void _handleBackOrCancel() {
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

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _handleBackOrCancel();
          },
          child: Scaffold(
            backgroundColor: AppTokens.background,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: const Color(0xFF101A14), // Seamless top hero bar
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: _handleBackOrCancel,
                tooltip: 'Back',
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
                                onPressed: _handleBackOrCancel,
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
}
