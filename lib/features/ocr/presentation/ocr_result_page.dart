// // ocr_result_page.dart — v5.0
// //
// // FIXES:
// // 1. CRASH FIX: health_rating is now parsed safely via _safeInt()
// //    instead of direct `as int?` cast. JSON can return num, String,
// //    or null — all handled without crashing.
// // 2. Newly-added biscuit/namkeen ingredients with null health_rating
// //    now show "Unknown" gracefully instead of crashing.
// //
// // Backend shape expected:
// // {
// //   ingredients: [ { name, description, category, health_rating } ],
// //   additives:   [ { code, name, description, category, health_rating } ],
// //   unresolved_terms: [ "string", ... ],
// //   raw_text: "string"
// // }
//
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// // ─────────────────────────────────────────────────────────────────────────────
// // SAFE INT PARSER — THE CORE FIX
// // JSON can deliver health_rating as:
// //   int (98), double (98.0), String ("98"), or null
// // Direct `as int?` crashes on double or String.
// // ─────────────────────────────────────────────────────────────────────────────
// int? _safeInt(dynamic value) {
//   if (value == null) return null;
//   if (value is int) return value;
//   if (value is double) return value.toInt();
//   if (value is String) {
//     final trimmed = value.trim();
//     if (trimmed.isEmpty) return null;
//     return int.tryParse(trimmed) ?? double.tryParse(trimmed)?.toInt();
//   }
//   return null;
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // DESIGN TOKENS
// // ─────────────────────────────────────────────────────────────────────────────
// class _T {
//   // Surfaces
//   static const Color bg     = Color(0xFF0F1E1B);
//   static const Color card   = Color(0xFF162320);
//   static const Color border = Color(0xFF1F3530);
//
//   // Brand
//   static const Color accent   = Color(0xFF0D9E7A);
//   static const Color accentLt = Color(0xFF1DB890);
//
//   // Text
//   static const Color textPri = Color(0xFFE8F5F1);
//   static const Color textSec = Color(0xFF7AB5A6);
//   static const Color textEye = Color(0xFF0D9E7A);
//
//   // Health palette — foreground
//   static const Color veryGood = Color(0xFF27AE60);
//   static const Color good     = Color(0xFF52BE80);
//   static const Color okay     = Color(0xFFF1C40F);
//   static const Color poor     = Color(0xFFE67E22);
//   static const Color veryPoor = Color(0xFFE74C3C);
//
//   // Health palette — background tints
//   static const Color veryGoodBg = Color(0xFF0A2318);
//   static const Color goodBg     = Color(0xFF0D2318);
//   static const Color okayBg     = Color(0xFF2A2000);
//   static const Color poorBg     = Color(0xFF2A1200);
//   static const Color veryPoorBg = Color(0xFF2A0808);
//
//   // ── Text styles ────────────────────────────────────────
//   static TextStyle eyebrow({Color? color}) => GoogleFonts.dmSans(
//       fontSize: 10, fontWeight: FontWeight.w600,
//       letterSpacing: 1.4, color: color ?? textEye);
//
//   static TextStyle heading({double fontSize = 22, Color? color}) =>
//       GoogleFonts.dmSans(
//           fontSize: fontSize, fontWeight: FontWeight.w700,
//           height: 1.2, color: color ?? textPri);
//
//   static TextStyle headingAccent({double fontSize = 26}) =>
//       GoogleFonts.dmSerifDisplay(
//           fontStyle: FontStyle.italic,
//           fontSize: fontSize, color: accentLt);
//
//   static TextStyle body({double fontSize = 13, Color? color}) =>
//       GoogleFonts.dmSans(
//           fontSize: fontSize, height: 1.6, color: color ?? textSec);
//
//   static TextStyle label({Color? color, double fontSize = 12}) =>
//       GoogleFonts.dmSans(
//           fontSize: fontSize, fontWeight: FontWeight.w600,
//           color: color ?? textPri);
//
//   static TextStyle mono({Color? color, double fontSize = 11}) =>
//       GoogleFonts.sourceCodePro(
//           fontSize: fontSize, fontWeight: FontWeight.w600,
//           color: color ?? textPri);
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // HEALTH RATING HELPERS
// // ─────────────────────────────────────────────────────────────────────────────
// Color _healthFg(int? rating) {
//   if (rating == null) return _T.textSec;
//   if (rating >= 85) return _T.veryGood;
//   if (rating >= 60) return _T.good;
//   if (rating >= 40) return _T.okay;
//   if (rating >= 20) return _T.poor;
//   return _T.veryPoor;
// }
//
// Color _healthBg(int? rating) {
//   if (rating == null) return _T.card;
//   if (rating >= 85) return _T.veryGoodBg;
//   if (rating >= 60) return _T.goodBg;
//   if (rating >= 40) return _T.okayBg;
//   if (rating >= 20) return _T.poorBg;
//   return _T.veryPoorBg;
// }
//
// IconData _healthIcon(int? rating) {
//   if (rating == null) return Icons.help_outline_rounded;
//   if (rating >= 60) return Icons.check_circle_outline_rounded;
//   if (rating >= 40) return Icons.warning_amber_rounded;
//   return Icons.cancel_outlined;
// }
//
// String _healthLabel(int? rating) {
//   if (rating == null) return 'Unknown';
//   if (rating >= 85) return 'Very Good';
//   if (rating >= 60) return 'Good';
//   if (rating >= 40) return 'Okay';
//   if (rating >= 20) return 'Poor';
//   return 'Very Poor';
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // PAGE
// // ─────────────────────────────────────────────────────────────────────────────
// class OCRResultPage extends StatelessWidget {
//   final Map<String, dynamic> data;
//   const OCRResultPage({super.key, required this.data});
//
//   @override
//   Widget build(BuildContext context) {
//     final ingredients     = (data['ingredients']      as List<dynamic>?) ?? [];
//     final additives       = (data['additives']        as List<dynamic>?) ?? [];
//     final unresolvedTerms = (data['unresolved_terms'] as List<dynamic>?) ?? [];
//
//     // ── Summary counts ──────────────────────────────────
//     int vg = 0, g = 0, ok = 0, po = 0, vp = 0;
//     for (final item in [...ingredients, ...additives]) {
//       // FIX: use _safeInt instead of direct cast
//       final r = _safeInt(item['health_rating']);
//       if (r == null) continue;
//       if (r >= 85)      vg++;
//       else if (r >= 60) g++;
//       else if (r >= 40) ok++;
//       else if (r >= 20) po++;
//       else              vp++;
//     }
//
//     final total = ingredients.length + additives.length;
//
//     return Scaffold(
//       backgroundColor: _T.bg,
//       body: CustomScrollView(
//         physics: const BouncingScrollPhysics(),
//         slivers: [
//           _AppBar(context: context),
//           SliverPadding(
//             padding: const EdgeInsets.fromLTRB(16, 0, 16, 60),
//             sliver: SliverList(
//               delegate: SliverChildListDelegate([
//
//                 // ── Summary banner ──────────────────────
//                 _SummaryBanner(
//                   total: total,
//                   veryGood: vg, good: g, okay: ok,
//                   poor: po, veryPoor: vp,
//                   additiveCount: additives.length,
//                 ),
//                 const SizedBox(height: 24),
//
//                 // ── Ingredients ─────────────────────────
//                 if (ingredients.isNotEmpty) ...[
//                   _SectionHeader(
//                     eyebrow: 'INGREDIENTS',
//                     title: "What's inside",
//                     count: ingredients.length,
//                   ),
//                   const SizedBox(height: 12),
//                   ...ingredients.asMap().entries.map((e) =>
//                       _IngredientTile(
//                         item:  e.value as Map<String, dynamic>,
//                         index: e.key,
//                       ),
//                   ),
//                   const SizedBox(height: 28),
//                 ],
//
//                 // ── Additives ───────────────────────────
//                 if (additives.isNotEmpty) ...[
//                   _SectionHeader(
//                     eyebrow: 'ADDITIVES',
//                     title: 'Chemical additives',
//                     count: additives.length,
//                   ),
//                   const SizedBox(height: 12),
//                   ...additives.asMap().entries.map((e) =>
//                       _AdditiveTile(
//                         item:  e.value as Map<String, dynamic>,
//                         index: e.key,
//                       ),
//                   ),
//                   const SizedBox(height: 28),
//                 ],
//
//                 // ── Nothing found ───────────────────────
//                 if (ingredients.isEmpty && additives.isEmpty)
//                   _EmptyState(),
//
//                 // ── Unresolved terms ────────────────────
//                 if (unresolvedTerms.isNotEmpty) ...[
//                   _SectionHeader(
//                     eyebrow: 'UNMATCHED',
//                     title: 'Not in database',
//                     count: unresolvedTerms.length,
//                   ),
//                   const SizedBox(height: 12),
//                   _UnresolvedCard(terms: unresolvedTerms),
//                 ],
//               ]),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // APP BAR
// // ─────────────────────────────────────────────────────────────────────────────
// class _AppBar extends StatelessWidget {
//   final BuildContext context;
//   const _AppBar({required this.context});
//
//   @override
//   Widget build(BuildContext ctx) {
//     return SliverAppBar(
//       expandedHeight: 160,
//       pinned: true,
//       backgroundColor: _T.bg,
//       surfaceTintColor: Colors.transparent,
//       leading: GestureDetector(
//         onTap: () => Navigator.pop(context),
//         child: Container(
//           margin: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: _T.card,
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(color: _T.border),
//           ),
//           child: const Icon(Icons.arrow_back_ios_new,
//               color: _T.textPri, size: 16),
//         ),
//       ),
//       flexibleSpace: FlexibleSpaceBar(
//         background: Stack(fit: StackFit.expand, children: [
//           Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [Color(0xFF0A2420), _T.bg],
//               ),
//             ),
//           ),
//           Positioned(
//             top: -30, right: -30,
//             child: Container(
//               width: 140, height: 140,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: _T.accent.withValues(alpha: 0.06),
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: 40, right: 20,
//             child: Container(
//               width: 60, height: 60,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: _T.accentLt.withValues(alpha: 0.04),
//               ),
//             ),
//           ),
//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   Text('SCAN RESULT', style: _T.eyebrow()),
//                   const SizedBox(height: 6),
//                   Row(children: [
//                     Text('Label ', style: _T.heading(fontSize: 24)),
//                     Text('Analysis', style: _T.headingAccent(fontSize: 26)),
//                   ]),
//                 ],
//               ),
//             ),
//           ),
//         ]),
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // SUMMARY BANNER
// // ─────────────────────────────────────────────────────────────────────────────
// class _SummaryBanner extends StatelessWidget {
//   final int total, veryGood, good, okay, poor, veryPoor, additiveCount;
//   const _SummaryBanner({
//     required this.total, required this.veryGood, required this.good,
//     required this.okay, required this.poor, required this.veryPoor,
//     required this.additiveCount,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final Color overallColor;
//     final String overallText;
//
//     if (veryPoor > 0) {
//       overallColor = _T.veryPoor;
//       overallText  = 'Concerning ingredients detected';
//     } else if (poor > 0) {
//       overallColor = _T.poor;
//       overallText  = 'Some ingredients to watch';
//     } else if (okay > 0) {
//       overallColor = _T.okay;
//       overallText  = 'Generally acceptable profile';
//     } else if (good > 0 || veryGood > 0) {
//       overallColor = _T.veryGood;
//       overallText  = 'Looks good overall';
//     } else {
//       overallColor = _T.textSec;
//       overallText  = 'Scan completed';
//     }
//
//     return Container(
//       decoration: BoxDecoration(
//         color: _T.card,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: overallColor.withValues(alpha: 0.25), width: 1.5),
//       ),
//       child: Column(children: [
//         Padding(
//           padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
//           child: Row(children: [
//             Container(
//               width: 10, height: 10,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle, color: overallColor,
//                 boxShadow: [
//                   BoxShadow(color: overallColor.withValues(alpha: 0.5), blurRadius: 8),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Text(overallText,
//                   style: _T.label(color: _T.textPri, fontSize: 13)),
//             ),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//               decoration: BoxDecoration(
//                 color: _T.bg,
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(color: _T.border),
//               ),
//               child: Row(mainAxisSize: MainAxisSize.min, children: [
//                 const Icon(Icons.science_outlined,
//                     color: _T.textSec, size: 12),
//                 const SizedBox(width: 4),
//                 Text('$additiveCount additives',
//                     style: _T.label(color: _T.textSec, fontSize: 11)),
//               ]),
//             ),
//           ]),
//         ),
//         Divider(height: 1, color: _T.border),
//         Padding(
//           padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
//           child: SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(children: [
//               Text('$total items  ',
//                   style: _T.label(color: _T.textSec, fontSize: 11)),
//               if (veryGood > 0) _MiniPill(count: veryGood, label: 'Very Good',
//                   color: _T.veryGood, bg: _T.veryGoodBg),
//               if (good > 0)     _MiniPill(count: good,     label: 'Good',
//                   color: _T.good,     bg: _T.goodBg),
//               if (okay > 0)     _MiniPill(count: okay,     label: 'Okay',
//                   color: _T.okay,     bg: _T.okayBg),
//               if (poor > 0)     _MiniPill(count: poor,     label: 'Poor',
//                   color: _T.poor,     bg: _T.poorBg),
//               if (veryPoor > 0) _MiniPill(count: veryPoor, label: 'Very Poor',
//                   color: _T.veryPoor, bg: _T.veryPoorBg),
//             ]),
//           ),
//         ),
//       ]),
//     );
//   }
// }
//
// class _MiniPill extends StatelessWidget {
//   final int count;
//   final String label;
//   final Color color, bg;
//   const _MiniPill({
//     required this.count, required this.label,
//     required this.color, required this.bg,
//   });
//
//   @override
//   Widget build(BuildContext context) => Container(
//     margin: const EdgeInsets.only(right: 6),
//     padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
//     decoration: BoxDecoration(
//       color: bg,
//       borderRadius: BorderRadius.circular(20),
//       border: Border.all(color: color.withValues(alpha: 0.35)),
//     ),
//     child: Row(mainAxisSize: MainAxisSize.min, children: [
//       Container(
//         width: 5, height: 5,
//         decoration: BoxDecoration(shape: BoxShape.circle, color: color),
//       ),
//       const SizedBox(width: 5),
//       Text('$count $label',
//           style: _T.label(color: color, fontSize: 10)),
//     ]),
//   );
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // SECTION HEADER
// // ─────────────────────────────────────────────────────────────────────────────
// class _SectionHeader extends StatelessWidget {
//   final String eyebrow, title;
//   final int? count;
//   const _SectionHeader({
//     required this.eyebrow, required this.title, this.count,
//   });
//
//   @override
//   Widget build(BuildContext context) => Row(
//     crossAxisAlignment: CrossAxisAlignment.end,
//     children: [
//       Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         Text(eyebrow, style: _T.eyebrow()),
//         const SizedBox(height: 3),
//         Text(title, style: _T.heading(fontSize: 18)),
//       ]),
//       const Spacer(),
//       if (count != null)
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//           decoration: BoxDecoration(
//             color: _T.card,
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: _T.border),
//           ),
//           child: Text('$count items',
//               style: _T.label(color: _T.textSec, fontSize: 11)),
//         ),
//     ],
//   );
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // INGREDIENT TILE
// // ─────────────────────────────────────────────────────────────────────────────
// class _IngredientTile extends StatelessWidget {
//   final Map<String, dynamic> item;
//   final int index;
//   const _IngredientTile({required this.item, required this.index});
//
//   @override
//   Widget build(BuildContext context) {
//     final name        = (item['name']        as String?) ?? '';
//     final description = (item['description'] as String?) ?? '';
//     final category    = (item['category']    as String?) ?? '';
//     // FIX: safe parse — never crash on String/double/null
//     final rating      = _safeInt(item['health_rating']);
//
//     final fgColor = _healthFg(rating);
//     final bgColor = _healthBg(rating);
//     final icon    = _healthIcon(rating);
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       decoration: BoxDecoration(
//         color: _T.card,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: _T.border),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         borderRadius: BorderRadius.circular(16),
//         child: Padding(
//           padding: const EdgeInsets.all(14),
//           child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             Container(
//               width: 38, height: 38,
//               decoration: BoxDecoration(
//                 color: bgColor,
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: fgColor.withValues(alpha: 0.3)),
//               ),
//               child: Icon(icon, color: fgColor, size: 18),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(name, style: _T.label(fontSize: 13)),
//                   if (category.isNotEmpty) ...[
//                     const SizedBox(height: 2),
//                     Text(
//                       category,
//                       style: _T.body(fontSize: 11)
//                           .copyWith(color: _T.accent.withValues(alpha: 0.75)),
//                     ),
//                   ],
//                   if (description.isNotEmpty) ...[
//                     const SizedBox(height: 4),
//                     Text(
//                       description,
//                       style: _T.body(fontSize: 12),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//             const SizedBox(width: 10),
//             _RatingBadge(rating: rating, color: fgColor, bg: bgColor),
//           ]),
//         ),
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // ADDITIVE TILE
// // ─────────────────────────────────────────────────────────────────────────────
// class _AdditiveTile extends StatelessWidget {
//   final Map<String, dynamic> item;
//   final int index;
//   const _AdditiveTile({required this.item, required this.index});
//
//   @override
//   Widget build(BuildContext context) {
//     final code        = (item['code']        as String?) ?? '';
//     final name        = (item['name']        as String?) ?? '';
//     final description = (item['description'] as String?) ?? '';
//     final category    = (item['category']    as String?) ?? '';
//     // FIX: safe parse
//     final rating      = _safeInt(item['health_rating']);
//
//     final fgColor = _healthFg(rating);
//     final bgColor = _healthBg(rating);
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       decoration: BoxDecoration(
//         color: _T.card,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: rating != null && rating < 40
//               ? fgColor.withValues(alpha: 0.25)
//               : _T.border,
//         ),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(14),
//         child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Container(
//             constraints: const BoxConstraints(minWidth: 46),
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
//             decoration: BoxDecoration(
//               color: bgColor,
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(color: fgColor.withValues(alpha: 0.3)),
//             ),
//             child: Text(
//               code.toUpperCase(),
//               textAlign: TextAlign.center,
//               style: _T.mono(color: fgColor, fontSize: 10),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(name, style: _T.label(fontSize: 13)),
//                 if (category.isNotEmpty) ...[
//                   const SizedBox(height: 2),
//                   Text(
//                     category,
//                     style: _T.body(fontSize: 11)
//                         .copyWith(color: _T.accent.withValues(alpha: 0.75)),
//                   ),
//                 ],
//                 if (description.isNotEmpty) ...[
//                   const SizedBox(height: 4),
//                   Text(
//                     description,
//                     style: _T.body(fontSize: 12),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           const SizedBox(width: 10),
//           _RatingBadge(rating: rating, color: fgColor, bg: bgColor),
//         ]),
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // SHARED RATING BADGE
// // ─────────────────────────────────────────────────────────────────────────────
// class _RatingBadge extends StatelessWidget {
//   final int? rating;
//   final Color color, bg;
//   const _RatingBadge({required this.rating, required this.color, required this.bg});
//
//   @override
//   Widget build(BuildContext context) => Column(
//     crossAxisAlignment: CrossAxisAlignment.end,
//     children: [
//       Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//         decoration: BoxDecoration(
//           color: bg,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: color.withValues(alpha: 0.4)),
//         ),
//         child: Text(
//           rating != null ? '$rating' : '?',
//           style: _T.label(color: color, fontSize: 12),
//         ),
//       ),
//       const SizedBox(height: 3),
//       Text(
//         _healthLabel(rating),
//         style: _T.body(fontSize: 9, color: color.withValues(alpha: 0.75)),
//       ),
//     ],
//   );
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // EMPTY STATE
// // ─────────────────────────────────────────────────────────────────────────────
// class _EmptyState extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) => Container(
//     margin: const EdgeInsets.symmetric(vertical: 32),
//     padding: const EdgeInsets.all(32),
//     decoration: BoxDecoration(
//       color: _T.card,
//       borderRadius: BorderRadius.circular(20),
//       border: Border.all(color: _T.border),
//     ),
//     child: Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(Icons.search_off_rounded,
//             color: _T.textSec.withValues(alpha: 0.4), size: 48),
//         const SizedBox(height: 16),
//         Text('No ingredients found',
//             style: _T.heading(fontSize: 16, color: _T.textSec)),
//         const SizedBox(height: 8),
//         Text(
//           'Make sure the ingredients label is clearly visible\nand well-lit before scanning.',
//           textAlign: TextAlign.center,
//           style: _T.body(fontSize: 12),
//         ),
//       ],
//     ),
//   );
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // UNRESOLVED TERMS CARD
// // ─────────────────────────────────────────────────────────────────────────────
// class _UnresolvedCard extends StatelessWidget {
//   final List<dynamic> terms;
//   const _UnresolvedCard({required this.terms});
//
//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.all(16),
//     decoration: BoxDecoration(
//       color: _T.card,
//       borderRadius: BorderRadius.circular(16),
//       border: Border.all(color: _T.border),
//     ),
//     child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Row(children: [
//         Icon(Icons.info_outline_rounded,
//             color: _T.textSec.withValues(alpha: 0.6), size: 14),
//         const SizedBox(width: 6),
//         Text(
//           'Found on label but not yet in our database.',
//           style: _T.body(fontSize: 12),
//         ),
//       ]),
//       const SizedBox(height: 12),
//       Wrap(
//         spacing: 6, runSpacing: 6,
//         children: terms.map((t) => Container(
//           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//           decoration: BoxDecoration(
//             color: _T.bg,
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: _T.border),
//           ),
//           child: Text(
//             t.toString(),
//             style: _T.label(color: _T.textSec, fontSize: 11),
//           ),
//         )).toList(),
//       ),
//     ]),
//   );
// }


