import 'package:flutter/material.dart';

class SafetyGuidelinesScreen extends StatelessWidget {
  const SafetyGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Guidelines'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildBeforeRunningCard(),
            const SizedBox(height: 16),
            _buildDuringRunCard(),
            const SizedBox(height: 16),
            _buildMeetingPointCard(),
            const SizedBox(height: 16),
            _buildCommunicationCard(),
            const SizedBox(height: 16),
            _buildEmergencyCard(),
            const SizedBox(height: 16),
            _buildRedFlagsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      color: Colors.green.shade50,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Text(
                  'Your Safety is Our Priority',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Running with others should be fun and safe. Follow these guidelines to protect yourself and others in the CommunityRun community.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeforeRunningCard() {
    return _buildGuidelineCard(
      'Before Running',
      Icons.schedule,
      Colors.blue,
      [
        '✓ Check the runner\'s profile and reviews from other participants',
        '✓ Verify the meeting location is public and well-lit',
        '✓ Share your running plans with a trusted friend or family member',
        '✓ Check the weather conditions and dress appropriately',
        '✓ Bring identification and emergency contact information',
        '✓ Ensure your phone is fully charged',
        '✓ Set up your emergency contact in the app',
        '✓ Review the planned route and distance',
      ],
    );
  }

  Widget _buildDuringRunCard() {
    return _buildGuidelineCard(
      'During the Run',
      Icons.directions_run,
      Colors.orange,
      [
        '✓ Stay aware of your surroundings at all times',
        '✓ Trust your instincts - if something feels wrong, stop or leave',
        '✓ Keep your group together, don\'t leave anyone behind',
        '✓ Follow traffic rules and run facing traffic when on roads',
        '✓ Be respectful of other runners\' pace and abilities',
        '✓ Stay hydrated and take breaks as needed',
        '✓ Use the SOS button if you encounter an emergency',
        '✓ Be kind and encouraging to all participants',
      ],
    );
  }

  Widget _buildMeetingPointCard() {
    return _buildGuidelineCard(
      'Choosing Safe Meeting Points',
      Icons.location_on,
      Colors.purple,
      [
        '✓ Select public locations with good visibility',
        '✓ Choose well-lit areas, especially for early morning or evening runs',
        '✓ Pick locations with nearby facilities (restrooms, water, parking)',
        '✓ Avoid isolated areas, parking lots, or residential neighborhoods',
        '✓ Consider locations with security cameras or foot traffic',
        '✓ Make sure the location is easily accessible by public transport',
        '✓ Provide clear landmarks and directions',
        '✓ Arrive early to assess the safety of the location',
      ],
    );
  }

  Widget _buildCommunicationCard() {
    return _buildGuidelineCard(
      'Communication Guidelines',
      Icons.chat,
      Colors.teal,
      [
        '✓ Be clear about your pace, distance, and running goals',
        '✓ Communicate any health conditions or limitations',
        '✓ Confirm attendance and arrival time in the group chat',
        '✓ Cancel with reasonable notice if you can\'t attend',
        '✓ Keep group conversations respectful and inclusive',
        '✓ Report inappropriate messages or behavior immediately',
        '✓ Don\'t share personal information beyond what\'s necessary',
        '✓ Use the app\'s messaging system rather than personal numbers',
      ],
    );
  }

  Widget _buildEmergencyCard() {
    return _buildGuidelineCard(
      'Emergency Procedures',
      Icons.emergency,
      Colors.red,
      [
        '⚠️ Call emergency services (112) for immediate medical emergencies',
        '⚠️ Use the SOS button to alert your emergency contact and group',
        '⚠️ Share your location immediately if you need help',
        '⚠️ Stay calm and provide clear information about your situation',
        '⚠️ If someone in your group needs help, don\'t leave them alone',
        '⚠️ Know the location of nearby hospitals or medical facilities',
        '⚠️ Carry any necessary medications (inhaler, insulin, etc.)',
        '⚠️ Report any safety incidents to CommunityRun support',
      ],
    );
  }

  Widget _buildRedFlagsCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 24),
                SizedBox(width: 12),
                Text(
                  'Red Flags - When to Be Cautious',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRedFlag('The organizer asks to meet in an isolated location'),
            _buildRedFlag('Someone pressures you to share personal information'),
            _buildRedFlag('The meeting point changes last minute to an unsafe area'),
            _buildRedFlag('Inappropriate messages or comments in group chat'),
            _buildRedFlag('Someone refuses to verify their identity'),
            _buildRedFlag('The organizer has no previous running history or reviews'),
            _buildRedFlag('You feel uncomfortable or unsafe for any reason'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Remember: It\'s always better to be safe. If you have any doubts, don\'t participate and report your concerns.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineCard(String title, IconData icon, Color color, List<String> guidelines) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...guidelines.map((guideline) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                guideline,
                style: const TextStyle(fontSize: 15),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRedFlag(String flag) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.flag, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              flag,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}