import 'package:flutter/material.dart';

class DriverLegalScreen extends StatelessWidget {
  const DriverLegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Legal & Privacy Policy', style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prominent Google Play Location Policy Compliance Notice Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Background Location Usage Disclosure',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'District Car Partner collects and accesses location data (foreground and background) to enable ride dispatch from nearby pickup points, calculate distance and rural fares, and provide real-time vehicle tracking to passengers even when the app is minimized, closed, or running in the background during active duty.',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF1E40AF), height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '1. Driver Partner Agreement',
              content:
                  'By registering as an independent driver partner on District Car Jharkhand, you agree to provide safe, reliable, and respectful transportation to citizens across rural, block, and urban districts. Drivers operate as independent transport partners with transparent, direct fare collection.',
            ),
            _buildSection(
              title: '2. Data Collection & Usage',
              content:
                  'We collect driver partner contact details (name, phone number, email), assigned vehicle information (registration number, category, vehicle model), and real-time GPS coordinates. This data is strictly utilized to facilitate customer bookings, calculate transparent travel fares, and ensure rider safety.',
            ),
            _buildSection(
              title: '3. Fare Transparency & Payment Directness',
              content:
                  'District Car follows a direct, transparent model for rural mobility. Fares are calculated on an accurate per-kilometer basis plus stopping allowance for round trips. Drivers receive payment directly from passengers via Cash or direct UPI without arbitrary platform withholdings.',
            ),
            _buildSection(
              title: '4. Vehicle & Passenger Safety Standards',
              content:
                  'Driver partners must maintain their vehicles in clean, roadworthy condition and possess valid commercial driving credentials and vehicle registration as applicable. Rash driving, passenger misconduct, or overcharging will lead to immediate partner suspension.',
            ),
            _buildSection(
              title: '5. Account & Data Deletion',
              content:
                  'In compliance with Google Play Store data safety standards, drivers retain complete control over their profile and vehicle data. You can request permanent account and vehicle data deletion anytime through the "Delete Account" option in your Profile screen or by contacting our Data Protection Officer.',
            ),
            _buildSection(
              title: '6. Contact & Grievance Officer',
              content:
                  'District Car Jharkhand\nCentral Control Room: Albert Ekka Chowk, Ranchi, Jharkhand\nEmail: contact@projectmarket.in\nHelpline: +91 87896 01387',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.5),
          ),
        ],
      ),
    );
  }
}
