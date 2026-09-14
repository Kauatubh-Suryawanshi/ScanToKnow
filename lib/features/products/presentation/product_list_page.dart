// lib/features/products/presentation/product_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../variants/presentation/variant_detail_page.dart';

// ── Model — unchanged ─────────────────────────────────────────────────────────

class ProductItem {
  final String id;
  final String title;
  final String? brand;
  final String? thumbnail;
  final int? novaGroup;
  final String? nutriScore;

  ProductItem({
    required this.id,
    required this.title,
    this.brand,
    this.thumbnail,
    this.novaGroup,
    this.nutriScore,
  });

  factory ProductItem.fromMap(Map m) {
    return ProductItem(
      id: (m['_id'] ?? m['id'] ?? '').toString(),
      title: (m['title'] ?? m['product_name'] ?? '').toString(),
      brand: (m['brand'] is Map)
          ? (m['brand']['name']?.toString())
          : (m['brand']?.toString()),
      thumbnail: (m['images'] is Map)
          ? (m['images']['front'] ?? m['images']['thumbnail'])?.toString()
          : null,
      novaGroup: m['nova_group'] is int
          ? m['nova_group'] as int
          : int.tryParse(m['nova_group']?.toString() ?? ''),
      nutriScore: m['nutri_score']?.toString(),
    );
  }
}

// ── Page ──────────────────────────────────────────────────────────────────────

class ProductListPage extends StatefulWidget {
  final String subSlug;
  final String title;

  const ProductListPage({
    super.key,
    required this.subSlug,
    required this.title,
  });

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  int _page = 1;
  final int _limit = 24;
  bool _isLoading = false;
  bool _hasMore = true;
  final List<ProductItem> _items = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _fetchPage();
  }

  // ── Fetch — identical to original ──────────────────────────────────
  Future<void> _fetchPage() async {
    if (!_hasMore || _isLoading) return;
    setState(() => _isLoading = true);

    try {
      final resp = await ApiService.get(
        '/v1/categories/${widget.subSlug}/products?page=$_page&limit=$_limit',
      );

      if (resp is Map && resp.containsKey('products')) {
        final List raw = resp['products'];
        final newItems =
        raw.map((m) => ProductItem.fromMap(m as Map)).toList();
        final total =
            int.tryParse(resp['total']?.toString() ?? '0') ?? 0;
        setState(() {
          _items.addAll(newItems);
          _page++;
          _hasMore = _items.length < total;
        });
      } else {
        throw Exception('Unexpected products response');
      }
    } catch (e) {
      // ignore: avoid_print
      print('ProductListPage error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load products',
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF162320),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Navigation — identical to original ─────────────────────────────
  void _openVariant(ProductItem p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VariantDetailPage(variantId: p.id),
      ),
    );
  }

  // ── NutriScore color ────────────────────────────────────────────────
  Color _nutriColor(String score) {
    switch (score.toLowerCase()) {
      case 'a': return const Color(0xFF1DB890);
      case 'b': return const Color(0xFF7AB83A);
      case 'c': return const Color(0xFFF5C518);
      case 'd': return const Color(0xFFE67E22);
      case 'e': return const Color(0xFFE74C3C);
      default:  return const Color(0xFF5A7A72);
    }
  }

  // ── Card ────────────────────────────────────────────────────────────
  Widget _buildCard(ProductItem p) {
    return GestureDetector(
      onTap: () => _openVariant(p),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF162320),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF0D9E7A).withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFF0D9E7A).withValues(alpha: 0.07),
                  child: p.thumbnail != null
                      ? Image.network(
                    p.thumbnail!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.image_not_supported_rounded,
                      color: const Color(0xFF0D9E7A).withValues(alpha: 0.3),
                      size: 28,
                    ),
                  )
                      : Icon(
                    Icons.fastfood_rounded,
                    color: const Color(0xFF0D9E7A).withValues(alpha: 0.3),
                    size: 28,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 9),

            // Title
            Text(
              p.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE8F5F1),
                height: 1.3,
              ),
            ),

            // Brand
            if (p.brand != null && p.brand!.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                p.brand!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 10.5,
                  color: const Color(0xFF7AB5A6),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Badges row
            Row(
              children: [
                if (p.nutriScore != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _nutriColor(p.nutriScore!)
                          .withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _nutriColor(p.nutriScore!)
                            .withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      p.nutriScore!.toUpperCase(),
                      style: GoogleFonts.dmSans(
                        color: _nutriColor(p.nutriScore!),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                if (p.novaGroup != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9E7A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF0D9E7A).withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'NOVA ${p.novaGroup}',
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF7AB5A6),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cols = width > 700 ? 3 : 2;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1612),

      // ── Custom AppBar ───────────────────────────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0A1612),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            border: Border(
              bottom: BorderSide(color: Color(0xFF1F3530), width: 1),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: Color(0xFFE8F5F1),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRODUCTS',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4,
                            color: const Color(0xFF0D9E7A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.title,
                          style: GoogleFonts.dmSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE8F5F1),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Item count badge
                  if (_items.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9E7A).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: const Color(0xFF0D9E7A).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        '${_items.length}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0D9E7A),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),

      // ── Body ────────────────────────────────────────────────────────
      body: SafeArea(
        child: _items.isEmpty && _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF0D9E7A),
          ),
        )
            : GridView.builder(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          physics: const BouncingScrollPhysics(),
          itemCount: _items.length + (_hasMore ? 1 : 0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, idx) {
            if (idx < _items.length) {
              return _buildCard(_items[idx]);
            } else {
              if (!_isLoading) _fetchPage();
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: const Color(0xFF0D9E7A),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
