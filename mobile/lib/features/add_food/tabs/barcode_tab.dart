import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../add_food_repository.dart';

class BarcodeTab extends ConsumerStatefulWidget {
  const BarcodeTab({super.key, required this.onFound});

  final ValueChanged<FoodItem> onFound;

  @override
  ConsumerState<BarcodeTab> createState() => _BarcodeTabState();
}

class _BarcodeTabState extends ConsumerState<BarcodeTab> {
  final _scanner = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (_busy || code == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    await _scanner.stop();
    try {
      final food = await ref.read(addFoodRepositoryProvider).barcode(code);
      if (!mounted) return;
      if (food == null) {
        setState(
          () => _message =
              'Bu ürün ($code) bulunamadı. Arama veya fotoğraf ile ekleyebilirsin.',
        );
      } else {
        widget.onFound(food);
      }
    } catch (e) {
      if (mounted) setState(() => _message = apiErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        await _scanner.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _scanner,
                    onDetect: _onDetect,
                    errorBuilder: (_, error) => const ColoredBox(
                      color: AppColors.surfaceMuted,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Kameraya erişilemedi. Ayarlardan kamera iznini açabilirsin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 240,
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (_busy)
                    const ColoredBox(
                      color: Colors.black38,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _message ?? 'Ürünün barkodunu çerçevenin içine getir.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _message != null
                  ? AppColors.danger
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
