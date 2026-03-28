import 'package:flutter/material.dart';

/// Terms shown only on the public (pre-login) navbar route `/terms`.
/// Logged-in flow still uses [TermsAgreementScreen] at `/terms-agreement`.
class PublicTermsConditionsPage extends StatelessWidget {
  const PublicTermsConditionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.description_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rules for using RankX before you create an account or make a purchase.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _introCard(context),
                  const SizedBox(height: 24),
                  _section(
                    context,
                    title: '1. Agreement',
                    body:
                        'By accessing or using RankX (website or app), you agree to these Terms & Conditions and our Privacy Policy. If you do not agree, please do not use the service.',
                  ),
                  _section(
                    context,
                    title: '2. The service',
                    body:
                        'RankX provides educational quiz content, practice tests, rankings, and related features. We may update, add, or remove features to improve the platform. Availability may vary by device or region.',
                  ),
                  _section(
                    context,
                    title: '3. Accounts',
                    body:
                        'You are responsible for accurate registration information and for keeping your login credentials confidential. You must not share your account in a way that abuses the service or harms other users.',
                  ),
                  _section(
                    context,
                    title: '4. Acceptable use',
                    body:
                        'You agree not to misuse RankX: no cheating, scraping, reverse engineering, disrupting servers, uploading harmful content, or attempting to access others’ accounts or data without permission.',
                  ),
                  _section(
                    context,
                    title: '5. Payments and checkout',
                    body:
                        'Paid quiz packages or subscriptions are subject to the pricing shown at checkout. Completing checkout means you accept the payment terms and our payment policy for that transaction. '
                        'Refunds and cancellations follow our Refund / Cancellation policy page. Taxes or fees may apply as shown before you pay.',
                  ),
                  _section(
                    context,
                    title: '6. Intellectual property',
                    body:
                        'RankX name, logo, questions, layouts, and other materials are protected. You receive a limited, personal licence to use the service; you may not copy, resell, or redistribute our content without permission.',
                  ),
                  _section(
                    context,
                    title: '7. Disclaimer',
                    body:
                        'RankX is provided for educational preparation. We do not guarantee exam results or ranks. To the extent permitted by law, we are not liable for indirect or consequential losses arising from use of the service.',
                  ),
                  _section(
                    context,
                    title: '8. Changes',
                    body:
                        'We may revise these terms from time to time. Continued use after changes means you accept the updated terms. Material changes may be highlighted in-app or on this page.',
                  ),
                  _section(
                    context,
                    title: '9. Contact',
                    body:
                        'For questions about these terms, use the Contact Us page or email rankxapp@gmail.com.',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Last updated: March 2026',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _introCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.gavel_rounded,
            color: Colors.blue,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'These Terms & Conditions apply to visitors and users who browse RankX before signing in. '
              'When you register or accept terms inside the app after login, additional agreements may apply as shown there.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.blue[900],
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