// lib/features/ocr/presentation/ocr_result_page.dart — v6.0
//
// NEW IN v6:
// - Shows description, notes, category from DB
// - Health rating bar (visual progress)
// - Expandable tiles (tap to expand description/notes)
// - Staggered entrance animation per tile
// - Better summary banner with overall verdict
// - Unresolved terms shown only if non-empty

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Safe int parser ───────────────────────────────────────────────────────────
int? _safeInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? double.tryParse(v.trim())?.toInt();
  return null;
}

// ── Design tokens ─────────────────────────────────────────────────────────────
class _T {
  static const Color bg       = Color(0xFF0F1E1B);
  static const Color card     = Color(0xFF162320);
  static const Color border   = Color(0xFF1F3530);
  static const Color accent   = Color(0xFF0D9E7A);
  static const Color accentLt = Color(0xFF1DB890);
  static const Color textPri  = Color(0xFFE8F5F1);
  static const Color textSec  = Color(0xFF7AB5A6);
  static const Color textEye  = Color(0xFF0D9E7A);

  static const Color veryGood   = Color(0xFF27AE60);
  static const Color good       = Color(0xFF52BE80);
  static const Color okay       = Color(0xFFF1C40F);
  static const Color poor       = Color(0xFFE67E22);
  static const Color veryPoor   = Color(0xFFE74C3C);
  static const Color veryGoodBg = Color(0xFF0A2318);
  static const Color goodBg     = Color(0xFF0D2318);
  static const Color okayBg     = Color(0xFF2A2000);
  static const Color poorBg     = Color(0xFF2A1200);
  static const Color veryPoorBg = Color(0xFF2A0808);

