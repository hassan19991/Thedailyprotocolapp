import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../protocols/application/protocol_providers.dart';
import '../../protocols/domain/subscription_tier.dart';
import '../data/subscription_service.dart';

Future<void> showPaywallSheet(BuildContext context,
    {required String protocolTitle}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (context) =>
        _PaywallSheetContent(protocolTitle: protocolTitle),
  );
}

// ── Sheet ─────────────────────────────────────────────────────────────────────

class _PaywallSheetContent extends ConsumerStatefulWidget {
  const _PaywallSheetContent({required this.protocolTitle});
  final String protocolTitle;

  @override
  ConsumerState<_PaywallSheetContent> createState() =>
      _PaywallSheetContentState();
}

class _PaywallSheetContentState extends ConsumerState<_PaywallSheetContent>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _processing = false;
  String? _error;
  List<SubscriptionProduct> _products = const [];

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadProducts();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products =
          await ref.read(subscriptionServiceProvider).availableProducts();
      if (!mounted) return;
      setState(() => _products = products);
      _fadeCtrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Unable to load plans: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _purchase(SubscriptionProduct product) async {
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      final tier =
          await ref.read(subscriptionServiceProvider).purchase(product);
      await ref.read(subscriptionTierProvider.notifier).refreshTier();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tier == SubscriptionTier.premium
            ? 'Premium unlocked! Enjoy full access.'
            : 'Purchase received. Premium may take a moment to activate.'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      // Don't show an error for a user-initiated cancellation.
      if (!msg.contains('cancelled') && !msg.contains('canceled')) {
        setState(() => _error = 'Purchase failed: $msg');
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _startPurchaseFlow(SubscriptionProduct product) async {
    await _purchase(product);
  }

  Future<void> _startRestoreFlow() async {
    await _restore();
  }

  Future<void> _restore() async {
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      final tier =
          await ref.read(subscriptionServiceProvider).restorePurchases();
      await ref.read(subscriptionTierProvider.notifier).refreshTier();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tier == SubscriptionTier.premium
            ? 'Purchases restored. Premium is active.'
            : 'No active premium subscription found.'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Restore failed: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _openPaymentSettings() async {
    final uri = defaultTargetPlatform == TargetPlatform.iOS
        ? Uri.parse('https://apps.apple.com/account/subscriptions')
        : Uri.parse('https://play.google.com/store/paymentmethods');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      setState(() => _error = 'Unable to open payment settings.');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1825) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24, 20, 24,
                MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Premium badge ─────────────────────────────────────
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF0D52A0), Color(0xFF0B9FBF)]),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium_rounded,
                              color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'PREMIUM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Headline ──────────────────────────────────────────
                  Text(
                    'Unlock the Full Library',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"${widget.protocolTitle}" is part of the premium library. '
                    'Upgrade to access every protocol, PDF exports, and cloud backup.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.65),
                        ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 22),

                  // ── Feature grid ──────────────────────────────────────
                  _FeatureGrid(isDark: isDark),

                  const SizedBox(height: 20),

                  // ── Comparison ────────────────────────────────────────
                  _ComparisonCard(
                      isDark: isDark,
                      freeLimit: AppConfig.freeProtocolLimit),

                  const SizedBox(height: 20),

                  // ── Products ──────────────────────────────────────────
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_products.isEmpty)
                    _NoProductsWidget(
                        processing: _processing,
                        ref: ref)
                  else
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        children: _products
                            .map((p) => _ProductTile(
                                  product: p,
                                  processing: _processing,
                                  isDark: isDark,
                                  onTap: () => _startPurchaseFlow(p),
                                ))
                            .toList(),
                      ),
                    ),

                  // ── Error ─────────────────────────────────────────────
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onErrorContainer,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── Footer ────────────────────────────────────────────
                  // ── Subscription legal notice (required by both stores) ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Subscription auto-renews monthly. Cancel anytime in '
                      'Play Store (Profile → Payments & subscriptions → Subscriptions) '
                      'or App Store (Settings → Apple ID → Subscriptions) '
                      'at least 24 hours before renewal. '
                      'No refund for the current billing period.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            height: 1.5,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _FooterLink(
                          label: 'Restore Purchases',
                          onTap: _processing ? null : _startRestoreFlow),
                      _FooterLink(
                          label: 'Payment Method',
                          onTap: _processing ? null : _openPaymentSettings),
                      _FooterLink(
                          label: 'Refresh',
                          onTap: _processing ? null : _loadProducts),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _FooterLink(
                          label: 'Privacy Policy',
                          onTap: () => context.push('/legal/privacy')),
                      const Text('·',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey)),
                      _FooterLink(
                          label: 'Terms',
                          onTap: () => context.push('/legal/terms')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feature grid ──────────────────────────────────────────────────────────────

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const features = [
      (Icons.library_books_rounded, 'Full Protocol Library',
          'Unlimited access to every checklist'),
      (Icons.picture_as_pdf_rounded, 'PDF Export',
          'Reports with notes, photos & timestamps'),
      (Icons.cloud_done_rounded, 'Cloud Backup',
          'Sync favourites and progress securely'),
      (Icons.wifi_off_rounded, 'Offline Vault',
          'All protocols available offline'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: features
          .map((f) => _FeatureCell(
              icon: f.$1,
              title: f.$2,
              subtitle: f.$3,
              isDark: isDark))
          .toList(),
    );
  }
}

