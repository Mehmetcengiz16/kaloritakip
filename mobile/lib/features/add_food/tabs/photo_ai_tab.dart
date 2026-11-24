import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/formatters.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../add_food_repository.dart';
import '../widgets/portion_sheet.dart';

typedef AddAnalyzed =
    Future<void> Function(int analysisId, List<AnalyzedItem> items);

class PhotoAiTab extends ConsumerStatefulWidget {
  const PhotoAiTab({super.key, required this.onAdd});

  final AddAnalyzed onAdd;

  @override
  ConsumerState<PhotoAiTab> createState() => _PhotoAiTabState();
}

class _PhotoAiTabState extends ConsumerState<PhotoAiTab> {
  final _picker = ImagePicker();

  Uint8List? _image;
  bool _analyzing = false;
  bool _saving = false;
  AiAnalysisResult? _result;
  List<AnalyzedItem> _items = const [];
  AiException? _error;
  AiQuota? _quota;

  @override
  void initState() {
    super.initState();
    ref
        .read(addFoodRepositoryProvider)
        .quota()
        .then((q) {
          if (mounted) setState(() => _quota = q);
        })
        .catchError((_) {});
  }

  Future<void> _pick(ImageSource source) async {
    // AI maliyetini belirleyen ana etken görsel boyutu: en uzun kenar 1024 px, %75 kalite.
    // image_picker bunu çekim/seçim sırasında yapar; sunucu da ayrıca 1024 px'e indirir.
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();

    setState(() {
      _image = bytes;
      _result = null;
      _items = const [];
      _error = null;
    });
    await _analyze(bytes);
  }

  Future<void> _analyze(Uint8List bytes) async {
    setState(() => _analyzing = true);
    try {
      final r = await ref.read(addFoodRepositoryProvider).analyzePhoto(bytes);
      if (!mounted) return;
      setState(() {
        _result = r;
        _items = r.items;
        _quota = r.quota;
      });
    } on AiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _editItem(int index) async {
    final item = _items[index];
    final grams = await showGramsSheet(
      context,
      title: item.name,
      grams: item.grams,
    );
    if (grams == null) return;
    setState(() => _items = [..._items]..[index] = item.withGrams(grams));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onAdd(_result!.id, _items);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiErrorMessage(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openPremium() async {
    final upgraded = await context.push<bool>('/premium?reason=quota');
    if (upgraded == true) {
      _reset();
      final q = await ref.read(addFoodRepositoryProvider).quota();
      if (mounted) setState(() => _quota = q);
    }
  }

  void _reset() => setState(() {
    _image = null;
    _result = null;
    _items = const [];
    _error = null;
  });

  @override
  Widget build(BuildContext context) {
    final total = _items.fold<int>(0, (s, i) => s + i.kcal);
    final canSave = _result != null && _result!.isFood && _items.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              _PhotoFrame(image: _image, analyzing: _analyzing),
              const SizedBox(height: 12),
              if (_image == null) ...[
                _PickButtons(
                  onPick: _pick,
                  enabled: _quota == null || _quota!.remaining > 0,
                ),
                const SizedBox(height: 12),
                if (_quota != null)
                  GestureDetector(
                    onTap: _quota!.isPremium ? null : _openPremium,
                    child: _QuotaLine(quota: _quota!),
                  ),
              ],
              if (_error != null)
                _ErrorCard(
                  error: _error!,
                  onRetry: _reset,
                  onPremium: _error!.isQuota ? _openPremium : null,
                ),
              if (_result != null && !_result!.isFood)
                _ErrorCard(
                  error: const AiException(
                    'Bu fotoğrafta yiyecek bulamadık. Tabağın net göründüğü bir fotoğraf dene.',
                  ),
                  onRetry: _reset,
                ),
              if (canSave)
                AiResultCard(
                  items: _items,
                  onEdit: _editItem,
                  onRemove: (i) =>
                      setState(() => _items = [..._items]..removeAt(i)),
                ),
            ],
          ),
        ),
        if (canSave)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                PrimaryButton(
                  label: 'Listeye Ekle (${formatNumber(total)} kcal)',
                  loading: _saving,
                  onPressed: _save,
                ),
                TextButton(
                  onPressed: _reset,
                  child: const Text('Yeni fotoğraf çek'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Fotoğraf alanı: köşelerde beyaz tarama çerçevesi (tasarımdaki gibi).
class _PhotoFrame extends StatelessWidget {
  const _PhotoFrame({required this.image, required this.analyzing});

  final Uint8List? image;
  final bool analyzing;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.55,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image != null)
              Image.memory(image!, fit: BoxFit.cover)
            else
              const ColoredBox(
                color: AppColors.surfaceMuted,
                child: Center(
                  child: Icon(
                    Icons.restaurant_rounded,
                    size: 56,
                    color: AppColors.border,
                  ),
                ),
              ),
            CustomPaint(
              painter: _CornerPainter(
                color: image != null ? Colors.white : AppColors.textMuted,
              ),
            ),
            if (analyzing)
              const ColoredBox(
                color: Colors.black45,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        'Yapay zekâ analiz ediyor...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 18.0, len = 30.0, r = 10.0;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final l = inset,
        t = inset,
        rt = size.width - inset,
        b = size.height - inset;

    void corner(double x, double y, double dx, double dy) {
      canvas.drawPath(
        Path()
          ..moveTo(x, y + dy * len)
          ..lineTo(x, y + dy * r)
          ..quadraticBezierTo(x, y, x + dx * r, y)
          ..lineTo(x + dx * len, y),
        p,
      );
    }

    corner(l, t, 1, 1);
    corner(rt, t, -1, 1);
    corner(l, b, 1, -1);
    corner(rt, b, -1, -1);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}

class _PickButtons extends StatelessWidget {
  const _PickButtons({required this.onPick, required this.enabled});

  final ValueChanged<ImageSource> onPick;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PrimaryButton(
          label: 'Fotoğraf Çek',
          icon: Icons.photo_camera_rounded,
          onPressed: enabled ? () => onPick(ImageSource.camera) : null,
        ),
        const SizedBox(height: 10),
        OutlineAppButton(
          label: 'Galeriden Seç',
          onPressed: enabled ? () => onPick(ImageSource.gallery) : null,
        ),
      ],
    );
  }
}

class _QuotaLine extends StatelessWidget {
  const _QuotaLine({required this.quota});