  static TextStyle eyebrow({Color? color}) => GoogleFonts.dmSans(
      fontSize: 10, fontWeight: FontWeight.w600,
      letterSpacing: 1.4, color: color ?? textEye);
  static TextStyle heading({double size = 22, Color? color}) =>
      GoogleFonts.dmSans(
          fontSize: size, fontWeight: FontWeight.w700,
          height: 1.2, color: color ?? textPri);
  static TextStyle headingAccent({double size = 26}) =>
      GoogleFonts.dmSerifDisplay(
          fontStyle: FontStyle.italic, fontSize: size, color: accentLt);
  static TextStyle body({double size = 13, Color? color}) =>
      GoogleFonts.dmSans(fontSize: size, height: 1.6, color: color ?? textSec);
  static TextStyle label({Color? color, double size = 12}) =>
      GoogleFonts.dmSans(
          fontSize: size, fontWeight: FontWeight.w600, color: color ?? textPri);
  static TextStyle mono({Color? color, double size = 11}) =>
      GoogleFonts.sourceCodePro(
          fontSize: size, fontWeight: FontWeight.w600, color: color ?? textPri);
}

// ── Health helpers ────────────────────────────────────────────────────────────
Color _fg(int? r) {
  if (r == null) return _T.textSec;
  if (r >= 85) return _T.veryGood;
  if (r >= 60) return _T.good;
  if (r >= 40) return _T.okay;
  if (r >= 20) return _T.poor;
  return _T.veryPoor;
}

