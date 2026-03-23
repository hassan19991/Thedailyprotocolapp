import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../subscription/presentation/paywall_sheet.dart';
import '../application/protocol_providers.dart';
import '../data/emergency_service.dart';
import '../data/reminder_service.dart';
import '../data/report_export_service.dart';
import '../data/translation_service.dart';
import '../data/tts_service.dart';
import '../domain/protocol_model.dart';
import '../domain/protocol_progress.dart';
import '../domain/subscription_tier.dart';

class ProtocolReaderScreen extends ConsumerStatefulWidget {
  const ProtocolReaderScreen({super.key, required this.protocol});

  final ProtocolModel protocol;

  @override
  ConsumerState<ProtocolReaderScreen> createState() => _ProtocolReaderScreenState();
}

class _ProtocolReaderScreenState extends ConsumerState<ProtocolReaderScreen> {
  static const Map<String, String> _languageCodeToName = {
    'en': 'English',
    'fr': 'French',
    'es': 'Spanish',
    'de': 'German',
    'ar': 'Arabic',
    'hi': 'Hindi',
    'ur': 'Urdu',
    'it': 'Italian',
    'ka': 'Georgian',
    'ru': 'Russian',
  };

  late final TextEditingController _notesController;
  late final ProtocolProgressNotifier _progressNotifier;
  final _picker = ImagePicker();

  String? _translatedLanguageCode;
  _TranslatedProtocol? _translated;
  bool _isTranslating = false;
  bool _isExporting = false;
  bool _isLocatingEmergency = false;
  String _emergencyNumber = '112';

  // TTS
  TtsService? _tts;
  String? _speakingText; // which text is currently being spoken

  ProtocolModel get _baseProtocol => widget.protocol;

  @override
  void initState() {
    super.initState();
    _progressNotifier = ref.read(protocolProgressProvider(widget.protocol.id).notifier);
    final progress = ref.read(protocolProgressProvider(widget.protocol.id));
    _notesController = TextEditingController(text: progress.notes);

    if (_isEmergencyCategory(widget.protocol.category)) {
      unawaited(_detectEmergencyNumber());
    }

    // Wire TTS completion so we clear the speaking indicator
    _tts = ref.read(ttsServiceProvider);
    _tts!.onComplete = () {
      if (mounted) setState(() => _speakingText = null);
    };
  }

