import * as admin from 'firebase-admin';
import { VehicleCategory, FareBreakdown } from '../types';

export class FareService {
  /**
   * Fetches category from Firestore vehicleCategories collection
   */
  static async getCategory(categoryId: string): Promise<VehicleCategory | null> {
    const doc = await admin.firestore().collection('vehicleCategories').doc(categoryId).get();
    if (!doc.exists) {
      return null;
    }
    return { id: doc.id, ...(doc.data() as any) } as VehicleCategory;
  }

  /**
   * Server-side authoritative calculation of ride fare breakdown
   */
  static calculateFare(
    category: VehicleCategory,
    distanceKm: number,
    durationMinutes: number
  ): FareBreakdown {
    const baseFare = category.baseFare || 0;
    const perKmRate = category.perKmRate || 0;
    const perMinuteRate = category.perMinuteRate || 0;
    const minimumFare = category.minimumFare || 0;
    const bookingFee = category.bookingFee || 0;

    const distanceFare = Math.round(distanceKm * perKmRate * 100) / 100;
    const timeFare = Math.round(durationMinutes * perMinuteRate * 100) / 100;

    const rawTotal = baseFare + distanceFare + timeFare + bookingFee;
    const totalFare = Math.max(rawTotal, minimumFare);

    return {
      baseFare,
      distanceKm: Math.round(distanceKm * 100) / 100,
      distanceFare,
      durationMinutes: Math.round(durationMinutes),
      timeFare,
      bookingFee,
      minimumFare,
      totalFare: Math.round(totalFare * 100) / 100,
    };
  }
}