  final AiQuota quota;

  @override
  Widget build(BuildContext context) {
    final none = quota.remaining == 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: none ? const Color(0xFFFFF4E5) : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          Icon(
            none ? Icons.lock_clock_outlined : Icons.auto_awesome_rounded,
            size: 18,
            color: none ? AppColors.carb : AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              none
                  ? (quota.isPremium
                        ? 'Bugünkü AI analiz hakkın doldu. Yarın yenilenecek.'
                        : 'Bugünkü ücretsiz AI hakkın doldu. Premium ile her gün daha fazla analiz yapabilirsin.')
                  : 'Bugün ${quota.remaining}/${quota.limit} AI analiz hakkın kaldı.${quota.isPremium ? '' : ' Premium ile daha fazlası →'}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.error,
    required this.onRetry,
    this.onPremium,
  });

  final AiException error;
  final VoidCallback onRetry;
  final VoidCallback? onPremium;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            error.isQuota
                ? Icons.lock_clock_outlined
                : Icons.info_outline_rounded,
            color: error.isQuota ? AppColors.carb : AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            error.message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          if (onPremium != null) ...[
            const SizedBox(height: 8),
            PrimaryButton(
              label: "Premium'a Geç",
              icon: Icons.workspace_premium_rounded,
              onPressed: onPremium,
            ),
          ],
          TextButton(
            onPressed: onRetry,
            child: Text(error.isQuota ? 'Tamam' : 'Tekrar dene'),
          ),
        ],
      ),
    );
  }
}

/// "Yapay Zeka Analizi" kartı: bulunan yemekler, dokununca gramaj düzenleme.
class AiResultCard extends StatelessWidget {
  const AiResultCard({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onRemove,
  });

  final List<AnalyzedItem> items;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.primarySoft,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Yapay Zeka Analizi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'AI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++)
            InkWell(
              onTap: () => onEdit(i),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  items[i].name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (items[i].confidence < 0.6) ...[
                                const SizedBox(width: 6),
                                const Tooltip(
                                  message: 'Emin değiliz, porsiyonu kontrol et',
                                  child: Icon(
                                    Icons.help_outline_rounded,
                                    size: 14,
                                    color: AppColors.carb,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${formatNumber(items[i].kcal)} kcal • ${items[i].grams} g',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    IconButton(
                      onPressed: () => onRemove(i),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      tooltip: 'Kaldır',
                    ),
                  ],
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Text(
              'Değerler tahminidir. Porsiyonu düzeltmek için yemeğe dokun.',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