  @override
  void dispose() {
    _tts?.onComplete = null;
    unawaited(_tts?.stop());
    unawaited(_progressNotifier.flushPendingSaves());
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _toggleStepAudio(String text) async {
    await _tts?.toggleStep(text);
    if (mounted) {
      setState(() => _speakingText = (_tts?.isSpeaking(text) == true) ? text : null);
    }
  }

  Future<void> _stopAudio() async {
    await _tts?.stop();
    if (mounted) setState(() => _speakingText = null);
  }

  @override
  Widget build(BuildContext context) {
    final protocol = widget.protocol;
    final progress = ref.watch(protocolProgressProvider(protocol.id));
    final tier = ref.watch(subscriptionTierProvider);
    final total = protocol.steps.length;
    final checked = progress.checkedSteps.where((index) => index >= 0 && index < total).length;
    final ratio = total == 0 ? 0.0 : checked / total;
    final allDone = total > 0 && checked == total;
    final isFavorite = ref.watch(favoritesProvider).contains(protocol.id);

    final shown = _translated == null
        ? _TranslatedProtocol.fromBase(protocol)
        : _TranslatedProtocol(
            title: _translated!.title,
            description: _translated!.description,
            safetyNotes: _translated!.safetyNotes,
            steps: _translated!.steps,
          );

    final sectorColor = SectorColors.forSector(protocol.category);
    final sectorGradient = SectorColors.gradientForSector(protocol.category);

    final hasReminder = ref.read(reminderServiceProvider).hasActiveReminder(protocol.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(shown.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          // ── Reminder bell ──────────────────────────────────────────
          IconButton(
            icon: Icon(
              hasReminder ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
              color: hasReminder ? const Color(0xFFE9621A) : null,
            ),
            tooltip: hasReminder ? 'Edit reminder' : 'Set reminder',
            onPressed: () => _showReminderSheet(context, protocol),
          ),
          // ── Read Aloud toggle ──────────────────────────────────────
          IconButton(
            icon: _speakingText != null
                ? const Icon(Icons.stop_circle_rounded, color: Color(0xFF1D6FD8))
                : const Icon(Icons.volume_up_rounded),
            tooltip: _speakingText != null ? 'Stop audio' : 'Read aloud',
            onPressed: () {
              if (_speakingText != null) {
                _stopAudio();
              } else {
                final fullText = '${shown.title}. ${shown.description}. '
                    '${shown.steps.join('. ')}';
                _toggleStepAudio(fullText);
              }
            },
          ),
          // ── Bookmark ───────────────────────────────────────────────
          IconButton(
            icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border_outlined),
            tooltip: isFavorite ? 'Remove bookmark' : 'Bookmark',
            onPressed: () async {
              await ref.read(favoritesProvider.notifier).toggle(protocol.id);
            },
          ),
          // ── Translate ──────────────────────────────────────────────
          PopupMenuButton<String>(
            tooltip: 'Translate',
            icon: _isTranslating
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.translate_rounded),
            onSelected: (value) {
              if (value == 'original') {
                setState(() {
                  _translated = null;
                  _translatedLanguageCode = null;
                });
                return;
              }
              unawaited(_translateProtocol(value));
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(value: 'original', child: Text('Original')),
              ..._languageCodeToName.entries.map(
                (entry) => PopupMenuItem<String>(value: entry.key, child: Text(entry.value)),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Safety / guidance-only disclaimer ─────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'For guidance only. In an emergency call 999 / 911 / 112 immediately.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Translation chip
          if (_translatedLanguageCode != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Chip(
                avatar: const Icon(Icons.language_rounded, size: 16),
                label: Text('Translated: ${_languageCodeToName[_translatedLanguageCode] ?? _translatedLanguageCode}'),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                onDeleted: () => setState(() {
                  _translated = null;
                  _translatedLanguageCode = null;
                }),
              ),
            ),

          // Hero protocol card
          _ProtocolHeroCard(
            protocol: protocol,
            shown: shown,
            ratio: ratio,
            checked: checked,
            total: total,
            sectorGradient: sectorGradient,
            sectorColor: sectorColor,
          ),

          const SizedBox(height: 14),

          // Sector-specific help card (shown for all sectors)
          _SectorHelpCard(
            protocol: protocol,
            emergencyNumber: _emergencyNumber,
            loading: _isLocatingEmergency,
            onCall: _isEmergencyCategory(protocol.category)
                ? () async {
                    setState(() => _isLocatingEmergency = true);
                    try {
                      final info = await ref.read(emergencyServiceProvider).detectAndCallEmergencyNumber();
                      if (mounted) setState(() => _emergencyNumber = info.number);
                    } finally {
                      if (mounted) setState(() => _isLocatingEmergency = false);
                    }
                  }
                : null,
            onShareStatus: () async {
              await SharePlus.instance.share(
                ShareParams(text: 'I am using The Daily Protocol. Protocol: ${protocol.title}. I may need assistance.'),
              );
            },
          ),

          const SizedBox(height: 12),

          // Vault Export — free users get first 4 steps with images,
          // premium users get full PDF with all steps and all images.
          _VaultExportCard(
            isPremium: tier == SubscriptionTier.premium,
            exporting: _isExporting,
            onExport: () async {
              setState(() => _isExporting = true);
              try {
                await ref.read(reportExportServiceProvider).exportProtocolReport(
                  protocol: protocol,
                  progress: progress,
                  isPremium: tier == SubscriptionTier.premium,
                );
              } finally {
                if (mounted) setState(() => _isExporting = false);
              }
            },
          ),

          const SizedBox(height: 12),

          // Safety Notes
          if (shown.safetyNotes.isNotEmpty) ...[
            _SafetyNotesSection(notes: shown.safetyNotes, sectorColor: sectorColor),
            const SizedBox(height: 14),
          ],

          // Completion panel
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutBack,
            child: allDone
                ? _CompletionPanel(
                    key: const ValueKey<String>('done-panel'),
                    progress: progress,
                    protocol: protocol,
                    isFavorite: isFavorite,
                    isPremium: tier == SubscriptionTier.premium,
                    exporting: _isExporting,
                    onToggleFavorite: () async => ref.read(favoritesProvider.notifier).toggle(protocol.id),
                    onReset: () async {
                      await _progressNotifier.resetChecklist();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Checklist reset. Ready for another run.')),
                        );
                      }
                    },
                    onScheduleSixMonths: () async {
                      await _progressNotifier.setRecurringResetDays(180);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('This protocol will auto-reset every 6 months.')),
                        );
                      }
                    },
                    onExportReport: () async {
                      setState(() => _isExporting = true);
                      try {
                        await ref.read(reportExportServiceProvider).exportProtocolReport(
                          protocol: protocol,
                          progress: progress,
                          isPremium: tier == SubscriptionTier.premium,
                        );
                      } finally {
                        if (mounted) setState(() => _isExporting = false);
                      }
                    },
                    onCopySummary: () async {
                      final summary = _buildSummary(protocol, progress);
                      await Clipboard.setData(ClipboardData(text: summary));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Summary copied to clipboard.')),
                        );
                      }
                    },
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 14),

          // Checklist heading
          Row(
            children: [
              Expanded(child: Text('Checklist', style: Theme.of(context).textTheme.titleMedium)),
              Text(
                '$checked / $total steps',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
              ),
            ],
          ),
          if (tier != SubscriptionTier.premium)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Text(
                'First ${AppConfig.freeStepSelectionLimit} steps are visible on the free plan.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
              ),
            ),
          const SizedBox(height: 8),

          ...List.generate(shown.steps.length, (index) {
            final isChecked = progress.checkedSteps.contains(index);
            final photos = progress.stepPhotoPaths[index] ?? const <String>[];
            final completedAt = progress.stepCompletedAtEpochMs[index];
            final lockedByVisibility = tier != SubscriptionTier.premium && index >= AppConfig.freeStepSelectionLimit;

            final checklistTile = Column(
              children: [
                CheckboxListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  value: isChecked,
                  onChanged: lockedByVisibility
                      ? (_) => showPaywallSheet(context, protocolTitle: protocol.title)
                      : (_) async => _progressNotifier.toggleStep(index),
                  title: Text(shown.steps[index], style: Theme.of(context).textTheme.bodyMedium),
                  subtitle: completedAt == null
                      ? null
                      : Text(
                          'Done at ${DateFormat.Hm().format(DateTime.fromMillisecondsSinceEpoch(completedAt))}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: sectorColor,
                  secondary: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Audio button — reads this step aloud
                      IconButton(
                        icon: Icon(
                          _speakingText == shown.steps[index]
                              ? Icons.stop_circle_rounded
                              : Icons.volume_up_outlined,
                          size: 20,
                          color: _speakingText == shown.steps[index] ? const Color(0xFF1D6FD8) : null,
                        ),
                        tooltip: _speakingText == shown.steps[index] ? 'Stop' : 'Read step aloud',
                        onPressed: lockedByVisibility
                            ? () => showPaywallSheet(context, protocolTitle: protocol.title)
                            : () => _toggleStepAudio(shown.steps[index]),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      // Camera button — attach photo evidence
                      IconButton(
                        icon: const Icon(Icons.camera_alt_outlined, size: 20),
                        tooltip: 'Attach photo',
                        onPressed: lockedByVisibility ? () => showPaywallSheet(context, protocolTitle: protocol.title) : () => _attachPhoto(index),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
                if (photos.isNotEmpty)
                  _StepPhotoStrip(photos: photos, onRemove: (path) => _progressNotifier.removeStepPhoto(index, path)),
              ],
            );

            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isChecked ? sectorColor.withValues(alpha: 0.06) : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isChecked
                      ? sectorColor.withValues(alpha: 0.3)
                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: lockedByVisibility
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            checklistTile,
                            Positioned.fill(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                                child: Container(color: Colors.black.withValues(alpha: 0.12)),
                              ),
                            ),
                            Positioned.fill(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => showPaywallSheet(context, protocolTitle: protocol.title),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(99),
                                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.lock_outline_rounded, size: 16),
                                          const SizedBox(width: 6),
                                          Text('🔒 ${shown.steps.length - AppConfig.freeStepSelectionLimit} more steps hidden — Subscribe to Premium', style: Theme.of(context).textTheme.labelLarge),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : checklistTile,
              ),
            );
          }),

          const SizedBox(height: 14),
          Text('Notes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            minLines: 4,
            maxLines: 8,
            onChanged: (value) => _progressNotifier.updateNotes(value),
            decoration: const InputDecoration(hintText: 'Write observations, reminders, or follow-up actions…'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _detectEmergencyNumber() async {
    setState(() => _isLocatingEmergency = true);
    try {
      final number = await ref.read(emergencyServiceProvider).detectEmergencyNumber();
      if (mounted) setState(() => _emergencyNumber = number);
    } finally {
      if (mounted) setState(() => _isLocatingEmergency = false);
    }
  }

  Future<void> _translateProtocol(String languageCode) async {
    setState(() => _isTranslating = true);
    final translator = ref.read(translationServiceProvider);
    final source = _baseProtocol;

    try {
      final futures = await Future.wait([
        translator.translateText(text: source.title, targetLanguageCode: languageCode),
        translator.translateText(text: source.description, targetLanguageCode: languageCode),
        ...source.safetyNotes.map((note) => translator.translateText(text: note, targetLanguageCode: languageCode)),
        ...source.steps.map((step) => translator.translateText(text: step, targetLanguageCode: languageCode)),
      ]);

      final title = futures[0];
      final description = futures[1];
      final safety = futures.sublist(2, 2 + source.safetyNotes.length);
      final steps = futures.sublist(2 + source.safetyNotes.length);

      if (!mounted) return;

      setState(() {
        _translatedLanguageCode = languageCode;
        _translated = _TranslatedProtocol(title: title, description: description, safetyNotes: safety, steps: steps);
      });
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Future<void> _attachPhoto(int index) async {
    final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image == null) return;
    await _progressNotifier.addStepPhoto(index, image.path);
  }

  bool _isEmergencyCategory(String category) => category.toLowerCase() == 'emergency';

  String _buildSummary(ProtocolModel protocol, ProtocolProgress progress) {
    final done = progress.checkedSteps.length;
    final total = protocol.steps.length;
    return [
      'Protocol Summary: ${protocol.title}',
      'Category: ${protocol.category}',
      'Progress: $done/$total steps completed',
      if (progress.notes.trim().isNotEmpty) 'Notes: ${progress.notes.trim()}',
      'Generated: ${DateFormat.yMd().add_jm().format(DateTime.now())}',
    ].join('\n');
  }

  void _showReminderSheet(BuildContext context, ProtocolModel protocol) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReminderSheet(
        protocol: protocol,
        reminderService: ref.read(reminderServiceProvider),
        onChanged: () => setState(() {}), // refresh bell icon
      ),
    );
  }
}

