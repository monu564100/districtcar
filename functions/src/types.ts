export type UserRole = 'customer' | 'driver' | 'super_admin' | 'admin' | 'support' | 'operations';

export type DriverVerificationStatus = 'pending' | 'approved' | 'rejected' | 'suspended';
export type DriverStatus = 'idle' | 'busy' | 'offline';

export type BookingStatus =
  | 'requested'
  | 'searching_driver'
  | 'driver_assigned'
  | 'driver_arriving'
  | 'driver_arrived'
  | 'trip_started'
  | 'trip_completed'
  | 'cancelled_by_customer'
  | 'cancelled_by_driver'
  | 'expired'
  | 'no_driver_found';

export type BookingRequestStatus = 'offered' | 'accepted' | 'rejected' | 'expired';

export type PaymentMethod = 'cash' | 'upi' | 'card' | 'wallet';
export type PaymentStatus = 'pending' | 'completed' | 'failed' | 'refunded';

export interface LocationData {
  latitude: number;
  longitude: number;
  address: string;
  geohash?: string;
}

export interface VehicleCategory {
  id: string;
  name: string;
  displayName: string;
  icon: string;
  image: string;
  baseFare: number;
  perKmRate: number;
  perMinuteRate: number;
  minimumFare: number;
  bookingFee: number;
  waitingCharge: number;
  cancellationFee: number;
  isActive: boolean;
  version?: number;
}

export interface FareBreakdown {
  baseFare: number;
  distanceKm: number;
  distanceFare: number;
  durationMinutes: number;
  timeFare: number;
  bookingFee: number;
  minimumFare: number;
  totalFare: number;
}

export interface CustomerProfile {
  uid: string;
  role: 'customer';
  phoneNumber: string;
  name: string;
  age: number;
  gender: string;
  profilePhotoUrl?: string;
  isActive: boolean;
  isBlocked: boolean;
  createdAt: any;
  updatedAt: any;
  lastLoginAt?: any;
}

export interface DriverProfile {
  uid: string;
  role: 'driver';
  name: string;
  phoneNumber: string;
  age: number;
  gender: string;
  profilePhotoUrl?: string;
  verificationStatus: DriverVerificationStatus;
  rejectionReason?: string;
  isActive: boolean;
  isBlocked: boolean;
  isOnline: boolean;
  driverStatus: DriverStatus;
  currentLocation?: {
    latitude: number;
    longitude: number;
    geohash: string;
  };
  lastLocationAt?: any;
  vehicleId?: string;
  vehicleCategoryId?: string;
  rating: number;
  totalTrips: number;
  createdAt: any;
  updatedAt: any;
}

export interface VehicleInfo {
  id: string;
  driverId: string;
  categoryId: string;
  make: string;
  model: string;
  registrationNumber: string;
  color: string;
  year: number;
  vehiclePhotoUrl?: string;
  livePhotoUrl?: string;
  verificationStatus: DriverVerificationStatus;
  isActive: boolean;
  createdAt: any;
  updatedAt: any;
}

export interface BookingRecord {
  id: string; // Document ID
  readableId: string; // DC-YYYYMMDD-XXXXXX
  customerId: string;
  customerName?: string;
  customerPhone?: string;
  driverId?: string;
  vehicleCategoryId: string;
  vehicleId?: string;
  pickup: LocationData;
  destination: LocationData;
  estimatedDistanceKm: number;
  estimatedDurationMinutes: number;
  estimatedFare: number;
  finalFare?: number;
  fareSnapshot: FareBreakdown;
  paymentMethod: PaymentMethod;
  paymentStatus: PaymentStatus;
  status: BookingStatus;
  rideOtp?: string;
  searchRadiusKm?: number;
  attemptedDriverIds?: string[];
  createdAt: any;
  assignedAt?: any;
  arrivedAt?: any;
  startedAt?: any;
  completedAt?: any;
  cancelledAt?: any;
  cancelledBy?: 'customer' | 'driver' | 'admin' | 'system';
  cancellationReason?: string;
}

export interface BookingRequestRecord {
  id: string;
  bookingId: string;
  driverId: string;
  pickupDistanceKm: number;
  status: BookingRequestStatus;
  offeredAt: any;
  expiresAt: any;
  respondedAt?: any;
  rejectionReason?: string;
}