class _FeatureCell extends StatelessWidget {
  const _FeatureCell(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.isDark});

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0D52A0)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Comparison card ───────────────────────────────────────────────────────────

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard(
      {required this.isDark, required this.freeLimit});
  final bool isDark;
  final int freeLimit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E2E42)
              : const Color(0xFFDDE6F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF111C2A)
                  : const Color(0xFFF2F6FC),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              children: [
                Expanded(
                    child: Text('Feature',
                        style: Theme.of(context).textTheme.labelLarge)),
                SizedBox(
                  width: 64,
                  child: Text('Free',
                      style: Theme.of(context).textTheme.labelMedium,
                      textAlign: TextAlign.center),
                ),
                SizedBox(
                  width: 72,
                  child: Text('Premium',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: const Color(0xFF0D52A0)),
                      textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
          _CmpRow('Protocols', '$freeLimit only', 'Unlimited'),
          _CmpRow('First steps visible', '5 steps only', 'All steps'),
          _CmpRow('Step photos', 'First 5 steps included', 'All steps + detailed images'),
          _CmpRow('PDF export', 'Not available', 'All steps + images + notes'),
          _CmpRow('Cloud backup', false, true),
          _CmpRow('Offline vault', false, true),
        ],
      ),
    );
  }
}

class _CmpRow extends StatelessWidget {
  const _CmpRow(this.label, this.free, this.premium);
  final String label;
  final Object free;
  final Object premium;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(
                color: Theme.of(context).dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.bodySmall)),
          SizedBox(width: 64, child: Center(child: _cell(context, free, false))),
          SizedBox(width: 72, child: Center(child: _cell(context, premium, true))),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, Object value, bool isPremium) {
    if (value is bool) {
      return Icon(
        value ? Icons.check_circle_rounded : Icons.cancel_rounded,
        size: 18,
        color: value
            ? (isPremium ? const Color(0xFF0D52A0) : Colors.green)
            : Colors.grey.withValues(alpha: 0.4),
      );
    }
    return Text(value as String,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isPremium ? const Color(0xFF0D52A0) : null,
        ),
        textAlign: TextAlign.center);
  }
}

// ── Product tile ──────────────────────────────────────────────────────────────

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.processing,
    required this.isDark,
    required this.onTap,
  });

  final SubscriptionProduct product;
  final bool processing;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: processing ? null : onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D52A0), Color(0xFF0B9FBF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D52A0)
                      .withValues(alpha: isDark ? 0.35 : 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(product.description,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(product.priceString,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900)),
                    const Text('/month',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── No products widget ────────────────────────────────────────────────────────

class _NoProductsWidget extends StatelessWidget {
  const _NoProductsWidget({required this.processing, required this.ref});
  final bool processing;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            kDebugMode
                ? 'No subscription plan found in the store yet.\n\n'
                  'To enable payments, create a subscription product in\n'
                  'Google Play Console (Android) or App Store Connect (iOS)\n'
                  'using the product ID:\n\n'
                  '  ${AppConfig.subscriptionProductId}\n\n'
                  'See PAYMENT_SETUP.md in the project root for full '
                  'step-by-step instructions.'
                : 'Unable to load subscription plans. Please ensure you have created '
                  'the subscription product in Google Play Console or App Store Connect. '
                  'Try refreshing or contact support for assistance.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: processing
                ? null
                : () async {
                    await ref
                        .read(subscriptionServiceProvider)
                        .setDebugPremiumOverride(true);
                    await ref
                        .read(subscriptionTierProvider.notifier)
                        .refreshTier();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Debug premium override enabled.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
            icon: const Icon(Icons.science_outlined),
            label: const Text('Enable Test Premium (Debug only)'),
          ),
        ],
      ],
    );
  }
}

// ── Footer link ───────────────────────────────────────────────────────────────

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        textStyle: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}
