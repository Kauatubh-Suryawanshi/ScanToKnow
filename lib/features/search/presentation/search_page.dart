// search_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/search_repository.dart';
import '../domain/search_item.dart';
import 'widgets/search_result_tile.dart';
import 'product_page.dart';
import '../../variants/presentation/variant_detail_page.dart';
import '../../../core/app_theme.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  List<ProductSuggestion> _suggestions = [];
  List<VariantCard> _results = [];

  bool _loadingSuggestions = false;
  bool _searching = false;
  String _query = '';
  late AnimationController _resultsAnimController;
  late Animation<double> _resultsFade;

  @override
  void initState() {
    super.initState();

    _resultsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _resultsFade = CurvedAnimation(
      parent: _resultsAnimController,
      curve: Curves.easeOut,
    );

    _focusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _resultsAnimController.dispose();
    super.dispose();
  }

  // ── AUTOCOMPLETE ──────────────────────────────────────────────────────────
  void _onTextChanged(String val) {
    _debounce?.cancel();
    final query = val.trim();
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _results = [];
        _query = '';
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _loadingSuggestions = true);
      try {
        final s = await SearchRepository.autocomplete(query);
        if (!mounted) return;
        setState(() {
          _suggestions = s;
          _loadingSuggestions = false;
        });
      } catch (_) {
        if (mounted) setState(() => _loadingSuggestions = false);
      }
    });
  }

  // ── SEARCH ────────────────────────────────────────────────────────────────
  Future<void> _doSearch(String q) async {
    final query = q.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    if (_suggestions.length == 1) {
      _onSuggestionTap(_suggestions.first);
      return;
    }
    setState(() {
      _searching = true;
      _suggestions = [];
      _query = query;
    });
    final res = await SearchRepository.searchByQuery(query);
    if (!mounted) return;
    setState(() {
      _results = res;
      _searching = false;
    });
    _resultsAnimController.forward(from: 0);
  }

  // ── SUGGESTION TAP ───────────────────────────────────────────────────────
  void _onSuggestionTap(ProductSuggestion s) {
    FocusScope.of(context).unfocus();
    _controller.text = s.label;
    setState(() {
      _suggestions = [];
      _query = s.label;
    });
    Navigator.push(
      context,
      _smoothRoute(ProductPage(productId: s.id, productLabel: s.label)),
    );
  }

  void _openVariant(VariantCard v) {
    Navigator.push(context, _smoothRoute(VariantDetailPage(variantId: v.id)));
  }

  void _clear() {
    _controller.clear();
    setState(() {
      _suggestions = [];
      _results = [];
      _query = '';
    });
  }

  PageRouteBuilder _smoothRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, anim, __) => page,
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 280),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            _buildHeader(),
            if (_loadingSuggestions) _buildProgressBar(),
            if (_suggestions.isNotEmpty) _buildSuggestions(),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(
          bottom: BorderSide(color: AppTheme.cardBorder, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Eyebrow
              Text('SEARCH', style: AppTheme.eyebrow),
              const SizedBox(height: 10),
              // Search field
              _ThemedSearchField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onTextChanged,
                onSubmitted: _doSearch,
                onClear: _clear,
                hasText: _controller.text.isNotEmpty,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      minHeight: 2,
      color: AppTheme.accent,
      backgroundColor: AppTheme.cardBorder,
    );
  }

  // ── SUGGESTIONS DROPDOWN ──────────────────────────────────────────────────
  Widget _buildSuggestions() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: _suggestions.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: AppTheme.cardBorder,
            indent: 48,
            endIndent: 16,
          ),
          itemBuilder: (_, i) {
            final s = _suggestions[i];
            return _SuggestionTile(
              suggestion: s,
              onTap: () => _onSuggestionTap(s),
            );
          },
        ),
      ),
    );
  }

  // ── RESULTS ───────────────────────────────────────────────────────────────
  Widget _buildResults() {
    if (_searching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.accent,
                backgroundColor: AppTheme.cardBorder,
              ),
            ),
            const SizedBox(height: 14),
            Text('Searching…', style: AppTheme.body.copyWith(fontSize: 13)),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _resultsFade,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _results.length,
        itemBuilder: (_, i) {
          final v = _results[i];
          return _AnimatedResultTile(
            index: i,
            child: _ResultCardWrapper(item: v, onTap: () => _openVariant(v)),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_query.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decorative icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.cardBorder, width: 1.5),
              ),
              child: Icon(
                Icons.search_rounded,
                color: AppTheme.accent.withValues(alpha: 0.6),
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Search products',
              style: AppTheme.label.copyWith(
                fontSize: 17,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type a product name, brand, or\nbarcode to get started.',
              style: AppTheme.body.copyWith(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Icon(
              Icons.search_off_rounded,
              color: AppTheme.textSecondary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No results',
            style: AppTheme.label.copyWith(
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nothing matched "$_query"',
            style: AppTheme.body.copyWith(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Themed search field ───────────────────────────────────────────────────────
class _ThemedSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final bool hasText;

  const _ThemedSearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.hasText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focusNode.hasFocus
              ? AppTheme.accent.withValues(alpha: 0.6)
              : AppTheme.cardBorder,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(
            Icons.search_rounded,
            color: AppTheme.accent.withValues(alpha: 0.7),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: AppTheme.label.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search products…',
                hintStyle: AppTheme.body.copyWith(
                  fontSize: 14,
                  color: AppTheme.textSecondary.withValues(alpha: 0.6),
                ),
              ),
              textInputAction: TextInputAction.search,
              cursorColor: AppTheme.accent,
            ),
          ),
          if (hasText)
            GestureDetector(
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 14),
        ],
      ),
    );
  }
}

