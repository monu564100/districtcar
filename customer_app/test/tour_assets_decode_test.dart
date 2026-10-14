import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:district_car_customer/widgets/tours/tour_assets.dart';

void main() {
  test('Verify all tour asset bytes can be decoded as valid images', () async {
    final codec1 = await ui.instantiateImageCodec(kPlaceholderLandscapeBytes);
    final frame1 = await codec1.getNextFrame();
    expect(frame1.image.width, greaterThan(0));
    print('kPlaceholderLandscape: ${frame1.image.width}x${frame1.image.height}');

    final codec2 = await ui.instantiateImageCodec(kOutOfAreaIllustrationBytes);
    final frame2 = await codec2.getNextFrame();
    expect(frame2.image.width, greaterThan(0));
    print('kOutOfArea: ${frame2.image.width}x${frame2.image.height}');

    final codec3 = await ui.instantiateImageCodec(kBookingConfirmedBytes);
    final frame3 = await codec3.getNextFrame();
    expect(frame3.image.width, greaterThan(0));
    print('kBookingConfirmed: ${frame3.image.width}x${frame3.image.height}');

    final codec4 = await ui.instantiateImageCodec(kMonsoonBannerBytes);
    final frame4 = await codec4.getNextFrame();
    expect(frame4.image.width, greaterThan(0));
    print('kMonsoonBanner: ${frame4.image.width}x${frame4.image.height}');
  });
}
