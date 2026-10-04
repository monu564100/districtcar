import { expect } from 'chai';
import { calculateDistanceKm, encodeGeohash, generateReadableBookingId, generateRideOtp } from '../src/utils/geo';
import { FareService } from '../src/services/fareService';
import { VehicleCategory } from '../src/types';

describe('District Car - Geospatial & Booking Utilities', () => {
  it('should accurately calculate distance using Haversine formula', () => {
    // Distance between New Delhi (28.6139, 77.2090) and Noida (28.5355, 77.3910) is ~19 km
    const distance = calculateDistanceKm(28.6139, 77.2090, 28.5355, 77.3910);
    expect(distance).to.be.greaterThan(17);
    expect(distance).to.be.lessThan(21);
  });

  it('should encode coordinates into valid Geohashes', () => {
    const hash = encodeGeohash(28.6139, 77.2090, 7);
    expect(hash).to.be.a('string');
    expect(hash.length).to.equal(7);
  });

  it('should format human-readable booking IDs with correct prefix', () => {
    const bookingId = generateReadableBookingId();
    expect(bookingId).to.match(/^DC-\d{8}-\d{6}$/);
  });

  it('should generate a 4-digit ride OTP', () => {
    const otp = generateRideOtp();
    expect(otp).to.match(/^\d{4}$/);
  });
});

describe('District Car - Fare Calculation Engine', () => {
  const sampleCarCategory: VehicleCategory = {
    id: 'car',
    name: 'Car',
    displayName: 'Car',
    icon: 'directions_car',
    image: '',
    baseFare: 50,
    perKmRate: 15,
    perMinuteRate: 2,
    minimumFare: 80,
    bookingFee: 10,
    waitingCharge: 2,
    cancellationFee: 30,
    isActive: true,
  };

  it('should calculate accurate fare breakdown including base fare and per km rate', () => {
    const distanceKm = 10;
    const durationMinutes = 20;

    const breakdown = FareService.calculateFare(sampleCarCategory, distanceKm, durationMinutes);

    // base: 50 + (10 * 15) = 150 + (20 * 2) = 40 + bookingFee 10 = 250
    expect(breakdown.baseFare).to.equal(50);
    expect(breakdown.distanceFare).to.equal(150);
    expect(breakdown.timeFare).to.equal(40);
    expect(breakdown.bookingFee).to.equal(10);
    expect(breakdown.totalFare).to.equal(250);
  });

  it('should respect minimum fare when distance is very short', () => {
    const breakdown = FareService.calculateFare(sampleCarCategory, 0.5, 2);
    // Calculated: 50 + 7.5 + 4 + 10 = 71.5. Minimum fare is 80.
    expect(breakdown.totalFare).to.equal(80);
  });
});