// ── Protocol Hero Card ────────────────────────────────────────────────────────

class _ProtocolHeroCard extends StatelessWidget {
  const _ProtocolHeroCard({
    required this.protocol,
    required this.shown,
    required this.ratio,
    required this.checked,
    required this.total,
    required this.sectorGradient,
    required this.sectorColor,
  });

  final ProtocolModel protocol;
  final _TranslatedProtocol shown;
  final double ratio;
  final int checked;
  final int total;
  final List<Color> sectorGradient;
  final Color sectorColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            sectorGradient[0].withValues(alpha: 0.12),
            sectorGradient[1].withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sectorColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: sectorGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconForCategory(protocol.category), color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      protocol.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: sectorColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      '${protocol.estimatedMinutes} min  ·  $total steps',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(shown.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.55)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: ratio),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: sectorColor.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(sectorColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(ratio * 100).round()}%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: sectorColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

IconData _iconForCategory(String category) {
  switch (category.toLowerCase()) {
    case 'emergency':
      return Icons.warning_amber_rounded;
    case 'auto':
      return Icons.directions_car_filled_rounded;
    case 'home':
      return Icons.home_repair_service_rounded;
    case 'legal':
      return Icons.gavel_rounded;
    case 'travel':
      return Icons.flight_takeoff_rounded;
    default:
      return Icons.checklist_rounded;
  }
}

