import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: _TermsBody(),
      ),
    );
  }
}

class _TermsBody extends StatelessWidget {
  const _TermsBody();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Terms of Service', style: textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Last updated: March 2026',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 16),

        // ── CRITICAL DISCLAIMER BOX ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.error.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: colorScheme.onErrorContainer, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'IMPORTANT — SAFETY DISCLAIMER\n\n'
                  'The Daily Protocol provides checklists and guides for '
                  'general educational purposes only. The content is NOT a '
                  'substitute for professional advice from trained emergency '
                  'services, medical professionals, fire safety experts, '
                  'electricians, or any other licensed professional.\n\n'
                  'IN A LIFE-THREATENING EMERGENCY, CALL YOUR LOCAL EMERGENCY '
                  'SERVICES IMMEDIATELY (e.g. 999 in the UK, 911 in the US, '
                  '112 in the EU). Do not delay calling emergency services in '
                  'order to consult this App.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        _section(context, '1. Acceptance of Terms',
            'By downloading, installing, or using The Daily Protocol application '
            '("App"), you agree to be bound by these Terms of Service ("Terms"). '
            'If you do not agree to these Terms, do not use the App.\n\n'
            'We may update these Terms at any time. Continued use of the App '
            'after changes are posted constitutes acceptance of the revised Terms.'),

        _section(context, '2. Description of Service',
            'The Daily Protocol is a mobile application that provides safety '
            'checklists, emergency protocols, and guidance for a range of sectors '
            'including but not limited to vehicle safety, fire safety, electrical '
            'safety, and workplace safety.\n\n'
            'The App also provides a "Nearby Help" feature that opens a third-party '
            'mapping service to help you locate services in your area.'),

        _section(context, '3. Safety Disclaimer & Limitation of Liability',
            '3.1 FOR GUIDANCE ONLY\n'
            'All content in the App — including checklists, protocols, safety tips, '
            'and emergency guidance — is provided for general informational and '
            'educational purposes only. It does not constitute professional advice '
            'and should not be relied upon as the sole basis for any safety, '
            'medical, legal, or other professional decision.\n\n'
            '3.2 ALWAYS CONTACT PROFESSIONAL SERVICES\n'
            'In any emergency situation:\n'
            '   • Call your local emergency services immediately (999 / 911 / 112)\n'
            '   • Do not rely solely on this App in life-threatening situations\n'
            '   • Consult qualified professionals (doctors, fire service, electricians, '
            'structural engineers) for any situation requiring expert judgement\n\n'
            '3.3 NO WARRANTY\n'
            'The App and its content are provided "as is" without warranty of any kind, '
            'express or implied. We do not warrant that the content is accurate, '
            'complete, current, suitable for any particular purpose, or free from '
            'errors.\n\n'
            '3.4 LIMITATION OF LIABILITY\n'
            'To the maximum extent permitted by applicable law, The Daily Protocol '
            'and its operators shall not be liable for any direct, indirect, '
            'incidental, special, or consequential damages arising out of or in '
            'connection with your use of, or inability to use, the App or its '
            'content — including but not limited to personal injury, property damage, '
            'or loss of data.'),

        _section(context, '4. Subscription Terms',
            '4.1 FREE PLAN\n'
            'The free plan gives access to a limited number of protocols as stated '
            'in the App. No payment is required for the free plan.\n\n'
            '4.2 PREMIUM SUBSCRIPTION\n'
            'Premium gives unlimited access to all protocols and features for a '
            'recurring monthly subscription fee as displayed in the App at the '
            'time of purchase.\n\n'
            '4.3 BILLING & AUTO-RENEWAL\n'
            '   • Your subscription automatically renews each month unless you cancel '
            'at least 24 hours before the end of the current billing period.\n'
            '   • Payment is charged to your Google Play or App Store account.\n'
            '   • You can manage or cancel your subscription at any time in:\n'
            '     – Google Play Store: Play Store → Profile → Payments & subscriptions → Subscriptions\n'
            '     – Apple App Store: Settings → Apple ID → Subscriptions\n\n'
            '4.4 CANCELLATION\n'
            'Cancellation takes effect at the end of the current paid period. '
            'You will retain Premium access until the period expires. We do not '
            'provide refunds for partial billing periods, except where required '
            'by applicable law.\n\n'
            '4.5 PRICE CHANGES\n'
            'We may change the subscription price. We will give you reasonable '
            'advance notice of any price change. Continued use of the subscription '
            'after the price change constitutes your acceptance of the new price.'),

        _section(context, '5. User Responsibilities',
            '• You must be at least 13 years of age to use the App.\n'
            '• You are responsible for maintaining the security of your account '
            'credentials.\n'
            '• You agree not to use the App for any unlawful purpose.\n'
            '• You agree not to attempt to reverse engineer, decompile, or '
            'disassemble any part of the App.\n'
            '• You agree not to use automated tools to scrape, copy, or reproduce '
            'App content without our written permission.'),

        _section(context, '6. Intellectual Property',
            'All content in the App, including protocol text, safety tips, '
            'checklists, icons, and design, is the intellectual property of '
            'The Daily Protocol or its licensors. You may not reproduce, '
            'distribute, or create derivative works without explicit written '
            'permission.\n\n'
            'Content you create within the App (checklist notes, photos) remains '
            'yours. We do not claim ownership over user-generated content.'),

        _section(context, '7. Third-Party Services',
            'The App integrates with Google Maps (via Nearby Help) and the respective '
            'app stores (Google Play, Apple App Store). Your use of those services is governed '
            'by their own terms and privacy policies. We are not responsible for '
            'the availability, accuracy, or content of third-party services.'),

        _section(context, '8. Governing Law',
            'These Terms are governed by and construed in accordance with the '
            'laws of England and Wales. Any disputes shall be subject to the '
            'exclusive jurisdiction of the courts of England and Wales, unless '
            'mandatory local laws require otherwise.'),

        _section(context, '9. Contact',
            'For questions about these Terms:\n\n'
            '  Email: dailyprotocolapp@gmail.com'),

        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Questions about these Terms? Email us at '
            'dailyprotocolapp@gmail.com',
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
