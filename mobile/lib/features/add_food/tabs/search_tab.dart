import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/formatters.dart';
import '../../../shared/widgets/food_thumb.dart';
import '../add_food_repository.dart';

class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key, required this.onSelect});

  final ValueChanged<FoodItem> onSelect;

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<FoodItem> _results = const [];
  bool _loading = false;
  String? _error;
  String _lastQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _search(value.trim()),
    );
  }

  Future<void> _search(String q) async {
    if (q.length < 2) {
      setState(() => _results = const []);
      return;
    }
    _lastQuery = q;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ref.read(addFoodRepositoryProvider).search(q);
      if (mounted && q == _lastQuery) setState(() => _results = r);
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted && q == _lastQuery) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            onSubmitted: (v) => _search(v.trim()),
            decoration: InputDecoration(
              hintText: 'Yemek ara (ör. mercimek çorbası)',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_error != null) {
      return _Message(icon: Icons.cloud_off_rounded, text: _error!);
    }
    if (_controller.text.trim().length < 2) {
      return const _Message(
        icon: Icons.restaurant_menu_rounded,
        text: 'Eklemek istediğin yemeğin adını yaz.',
      );
    }
    if (!_loading && _results.isEmpty) {
      return const _Message(
        icon: Icons.search_off_rounded,
        text: 'Sonuç bulunamadı. Fotoğraf (AI) sekmesiyle de ekleyebilirsin.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final f = _results[i];
        return Material(
          color: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card - 4),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card - 4),
            ),
            onTap: () => widget.onSelect(f),
            contentPadding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
            leading: FoodThumb(name: f.name, imageUrl: f.imageUrl, size: 52),
            title: Text(
              f.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${f.brand != null ? '${f.brand} • ' : ''}${formatNumber(f.kcalFor(f.defaultPortionG))} kcal • ${f.defaultPortionG} g',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            trailing: const Icon(
              Icons.add_circle_rounded,
              color: AppColors.primary,
            ),
          ),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}