// ── Sector Help Card ──────────────────────────────────────────────────────────

class _SectorHelpCard extends ConsumerWidget {
  const _SectorHelpCard({
    required this.protocol,
    required this.emergencyNumber,
    required this.loading,
    this.onCall,
    required this.onShareStatus,
  });

  final ProtocolModel protocol;
  final String emergencyNumber;
  final bool loading;
  final Future<void> Function()? onCall;
  final Future<void> Function() onShareStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(emergencyServiceProvider);
    final sectorColor = SectorColors.forSector(protocol.category);
    final nearbyOptions = service.helpOptionsForSector(protocol.category);
    final isEmergency = protocol.category.toLowerCase() == 'emergency';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isEmergency
            ? (isDark ? const Color(0xFF2A0A0A) : const Color(0xFFFFF0F0))
            : (isDark ? const Color(0xFF0D1825) : const Color(0xFFF0F6FF)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isEmergency ? const Color(0xFFE63946).withValues(alpha: 0.4) : sectorColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isEmergency ? Icons.emergency_share_rounded : Icons.place_rounded,
                color: sectorColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isEmergency ? 'Emergency Tools' : 'Nearby Help for ${protocol.category}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: sectorColor),
                ),
              ),
              if (loading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          if (isEmergency) ...[
            const SizedBox(height: 6),
            Text(
              'Auto-detected emergency number: $emergencyNumber',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onCall != null)
                FilledButton.icon(
                  onPressed: onCall,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE63946),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.call_rounded, size: 16),
                  label: Text('Call $emergencyNumber'),
                ),
              for (final option in nearbyOptions.take(3))
                OutlinedButton.icon(
                  onPressed: () => service.openNearbyHelpOption(option),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: sectorColor,
                    side: BorderSide(color: sectorColor.withValues(alpha: 0.4)),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(_chipIconForOption(option.icon), size: 14),
                  label: Text(option.label, style: const TextStyle(fontSize: 12)),
                ),
              OutlinedButton.icon(
                onPressed: onShareStatus,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.share_location_outlined, size: 14),
                label: const Text('Share Status', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

IconData _chipIconForOption(String iconName) {
  switch (iconName) {
    case 'local_hospital':
      return Icons.local_hospital_outlined;
    case 'local_fire_department':
      return Icons.local_fire_department_outlined;
    case 'local_police':
      return Icons.local_police_outlined;
    case 'local_pharmacy':
      return Icons.local_pharmacy_outlined;
    case 'car_repair':
      return Icons.car_repair_outlined;
    case 'tire_repair':
      return Icons.tire_repair_outlined;
    case 'local_gas_station':
      return Icons.local_gas_station_outlined;
    case 'local_shipping':
      return Icons.local_shipping_outlined;
    case 'directions_car':
      return Icons.directions_car_outlined;
    case 'plumbing':
      return Icons.plumbing_outlined;
    case 'electrical_services':
      return Icons.electrical_services_outlined;
    case 'hardware':
      return Icons.hardware_outlined;
    case 'pest_control':
      return Icons.pest_control_outlined;
    case 'gavel':
      return Icons.gavel_outlined;
    case 'account_balance':
      return Icons.account_balance_outlined;
    case 'balance':
      return Icons.balance_outlined;
    case 'flag':
      return Icons.flag_outlined;
    case 'flight':
      return Icons.flight_outlined;
    case 'currency_exchange':
      return Icons.currency_exchange_outlined;
    default:
      return Icons.location_on_outlined;
  }
}

// ── Safety Notes Section ──────────────────────────────────────────────────────

class _SafetyNotesSection extends StatelessWidget {
  const _SafetyNotesSection({required this.notes, required this.sectorColor});

  final List<String> notes;
  final Color sectorColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: sectorColor.withValues(alpha: isDark ? 0.07 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sectorColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, color: sectorColor, size: 16),
              const SizedBox(width: 6),
              Text('Safety Notes', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: sectorColor)),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < notes.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  decoration: BoxDecoration(color: sectorColor, shape: BoxShape.circle),
                ),
                Expanded(
                  child: Text(notes[i], style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.55)),
                ),
              ],
            ),
            if (i < notes.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

// ── Vault Export Card ─────────────────────────────────────────────────────────

class _VaultExportCard extends StatelessWidget {
  const _VaultExportCard({required this.isPremium, required this.exporting, required this.onExport});

  final bool isPremium;
  final bool exporting;
  final Future<void> Function() onExport;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.picture_as_pdf_outlined,
                color: Theme.of(context).colorScheme.tertiary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Export PDF Report', style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    isPremium
                        ? 'Full PDF — all steps, all photos, timestamps & notes.'
                        : 'Free: first 4 steps with photos included. Upgrade for full PDF.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: exporting ? null : onExport,
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: isPremium ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
                foregroundColor: isPremium ? null : Theme.of(context).colorScheme.onSurface,
              ),
              child: exporting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.download_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Completion Panel ──────────────────────────────────────────────────────────

class _CompletionPanel extends StatelessWidget {
  const _CompletionPanel({
    super.key,
    required this.progress,
    required this.protocol,
    required this.isFavorite,
    required this.isPremium,
    required this.exporting,
    required this.onToggleFavorite,
    required this.onReset,
    required this.onScheduleSixMonths,
    required this.onExportReport,
    required this.onCopySummary,
  });

  final ProtocolProgress progress;
  final ProtocolModel protocol;
  final bool isFavorite;
  final bool isPremium;
  final bool exporting;
  final Future<void> Function() onToggleFavorite;
  final Future<void> Function() onReset;
  final Future<void> Function() onScheduleSixMonths;
  final Future<void> Function() onExportReport;
  final Future<void> Function() onCopySummary;

  @override
  Widget build(BuildContext context) {
    final category = protocol.category.toLowerCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A5C3A), Color(0xFF2D9E6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text('Protocol Completed!', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'You completed all ${protocol.steps.length} steps.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onReset,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1A5C3A),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.restart_alt_rounded, size: 16),
                label: const Text('Run Again'),
              ),
              OutlinedButton.icon(
                onPressed: onToggleFavorite,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(isFavorite ? Icons.bookmark_rounded : Icons.bookmark_add_outlined, size: 16),
                label: Text(isFavorite ? 'Favorited' : 'Save'),
              ),
              OutlinedButton.icon(
                onPressed: exporting ? null : onExportReport,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: exporting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.picture_as_pdf_outlined, size: 16),
                label: Text(isPremium ? 'Export PDF' : 'Export PDF (Free)'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (category == 'home')
            TextButton.icon(
              onPressed: onScheduleSixMonths,
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              icon: const Icon(Icons.alarm_add_outlined, size: 16),
              label: const Text('Schedule 6-month reset', style: TextStyle(fontSize: 13)),
            ),
          if (category == 'legal')
            TextButton.icon(
              onPressed: onCopySummary,
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              icon: const Icon(Icons.copy_all_outlined, size: 16),
              label: const Text('Copy summary for records', style: TextStyle(fontSize: 13)),
            ),
          if (category == 'travel')
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Save this protocol to reuse on your next trip.', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          if (category == 'emergency')
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Use the Nearby Help actions above to find assistance.', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

// ── Step Photo Strip ──────────────────────────────────────────────────────────

class _StepPhotoStrip extends StatelessWidget {
  const _StepPhotoStrip({required this.photos, required this.onRemove});

  final List<String> photos;
  final Future<void> Function(String path) onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final path = photos[index];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(path),
                  width: 90,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 90,
                    height: 72,
                    color: Colors.black12,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
              Positioned(
                right: 2,
                top: 2,
                child: InkWell(
                  onTap: () => onRemove(path),
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Model helpers ─────────────────────────────────────────────────────────────

class _TranslatedProtocol {
  const _TranslatedProtocol({
    required this.title,
    required this.description,
    required this.safetyNotes,
    required this.steps,
  });

  final String title;
  final String description;
  final List<String> safetyNotes;
  final List<String> steps;

  factory _TranslatedProtocol.fromBase(ProtocolModel model) {
    return _TranslatedProtocol(
      title: model.title,
      description: model.description,
      safetyNotes: model.safetyNotes,
      steps: model.steps,
    );
  }
}

// ── Reminder Sheet ────────────────────────────────────────────────────────────

class _ReminderSheet extends StatefulWidget {
  const _ReminderSheet({
    required this.protocol,
    required this.reminderService,
    required this.onChanged,
  });

  final ProtocolModel protocol;
  final ReminderService reminderService;
  final VoidCallback onChanged;

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _saving = false;

  DateTime? get _existing => widget.reminderService.reminderFor(widget.protocol.id);

  @override
  void initState() {
    super.initState();
    final existing = _existing;
    if (existing != null && existing.isAfter(DateTime.now())) {
      _selectedDate = existing;
      _selectedTime = TimeOfDay.fromDateTime(existing);
    } else {
      // Default: tomorrow at 09:00
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      _selectedDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
      _selectedTime = const TimeOfDay(hour: 9, minute: 0);
    }
  }

  DateTime get _combined => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? _selectedDate : now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    final scheduled = _combined;
    if (!scheduled.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a time in the future.')),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await widget.reminderService.scheduleReminder(
      protocolId: widget.protocol.id,
      protocolTitle: widget.protocol.title,
      category: widget.protocol.category,
      scheduledAt: scheduled,
    );
    if (mounted) {
      setState(() => _saving = false);
      widget.onChanged();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Reminder set for ${_formatDateTime(scheduled)}'
                : 'Could not schedule reminder. Check notification permissions.',
          ),
        ),
      );
    }
  }

  Future<void> _cancel() async {
    await widget.reminderService.cancelReminder(widget.protocol.id);
    if (mounted) {
      widget.onChanged();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder cancelled.')),
      );
    }
  }

  String _formatDateTime(DateTime dt) {
    final date = '${_monthName(dt.month)} ${dt.day}, ${dt.year}';
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$date at $h:$m $period';
  }

  String _monthName(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectorColor = SectorColors.forSector(widget.protocol.category);
    final hasExisting = _existing != null && _existing!.isAfter(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1825) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: sectorColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.notifications_rounded, color: sectorColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Set Reminder', style: Theme.of(context).textTheme.titleLarge),
                    Text(
                      widget.protocol.title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (hasExisting) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE9621A).withValues(alpha: isDark ? 0.12 : 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE9621A).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.alarm_rounded, color: Color(0xFFE9621A), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Active reminder: ${_formatDateTime(_existing!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFE9621A),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 22),
          Text('Schedule for', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),

          // Date + Time pickers
          Row(
            children: [
              Expanded(
                child: _PickerTile(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: '${_monthName(_selectedDate.month)} ${_selectedDate.day}, ${_selectedDate.year}',
                  onTap: _pickDate,
                  color: sectorColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickerTile(
                  icon: Icons.access_time_rounded,
                  label: 'Time',
                  value: _selectedTime.format(context),
                  onTap: _pickTime,
                  color: sectorColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              if (hasExisting) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _cancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.notifications_off_outlined, size: 18),
                    label: const Text('Cancel Reminder'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: hasExisting ? 1 : 2,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: sectorColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.alarm_add_rounded, size: 18),
                  label: Text(hasExisting ? 'Update' : 'Set Reminder'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.1 : 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 5),
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
