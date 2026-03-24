import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Central "Legal & About" hub accessed from Settings.
///
/// Links to:
///   - Privacy Policy  (/legal/privacy)
///   - Terms of Service  (/legal/terms)
///   - Contact (email)
///   - App version info
class LegalHubScreen extends StatelessWidget {
  const LegalHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Legal & About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // ── App identity card ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D52A0), Color(0xFF0B9FBF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'The Daily Protocol',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Safety checklists & emergency protocols',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Safety disclaimer ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: colorScheme.error.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: colorScheme.onErrorContainer, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'FOR GUIDANCE ONLY — Always call 999 / 911 / 112 in a '
                    'life-threatening emergency. This App is not a substitute '
                    'for professional emergency services.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Legal documents section ──────────────────────────────────────
          _sectionHeader(context, 'Legal Documents'),
          const SizedBox(height: 8),

          _legalTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'How we collect, use, and protect your data',
            onTap: () => context.push('/legal/privacy'),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _legalTile(
            context,
            icon: Icons.gavel_rounded,
            title: 'Terms of Service',
            subtitle:
                'Usage rules, safety disclaimer, and subscription terms',
            onTap: () => context.push('/legal/terms'),
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          // ── Contact section ──────────────────────────────────────────────
          _sectionHeader(context, 'Contact Us'),
          const SizedBox(height: 8),

          _legalTile(
            context,
            icon: Icons.mail_outline_rounded,
            title: 'Get in Touch',
            subtitle: 'Advertising, protocol suggestions & content updates',
            onTap: () => _launchEmail(
              'dailyprotocolapp@gmail.com',
              subject: 'The Daily Protocol — Enquiry',
            ),
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          // ── App info ─────────────────────────────────────────────────────
          _sectionHeader(context, 'App Information'),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF111C2A)
                  : const Color(0xFFF2F6FC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E2E42)
                    : const Color(0xFFDDE6F0),
              ),
            ),
            child: Column(
              children: [
                _infoRow(context, 'App Name', 'The Daily Protocol'),
                _divider(context),
                _infoRow(context, 'Purpose',
                    'Safety checklists & emergency guidance'),
                _divider(context),
                _infoRow(context, 'Content Disclaimer',
                    'For guidance only — not professional advice'),
                _divider(context),
                _infoRow(context, 'Data Protection',
                    'GDPR / UK GDPR compliant'),
                _divider(context),
                _infoRow(context, 'Minimum Age', '13 years'),
                _divider(context),
                _infoRow(context, 'Governing Law', 'England and Wales'),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Footer ───────────────────────────────────────────────────────
          Text(
            'The Daily Protocol is provided for educational and informational '
            'purposes. Always follow the advice of qualified professionals and '
            'emergency services.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.45),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.5),
          ),
    );
  }

  Widget _legalTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF111C2A)
                : const Color(0xFFF2F6FC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF1E2E42)
                  : const Color(0xFFDDE6F0),
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 22,
                  color: const Color(0xFF0D52A0)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color:
                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
          ),
          Expanded(
            flex: 3,
            child: Text(value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.65),
                    ),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
        height: 1,
        thickness: 0.5,
        color: Theme.of(context).dividerColor);
  }

  Future<void> _launchEmail(String address, {required String subject}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: address,
      queryParameters: {'subject': subject},
    );
    if (!await launchUrl(uri)) {
      // Email client not available — silently ignore.
    }
  }
}