Color _bg(int? r) {
  if (r == null) return _T.card;
  if (r >= 85) return _T.veryGoodBg;
  if (r >= 60) return _T.goodBg;
  if (r >= 40) return _T.okayBg;
  if (r >= 20) return _T.poorBg;
  return _T.veryPoorBg;
}

IconData _icon(int? r) {
  if (r == null) return Icons.help_outline_rounded;
  if (r >= 60) return Icons.check_circle_outline_rounded;
  if (r >= 40) return Icons.warning_amber_rounded;
  return Icons.cancel_outlined;
}

String _ratingLabel(int? r) {
  if (r == null) return 'Unknown';
  if (r >= 85) return 'Very Good';
  if (r >= 60) return 'Good';
  if (r >= 40) return 'Okay';
  if (r >= 20) return 'Poor';
  return 'Very Poor';
}

// ── Page ──────────────────────────────────────────────────────────────────────
class OCRResultPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const OCRResultPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final ingredients     = (data['ingredients']      as List?) ?? [];
    final additives       = (data['additives']        as List?) ?? [];
    final unresolvedTerms = (data['unresolved_terms'] as List?) ?? [];

    int vg = 0, g = 0, ok = 0, po = 0, vp = 0;
    for (final item in [...ingredients, ...additives]) {
      final r = _safeInt(item['health_rating']);
      if (r == null) continue;
      if (r >= 85) {
        vg++;
      } else if (r >= 60) {
        g++;
      } else if (r >= 40) {
        ok++;
      } else if (r >= 20) {
        po++;
      } else {
        vp++;
      }
    }

    // Build the list of all widgets with stagger indices
    final items = <Widget>[];
    int staggerIndex = 0;

    // Summary banner
    items.add(_StaggerIn(
      index: staggerIndex++,
      child: _SummaryBanner(
        total: ingredients.length + additives.length,
        vg: vg, g: g, ok: ok, po: po, vp: vp,
        additives: additives.length,
      ),
    ));
    items.add(const SizedBox(height: 28));

    // Ingredients section
    if (ingredients.isNotEmpty) {
      items.add(_StaggerIn(
        index: staggerIndex++,
        child: _SectionHeader(
          eyebrow: 'INGREDIENTS',
          title: "What's inside",
          count: ingredients.length,
        ),
      ));
      items.add(const SizedBox(height: 10));
      for (final item in ingredients) {
        items.add(_StaggerIn(
          index: staggerIndex++,
          child: _IngredientCard(item: item as Map<String, dynamic>),
        ));
        items.add(const SizedBox(height: 8));
      }
      items.add(const SizedBox(height: 20));
    }

    // Additives section
    if (additives.isNotEmpty) {
      items.add(_StaggerIn(
        index: staggerIndex++,
        child: _SectionHeader(
          eyebrow: 'ADDITIVES',
          title: 'Chemical additives',
          count: additives.length,
        ),
      ));
      items.add(const SizedBox(height: 10));
      for (final item in additives) {
        items.add(_StaggerIn(
          index: staggerIndex++,
          child: _AdditiveCard(item: item as Map<String, dynamic>),
        ));
        items.add(const SizedBox(height: 8));
      }
      items.add(const SizedBox(height: 20));
    }

    // Empty state
    if (ingredients.isEmpty && additives.isEmpty) {
      items.add(_StaggerIn(
        index: staggerIndex++,
        child: const _EmptyState(),
      ));
    }

    // Unresolved
    if (unresolvedTerms.isNotEmpty) {
      items.add(_StaggerIn(
        index: staggerIndex++,
        child: _SectionHeader(
          eyebrow: 'UNMATCHED',
          title: 'Not in database',
          count: unresolvedTerms.length,
        ),
      ));
      items.add(const SizedBox(height: 10));
      items.add(_StaggerIn(
        index: staggerIndex++,
        child: _UnresolvedCard(terms: unresolvedTerms),
      ));
    }

    items.add(const SizedBox(height: 48));

    return Scaffold(
      backgroundColor: _T.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(items),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 155,
      pinned: true,
      backgroundColor: _T.bg,
      surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _T.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _T.border),
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              color: _T.textPri, size: 16),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(fit: StackFit.expand, children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0A2420), _T.bg],
              ),
            ),
          ),
          Positioned(
            top: -30, right: -30,
            child: Container(
              width: 150, height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _T.accent.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 44, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('SCAN RESULT', style: _T.eyebrow()),
                  const SizedBox(height: 5),
                  Row(children: [
                    Text('Label ', style: _T.heading(size: 24)),
                    Text('Analysis', style: _T.headingAccent(size: 26)),
                  ]),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Stagger-in animation wrapper ──────────────────────────────────────────────
class _StaggerIn extends StatefulWidget {
  final int index;
  final Widget child;
  const _StaggerIn({required this.index, required this.child});

  @override
  State<_StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<_StaggerIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
        begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // Stagger: max delay 40ms * index, capped at 600ms
    final delay = math.min(widget.index * 40, 600);
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}

// ── Summary banner ────────────────────────────────────────────────────────────
class _SummaryBanner extends StatelessWidget {
  final int total, vg, g, ok, po, vp, additives;
  const _SummaryBanner({
    required this.total, required this.vg, required this.g,
    required this.ok, required this.po, required this.vp,
    required this.additives,
  });

  @override
  Widget build(BuildContext context) {
    final Color overallColor;
    final String verdict;
    final IconData verdictIcon;

    if (vp > 0) {
      overallColor = _T.veryPoor;
      verdict      = 'Concerning items detected';
      verdictIcon  = Icons.warning_rounded;
    } else if (po > 0) {
      overallColor = _T.poor;
      verdict      = 'Some items to watch';
      verdictIcon  = Icons.info_outline_rounded;
    } else if (ok > 0) {
      overallColor = _T.okay;
      verdict      = 'Generally acceptable';
      verdictIcon  = Icons.thumb_up_alt_outlined;
    } else if (g > 0 || vg > 0) {
      overallColor = _T.veryGood;
      verdict      = 'Looks good overall';
      verdictIcon  = Icons.check_circle_outline_rounded;
    } else {
      overallColor = _T.textSec;
      verdict      = 'Scan completed';
      verdictIcon  = Icons.done_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: overallColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Top row — verdict
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: overallColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(verdictIcon, color: overallColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(verdict,
                      style: _T.label(color: _T.textPri, size: 13)),
                  Text('$total items scanned',
                      style: _T.body(size: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _T.bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _T.border),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.science_outlined,
                    color: _T.textSec, size: 12),
                const SizedBox(width: 4),
                Text('$additives additives',
                    style: _T.label(color: _T.textSec, size: 11)),
              ]),
            ),
          ]),
        ),
        Divider(height: 1, color: _T.border),
        // Pills row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              if (vg > 0) _Pill(count: vg, label: 'Very Good',
                  color: _T.veryGood, bg: _T.veryGoodBg),
              if (g > 0)  _Pill(count: g,  label: 'Good',
                  color: _T.good,     bg: _T.goodBg),
              if (ok > 0) _Pill(count: ok, label: 'Okay',
                  color: _T.okay,     bg: _T.okayBg),
              if (po > 0) _Pill(count: po, label: 'Poor',
                  color: _T.poor,     bg: _T.poorBg),
              if (vp > 0) _Pill(count: vp, label: 'Very Poor',
                  color: _T.veryPoor, bg: _T.veryPoorBg),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  final int count;
  final String label;
  final Color color, bg;
  const _Pill({required this.count, required this.label,
    required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 6),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 5, height: 5,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 5),
      Text('$count $label',
          style: _T.label(color: color, size: 11)),
    ]),
  );
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String eyebrow, title;
  final int? count;
  const _SectionHeader({
    required this.eyebrow, required this.title, this.count,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(eyebrow, style: _T.eyebrow()),
        const SizedBox(height: 3),
        Text(title, style: _T.heading(size: 18)),
      ]),
      const Spacer(),
      if (count != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _T.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _T.border),
          ),
          child: Text('$count items',
              style: _T.label(color: _T.textSec, size: 11)),
        ),
    ],
  );
}