// ── Suggestion tile ───────────────────────────────────────────────────────────
class _SuggestionTile extends StatefulWidget {
  final ProductSuggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionTile({required this.suggestion, required this.onTap});

  @override
  State<_SuggestionTile> createState() => _SuggestionTileState();
}

class _SuggestionTileState extends State<_SuggestionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _pressed
            ? AppTheme.accent.withValues(alpha: 0.08)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 18,
              color: AppTheme.accent.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.suggestion.label,
                    style: AppTheme.label.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.suggestion.brand != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.suggestion.brand!,
                      style: AppTheme.body.copyWith(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.north_west_rounded,
              size: 14,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Staggered animation wrapper ───────────────────────────────────────────────
class _AnimatedResultTile extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedResultTile({required this.index, required this.child});

  @override
  State<_AnimatedResultTile> createState() => _AnimatedResultTileState();
}

class _AnimatedResultTileState extends State<_AnimatedResultTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ── Result card wrapper ───────────────────────────────────────────────────────
class _ResultCardWrapper extends StatefulWidget {
  final VariantCard item;
  final VoidCallback onTap;

  const _ResultCardWrapper({required this.item, required this.onTap});

  @override
  State<_ResultCardWrapper> createState() => _ResultCardWrapperState();
}

class _ResultCardWrapperState extends State<_ResultCardWrapper> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          transform: Matrix4.diagonal3Values(
            _pressed ? 0.976 : 1.0,
            _pressed ? 0.976 : 1.0,
            _pressed ? 0.976 : 1.0,
          ),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: _pressed
                ? AppTheme.cardBorder.withValues(alpha: 0.5)
                : AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _pressed
                  ? AppTheme.accent.withValues(alpha: 0.4)
                  : AppTheme.cardBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 12,
                  bottom: 12,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 110),
                    width: 3,
                    decoration: BoxDecoration(
                      color: _pressed
                          ? AppTheme.accent
                          : AppTheme.accent.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: SearchResultTile(
                    item: widget.item,
                    onTap: widget.onTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
