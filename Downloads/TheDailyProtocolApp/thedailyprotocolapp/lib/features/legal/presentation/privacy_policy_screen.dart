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
            '   • Protocol reminder times you have set\n'
            '   • Daily notification preferences (on/off, scheduled time)\n'
            '   • Location permission preference (enabled/disabled toggle stored locally)\n'
            '   • Subscription tier status (free or premium)\n\n'
            'b) Location Data (only when you enable the Location feature)\n'
            '   • When you turn on "Location" in Settings and grant OS permission, '
            'the App accesses your device\'s GPS to display nearby emergency services '
            'within the Nearby Help screen.\n'
            '   • Your location is processed entirely on-device and is NEVER transmitted '
            'to our servers or any third party.\n'
            '   • You can disable location access at any time in App Settings or in '
            'your phone\'s system settings.\n\n'
            'c) Technical Data\n'
            '   • App version and operating system version (for crash diagnostics, if enabled)\n\n'
            'We do NOT collect:\n'
            '   • Any account, email, phone number, or personal identifier — no sign-in is required\n'
            '   • Location data without your explicit permission and voluntary opt-in\n'
            '   • Contacts, camera roll, or microphone data\n'
            '   • Health or biometric data\n'
            '   • Browsing history or advertising identifiers'),

        _section(context, '3. How We Use Your Data',
            '• To save your checklist progress, favourites, and reminders on your device\n'
            '• To send local push notifications for reminders you configure\n'
            '• To send a daily Protocol of the Day notification (opt-out available in Settings)\n'
            '• To show nearby emergency services based on your device location '
            '(only when you have enabled Location in Settings and granted OS permission)\n'
            '• To maintain your subscription status (verified through Google Play or the App Store)\n'
            '• To diagnose crashes and improve app stability\n\n'
            'We do NOT:\n'
            '• Sell your data to third parties\n'
            '• Use your data for advertising or profiling\n'
            '• Transmit your location or any personal data to our servers\n'
            '• Share your data with any third party except those listed in Section 4'),

        _section(context, '4. Third-Party Services',
            'The App uses the following third-party services, each governed by '
            'their own privacy policy:\n\n'
            '• Google Play Billing / Apple App Store (subscription payments)\n'
            '  Google Privacy Policy: https://policies.google.com/privacy\n'
            '  Apple Privacy Policy: https://www.apple.com/legal/privacy/\n\n'
            '• Device Location Services (OS-level GPS, only when Location is enabled)\n'
            '  Location data is processed on-device only and is not shared with any '
            'third-party service by this App.\n\n'
            'We do not use analytics SDKs (e.g. Mixpanel, Amplitude) or '
            'advertising SDKs (e.g. AdMob, Facebook Audience Network).'),

        _section(context, '5. Data Storage & Security',
            '• All your data is stored locally on your device using encrypted storage (Hive).\n'
            '• No personal data — including location data — is transmitted to or stored on our servers.\n'
            '• Location is accessed on-device only and is never logged, cached, or shared externally.\n'
            '• Crash log files are stored locally on your device; we never receive them automatically.\n'
            '• Payment processing is handled entirely by Google Play or the App Store — '
            'we never see your card number or payment details.'),

        _section(context, '6. Data Retention',
            '• All data is stored locally on your device until you uninstall the App '
            'or clear App data in your phone\'s settings.\n'
            '• We do not hold any of your data on our servers.'),

        _section(context, '7. Your Rights',
            'Since all your data is stored locally on your device, you have '
            'full control over it at all times:\n\n'
            '• View your data directly within the App\n'
            '• Edit or clear your checklist progress, favourites, and reminders in the App\n'
            '• Erase all data by clearing App data or uninstalling the App from your device\n'
            '• Disable location, notifications, or any other feature at any time in Settings'),

        _section(context, '8. Children\'s Privacy',
            'The App is not directed to children under the age of 13. '
            'We do not knowingly collect personal data from children under 13.'),

        _section(context, '9. Changes to This Policy',
            'We may update this Privacy Policy from time to time. We will notify you '
            'of material changes by updating the "Last updated" date at the top of '
            'this page. Continued use of the App after changes constitutes your '
            'acceptance of the revised policy.'),

        _section(context, '10. Contact Us',
            'Want to suggest a new protocol, request a content update, or discuss '
            'advertising opportunities?\n\n'
            'Email: dailyprotocolapp@gmail.com'),

        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Protocol suggestions, content updates, or advertising — '
            'reach us at dailyprotocolapp@gmail.com',
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