// ── Health rating bar ─────────────────────────────────────────────────────────
class _HealthBar extends StatelessWidget {
  final int? rating;
  const _HealthBar({required this.rating});

  @override
  Widget build(BuildContext context) {
    final r = rating ?? 0;
    final color = _fg(rating);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Health rating',
              style: _T.body(size: 11)),
          const Spacer(),
          Text('$r / 100',
              style: _T.label(color: color, size: 11)),
        ]),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: r / 100.0),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            builder: (_, value, __) => LinearProgressIndicator(
              value: value,
              minHeight: 5,
              backgroundColor: _T.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Ingredient card (expandable) ──────────────────────────────────────────────
class _IngredientCard extends StatefulWidget {
  final Map<String, dynamic> item;
  const _IngredientCard({required this.item});

  @override
  State<_IngredientCard> createState() => _IngredientCardState();
}

class _IngredientCardState extends State<_IngredientCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _expandAnim = CurvedAnimation(
        parent: _expandCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _expandCtrl.forward();
    } else {
      _expandCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final name        = (widget.item['name']         as String?) ?? '';
    final description = (widget.item['description']  as String?) ?? '';
    final notes       = (widget.item['notes']        as String?) ?? '';
    final category    = (widget.item['category']     as String?) ?? '';
    final rating      = _safeInt(widget.item['health_rating']);
    final fgColor     = _fg(rating);
    final bgColor     = _bg(rating);
    final hasExtra    = description.isNotEmpty || notes.isNotEmpty || rating != null;

    return GestureDetector(
      onTap: hasExtra ? _toggle : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _expanded ? bgColor.withValues(alpha: 0.5) : _T.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expanded
                ? fgColor.withValues(alpha: 0.35)
                : _T.border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main row
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Icon
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: fgColor.withValues(alpha: 0.35)),
                  ),
                  child: Icon(_icon(rating), color: fgColor, size: 18),
                ),
                const SizedBox(width: 12),
                // Name + category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: _T.label(size: 13)),
                      if (category.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(category,
                            style: _T.body(size: 11).copyWith(
                                color: _T.accent.withValues(alpha: 0.8))),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Rating badge + chevron
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: fgColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        rating != null ? '$rating' : '?',
                        style: _T.label(color: fgColor, size: 12),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(_ratingLabel(rating),
                        style: _T.body(size: 9).copyWith(
                            color: fgColor.withValues(alpha: 0.75))),
                  ],
                ),
                if (hasExtra) ...[
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: _T.textSec, size: 18),
                  ),
                ],
              ]),

              // Expanded content
              SizeTransition(
                sizeFactor: _expandAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    if (rating != null) ...[
                      _HealthBar(rating: rating),
                      const SizedBox(height: 12),
                    ],
                    if (description.isNotEmpty) ...[
                      Text('About',
                          style: _T.label(
                              color: _T.textSec, size: 10)),
                      const SizedBox(height: 4),
                      Text(description,
                          style: _T.body(size: 12)),
                      const SizedBox(height: 10),
                    ],
                    if (notes.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _T.bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _T.accent.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: _T.accent.withValues(alpha: 0.7),
                                size: 13),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(notes,
                                  style: _T.body(size: 11).copyWith(
                                      color: _T.textSec
                                          .withValues(alpha: 0.9))),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Additive card (expandable) ────────────────────────────────────────────────
class _AdditiveCard extends StatefulWidget {
  final Map<String, dynamic> item;
  const _AdditiveCard({required this.item});

  @override
  State<_AdditiveCard> createState() => _AdditiveCardState();
}

class _AdditiveCardState extends State<_AdditiveCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _expandAnim = CurvedAnimation(
        parent: _expandCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _expandCtrl.forward();
    } else {
      _expandCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final code        = (widget.item['code']        as String?) ?? '';
    final name        = (widget.item['name']        as String?) ?? '';
    final description = (widget.item['description'] as String?) ?? '';
    final notes       = (widget.item['notes']       as String?) ?? '';
    final category    = (widget.item['category']    as String?) ?? '';
    final rating      = _safeInt(widget.item['health_rating']);
    final fgColor     = _fg(rating);
    final bgColor     = _bg(rating);
    final hasExtra    = description.isNotEmpty || notes.isNotEmpty || rating != null;

    // Highlight bad additives border
    final borderColor = (rating != null && rating < 40)
        ? fgColor.withValues(alpha: _expanded ? 0.5 : 0.3)
        : (_expanded ? fgColor.withValues(alpha: 0.3) : _T.border);

    return GestureDetector(
      onTap: hasExtra ? _toggle : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _expanded ? bgColor.withValues(alpha: 0.5) : _T.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // E-code badge
                Container(
                  constraints: const BoxConstraints(minWidth: 48),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 7),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: fgColor.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    code.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: _T.mono(color: fgColor, size: 10),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: _T.label(size: 13)),
                      if (category.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(category,
                            style: _T.body(size: 11).copyWith(
                                color: _T.accent.withValues(alpha: 0.8))),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Rating badge + chevron
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: fgColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        rating != null ? '$rating' : '?',
                        style: _T.label(color: fgColor, size: 12),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(_ratingLabel(rating),
                        style: _T.body(size: 9).copyWith(
                            color: fgColor.withValues(alpha: 0.75))),
                  ],
                ),
                if (hasExtra) ...[
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: _T.textSec, size: 18),
                  ),
                ],
              ]),

              // Expanded content
              SizeTransition(
                sizeFactor: _expandAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    if (rating != null) ...[
                      _HealthBar(rating: rating),
                      const SizedBox(height: 12),
                    ],
                    if (description.isNotEmpty) ...[
                      Text('About',
                          style: _T.label(
                              color: _T.textSec, size: 10)),
                      const SizedBox(height: 4),
                      Text(description,
                          style: _T.body(size: 12)),
                      const SizedBox(height: 10),
                    ],
                    if (notes.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _T.bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _T.accent.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: _T.accent.withValues(alpha: 0.7),
                                size: 13),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(notes,
                                  style: _T.body(size: 11).copyWith(
                                      color: _T.textSec
                                          .withValues(alpha: 0.9))),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 32),
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: _T.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _T.border),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.search_off_rounded,
          color: _T.textSec.withValues(alpha: 0.35), size: 48),
      const SizedBox(height: 16),
      Text('No ingredients found',
          style: _T.heading(size: 16, color: _T.textSec)),
      const SizedBox(height: 8),
      Text(
        'Make sure the ingredients label is clearly\nvisible and well-lit before scanning.',
        textAlign: TextAlign.center,
        style: _T.body(size: 12),
      ),
    ]),
  );
}

// ── Unresolved card ───────────────────────────────────────────────────────────
class _UnresolvedCard extends StatelessWidget {
  final List terms;
  const _UnresolvedCard({required this.terms});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _T.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _T.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.info_outline_rounded,
            color: _T.textSec.withValues(alpha: 0.5), size: 13),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Found on label but not yet in our database.',
            style: _T.body(size: 11),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      Wrap(
        spacing: 6, runSpacing: 6,
        children: terms.map((t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _T.bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _T.border),
          ),
          child: Text(t.toString(),
              style: _T.label(color: _T.textSec, size: 11)),
        )).toList(),
      ),
    ]),
  );
}