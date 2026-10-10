import 'package:flutter/material.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalPolicyScreen extends StatelessWidget {
  final int initialTabIndex; // 0 for Terms, 1 for Privacy

  const LegalPolicyScreen({super.key, this.initialTabIndex = 0});

  Future<void> _makeCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Legal & Policies (नियम व नीतियां)',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor: Color(0xFF64748B),
            labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            tabs: [
              Tab(text: 'Terms & Conditions'),
              Tab(text: 'Privacy Policy'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTermsTab(),
            _buildPrivacyTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPolicyCard(
            title: '1. Passenger Transit Agreement',
            content:
                'District Car Mobility ("Platform", "We") operates as an intermediary technology aggregator connecting commuters across Jharkhand with verified independent commercial driver partners ("Sarathi"). By booking a ride through District Car, you agree to comply with all platform transit guidelines.',
          ),
          const SizedBox(height: 14),
          _buildPolicyCard(
            title: '2. Fare Structure & Transparent Calculation',
            content:
                '• Short Trips (<25 km): Calculated strictly based on vehicle category per-km rate plus minimum fare protection.\n• Long Distance & Round Trips: Computed as (Target Distance × 2 × per-km rate) with 1st Hour Waiting completely complimentary.\n• Additional waiting hours are billed at category rates (₹40-₹60/hr) or overnight driver night allowance.\n• Actual state/national toll plaza receipts and railway station parking charges are payable as per physical slips.',
          ),
          const SizedBox(height: 14),
          _buildPolicyCard(
            title: '3. Rural Doorstep Pickups & Route Feasibility',
            content:
                'Drivers will navigate to the nearest motorable village chowk, tola, or road coordinate. In cases of unpaved or obstructed dirt paths, the rider coordinates mutual pickup points with the Sarathi partner directly over phone.',
          ),
          const SizedBox(height: 14),
          _buildPolicyCard(
            title: '4. Cancellation & Refund Policy',
            content:
                '• Cancellations within 5 minutes of driver acceptance are 100% free of charge.\n• If a driver reaches the designated pickup point and waits over 10 minutes without passenger response, a nominal cancellation fee (₹20-₹40) applies to compensate driver fuel.\n• Digital deductions for unfulfilled rides are refunded back within 24 to 48 hours to the original payment source.',
          ),
          const SizedBox(height: 14),
          _buildPolicyCard(
            title: '5. Zero Harassment & Safety Protocol',
            content:
                'Carriage of hazardous, inflammable, or contraband substances is strictly banned under the Indian Motor Vehicles Act. Any verbal abuse, vandalism, or harassment of drivers or riders results in immediate permanent blacklisting and forwarding to Jharkhand Police.',
          ),
          const SizedBox(height: 14),
          _buildCompanyContactFooter(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPrivacyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPolicyCard(
            title: '1. Information We Collect (Google Play Safe)',
            content:
                'We collect only data strictly necessary for rural cab operations:\n• Profile Data: Full name, mobile number, optional date of birth, blood group (for emergency medical SOS).\n• Geolocation Data: Pickup and drop coordinates solely during active booking and trip execution for GPS route navigation and driver dispatch.\n• Device & App Identifiers: Push notification tokens (FCM) to deliver live ride status updates.',
          ),
          const SizedBox(height: 14),
          _buildPolicyCard(
            title: '2. Zero Data Selling & Third-Party Sharing',
            content:
                'District Car has a strict policy: We NEVER sell, lease, or monetize your personal data to ad brokers or marketing agencies. Data is processed securely via Google Cloud Firestore with end-to-end security encryption.',
          ),
          const SizedBox(height: 14),
          _buildPolicyCard(
            title: '3. Location Privacy & Phone Masking',
            content:
                '• Rider background location is never tracked outside active trip sessions.\n• Ride communications are safeguarded. Drivers receive only pickup and destination coordinates necessary to complete transit safely.',
          ),
          const SizedBox(height: 14),
          _buildPolicyCard(
            title: '4. Account Deletion & Right to Be Forgotten',
            content:
                'In full accordance with Google Play Store User Data Policy, any registered user can permanently delete their account and associated profile information directly within the app under Profile ➔ Delete Account. All identifiers are erased immediately.',
          ),
          const SizedBox(height: 14),
          _buildPolicyCard(
            title: '5. Grievance Officer & Contact',
            content:
                'For privacy inquiries or compliance notices, reach our Grievance Officer:\n• Monu Kumar (CEO, District Car Mobility)\n• Sonu Kumar (Co-Founder)\n• Nichey Chowk, Khunti, Jharkhand - 835210\n• Contact: +91 87896 01387\n• Email: support@districtcar.in',
          ),
          const SizedBox(height: 14),
          _buildCompanyContactFooter(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPolicyCard({required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.55),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyContactFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'District Car Mobility · Jharkhand Operational Office',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Nichey Chowk, Khunti, Jharkhand - 835210 · Helpline: +91 87896 01387\nCEO: Monu Kumar | Co-Founder: Sonu Kumar',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _makeCall('+918789601387'),
            child: const Row(
              children: [
                Icon(Icons.phone, size: 14, color: AppColors.primary),
                SizedBox(width: 6),
                Text('Call Helpline: +91 87896 01387', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
