import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: _PolicyBody(),
      ),
    );
  }
}

class _PolicyBody extends StatelessWidget {
  const _PolicyBody();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Privacy Policy', style: textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Last updated: March 2026',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 20),

        _section(context, 'About This Policy',
            'The Daily Protocol ("we", "our", "us") is committed to protecting '
            'your personal information. This Privacy Policy explains what data '
            'we collect when you use The Daily Protocol mobile application '
            '("App"), how we use it, and the rights you have over it.\n\n'
            'By using the App you agree to the collection and use of information '
            'as described in this policy. If you do not agree, please do not '
            'use the App.'),

        _section(context, '1. Who We Are',
            'The Daily Protocol is operated as an independent mobile application. '
            'For privacy enquiries, contact us at:\n\n'
            '  Email: dailyprotocolapp@gmail.com\n\n'
            'We are the data controller for the personal data described in this '
            'policy.'),

        _section(context, '2. Data We Collect',
            'We collect only what is necessary to provide the App\'s features.\n\n'
            'a) App Usage Data (stored only on your device)\n'
            '   • Protocols you have marked as favourites\n'
            '   • Protocols you have recently opened\n'
            '   • Checklist progress (which steps you have checked, timestamps, notes, photos)\n'
            '   • Protocol reminder times you have set\n\n'
            'b) Technical Data\n'
            '   • App version, operating system version (for crash diagnostics, if enabled)\n'
            '   • Anonymous usage events (e.g. app open, search query — no personally identifiable information)\n\n'
            'We do NOT collect:\n'
            '   • Any account, email, phone number, or personal identifier — no sign-in is required\n'
            '   • Precise GPS location (the "Nearby Help" feature opens Google Maps in your browser — we receive no location data)\n'
            '   • Contacts, camera roll, or microphone data\n'
            '   • Health or biometric data'),

        _section(context, '3. How We Use Your Data',
            '• To save your checklist progress, favourites, and reminders on your device\n'
            '• To send local push notifications for reminders you configure\n'
            '• To maintain your subscription status (verified through Google Play or the App Store)\n'
            '• To diagnose crashes and improve app stability\n\n'
            'We do NOT:\n'
            '• Sell your data to third parties\n'
            '• Use your data for advertising or profiling\n'
            '• Share your data with any third party except those listed in Section 4'),

        _section(context, '4. Third-Party Services',
            'The App uses the following third-party services, each governed by '
            'their own privacy policy:\n\n'
            '• Google Play Billing / Apple App Store (subscription payments)\n'
            '  Google Privacy Policy: https://policies.google.com/privacy\n'
            '  Apple Privacy Policy: https://www.apple.com/legal/privacy/\n\n'
            'We do not use analytics SDKs (e.g. Mixpanel, Amplitude) or '
            'advertising SDKs (e.g. AdMob, Facebook Audience Network).'),

        _section(context, '5. Data Storage & Security',
            '• All your data is stored locally on your device using encrypted storage (Hive).\n'
            '• No personal data is transmitted to or stored on our servers.\n'
            '• Payment processing is handled entirely by Google Play or the App Store — '
            'we never see your card number or payment details.'),

        _section(context, '6. Data Retention',
            '• All data is stored locally on your device until you uninstall the App '
            'or clear App data in your phone\'s settings.\n'
            '• We do not hold any of your data on our servers.'),

        _section(context, '7. Your Rights (GDPR / UK GDPR)',
            'If you are located in the European Economic Area or the United Kingdom, '
            'you have the following rights:\n\n'
            '• Right of access — You can request a copy of the data we hold about you.\n'
            '• Right to rectification — You can ask us to correct inaccurate data.\n'
            '• Right to erasure ("right to be forgotten") — Since all data is stored '
            'locally on your device, you can erase it by clearing App data or uninstalling the App. For any enquiries, email us.\n'
            '• Right to data portability — We can provide your data in a structured, '
            'machine-readable format on request.\n'
            '• Right to object — You can object to processing at any time by emailing us.\n'
            '• Right to restrict processing — You can request we limit how we use your data.\n\n'
            'To exercise any right, email: dailyprotocolapp@gmail.com\n'
            'We will respond within 30 days.'),

        _section(context, '8. Children\'s Privacy',
            'The App is not directed to children under the age of 13. We do not '
            'knowingly collect personal data from children under 13. If you believe '
            'a child under 13 has provided us with personal data, please contact us '
            'at dailyprotocolapp@gmail.com and we will delete it promptly.'),

        _section(context, '9. Changes to This Policy',
            'We may update this Privacy Policy from time to time. We will notify you '
            'of material changes by updating the "Last updated" date at the top of '
            'this page. Continued use of the App after changes constitutes your '
            'acceptance of the revised policy.'),

        _section(context, '10. Contact Us',
            'For privacy-related questions, requests, or complaints:\n\n'
            '  Email: dailyprotocolapp@gmail.com\n\n'
            'You also have the right to lodge a complaint with your local data '
            'protection authority (e.g. the ICO in the UK, or your national DPA '
            'in the EU).'),

        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Questions? Email us at dailyprotocolapp@gmail.com — '
            'we aim to respond within 30 days.',
            style: textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _section(BuildContext context, String title, String body) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(body, style: textTheme.bodyMedium?.copyWith(height: 1.55)),
        ],
      ),
    );
  }
}
